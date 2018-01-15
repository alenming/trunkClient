-- 王向明
-- 2016年11月3日 17:12:45
-- 七日狂欢活动模型

require"model.ModelConst"
-- 七日活动类型
-- SevenCrazyType = {
--     TYPE_NONE = 0,
--     TYPE_EVERY_DAY = 1,
--     TYPE_GROUP_UP = 2,
--     TYPE_SALE_BAG = 3,
-- }

local SevenCrazyModel = class("SevenCrazyModel")
local SevenDay = require"configlua.SevenDay"
local scheduler = require("framework.scheduler")


function SevenCrazyModel:ctor()
	self.mActiveCount = 0				-- 活动个数
	self.mToDay = 1						-- 今天是第几天
	self.mActiveTaskData = {}   			-- 商店活动数据
	self.mNeedFresh = false
	self.mActiveTaskData = {}
	self.mActiveData = {}
	self.activityOut = false
end

function SevenCrazyModel:init(buffData)
	self.mToDay = buffData:readInt()	
	self.mActiveCount = buffData:readShort() 							-- 活动个数

	if self.mToDay > 7 then
		self.activityOut = true
		return
	end

	self.mActiveShopData = {}										-- 商店活动数据
	self.mActiveTaskData = {}										-- 任务活动数据
	self.mActiveData = {}
	
	for i = 1, self.mActiveCount do
		local activeId = buffData:readShort()
		local activeType = buffData:readChar()

		self.mActiveData[activeId] = {
			activeID = activeId,
			activeType = activeType,
		}

		if activeType == ActiveType.TYPE_SHOP then
			local giftNum = buffData:readShort()						-- 礼包个数
			local gifts = {}
			for j = 1, giftNum do

				local goodsIds = {}
				for k = 1, 4 do
					table.insert(goodsIds, buffData:readInt())		-- 道具id 
				end
				local goodsNums = {}
				for k = 1, 4 do
					table.insert(goodsNums, buffData:readInt())		-- 道具数量
				end

				local price = buffData:readInt()	
				local giftId = buffData:readChar()
				local coinType = buffData:readChar()					-- 货币类型
				local saleRate = buffData:readChar()
				local maxBuyTimes = buffData:readChar()
				local buyTimes = buffData:readChar()					-- 已经购买次数		

				table.insert(gifts, {
					giftID = giftId,
					goodsID = goodsIds,
					goodsNum = goodsNums,
					goldType = coinType,
					price = price,
					saleRate = saleRate,
					maxBuyTimes = maxBuyTimes,
					buyTimes = buyTimes
				})
			end

			self.mActiveShopData[activeId] = {
				giftNum = giftNum,
				gifts = gifts
			}
		elseif activeType == ActiveType.TYPE_TASK then
			local taskNum = buffData:readShort()						-- 活动任务数
            local temp1 = {}
			for j = 1, taskNum do
				local conditionParam = {}
				for k = 1, 2 do
					table.insert(conditionParam, buffData:readInt())
				end
				local rewardGold = buffData:readInt()
				local rewardGoodsID = {}
				for k = 1, 4 do
					table.insert(rewardGoodsID, buffData:readInt())
				end
				local rewardGoodsNum = {}
				for k = 1, 4 do
					table.insert(rewardGoodsNum, buffData:readInt())
				end
				local value = buffData:readInt()					-- 任务完成进度
				local finishCondition = buffData:readShort()
				local rewardDiamond = buffData:readShort()
				local taskID = buffData:readChar()
				local finishFlag = buffData:readChar()				-- 是否领取，0-未领取，1-领取

				local temp2 = {}

				temp2.taskID = taskID
				temp2.finishCondition = finishCondition
				temp2.conditionParam = conditionParam
				temp2.rewardDimand = rewardDiamond
				temp2.rewardGold = rewardGold
				temp2.rewardEnergy = rewardEnergy
				temp2.rewardGoodsID = rewardGoodsID
				temp2.rewardGoodsNum = rewardGoodsNum
				temp2.value = value
				temp2.finishFlag = finishFlag

				table.insert(temp1, taskID, temp2)
				
			end
            table.insert(self.mActiveTaskData, activeId, temp1)
		end
	end

    self:startTimeListener()

	return true
