--[[
    大厅界面
    1、相关系统界面的按钮切换
    2、通关队伍显示
]]

local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()
local scheduler = require("framework.scheduler")  
local AnimatePool = require("common.AnimatePool")
local AnimationClick = require("game.comm.AnimationClick")
local UIHall = class("UIHall", function ()
	return require("common.UIView").new()
end)
local UIEquipMakeRedHelper = require("game.equipMake.UIEquipMakeRedHelper")
-- 对应语言包ID和系统
local FuncBtn = {BagButton = {lang = 16, system = RedPointHelper.System.Bag}
    , TrailButton = {lang = 17, system = RedPointHelper.System.FB}
    , GuildButton = {lang = 19, system = RedPointHelper.System.Union}
    , ArenaButton = {lang = 20, system = RedPointHelper.System.Arena}
    , StoryButton = {lang = 22, system = RedPointHelper.System.WorldMap}
    , HeroButton = {lang = 15, system = RedPointHelper.System.Hero}
    , SummonerButton = {lang = 14, system = RedPointHelper.System.Summoner}
    , TaskButton = {lang = 13, system = RedPointHelper.System.TaskAndAchieve}
}

local IconBtn = {RankingButton = {lang = 18, system = RedPointHelper.System.Invalid}
    , SignButton = {lang = 56, system = RedPointHelper.System.Sign}
    , MailButton = {lang = 24, system = RedPointHelper.System.Mail}
    , ActivityButton = {lang = 55, system = RedPointHelper.System.Activity}
    , FriendButton = {lang = 25, system = RedPointHelper.System.Invalid}
    , DrawCardButton = {lang = 12, system = RedPointHelper.System.DrawCard}
    , ShopButton = {lang = 21, system = RedPointHelper.System.Shop}
    , BoonButton = {lang = 1718, system = RedPointHelper.System.Boon}
    , SmithShopButton = {lang = 638, system = RedPointHelper.System.EquipMake}
    , SevenDayButton = {lang = 1271, system = RedPointHelper.System.SevenDay}
}

local FloatText = {UnDevelop = 11, RepeatName = 51, NoEnoughDiamond = 5, OpenUnion = 301, 
    UnNil = 432, UnLegal = 8, RecordShort = 1996}

local IconImage = {BagButton = "icon_button_bag.png",           TrailButton = "icon_button_fight.png",       GuildButton = "icon_button_pub.png",
                   ArenaButton = "icon_button_arenna.png",      ShopButton = "icon_button_shop.png",         WordButton = "icon_button_word.png",
                   HeroButton = "icon_button_hero.png",         SummonerButton = "icon_button_summoner.png", TaskButton = "icon_button_task.png",
                   DrawCardButton = "icon_button_drawcard.png", RankingButton = "icon_button_ranking.png",   SignButton = "icon_button_sign.png",
                   MailButton = "icon_button_mail.png",         ActivityButton = "icon_button_activity.png", FriendButton = "icon_button_firend.png",
                   BoonButton = "icon_button_boon.png",         SmithShopButton = "smith_makeicon.png",      SevenDayButton = "icon_button_sevenday.png"
}

local TencentVipButtonCsb = "ui_new/g_gamehall/g_gpub/TencentVipButton.csb"
local QQGameButtonCsb = "ui_new/g_gamehall/g_gpub/QQGameButton.csb"

local SummonerTag = 100
local BoneZOrder = 1000

function UIHall:ctor()
end

function UIHall:init()
	self:initUI()			-- UI
	self:initData()			-- 数值
	self:initBtnCallBack()	-- 按钮的回调
end

function UIHall:onOpen(fromUIID, ...)
    --初始化网络回调
    self:initNetwork()
    
    -- 请求佣兵信息
    if not UnionMercenaryModel.isInit then
        self:sendMercenarysInfoCmd()
    end

    self:onResponse()
    self:showRedPoint()

    -- 没有公会隐藏该按钮
    --self.recordChatButton:setVisible(getGameModel():getUnionModel():getUnionID() > 0)
    self.recordChatButton:setVisible(false)
    -- 获取新的聊天信息
    local newMessage = ChatHelper.getNewMessages(getGameModel():getUserModel():getUserID(), 0)
    for k, v in pairs(newMessage) do
        self:eventChatCallBack(_, v)
    end
    -- 蓝钻显示
    CommonHelper.showBlueDiamond(self.tencentLogo, nil, nil, self.playerNameLb)
    -- 显示公告
    self:showNotice()
    self:hideBoonBtn()
    self:sevenDayVisible()
	-- 玩家金币/钻石
    self:updateGoldCallBack()
	self:updateDiamondCallBack()

    if not UIManager.isBuilding then    
        EventManager:raiseEvent(GameEvents.EventGotoHall)
    end
end

