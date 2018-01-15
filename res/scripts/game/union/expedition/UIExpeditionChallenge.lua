--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征关卡挑战界面
** 应  用:
********************************************************************/
--]]

local userModel = getGameModel():getUserModel()
local expeditionModel = getGameModel():getExpeditionModel()

local UIExpeditionChallenge = class("UIExpeditionChallenge", function()
    return require("common.UIView").new()
end)

function UIExpeditionChallenge:ctor()
    self.animationClick = require("game.comm.AnimationClick").new()
end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionChallenge:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionChallenge.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    
    -- 退出按钮
    local backButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(backButton, handler(self, self.onClick))
    local closeButton = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/CloseButton")
    CsbTools.initButton(closeButton, handler(self, self.onClick))
    -- 挑战按钮
    local attackButton = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/AttackButton")
    attackButton:addTouchEventListener(handler(self, self.onChallengeClick))

    CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/Tips_2"):setString(CommonHelper.getStageString(6000))
    CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/Tips"):setString(CommonHelper.getUIString(1965))

    local heroPanel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel1/HeroNodePanel")
    heroPanel:setTouchEnabled(true)
    heroPanel:addClickEventListener(function() 
        if self.animationClick then
            self.animationClick:playRandomAnimation()
        end
    end)
    self.heroNode = CsbTools.getChildFromPath(heroPanel, "HeroNode")
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionChallenge:onOpen(openerUIID, index, record)
    self.index = index
    self.record = record

    self:initEvent()
    self:setMoneyPanel()
    self:setStageInfoPanel()
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionChallenge:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionChallenge:onClose()
    if self.heroNode then
        self.heroNode:removeAllChildren()
    end
    if self.animationClick then
        self.animationClick:setAnimationNode(nil)
    end
    self:removeEvent()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionChallenge:onTop(preUIID, ...)
end

-- 当前界面点击回调
function UIExpeditionChallenge:onClick(obj)
    local btnName = obj:getName()
    if btnName == "BackButton" then             -- 返回
        UIManager.close()
    elseif btnName == "CloseButton" then        -- 关闭
        UIManager.close()
    end
end

function UIExpeditionChallenge:onChallengeClick(obj, eventType)
    local node = CsbTools.getChildFromPath(obj, "AttackButton")
    if 0 == eventType then
        CommonHelper.playCsbAnimation(node, "On", false)
        MusicManager.playSoundEffect(obj:getName())
    elseif 2 == eventType then
        CommonHelper.playCsbAnimation(node, "Normal", false)
        local nowTime = getGameModel():getNow()
        local warEndTime = expeditionModel:getWarEndTime()
        if nowTime >= warEndTime then
            -- 远征已结束
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2006))
            return
        end
        local bossHp = expeditionModel:getStageHp(self.index)
        if bossHp <= 0 then
            -- 关卡已通过
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2010))
            return
        end
        local fightCount = expeditionModel:getFightCount()
        local unionConf = getUnionConfItem() or {}
        if fightCount >= unionConf.Expedition_Num then
            -- 提示挑战次数不足
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1977))
            return
        end
        UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
            BattleHelper.requestExpedition(summonerId, heroIds, self.index, mercenaryId)
        end)
    elseif 3 == eventType then
        CommonHelper.playCsbAnimation(node, "Normal", false)
    end
end

-- 设置货币面板
function UIExpeditionChallenge:setMoneyPanel()
    local lableCoin     = CsbTools.getChildFromPath(self.root, "AssetInfoPanel/Coin/CoinLabel")
    local lableDiamond  = CsbTools.getChildFromPath(self.root, "AssetInfoPanel/Diamond/PowerLabel_0")
    lableCoin:setString(userModel:getGold())
    lableDiamond:setString(userModel:getDiamond())
end

