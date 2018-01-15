--[[
	AchieveManage 主要用于过滤出成就事件的监听, 判断条件是否满足, 
		更新成就模型, 执行界面回调, 领取成就, 激活其他成就处理

	AchieveManage.achievesInfo = {
		{achieveID = 1, achieveVal = 0, achieveStatus = 0, preAchieveVal = 0}
	}	
]]

AchieveManage = {}

require("summonerComm.GameEvents")

local achieveModel = getGameModel():getAchieveModel()
local achieveStatus = {unActive = -1, active = 0, finish = 1, get = 2}

function AchieveManage.init()
	-- 注册监听
	local needListenEvent = {
		"EventStageOver", "EventHeroTestStageOver", "EventGoldTestStageOver", "EventTowerTestStageOver",
		"EventFBTestStageOver", "EventPVPOver", "EventDrawCard", "EventUseItem", "EventTouchGloden", 
		"EventReceiveCurrency", "EventReceiveEquip", "EventReceiveHero", "EventReceiveSummoner", 
		"EventDressEquip", "EventHeroUpgradeLevel", "EventHeroUpgradeStar", "EventHeroUpgradeSkill", 
		"EventPlayerUpgradeLevel", "EventFinishTask", "EventOwnUnion", "EventShopBuy", "EventEquipMake",
	}
	for _, eventName in pairs(needListenEvent) do
		EventManager:addEventListener(GameEvents[eventName], AchieveManage.onAchieveEvent)
	end	

	-- 从模型中取得成就信息
	AchieveManage.achievesInfo = achieveModel:getAchievesData()

	AchieveManage.conditionAchieveIds =  {}
	for id, info in pairs(AchieveManage.achievesInfo) do
		local achieveConf = getAchieveConfItem(id)
		if achieveConf ~= nil then
			-- 提取出监听id 对应成就ids 的数据
			if AchieveManage.conditionAchieveIds[achieveConf.FinishCondition] == nil then
				AchieveManage.conditionAchieveIds[achieveConf.FinishCondition] = {}
			end
			table.insert(AchieveManage.conditionAchieveIds[achieveConf.FinishCondition], id)

			-- 状态判断
			if info.achieveStatus == achieveStatus.active then
				local completeTimes = ConditionProcess.getStateTaskCompleteTimes(
					achieveConf.FinishCondition, achieveConf.FinishParameters, info.achieveVal)
				AchieveManage.setAchieveCompleteTimes(id, completeTimes)
			end
		end
	end

	-- 策划说登陆的时候判断任务是否激活
	AchieveManage.checkAchieveActive(GameEvents.EventPlayerUpgradeLevel, {})
end

function AchieveManage.onAchieveEvent(eventName, args)
    print("AchieveManage.onAchieveEvent(eventName, args) 1")
	-- 成就激活判断
	AchieveManage.checkAchieveActive(eventName, args)

	-- 事件函数
	local func = ConditionProcess.getFuncByEvent(eventName)
	if func == nil then return end

	-- 影响的成就Id
	local achieveIds = AchieveManage.getAchieveIdsByEvent(eventName)
	if achieveIds == nil then return end

	for _, achieveId in ipairs(achieveIds) do
		local achieveInfo = AchieveManage.getAchieveInfoById(achieveId)
		local achieveConf = getAchieveConfItem(achieveId)
		if achieveInfo ~= nil and achieveConf ~= nil and achieveInfo.achieveStatus == achieveStatus.active then
			local achieveVal = achieveInfo.achieveVal
			local newAchieveVal = func(achieveConf.FinishCondition, achieveConf.FinishParameters, achieveVal, args)
			if achieveVal ~= newAchieveVal then
				AchieveManage.setAchieveCompleteTimes(achieveId, newAchieveVal)
			end
		end
	end
    print("AchieveManage.onAchieveEvent(eventName, args) 2")
end

-- 添加成就界面刷新回调
function AchieveManage.setUIReloadFunc(func)
	AchieveManage.uiCallBackFunc = func
end

-- 注销成就界面刷新回调
function AchieveManage.clearUIReloadFunc()
	AchieveManage.uiCallBackFunc = nil
end

-- 通过事件, 取出可能受到影响的成就id
function AchieveManage.getAchieveIdsByEvent(eventName)
	local achieveIds = {}
	local conditionIds = ConditionProcess.getConditionIdsByEvent(eventName)
	if conditionIds ~= nil then
		for _, conditionId in ipairs(conditionIds) do
			local ids = AchieveManage.conditionAchieveIds[conditionId]
			if ids ~= nil then
				for _, id in ipairs(ids) do
					table.insert(achieveIds, id)
				end
			end
		end
	end
	return achieveIds
end

function AchieveManage.getAchieveInfoById(achieveId)
	return AchieveManage.achievesInfo[achieveId]
end

