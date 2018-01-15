--[[
    实现抽卡界面的召唤大厅显示, 单次抽卡, 十次抽卡功能. 与服务器交互
    的网络协议发送和解析也在这里实现, 显卡卡片界面不需要理会网络收发
    和数据改变.
	2016-08-22 by wsz
]]

local UIDrawCard = class("UIDrawCard", function ()
	return require("common.UIView").new()
end)

local scheduler = require("framework.scheduler")
local RichLabel = require("richlabel.RichLabel")

local BUY_ONE_CARD = 0
local BUY_TEN_CARD = 1

--界面资源
local csbResMainLayer 	= ResConfig.UIDrawCard.Csb2.main
local csbResFreeOnce 	= "ui_new/g_gamehall/d_drawcard/FreeOnece.csb"
local csbResDrawOnePrice = "ui_new/g_gamehall/d_drawcard/DrawCardPrice.csb"

function UIDrawCard:ctor()
    --print("================UIDrawCard:ctor=====================")
	--模型
	self.userModel = getGameModel():getUserModel()
	--文字
	local barText = CommonHelper.getUIString(98)
	local tipFreeHeroText = CommonHelper.getUIString(103)
	local tenBtnText = CommonHelper.getUIString(101)

	--配置钻石个数
	local gameSetting = getCardGambleSettingConfItem()
	self.oneCardDiamond = gameSetting.DiamondCardGamblePrice
	self.tenCardDiamond = gameSetting.DiamondCardGamble10Price

	--主界面, 整个界面
	self.root = getResManager():getCsbNode(csbResMainLayer) 
    self.mainAct = cc.CSLoader:createTimeline(csbResMainLayer)

    self:addChild(self.root)
	--主背景
	self.mainBgNode = CsbTools.getChildFromPath(self.root, "MainPanel")
	-- 天空层
	self.skyNode = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/Image_sky")
    self.skyNode:setTouchEnabled(false)
	-- "抽一次"按钮
	self.oneBtnTouch = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/OneceButton")
	-- "抽十次"按钮
	self.tenBtnTouch = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TenButton")

    -- 单次抽卡或"抽卡券"节点
    self.drawOneCardPrice = CsbTools.getChildFromPath(self.oneBtnTouch, "DrawOneceButton/DrawButton/Price")
    self.drawOneCardAct = cc.CSLoader:createTimeline(csbResDrawOnePrice)
    -- "抽卡券"数量
    self.drawOneFlashcardLabel = CsbTools.getChildFromPath(self.drawOneCardPrice, "CardNum")
    -- 隐藏9折
    CsbTools.getChildFromPath(self.oneBtnTouch, "DrawOneceButton/DrawButton/DiscountBar"):setVisible(false)
    -- 抽一次价格"200"(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawOneCardPrice, "GemNum"):setString(self.oneCardDiamond)
    -- "抽卡券*1"(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawOneCardPrice, "Card"):setString(CommonHelper.getUIString(598))
    -- "免费"文字(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawOneCardPrice, "Free"):setString(CommonHelper.getUIString(104))
     
    -- "抽十次"金额
	self.drawTenCardPrice = CsbTools.getChildFromPath(self.tenBtnTouch, "DrawTenButton/DrawButton/Price")
    self.drawTenCardAct = cc.CSLoader:createTimeline(csbResDrawOnePrice)
    -- "抽卡券"数量
    self.drawTenFlashcardLabel = CsbTools.getChildFromPath(self.drawTenCardPrice, "CardNum")
    -- 抽一次价格"1888"(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawTenCardPrice, "GemNum"):setString(self.tenCardDiamond)
    -- "抽卡券*1"(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawTenCardPrice, "Card"):setString(CommonHelper.getUIString(598))
    -- "免费"文字(设置一次就可以了)
    CsbTools.getChildFromPath(self.drawTenCardPrice, "Free"):setString(CommonHelper.getUIString(104))
    -- 替换十连抽卡券图片
    CsbTools.replaceImg(CsbTools.getChildFromPath(self.drawTenCardPrice, "CardIcon"), "icon_flashcard_02.png")

	-- 提示凌晨5点
	self.freeLabel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TipLabel_rd")
	self.freeLabel:setString(tipFreeHeroText)

    -- 中间箱子
	--self.boxNode = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BoxPanel/BoxNode")
	--召唤师大厅节点
	--self.barLabel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BarLabel")
	--self.barLabel:setString(barText)
	--货币提示节点
	self.tipDiamond = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GemItem/GemCountLabel")
	--返回按钮节点
	self.backBtn = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BackButton")
    --提示可抽取3星英雄剩余次数节点
	local tip3StarLabel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TipPanel/TipLabel")
    --CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TipPanel"):setVisible(true)
	
	--设置action
	self.root:runAction(self.mainAct)
    self.drawOneCardPrice:runAction(self.drawOneCardAct)
    self.drawTenCardPrice:runAction(self.drawTenCardAct)
	--按钮回调
    CsbTools.initButton(self.backBtn, handler(self, self.backCallback))
	CsbTools.initButton(self.oneBtnTouch, handler(self, self.extractOne), nil, "DrawOneceButton")
	CsbTools.initButton(self.tenBtnTouch, handler(self, self.extractTen), nil, "DrawTenButton")

    self.mainAct:setFrameEventCallFunc(handler(self, self.mainActionCallback))

    --女巫师
    local beautyNode = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/JsonPanel/Node")
    self.beautySpine = getResManager():createSpine("ui_new/g_gamehall/d_drawcard/effect/json/C_chou.json")
    beautyNode:addChild(self.beautySpine)
    self.beautySpine:setAnimation(0, "Stand1", true)

    --[[local fairy1Node = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/JsonPanel/Node_Fairy1")
    local fairy2Node = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/JsonPanel/Node_Fairy2")

    self.fairy1 = getResManager():createSpine("ui_new/g_gamehall/d_drawcard/effect/json/Fairy.json")
    fairy1Node:addChild(self.fairy1)
    self.fairy2 = getResManager():createSpine("ui_new/g_gamehall/d_drawcard/effect/json/Fairy.json")
    fairy2Node:addChild(self.fairy2)

    self.fairy1:setAnimation(0, "Stand1", true)
    self.fairy2:setAnimation(0, "Stand1", true)]]
    --适配
	CommonHelper.layoutNode(self.root)
