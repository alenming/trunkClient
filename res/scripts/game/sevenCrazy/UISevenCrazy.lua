--[[
		佣兵主界面
--]]

local UISevenCrazy = class("UISevenCrazy", function()
		return require("common.UIView").new()
	end)

local SevenCrazyModel = getGameModel():getSevenCrazyModel()

local csbFile = ResConfig.UISevenCrazy.Csb2

local btnFile = "ui_new/g_gamehall/o_operate/operate/ButtonState.csb"

local PropTips = require("game.comm.PropTips")

--活动语言包ID
local activeID = {1272,1273,1274}

local scheduler = require("framework.scheduler")

local function restTime()
    local delta = getGameModel():getNow()
    if delta < 0 then
        delta = 0
    end
    local d = math.modf(delta / 86400)
    local h = math.modf((delta - d * 86400) / 3600)
    local m = math.modf((delta - d * 86400 - h * 3600) / 60)
    local s = math.modf(delta - d * 86400 - h * 3600 - m * 60)
    return {day = d, hour = h, min = m, sec = s}
end


function UISevenCrazy:ctor()
	-- 初始化UI
	self.rootPath 	= csbFile.root
	self.root 		= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mShowPart = 1
	self.mMoney = 0
	self.mIsBuyGem = false

	--返回按钮
	self.mBackBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(self.mBackBtn, handler(self, self.backBtnCallBack))

	self.mPropScrollView = CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/PropScrollView")
	self.mPropScrollView:setScrollBarEnabled(false)
 	for i=1,3 do
 		self["TabButton_"..i]= CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/TabButton_"..i)
 		CsbTools.initButton(self["TabButton_"..i], handler(self, self.threeBtnCallBack), nil, nil, "TabButton_"..i)
 		self["TabButton_"..i]:setTag(i)
 	end

 	self.mTabPanel = CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/TabPanel_1")
	self.mTabPanel:setVisible(false)

 	self.mScrollView1 = CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/ScrollView_1")
 	self.mScrollView1:setScrollBarEnabled(false)
	self.mScrollView1:removeAllChildren()
	self.mTabPanel:setVisible(false)
   
 	self.mScrollView2 = CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/ScrollView_2"):setVisible(false)
 	self.mScrollView2:setScrollBarEnabled(false)
	self.mScrollView2:removeAllChildren()
	self.mScrollView2:setVisible(false)


	self.mGoldInfo = CsbTools.getChildFromPath(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
	self.mGemInfo = CsbTools.getChildFromPath(self.root, "GemInfo/GemPanel/GemCountLabel")


	self.mTaskItemSize = {width = 600, height = 140}
	self.mPropItemSize = {width = 110, height = 150 }
end

function UISevenCrazy:update(dt)  
	 if SevenCrazyModel:getNeedFresh() then
	 	print("在线任务好了,刷新一下界面")
	 	SevenCrazyModel:setNeedFresh(false)
		self:updateRightUi()
		self:initRedPoint()
	 end
end  

function UISevenCrazy:onOpen()
    local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, SevenCrazyProtocol.SevenCrazyGetSC)
	local mCallBack = handler(self, self.acceptGetCmd)
	NetHelper.setResponeHandler(cmd, mCallBack)

	self.surplusTimeSheduler = scheduler.scheduleGlobal(handler(self, self.update), 1)


	self:initCommonUI()
	self:initRedPoint()
	self:updateRightUi()
	self:initRightUIAC3()
end

function UISevenCrazy:onClose()
	-- self.itemButton = {}
	-- self.mScrollView1:removeAllChildren()
	-- self.mScrollView2:removeAllChildren()
	-- self.mCache1 = {}
	-- self.mCache2 = {}
	-- self.mCache3 = {}
	-- if self.propTips then
 --        self.propTips:removePropAllTips()
 --        self.propTips = nil
 --    end
	local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, SevenCrazyProtocol.SevenCrazyGetSC)
	NetHelper.removeResponeHandler(cmd,handler(self, self.acceptGetCmd))

	if self.surplusTimeSheduler then
		scheduler.unscheduleGlobal(self.surplusTimeSheduler)
		self.surplusTimeSheduler = nil
	end
