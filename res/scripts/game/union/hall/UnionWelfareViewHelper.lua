--[[
	公会福利协助管理，主要实现以下内容
	1. 显示福利基本信息:
		名称, 进度
	2. 领取福利
--]]

local UnionWelfareViewHelper = class("UnionWelfareViewHelper")

local csbFile = ResConfig.UIUnionHall.Csb2

local unionModel = getGameModel():getUnionModel()

function UnionWelfareViewHelper:ctor(uiUnionHall, csb)
	self.uiUnionHall = uiUnionHall
	self.root = csb

	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/WealPanel/ScrollView")
	self.scroll:removeAllChildren()
    self.scroll:setScrollBarEnabled(false)
end

function UnionWelfareViewHelper:onOpen()
	-- 服务器回调监听
	local cmdWelfareReceive = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionWelfareSC)
	self.welfareReceiveHandler = handler(self, self.onWelfareReceive)
	NetHelper.setResponeHandler(cmdWelfareReceive, self.welfareReceiveHandler)
end

function UnionWelfareViewHelper:onClose()
	-- 取消监听
	local cmdWelfareReceive = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionWelfareSC)
	NetHelper.removeResponeHandler(cmdWelfareReceive, self.welfareReceiveHandler)
end

function UnionWelfareViewHelper:onTop(uiID)
end

function UnionWelfareViewHelper:setVisible(visiable)
	self.root:setVisible(visiable)

	if visiable then
		self.unionLv = unionModel:getOriginUnionLv()
		self.unionLiveness = unionModel:getUnionLiveness()
		self.welfareTag = unionModel:getWelfareTag()
		--self.todayStageLiveness = unionModel:getTodayStageLiveness()
		self.todayPvpLiveness = unionModel:getTodayPvpLiveness()
		self.unionLvConf = getUnionLevelConfItem(self.unionLv)

		if not self.unionLvConf then
			print("unionLevelConf is nil ", self.unionLv)
			return
		end

    	self:refreshUI()
	end
end

function UnionWelfareViewHelper:refreshUI()
	if not self.root:isVisible() then
		return
	end
	
	self.scroll:removeAllChildren()
	local allItemHeight = 0
	local innerSize = self.scroll:getContentSize()
	local itemsInfo = {}

	local itemCsb = nil
	local itemSize = 0
	local func = {"autoAddActiveRewardItem", "autoAddActiveSRewardItem"}
	for i,v in ipairs(func) do
		itemCsb, itemSize = UnionWelfareViewHelper[v](self)
		if itemCsb then
			table.insert(itemsInfo, {csb = itemCsb, size = itemSize})
			allItemHeight = allItemHeight + itemSize.height
		end
	end

	-- 设置innerSize
	if allItemHeight > innerSize.height then
		innerSize.height = allItemHeight
	end
	
	-- 改变位置
	allItemHeight = 0 
	for i,v in ipairs(itemsInfo) do
		v.csb:setPosition(v.size.width*0.5, innerSize.height - v.size.height/2 - allItemHeight)
		allItemHeight = allItemHeight + v.size.height
	end
end

function UnionWelfareViewHelper:resetDataValidity()
	UnionHelper.reGetStamp.unionInfo = 0
end

function UnionWelfareViewHelper:resetHasRefresh()
	
end

function UnionWelfareViewHelper:autoAddActiveRewardItem()
	local item = getResManager():cloneCsbNode(csbFile.activeItem)
    self.scroll:addChild(item)
	local panel = CsbTools.getChildFromPath(item, "WealBarPanel")
	local size = panel:getContentSize()

	local titleLab = CsbTools.getChildFromPath(panel, "BoxName")
	local livenessLab = CsbTools.getChildFromPath(panel, "LoadingBarNum")
	local descLab = CsbTools.getChildFromPath(panel, "Tips2")
	local questionBtn = CsbTools.getChildFromPath(panel, "QuestionButton")
	local receiveBtn = CsbTools.getChildFromPath(panel, "AwardButton")
	local receiveLab = CsbTools.getChildFromPath(receiveBtn, "Text")
	local livenessBar = CsbTools.getChildFromPath(panel, "LoadingBar")
	
	local isMeet = (self.unionLiveness >= self.unionLvConf.ActiveReward and true or false)
	local notReceive = ((bit.band(self.welfareTag, 2^0) == 0) and true or false)
	local canClick = isMeet and notReceive
	receiveBtn:setTouchEnabled(canClick)
	receiveBtn:setBright(canClick)
	receiveLab:enableOutline(cc.c4b(0,92,0, canClick and 255 or 0), 2)

	CsbTools.initButton(questionBtn, function()
		UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2013))
	end)

	-- 按钮提示文字
	local tipsStr = ""
	if notReceive then
		if isMeet then
			tipsStr = CommonHelper.getUIString(79)
		else
			tipsStr = CommonHelper.getUIString(1473)
		end
	else
		tipsStr = CommonHelper.getUIString(503)
	end
	CsbTools.initButton(receiveBtn, handler(self, self.activeReceiveBtn), tipsStr)
	titleLab:setString(CommonHelper.getUIString(2009))
	livenessLab:setString(self.unionLiveness .. "/" .. self.unionLvConf.ActiveReward)
	descLab:setString(string.format(CommonHelper.getUIString(2007), self.todayPvpLiveness))
	livenessBar:setPercent(self.unionLiveness * 100 / self.unionLvConf.ActiveReward)
	CommonHelper.playCsbAnimate(item, csbFile.activeItem, "State1", false, nil, true)

	return item, size
