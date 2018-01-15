--[[
		佣兵主界面
--]]
local UIUnionMercenary = class("UIUnionMercenary", require("common.UIView"))
local scheduler = require("framework.scheduler")
local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()
local btnCallBackType = {
			mMyMercenaryBtn = 1,
			mAllMercenaryBtn = 2
}
local btnFile = "ui_new/g_gamehall/b_bag/AllButton.csb"
local starFile = "ui_new/g_gamehall/c_card/HeroStar_S.csb"

local M_LEFT = 1
local M_RIGHT = 2

local function restTime(time)
    local cur = getGameModel():getNow()
    --print("cur", cur)
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

function UIUnionMercenary:ctor()
	self.isDebug = false
	-- 初始化UI
	self.rootPath 	= ResConfig.UIUnionMercenary.Csb2.root
	self.root 		= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.frashItem = {}				-- 两个派遣的ITEM
	self.cardsInfo = {}

	self.curDyId		= 0	 		-- 当前点击的是哪个佣兵

	-- 返回按钮
	self.mBackBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(self.mBackBtn, handler(self, self.backBtnCallBack))

	-- 金币
	self.mGoldCount = CsbTools.getChildFromPath(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
	--钻石
	self.mGemCount = CsbTools.getChildFromPath(self.root, "GemInfo/GemPanel/GemCountLabel")


	self.mTabButton_1 = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_1")
	self.mTabButton_2 = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_2")

    self.mTabButton_1.myType = btnCallBackType.mAllMercenaryBtn
    self.mTabButton_2.myType = btnCallBackType.mMyMercenaryBtn
    local btnCsb1 = CsbTools.getChildFromPath(self.mTabButton_1, "AllButton")
	local btnCsb2 = CsbTools.getChildFromPath(self.mTabButton_2, "AllButton")

    CommonHelper.playCsbAnimate(btnCsb1, btnFile, "On", false, nil, true)
    CommonHelper.playCsbAnimate(btnCsb2, btnFile, "Normal", false, nil, true)

    local myMercenaryLabel = CsbTools.getChildFromPath(btnCsb2, "ButtonPanel/NameLabel")

	CsbTools.initButton(self.mTabButton_1, handler(self, self.btnCallBack))
	CsbTools.initButton(self.mTabButton_2, handler(self, self.btnCallBack), CommonHelper.getUIString(1951), myMercenaryLabel, "AllButton")

	CsbTools.getChildFromPath(btnCsb1, "RedTipPoint"):setVisible(false)
	CsbTools.getChildFromPath(btnCsb2, "RedTipPoint"):setVisible(false)

	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/CardScrollView")
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()
	self.scroll:setVisible(false)

	self.scrollme = self.scroll:clone()
	self.scrollme:setScrollBarEnabled(false)
	self.scrollme:removeAllChildren()
	self.scrollme:setVisible(false)
	self.scrollme:setPosition(self.scroll:getPosition())

	 CsbTools.getChildFromPath(self.root, "MainPanel"):addChild(self.scrollme,99)

	self.mTips = CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel")
	self.mTips:setString(CommonHelper.getUIString(1993))
	self.mTips:setVisible(false)

	self.mGuildTips = CsbTools.getChildFromPath(self.root, "MainPanel/QuestionButton")
	CsbTools.initButton(self.mGuildTips, handler(self, self.questionTipCallBack))

	-- item的size
	local itemCsb 	= getResManager():getCsbNode(ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Guild)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "BarPanel"):getContentSize()

	local itemCsb1 	= getResManager():getCsbNode(ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self)
	self.itemSize1	= CsbTools.getChildFromPath(itemCsb1, "BarPanel"):getContentSize()
end

function UIUnionMercenary:onOpen()
		self.openTime = getGameModel():getNow()
		self:getData()
		if #self.cardsInfo == 0 then
			self:IsHasCard(false)
		else
			self:IsHasCard(true)
		end
		self:initUI()
		self:refreshCommonUI(M_LEFT)

		self.scrollme:jumpToTop()
		self.scroll:jumpToTop()
end

function UIUnionMercenary:onClose()
	-- 删除自己不能召回时的
	local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryCallSC)
	NetHelper.removeResponeHandler(cmd,handler(self, self.dontCallBack))
	-- 删除请求详细信息的
	local cmd1 = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryGetSC)
	NetHelper.removeResponeHandler(cmd,handler(self, self.getMercenaryAllInfo))
	if self.surplusTimeSheduler then
		scheduler.unscheduleGlobal(self.surplusTimeSheduler)
		self.surplusTimeSheduler = nil
	end
