--------------------------------------------------
--名称:UIChallenge
--简介:关卡信息
--日期:2016年2月24日
--作者:Azure
--------------------------------------------------
local userModel     = getGameModel():getUserModel()

local AnimatePool = require("common.AnimatePool")
local UIChallenge = class("UIChallenge", function()
    return require("common.UIView").new()
end)
local AnimationClick = require("game.comm.AnimationClick")
local PropTips = require("game.comm.PropTips")

--构造函数
function UIChallenge:ctor()
    self.animationClick = AnimationClick.new()
end

--初始化
function UIChallenge:init()
    -- 加载
    self.rootPath = ResConfig.UIChallenge.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
 
    -- 资源
    local asset = getChild(self.root, "AssetInfoPanel")
    local btnCoin = getChild(asset, "Coin/CoinButton")
    btnCoin:addClickEventListener(function() 
        UIManager.open(UIManager.UI.UIGold)
    end)
    local btnDiamond = getChild(asset, "Diamond/PowerButton_0")
    btnDiamond:addClickEventListener(function() 
        UIManager.open(UIManager.UI.UIShop, ShopType.DiamondShop)
    end)

    -- 返回
    local backBtn = getChild(self.root, "BackButton")
    CsbTools.initButton(backBtn, function()
        UIManager:close()
    end)

    -- 关闭
    local closeBtn = getChild(self.root, "MainPanel/InfoPanel2/CloseButton")
    CsbTools.initButton(closeBtn, function()
        UIManager:close()
    end)

    -- 挑战
    local attackBtn = getChild(self.root, "MainPanel/InfoPanel2/AttackButton")
    attackBtn:addTouchEventListener(handler(self, self.challengeCallBack))
	self.attackBtnAct = cc.CSLoader:createTimeline(ResConfig.UIChallenge.Csb2.attack)
	attackBtn:runAction(self.attackBtnAct)


    local heroPanel = getChild(self.root, "MainPanel/InfoPanel1/HeroNodePanel")
    heroPanel:setTouchEnabled(true)
    heroPanel:addClickEventListener(function() 
        if self.animationClick then
            self.animationClick:playRandomAnimation()
        end
    end)
    self.heroNode = getChild(heroPanel, "HeroNode")
end

--打开
function UIChallenge:onOpen(openerUIID, chapterID, stageID)
    --
    if openerUIID == UIManager.UI.UITaskAchieve or
        openerUIID == UIManager.UI.UIPropQuickTo or
        openerUIID == UIManager.UI.UIHeroQuickTo then
        getChild(self.root, "AssetInfoPanel/Coin"):setVisible(false)
        getChild(self.root, "AssetInfoPanel/Diamond"):setVisible(false)
    else
        getChild(self.root, "AssetInfoPanel/Coin"):setVisible(true)
        getChild(self.root, "AssetInfoPanel/Diamond"):setVisible(true)
    end
    self:registerResponse()
    -- 道具点击提示
    self.propTips = PropTips.new()

    --初始化
    print("章节：" .. chapterID  .. "   关卡：" .. stageID)
    self.stageID = stageID
    self.chapterID = chapterID
    local chapterConf = getChapterConfItem(self.chapterID)
    if not chapterConf then
        print("Error: chapterConf is nil, chapterID", self.chapterID)
        return
    end
    self.stageConf = chapterConf.Stages[stageID]
    if not self.stageConf then
        print("Error: self.stageConf is nil, stageID", self.stageID)
        return
    end

    -- 先刷新数据
    if StageHelper.ChapterMode.CM_ELITE == StageHelper.getChapterType(self.chapterID) then
        StageHelper.checkNextTimestamp(self.chapterID, self.stageID)
    end

    self:setMoneyPanel()
    self:setStageBar()
    self:setStageBoss()
    self:setStageDesc()
    self:setStageDrop()
end

function UIChallenge:onTop(pre, chapterId, stageId)
    EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
end

--注册监听扫荡结果
function UIChallenge:registerResponse()

    -- 监听刷新货币
    self.updateHandler = handler(self, self.setMoneyPanel)
    EventManager:addEventListener(GameEvents.EventUpdateGold, self.updateHandler)
    EventManager:addEventListener(GameEvents.EventUpdateDiamond, self.updateHandler)
    EventManager:addEventListener(GameEvents.EventUpdateEnergy, self.updateHandler)
end

