--[[
金币试炼主界面
1、挑战获取金币,伤害越高金币越多
2、打开该界面的时候需要判断是否过了挑战时间,是则需要更换挑战的信息和模型修改
]]

local UIGoldTest = class("UIGoldTest", function()
    return require("common.UIView").new()
end)

local GoldTestUILanguage = {BeginBattle = 88, NoEnoughBattleCount = 1005, RemainCount = 1013, ExtraReward = 1036}
local PageViewPoint = {hide = "goldtrial_point_off.png", display = "goldtrial_point_on.png"}

function UIGoldTest:ctor()
end

function UIGoldTest:init()
    self.rootPath = ResConfig.UIGoldTest.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local callBack = function(obj)
        obj:setTouchEnabled(false)
        UIManager.close()
    end

    self.back = getChild(self.root, "BackButton")
    self.close = getChild(self.root, "MainPanel/CloseButton")
    CsbTools.initButton(self.back, callBack)
    CsbTools.initButton(self.close, callBack)

    local extra = getChild(self.root, "MainPanel/ReceiveButton")
    local extraCallBack = function()
        UIManager.open(UIManager.UI.UIGoldTestChest)
    end
    CsbTools.initButton(extra, extraCallBack
        , CommonHelper.getUIString(GoldTestUILanguage.ExtraReward), "Button_Receive/ButtomName", "Button_Receive")

    local fightBtn = getChild(self.root, "MainPanel/StartBattleButton")
    local fightCallBack = function(obj)
        obj.soundId = nil
        local count = self.goldTestConf.Frequency - getGameModel():getGoldTestModel():getCount()
        if count <= 0 then
            obj.soundId = MusicManager.commonSound.fail
            CsbTools.createDefaultTip(CommonHelper.getUIString(GoldTestUILanguage.NoEnoughBattleCount)):addTo(self)
            return 
        end

        UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
            BattleHelper.requestGoldTest(summonerId, heroIds, mercenaryId)
        end)
    end
    CsbTools.initButton(fightBtn, fightCallBack
        , CommonHelper.getUIString(GoldTestUILanguage.BeginBattle), "Button_Orange/ButtomName", "Button_Orange")
    self.btnImage = getChild(self.root, "MainPanel/StartBattleButton/Button_Orange/ButtomImage")

    -- pageView滑动点
    local pageView = getChild(self.root, "MainPanel/BossPanel/MainPanel/BossPageView")
    -- 注:cocos3.10之前为addEventListener, getCurPageIndex
    pageView:addScrollViewEventListener(function (obj, type)
        local node1 = getChild(self.root, "MainPanel/BossPanel/MainPanel/goldtrial_point_off_9")
        local node2 = getChild(self.root, "MainPanel/BossPanel/MainPanel/goldtrial_point_on_10")
        if 0 == obj:getCurrentPageIndex() then
            node1:setSpriteFrame(PageViewPoint.hide)
            node2:setSpriteFrame(PageViewPoint.display)
        else
            node1:setSpriteFrame(PageViewPoint.display)
            node2:setSpriteFrame(PageViewPoint.hide)
        end
    end)

    getChild(self.root, "MainPanel/TipLabel_2"):setString(getUILanConfItem(GoldTestUILanguage.RemainCount)) -- 今日剩余次数

    local panel = getChild(self.root, "MainPanel/BossPanel/MainPanel")
    self.bossNameLb = getChild(panel, "TitleLabel")
    self.bossInfoLb = getChild(panel, "BossPageView/InfoPanel/BossInfoPanel/InfoPanel/BossInfoLabel")
    local board = getChild(panel, "BossPageView/BossPanel/BossNodePanel/BossPanel")
    self.anime_node = getChild(board, "BossNode")
    self.originX, self.originY = self.anime_node:getPosition()

    self.hitLb = getChild(self.root, "MainPanel/HitSumFontLabel")
    self.challengeLb = getChild(self.root, "MainPanel/NumLabel")
    self.introLb = getChild(self.root, "MainPanel/IntroLabel")
end

function UIGoldTest:onOpen(fromUIID)
    self.back:setTouchEnabled(true)
    self.close:setTouchEnabled(true)
    local curTime = getGameModel():getNow()
    local w = tonumber(os.date("%w", curTime))-- 周日为0
    local h = tonumber(os.date("%H", curTime))
    local m = tonumber(os.date("%M", curTime))
    w = (w == 0 and 7 or w)

    if h < ModelHelper.AllRefreshTime.H
        or (h == ModelHelper.AllRefreshTime.H and m == ModelHelper.AllRefreshTime.M) then
        w = w - 1 -- 这时间段前的boss为前一天
        self.goldTestConf = getGoldTestConfItem(w == 0 and 7 or w)
    else
        self.goldTestConf = getGoldTestConfItem(w)
    end
    
    if not self.goldTestConf then
        print("GoldTestConfItem no config! weekday", w)
        return
    end

    local model = getGameModel():getGoldTestModel()
    self.hitLb:setString(tostring(model:getDamage()))-- 伤害值
    local count = self.goldTestConf.Frequency - model:getCount()
    self.challengeLb:setString(tostring(count))-- 挑战次数
    if count <= 0 then
        CommonHelper.applyGray(self.btnImage)
    end
    getChild(self.root, "MainPanel/StartBattleButton/RedTipPoint"):setVisible(count > 0)

    local boss = getBossConfItem(getStageConfItem(self.goldTestConf.Stage).Boss)
    local anime_id = 1

    self.bossNameLb:setString(getBMCLanConfItem(boss.Common.Name))
    self.bossInfoLb:setString(getBMCLanConfItem(boss.Common.Desc))
    self.anime_node:removeAllChildren()

    AnimatePool.createAnimate(boss.Common.AnimationID, function(animation)
        CommonHelper.dumpObject(self)
        if not animation or not self.anime_node then
            print("create animate error or self.anime_node is nil!", boss.Common.AnimationID, self.anime_node)
            return
        end

        self.anime_node:addChild(animation)
        CommonHelper.setRoleZoom(boss.Common.ClassID
            , animation, self.anime_node, self.originX, self.originY)

        -- 可以点击Boss动画
--            local listener = cc.EventListenerTouchOneByOne:create()
--            listener:registerScriptHandler(function (touch, event)
--                anime_id = AnimatePool.playAnimation(animation, anime_id + 1, 2)
--            end, cc.Handler.EVENT_TOUCH_BEGAN)
--            cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, animationNode)
    end)

    self.introLb:setString(getUILanConfItem(self.goldTestConf.StageDesc)) -- 关卡描述
end

function UIGoldTest:onClose()
    self.anime_node:removeAllChildren()
end

return UIGoldTest
