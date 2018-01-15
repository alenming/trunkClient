--[[
		佣兵主界面
--]]
require("game.qqHall.QQHallHelper")
local UICommonHall = class("UICommonHall", function()
		return require("common.UIView").new()
	end)

local BlueGemModel = getGameModel():getBlueGemModel()

local csbFile = ResConfig.UICommonHall.Csb2
local btnFile = "ui_new/g_gamehall/o_operate/s_sevenday/TabButton.csb"
local PropTips = require("game.comm.PropTips")

-- 活动ID写死在这里了
local everyDayActId = 4001  --每日领取活动ID
local growActId = 6001
local newPlayerActId = 5001

local lan = {1001,1003,1002}

local lingqu = "领取"
local yulingqu = "已领取"
local weiwanchen = "未完成"
local wufalingqu = "无法领取"


function UICommonHall:ctor()
	-- 初始化UI
	self.rootPath 	= csbFile.root
	self.root 		= getResManager():getCsbNode(self.rootPath)

	self:addChild(self.root)

	self.mIsInit = {everyDayUI = false, newPlayerUI =false, growUI = false}

	--返回按钮
	self.mBackBtn 	= CsbTools.getChildFromPath(self.root, "MainPanel/CloseButton")
	CsbTools.initButton(self.mBackBtn, handler(self, self.backBtnCallBack))

	self.mEveryDayPanel = CsbTools.getChildFromPath(self.root, "MainPanel/GameVipPanel/EveryDayPanel")
	self.mEveryDayPanel:setVisible(false)

	self.mGrowPanel = CsbTools.getChildFromPath(self.root, "MainPanel/GameVipPanel/GrowUpPanel")
	self.mGrowPanel:setVisible(false)

	self.mNewPlayerPanel = CsbTools.getChildFromPath(self.root, "MainPanel/GameVipPanel/NewBiePanel")
	self.mNewPlayerPanel:setVisible(false)

	-- 4个切换按钮
	 for i=1,3 do
 		self["TabButton"..i]= CsbTools.getChildFromPath(self.root, "MainPanel/GameVipPanel/TabButton_"..i)
 		CsbTools.initButton(self["TabButton"..i], handler(self, self.fourBtnCallBack))
 		self["TabButton"..i]:setTag(i)
 		self["TabButtonAni"..i] = CsbTools.getChildFromPath(self["TabButton"..i], "TabButton")
		self["TabButtonRed"..i] = CsbTools.getChildFromPath(self["TabButton"..i], "TabButton/TabButton/RedTipPoint")
		self["TabButtonRed"..i]:setVisible(false)
		self["TabButtonText"..i] = CsbTools.getChildFromPath(self["TabButton"..i], "TabButton/TabButton/Text")
		self["TabButtonText"..i]:setString(getBlueDiamondLanConfItem(lan[i]))
 	end

 	-- 每日部分UI

	-- 成长部分UI
	self.mGrowUpScrollView = CsbTools.getChildFromPath(self.mGrowPanel, "AwardPanel/ScrollView")
	self.mGrowUpScrollView:setScrollBarEnabled(false)
	self.mGrowUpItemSize = {width = 600, height = 100}

	-- 新手部分UI
end


function UICommonHall:onOpen()
	self:showPart(1)

	local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetSC)
	local mCallBack = handler(self, self.acceptGetCmd)
	NetHelper.setResponeHandler(cmd, mCallBack)
	self:updateGrowUpAct()

	self:showRedPoint()
end

function UICommonHall:onClose()
	local cmd = NetHelper.makeCommand(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetSC)
	NetHelper.removeResponeHandler(cmd,handler(self, self.acceptGetCmd))
end

function UICommonHall:onTop()

end

function UICommonHall:refreshUI()
	print("UICommonHall:refreshUI()")
	--BlueGemModel:setActivityById(everyDayActId, 1, 0)
	local Text = CsbTools.getChildFromPath(self.mEveryReceiveButton, "Text")
	Text:setString(lingqu)
	self.mEveryReceiveButton:setTouchEnabled(true)
	self.mEveryReceiveButton:setEnabled(true) 

    self:showRedPoint()
	-- BlueGemModel:setActivityById(newPlayerActId, 1, 0)
	-- local newText = CsbTools.getChildFromPath(self.mNewReceiveButton, "Text")
	-- newText:setString(lingqu)
	-- self.mNewReceiveButton:setTouchEnabled(true)
	-- self.mNewReceiveButton:setEnabled(true)
end

function UICommonHall:updateGrowUpAct()
	local data = getBlueDiamondConfig(growActId)
	for i=1,#data do
		local activeInfo = getBlueDiamondConfig(growActId, i)
		local userLv = getGameModel():getUserModel():getUserLevel()
		local condition = activeInfo.ConditionsType1

		local Text = CsbTools.getChildFromPath(self["GrowUpButton"..i], "Text")
		if userLv >= condition then
			local attrubute = BlueGemModel:getActivityById(growActId, i)
			if attrubute == 0 then   -- 可领取已领取
				Text:setString(lingqu)
				self["GrowUpButton"..i]:setTouchEnabled(true)
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
	end
    self:showRedPoint()