end

function UIUnionMercenary:onTop()
end

function UIUnionMercenary:IsHasCard(isHasCard)
	if isHasCard then
	    self.mTips:setVisible(false)
	else
		self.mTips:setVisible(true)
	end
end

function UIUnionMercenary:getData()
	self.cardsInfo = UnionMercenaryModel:getUnionMercenarysSimpleInfo()
end

function UIUnionMercenary:initUI()
	self:initUnionUI()
	self:initMyselfUI()
end

function UIUnionMercenary:initUnionUI()
	self.scroll:removeAllChildren()
    self.scroll:setVisible(true)
	self.scrollme:setVisible(false)
	if #self.cardsInfo == 0 then
		self.scroll:setInnerContainerSize(self.scroll:getContentSize())
		return
	end
	local itemPlace = {}
	local hang = 0
	local lie = 5
	local isFrag = false
	for _,_ in pairs(self.cardsInfo) do
		if lie == 5 then
				hang = hang + 1
				lie = 1
		else
				lie = lie + 1
		end
		table.insert(itemPlace, {hang = hang, lie = lie})
	end

	local intervalX = 9
	local intervalY = 10
	local offsetX = 5
	local offsetY = 15
	local innerSize = self.scroll:getContentSize()
	--算scrollview高的大小
	local hang = itemPlace[#itemPlace].hang

	local h = offsetY + hang*self.itemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.scroll:getInnerContainerSize().height ~= innerSize.height then
	    self.scroll:setInnerContainerSize(innerSize)
    end      

	for i=1, #self.cardsInfo do
		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local posX = offsetX + (lie - 0.5)* self.itemSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.itemSize.height - (hang - 1)*intervalY

		self:addItem(self.cardsInfo[i], cc.p(posX, posY), i)
	end
end

function UIUnionMercenary:addItem(info, pos, tag)
	local item = nil

	item = ccui.Button:create()
	item:setTouchEnabled(true)
	item:setScale9Enabled(true)
	item:setContentSize(self.itemSize)
	CsbTools.initButton(item, handler(self, self.cardTouchCallBack))
	self.scroll:addChild(item)
	local itemCsb = getResManager():cloneCsbNode(ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Guild)
    CsbTools.getChildFromPath(itemCsb, "BarPanel/TencentLogo"):setVisible(false)
	itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
	item:addChild(itemCsb)	

	item:setPosition(pos)
	item:setTag(tag)

	local callBtnName = CsbTools.getChildFromPath(itemCsb, "BarPanel/Name")
	callBtnName:setString(info.userName)
	
	local cardCsb = CsbTools.getChildFromPath(itemCsb, "BarPanel/HeroCard")

	self:initCard(cardCsb, info)
end

function UIUnionMercenary:initMyselfUI()
	self.scrollme:removeAllChildren()
	local intervalX = 10
	local intervalY = 37
	local offsetX = 4
	local offsetY = 28
	local innerSize = self.scrollme:getContentSize()

	local count = UnionMercenaryModel:getMecenartyCount()

	local hang = count

	local h = offsetY + hang*self.itemSize1.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.scrollme:getInnerContainerSize().height ~= innerSize.height then
	    self.scrollme:setInnerContainerSize(innerSize)
    end      


	self.frashItem = {}

	for i=1, count do
		local posX = offsetX + self.itemSize1.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.itemSize1.height - (i - 1)*intervalY

		local itemCsb = getResManager():cloneCsbNode(ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self)
		self.frashItem[i] = itemCsb
		self:addItemToMe(itemCsb, cc.p(posX, posY), i)
	end

	self.surplusTimeSheduler = scheduler.scheduleGlobal(handler(self, self.update), 1)
end

function UIUnionMercenary:addItemToMe(itemCsb, pos, tag)
		
		local SendButton = CsbTools.getChildFromPath(itemCsb, "BarPanel/SendButton")
		SendButton:setTag(tag)
		CsbTools.initButton(SendButton, handler(self, self.sendHeroButonCallBack))

		local CallBackButton = CsbTools.getChildFromPath(itemCsb, "BarPanel/CallBackButton")
		CallBackButton:setTag(tag)
		CsbTools.initButton(CallBackButton, handler(self, self.callBackHeroButonCallBack))
		
		local sonButton = CsbTools.getChildFromPath(SendButton, "SendButton")
		local VipLevel = CsbTools.getChildFromPath(sonButton, "SendButton/VipLevel")

		local heroId = 0

		local allInfo = UnionMercenaryModel:getMyselfInfoByTag(tag)
		local dyId =  allInfo.dyId
		print("从佣兵模型拿出来的自己派遣 出去的信息dyId", dyId)
		local allinfo = {}
		if dyId ~= 0 then
			allinfo =  UnionMercenaryModel:getUnionMercenaryByDyId(dyId)
			heroId = allinfo.heroId
			dump(allinfo)
		end

		--没有VIP这个东西
		if VipLevel then
			VipLevel:setVisible(false)
		end

		self:initMyselfItem(itemCsb, heroId, tag)
		itemCsb:setPosition(pos)
		self.scrollme:addChild(itemCsb)
end

function UIUnionMercenary:initMyselfItem(itemCsb, heroId, tag)
	local SendButton = CsbTools.getChildFromPath(itemCsb, "BarPanel/SendButton")
	if heroId ~= 0  then
		CommonHelper.playCsbAnimate(itemCsb, ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self, "Normal", false, nil, true)
		SendButton:setEnabled(false)
		SendButton:setTouchEnabled(false)

		local GoldNum =  CsbTools.getChildFromPath(itemCsb, "BarPanel/GoldNum")
		local Time =  CsbTools.getChildFromPath(itemCsb, "BarPanel/Time")

		local myMercenaryInfo = UnionMercenaryModel:getMyselfInfoByTag(tag)

		GoldNum:setString(myMercenaryInfo.money)				--收益

		local nowTime = restTime(myMercenaryInfo.time)
		Time:setString(string.format(CommonHelper.getUIString(2039), nowTime.day, nowTime.hour, nowTime.min, nowTime.sec)) --时间

		--local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
		local dyId = UnionMercenaryModel:getMyselfInfoByTag(tag).dyId
		local menacenaryInfo =  UnionMercenaryModel:getUnionMercenaryByDyId(dyId)

		local upRateConf = getSoldierUpRateConfItem(heroId)
		local star = upRateConf.DefaultStar
		if menacenaryInfo and menacenaryInfo.heroStar ~= 0 then
			star = menacenaryInfo.heroStar
		end
		local heroConf = getSoldierConfItem(heroId, star)

		-- 初始化固定属性, 及默认属性
		local info = {
			heroId = heroId,
			defaultStar = upRateConf.DefaultStar,
			topStar = TopStar,
			icon = heroConf.Common.HeadIcon,
			cost = heroConf.Cost,
			race = heroConf.Common.Race,
			job = heroConf.Common.Vocation,
			frag = menacenaryInfo.callFrag,
			lv = menacenaryInfo.heroLv,
			star = menacenaryInfo.heroStar,
			rare = heroConf.Rare
		}
		local HeroCard = CsbTools.getChildFromPath(itemCsb, "BarPanel/HeroCard")
		self:initCard(HeroCard, info)

	else
		SendButton:setEnabled(true)
		SendButton:setTouchEnabled(true)
		CommonHelper.playCsbAnimate(itemCsb, ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self, "Send", false, nil, true)
	end
end

function UIUnionMercenary:initCard(itemCsb, info)
	local lvLab = CsbTools.getChildFromPath(itemCsb, "HeroCard/Level")
	local costLab = CsbTools.getChildFromPath(itemCsb, "HeroCard/GemSum")
	local jobImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/Profesion")
	local jobBgImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/ProfesionBar")
	local raceImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/RaceImage")
	local frameImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/LvImage")
	local iconImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/HeroImage")
	local starCsb = CsbTools.getChildFromPath(itemCsb, "HeroCard/Star")
	local lvImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/LvBar")
	--佣兵LOGO
	local MercenaryLogo = CsbTools.getChildFromPath(itemCsb, "HeroCard/MercenaryLogo")
	MercenaryLogo:setVisible(true)

	lvLab:setString(info.lv)
	costLab:setString(info.cost)
	CsbTools.replaceSprite(jobImg, IconHelper.getSoldierJobIcon(info.star, info.job))
	CsbTools.replaceSprite(jobBgImg, IconHelper.getSoldierJobIconCircle(info.rare))
	CsbTools.replaceImg(lvImg, IconHelper.getCardLevelBorder(info.rare))
	CsbTools.replaceImg(raceImg, getIconSettingConfItem().RaceIcon[info.race])
	CsbTools.replaceImg(frameImg, IconHelper.getSoldierBigHeadFrame(info.rare))
	CsbTools.replaceImg(iconImg, info.icon)

	CommonHelper.playCsbAnimate(itemCsb, ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Guild, "Normal", false, nil, true)
	CommonHelper.playCsbAnimate(starCsb, starFile, "Star" .. info.star, false, nil, true)
end

function UIUnionMercenary:refreshCommonUI(leftAndRight)
	local btnCsb1 = CsbTools.getChildFromPath(self.mTabButton_1, "AllButton")
	local btnCsb2 = CsbTools.getChildFromPath(self.mTabButton_2, "AllButton")

	if leftAndRight == M_LEFT then
		CommonHelper.playCsbAnimate(btnCsb1, btnFile, "OnAnimation", false, nil, true)
   		CommonHelper.playCsbAnimate(btnCsb2, btnFile, "Normal", false, nil, true)
		self.mTabButton_1:setLocalZOrder(10)
		self.mTabButton_2:setLocalZOrder(-10)
	elseif leftAndRight == M_RIGHT then
		CommonHelper.playCsbAnimate(btnCsb1, btnFile, "Normal", false, nil, true)
    	CommonHelper.playCsbAnimate(btnCsb2, btnFile, "OnAnimation", false, nil, true)
		self.mTabButton_1:setLocalZOrder(-10)
		self.mTabButton_2:setLocalZOrder(10)
	end

	self.mGoldCount:setString(getGameModel():getUserModel():getGold())
	self.mGemCount:setString(getGameModel():getUserModel():getDiamond())
end

function UIUnionMercenary:refreshUnion()
    self.scroll:setVisible(true)
	self.scrollme:setVisible(false)
end

function UIUnionMercenary:refreshScrollView()
	self:getData()
	if #self.cardsInfo == 0 then
		self:IsHasCard(false)
	else
		self:IsHasCard(true)
	end
	self.scroll:removeAllChildren()
	if #self.cardsInfo == 0 then
		self.scroll:setInnerContainerSize(self.scroll:getContentSize())
		return
	end

	local itemPlace = {}
	local hang = 0
	local lie = 5
	local isFrag = false
	for _,_ in pairs(self.cardsInfo) do
		if lie == 5 then
				hang = hang + 1
				lie = 1
		else
				lie = lie + 1
		end
		table.insert(itemPlace, {hang = hang, lie = lie})
	end

	local intervalX = 9
	local intervalY = 10
	local offsetX = 5
	local offsetY = 15
	local innerSize = self.scroll:getContentSize()
	--算scrollview高的大小
	local hang = itemPlace[#itemPlace].hang

	local h = offsetY + hang*self.itemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.scroll:getInnerContainerSize().height ~= innerSize.height then
	    self.scroll:setInnerContainerSize(innerSize)
    end      

	for i=1, #self.cardsInfo do
		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local posX = offsetX + (lie - 0.5)* self.itemSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.itemSize.height - (hang - 1)*intervalY
		local item = nil

		local item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.itemSize)
		CsbTools.initButton(item, handler(self, self.cardTouchCallBack))
		local itemCsb = getResManager():cloneCsbNode(ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Guild)
		itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
		item:addChild(itemCsb)
		self.scroll:addChild(item)

		item:setPosition(cc.p(posX, posY))
		item:setTag(i)

		local callBtnName = CsbTools.getChildFromPath(itemCsb, "BarPanel/Name")
		callBtnName:setString(self.cardsInfo[i].userName)
		
		local cardCsb = CsbTools.getChildFromPath(itemCsb, "BarPanel/HeroCard")
		self:initCard(cardCsb, self.cardsInfo[i])
	end
end

function UIUnionMercenary:refreshMe()
	self.scroll:setVisible(false)
	self.scrollme:setVisible(true)
end

function UIUnionMercenary:refreshMeItem(tag, heroId)
	self.scroll:setVisible(false)
	self.scrollme:setVisible(true)

	local itemCsb = self.frashItem[tag]
	if not itemCsb then
		print("这个item不见啦 ")
		return
	end

	local SendButton = CsbTools.getChildFromPath(itemCsb, "BarPanel/SendButton")
	if heroId ~= 0  then
		CommonHelper.playCsbAnimate(itemCsb, ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self, "Normal", false, nil, true)
		SendButton:setEnabled(false)
		SendButton:setTouchEnabled(false)

		local GoldNum =  CsbTools.getChildFromPath(itemCsb, "BarPanel/GoldNum")
		local Time =  CsbTools.getChildFromPath(itemCsb, "BarPanel/Time")

		local allInfo = UnionMercenaryModel:getMyselfInfoByTag(tag)
		GoldNum:setString(allInfo.money)				--收益

		local nowTime = restTime(allInfo.time)
		Time:setString(string.format(CommonHelper.getUIString(2039),nowTime.day, nowTime.hour, nowTime.min, nowTime.sec))			--时间

		 local dyId = UnionMercenaryModel:getMyselfInfoByTag(tag).dyId
		local heroModel = UnionMercenaryModel:getUnionMercenaryByDyId(dyId)

		local upRateConf = getSoldierUpRateConfItem(heroId)
		local star = upRateConf.DefaultStar
		if heroModel and heroModel.heroStar ~= 0 then
			star = heroModel.heroStar
		end
		local heroConf = getSoldierConfItem(heroId, star)

		-- 初始化固定属性, 及默认属性
		local info = {
			heroId = heroId,
			defaultStar = upRateConf.DefaultStar,
			topStar = TopStar,
			icon = heroConf.Common.HeadIcon,
			cost = heroConf.Cost,
			race = heroConf.Common.Race,
			job = heroConf.Common.Vocation,
			frag = heroModel.callFrag,
			lv = heroModel.heroLv,
			star = heroModel.heroStar,
			rare = heroConf.Rare
		}
		local HeroCard = CsbTools.getChildFromPath(itemCsb, "BarPanel/HeroCard")
		self:initCard(HeroCard, info)

	else
		SendButton:setEnabled(true)
		SendButton:setTouchEnabled(true)
		CommonHelper.playCsbAnimate(itemCsb, ResConfig.UIUnionMercenary.Csb2.MercenaryBar_Self, "Send", false, nil, true)
	end
end

function UIUnionMercenary:update(dt)  
	local count = UnionMercenaryModel:getMecenartyCount()

	for i=1,count do
		local myMercenaryInfo = UnionMercenaryModel:getMyselfInfoByTag(i)
		if myMercenaryInfo and myMercenaryInfo.dyId ~= 0  then
			local nowTime = restTime(myMercenaryInfo.time)
			--print("day,hour,min,sec", nowTime.day, nowTime.hour, nowTime.min, nowTime.sec)
			local Time =  CsbTools.getChildFromPath(self.frashItem[i], "BarPanel/Time")
			Time:setString(string.format(CommonHelper.getUIString(2039), nowTime.day, nowTime.hour, nowTime.min, nowTime.sec)) --时间
		end
	end
end  

--------------- 按钮回调 ----------------------
-- 返回
function UIUnionMercenary:backBtnCallBack(ref)
	UIManager.close()
end

function UIUnionMercenary:questionTipCallBack(ref)
	UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(1994))