function UIHall:onTop()
    if self.UserInfo.headIconID ~= self.userModel:getHeadID() then
        self.UserInfo.headIconID = self.userModel:getHeadID()
        self.headImage:loadTexture(self.headIconItem[self.UserInfo.headIconID].IconName, 1)
    end

    if self.UserInfo.playerName ~= self.userModel:getUserName() then
        self.UserInfo.playerName = self.userModel:getUserName()
        self.playerNameLb:setString(self.UserInfo.playerName)
    end

    -- 红点刷新
    self:showRedPoint()
    self:hideBoonBtn()
    -- 蓝钻显示
    CommonHelper.showBlueDiamond(self.tencentLogo, nil, nil, self.playerNameLb)

    EventManager:raiseEvent(GameEvents.EventGotoHall)
    -- 引导提示
    self:showWorldArow()
end

function UIHall:onClose()
    -- 移除网络回调
    self:removeNetwork()
    self.recordVoice:stopRecordVoice()

    if self.onEventResponse then
        for event, handler in pairs(self.onEventResponse) do
            EventManager:removeEventListener(event, handler)
        end
    end

    if self.AnimationNode then
        for _, v in pairs(self.AnimationNode) do
            v.obj:removeAllChildren()
        end
    end
    
    self.AnimationNode = {}
    if self.mouseListenerMouse then
        cc.Director:getInstance():getEventDispatcher():removeEventListener(self.mouseListenerMouse)
    end
end

