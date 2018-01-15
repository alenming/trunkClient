--[[
		佣兵主界面
--]]
require("game.qqHall.QQHallHelper")
local UIBlueGem = class("UIBlueGem", function()
		return require("common.UIView").new()
	end)

local BlueGemModel = getGameModel():getBlueGemModel()

local csbFile = ResConfig.UIBlueGem.Csb2
local btnFile = "ui_new/g_gamehall/o_operate/t_tencent/TopButton.csb"

local PropTips = require("game.comm.PropTips")
local NewPlayerPanelHelper = require "game.blueGem.NewPlayerPanelHelper"
local IntroPanelHelper = require "game.blueGem.IntroPanelHelper"
local SdkManager = require"common.sdkmanager.SdkManager"

-- 活动ID写死在这里了
local everyDayActId = 1001  --蓝钻贵族每日领取活动ID
local blueGemYearActId =  1009 -- 年费蓝钻每日额外领取活动ID
local haoBlueGemActId = 1010  -- 豪华蓝钻额外领取活动ID
local growActId = 3001
local newPlayerActId = 2001
local introduceActId = 6

local lan = {1001,1003,1002,1004}
local yearLanId = 1005
local haoLanId = 1006

local lingqu = "领取"
local yulingqu = "已领取"
local weiwanchen = "未完成"
local wufalingqu = "无法领取"

function UIBlueGem:ctor()
	-- 初始化UI
	self.rootPath 	= csbFile.root
	self.root 		= getResManager():getCsbNode(self.rootPath)

	self:addChild(self.root)

	self.mIsInit = {everyDayUI = false, newPlayerUI =false, growUI = false, introduceUI = false}

	--返回按钮
	self.mBackBtn 	= CsbTools.getChildFromPath(self.root, "MainPanel/CloseButton")
	CsbTools.initButton(self.mBackBtn, handler(self, self.backBtnCallBack))

	self.mEveryDayPanel = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/EveryDayPanel")
	self.mEveryDayPanel:setVisible(false)

	self.mGrowPanel = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/GrowUpPanel")
	self.mGrowPanel:setVisible(false)

	self.mNewPlayerPanel = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/NewBiePanel")
	self.mNewPlayerPanel:setVisible(false)

	self.mIntroducePanel = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/IntroDayPanel")
	self.mIntroducePanel:setVisible(false)

	-- 4个切换按钮
	 for i=1,4 do
 		self["TobButton"..i]= CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/TobButton"..i)
 		CsbTools.initButton(self["TobButton"..i], handler(self, self.fourBtnCallBack))
 		self["TobButton"..i]:setTag(i)
 		self["TobButtonRed"..i] = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/TobButton"..i.."/TopButton/TabButton/RedTipPoint")
 		self["TobButtonRed"..i]:setVisible(false)
 		self["TobButtonText"..i] = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/TobButton"..i.."/TopButton/TabButton/Text")
 		self["TobButtonText"..i]:setString(getBlueDiamondLanConfItem(lan[i]))
 	end

 	-- title图片
 	self.mTitleSprite = CsbTools.getChildFromPath(self.root, "MainPanel/VipPanel/BarImage/TitleText")
 	self.mOpenVipButton = CsbTools.getChildFromPath(self.root, "MainPanel/OpenVipButton")
	self.mOpenVipYearButton = CsbTools.getChildFromPath(self.root, "MainPanel/OpenVipYearButton")
	self.mOpenVipButton:setTag(1)
	self.mOpenVipYearButton:setTag(2)
	CsbTools.initButton(self.mOpenVipButton, handler(self, self.openBlueGem))
	CsbTools.initButton(self.mOpenVipYearButton, handler(self, self.openBlueGem))
	
 	-- 每日部分UI
	self.mEveryDataScrollView = CsbTools.getChildFromPath(self.mEveryDayPanel, "EveryDayPanel/AwardScrollView")
	self.mEveryDataScrollView:setScrollBarEnabled(false)
	self.mEveryItemSize = {width = 580, height = 64}

	self.mEveryDayYearVipPanel = CsbTools.getChildFromPath(self.mEveryDayPanel, "EveryDayPanel/YearVip_AwradPanel")
	self.mEveryDayHaoVipPanel = CsbTools.getChildFromPath(self.mEveryDayPanel, "EveryDayPanel/LuxuryVip_AwradPanel")

	-- 成长部分UI
	self.mGrowUpScrollView = CsbTools.getChildFromPath(self.mGrowPanel, "EveryDayPanel/AwardScrollView")
	self.mGrowUpScrollView:setScrollBarEnabled(false)
	self.mGrowUpItemSize = {width = 826, height = 100}

	-- 新手部分UI

	-- 介绍部分UI