end

-- 右边标签切换
function UIUnionMercenary:btnCallBack(ref)
	if ref.myType == btnCallBackType.mAllMercenaryBtn then
		self:refreshCommonUI(M_LEFT)
		self:refreshUnion()
    	if #self.cardsInfo==0 and not self.mTips:isVisible() then
    		self.mTips:setVisible(not self.mTips:isVisible())
    	end
	elseif ref.myType == btnCallBackType.mMyMercenaryBtn then
		self:refreshCommonUI(M_RIGHT)
    	self:refreshMe()
    	if #self.cardsInfo==0 and self.mTips:isVisible() then
    		self.mTips:setVisible(not self.mTips:isVisible())
    	end
	end
end

-- 点击佣兵的详细信息
function UIUnionMercenary:cardTouchCallBack(ref)
    local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryGetSC)
    local mCallBack = handler(self, self.getMercenaryAllInfo)
    NetHelper.setResponeHandler(cmd, mCallBack)

	local info = self.cardsInfo[ref:getTag()]

	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 开始发送拉取佣兵详细信息协议")
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryGetCS)

    bufferData:writeInt(info.dyId)
   	NetHelper.request(buffData)
   	self.curDyId = info.dyId

end

-- 派遣按钮  判断VIP条件,同一个英雄不能再派遣
function UIUnionMercenary:sendHeroButonCallBack(ref)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 开始发送派遣佣兵协议")
	local tag = ref:getTag()

	UIManager.open(UIManager.UI.UIUnionHeroCard, tag, handler(self, self.MercenaryCallBack))