end

function UISevenCrazy:onTop()
	self:initCommonUI()
	self:initRedPoint()
	self:updateRightUi()
	self:initRightUIAC3()
end

function UISevenCrazy:init()

	self:initUI()
end

function UISevenCrazy:initUI()

    self.propTips = PropTips.new()
    self.mScrollView1:removeAllChildren()
	self.mScrollView2:removeAllChildren()
	self.mCache1 = {}
	self.mCache2 = {}
	self.mCache3 = {}
	self.itemButton = {}

	self.mShowPart = 1
	self.curActiveType = 1

	self:initTopUI()
	self:initLeftUI()
	self:initRightUI()
	self:initCommonUI()
	self:initRedPoint()
end

function UISevenCrazy:refreshUI()

	self.mScrollView1:removeAllChildren()
	self.mScrollView2:removeAllChildren()
	self.mCache1 = {}
	self.mCache2 = {}
	self.itemButton = {}

	self.mShowPart = 1
	self.curActiveType = 1

	self:updateTopUi()
	self:initLeftUI()
	self:initRightUI()
	self:initCommonUI()
	self:initRedPoint()
end

function UISevenCrazy:initRedPoint()
	self.activitysRedPoint = RedPointHelper.getSevenDayActivityRedPoint()
	for acId, count in pairs(self.activitysRedPoint) do
		if self.mRedPoint[acId] then
			self.mRedPoint[acId]:setVisible(count > 0)
		end
	end
end 

function UISevenCrazy:initCommonUI()
	local gold   = getGameModel():getUserModel():getGold()
	local gem = getGameModel():getUserModel():getDiamond()

	self.mGoldInfo:setString(gold)
	self.mGemInfo:setString(gem)

	--更新按钮
	if 	self.mIsBuyGem  then
		self.mIsBuyGem = false
		local panel = CsbTools.getChildFromPath(self.mTabPanel, "TabPanel")
		local BuyButton =  CsbTools.getChildFromPath(panel, "BuyButton")
		local gem = getGameModel():getUserModel():getDiamond()
		if gem >= self.mMoney  then --钱够
			CommonHelper.playCsbAnimate(BuyButton, btnFile, "Green", false, nil, true)
		else
			CommonHelper.playCsbAnimate(BuyButton, btnFile, "Orange", false, nil, true)	
		end
	end
end

function UISevenCrazy:initTopUI()
	local toDay = SevenCrazyModel:getToday()
	self.mPropScrollView:removeAllChildren()
	local size = self.mPropScrollView:getContentSize()
	for i=1,7  do
		local item = nil
		item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setTag(i)
		item:setContentSize(self.mPropItemSize)
 		CsbTools.initButton(item, handler(self, self.sevenBtnCallBack))
 		item:setTag(i)
 	 	local son = getResManager():cloneCsbNode(csbFile.PropItem)
 	 	table.insert(self.mCache3, i, son)
		son:setTag(7758258)
		son:setPosition(cc.p(self.mPropItemSize.width/2,self.mPropItemSize.height/2))
		item:addChild(son)
		item:setPosition(cc.p(self.mPropItemSize.width/2 + (i-1)*(self.mPropItemSize.width+10),self.mPropItemSize.height/2))

		self:initTopUIItem(son, i)
		self.mPropScrollView:addChild(item)
	end
end

function UISevenCrazy:initTopUIItem(csbItem, i)

	local info = SevenCrazyModel:getSevenDayConfByDay(i)
	local data = CsbTools.getChildFromPath(csbItem, "PropItem/Date")
	local name = CsbTools.getChildFromPath(csbItem, "PropItem/Name")
	local redPoint = CsbTools.getChildFromPath(csbItem, "PropItem/RedTipPoint")
	local icon = CsbTools.getChildFromPath(csbItem, "PropItem/AllItem/MainPanel/Prop/Item/icon")
	local num = CsbTools.getChildFromPath(csbItem, "PropItem/AllItem/MainPanel/Prop/Item/Num")
	local level = CsbTools.getChildFromPath(csbItem, "PropItem/AllItem/MainPanel/Prop/Item/Level")
	num:setVisible(false)

	data:setString(string.format(CommonHelper.getUIString(1292), i))
	name:setString(CommonHelper.getPropString(info.Desc))
	redPoint:setVisible(false)
	CsbTools.replaceImg(icon, info.Icon)

	local today = SevenCrazyModel:getToday()
	if today > i then
		CommonHelper.playCsbAnimate(csbItem, csbFile.PropItem, "Over", false, nil, true)
	elseif today == i then
		CommonHelper.playCsbAnimate(csbItem, csbFile.PropItem, "On", false, nil, true)
	elseif today < i then
		CommonHelper.playCsbAnimate(csbItem, csbFile.PropItem, "Off", false, nil, true)
	end