function UIHall:initUI()
    self.UICsb = ResConfig.UIHall.Csb2
	-- 大厅主界面
    self.rootPath = self.UICsb.GameHallNew
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)
    self.gameHallAct = cc.CSLoader:createTimeline(self.rootPath)
	self.root:runAction(self.gameHallAct)
    self.gameHallAct:play("Normal", false)
    -- 聊天面板
	self.talkPanel = CsbTools.getChildFromPath(self.root, "MainPanel/TalkPanel")
    self.talkPanel:setLocalZOrder(BoneZOrder)
    CsbTools.getChildFromPath(self.root, "MainPanel/TalkPanel/TalkPanel"):setTouchEnabled(false)
    self.talkView = CsbTools.getChildFromPath(self.talkPanel, "TalkPanel/TalkPanel/TalkScrollView")
    self.talkView:setScrollBarEnabled(false)
    self.talkView:removeAllChildren()
    self.talkViewSize = self.talkView:getContentSize()
    -- 通告栏
    self.noticeBar = CsbTools.getChildFromPath(self.root, "TopTips")
    self.noticeBar:setVisible(false)
	-- 按钮文本+回调
    self.funcBtnRedTip = {}
    self.funcBtn = {}
	for k, v in pairs(FuncBtn) do
        local Btn = CsbTools.getChildFromPath(self.root, k)
        local Lbl = CsbTools.getChildFromPath(self.root, k .. "/Button/ButtonPanel/NameLabel")
        
        if k ~= "ArenaButton" and k ~= "StoryButton" then
		    CsbTools.getChildFromPath(self.root, k .. "/Button/ButtonPanel"):setTouchEnabled(false)
            CsbTools.getChildFromPath(self.root, k .."/Button/ButtonPanel/InfoImage"):loadTexture(IconImage[k], 1)
            CsbTools.initButton(Btn, handler(self, self.funcBtnCallBack), CommonHelper.getUIString(v.lang), Lbl, "Button")
        else
            if k == "StoryButton" then
                -- 引导箭头
                self.arow = CsbTools.getChildFromPath(Btn, "Button/ButtonPanel/Arow")
                self.arow:setVisible(false)
            end

            CsbTools.initButton(Btn, handler(self, self.funcBtnCallBack), CommonHelper.getUIString(v.lang), Lbl, "Button")
        end
        
        self.funcBtn[v.system] = Btn
        self.funcBtnRedTip[CsbTools.getChildFromPath(self.root, k .. "/Button/ButtonPanel/RedTipPoint")] = v.system
	end

	for k, v in pairs(IconBtn) do
		local iconBtn = CsbTools.getChildFromPath(self.root, "MainPanel/".. k)	
		local iconLbl = CsbTools.getChildFromPath(self.root, "MainPanel/".. k .. "/Button/ButtonPanel/NameLabel")
		CsbTools.getChildFromPath(self.root, "MainPanel/".. k .. "/Button/ButtonPanel"):setTouchEnabled(false)
        CsbTools.getChildFromPath(self.root, "MainPanel/".. k .. "/Button/ButtonPanel/InfoImage"):loadTexture(IconImage[k], 1)

        self.funcBtn[v.system] = iconBtn
        self.funcBtnRedTip[CsbTools.getChildFromPath(self.root, "MainPanel/".. k .. "/Button/ButtonPanel/RedTipPoint")] = v.system

        CsbTools.initButton(iconBtn, handler(self, self.iconBtnCallBack), CommonHelper.getUIString(v.lang), iconLbl, "Button")
	end

    -- 蓝钻和QQ大厅入口
    self.mVipAwardButton = CsbTools.getChildFromPath(self.root, "MainPanel/VipAwardButton")  
    CsbTools.getChildFromPath(self.root, "MainPanel/VipAwardButton/Button/ButtonPanel/RedTipPoint"):setVisible(false)
    CsbTools.getChildFromPath(self.root, "MainPanel/VipAwardButton/Button/ButtonPanel"):setTouchEnabled(false)
    self.vipAwardTips = CsbTools.getChildFromPath(self.root, "MainPanel/VipAwardButton/Button/TipPanel")
    self.vipTipsLight = CsbTools.getChildFromPath(self.root, "MainPanel/VipAwardButton/Button/ButtonPanel/TipsLight")
    self.mVipAwardButtonAct = cc.CSLoader:createTimeline(TencentVipButtonCsb)
    self.mVipAwardButton:runAction(self.mVipAwardButtonAct)

    self.mQQGameButton = CsbTools.getChildFromPath(self.root, "MainPanel/QQGameButton")  
    CsbTools.getChildFromPath(self.root, "MainPanel/QQGameButton/Button/ButtonPanel/RedTipPoint"):setVisible(false)
    CsbTools.getChildFromPath(self.root, "MainPanel/QQGameButton/Button/ButtonPanel"):setTouchEnabled(false)
    self.qqGameTips = CsbTools.getChildFromPath(self.root, "MainPanel/QQGameButton/Button/TipPanel")
    self.qqGameTipsLight = CsbTools.getChildFromPath(self.root, "MainPanel/QQGameButton/Button/ButtonPanel/TipsLight")
    self.mQQGameButtonAct = cc.CSLoader:createTimeline(QQGameButtonCsb)
    self.mQQGameButton:runAction(self.mQQGameButtonAct)

    CsbTools.initButton(self.mVipAwardButton, function (obj)
        print("mVipAwardButton")
        UIManager.open(UIManager.UI.UIBlueGem) 
    end, nil, nil, "Button")

    CsbTools.initButton(self.mQQGameButton,function (obj)
         print("mQQGameButton")

        UIManager.open(UIManager.UI.UICommonHall) 
    end, nil, nil, "Button")

    self.mQQGameButton:setVisible(gIsQQHall and true or false)
    self.mVipAwardButton:setVisible(gIsQQHall and true or false)

    -- 头像红点
    self.funcBtnRedTip[CsbTools.getChildFromPath(self.root, "MainPanel/HeadButton/PlayerInfoPanel/PlayerInfoPanel/RedTipPoint")] = RedPointHelper.System.HeadUnlock

	self.hallCoinLb = CsbTools.getChildFromPath(self.root, "MainPanel/Coin/Coin/CoinLabel")
    self.hallDiamondLb = CsbTools.getChildFromPath(self.root, "MainPanel/Diamond/Diamond/PowerLabel_0")

    -- 屏蔽层
    self.MaskPanel = CsbTools.getChildFromPath(self.root, "MaskPanel")
    self.MaskPanel:addTouchEventListener(handler(self, self.touchMaskPanelCallback))

    local qqGroupLb = CsbTools.getChildFromPath(self.root, "MainPanel/Time")
    qqGroupLb:setString("官方交流群:\n271514828")

 --    local tipPanel = CsbTools.getChildFromPath(self.root, "MainPanel/Power/EnergTipPanel")
	-- self.tipLabel = CsbTools.getChildFromPath(self.root, "MainPanel/Power/EnergTipPanel/EnergTipLabel")
 --    self.tipLabel:setAnchorPoint(cc.p(0.5, 0.7)) 
 --    tipPanel:setContentSize(tipPanel:getContentSize().width, 110)
end

