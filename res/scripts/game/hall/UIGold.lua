--[[
金币购买界面
]]

local UIGold = class("UIGold", function()
    return require("common.UIView").new()
end)

local UILanguage = {maxTimes = 2, buyTimes = 3, confirm = 500, cancel = 501
    , unEnoughDiamond = 210, vipInfo = 502, toFast = 342, unEnoughTimes = 390}
local GoldTipsLang = {[1] = 204, [2] = 205, [5] = 206, [10] = 207} -- 倍数提示
local GoldEffect = {birth = 8, add = 13} -- 音效

function UIGold:ctor()
end

function UIGold:init()
    self.rootPath = ResConfig.Common.Csb2.buyGold
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    CsbTools.getChildFromPath(self.root, "BuyGoldPanel/TipLabel3"):setString(CommonHelper.getUIString(624))
    CsbTools.getChildFromPath(self.root, "BuyGoldPanel/TipsText_2"):setString(CommonHelper.getUIString(389))

    self:initUI()
end

function UIGold:initUI()
    self.buyButton = CsbTools.getChildFromPath(self.root, "BuyGoldPanel/BuyButton/BuyButton")
    CsbTools.initButton(self.buyButton, handler(self, self.buyGoldCallBack), nil, nil, "Node")

    self.buyTimesLb = CsbTools.getChildFromPath(self.root, "BuyGoldPanel/TimesUse")
    self.totalTimesLb = CsbTools.getChildFromPath(self.root, "BuyGoldPanel/TimesConut")
    self.costDiamondLb = CsbTools.getChildFromPath(self.buyButton, "Node/ButtonName")
    self.GoldSumLb = CsbTools.getChildFromPath(self.root, "BuyGoldPanel/GoldSum")
    self.totalTimesLb:setString("/" .. #getIncreasePayItemList())

    self.assretPanel = CsbTools.getChildFromPath(self.root, "AssretPanel")
    self.goldLb = CsbTools.getChildFromPath(self.assretPanel, "AssetPanel/GoldCountLabel")
    self.diamondLb = CsbTools.getChildFromPath(self.assretPanel, "AssetPanel/GemCountLabel")
end

function UIGold:onOpen(fromUIID, ...)
    self.isOverTouchGold = true

    local userModel = getGameModel():getUserModel()
    self.buyGoldTimes = userModel:getBuyGoldTimes()
    self.showGoldCount = userModel:getGold()

    self:showBuyInfo()
    self:updateCallBack()

    self.goldLb:setString(getGameModel():getUserModel():getGold())

    self:initEvent()
end

function UIGold:onClose()
    self:removeEvent()
end

function UIGold:onTop()
    self:showBuyInfo()
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIGold:initEvent()
    -- 监听刷新货币
    self.updateHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventReceiveCurrency, self.updateHandler)
    -- 添加金币刷新事件监听
    self.eventUpdateGoldHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUpdateGold, self.eventUpdateGoldHandler)
end

-- 移除事件回调
function UIGold:removeEvent()
    -- 移除刷新货币监听
    if self.updateHandler then
        EventManager:removeEventListener(GameEvents.EventReceiveCurrency, self.updateHandler)
        self.updateHandler = nil
    end
    -- 移除金币刷新事件监听
    if self.eventUpdateGoldHandler then
        EventManager:removeEventListener(GameEvents.EventUpdateGold, self.eventUpdateGoldHandler)
        self.eventUpdateGoldHandler = nil
    end
end

function UIGold:onEventCallback(eventName, ...)
    if eventName == GameEvents.EventReceiveCurrency then
        self:updateCallBack()
    elseif eventName == GameEvents.EventUpdateGold then
        --CommonHelper.playCsbAnimation(self.assretPanel, "AddGold", false, nil)
    end
end

function UIGold:buyGoldCallBack(obj)
    obj.soundId = nil
    -- 次数判断
    if self.buyGoldTimes >= #getIncreasePayItemList() then
        obj.soundId = MusicManager.commonSound.confirm
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(370))
        return
    end
    -- 货币判断