end

function UIBlueGem:onOpen()
	self:showPart(1)

	local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetSC)
	local mCallBack = handler(self, self.acceptGetCmd)
	NetHelper.setResponeHandler(cmd, mCallBack)

	self:updateGrowUpAct()

	self:showRedPoint()
end

function UIBlueGem:onClose()
	local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetSC)
	NetHelper.removeResponeHandler(cmd,handler(self, self.acceptGetCmd))
end

function UIBlueGem:onTop()

end

function UIBlueGem:refreshUI()
	print("UIBlueGem:refreshUI()")
	local useBlueLv = getGameModel():getUserModel():getBDLv()
	if useBlueLv == 0 then
		return
	end
	--BlueGemModel:setActivityById(everyDayActId, useBlueLv, 0)
	local Text = CsbTools.getChildFromPath(self["EveryDayButton"..useBlueLv], "Text")
	Text:setString(lingqu)
	self["EveryDayButton"..useBlueLv]:setTouchEnabled(true)
	self["EveryDayButton"..useBlueLv]:setEnabled(true)

	local YearText =  CsbTools.getChildFromPath(self.mEveryDayYearVipPanel, "ReceiveButton/Text")
	local HaoText =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "ReceiveButton/Text")
	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	if isBd==1 and isYearBd == 1 then --是年费


		YearText:setString(lingqu)
		self.mBlueYearButton:setTouchEnabled(true)
		self.mBlueYearButton:setEnabled(true)
		HaoText:setString(lingqu)
		self.mBlueHaoButton:setTouchEnabled(true)
		self.mBlueHaoButton:setEnabled(true)
	else
		YearText:setString(wufalingqu)
		self.mBlueYearButton:setTouchEnabled(false)
		self.mBlueYearButton:setEnabled(false)

		HaoText:setString(wufalingqu)
		self.mBlueHaoButton:setTouchEnabled(false)
		self.mBlueHaoButton:setEnabled(false)
	end

	self:showRedPoint()

end

function UIBlueGem:updateGrowUpAct()
	--print("升级了, 这个界面找开了的话要刷新一下那个升级活动的按钮")
    local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
    local data = getBlueDiamondConfig(growActId)

	for i=1,#data do
		local activeInfo = getBlueDiamondConfig(growActId, i)
		local userLv = getGameModel():getUserModel():getUserLevel()
		local condition = activeInfo.ConditionsType1

		local Text = CsbTools.getChildFromPath(self["GrowUpButton"..i], "Text")

        if isBd==1  then
	        local data = getBlueDiamondConfig(growActId)
		    if userLv >= condition then
			    local attrubute = BlueGemModel:getActivityById(growActId, i)
			    if attrubute == 0 then   -- 可领取已领取
				    Text:setString(lingqu)
				    self["GrowUpButton"..i]:setTouchEnabled(true)
				    self["GrowUpButton"..i]:setEnabled(true)
			    elseif(attrubute == 1) then
				    Text:setString(yulingqu)
				    self["GrowUpButton"..i]:setTouchEnabled(false)
				    self["GrowUpButton"..i]:setEnabled(false)
			    end
		    else
			    Text:setString(weiwanchen)
			    self["GrowUpButton"..i]:setTouchEnabled(false)
			    self["GrowUpButton"..i]:setEnabled(false)
		    end
        else
    	    Text:setString(wufalingqu)
		    self["GrowUpButton"..i]:setTouchEnabled(false)
		    self["GrowUpButton"..i]:setEnabled(false)	   
        end
	end

end

function UIBlueGem:init()
	self.propTips = PropTips.new()
	self:initEveryDayUI()
	self:initNewPlayerUI()
	self:initGrowUI()
	self:initIntroduceUI()
end