function UIHall:initData()
	self.UserInfo = {}			 -- 用户信息

	self.userModel = getGameModel():getUserModel()
    local playerInfoPanel = CsbTools.getChildFromPath(self.root, "MainPanel/HeadButton/PlayerInfoPanel/PlayerInfoPanel")
	-- 玩家名字
	self.UserInfo.playerName = self.userModel:getUserName()
	self.playerNameLb = CsbTools.getChildFromPath(playerInfoPanel, "PalyerName")
    self.playerNameLb:setString(self.UserInfo.playerName)
	-- 玩家等级
	self.UserInfo.userLv = self.userModel:getUserLevel()
    self.userLvLb = CsbTools.getChildFromPath(playerInfoPanel, "LevelLabel")
    self.userLvLb:setString(self.UserInfo.userLv)
	-- 玩家头像
	self.UserInfo.headIconID = self.userModel:getHeadID()
    self.headIconItem = getSystemHeadIconItem()
    self.headImage = CsbTools.getChildFromPath(playerInfoPanel, "HeadImage")
    if self.headIconItem[self.userModel:getHeadID()] then
        self.headImage:loadTexture(self.headIconItem[self.userModel:getHeadID()].IconName, 1)
    end
    -- 蓝钻显示
    self.tencentLogo = CsbTools.getChildFromPath(playerInfoPanel, "TencentLogo")
	-- 玩家经验
	self.userLevelConfItem = getUserLevelSettingConfItem(self.UserInfo.userLv)
    if not self.userLevelConfItem then
        print("getUserLevelSettingConfItem is nil!!!", self.UserInfo.userLv)
        return
    end

    self.expBar = CsbTools.getChildFromPath(playerInfoPanel, "ExpLoadingBar")
    self.expBar:setPercent(self.userModel:getUserExp() / self.userLevelConfItem.Exp * 100)

    self.SummonerAnimationClick = AnimationClick.new()    
    self.HeroAnimationClicks = {}

    local mailPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    self.AnimationNode = {}
    for i = 0, 7 do
        self.AnimationNode[i] = {}
        self.AnimationNode[i].obj = cc.Node:create()
        mailPanel:addChild(self.AnimationNode[i].obj)
        if i > 0 then
            CsbTools.getChildFromPath(self.root, "MainPanel/Hero_"..i):setTouchEnabled(false)
        end
    end

    -- 队伍模型动画(可能是armature或是spine)
    local summonerID, heroList = TeamHelper.getTeamInfo()
    self:createSummoner(summonerID)
    self:createHeros(heroList)
end

function UIHall:sevenDayVisible()
    local activityOver = getGameModel():getSevenCrazyModel().activityOut
    self.funcBtn[IconBtn.SevenDayButton.system]:setVisible(not activityOver)
    -- 七日活动结束后移动首充按钮位置
    if activityOver then
        self.funcBtn[IconBtn.BoonButton.system]:setPosition(self.funcBtn[IconBtn.SevenDayButton.system]:getPosition())
    end
end

function UIHall:initBtnCallBack()
	-- 喇叭按钮
	local talkButton = CsbTools.getChildFromPath(self.root, "MainPanel/TalkButton")
    talkButton:setLocalZOrder(BoneZOrder)
    CsbTools.initButton(talkButton, function() 
        self.talkAct:play("On", false)
        UIManager.open(UIManager.UI.UIChat)
    end)

	CsbTools.getChildFromPath(self.root, "MainPanel/TalkButton/Button/Panel_1"):setTouchEnabled(false)	
    self.talkAct = cc.CSLoader:createTimeline(self.UICsb.TalkButton)
	local talkBtn = CsbTools.getChildFromPath(self.root, "MainPanel/TalkButton/Button")
	talkBtn:runAction(self.talkAct)
    -- 录音按钮
    self.recordChatButton = CsbTools.getChildFromPath(self.talkPanel, "TalkPanel/TalkPanel/GuildChatButton")
    self.recordChatButton:addTouchEventListener(handler(self, self.touchRecordCallBack))
    -- 显示录音
    self.recordVoice = (require "game.chat.ChatRecord").new()
    self.recordVoice:setPosition(cc.p(display.cx, display.cy))
    self:addChild(self.recordVoice)
	-- 头像按钮
	local headButton = CsbTools.getChildFromPath(self.root, "MainPanel/HeadButton")
    self.funcBtn[RedPointHelper.System.HeadUnlock] = headButton
    CsbTools.initButton(headButton, function (obj)
        if UIManager.isOpening or UIManager.isClosing then
            return
        end
        if self.headAct == nil then
            self.headAct = cc.CSLoader:createTimeline(self.UICsb.PlayerInfoPanel)
	        local headBtn = CsbTools.getChildFromPath(self.root, "MainPanel/HeadButton")
	        headBtn:runAction(self.headAct)
        end
	    
	    self.headAct:play("On", false)
	    -- 玩家信息面板
	    UIManager.open(UIManager.UI.UIUserSetting)
    end)

	CsbTools.getChildFromPath(self.root, "MainPanel/HeadButton/PlayerInfoPanel/PlayerInfoPanel"):setTouchEnabled(false)    
    
	-- 购买金币+按钮
	local buyCoinBtn = CsbTools.getChildFromPath(self.root, "MainPanel/Coin/Coin/CoinButton")
	CsbTools.initButton(buyCoinBtn, function ()
		UIManager.open(UIManager.UI.UIGold)
	end)
	-- 购买钻石+按钮
	local buyDiamondBtn = CsbTools.getChildFromPath(self.root, "MainPanel/Diamond/Diamond/PowerButton_0")
	CsbTools.initButton(buyDiamondBtn, function ()
        UIManager.open(UIManager.UI.UIShop, ShopType.DiamondShop)
	end)
