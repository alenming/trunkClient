--[[
	十连抽管理, 处理卡片信息设置, 显示, 长按播放抖动动画, 
	一键翻牌, 再来一次, 返回事件回调
	2015-09-10 by wsz
]]

require("common.CommonHelper")

local UIDrawCardTen = class("UIDrawCardTen", function ()
	return require("common.UIView").new()
end)

local aniName = {"Grey", "Green", "Blue", "Voilet", "Orange", "Yellow", "Colorful"}
local lightB = "ui_new/g_gamehall/d_drawcard/effect/CardLight_B.csb"
local lightF = "ui_new/g_gamehall/d_drawcard/effect/CardLight_F.csb"

--资源
local csbResShowTen = ResConfig.UIDrawCard.Csb2.ten
local csbResHeroCard = ResConfig.UIDrawCard.Csb2.heroCard
local csbResHeroGoldCard = ResConfig.UIDrawCard.Csb2.heroGoldCard
local csbResHeroSilverCard = ResConfig.UIDrawCard.Csb2.heroSilverCard
local csbResBigStar = ResConfig.UIDrawCard.Csb2.bigStar
local csbResAgainPanel = ResConfig.UIDrawCard.Csb2.againPanel
local csbResAgainBtn = ResConfig.UIDrawCard.Csb2.againBtn
local csbResBackBtn = ResConfig.UIDrawCard.Csb2.backBtn
local csbResDrawCardPrice = "ui_new/g_gamehall/d_drawcard/DrawCardPrice.csb"

local heroFragText = CommonHelper.getUIString(1282)
local heroEnergyText = CommonHelper.getUIString(1281)

local scheduler = require("framework.scheduler")

function isAnimationPlay(animation, actionName)
	local curFrame = animation:getCurrentFrame()
	local startFrame = animation:getAnimationInfo(actionName).startIndex
	local endFrame = animation:getAnimationInfo(actionName).endIndex
	if (curFrame >= startFrame and curFrame <= endFrame) then 
		return true
	end
	return false
end

function UIDrawCardTen:ctor()
	--抽10张卡主件
   	self.root = getResManager():getCsbNode(csbResShowTen)
	self.rootAct = cc.CSLoader:createTimeline(csbResShowTen)
    self:addChild(self.root)

    self.backInfo = {}
    self.backInfo.isAgain = false
    self.backInfo.buyCardType = 1
   
	local gameSetting = getCardGambleSettingConfItem()
	local oneKeyText = CommonHelper.getUIString(108)
	local againText = CommonHelper.getUIString(106)
	local backText = CommonHelper.getUIString(107)
	local againDiamondText = gameSetting.DiamondCardGamble10Price

    -- 卡片信息 
    self.cardInfos = {}
    -- 一键翻牌, 待翻完之后才播放整卡的卡片信息     
    self.finalCardInfos = {}
    self.heroCard = {}
    self.cardNodes = {}
    -- 卡片对应金银节点
    self.cardColorActs = {} 
	--初始化10(1-10)个卡片节点
	for i = 1, 10 do
		local nodeName = "TenCardPanel/Card_".. i
        local cardButton = CsbTools.getChildFromPath(self.root, nodeName)
		cardButton:setTouchEnabled(true)
		-- 添加点击事件
	    cardButton:addTouchEventListener(handler(self, self.onClickActionCallFunc))

        self.heroCard[i] = CsbTools.getChildFromPath(cardButton, "SummonerCard")
	end

	--按钮节点
	self.buttonNode = CsbTools.getChildFromPath(self.root, "TenCardPanel/AgainButtonPanel")
	self.buttonAct = cc.CSLoader:createTimeline(csbResAgainPanel)

	--一键翻牌按钮
	self.showAllBtn = CsbTools.getChildFromPath(self.buttonNode, "OneKeyFlipButton")
	self.showAllBtn:setTitleText(oneKeyText)

	--再来一次按钮
	self.againBtn = CsbTools.getChildFromPath(self.buttonNode, "AgainTenButton")
	self.againBtn:setTitleText(againText)

    --抽卡券
    self.againTenCardPrice = CsbTools.getChildFromPath(self.buttonNode, "AgainTenButton/DrawCardPrice")
    self.againTenCardAct = cc.CSLoader:createTimeline(csbResDrawCardPrice)
    -- "抽卡券"数量
    self.againTenFlashcardLabel = CsbTools.getChildFromPath(self.againTenCardPrice, "CardNum")
    -- 抽一次价格"200"(设置一次就可以了)
    CsbTools.getChildFromPath(self.againTenCardPrice, "GemNum"):setString(againDiamondText)
    -- "抽卡券*1"(设置一次就可以了)
    CsbTools.getChildFromPath(self.againTenCardPrice, "Card"):setString(CommonHelper.getUIString(598))
    -- "免费"文字(设置一次就可以了)
    CsbTools.getChildFromPath(self.againTenCardPrice, "Free"):setString(CommonHelper.getUIString(104))
    -- 替换十连抽卡券图片
    CsbTools.replaceImg(CsbTools.getChildFromPath(self.againTenCardPrice, "CardIcon"), "icon_flashcard_02.png")

	--返回按钮
	self.backBtn =  CsbTools.getChildFromPath(self.buttonNode, "BackButton")
	self.backBtn:setTitleText(backText)

	--动作
	self.root:runAction(self.rootAct)
	self.buttonNode:runAction(self.buttonAct)
    self.againTenCardPrice:runAction(self.againTenCardAct)

	--回调
    CsbTools.initButton(self.showAllBtn, handler(self, self.showAllCallback))
	CsbTools.initButton(self.againBtn, handler(self, self.againCallback))
	CsbTools.initButton(self.backBtn, handler(self, self.backCallback))
	--适配
	CommonHelper.layoutNode(self.root)