function UIBlueGem:initEveryDayUI()
	if self.mIsInit.everyDayUI then
		self.mEveryDayPanel:setVisible(true)
		return
	end

	self.mIsInit.everyDayUI = true
	-- init
	self:initEveryDayUIScrollView()
	self:initEveryDayUIBlueYear()
	self:initEveryDayUIBlueHao()
end

function UIBlueGem:initEveryDayUIScrollView()

	self.mEveryDataScrollView:removeAllChildren()

	local data = getBlueDiamondConfig(everyDayActId)

	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5
	local hang = #data
	local innerSize = self.mEveryDataScrollView:getContentSize()

	local h = offsetY + hang*self.mEveryItemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mEveryDataScrollView:getInnerContainerSize().height ~= innerSize.height then
	    self.mEveryDataScrollView:setInnerContainerSize(innerSize)
    end  
	
	for i=1,#data do
		local activeInfo = data[i]
		local itemCsb = getResManager():cloneCsbNode(csbFile.everyDayItem)
		self:initEveryDayUIScrollViewItem(itemCsb, activeInfo, i)
		local posX = offsetX + self.mEveryItemSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mEveryItemSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX,posY))
		self.mEveryDataScrollView:addChild(itemCsb)

	end
	self.mEveryDataScrollView:jumpToTop()
end

function UIBlueGem:initEveryDayUIScrollViewItem(itemCsb, activeInfo, index)
	local VipLogo = CsbTools.getChildFromPath(itemCsb, "AwardPanel/VipLogo")
	
	CsbTools.replaceSprite(VipLogo, "bluediamond_"..(index)..".png") 
	self["EveryDayButton"..index] = CsbTools.getChildFromPath(itemCsb, "AwardPanel/ReceiveButton")
	self["EveryDayButton"..index]:setTag(everyDayActId*10+index)
	CsbTools.initButton(self["EveryDayButton"..index], handler(self, self.netbtnCallBack))

	local Text = CsbTools.getChildFromPath(self["EveryDayButton"..index], "Text")

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)

	local useBlueLv = getGameModel():getUserModel():getBDLv()
	print("useBlueLv"..useBlueLv)
	if isBd==1 and useBlueLv == index then

		local attrubute = BlueGemModel:getActivityById(everyDayActId, index)
		if attrubute == 0 then   -- 可领取已领取
			Text:setString(lingqu)
			self["EveryDayButton"..index]:setTouchEnabled(true)
			self["EveryDayButton"..index]:setEnabled(true)
		elseif attrubute == 1 then
			--todo
			Text:setString(yulingqu)
			self["EveryDayButton"..index]:setTouchEnabled(false)
			self["EveryDayButton"..index]:setEnabled(false)
		end
	elseif isBd==1  then
		Text:setString(lingqu)
		self["EveryDayButton"..index]:setTouchEnabled(false)
		self["EveryDayButton"..index]:setEnabled(false)
	elseif isBd~=1 then
		Text:setString(wufalingqu)
		self["EveryDayButton"..index]:setTouchEnabled(false)
		self["EveryDayButton"..index]:setEnabled(false)
	end

	local AwardPanel = CsbTools.getChildFromPath(itemCsb, "AwardPanel/AwardPanel")

	local posX = 40
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(ResConfig.UIOperateActive.Csb2.awardItem)
  		item:setPosition(posX, 30)
        item:setVisible(true)
        AwardPanel:addChild(item)

        local panel = getChild(item, "TaskAwradPanel")

        local propConf = getPropConfItem(id)
        if propConf then
            -- 道具图片
            local allItem = getChild(panel, "Award1")
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        end

        -- 道具数量
        local propNumLab = getChild(panel, "Award1_Num")
       
        propNumLab:setString("x"..num)
        propNumLab:setTextColor(display.COLOR_WHITE)
        local panelWidht = panel:getContentSize().width
        local lableWidth = propNumLab:getContentSize().width
        posX = posX + lableWidth + panelWidht
    end

    for i, id in pairs(activeInfo.Reward3) do
        local num = activeInfo.Reward3[i].num or 0
        local id = activeInfo.Reward3[i].ID or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
end