-- 设置完成次数
function AchieveManage.setAchieveCompleteTimes(achieveId, times)
	local achieveInfo = AchieveManage.getAchieveInfoById(achieveId)
	if not achieveInfo then
		return 
	end

	if achieveInfo.achieveStatus == achieveStatus.active then
		local achieveConf = getAchieveConfItem(achieveId)
		if achieveConf ~= nil then
			achieveInfo.achieveVal = times
			-- 是否告知服务器
			AchieveManage.autoSendServer(achieveInfo, achieveConf)

			if times >= achieveConf.CompleteTimes then
				-- 判断是否是隐藏的成就
				if achieveConf.Show == 0 then
					-- 将成就切换成领取状态
					achieveInfo.achieveStatus = achieveStatus.get
					AchieveManage.setAchieveAboutComplete(achieveInfo)
					AchieveManage.receiveAchieve(achieveId)
				else
					-- 成就完成
					achieveInfo.achieveStatus = achieveStatus.finish
					AchieveManage.setAchieveAboutComplete(achieveInfo)
                    RedPointHelper.addCount(RedPointHelper.System.TaskAndAchieve, 1)
				end
			else
				AchieveManage.setAchieveAboutComplete(achieveInfo)					
			end
		end
	end
end

-- 根据信息, 判断是否需要发送给服务器
function AchieveManage.autoSendServer(achieveInfo, achieveConf)
	if not achieveInfo.preAchieveVal then
		achieveInfo.preAchieveVal = 0
	end

	-- 数据没有改变不发送
	if achieveInfo.preAchieveVal == achieveInfo.achieveVal then
		return
	end
	achieveInfo.preAchieveVal = achieveInfo.achieveVal

	if ConditionProcess.needSendConditionIds[achieveConf.FinishCondition] then
		-- 完成时发送的, 在没有完成前不发送
		if achieveInfo.achieveStatus ~= achieveStatus.finish and achieveInfo.achieveVal < achieveConf.CompleteTimes then
			return
		end
	elseif not ConditionProcess.everyNeedSendConditionIds[achieveConf.FinishCondition] then
		-- 不是完成发送, 也不是改变时发送的不发送
		return
	end
	
	local bufferData = NetHelper.createBufferData(MainProtocol.Achievement, AchievementProtocol.FinishCS)
	bufferData:writeUShort(achieveConf.ID)
	bufferData:writeInt(achieveInfo.achieveVal)
	NetHelper.request(bufferData)
end

-- 领取成就, 激活新的成就(此处不计算奖励领取)
function AchieveManage.receiveAchieve(achieveId)
	AchieveManage.raiseUI(achieveId, "receiveBegin")
	local achieveConf = getAchieveConfItem(achieveId)
	local achieveInfo = AchieveManage.getAchieveInfoById(achieveId)
	if achieveConf == nil or achieveInfo == nil then return end

	-- 处理成就本身
	local isClose = false	-- 处理覆盖显示
	if achieveConf.CloseDisplay == 1 then
		achieveInfo.achieveStatus = achieveStatus.get
		AchieveManage.setAchieveAboutComplete(achieveInfo)
	else
		isClose = true
		achieveModel:delAchieve(achieveId)
		AchieveManage.achievesInfo[achieveId] = nil
	end
	if AchieveManage.conditionAchieveIds[achieveConf.FinishCondition] ~= nil then
		for i, id in ipairs(AchieveManage.conditionAchieveIds[achieveConf.FinishCondition]) do
			if id == achieveId then
				table.remove(AchieveManage.conditionAchieveIds[achieveConf.FinishCondition], i)
				break
			end
		end
	end

	-- 激活其他成就
	local endStarIds = achieveConf.EndStartID
	for _, id in ipairs(endStarIds) do
		local endStarIdConf = getAchieveConfItem(id)
		if endStarIdConf ~= nil and AchieveManage.achievesInfo[id] == nil then
			if AchieveManage.conditionAchieveIds[endStarIdConf.FinishCondition] == nil then
				AchieveManage.conditionAchieveIds[endStarIdConf.FinishCondition] = {}
			end
			table.insert(AchieveManage.conditionAchieveIds[endStarIdConf.FinishCondition], id)

			local newAchieveVal, isActive = ConditionProcess.getEndStarIdInfo(
					endStarIdConf.FinishCondition, endStarIdConf.FinishParameters, endStarIdConf.UnLockLv)
			local status = isActive and achieveStatus.active or achieveStatus.unActive
			-- 添加成就
			AchieveManage.achievesInfo[id] = {achieveID=id, achieveVal=0, achieveStatus=status, preAchieveVal = 0}
			achieveModel:addAchieve(AchieveManage.achievesInfo[id])
			AchieveManage.setAchieveCompleteTimes(id, newAchieveVal)
		end
	end
	AchieveManage.raiseUI(achieveId, "receiveEnd")
end

-- 成就激活检测
function AchieveManage.checkAchieveActive(eventName, args)
	if eventName == GameEvents.EventPlayerUpgradeLevel then
		local userLv = getGameModel():getUserModel():getUserLevel()
		for id, info in pairs(AchieveManage.achievesInfo) do
			if info.achieveStatus == achieveStatus.unActive then
				local achieveConf = getAchieveConfItem(id)
				if achieveConf ~= nil then
					if userLv >= achieveConf.UnLockLv then
						info.achieveStatus = achieveStatus.active
						achieveModel:setAchieve(info)
	                    TaskManage.raiseUI(id, "unActivateToActivate")
					end
				end
			end
		end
	end
end

-- 设置成就模型
function AchieveManage.setAchieveAboutComplete(achieveInfo)
	achieveModel:setAchieve(achieveInfo)
	AchieveManage.raiseUI(achieveInfo.achieveID, "changeCompleteTimes")
end

-- 通知界面刷新
function AchieveManage.raiseUI(...)
	if type(AchieveManage.uiCallBackFunc) == "function" then
		AchieveManage.uiCallBackFunc(...)
	end
end

return AchieveManage