end

function UIDrawCardTen:onOpen(fromUI, cards, goldenCards, silverCards)
    print("UIDrawCardTen:onOpen cards", cards)
    self.isShowAll = false
    self.isAllCardShowing = false
    self.goldenCards = goldenCards
    self.silverCards = silverCards
    self.backInfo.isAgain = false
    self.cardInfos = cards

    self:showCardOrDiamond()

    for i, v in ipairs(cards) do
        print("UIDrawCardTen:onOpen i v", i, v)
        self:setHeroCardInfo(i, v.cardId, v.star, v.heroLv)
    end

	self.root:setVisible(true)
	self.root:setTouchEnabled(true)
	self.rootAct:play("Open", false)
	-- 显示一键翻牌
	self.buttonAct:play("OneKeyFlip", false)
end

function UIDrawCardTen:onTop(fromUI, ...)
    --[[if self.isShowAll then
        self:nextCard()
    end]]
end

function UIDrawCardTen:onClose()
	self.rootAct:play("Close", false)
	--执行关闭后设置不可见, 不可点击
	self.root:setVisible(false)
	self.root:setTouchEnabled(false)

    for i= 1, 10 do
        if self.cardNodes[i] then 
            self.cardColorActs[i]:play("Normal_B", false)
            --self.cardNodes[i] = nil
            --self.cardColorActs[i] = nil
        end 
    end

    if self.showUpdate then
        scheduler.unscheduleGlobal(self.showUpdate)
        self.showUpdate = nil
    end

    return self.backInfo
end

function UIDrawCardTen:setHeroCardInfo(cardNumber, cardId, star, heroLv)
	local colorNode = nil
	local cardNode = self.heroCard[cardNumber]

	--获得英雄配置数据, 获得名字
	local heroConfig = getSoldierConfItem(cardId, star)
	if (heroConfig == nil) then
		print("cannot found hero config, hero not exsit!")
	end
  
    --[[local oldGCard = cardNode:getChildByTag(1024)
    local oldSCard = cardNode:getChildByTag(1023)

    if oldSCard then
        self.silverCards:freeCsb(oldSCard)
        oldSCard:removeFromParent(false)
    end
    if oldGCard then
        self.goldenCards:freeCsb(oldGCard)
        oldGCard:removeFromParent(false)
    end

	if heroConfig.Rare < 3 then
        colorNode = self.silverCards:getCsb()
        colorNode:setTag(1023)
        --colorNode = getResManager():cloneCsbNode(csbResHeroSilverCard)
		self.cardColorActs[cardNumber] = cc.CSLoader:createTimeline(csbResHeroSilverCard)
	else
        colorNode = self.goldenCards:getCsb()
        colorNode:setTag(1024)
        --colorNode = getResManager():cloneCsbNode(csbResHeroGoldCard)
		self.cardColorActs[cardNumber] = cc.CSLoader:createTimeline(csbResHeroGoldCard)
	end
    cardNode:addChild(colorNode)

	colorNode:runAction(self.cardColorActs[cardNumber])

    self.cardNodes[cardNumber] = colorNode
    self.cardColorActs[cardNumber]:setTag(cardNumber)
	self.cardColorActs[cardNumber]:play("Normal_B", true)
    ]]
    colorNode = cardNode:getChildByTag(1024)
    if not colorNode then
        colorNode = getResManager():cloneCsbNode(csbResHeroGoldCard)
        colorNode:setTag(1024)
        self.cardNodes[cardNumber] = colorNode
	    self.cardColorActs[cardNumber] = cc.CSLoader:createTimeline(csbResHeroGoldCard)
       
	    colorNode:runAction(self.cardColorActs[cardNumber])
        self.cardColorActs[cardNumber]:setTag(cardNumber)
        cardNode:addChild(colorNode)
    end

	self.cardColorActs[cardNumber]:play("Normal_B", true)
    
    UICommHelper.setHeroCardInfo(colorNode, cardId, star, heroLv)
end