end

function UIDrawCard:onOpen()
    self.isShowing = false
    self.firstLoad = true
    self.boomOver = false
    self.preloadOver = false
	--添加网络监听
	local cmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.BuyCardSC)
	self.onRespCallback = handler(self, self.onResponeCallback)
	NetHelper.setResponeHandler(cmd, self.onRespCallback)
	
    --每2秒1次检查是否免费
	self.updateFunc = scheduler.scheduleGlobal(function(dt) 
		self:showCardOrDiamond()
	end, 2.0)

	--钻石数量
    self.tipDiamond:setString(self.userModel:getDiamond())

    -- 避免一段时间后才显示免费
    self:showCardOrDiamond()
    -- 设置按钮显示
    self:setButtonEnabled(true)

    self.mainAct:play("Normal", true)
    --self.boxNode:setVisible(true)
	--self.boxNode:getAnimation():play("Normal", -1, 0)

    --self.mainAct:clearFrameEventCallFunc()
end

function UIDrawCard:onClose()
	--移除网络监听
	local cmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.BuyCardSC)
	NetHelper.removeResponeHandler(cmd, self.onRespCallback)
	--取消每2秒1次的计时
	scheduler.unscheduleGlobal(self.updateFunc)
    --清理预加载数据
    self:clearCSB()
end

function UIDrawCard:onTop(fromUI, backInfo)
    self.isShowing = false
    self.boomOver = false 
    self.preloadOver = false
    --切回普通状态
    self.mainAct:play("Normal", false)
    --self.boxNode:getAnimation():play("Normal", -1, 0)
    
    if not backInfo then
        return
    end

    if backInfo.isAgain then
        if self:checkBuyCard(backInfo.buyCardType) then
            self:setButtonEnabled(false)
            -- 发送抽卡
            self:requestExtractCard(backInfo.buyCardType)
            self.isShowing = true
        else
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
            MusicManager.playFailSoundEffect()
            self:setButtonEnabled(true)
        end
    else
        self:setButtonEnabled(true)
    end
end

-- 设置抽卡按钮状态
function UIDrawCard:setButtonEnabled(enabled)
    self.oneBtnTouch:setVisible(enabled)
    self.tenBtnTouch:setVisible(enabled)
end