end

function UISevenCrazy:initLeftUI()
	self.mRedPoint = {}
	self.activitysRedPoint = RedPointHelper.getSevenDayActivityRedPoint()
    local info = SevenCrazyModel:getSevenDayConfByDay(SevenCrazyModel:getToday())

	for i=1,3 do
		local text = CsbTools.getChildFromPath(self["TabButton_"..i], "TabButton/TabButton/Text")
 		text:setString(CommonHelper.getUIString(activeID[i]))
 		local red = CsbTools.getChildFromPath(self["TabButton_"..i], "TabButton/TabButton/RedTipPoint")
 		red:setVisible(false)
 		table.insert(self.mRedPoint, info["OpID"..i], red)
 		self:showActiveRedPoint(info["OpID"..i])
 	end

 	local son1 = CsbTools.getChildFromPath(self["TabButton_1"], "TabButton")
 	CommonHelper.playCsbAnimate(son1, csbFile.TabButton, "On", false, nil, true)

	local son2 = CsbTools.getChildFromPath(self["TabButton_2"], "TabButton")
 	CommonHelper.playCsbAnimate(son2, csbFile.TabButton, "Off", false, nil, true)

	local son3 = CsbTools.getChildFromPath(self["TabButton_3"], "TabButton")
 	CommonHelper.playCsbAnimate(son3, csbFile.TabButton, "Off", false, nil, true)
end

function UISevenCrazy:showParts()
	if self.mShowPart == 1 then
		self.mTabPanel:setVisible(false)
		self.mScrollView1:setVisible(true)
		self.mScrollView2:setVisible(false) 
	elseif self.mShowPart == 2 then
		self.mTabPanel:setVisible(false)
		self.mScrollView1:setVisible(false)
		self.mScrollView2:setVisible(true)
	elseif self.mShowPart == 3 then
		self.mTabPanel:setVisible(true)
		self.mScrollView1:setVisible(false)
		self.mScrollView2:setVisible(false)  
	end
end

function UISevenCrazy:initRightUI()
	self:showParts()

	local data = SevenCrazyModel:getToDayData(1)  -- 传这个showpart是只为了找表而已gameop几
	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5
	local hang = #data
	local innerSize = self.mScrollView1:getContentSize()

	local h = offsetY + hang*self.mTaskItemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mScrollView1:getInnerContainerSize().height ~= innerSize.height then
	    self.mScrollView1:setInnerContainerSize(innerSize)
    end  
	
	for i=1,#data do
		local activeInfo = data[i]
		local itemCsb = getResManager():cloneCsbNode(csbFile.TaskItem)
		table.insert(self.mCache1, i, itemCsb)
		self:initRightUIItem(itemCsb, activeInfo)
		local posX = offsetX + self.mTaskItemSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mTaskItemSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX,posY))
		self.mScrollView1:addChild(itemCsb)

	end
	self.mScrollView1:jumpToTop()

	local data2 = SevenCrazyModel:getToDayData(2)  -- 传这个showpart是只为了找表而已gameop几
	local hang2 = #data2

	local innerSize2 = self.mScrollView2:getContentSize()

	local h2 = offsetY + hang2*self.mTaskItemSize.height + (hang2 + 1)*intervalY
	if h2 > innerSize2.height then
		innerSize2.height = h2
	end
    if self.mScrollView2:getInnerContainerSize().height ~= innerSize2.height then
	    self.mScrollView2:setInnerContainerSize(innerSize2)
    end 
	
	for i=1,#data2 do
		local activeInfo = data2[i]
		local itemCsb = getResManager():cloneCsbNode(csbFile.TaskItem)
		table.insert(self.mCache2, i, itemCsb)
		self:initRightUIItem(itemCsb, activeInfo)
		local posX = offsetX + self.mTaskItemSize.width/2
		local posY = innerSize2.height - offsetY - (i - 0.5)*self.mTaskItemSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX,posY))
		self.mScrollView2:addChild(itemCsb)
	end
	self.mScrollView2:jumpToTop()

	self:initRightUIAC3()

