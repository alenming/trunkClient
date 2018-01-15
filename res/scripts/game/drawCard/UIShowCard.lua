--[[
	抽卡单张卡片抽卡显示, 主要进行卡片信息设置, 
	再来一次和返回按钮的回调处理
	2015-09-10 by wsz
]]

local UIShowCard = class("UIShowCard", function()
	return require("common.UIView").new()
end)

local csbResHeroCard = ResConfig.UIDrawCard.Csb2.heroCard
local csbResHeroGoldCard = ResConfig.UIDrawCard.Csb2.heroGoldCard
local csbResHeroSilverCard = ResConfig.UIDrawCard.Csb2.heroSilverCard
local csbResBigStar = ResConfig.UIDrawCard.Csb2.bigStar
local csbResAgainPanel = ResConfig.UIDrawCard.Csb2.againPanel
local lightB = "ui_new/g_gamehall/d_drawcard/effect/CardLight_B.csb"
local lightF = "ui_new/g_gamehall/d_drawcard/effect/CardLight_F.csb"
local csbResDrawOnePrice = "ui_new/g_gamehall/d_drawcard/DrawCardPrice.csb"

local heroFragText = CommonHelper.getUIString(1282)
local heroEnergyText = CommonHelper.getUIString(1281)

function UIShowCard:ctor()
end

function UIShowCard:init()
    self.rootPath = "ui_new/g_gamehall/d_drawcard/OneCardPanel.csb"
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)
    self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
    self.root:runAction(self.rootAct)

    self:initUI()
end

function UIShowCard:initUI()
	local gameSetting = getCardGambleSettingConfItem()
	local againText = CommonHelper.getUIString(106)
	local againDiamondText = gameSetting.DiamondCardGamblePrice

    self:setGlobalZOrder(5)
	self:setLocalZOrder(5)

    self.backInfo = {}
    self.backInfo.isAgain = false
    self.backInfo.buyCardType = 0

    self.background = CsbTools.getChildFromPath(self.root, "Background")
	-- 卡片
	self.cardNode = CsbTools.getChildFromPath(self.root, "OneCardPanel/SummonerCard")
	self.cardNodeAct = cc.CSLoader:createTimeline(csbResHeroCard)
	--根据配置决定银卡或金卡的代理节点
	self.colorAct = nil
	--星星节点
	self.uiStarNode = CsbTools.getChildFromPath(self.root, "OneCardPanel/BigStarPanel")
	self.uiStarAct = cc.CSLoader:createTimeline(csbResBigStar)
	--名字节点
	self.getHeroNameNode = CsbTools.getChildFromPath(self.root, "OneCardPanel/TipInfoLabel")
    --标题节点"史诗"
    self.titleText = CsbTools.getChildFromPath(self.root, "OneCardPanel/TitleText")
    --职业节点
    self.profLabel = CsbTools.getChildFromPath(self.root, "OneCardPanel/Profesion")
    --种族节点
    self.raceLabel = CsbTools.getChildFromPath(self.root, "OneCardPanel/Race")
	--按钮节点, 切换成多按钮
	self.buttonNode = CsbTools.getChildFromPath(self.root, "OneCardPanel/AgainButtonPanel")
	self.buttonAct = cc.CSLoader:createTimeline(csbResAgainPanel)

	--再来一次文本
    self.againBtn = CsbTools.getChildFromPath(self.buttonNode, "AgainTenButton")
	self.againBtn:setTitleText(againText)

    self.againOneCardPrice = CsbTools.getChildFromPath(self.buttonNode, "AgainTenButton/DrawCardPrice")
    self.againOneCardAct = cc.CSLoader:createTimeline(csbResDrawOnePrice)
    -- "抽卡券"数量
    self.againOneFlashcardLabel = CsbTools.getChildFromPath(self.againOneCardPrice, "CardNum")
    -- 抽一次价格"200"(设置一次就可以了)
    CsbTools.getChildFromPath(self.againOneCardPrice, "GemNum"):setString(againDiamondText)
    -- "抽卡券*1"(设置一次就可以了)
    CsbTools.getChildFromPath(self.againOneCardPrice, "Card"):setString(CommonHelper.getUIString(598))
    -- "免费"文字(设置一次就可以了)
    CsbTools.getChildFromPath(self.againOneCardPrice, "Free"):setString(CommonHelper.getUIString(104))

	--返回按钮文本
	self.backBtn = CsbTools.getChildFromPath(self.buttonNode, "BackButton")
    self.backLabel = CsbTools.getChildFromPath(self.buttonNode, "BackButton/Button_Orange/ButtomName")
    CsbTools.initButton(self.backBtn, function () UIManager.close() end
        , CommonHelper.getUIString(107), self.backLabel, "Button_Orange")

    self.oneKeyFlipButton = CsbTools.getChildFromPath(self.buttonNode, "OneKeyFlipButton")
    self.oneKeyFlipButton:setTitleText(CommonHelper.getUIString(107))
    self.oneKeyFlipButton:addClickEventListener(function (obj)
        UIManager.close()
    end)

	--设置节点动作
	self.cardNode:runAction(self.cardNodeAct)
	self.uiStarNode:runAction(self.uiStarAct)
	self.buttonNode:runAction(self.buttonAct)
    self.againOneCardPrice:runAction(self.againOneCardAct)
	-- 回调
    CsbTools.initButton(self.againBtn, handler(self, self.againCallback))
	self.rootAct:setFrameEventCallFunc(handler(self, self.openEndCallFunc))
end