--显示卡片或钻石
function UIDrawCard:showCardOrDiamond()
    if getGameModel():isFreePickCard() then
	    self.drawOneCardAct:play("Free", false)
    else
        --如果有"抽卡券"
        local flashcard = self.userModel:getFlashcard()
        if flashcard > 0 then
            self.drawOneCardAct:play("Card", false)
            self.drawOneFlashcardLabel:setString(flashcard)
        else
            self.drawOneCardAct:play("Gem", false)
        end
    end

    local flashcard10 = self.userModel:getFlashcard10()
    if flashcard10 > 0 then
        self.drawTenCardAct:play("Card", false)
        self.drawTenFlashcardLabel:setString(flashcard10)
        CsbTools.getChildFromPath(self.tenBtnTouch, "DrawTenButton/DrawButton/DiscountBar"):setVisible(false)
    else
        self.drawTenCardAct:play("Gem", false)
        CsbTools.getChildFromPath(self.tenBtnTouch, "DrawTenButton/DrawButton/DiscountBar"):setVisible(true)
    end
end

function UIDrawCard:showCard()
	if #self.cards > 1 then
		UIManager.open(UIManager.UI.UIDrawCardTen, self.cards, self.goldenCards, self.silverCards)
    else
        UIManager.open(UIManager.UI.UIShowCard, 1, self.cards[1])
	end
end

--消耗钻石 
function UIDrawCard:costDiamond(buyType)
	local haveDiamond = self.userModel:getDiamond()
    local costDiamond = 0
    local costFlashcard = 0
    local costFlashcard10 = 0
	--抽一次
	if buyType == BUY_ONE_CARD then
		--如果免费抽取, 不扣钱
		if getGameModel():isFreePickCard() then
            local freeTimes = self.userModel:getFreeHeroTimes()
			self.userModel:setFreeHeroTimes(freeTimes - 1)
			self:showCardOrDiamond()
        --使用抽卡券
		elseif self.userModel:getFlashcard() > 0 then
            costFlashcard = 1
        else
			costDiamond = self.oneCardDiamond
		end
	--抽十次
	elseif buyType == BUY_TEN_CARD then
        if self.userModel:getFlashcard10() > 0  then
            costFlashcard10 = 1
        else
        	costDiamond = self.tenCardDiamond
        end
	end

    if costFlashcard10 > 0 then
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Flashcard10, -costFlashcard10)
        self:showCardOrDiamond()
	elseif costFlashcard > 0 then
    	ModelHelper.addCurrency(UIAwardHelper.ResourceID.Flashcard, -costFlashcard)
        self:showCardOrDiamond()
    elseif costDiamond > 0 then
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -costDiamond)
        self.tipDiamond:setString(haveDiamond - costDiamond)
    end
end

-- 钻石是否足够
function UIDrawCard:isDiamondEnough(buyType)
	local haveDiamond = self.userModel:getDiamond()
 	local needDiamond = 0 
 	if buyType == BUY_ONE_CARD then
 		needDiamond = self.oneCardDiamond
 	else
 		needDiamond = self.tenCardDiamond
 	end
 	return haveDiamond >= needDiamond
end

function UIDrawCard:hideDrawCardButton(isHide)
    if isHide then
        self.oneBtnTouch:setVisible(false)
        self.tenBtnTouch:setVisible(false)
    else
        self.oneBtnTouch:setVisible(true)
        self.tenBtnTouch:setVisible(true)
    end
end

--显示卡片获得界面之前先播放的一系列动作
function UIDrawCard:prepareChange(cardCount)
	--阻挡后面的按钮点击
	self:setButtonEnabled(false)
	--播放盒子动画
    if cardCount == 1 then    
        MusicManager.playSoundEffect(28)
	elseif cardCount == 10 then
        MusicManager.playSoundEffect(29)
	else
		print("drawCard count is error", cardCount)
        return
	end

    self.beautySpine:setAnimation(0, "Choose1", true)
    self.spineDelayFunc = scheduler.scheduleGlobal(function(dt) 
		scheduler.unscheduleGlobal(self.spineDelayFunc)
        self.mainAct:play("DrawCard", false)
	end, 1.0)
    --self.boxNode:getAnimation():play("Open", -1, 0)
    --self.boxNode:getAnimation():setFrameEventCallFunc(handler(self, self.boxBoomCallback))
end

function UIDrawCard:mainActionCallback(frame)
    print("========================================== UIDrawCard:mainActionCallback !!!!!!!!!!!")
    if frame:getEvent() == "BoomTime" then
        self:showCard()
        self.beautySpine:setAnimation(0, "Stand1", true)
    end