end

function UISevenCrazy:initRightUIAC3()
	local day = SevenCrazyModel:getToday()
	local info  = getGameOp1(getSevenDayConfByDay(day).OpID3)

	local panel = CsbTools.getChildFromPath(self.mTabPanel, "TabPanel")
	local PPrice =  CsbTools.getChildFromPath(panel, "PPrice")
	local OPrince =  CsbTools.getChildFromPath(panel, "OPrince")

	self.mMoney = math.floor(info.GameOp_price[2]*info.GameOp_priceNew/100)

	PPrice:setString(CommonHelper.getUIString(350)..self.mMoney)
	OPrince:setString(CommonHelper.getUIString(102)..info.GameOp_price[2])
	local temp = 0
	for i=1,4 do
		local itemInfo = info["Goods"..i]
		if table.maxn(itemInfo) == 0 then			
			break
		end
		temp = i
	end

	local name = "Four"
	if temp==1 then
		name = "One"
	elseif temp==2 then
		name = "Two"
	elseif temp==3 then
		name = "Three"
	elseif temp==4 then
		name = "Four"
	elseif temp==5 then
		name = "Five"
	end
	print("temp  name", temp, name)
	CommonHelper.playCsbAnimate(self.mTabPanel, csbFile.TabPanel_1, name, false, nil, true)

	for i=1,temp do
		local button =  CsbTools.getChildFromPath(panel, "AllItem_"..i)

		local itemInfo = info["Goods"..i]

		local propConf = getPropConfItem(itemInfo[1])
        if propConf then
            UIAwardHelper.setAllItemOfConf(button, propConf, itemInfo[2])
            local touchPanel = getChild(button, "MainPanel")
        	self.propTips:addPropTips(touchPanel, propConf)
        end
	end

	local BuyButton =  CsbTools.getChildFromPath(panel, "BuyButton")
	local shopData = SevenCrazyModel:getActiveShopProgress(getSevenDayConfByDay(day).OpID3)
	local buyTimes = shopData.gifts[1].buyTimes
	local maxBuyTimes = shopData.gifts[1].maxBuyTimes

	local isBuy = buyTimes>=maxBuyTimes and true or false
	print("isBuy = buyTimes>=maxBuyTimes", isBuy,buyTimes,maxBuyTimes)
	if isBuy then
		CommonHelper.playCsbAnimate(BuyButton, btnFile, "Grey", false, nil, true)
		local Button_Grey = CsbTools.getChildFromPath(BuyButton, "Button_Grey")
		local Text = CsbTools.getChildFromPath(Button_Grey, "Text")
		Text:setString(CommonHelper.getUIString(625))
	else
		local gem = getGameModel():getUserModel():getDiamond()
		if gem >= self.mMoney  then --钱够
			CommonHelper.playCsbAnimate(BuyButton, btnFile, "Green", false, nil, true)
			local Button_Green = CsbTools.getChildFromPath(BuyButton, "Button_Green")
			CsbTools.initButton(Button_Green, handler(self, self.netbtnCallBack))
			Button_Green:setTag(getSevenDayConfByDay(day).OpID3)
			table.insert(self.itemButton, getSevenDayConfByDay(day).OpID3 , Button_Green)
			local Text = CsbTools.getChildFromPath(Button_Green, "Text")
			Text:setString(CommonHelper.getUIString(626))
		else
			CommonHelper.playCsbAnimate(BuyButton, btnFile, "Orange", false, nil, true)	
			local Button_Orange = CsbTools.getChildFromPath(BuyButton, "Button_Orange")
			CsbTools.initButton(Button_Orange, handler(self, self.congCallBack))
			local Text = CsbTools.getChildFromPath(Button_Orange, "Text")
			Text:setString(CommonHelper.getUIString(627))
		end
	end