function UIBlueGem:initEveryDayUIBlueYear()
	local AllItem = CsbTools.getChildFromPath(self.mEveryDayYearVipPanel, "AllItem")
	local data = getBlueDiamondConfig(blueGemYearActId, 1)

	local propConf = getPropConfItem(data.Reward3[1].ID)
   	if propConf then
        UIAwardHelper.setAllItemOfConf(AllItem, propConf, data.Reward3[1].num)
        local touchPanel = getChild(AllItem, "MainPanel")
    	self.propTips:addPropTips(touchPanel, propConf)
    end

	self.mBlueYearButton =  CsbTools.getChildFromPath(self.mEveryDayYearVipPanel, "ReceiveButton")
	self.mBlueYearButton:setTag(blueGemYearActId*10 + 1)
	CsbTools.initButton(self.mBlueYearButton, handler(self, self.netbtnCallBack))

	local Text =  CsbTools.getChildFromPath(self.mEveryDayYearVipPanel, "ReceiveButton/Text")

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	if isBd==1 and isYearBd == 1 then --是年费
		local attrubute = BlueGemModel:getActivityById(blueGemYearActId, 1)
		if attrubute == 0 then   -- 可领取已领取
			Text:setString(lingqu)
			self.mBlueYearButton:setTouchEnabled(true)
			self.mBlueYearButton:setEnabled(true)
		elseif attrubute == 1 then 
			Text:setString(yulingqu)
			self.mBlueYearButton:setTouchEnabled(false)
			self.mBlueYearButton:setEnabled(false)
		end
	else
		Text:setString(wufalingqu)
		self.mBlueYearButton:setTouchEnabled(false)
		self.mBlueYearButton:setEnabled(false)
	end

	local ItemName =  CsbTools.getChildFromPath(self.mEveryDayYearVipPanel, "ItemName")
	local name = CommonHelper.getPropString(propConf.Name)
	ItemName:setString(name and name or "")

	local TipsText =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "TipsText")
	TipsText:setString(getBlueDiamondLanConfItem(yearLanId))
end

function UIBlueGem:initEveryDayUIBlueHao()
	local AllItem = CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "AllItem")
	local data = getBlueDiamondConfig(haoBlueGemActId, 1)

	local propConf = getPropConfItem(data.Reward3[1].ID)
   	if propConf then
        UIAwardHelper.setAllItemOfConf(AllItem, propConf, data.Reward3[1].num)
        local touchPanel = getChild(AllItem, "MainPanel")
    	self.propTips:addPropTips(touchPanel, propConf)
    end

	self.mBlueHaoButton =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "ReceiveButton")
	self.mBlueHaoButton:setTag(haoBlueGemActId*10+1)
	CsbTools.initButton(self.mBlueHaoButton, handler(self, self.netbtnCallBack))

	local Text =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "ReceiveButton/Text")

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	if isBd==1 and isHaoBd == 1 then --是年费
	local attrubute = BlueGemModel:getActivityById(haoBlueGemActId, 1)
		if attrubute == 0 then   -- 可领取已领取
			Text:setString(lingqu)
			self.mBlueHaoButton:setTouchEnabled(true)
			self.mBlueHaoButton:setEnabled(true)
		elseif attrubute == 1 then 
			Text:setString(yulingqu)
			self.mBlueHaoButton:setTouchEnabled(false)
			self.mBlueHaoButton:setEnabled(false)
		end
	else
		Text:setString(wufalingqu)
		self.mBlueHaoButton:setTouchEnabled(false)
		self.mBlueHaoButton:setEnabled(false)
	end

	local ItemName =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "ItemName")
	local name = CommonHelper.getPropString(propConf.Name)
	ItemName:setString(name and name or "")



	local TipsText =  CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "TipsText")
	TipsText:setString(getBlueDiamondLanConfItem(haoLanId))
	--获取玩家的蓝钻等级
	local TencentVipLogo = CsbTools.getChildFromPath(self.mEveryDayHaoVipPanel, "TencentVipLogo")
	--CsbTools.replaceSprite(TencentVipLogo, "bluediamond_"..(5)..".png") 
end

function UIBlueGem:initGrowUI()
	if self.mIsInit.growUI then
		self.mGrowPanel:setVisible(true)
		return
	end

	self.mIsInit.growUI = true
	-- init
	self:initGrowUIScrollView()
end

