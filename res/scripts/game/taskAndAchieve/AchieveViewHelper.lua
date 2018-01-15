local AchieveViewHelper = class("AchieveViewHelper")
local PropTips = require("game.comm.PropTips")

local csbFile = ResConfig.UITaskAchieve.Csb2
local starFile = "ui_new/g_gamehall/t_task/AchieveStar.csb"
local stateFile = "ui_new/g_gamehall/t_task/AchieveState.csb"
local confrimBtnFile = "ui_new/p_public/Button_Confrim.csb"

local achieveStatus = {unActive = -1, active = 0, finish = 1, get = 2}

function AchieveViewHelper:ctor(taskAchieve, uiAchieve)
	self.taskAchieve = taskAchieve
	self.root = uiAchieve

	-- {id1, id2, ...}
	self.achieveID = {}
	-- {id = 成就ID, achieveVal = 完成次数, achieveStatus = 成就状态}
	self.achieveInfo = {}

	-- scroll上的item {[achieveId1] = Node1, [achieveId2] = Node2}
	self.items = {}
	self.itemsCache = {}

	self.scroll = CsbTools.getChildFromPath(self.root, "TaskPanel/AchieveScrollView")
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()
	local itemCsb = getResManager():getCsbNode(csbFile.achieveItem)
	local itemLayout = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel")
	self.itemSize = itemLayout:getContentSize()
    itemCsb:cleanup()
end

function AchieveViewHelper:onOpen(preUIID, part)
	self.immediatelyRefresh = true

	-- 道具点击提示
	self.propTips = PropTips.new()
	
	self:initAchievesInfo()
	self:reloadScroll()
	self.scroll:setInnerContainerPosition(cc.p(0,0))
	AchieveManage.setUIReloadFunc(handler(self, self.changeCallBack))

	-- 成就领奖回调监听
	local cmd = NetHelper.makeCommand(MainProtocol.Achievement, AchievementProtocol.GainSC)
	self.achieveHandler = handler(self, self.onAchieveCallBack)
	NetHelper.setResponeHandler(cmd, self.achieveHandler)
end

function AchieveViewHelper:onClose()
	AchieveManage.clearUIReloadFunc()
	self:cacheItems()

	local cmd = NetHelper.makeCommand(MainProtocol.Achievement, AchievementProtocol.GainSC)
	NetHelper.removeResponeHandler(cmd, self.achieveHandler)

	self.propTips:removePropAllTips()	
	self.propTips = nil
end

function AchieveViewHelper:cacheItems()
	for id, node in pairs(self.items) do
		table.insert(self.itemsCache, node)
		node:setVisible(false)
	end
	self.items = {}
end

function AchieveViewHelper:initAchievesInfo()
	self.achievesID = {}
	self.achievesInfo = {}
	local achievesModelInfo = getGameModel():getAchieveModel():getAchievesData()
	for id, info in pairs(achievesModelInfo) do
		local achieveConf = getAchieveConfItem(id)
		if achieveConf ~= nil and achieveConf.Show == 1 and info.achieveStatus ~= achieveStatus.unActive then
			self.achievesInfo[id] = {
				achieveID = id,
				achieveVal = info.achieveVal,
				achieveStatus = info.achieveStatus,
			}
			table.insert(self.achievesID, id)
		end
	end

	local function sortAchieve(achieveID1, achieveID2)
		local info1 = self.achievesInfo[achieveID1]
		local info2 = self.achievesInfo[achieveID2]
		local weight = {[-1]=1, [0]=3, [1]=4, [2]=2}
		if weight[info1.achieveStatus] > weight[info2.achieveStatus] then
			return true
		elseif info1.achieveStatus == info2.achieveStatus then
			if info1.achieveID > info2.achieveID then
				return true
			end
		end
		return false
	end

	table.sort(self.achievesID, sortAchieve)	-- 排序

	self:showTipsCount()
end

function AchieveViewHelper:showTipsCount(isVisible)
	local achieveTipsNum = 0
	for id, info in pairs(self.achievesInfo) do
		if info.achieveStatus == achieveStatus.finish then
			achieveTipsNum = achieveTipsNum + 1
		end
	end
	self.taskAchieve:setRedTipsNum("achieve", achieveTipsNum)
end