end

function UISevenCrazy:initRightUIItem(itemCsb, activeInfo)
	local TaskTips = CsbTools.getChildFromPath(itemCsb, "TabPanel/TaskTips")
	local OverNum = CsbTools.getChildFromPath(itemCsb, "TabPanel/OverNum")
	local BuyButton = CsbTools.getChildFromPath(itemCsb, "TabPanel/BuyButton")
	local tile = CsbTools.getChildFromPath(itemCsb, "TabPanel/BackButton")

	TaskTips:setString(CommonHelper.getUIString(activeInfo.GameOptask_des))
	OverNum:setVisible(true)

	local acData = SevenCrazyModel:getActiveTaskProgress(activeInfo.GameOp_ID, activeInfo.GameOp_taskID)
	if not acData then
		return
	end

	local maxD = acData.value > acData.conditionParam[1] and acData.conditionParam[1] or acData.value
	if acData.finishCondition ==201 then
		OverNum:setString(math.floor(maxD/60).."/"..math.floor(acData.conditionParam[1]/60))
	else
		OverNum:setString(maxD.."/"..acData.conditionParam[1])
	end
	BuyButton:setVisible(true)

	if acData.finishFlag == 1 then
		CommonHelper.playCsbAnimate(BuyButton, btnFile, "Grey", false, nil, true)  --已经领取
		local Button_Grey = CsbTools.getChildFromPath(BuyButton, "Button_Grey")
		local Text = CsbTools.getChildFromPath(Button_Grey, "Text")
		Text:setString(CommonHelper.getUIString(1474))
	else 
		if acData.value>= acData.conditionParam[1] then
			CommonHelper.playCsbAnimate(BuyButton, btnFile, "Green", false, nil, true)  --完成领取显示
			local Button_Green = CsbTools.getChildFromPath(BuyButton, "Button_Green")
			Button_Green:setTag(activeInfo.GameOp_taskID)
			table.insert(self.itemButton, activeInfo.GameOp_taskID, Button_Green)
			CsbTools.initButton(Button_Green, handler(self, self.netbtnCallBack))
			local Text = CsbTools.getChildFromPath(Button_Green, "Text")
			Text:setString(CommonHelper.getUIString(79))
		else 		--未完成 分情况 一种 不显示,一种显示立即前往   
			if #activeInfo.Goto > 0 then
				CommonHelper.playCsbAnimate(BuyButton, btnFile, "Green", false, nil, true)  --完成领取显示
				local Button_Green = CsbTools.getChildFromPath(BuyButton, "Button_Green")
				Button_Green:setTag(activeInfo.GameOp_taskID)
				table.insert(self.itemButton, activeInfo.GameOp_taskID, Button_Green)
				CsbTools.initButton(Button_Green, handler(self, self.netbtnCallBack))
				local Text = CsbTools.getChildFromPath(Button_Green, "Text")
				Text:setString("立即前往")
			else
				CommonHelper.playCsbAnimate(BuyButton, btnFile, "Grey", false, nil, true)  --示达成
				local Button_Grey = CsbTools.getChildFromPath(BuyButton, "Button_Grey")
				local Text = CsbTools.getChildFromPath(Button_Grey, "Text")
				Text:setString("未达成")
			end
		end
	end

	local allData = activeInfo.GameOp_award3
	for i=1,4 do
		local button = CsbTools.getChildFromPath(itemCsb, "TabPanel/AllItem_"..i)
		if i> #allData then
			button:setVisible(false)
		else
			button:setVisible(true)
			local propConf = getPropConfItem(allData[i].ID)
	        if propConf then
	            UIAwardHelper.setAllItemOfConf(button, propConf, allData[i].num)
	            local touchPanel = getChild(button, "MainPanel")
	        	self.propTips:addPropTips(touchPanel, propConf)
	        end
		end
	end
end