end

function UICommonHall:init()
	self.propTips = PropTips.new()
	self:initEveryDayUI()
	self:initNewPlayerUI()
	self:initGrowUI()
end

function UICommonHall:initEveryDayUI()
	if self.mIsInit.everyDayUI then
		self.mEveryDayPanel:setVisible(true)
		return
	end

	self.mIsInit.everyDayUI = true
	-- init
	local DBImage =  CsbTools.getChildFromPath(self.mEveryDayPanel, "DBImage")
	self.mEveryReceiveButton = CsbTools.getChildFromPath(self.mEveryDayPanel, "AwardPanel/ReceiveButton")
	local Text = CsbTools.getChildFromPath(self.mEveryReceiveButton, "Text")
	local Tips = CsbTools.getChildFromPath(self.mEveryDayPanel, "Tips")
	local TitleText = CsbTools.getChildFromPath(self.mEveryDayPanel, "TitleText")
	local AwardScrollView = CsbTools.getChildFromPath(self.mEveryDayPanel, "AwardPanel/AwardScrollView")

	AwardScrollView:setScrollBarEnabled(false)
	AwardScrollView:removeAllChildren()

	self.mEveryReceiveButton:setTag(everyDayActId*10+1)
	CsbTools.initButton(self.mEveryReceiveButton, handler(self, self.netbtnCallBack))

	local data = getBlueDiamondConfig(everyDayActId, 1)
	local attrubute = BlueGemModel:getActivityById(everyDayActId, 1)

	if attrubute == 0 then   -- 可领取已领取
		Text:setString(lingqu)
		self.mEveryReceiveButton:setTouchEnabled(true)
		self.mEveryReceiveButton:setEnabled(true)
	elseif attrubute == 1 then
		Text:setString(yulingqu)
		self.mEveryReceiveButton:setTouchEnabled(false)
		self.mEveryReceiveButton:setEnabled(false)
	end

	local posX = 100
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(csbFile.AwardItem)
        item:setPosition(posX, 60)
        item:setVisible(true)
        AwardScrollView:addChild(item)

        local AllItem = getChild(item, "AwardItem/AllItem")
        local itemName = getChild(item, "AwardItem/Name")
        local propConf = getPropConfItem(id)
        local touchPanel = getChild(AllItem, "MainPanel")

        if propConf then
            -- 道具图片
            UIAwardHelper.setAllItemOfConf(AllItem, propConf, num)
            -- 道具tips
            self.propTips:addPropTips(touchPanel, propConf)
            local name = CommonHelper.getPropString(propConf.Name)
        	itemName:setString(name)
        end

        local panelWidht = touchPanel:getContentSize().width
        posX = posX  + panelWidht + 60
    end

    for i, id in pairs(data.Reward3) do
        local num = data.Reward3[i].num or 0
        local id = data.Reward3[i].ID or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
end

function UICommonHall:initGrowUI()
	if self.mIsInit.growUI then
		self.mGrowPanel:setVisible(true)
		return
	end

	self.mIsInit.growUI = true
	-- init
	self:initGrowUIScrollView()
end

function UICommonHall:initGrowUIScrollView()

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

function UICommonHall:initGrowUpUIScrollViewItem(itemCsb, activeInfo, index)

	local data = getBlueDiamondConfig(growActId, index)

	self["GrowUpButton"..index] = CsbTools.getChildFromPath(itemCsb, "AwardPanel/ReceiveButton")
	local Text = CsbTools.getChildFromPath(self["GrowUpButton"..index], "Text")

	self["GrowUpButton"..index]:setTag(growActId*10+index)
	CsbTools.initButton(self["GrowUpButton"..index], handler(self, self.netbtnCallBack))

	local userLv = getGameModel():getUserModel():getUserLevel()
	local condition = data.ConditionsType1
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