function AchieveViewHelper:reloadScroll()
	self:cacheItems()
	local scrollInnerSize = self.scroll:getContentSize()
	local allItemWidth = (self.itemSize.width + 18)*(#self.achievesID) + 2
	if allItemWidth > scrollInnerSize.width then
		scrollInnerSize.width = allItemWidth
	end
	self.scroll:setInnerContainerSize(scrollInnerSize)   --设置拖动区域

	for i, id in ipairs(self.achievesID) do
		local item = self:createAddItem(id)
		if item ~= nil then
			item:setPosition(cc.p(self.itemSize.width * (i - 0.5) + 18*(i - 1) + 10, self.itemSize.height*0.5+10))
		end
	end
end

function AchieveViewHelper:refreshScroll()
	for i, id in ipairs(self.achievesID) do
		local item = self.items[id]
		if item ~= nil then
			item:setPosition(cc.p(self.itemSize.width * (i - 0.5) + 18*(i - 1) + 10, self.itemSize.height*0.5+10))
			self:initAchieveInfo(item, id)
		end
	end
end

function AchieveViewHelper:changeCallBack(achieveId, type, replaceId)
	if type == "receiveBegin" then
    	self.immediatelyRefresh = false
	elseif type == "receiveEnd" then
		self.immediatelyRefresh = true
		self:initAchievesInfo()
		self:reloadScroll()

	elseif self.immediatelyRefresh then
		self:initAchievesInfo()
		self:refreshScroll()
	end
end

function AchieveViewHelper:createAddItem(achieveId)
	local itemCsb = nil
	if #self.itemsCache ~= 0 then
		itemCsb = self.itemsCache[1]
		itemCsb:setVisible(true)
		table.remove(self.itemsCache, 1)
	else
		itemCsb = getResManager():cloneCsbNode(csbFile.achieveItem)
		self.scroll:addChild(itemCsb)
	end
	
	self.items[achieveId] = itemCsb
	self:initAchieveInfo(itemCsb, achieveId)

	return itemCsb
end

function AchieveViewHelper:initAchieveInfo(itemCsb, achieveId)
	if itemCsb == nil then return end
	local achieveInfo = self.achievesInfo[achieveId]
	local achieveConf = getAchieveConfItem(achieveId)
	if achieveConf == nil or achieveInfo == nil then return end

	local stateCsb = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/AchieveState")
	local stateBtnCsb = CsbTools.getChildFromPath(stateCsb, "AchieveStatePanel/ReceiveButton/Button_Green")
	local progressBar = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/Task_LoadingBar_1")
	local titleLab = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/AchieveName")
	local progressLab = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/LoadingValue")
	local descLab = CsbTools.getChildFromPath(stateCsb, "AchieveStatePanel/ConditionTipLabel")
	local awardNode1 = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/Node_1")
	local awardNode2 = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/Node_2")

	local stateBtn = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/AchieveState/AchieveStatePanel/ReceiveButton")
	local stateBtnLab = CsbTools.getChildFromPath(stateBtn, "Button_Green/ButtomName")
	stateBtn:setTag(achieveId)
	stateBtn:setTouchEnabled(true)
	CsbTools.initButton(stateBtn, handler(self, self.achieveBtnCallBack), CommonHelper.getUIString(79), stateBtnLab, "Button_Green")

	self:addAwardToItem(achieveConf, awardNode1, awardNode2)

	if achieveInfo.achieveStatus == achieveStatus.active then
		progressBar:setPercent(achieveInfo.achieveVal*100 / achieveConf.CompleteTimes)
		progressLab:setString(achieveInfo.achieveVal .. "/" .. achieveConf.CompleteTimes)
	else
		progressBar:setPercent(100)
		progressLab:setString(achieveConf.CompleteTimes .. "/" .. achieveConf.CompleteTimes)
	end

	titleLab:setString(CommonHelper.getAchieveString(achieveConf.Title))
	descLab:setString(CommonHelper.getAchieveString(achieveConf.Desc))

	local preStarCount = 0
	local preAchieveID = getPreAchieveID(achieveId)
	if preAchieveID ~= nil and preAchieveID ~= 0 then
		local preAchieveConf = getAchieveConfItem(preAchieveID)
		if preAchieveConf ~= nil and achieveConf.PosType == preAchieveConf.PosType then
			preStarCount = getAchieveConfItem(preAchieveID).AchieveStar
		end
	end

	local realStarCount = preStarCount
	if achieveInfo.achieveStatus == 0 then
		CommonHelper.playCsbAnimate(stateCsb, stateFile, "TipLabel", false, nil, true)
	elseif achieveInfo.achieveStatus == 1 then
		CommonHelper.playCsbAnimate(stateCsb, stateFile, "Receive", true, nil, true)
	elseif achieveInfo.achieveStatus == 2 then
		realStarCount = achieveConf.AchieveStar
		CommonHelper.playCsbAnimate(stateCsb, stateFile, "Over", false, nil, true)
	end

	-- 星星动画
	for i=1,3 do		
		local starCsb = CsbTools.getChildFromPath(itemCsb, "AchieveBarPanel/AchieveStar_" .. i)
		if realStarCount > i then
			CommonHelper.playCsbAnimate(starCsb, starFile, "Star", false, nil, true)
		elseif realStarCount == i then
			if self.starAniID == achieveID then
				CommonHelper.playCsbAnimate(starCsb, starFile, "Get", false, nil, true)
			else
				CommonHelper.playCsbAnimate(starCsb, starFile, "Star", false, nil, true)
			end
		else
			CommonHelper.playCsbAnimate(starCsb, starFile, "NoGet", false, nil, true)
		end
	end
end

function AchieveViewHelper:addAwardToItem(achieveConf, awardNode1, awardNode2)
	awardNode1:removeAllChildren()
	awardNode2:removeAllChildren()

	local awardCount = 0
	local awardWidth = {}
	local function getAwardNode()
		awardCount = awardCount + 1
		if awardCount == 1 then
			return awardNode1
		elseif awardCount == 2 then
			return awardNode2
		else
			print("奖励不超过两个")
			return nil
		end
	end

	local currencyInfo = {AwardExp = "exp", AwardCoin = "gold", AwardDiamond = "diamond", AwardEnergy = "energy"}
	for k,v in pairs(currencyInfo) do
		if achieveConf[k] ~= 0 then
			local awardCsb1 = getResManager():cloneCsbNode(csbFile.taskAward1)
			getAwardNode():addChild(awardCsb1)
			awardWidth[awardCount] = self.taskAchieve:setAwardCsb1(awardCsb1, v, achieveConf[k])
		end
	end

	for _, propData in ipairs(achieveConf.AwardItems) do
		local propID = propData.ID
		local propNum = propData.num
		local awardCsb2 = getResManager():cloneCsbNode(csbFile.taskAward2)
		getAwardNode():addChild(awardCsb2)
		awardWidth[awardCount] = self.taskAchieve:setAwardCsb2(awardCsb2, propID, propNum)

		local touchNode = CsbTools.getChildFromPath(awardCsb2, "TaskAwradPanel/Award1/MainPanel")
		self.propTips:addPropTips(touchNode, getPropConfItem(propID), cc.p(-20, -50))
	end

	-- 移动位置, 一个的时候移到中间
	local posX, posY = awardNode1:getPosition()
	if awardCount == 1 then
		posX = 105 - awardWidth[1]/2
		awardNode1:setPosition(posX, posY)
	elseif awardCount == 2 then
		local allWidht = awardWidth[1] + awardWidth[2]
		posX = (200 - allWidht)/2
		awardNode1:setPosition(posX, posY)
		posX = posX + awardWidth[1] + 10
		awardNode2:setPosition(posX, posY)
	end
end

function AchieveViewHelper:achieveBtnCallBack(obj)
	local achieveID = obj:getTag()
	if self.achievesInfo[achieveID] == nil then	return end

	if self.achievesInfo[achieveID].achieveStatus == achieveStatus.finish then
		obj:setTouchEnabled(false)
		-- 发包
		local bufferData = NetHelper.createBufferData(MainProtocol.Achievement, AchievementProtocol.GainCS)
		bufferData:writeUShort(achieveID)
		NetHelper.request(bufferData)
	end
end

function AchieveViewHelper:onAchieveCallBack(mainCmd, subCmd, data)	
	local achieveID = data:readUShort()
	local propCount = data:readUChar()

    local awardData = {}
    local dropInfo = {}
	for i=1, propCount do
		dropInfo.id = data:readInt()
		dropInfo.num = data:readInt()
		UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
	end

	-- 显示奖励
	if achieveID ~= 0 then
		UIManager.open(UIManager.UI.UIAward, awardData)
	 	-- 结束此成就, 激活其他成就
	 	AchieveManage.receiveAchieve(achieveID)
	end

	-- 完成任务事件
    EventManager:raiseEvent(GameEvents.EventFinishTask, {taskId = achieveID, taskType = 2})
end

function AchieveViewHelper:makeVisible(isVisible)
	self.root:setVisible(isVisible)
end

return AchieveViewHelper