end

-- 派遣发协议
function UIUnionMercenary:MercenaryCallBack(heroId, tag)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 开始发送派遣协议")
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenarySendCS)
    buffData:writeInt(heroId)
    buffData:writeInt(tag)
    NetHelper.request(buffData)

end

-- 召回按钮 ,请求可否召回
function UIUnionMercenary:callBackHeroButonCallBack(ref)
	-- 弹出确认框
	local tag = ref:getTag()
	UIManager.open(UIManager.UI.UIUnionMercenaryYes, tag, handler(self,self.yesCallback))
	
end
-- 召回 发协议 
function UIUnionMercenary:yesCallback(tag)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 开始发送召回协议")

	local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryCallSC)
    local mCallBack = handler(self, self.dontCallBack)
    NetHelper.setResponeHandler(cmd, mCallBack)

	local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryCallCS)
	local info = UnionMercenaryModel:getMyselfInfoByTag(tag)
    buffData:writeInt(info.dyId)
    NetHelper.request(buffData)
end

-- 不能召回时回调
function UIUnionMercenary:dontCallBack(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 召回信息返回,在这个位置回调肯定是自己不能召回的回调")
	local tag = buffData:readInt()
	local getMoney = buffData:readInt()

	local nowTime = {}
	nowTime = restTime(UnionMercenaryModel:getMyselfInfoByTag(tag).time)

	CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(1989), 23-nowTime.hour, 59-nowTime.min, 59-nowTime.sec))			--时间

	local info = UnionMercenaryModel:getMyselfInfoByTag(tag)
	info.money = getMoney
	info.tag = tag
	UnionMercenaryModel:setMyselfInfoByTag(tag, info)
	--UnionMercenaryModel:setMyselfInfoByTag(tag,{tag=tag, dyId=info.dyId, heroId=info.heroId,  time=info.time, money=getMoney})

	local heroInfo = UnionMercenaryModel:getUnionMercenaryByDyId(info.dyId)
	self:refreshMeItem(tag, heroInfo.heroId)   				--只刷新他这个item