end

function UnionWelfareViewHelper:autoAddActiveSRewardItem()
	if self.unionLiveness >= self.unionLvConf.ActiveSReward then
       local item = getResManager():cloneCsbNode(csbFile.activeSItem)
	    self.scroll:addChild(item)
		local panel = CsbTools.getChildFromPath(item, "WealBarPanel")
		local size = panel:getContentSize()

		local titleLab = CsbTools.getChildFromPath(panel, "BoxName")
		local livenessLab = CsbTools.getChildFromPath(panel, "LoadingBarNum")
		local descLab = CsbTools.getChildFromPath(panel, "Tips2")
		local questionBtn = CsbTools.getChildFromPath(panel, "QuestionButton")
		local receiveBtn = CsbTools.getChildFromPath(panel, "AwardButton")
		local receiveLab = CsbTools.getChildFromPath(receiveBtn, "Text")
		local livenessBar = CsbTools.getChildFromPath(panel, "LoadingBar")

		local isMeet = (self.unionLiveness >= self.unionLvConf.ActiveReward and true or false)
		local notReceive = ((bit.band(self.welfareTag, 2^1) == 0) and true or false)
		local canClick = isMeet and notReceive
		receiveBtn:setTouchEnabled(canClick)
		receiveBtn:setBright(canClick)
		receiveLab:enableOutline(cc.c4b(0,92,0, canClick and 255 or 0), 2)

		CsbTools.initButton(questionBtn, function()
			UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2013))
		end)
		
		-- 按钮提示文字
		local tipsStr = ""
		if notReceive then
			if isMeet then
				tipsStr = CommonHelper.getUIString(79)
			else
				tipsStr = CommonHelper.getUIString(1473)
			end
		else
			tipsStr = CommonHelper.getUIString(503)
		end
		CsbTools.initButton(receiveBtn, handler(self, self.activeSReceiveBtn), tipsStr)
		titleLab:setString(CommonHelper.getUIString(2011))
		livenessLab:setString(self.unionLiveness .. "/" .. self.unionLvConf.ActiveSReward)
		descLab:setString(CommonHelper.getUIString(2008))
		livenessBar:setPercent(self.unionLiveness * 100 / self.unionLvConf.ActiveSReward)
		CommonHelper.playCsbAnimate(item, csbFile.activeItem, "State2", false, nil, true)

		return item, size
	else
		return nil, 0
	end
end

function UnionWelfareViewHelper:activeReceiveBtn(obj)
	obj.soundId = nil
	if self.unionLiveness >= self.unionLvConf.ActiveReward and 
		bit.band(self.welfareTag, 2^UnionHelper.welfareType.activeBox) == 0 then
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionWelfareCS)
		buffer:writeChar(UnionHelper.welfareType.activeBox)
		NetHelper.request(buffer)
	else
		obj.soundId = MusicManager.commonSound.fail
	end
end

function UnionWelfareViewHelper:activeSReceiveBtn(obj)
	obj.soundId = nil
	if self.unionLiveness >= self.unionLvConf.ActiveSReward and 
		bit.band(self.welfareTag, 2^UnionHelper.welfareType.activeSBox) == 0 then
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionWelfareCS)
		buffer:writeChar(UnionHelper.welfareType.activeSBox)
		NetHelper.request(buffer)
	else
		obj.soundId = MusicManager.commonSound.fail
	end
end

function UnionWelfareViewHelper:onWelfareReceive(mainCmd, subCmd, data)
	local welfareType = data:readChar()
	local propCount = data:readInt()

	local awardData = {}
	local dropInfo = {}
	for i=1, propCount do
		dropInfo.id = data:readInt()
		dropInfo.num = data:readInt()
		UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
	end

	self.welfareTag = bit.bor(self.welfareTag, 2^welfareType)
	unionModel:setWelfareTag(self.welfareTag)
	self:refreshUI()

	-- 显示奖励
	if welfareType >= UnionHelper.welfareType.activeBox then
        RedPointHelper.addCount(RedPointHelper.System.Union, -1, RedPointHelper.UnionSystem.Liveness)
		self.uiUnionHall:showRedPoint(self.root:getTag())
        UIManager.open(UIManager.UI.UIAward, awardData)
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
	end
end

return UnionWelfareViewHelper