function UIBlueGem:initGrowUIScrollView()

	self.mGrowUpScrollView:removeAllChildren()

	local data = getBlueDiamondConfig(growActId)

	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5
	local hang = #data
	local innerSize = self.mGrowUpScrollView:getContentSize()

	local h = offsetY + hang*self.mGrowUpItemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mGrowUpScrollView:getInnerContainerSize().height ~= innerSize.height then
	    self.mGrowUpScrollView:setInnerContainerSize(innerSize)
    end  
	
	for i=1,#data do
		local activeInfo = data[i]
		local itemCsb = getResManager():cloneCsbNode(csbFile.growUpItem)
		self:initGrowUpUIScrollViewItem(itemCsb, activeInfo, i)
		local posX = offsetX + self.mGrowUpItemSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mGrowUpItemSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX,posY))
		self.mGrowUpScrollView:addChild(itemCsb)

	end
	self.mGrowUpScrollView:jumpToTop()
end

function UIBlueGem:initGrowUpUIScrollViewItem(itemCsb, activeInfo, index)

	local data = getBlueDiamondConfig(growActId, index)

	self["GrowUpButton"..index] = CsbTools.getChildFromPath(itemCsb, "AwardPanel/ReceiveButton")
	local Text = CsbTools.getChildFromPath(self["GrowUpButton"..index], "Text")

	self["GrowUpButton"..index]:setTag(growActId*10+index)
	CsbTools.initButton(self["GrowUpButton"..index], handler(self, self.netbtnCallBack))

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	local condition = data.ConditionsType1
	if isBd==1  then
		local userLv = getGameModel():getUserModel():getUserLevel()
		if userLv >= condition then
			local attrubute = BlueGemModel:getActivityById(growActId, index)
			if attrubute == 0 then   -- 可领取已领取
				Text:setString(lingqu)
				self["GrowUpButton"..index]:setTouchEnabled(true)
	            self["GrowUpButton"..index]:setEnabled(true)
			elseif(attrubute == 1) then
				Text:setString(yulingqu)
				self["GrowUpButton"..index]:setTouchEnabled(false)
				self["GrowUpButton"..index]:setEnabled(false)
			end
		else
			Text:setString(weiwanchen)
			self["GrowUpButton"..index]:setTouchEnabled(false)
			self["GrowUpButton"..index]:setEnabled(false)
		end
	else
		Text:setString(wufalingqu)
		self["GrowUpButton"..index]:setTouchEnabled(false)
		self["GrowUpButton"..index]:setEnabled(false)
	end
	
	local Level = CsbTools.getChildFromPath(itemCsb, "AwardPanel/Level")
	Level:setString("Lv"..condition)

	local AwardPanel = CsbTools.getChildFromPath(itemCsb, "AwardPanel/AwardPanel")

	local posX = 40
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(ResConfig.UIBlueGem.Csb2.awardItem)
        item:setScale(0.9)
        item:setPosition(posX, 45)
        item:setVisible(true)
        AwardPanel:addChild(item)

        local propConf = getPropConfItem(id)
        local touchPanel = getChild(item, "MainPanel")

        if propConf then
            -- 道具图片
            UIAwardHelper.setAllItemOfConf(item, propConf, num)
            -- 道具tips
            self.propTips:addPropTips(touchPanel, propConf)
        end

        local panelWidht = touchPanel:getContentSize().width
        posX = posX  + panelWidht
    end

    for i, id in pairs(activeInfo.Reward3) do
        local num = activeInfo.Reward3[i].num or 0
        local id = activeInfo.Reward3[i].ID or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
end

function UIBlueGem:initNewPlayerUI()
	if self.mIsInit.newPlayerUI then
		self.mNewPlayerPanel:setVisible(true)
		NewPlayerPanelHelper.init(self.mNewPlayerPanel)
		return
	end

	self.mIsInit.newPlayerUI = true
	-- init

end

function UIBlueGem:initIntroduceUI()
	if self.mIsInit.introduceUI then
		self.mIntroducePanel:setVisible(true)
		IntroPanelHelper.init(self.mIntroducePanel)
		return
	end

	self.mIsInit.introduceUI = true
	-- init
end