-- type 1为抽卡,2为关卡掉落卡片
function UIShowCard:onOpen(fromUI, type, heroInfo)
    self.root:setVisible(true)
    self.backInfo.isAgain = false
    self.heroInfo = heroInfo
	self.colorNode = nil

    local heroConfig = getSoldierConfItem(heroInfo.cardId, heroInfo.star)
	if heroConfig == nil then
		print("can't found hero config, hero not exsit!")
		return
	end

    if 1 == type then
        --处理再来一次按钮
	    self.buttonAct:play("Again", false)
        self:showCardOrDiamond()
    else
        self.buttonAct:play("Back", false)
    end
	--[[--如果银卡, 三星以上为金卡
	if heroConfig.Rare < 3 then
        --self.colorNode = silverCards:getCsb()
        --self.colorNode:setTag(1023)
		self.colorNode = getResManager():cloneCsbNode(csbResHeroSilverCard)
		self.colorAct = cc.CSLoader:createTimeline(csbResHeroSilverCard)
	else
        --self.colorNode = goldenCards:getCsb()
        --self.colorNode:setTag(1024)
		self.colorNode = getResManager():cloneCsbNode(csbResHeroGoldCard)
		self.colorAct = cc.CSLoader:createTimeline(csbResHeroGoldCard)
	end	
    self.cardNode:removeAllChildren()
    self.cardNode:addChild(self.colorNode)
    --卡片执行的动作
	self.colorNode:runAction(self.colorAct)]]

    self.colorNode = self.cardNode:getChildByTag(1024)
    if not self.colorNode then
        self.colorNode = getResManager():cloneCsbNode(csbResHeroGoldCard)
		self.colorAct = cc.CSLoader:createTimeline(csbResHeroGoldCard)
        self.cardNode:addChild(self.colorNode)
        self.colorNode:runAction(self.colorAct)
    end

    --设置卡片信息
    UICommHelper.setHeroCardInfo(self.colorNode, heroInfo.cardId, heroInfo.star, heroInfo.heroLv)
    --设置卡片外信息
	self:setUIInfo(heroName, heroInfo.star, heroInfo.heroLv) 
    --标题语言包
    local lanRare = {785, 786, 787, 788, 789}
    local lanVoc = {521, 524, 522, 523, 525, 520}
    local lanRace = {514, 515, 517, 516 }

    self.titleText:setString(CommonHelper.getUIString(lanRare[heroConfig.Rare]) or "")
    self.profLabel:setString(CommonHelper.getUIString(611)..CommonHelper.getUIString(lanVoc[heroConfig.Common.Vocation]))
    self.raceLabel:setString(CommonHelper.getUIString(518)..CommonHelper.getUIString(lanRace[heroConfig.Common.Race]))
    --设置角色描述
    CsbTools.getChildFromPath(self.root, "OneCardPanel/HeroIntro"):setString(
        CommonHelper.getHSString(heroConfig.Common.Desc))
    --打开动画
	self.rootAct:play("Open", false)
	--如果第二次翻, 卡片设置为未翻开
	self.colorAct:play("Normal_B", false)
end

function UIShowCard:onClose()
	self.root:setVisible(false)
	self.background:setTouchEnabled(false)
    return self.backInfo
end
-- 根据数据显示抽卡券或钻石
function UIShowCard:showCardOrDiamond()
    if getGameModel():isFreePickCard() then
	    self.againOneCardAct:play("Free", false)
    else
        --如果有"抽卡券"
        local flashcard = getGameModel():getUserModel():getFlashcard()
        if flashcard > 0 then
            self.againOneCardAct:play("Card", false)
            self.againOneFlashcardLabel:setString(flashcard)
        else
            self.againOneCardAct:play("Gem", false)
        end
    end
end

function UIShowCard:setUIInfo(heroName, heroStar, heroLevel)
	local tipHero = CommonHelper.getUIString(105)
	if heroName then
		heroName = string.format(tipHero, heroName)
	else
		heroName = ""
	end
	
	local starActName = "Normal" .. heroStar
	--设置星星个数
	self.uiStarAct:play(starActName, false)
	--英雄获得提示
	self.getHeroNameNode:setString(heroName)
end

function UIShowCard:openEndCallFunc(frame)
	if self.colorAct then 
		self.colorAct:play("Flip", false)
		self.colorAct:setFrameEventCallFunc(handler(self, self.flipEndCallback))
	end
end

function UIShowCard:flipEndCallback(frame)
    if frame:getEvent() == "FlipEnd" then
        self.colorAct:clearFrameEventCallFunc()
        -- 转成碎片
        if self.heroInfo.addType == 2 then
            local tips = string.format(CommonHelper.getUIString(1707),self.heroInfo.addCount)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/PieceNum"):setString(self.heroInfo.addCount)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/PieceTips"):setString(tips)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/AwardName_1"):setString(heroFragText)
            self.colorAct:play("Piece", false)
        -- 转成粉尘
        elseif self.heroInfo.addType == 3 then
            local tips = string.format(CommonHelper.getUIString(1708),self.heroInfo.addCount)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/PieceNum"):setString(self.heroInfo.addCount)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/PieceTips"):setString(tips)
            CsbTools.getChildFromPath(self.colorNode, "CardPanel/Front/AwardName_1"):setString(heroEnergyText)
            self.colorAct:play("CardEnergry", false)
        else
            self.colorAct:play("Normal_F", true)
        end
    end
end

function UIShowCard:againCallback(obj, touchType)
    self.backInfo.isAgain = true
	UIManager.close()
end

return UIShowCard