end

function UIHall:onResponse()
    -- 事件回调
    self.onEventResponse = {}
    self.onEventResponse[GameEvents.EventUpdateGold] = handler(self, self.updateGoldCallBack)
    EventManager:addEventListener(GameEvents.EventUpdateGold, self.onEventResponse[GameEvents.EventUpdateGold])
    self.onEventResponse[GameEvents.EventUpdateDiamond] = handler(self, self.updateDiamondCallBack)
    EventManager:addEventListener(GameEvents.EventUpdateDiamond, self.onEventResponse[GameEvents.EventUpdateDiamond])
    self.onEventResponse[GameEvents.EventUpdateLvExp] = handler(self, self.updateLvExpCallBack)
    EventManager:addEventListener(GameEvents.EventUpdateLvExp, self.onEventResponse[GameEvents.EventUpdateLvExp])
    self.onEventResponse[GameEvents.EventChatMessage] = handler(self, self.eventChatCallBack)
    EventManager:addEventListener(GameEvents.EventChatMessage, self.onEventResponse[GameEvents.EventChatMessage])
    self.onEventResponse[GameEvents.EventUpdateMainBtnRed] = handler(self, self.showRedPoint)
    EventManager:addEventListener(GameEvents.EventUpdateMainBtnRed, self.onEventResponse[GameEvents.EventUpdateMainBtnRed])
    self.onEventResponse[GameEvents.EventUpdateTeam] = handler(self, self.refreshAnimationNode)
    EventManager:addEventListener(GameEvents.EventUpdateTeam, self.onEventResponse[GameEvents.EventUpdateTeam])
    
    -- 鼠标移动事件
    if gIsQQHall then
        self.mouseListenerMouse = cc.EventListenerMouse:create()
        self.mouseListenerMouse:registerScriptHandler(function(event)
            -- 当前界面是大厅界面
            if not UIManager.isTopUI(UIManager.UI.UIHall) then
                return
            end

            -- 判断是否点击到蓝钻特权图标
            if cc.rectContainsPoint(self.mVipAwardButton:getBoundingBox(), cc.p(event:getCursorX(), event:getCursorY())) then
                self.vipAwardTips:setVisible(true)
            else
                self.vipAwardTips:setVisible(false)
            end
            -- 判断是否点击到QQ大厅特权图标
            if cc.rectContainsPoint(self.mQQGameButton:getBoundingBox(), cc.p(event:getCursorX(), event:getCursorY())) then
                self.qqGameTips:setVisible(true)
            else
                self.qqGameTips:setVisible(false)
            end
        end, 50)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.mouseListenerMouse, self)
    end
end

function UIHall:funcBtnCallBack(obj)
	local btnName = obj:getName()
    obj.soundId = nil
	if btnName == "HeroButton" then
        UIManager.open(UIManager.UI.UIHeroCardBag)
    elseif btnName == "SummonerButton" then
        UIManager.open(UIManager.UI.UISummonerList)
    elseif btnName == "BagButton" then
        UIManager.open(UIManager.UI.UIBag)
    elseif btnName == "ArenaButton" then
        -- 免费改名
        if 0 == self.userModel:getChangeNameFree() then
            UIManager.open(UIManager.UI.UINameIntitle)
        else
            UIManager.open(UIManager.UI.UIArena)
        end
    elseif btnName == "StoryButton" then
        SceneManager.loadScene(SceneManager.Scene.SceneWorld) 
    elseif btnName == "TrailButton" then
        UIManager.open(UIManager.UI.UIInstanceEntry)
    elseif btnName == "TaskButton" then
        UIManager.open(UIManager.UI.UITaskAchieve, "task")
    elseif btnName == "GuildButton" then
        local unionConf = getUnionConfItem()
        local userLv = getGameModel():getUserModel():getUserLevel()
        if unionConf and userLv >= unionConf.UnLockLv then
            local hasUnion = getGameModel():getUnionModel():getHasUnion()
            if hasUnion then
                -- 有工会进入公会界面
                SceneManager.loadScene(SceneManager.Scene.SceneUnion)
            else
                -- 没有公会进入公会列表
                UIManager.open(UIManager.UI.UIUnionList)
            end
        else
            -- 进入公会等级不足, 提示
            CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(300), unionConf.UnLockLv))            
        end
    end
end