--移除网络监听
function UIChallenge:onClose()
    local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.SweepSC)
    NetHelper.removeResponeHandler(cmd, self.sweepHandler)

    EventManager:removeEventListener(GameEvents.EventUpdateGold, self.updateHandler)
    EventManager:removeEventListener(GameEvents.EventUpdateDiamond, self.updateHandler)
    EventManager:removeEventListener(GameEvents.EventUpdateEnergy, self.updateHandler)

    self.propTips:removePropAllTips()
    self.propTips = nil

    if self.heroNode then
        self.heroNode:removeAllChildren()
    end
    if self.animationClick then
        self.animationClick:setAnimationNode(nil)
    end
end

-- 设置货币面板
function UIChallenge:setMoneyPanel()
    local lableCoin     = getChild(self.root, "AssetInfoPanel/Coin/CoinLabel")
    local lablePower    = getChild(self.root, "AssetInfoPanel/Power")--/PowerLabel")
    local lableDiamond  = getChild(self.root, "AssetInfoPanel/Diamond/PowerLabel_0")
    lableCoin:setString(userModel:getGold())
    lableDiamond:setString(userModel:getDiamond())
    --lablePower:setString(userModel:getEnergy())
    if lablePower then
        lablePower:setVisible(false)
    end
end

-- 设置关卡公告
function UIChallenge:setStageBar()
    local bar = getChild(self.root, "MainPanel/InfoPanel1/StageInfoBar")
    local barImage = getChild(bar, "Image_Bar")
    local stageImage = getChild(bar, "StageImage")
    local stageName = getChild(bar, "StageNameLabel")
    local pic = "stagemap_bar.png"
    if StageHelper.ChapterMode.CM_ELITE == StageHelper.getChapterType(self.chapterID) then
        pic = "stagemap_bar02.png"
    end
    barImage:loadTexture(pic, 1)
    stageImage:loadTexture(self.stageConf.Thumbnail, 1)
    stageName:setString(getStageLanConfItem(self.stageConf.Name))

    local act = "Star0"
    if StageHelper.StageState.SS_ONE == state then
        act = "Star1"
    elseif StageHelper.StageState.SS_TWO == state then
        act = "Star2"
    elseif StageHelper.StageState.SS_TRI == state then
        act = "Star3"
    end
    CommonHelper.playCsbAnimate(bar, ResConfig.UIMap.Csb2.board, act, false)
end

-- 设置关卡BOSS信息
function UIChallenge:setStageBoss()
    local bgImage = getChild(self.root, "MainPanel/InfoPanel1/StageBGroundImage")
    bgImage:loadTexture(self.stageConf.BG, 1)

    local bossID = getStageConfItem(self.stageID).Boss
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
end

-- 设置关卡描述信息
function UIChallenge:setStageDesc()
    local labelDesc = getChild(self.root, "MainPanel/InfoPanel2/IntroLabel")
    labelDesc:setString(getStageLanConfItem(self.stageConf.Desc))
end

-- 设置关卡掉落物品
function UIChallenge:setStageDrop()
    local infoPanel = getChild(self.root, "MainPanel/InfoPanel2")
    infoPanel:setTouchEnabled(false)
    getChild(self.root, "MainPanel/InfoPanel2/Bground"):setTouchEnabled(true)
    for i = 1, 4 do
        local propConf = getPropConfItem(self.stageConf.Drop[i])
        local allItem = getChild(self.root, "MainPanel/InfoPanel2/BagItem" .. i)

        if propConf then
            -- 道具图标
            allItem:setVisible(true)
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        else
            allItem:setVisible(false)
        end
    end
end

function UIChallenge:checkEnergyCallBack(needEnergy, enoughCall)
    if not enoughCall then
        return
    end

    local curEnergy = getGameModel():getUserModel():getEnergy()
    if curEnergy >= needEnergy then
        enoughCall()
    else
        UIManager.open(UIManager.UI.UIEnergy)
    end
end


function UIChallenge:challengeCallBack(obj, eventType)
    if 0 == eventType then
        self.attackBtnAct:play("On", false)
        MusicManager.playSoundEffect(obj:getName())
    elseif 2 == eventType then
        self.attackBtnAct:play("Normal", false)

        UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
            BattleHelper.requestStage(summonerId, heroIds, self.chapterID, self.stageID, mercenaryId)
        end)
    elseif 3 == eventType then
        self.attackBtnAct:play("Normal", false)
    end
end

return UIChallenge