--卡片是否可以翻
function UIDrawCardTen:canCardFlip(cardNumber)
	if isAnimationPlay(self.cardColorActs[cardNumber], "Flip") 
		or isAnimationPlay(self.cardColorActs[cardNumber], "Normal_F") 
        or isAnimationPlay(self.cardColorActs[cardNumber], "CardEnergry") 
        or isAnimationPlay(self.cardColorActs[cardNumber], "Piece") then
		return false
	end
	return true
end

function UIDrawCardTen:nextCard()
    for i = 1, 10 do
        if self:canCardFlip(i) then
            self:show(i)
            if self.isAllCardShowing then
                self.finalCardInfos[i] = {}
                self.finalCardInfos[i] = self.cardInfos[i]
            end
            return
        end
	end

    self.isShowAll = true
end

function UIDrawCardTen:show(cardNumber)
	--翻过来
	self.cardColorActs[cardNumber]:play("Flip", false)
	--翻完之后播放"Normal_F"动作
	self.cardColorActs[cardNumber]:setFrameEventCallFunc(handler(self, self.flipEndCallback))

    if self.cardInfos[cardNumber] then
        if self.cardInfos[cardNumber].star > 3 then
            MusicManager.playSoundEffect(15)
        else
            MusicManager.playSoundEffect(14)
        end
    end
end

function UIDrawCardTen:flipEndCallback(frame)
    local action = frame:getTimeline():getActionTimeline()
    local tag = action:getTag()
    --如果全翻过来就切换按钮
    local allFilp = true
	for i = 1, 10 do
		if self:canCardFlip(i) then
			allFilp = false
		end
	end
    if allFilp then
      -- 切换按钮状态
        self.buttonAct:play("Again", false)
    end
            
    if frame:getEvent() == "FlipEnd" then
        if self.cardInfos[tag].addType == 2 then
            -- 转成碎片
            local tips = string.format(CommonHelper.getUIString(1707),self.cardInfos[tag].addCount)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/PieceNum"):setString(self.cardInfos[tag].addCount)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/PieceTips"):setString(tips)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/AwardName_1"):setString(heroFragText)
            self.cardColorActs[tag]:play("Piece", false)
        elseif self.cardInfos[tag].addType == 3 then
            -- 转成粉尘
            local tips = string.format(CommonHelper.getUIString(1708),self.cardInfos[tag].addCount)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/PieceNum"):setString(self.cardInfos[tag].addCount)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/PieceTips"):setString(tips)
            CsbTools.getChildFromPath(self.cardNodes[tag], "CardPanel/Front/AwardName_1"):setString(heroEnergyText)
            self.cardColorActs[tag]:play("CardEnergry", false)
        else
            -- 新卡牌, 显示新卡牌
            self.cardColorActs[tag]:play("Normal_F", true)
            if not self.isAllCardShowing then
                UIManager.open(UIManager.UI.UIShowCard, 0, self.cardInfos[tag])
            end
        end
    end
end

function UIDrawCardTen:onClickActionCallFunc(obj, touchType)
	local objName = obj:getName()
	local index = string.gsub(objName, "Card_", "")
	index = tonumber(index)
	-- 通过"begin"播放普通点击特效
	-- 通过"ended"翻卡片
	-- "cancel"恢复正常, 不进行翻牌
	if self:canCardFlip(index) then
		if touchType == 0 then -- 开始翻卡
			self.cardColorActs[index]:play("On_B", true)
		elseif touchType == 2 then --翻卡
			self:show(index)
        elseif touchType == 3 then --取消翻卡
			self.cardColorActs[index]:play("Normal_B", true)
		end
	end
end

--一键翻牌, 显示10张卡
function UIDrawCardTen:showAllCallback(obj)
    if self.isAllCardShowing then
        return
    end
    self.isAllCardShowing = true
    self:nextCard()
    
    self.showUpdate = scheduler.scheduleGlobal(function(dt) 
		self:nextCard()
        if self.isShowAll then
            for _, cardInfo in pairs(self.finalCardInfos) do
                if cardInfo.addType == 1 then
                    UIManager.open(UIManager.UI.UIShowCard, 0, cardInfo)
                end
            end
            -- 移除计时器
            scheduler.unscheduleGlobal(self.showUpdate)
            self.showUpdate = nil
        end
	end, 0.2)
end

-- 显示
function UIDrawCardTen:showCardOrDiamond()
    --如果有"10连抽卡券"
    local flashcard10 = getGameModel():getUserModel():getFlashcard10()
    if flashcard10 > 0 then
        self.againTenCardAct:play("Card", false)
        self.againTenFlashcardLabel:setString(flashcard10)
    else
        self.againTenCardAct:play("Gem", false)
    end
end

--再抽一次
function UIDrawCardTen:againCallback(obj)
	self.backInfo.isAgain = true
    UIManager.close()
end

--返回
function UIDrawCardTen:backCallback(obj)
    UIManager.close()
end

return UIDrawCardTen