function UIHall:iconBtnCallBack(obj)
	local btnName = obj:getName()
    obj.soundId = nil
	if btnName == "MailButton" then
        UIManager.open(UIManager.UI.UIMail)
    elseif btnName == "ShopButton" then
        UIManager.open(UIManager.UI.UIShop, ShopType.GoldShop)
    elseif btnName == "DrawCardButton" then
        UIManager.open(UIManager.UI.UIDrawCard)
    elseif btnName == "RankingButton" then
        UIManager.open(UIManager.UI.UIRank, RankData.rankType.arena)
    elseif btnName == "ActivityButton" then
        local operateActiveModel = getGameModel():getOperateActiveModel()
        local allActive = operateActiveModel:getActiveData() or {}
        local showActive = {}
        local nowTime = getGameModel():getNow()
        for i, data in pairs(allActive) do
            -- 剔除未开始、已结束的活动
            if 0 == data.timeType or (nowTime >= data.startTime and nowTime < data.endTime) then
                table.insert(showActive, data)
            end
        end
        --
        if #showActive <= 0 then
            CsbTools.createDefaultTip(CommonHelper.getUIString(1477)):addTo(self)
        else
            UIManager.open(UIManager.UI.UIOperateActive, showActive)
        end
    elseif btnName == "SignButton" then
        UIManager.open(UIManager.UI.UISignIn)
    elseif btnName == "BoonButton" then
        UIManager.open(UIManager.UI.UIFirstRecharge)
    elseif btnName == "SmithShopButton" then
        UIManager.open(UIManager.UI.UIEquipMake, true)
    elseif btnName == "SevenDayButton" then
        UIManager.open(UIManager.UI.UISevenCrazy)
    else
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(FloatText.UnDevelop)):addTo(self)
    end
end

function UIHall:refreshAnimationNode()
    if self.AnimationNode then
        for _, v in pairs(self.AnimationNode) do
            v.obj:removeAllChildren()
        end
    end

    local summonerID, heroList = TeamHelper.getTeamInfo()
    self:createSummoner(summonerID)
    self:createHeros(heroList)
end

function UIHall:touchMaskPanelCallback(obj, eventType)
    if 0 == eventType then -- 触摸开始
        self.MaskPanel:setVisible(false)
        self.gameHallAct:play("TipHide", false)
    end
end

function UIHall:createSummoner(summonerID)
    self.summonerID = summonerID
    local summonerConf = getHeroConfItem(self.summonerID)
    if summonerConf ~= nil then
        AnimatePool.createAnimate(summonerConf.Common.AnimationID, handler(self, self.createSummonerAnimation))
        self.SummonerAnimationClick:setAnimationResID(summonerConf.Common.AnimationID)
    end
end

function UIHall:createSummonerAnimation(animation)
    self.AnimationNode[0].animation = animation
    self.AnimationNode[0].obj:addChild(animation)
    animation:setTag(SummonerTag)
    animation:setTouchSwallowEnabled(true)
    self:showAnimationNode(self.summonerID, 0)
	CsbTools.getChildFromPath(self.root, "MainPanel/Summoner"):setTouchEnabled(false)

    self.SummonerAnimationClick:setAnimationNode(animation)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.touchArmatureNode), cc.Handler.EVENT_TOUCH_BEGAN)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, animation)
end

function UIHall:createHeros(heroList)
    if not heroList then
        return
    end

    -- 站位优先级
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    local function sortStandPriority(a, b)
        local heroModelA = heroCardBagModel:getHeroCard(a)
        local heroModelB = heroCardBagModel:getHeroCard(b)
        local zoomA = getRoleZoom(heroModelA:getID())
        local zoomB = getRoleZoom(heroModelB:getID())
        if not zoomA or not zoomB then
            print("getRoleZoom is nil!!!", heroModelA:getID(), heroModelB:getID())
            return false
        end

        return zoomA.Priority < zoomB.Priority
    end
    
    table.sort(heroList, sortStandPriority)
    self.teamHeroList = heroList

	for i = 1, #self.teamHeroList do
        local heroModel = heroCardBagModel:getHeroCard(self.teamHeroList[i])
        local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
        if heroConf then
            if self.HeroAnimationClicks[i] == nil then
                self.HeroAnimationClicks[i] = AnimationClick.new()
            end
            self.HeroAnimationClicks[i]:setAnimationResID(heroConf.Common.AnimationID)

            AnimatePool.createAnimate(heroConf.Common.AnimationID, handler(self, self.createHeroAnimation))
        end
	end
end

function UIHall:createHeroAnimation(animation, animationId)
    --CommonHelper.dumpObject(self)
    if not animation then
        return
    end

    -- 加载先后不确定
    local index = -1
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    for i, heroId in pairs(self.teamHeroList) do
        local heroModel = heroCardBagModel:getHeroCard(heroId)
        local heroConf = getSoldierConfItem(heroId, heroModel:getStar())
        if heroConf and heroConf.Common.AnimationID == animationId then
            index = i
            break
        end
    end

    if not self.AnimationNode[index] then
        return
    end

    self.AnimationNode[index].animation = animation
    self.AnimationNode[index].obj:addChild(animation)
    animation:setTag(index)
    animation:setTouchSwallowEnabled(true)
    self:showAnimationNode(self.teamHeroList[index], index)
    self.HeroAnimationClicks[index]:setAnimationNode(animation)

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self, self.touchArmatureNode), cc.Handler.EVENT_TOUCH_BEGAN)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, animation)
end