function UISevenCrazy:updateRightUi()
	local data = SevenCrazyModel:getToDayData(1)  -- 传这个showpart是只为了找表而已gameop几
	for i=1,#data do
		local activeInfo = data[i]
		local itemCsb = self.mCache1[i]
		self:initRightUIItem(itemCsb, activeInfo)
	end
	self.mScrollView1:jumpToTop()

	local data1 = SevenCrazyModel:getToDayData(2)  -- 传这个showpart是只为了找表而已gameop几
	for i=1,#data1 do
		local activeInfo = data1[i]
		local itemCsb = self.mCache2[i]
		self:initRightUIItem(itemCsb, activeInfo)
	end
	self.mScrollView2:jumpToTop()
end

function UISevenCrazy:updateTopUi()
	for i=1,7  do

 	 	local son = self.mCache3[i]

		local today = SevenCrazyModel:getToday()
		if today > i then
			CommonHelper.playCsbAnimate(son, csbFile.PropItem, "Over", false, nil, true)
		elseif today == i then
			CommonHelper.playCsbAnimate(son, csbFile.PropItem, "On", false, nil, true)
		elseif today < i then
			CommonHelper.playCsbAnimate(son, csbFile.PropItem, "Off", false, nil, true)
		end

	end
end

--------------- 按钮回调 ----------------------
-- 返回
function UISevenCrazy:backBtnCallBack(ref)
	UIManager.close()
end

-- 打开预览 之前的不能打开
function UISevenCrazy:sevenBtnCallBack(ref)
	local tag = ref:getTag()
	print("第"..tag.."天")
	local toDay = SevenCrazyModel:getToday()
	if toDay ==tag then
		return
	elseif toDay > tag then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(394))			--已经结束
		return
	end

	-- 打开预览
	UIManager.open(UIManager.UI.UISevenCrazyView, tag)
end

-- 跳转充值界面
function UISevenCrazy:congCallBack(ref)
	local tag = ref:getTag()
	print("充值")
	self.mIsBuyGem = true

	UIManager.open(UIManager.UI.UIShop, ShopType.DiamondShop)
end

--左边三个标签切换
function UISevenCrazy:threeBtnCallBack(ref)
	local tag = ref:getTag()
	print("第"..tag.."个标签")
	if tag == self.mShowPart then
		return
	end

 	local son = CsbTools.getChildFromPath(self["TabButton_"..self.mShowPart], "TabButton")
 	CommonHelper.playCsbAnimate(son, csbFile.TabButton, "Off", false, nil, true)
	--原来的复原
	self.mShowPart = tag
	-- 新点击的高亮
 	local son = CsbTools.getChildFromPath(self["TabButton_"..self.mShowPart], "TabButton")
 	local day = SevenCrazyModel:getToday()
 	CommonHelper.playCsbAnimate(son, csbFile.TabButton, "On", false, nil, true)

	local info = SevenCrazyModel:getSevenDayConfByDay(SevenCrazyModel:getToday())

	self.curActiveType = self.mShowPart ~=3 and 1 or 2
	self:showParts()

end

-- 发送网络请求, 领取和购买,也会是前往
function UISevenCrazy:netbtnCallBack(ref)
	local tag = ref:getTag()
	local day = SevenCrazyModel:getToday()
	self.mTaskId = 0
	--dump(getSevenDayConfByDay(day))
	if tag ~= getSevenDayConfByDay(day).OpID3 then -- 不是打折礼包 
		print("第"..tag.."个活动的按键")
		self.mTaskId = tag

		local info = SevenCrazyModel:getSevenDayConfByDay(SevenCrazyModel:getToday())
		local allInfo = getGameOp3Data(info["OpID"..self.mShowPart])
		
		local acInfo = SevenCrazyModel:getActiveTaskProgress( info["OpID"..self.mShowPart],tag)
		local count = acInfo.value
		local needCount  = acInfo.conditionParam[1]   --allInfo[tag].GameOp_conditionNum1
		dump(acInfo)
		print("count, needCount",count, needCount)
		if count >= needCount then
			print("发送领取奖励回调 活动ID, 活动任务ID",info["OpID"..self.mShowPart], tag)
		    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, SevenCrazyProtocol.SevenCrazyGetCS)
	 		buffData:writeShort(info["OpID"..self.mShowPart])
	    	buffData:writeChar(tag)
	   		NetHelper.request(buffData)
		else
			print("前往回调 tag", tag)
			local quickToData = allInfo[tag].Goto

			if quickToData[1] == nil then
				return
			end
		    local canQuickTo = true
			if quickToData[1] == 10 then
		        local s = StageHelper.getStageState(quickToData[2], quickToData[3])
		        if s <= StageHelper.StageState.SS_LOCK then
		            canQuickTo = false
		        end
		        if not canQuickTo then
		            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1478), {})
		        else
				    -- 进入关卡
				    UIManager.open(quickToData[1], quickToData[2], quickToData[3], quickToData[4])
		        end
		    elseif quickToData[1] == 200 then
		    	UIManager.open(quickToData[1],true)
			else
				UIManager.open(quickToData[1], quickToData[2], quickToData[3], quickToData[4])
			end
		end
	else
		print("购买")
		local info  = getGameOp1(getSevenDayConfByDay(day).OpID3)
	    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, SevenCrazyProtocol.SevenCrazyGetCS)
	    buffData:writeShort(getSevenDayConfByDay(day).OpID3)
	 	buffData:writeChar(info.GameOpGoodsID)
	 	print("活动ID, 礼包 ID",getSevenDayConfByDay(day).OpID3, info.GameOpGoodsID)
   		NetHelper.request(buffData)
	end