end

-- 获取活动基础信息
function SevenCrazyModel:getActiveData()
	local ret = {}
	for _, data in pairs(self.mActiveData) do
		table.insert(ret, data)
	end
	return ret
end

function SevenCrazyModel:getActiveTaskData(activeId)
    return self.mActiveTaskData[activeId]
end

-- 获取商店任务信息
function SevenCrazyModel:getActiveShopProgress(activeId)
	if self.mActiveShopData[activeId] then
		return self.mActiveShopData[activeId]
	end
	return 0
end

-- 获取任务完成度
function SevenCrazyModel:getActiveTaskProgress(activeId, taskId)
	if self.mActiveTaskData[activeId] then
		if self.mActiveTaskData[activeId][taskId] then
			return self.mActiveTaskData[activeId][taskId]
		end
	end
end

-- 设置商店购买任务购买个数
function SevenCrazyModel:setActiveShopProgress(activeId, paramID, num)
	print("activeId, paramID",activeId, paramID)
	if self.mActiveShopData[activeId] then
		self.mActiveShopData[activeId].gifts[paramID].buyTimes = self.mActiveShopData[activeId].gifts[paramID].buyTimes + num
	end
end

-- 设置任务状态
function SevenCrazyModel:setActiveTaskValue(activeId, taskId, value)
	if self.mActiveTaskData[activeId] then
		if self.mActiveTaskData[activeId][taskId] then
			self.mActiveTaskData[activeId][taskId].value = value
            return true
		end
	end
    return false
end

-- 任务刷新后来刷新一下界面
function SevenCrazyModel:updateToRefreshUI()
	if UIManager.isTopUI(UIManager.UI.UISevenCrazy) then
		local ui = UIManager.getUI(UIManager.UI.UISevenCrazy)
		ui:refreshUI()
	end
end

-- 任务刷新后来刷新一下界面
function SevenCrazyModel:RefreshUI()
    -- 刷新红点
    RedPointHelper.updateSevenDay()

	if self.activityOut then
		if UIManager.isTopUI(UIManager.UI.UISevenCrazy) then
			UIManager.close()
			local hallUI = UIManager.getUI(UIManager.UI.UIHall)
			if hallUI then
				hallUI:sevenDayVisible()				
			end
			return
		end
	end
	if UIManager.isTopUI(UIManager.UI.UISevenCrazy) then
		local ui = UIManager.getUI(UIManager.UI.UISevenCrazy)
		ui:refreshUI()
	end
end


-- 设置任务领取状态
function SevenCrazyModel:setActiveTaskFinishFlag(activeId, taskId, finishFlag)
	if self.mActiveTaskData[activeId] then
		if self.mActiveTaskData[activeId][taskId] then
			self.mActiveTaskData[activeId][taskId].finishFlag = finishFlag
            return true
		end
	end
    return false
end

-- 获取今天是哪天
function SevenCrazyModel:getToday()
	return self.mToDay
end

-- 获取七天中某天的数据
function SevenCrazyModel:getSevenDayConfByDay(day)
	return getSevenDayConfByDay(day)
end