--    if getIncreasePayConfItem(self.buyGoldTimes + 1).GoldCost > getGameModel():getUserModel():getDiamond() then
--        obj.soundId = MusicManager.commonSound.fail
--        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.unEnoughDiamond))
--        return
--    end

    CommonHelper.checkConsumeCallback(2, getIncreasePayConfItem(self.buyGoldTimes + 1).GoldCost, function ()
        local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.BuyCS)
	    buffData:writeInt(1)
        buffData:writeInt(1)
        -- 发送购买金币消息
	    NetHelper.requestWithTimeOut(buffData, 
            NetHelper.makeCommand(MainProtocol.User, UserProtocol.BuySC), 
            handler(self, self.onResponeBuyGold)) 
    end)
end

function UIGold:onResponeBuyGold(mainCmd, subCmd, data)
    local attrType = data:readInt()
    local addCount = data:readInt()
    local result = data:readInt()
    local extend = data:readInt()

    if 1 == result and 1 == attrType then
        self.buyGoldTimes = self.buyGoldTimes + 1
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, addCount * extend)
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -getIncreasePayConfItem(self.buyGoldTimes).GoldCost)
     
        getGameModel():getUserModel():setBuyGoldTimes(self.buyGoldTimes)
        -- 点金事件
        EventManager:raiseEvent(GameEvents.EventTouchGloden)

        self:showBuyInfo()
        -- 暴击提示
        if extend > 0 then
            local tips = string.format(CommonHelper.getUIString(GoldTipsLang[extend]), addCount * extend)
            CsbTools.addTipsToRunningScene(tips, {color = cc.c3b(255, 0, 0)})        
        end

        -- 金币获得动画
        local UIItemAnimation = require("game.hall.UIItemAnimation").new(addCount, extend, self, 
            "ui_new/g_gamehall/g_gpub/BuyGoldEf.csb", function(addCount)
                self.showGoldCount = self.showGoldCount + addCount
                self.goldLb:setString(math.ceil(self.showGoldCount))
                CommonHelper.playCsbAnimation(self.assretPanel, "AddGold", false, nil)
            end)

        MusicManager.playSoundEffect(GoldEffect.add)
    end
end

function UIGold:showBuyInfo()
    if self.buyGoldTimes >= #getIncreasePayItemList() then
        CommonHelper.playCsbAnimate(self.buyButton, "ui_new/g_gamehall/g_gpub/BuyButton.csb", "Cant", nil, true)
        self.costDiamondLb:setString(CommonHelper.getUIString(UILanguage.unEnoughTimes))
    else
        local conf = getIncreasePayConfItem(self.buyGoldTimes + 1)
        if not conf then
            print(">>>error<<< getIncreasePayConfItem is nil", self.buyGoldTimes + 1)
            return
        end

        self.costDiamondLb:setString(conf.GoldCost)
        CommonHelper.playCsbAnimate(self.buyButton, "ui_new/g_gamehall/g_gpub/BuyButton.csb", "Can", nil, true)
        
        local userLevelItem = getUserLevelSettingConfItem(getGameModel():getUserModel():getUserLevel())
        if not userLevelItem then
            print(">>>error<<< getUserLevelSettingConfItem is nil", getGameModel():getUserModel():getUserLevel())
            return
        end

        self.GoldSumLb:setString(userLevelItem.BuyCoin[1])
        if conf.GoldCost > getGameModel():getUserModel():getDiamond() then
            self.costDiamondLb:setColor(cc.c3b(255, 0, 0))
        else
            self.costDiamondLb:setColor(cc.c3b(255, 255, 255))
        end
    end

    self.buyTimesLb:setString(self.buyGoldTimes)
end

function UIGold:updateCallBack()
    local userModel = getGameModel():getUserModel()
    --self.goldLb:setString(userModel:getGold())
    self.diamondLb:setString(userModel:getDiamond())
end

return UIGold