end

function UIDrawCard:boxBoomCallback(bone, frameEventName, originFrameIndex, currentFrameIndex)
	print("=========== FrameBoomTime frameEventName ===========")
	if frameEventName == "BoomTime" then
        self.boomOver = true
        if self.boomOver and self.preloadOver then
            self:showCard()
        end
	end
end

-- 服务器消息返回回调
function UIDrawCard:onResponeCallback(maincmd, subcmd, bufferData)
	--分析数据包
    local cardCount = bufferData:readInt()
	print("cardCount" .. cardCount)

    if 1 ~= cardCount and 10 ~= cardCount then
        print("when parse the buy hero card package, card count not equal to 1 or 10!")
		return
    end
    self.cards = {}
    for i = 1, cardCount do
		local heroId = bufferData:readInt()
		local star = bufferData:readInt()
        -- 类型: 1. 整卡 2.碎片 3. 金币
		local addType, addCount = ModelHelper.AddHero(heroId, 1, star) 
        print("add hero type count", addType, addCount)
        self.cards[i] = {cardId = heroId, heroLv = 1, star = star, 
            addType = addType, addCount = addCount}
    end
    
    --扣钱
    self:costDiamond(1 == cardCount and 0 or 1)   
    -- 播放盒子爆炸动画
	self:prepareChange(cardCount)
    if self.firstLoad and cardCount >= 10 then
        self.firstLoad = false
        self:preloadCSB()
    else
        self.preloadOver = true
    end
    -- 抽卡事件
    EventManager:raiseEvent(GameEvents.EventDrawCard, {drawCardType = cardCount == 1 and 1 or 2})
end

function UIDrawCard:preloadCSB() 
    self.goldenCards = require("common.CsbNodePool").new(ResConfig.UIDrawCard.Csb2.heroGoldCard)
    self.silverCards = require("common.CsbNodePool").new(ResConfig.UIDrawCard.Csb2.heroSilverCard)

    self.goldenCards:preload(10, nil, handler(self, self.loadOverCSB))
    self.silverCards:preload(10, nil, handler(self, self.loadOverCSB))
end

function UIDrawCard:clearCSB() 
    if self.goldenCards then
        self.goldenCards:clear()
    end

    if self.silverCards then
        self.silverCards:clear()
    end
end

function UIDrawCard:loadOverCSB()
    self.preloadOver = true
    if self.boomOver and self.preloadOver then
        self:showCard()
    end
end

--请求抽卡
function UIDrawCard:requestExtractCard(buyType)
    -- 发送抽卡信息
	local bufferData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.BuyCardCS)
	bufferData:writeInt(buyType)
	NetHelper.request(bufferData)
end

--抽一张回调
function UIDrawCard:extractOne(obj, touchType)
    if self.isShowing then
        return
    end
    obj.soundId = nil
	--每次发送抽一次计算一次是否免费
    if self:checkBuyCard(BUY_ONE_CARD) then
	    --封抽一次数据包, 发送到服务器
	    self:requestExtractCard(BUY_ONE_CARD)
        self.isShowing = true
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
        obj.soundId = MusicManager.commonSound.fail
	end
end

--抽十张回调
function UIDrawCard:extractTen(obj, touchType)
    if self.isShowing then
        return
    end
    obj.soundId = nil
	--每次发送抽一次计算一次是否免费
    if self:checkBuyCard(BUY_TEN_CARD) then
        --封抽十次数据包, 发送到服务器
	    self:requestExtractCard(BUY_TEN_CARD)
        self.isShowing = true
    else
 	    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
        obj.soundId = MusicManager.commonSound.fail
 	end
end

--返回大厅界面
function UIDrawCard:backCallback(obj)
    if not self.isShowing then
        UIManager.close()
    end
end

function UIDrawCard:checkBuyCard(buyCardType)
	if buyCardType == BUY_ONE_CARD then
	    if not self:isDiamondEnough(buyCardType) 
          and not getGameModel():isFreePickCard() 
          and self.userModel:getFlashcard() <= 0 then
		    return false
	    end
    else
        if self.userModel:getFlashcard10() <= 0 
          and not self:isDiamondEnough(buyCardType) then
 		    return false
 	    end
	end

    return true
end

return UIDrawCard