-- 获取当天的数据 要根据服务器给的任务完成度进行排序
function SevenCrazyModel:getToDayData(ShowPart)

	local toDayData = getSevenDayConfByDay(self.mToDay)
	local activeId      = toDayData["OpID"..ShowPart]
	local csvId    = toDayData["Type"..ShowPart]
	local sortInfo = {}
	local Acinfo = {}

	if csvId == 3 then
		Acinfo = getGameOp3Data(activeId)
	end
	
	local temp = 1
	for _,info in pairs(Acinfo) do
		table.insert(sortInfo, info)
	end

	local function sortData(info1, info2)
		local acId1 = info1.GameOp_ID
		local taskId1 = info1.GameOp_taskID
		local acInfo1 = self.mActiveTaskData[acId1][taskId1]
		local acId2 = info2.GameOp_ID
		local taskId2 = info2.GameOp_taskID
		local acInfo2 = self.mActiveTaskData[acId2][taskId2]
        local value1 = acInfo1.value
        local value2 = acInfo2.value
        local finishCondition1 = acInfo1.conditionParam[1]
        local finishCondition2 = acInfo2.conditionParam[1]

    	if  acInfo1.finishFlag == 0 and  acInfo2.finishFlag == 1 then
    		return true
    	elseif acInfo1.finishFlag == 1 and  acInfo2.finishFlag == 1 then
			if info1.GameOp_taskID< info2.GameOp_taskID then
				return true
			end
	    elseif acInfo1.finishFlag == 0 and  acInfo2.finishFlag == 0 then
		    if value1 >= finishCondition1 and value2 < finishCondition2 then
	 		    return true
	 		elseif value1 >= finishCondition1 and value2 >= finishCondition2 then
	 			if info1.GameOp_taskID< info2.GameOp_taskID then
	 				return true
	 			end
	 	    elseif value1 < finishCondition1 and value2 < finishCondition2 then
	 		    if #info1.Goto>0 and #info2.Goto ==0 then
	 			    return true
	 			elseif #info1.Goto>0 and #info2.Goto >0 then
	 				if info1.GameOp_taskID< info2.GameOp_taskID then
	 					return true
	 				end
	 			elseif #info1.Goto==0 and #info2.Goto ==0 then
	 				if info1.GameOp_taskID< info2.GameOp_taskID then
	 					return true
	 				end
	 			end
		    end
	    end
	    return false 
	end
	if  table.maxn(self.mActiveTaskData) ~= 0 then
		table.sort(sortInfo, sortData)
	end

	return sortInfo
end

local function restTime(time)
    local cur = os.time()
    local delta = cur -  time 
    if delta < 0 then
        delta = 0
    end
    local d = math.modf(delta / 86400)
    local h = math.modf((delta - d * 86400) / 3600)
    local m = math.modf((delta - d * 86400 - h * 3600) / 60)
    local s = math.modf(delta - d * 86400 - h * 3600 - m * 60)
    return {day = d, hour = h, min = m, sec = s}
end

local secTime = 0

function SevenCrazyModel:update(dt) 
	-- secTime = secTime + 1
	-- --print("secTime", secTime)
	-- if secTime%60 == 0 then
	-- 	self.mNeedFresh = true
	-- end
	for i,info in pairs(self.mTimeTask) do
        local acId =info.acId
        local taskId = info.taskId
		--print("acID,taskId",acId,taskId)
        local data = self.mActiveTaskData[acId][taskId]
		data.value = data.value + 1
		if data.finishFlag ~=1 and data.value == data.conditionParam[1] then
			print("在线时长任务完成了,在线时间为", data.value)
			RedPointHelper.addCount(RedPointHelper.System.SevenDay, 1, acId)
			self.mNeedFresh = true
            if i == #self.mTimeTask then
               scheduler.unscheduleGlobal(self.mSchedur)
               self.mSchedur = nil
            end
		end
	end
end  
  	 
 -- 本地时间监听
function SevenCrazyModel:getTime()
	
end

function SevenCrazyModel:getNeedFresh()
	return self.mNeedFresh
end

function SevenCrazyModel:setNeedFresh(isfresh)
	self.mNeedFresh = isfresh
end

-- 本地时间监听
function SevenCrazyModel:startTimeListener()
	self.mTimeTask = {}
	for i,info in pairs(self.mActiveTaskData) do
		for j,xnfo in pairs(info) do
			if xnfo.finishCondition == 201 and xnfo.value < xnfo.conditionParam[1] then
				table.insert(self.mTimeTask,{acId=i,taskId=j})
			end
		end
	end
	--dump(self.mTimeTask)
	if #self.mTimeTask ~= 0 then
		self.mSchedur = scheduler.scheduleGlobal(handler(self, self.update), 1)
	end
end


return SevenCrazyModel