function UIBlueGem:showPart(part)
	self.mEveryDayPanel:setVisible(false)
	self.mGrowPanel:setVisible(false)
	self.mNewPlayerPanel:setVisible(false)
	self.mIntroducePanel:setVisible(false)
	for i=1,4 do
		if part == i then
			CommonHelper.playCsbAnimate(self["TobButton"..i], btnFile, "On", false, nil, true)
		else
			CommonHelper.playCsbAnimate(self["TobButton"..i], btnFile, "Off", false, nil, true)
		end
 	end

	if part ==1 then
		self.mEveryDayPanel:setVisible(true)
	elseif part ==2 then
		self.mGrowPanel:setVisible(true)
	elseif part ==3 then
		self.mNewPlayerPanel:setVisible(true)
		NewPlayerPanelHelper.init(self.mNewPlayerPanel)
	elseif part ==4 then
		self.mIntroducePanel:setVisible(true)
		IntroPanelHelper.init(self.mIntroducePanel)
	end
end

function UIBlueGem:showRedPoint()
	local redPoint = BlueGemModel:getRedPointForBlueGem()
	-- local i = 1
	-- for _,isShow in pairs(redPoint) do
	-- 	self["TobButtonRed"..i]:setVisible(isShow)
	-- 	i = i + 1
	-- end

	self["TobButtonRed"..1]:setVisible(redPoint.everyDay)
	self["TobButtonRed"..2]:setVisible(redPoint.growUp)
	self["TobButtonRed"..3]:setVisible(redPoint.newPlayer)
end


--------------- 按钮回调 ----------------------

function UIBlueGem:backBtnCallBack(ref)
	UIManager.close()
end

function UIBlueGem:fourBtnCallBack(ref)
	local tag = ref:getTag()
	self:showPart(tag)
end

function UIBlueGem:openBlueGem(ref)
	local tag = ref:getTag()
	print("开通蓝钻"..tag)
	SdkManager:openVip()
end

-- 领取按钮回调 发送网络请求
function UIBlueGem:netbtnCallBack(ref)
	local tag = ref:getTag()
	local actId = math.floor(tag/10)
	local taskId = tag%10
	print("领取活动id:".. actId.."  任务Id:"..taskId)

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	print("是不是蓝钻:"..isBd)
	
    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetCS)
    buffData:writeShort(actId)
    buffData:writeChar(taskId)
    NetHelper.request(buffData)
end

-- 接收请求
function UIBlueGem:acceptGetCmd(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 领取结果返回")
    local activeID = buffData:readUShort()    -- 活动ID
    local taskId = buffData:readUChar()     -- 礼包ID/任务ID
    local flag = buffData:readUChar()        -- 领取标记
    print("activeID, taskId,flag",activeID, taskId, flag)
	BlueGemModel:setActivityById(activeID, taskId, flag)
	--获取道具
	local data = getBlueDiamondConfig(activeID, taskId)

	local result = {}
	for i=1,#data.Reward3 do
		local itemInfo = data.Reward3[i]
		local tmep = {}
		tmep.id = itemInfo.ID
		tmep.num = itemInfo.num
		table.insert(result, tmep)
	end

	UIManager.open(UIManager.UI.UIAward, result)
    --刷新UI
    if activeID == everyDayActId then
       	self["EveryDayButton"..taskId]:setTouchEnabled(false) 	
    	self["EveryDayButton"..taskId]:setEnabled(false)
    	local Text = CsbTools.getChildFromPath(self["EveryDayButton"..taskId], "Text")
    	Text:setString(yulingqu)
    elseif activeID == blueGemYearActId then
    	self.mBlueYearButton:setTouchEnabled(false) 
    	self.mBlueYearButton:setEnabled(false)
    	local Text = CsbTools.getChildFromPath(self.mBlueYearButton, "Text")
    	Text:setString(yulingqu)
    elseif activeID == haoBlueGemActId then
    	self.mBlueHaoButton:setTouchEnabled(false) 
    	self.mBlueHaoButton:setEnabled(false)
    	local Text = CsbTools.getChildFromPath(self.mBlueHaoButton, "Text")
    	Text:setString(yulingqu)
    elseif activeID == growActId then
    	self["GrowUpButton"..taskId]:setTouchEnabled(false)
    	self["GrowUpButton"..taskId]:setEnabled(false)
    	local Text = CsbTools.getChildFromPath(self["GrowUpButton"..taskId], "Text")
    	Text:setString(yulingqu)
    elseif activeID == newPlayerActId then
    	NewPlayerPanelHelper.init(self.mNewPlayerPanel)
    end

    self:showRedPoint()
end



return UIBlueGem