function UIHall:touchArmatureNode(touch, event)
    local target = event:getCurrentTarget()
    local rect = target:getBoundingBox()
    local nodepos = target:getParent():convertTouchToNodeSpace(touch)
    if cc.rectContainsPoint(rect, nodepos) then
        if SummonerTag == target:getTag() then
            --print("==============touch Summoner============")
            self.SummonerAnimationClick:playRandomAnimation()
        else
            --print("==============touch Hero", target:getTag())
            local heroIndex = target:getTag()
		    local heroArmartureNode = self.AnimationNode[heroIndex].animation
		    if heroArmartureNode then
                self.HeroAnimationClicks[heroIndex]:playRandomAnimation()
		    end
        end
        return true
    end

    return false
end

function UIHall:updateGoldCallBack()
    local gold = self.userModel:getGold()
    self.hallCoinLb:setString(gold)
end

function UIHall:updateDiamondCallBack()
    local diamond = self.userModel:getDiamond()
	self.hallDiamondLb:setString(diamond)
end

function UIHall:updateLvExpCallBack(eventName, lvExpInfo)
    if lvExpInfo.lv ~= self.UserInfo.userLv then
        self.UserInfo.userLv = lvExpInfo.lv
        self.userLvLb:setString(lvExpInfo.lv)
        self.userLevelConfItem = getUserLevelSettingConfItem(lvExpInfo.lv)
    end

    self.expBar:setPercent(lvExpInfo.exp / self.userLevelConfItem.Exp * 100)
end

function UIHall:eventChatCallBack(eventName, chatInfo)
    local limitLv = cc.UserDefault:getInstance():getIntegerForKey("CHAT_LV_LIMIT", 1)
    local chatMode = cc.UserDefault:getInstance():getIntegerForKey("CHAT_MODE", 11)
    -- 等级限制&语音限制
    if chatInfo.lv and limitLv > chatInfo.lv then
        return
    end

    -- 频道限制
    if chatInfo.chatMode == 1 then
        if math.floor(chatMode/10) == 1 then
            self:addChatItem(chatInfo)
        end
    elseif chatInfo.chatMode == 2 then
        if math.floor(chatMode%10) == 1 then
            self:addChatItem(chatInfo)
        end
    else
        self:addChatItem(chatInfo)
    end
end

function UIHall:addChatItem(chatInfo)
    local chatStr = ChatHelper.toFormatCode(chatInfo)
    local richText = createRichTextWithCode(chatStr, self.talkViewSize.width-8)
    richText:setTouchEnabled(false)
    if not self.curChatHeight then
        self.curChatHeight = 5
    end

    local posHeight = self.curChatHeight
    self.curChatHeight = self.curChatHeight + richText:getContentSize().height
    if self.curChatHeight > self.talkViewSize.height then
        self.talkViewSize.height = self.curChatHeight
    end

    --richText:setAnchorPoint(cc.p(0, 1))
    richText:setPosition(5, posHeight)
    self.talkView:setInnerContainerSize(self.talkViewSize)
    self.talkView:addChild(richText)
end

function UIHall:showAnimationNode(roleID, index)
    local zoom = getRoleZoom(roleID)
    local standItem = getConfHallStandingItem(index)
    if not zoom or not standItem then
        print("getRoleZoom or getConfHallStandingItem is nil", roleID, index)
        return
    end

    self.AnimationNode[index].animation:setScale(zoom.HallZoom)
    self.AnimationNode[index].obj:setLocalZOrder(standItem.ZOrder)
    self.AnimationNode[index].obj:setPosition(standItem.Position.x/960*display.width
        , standItem.Position.y/640*display.height)
end

function UIHall:touchRecordCallBack(obj, event)
    if not ChatHelper.canSendMessage() then
        return
    end

    if event == 0 then
        -- 开始录音
        self.recordVoice:startRecordVoice()
	elseif event == 1 then
        -- 拖动取消录音
	    if cc.pGetDistance(obj:getTouchBeganPosition(), obj:getTouchMovePosition()) > 30 then
            self.recordVoice:cancelRecordVoice()
	    end

    elseif event == 2 or event == 3 then
        self.recordVoice:stopRecordVoice()
	end
end