-- 设置关卡信息
function UIExpeditionChallenge:setStageInfoPanel()
    local mapId = expeditionModel:getMapId()
    local mapConf = getExpeditionMapConf(mapId)
    if not mapConf then return end

    local stage = mapConf.Stages[self.index]
    -- 关卡标题
    local titleText = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel1/TitleText")
    titleText:setString(CommonHelper.getStageString(stage.titleID))
    -- 关卡描述
    local introLabel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/IntroLabel")
    introLabel:setString(CommonHelper.getStageString(stage.descID))
    -- 关卡背景
    local bgImage = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel1/StageBGroundImage")
    CsbTools.replaceImg(bgImage, stage.background)
    -- 关卡BOSS
    local bossID = getStageConfItem(stage.stageID).Boss
    local bossAnimationID = getBossConfItem(bossID).Common.AnimationID
    self.animationClick:setAnimationResID(bossAnimationID)
    AnimatePool.createAnimate(bossAnimationID or 1000, function(animation) 
        if animation then
            animation:setScale(getRoleZoom(bossID) and getRoleZoom(bossID).ZoomNumber or 1)
            if self.heroNode then
                self.heroNode:removeAllChildren()
                self.heroNode:addChild(animation)
            end
            if self.animationClick then
                self.animationClick:setAnimationNode(animation)
            end
        end
    end)

    -- 关卡进度
    local bossHp = stage.bossHp
    local restHp = expeditionModel:getStageHp(self.index)
    local percent = restHp and (restHp / bossHp) or 1
    local loadingBar = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/LoadingBar")
    local loadingNum = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/LaodingBarNum")
    loadingBar:setPercent(percent * 100)
    loadingNum:setString(string.format("%0.1f%%", percent * 100))

    -- 本关最佳
    local tipsPanel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/TipsPanel")
    tipsPanel:setVisible(false)
    if percent < 1 then
        tipsPanel:setVisible(true)
        local record = self.record
        -- 等级
        local levelText = CsbTools.getChildFromPath(tipsPanel, "HeadItem/HeadPanel/LevelNum")
        levelText:setString(record.level)
        -- 名称
        local nameText = CsbTools.getChildFromPath(tipsPanel, "Name")
        nameText:setString(record.name)
        -- 伤害
        local attackNum = CsbTools.getChildFromPath(tipsPanel, "AttackNum")
        attackNum:setString(record.damage)
        -- 头像
        local headIcons = getSystemHeadIconItem()
        local headItem = headIcons[record.head]
        if not headItem then return end
        local headImage = CsbTools.getChildFromPath(tipsPanel, "HeadItem/HeadPanel/IconImage")
        CsbTools.replaceImg(headImage, headItem.IconName)
    end
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIExpeditionChallenge:initEvent()
    -- 添加远征关卡通过事件监听
    self.stagePassHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionStagePass, self.stagePassHandler)
    -- 添加远征胜利事件监听
    self.winHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionWin, self.winHandler)
    -- 添加远征失败事件监听
    self.failHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionFail, self.failHandler)
end

-- 移除事件回调
function UIExpeditionChallenge:removeEvent()
    -- 移除远征关卡通过事件监听
    if self.stagePassHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionStagePass, self.stagePassHandler)
        self.stagePassHandler = nil
    end
    -- 移除远征胜利事件监听
    if self.winHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionWin, self.winHandler)
        self.winHandler = nil
    end
    -- 移除远征失败事件监听
    if self.failHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionFail, self.failHandler)
        self.failHandler = nil
    end
end

-- 远征 胜利/失败 事件回调
function UIExpeditionChallenge:onEventCallback(eventName)
    if eventName == GameEvents.EventExpeditionWin or
       eventName == GameEvents.EventExpeditionFail then
        -- 关卡进度
        local loadingBar = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/LoadingBar")
        local loadingNum = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel2/LaodingBarNum")
        loadingBar:setPercent(0)
        loadingNum:setString(string.format("%0.1f%%", 0))
    elseif eventName == GameEvents.EventExpeditionStagePass then
        self:setStageInfoPanel()
    end
end

return UIExpeditionChallenge