function UICommonHall:initNewPlayerUI()
	if self.mIsInit.newPlayerUI then
		self.mNewPlayerPanel:setVisible(true)
		return
	end

	self.mIsInit.newPlayerUI = true
	-- init
	local DBImage =  CsbTools.getChildFromPath(self.mNewPlayerPanel, "DBImage")
	self.mNewReceiveButton = CsbTools.getChildFromPath(self.mNewPlayerPanel, "AwardPanel/ReceiveButton")
	local Text = CsbTools.getChildFromPath(self.mNewReceiveButton, "Text")
	local Tips = CsbTools.getChildFromPath(self.mNewPlayerPanel, "Tips")
	local TitleText = CsbTools.getChildFromPath(self.mNewPlayerPanel, "TitleText")
	local AwardScrollView = CsbTools.getChildFromPath(self.mNewPlayerPanel, "AwardPanel/AwardScrollView")

	AwardScrollView:setScrollBarEnabled(false)
	AwardScrollView:removeAllChildren()

	self.mNewReceiveButton:setTag(newPlayerActId*10+1)
	CsbTools.initButton(self.mNewReceiveButton, handler(self, self.netbtnCallBack))

	local data = getBlueDiamondConfig(newPlayerActId, 1)
	local attrubute = BlueGemModel:getActivityById(newPlayerActId, 1)

	if attrubute == 0 then   -- 可领取已领取
		Text:setString(lingqu)
		self.mNewReceiveButton:setTouchEnabled(true)
		self.mNewReceiveButton:setEnabled(true)
	elseif attrubute == 1 then
		Text:setString(yulingqu)
		self.mNewReceiveButton:setTouchEnabled(false)
		self.mNewReceiveButton:setEnabled(false)
	end

	local posX = 75
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(csbFile.AwardItem)
        item:setPosition(posX, 60)
        item:setVisible(true)
        item:setScale(0.8)
        AwardScrollView:addChild(item)

        local AllItem = getChild(item, "AwardItem/AllItem")
        local itemName = getChild(item, "AwardItem/Name")
        local propConf = getPropConfItem(id)
        local touchPanel = getChild(AllItem, "MainPanel")

        if propConf then
            -- 道具图片
            UIAwardHelper.setAllItemOfConf(AllItem, propConf, num)
            -- 道具tips
            self.propTips:addPropTips(touchPanel, propConf)
            local name = CommonHelper.getPropString(propConf.Name)
        	itemName:setString(name)
        end

        local panelWidht = touchPanel:getContentSize().width
        posX = posX  + panelWidht 
    end

    for i, id in pairs(data.Reward3) do
        local num = data.Reward3[i].num or 0
        local id = data.Reward3[i].ID or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
end

function UICommonHall:showPart(part)
	self.mEveryDayPanel:setVisible(false)
	self.mGrowPanel:setVisible(false)
	self.mNewPlayerPanel:setVisible(false)

	for i=1,3 do
		if part == i then
			CommonHelper.playCsbAnimate(self["TabButtonAni"..i], btnFile, "On", false, nil, true)
		else
			CommonHelper.playCsbAnimate(self["TabButtonAni"..i], btnFile, "Off", false, nil, true)
		end
 	end

	if part ==1 then
		self.mEveryDayPanel:setVisible(true)
	elseif part ==2 then
		self.mGrowPanel:setVisible(true)
	elseif part ==3 then
		self.mNewPlayerPanel:setVisible(true)

	end
end


function UICommonHall:showRedPoint()
	local redPoint = BlueGemModel:getRedPointForCommon()
	-- local i = 1
	-- for _,isShow in pairs(redPoint) do
	-- 	self["TabButtonRed"..i]:setVisible(isShow)
	-- 	i = i + 1
	-- end

	self["TabButtonRed"..1]:setVisible(redPoint.everyDay)
	self["TabButtonRed"..2]:setVisible(redPoint.growUp)
	self["TabButtonRed"..3]:setVisible(redPoint.newPlayer)
end

--------------- 按钮回调 ----------------------
function UICommonHall:backBtnCallBack(ref)
	UIManager.close()
end

function UICommonHall:fourBtnCallBack(ref)
	local tag = ref:getTag()
	self:showPart(tag)
end

function UICommonHall:openBlueGem(ref)
	local tag = ref:getTag()
	print("开通蓝钻"..tag)
end

-- 领取按钮回调 发送网络请求
function UICommonHall:netbtnCallBack(ref)
	local tag = ref:getTag()
	local actId = math.floor(tag/10)
	local taskId = tag%10
	print("领取活动id:".. actId.."  任务Id:"..taskId)
    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetCS)
    buffData:writeShort(actId)
    buffData:writeChar(taskId)
    NetHelper.request(buffData)
end

-- 接收请求
function UICommonHall:acceptGetCmd(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 领取结果返回")
    local activeID = buffData:readUShort()    -- 活动ID
    local taskId = buffData:readUChar()     -- 礼包ID/任务ID
    local flag = buffData:readUChar()        -- 领取标记

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
    	local Text = CsbTools.getChildFromPath(self.mEveryReceiveButton, "Text")
    	Text:setString(yulingqu)
    	self.mEveryReceiveButton:setTouchEnabled(false) 
    	self.mEveryReceiveButton:setEnabled(false)
    elseif activeID == growActId then
		local Text = CsbTools.getChildFromPath(self["GrowUpButton"..taskId], "Text")
		Text:setString(yulingqu)
		self["GrowUpButton"..taskId]:setTouchEnabled(false)
		self["GrowUpButton"..taskId]:setEnabled(false)
    elseif activeID == newPlayerActId then
    	local Text = CsbTools.getChildFromPath(self.mNewReceiveButton, "Text")
    	Text:setString(yulingqu)
    	self.mNewReceiveButton:setTouchEnabled(false)
    	self.mNewReceiveButton:setEnabled(false)
    end

    self:showRedPoint()
end



return UICommonHall