end

-- 接收请求
function UISevenCrazy:acceptGetCmd(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 购买或者领取结果返回")
    local activeID = buffData:readShort()    -- 活动ID
    local paramID = buffData:readChar()     -- 礼包ID/任务ID
    local flag = buffData:readChar()
    if 1 == flag then
        if self.curActiveType == 1 then
            self:getNetCallback(activeID, paramID)
        elseif self.curActiveType == 2 then
            self:buyNetCallback(activeID, paramID)
        end
    else
        print("UIOperateActive Get Error!! flag", flag)
    end
end

-- 购买回调
function UISevenCrazy:buyNetCallback(activeID, paramID)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 购买结果返回activeID, paramID ",activeID, paramID)
	ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -self.mMoney)
	SevenCrazyModel:setActiveShopProgress(activeID,paramID, 1)

	-- 展示所得
	local day = SevenCrazyModel:getToday()
	local info  = getGameOp1(getSevenDayConfByDay(day).OpID3)
	
	local result = {}
	for i=1,4 do
		local itemInfo = info["Goods"..i]
		if #itemInfo==0 then
			break
		end
		local tmep = {}
		tmep.id = itemInfo[1]
		tmep.num = itemInfo[2]
		table.insert(result, tmep)
	end

	UIManager.open(UIManager.UI.UIAward, result)

end

-- 领取回调
function UISevenCrazy:getNetCallback(activeID, paramID)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 领取结果返回")
	local toDayData = getSevenDayConfByDay(SevenCrazyModel:getToday())
	local activeId      = toDayData["OpID"..self.mShowPart]
	Acinfo = getGameOp3Data(activeId)
	local gift = Acinfo[self.mTaskId].GameOp_award3
	local result = {}
	for i=1,#gift do
		local tmep = {}
		tmep.id = gift[i].ID
		tmep.num = gift[i].num
		table.insert(result, tmep)
	end

	UIManager.open(UIManager.UI.UIAward, result)

	print("activeID, self.mTaskId",activeID, self.mTaskId)
	SevenCrazyModel:setActiveTaskFinishFlag(activeID, self.mTaskId, 1)

	RedPointHelper.addCount(RedPointHelper.System.SevenDay, -1, activeID)

    if not self.activitysRedPoint[activeID] then
        print("Error: self.activitysRedPoint[activeID] is nil. activeID", activeID)
        return
    end
    self.activitysRedPoint[activeID] = self.activitysRedPoint[activeID] - 1
    self:showActiveRedPoint(activeID)

end
function UISevenCrazy:showActiveRedPoint(activeID)

    if not self.activitysRedPoint[activeID] or self.activitysRedPoint[activeID] <= 0 then
        self.activitysRedPoint[activeID] = nil
        self.mRedPoint[activeID]:setVisible(false)
    else
        self.mRedPoint[activeID]:setVisible(true)
    end

end

return UISevenCrazy