end

-- 请求某个佣兵详细信息回调
function UIUnionMercenary:getMercenaryAllInfo(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 请求佣兵详细信息返回")
	-- 把这个佣兵的信息写入model
	UnionMercenaryModel:refreshCurMercenaryData(buffData)
	--打开界面,这个界面需要的数据从model中取就好了
	-- 打开UI栈,看下当前界面是啥子
	if UIManager.isTopUI(UIManager.UI.UIUnionMercenary) then
		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@打开详细信息界面")
		UIManager.open(UIManager.UI.UIUnionMercenaryInfo, self.curDyId)
	elseif UIManager.isTopUI(UIManager.UI.UIUnionMercenaryInfo) then
		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@刷新详细信息界面")

		UIManager.getUI(UIManager.UI.UIUnionMercenaryInfo):toNextBtnCallBack()
	end
end

-- 全局监听有召回时,如果此界面打开时回调
function UIUnionMercenary:callMercenary(dyId, getMoney, tag)
	local info = UnionMercenaryModel:getMyselfInfoByTag(tag)
	info.tag = tag
	info.dyId = 0
	info.heroId = 0
	info.time = 0
	info.money = 0
	UnionMercenaryModel:setMyselfInfoByTag(tag, info)

	UnionMercenaryModel:deleteHeroToMercenaryBag(dyId)

	--弹窗奖励
	if getMoney > 0 then
		ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, getMoney)
		UIManager.open(UIManager.UI.UIAward,{[1] = {id = UIAwardHelper.ResourceID.Gold, num = getMoney}})
	end

	self:refreshCommonUI(M_RIGHT)
    self:refreshMeItem(tag, 0)						--只刷新他这个item
	self:refreshScrollView()
end

-- 全局监听派遣时,如果此界面打开时回调
function UIUnionMercenary:sendMercenary(dyId, heroId, tag, name, lv, star)
	local info = {}
	info.tag = tag
	info.dyId = dyId
	info.heroId = heroId
	info.time = getGameModel():getNow()
	info.money = 0
	UnionMercenaryModel:setMyselfInfoByTag(tag, info)
	UnionMercenaryModel:insertHeroToMercenaryBag(dyId, heroId, name, lv ,star)
	self:refreshCommonUI(M_RIGHT)
    self:refreshMeItem(tag, heroId)   	--只刷新他这个item
  	self:refreshScrollView()

  	if self.surplusTimeSheduler then
		scheduler.unscheduleGlobal(self.surplusTimeSheduler)
		self.surplusTimeSheduler = nil
	end
	self.surplusTimeSheduler = scheduler.scheduleGlobal(handler(self, self.update), 1)
end

return UIUnionMercenary