function UIHall:showRedPoint()
    for redPoint, system in pairs(self.funcBtnRedTip) do
        redPoint:setVisible(RedPointHelper.getSystemRedPoint(system))
        
        local hide = false
        if system == RedPointHelper.System.FB then
            local info = RedPointHelper.getSystemInfo(system)
            -- 金币试炼是否需要红点+未解锁
            hide = (not info[1]) or GuideUI.islock(526)
            -- 英雄试炼是否需要红点+未解锁
            hide = hide and ((not info[2]) or GuideUI.islock(135))
        end

        if system == RedPointHelper.System.EquipMake then
            -- 装备打造红点
            UIEquipMakeRedHelper:abcdefg()
            redPoint:setVisible(next(UIEquipMakeRedHelper.mCanShowJobRed) ~= nil)
        end

        -- 如果按钮是不可点击,隐藏红点,新手引导未解锁!!!
        local button = self.funcBtn[system]
        if not button or not button:isTouchEnabled() or hide then
            redPoint:setVisible(false)
        end
    end

    -- 蓝钻特权+qq大厅特权
    if gIsQQHall then
        local isShowBlueGem, isShowQQGame = RedPointHelper.getBlueGemRedPoint()
        if isShowBlueGem then
            self.vipTipsLight:setVisible(true)
            self.mVipAwardButtonAct:play("Normal", true)
        else
            self.vipTipsLight:setVisible(false)
        end

        if isShowQQGame then
            self.qqGameTipsLight:setVisible(true)
            self.mQQGameButtonAct:play("Normal", true)
        else
            self.qqGameTipsLight:setVisible(false)
        end
    end
end

function UIHall:showNotice()
    if gIsQQHall then
        return
    end
    -- 平台限制
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    --if cc.PLATFORM_OS_IPHONE == targetPlatform or cc.PLATFORM_OS_ANDROID == targetPlatform then
        -- 首次进入主城限制
        if gEnterHallFirst and GuideManager.currentGuide == nil and not UIManager.isBuilding then
            -- 用户选择限制
            local hideTime = cc.UserDefault:getInstance():getIntegerForKey("NoticeActivityHideTime", 0)
            local dayHide = os.date("%d", hideTime)
            local dayNow = os.date("%d", os.time())
            if 0 == hideTime or dayHide ~= dayNow then
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                    -- 如果当前执行了新手引导，则不弹出公告框
                    if GuideManager.currentGuide == nil and not UIManager.isBuilding then
                        gEnterHallFirst = false
                        print("打开公告界面")
                        UIManager.open(UIManager.UI.UINoticeActivity)
                    end
                end)))  
            end
        end
    --end
end

function UIHall:hideBoonBtn()
    local userModel = getGameModel():getUserModel()
    local firstPayFlag = userModel:getFirstPayFlag()     -- 奖励状态(0：未领取, 1：已领取)
    local startTime = userModel:getFundStartFlag()    -- 开始时间
    local firstPayData = GetFirstPayData()
    local boonBtn = CsbTools.getChildFromPath(self.root, "MainPanel/BoonButton")

    if 1 == firstPayFlag then   -- 首充奖励已领取
        boonBtn:setVisible(false)
        --[[if 0 == startTime then  -- 成长基金还未购买
            boonBtn:setVisible(true)
        else
            if os.time() < startTime + firstPayData.GetTimes * 86400 then
                boonBtn:setVisible(true)
            else
                boonBtn:setVisible(false)
            end
        end--]]
    else
        boonBtn:setVisible(true)
    end
end

---------------------------------------------------------------------
-- 初始化网络回调
function UIHall:initNetwork()
    -- 公会佣兵: 请求佣兵信息
    local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoSC)
    self.mercenarysInfoHandler = handler(self, self.acceptMercenarysInfoCmd)
    NetHelper.setResponeHandler(cmd, self.mercenarysInfoHandler)
end

-- 移除网络回调
function UIHall:removeNetwork()
    -- 注销请求公会佣兵信息网络回调
    if self.mercenarysInfoHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoSC)
        NetHelper.removeResponeHandler(cmd, self.mercenarysInfoHandler)
        self.mercenarysInfoHandler = nil
    end
end

-- 请求公会佣兵信息
function UIHall:sendMercenarysInfoCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoCS)
    NetHelper.request(buffData)
end

-- 接收公会佣兵信息
function UIHall:acceptMercenarysInfoCmd(mainCmd, subCmd, data)
    if UnionMercenaryModel:init(data) then
    	print("UIHall:acceptMercenarysInfoCmd 数据初始化成功!!!!!")
    end
end

-- 显示世界按钮监听
function UIHall:showWorldArow()
    local needTips = false
    if GuideManager.guideList then
        for _, guide in pairs(GuideManager.guideList) do
            if guide > 25 and guide <= 29 then
                needTips = true
                break
            end
        end
    end
    self.arow:setVisible(needTips)
end

return UIHall