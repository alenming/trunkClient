--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  商店物品购买界面
** 应  用:
********************************************************************/
--]]
require("common.WidgetExtend")

local userModel = getGameModel():getUserModel()
local shopModel = getGameModel():getShopModel()

local UIShopBuyHero = class("UIShopBuyHero", function()
    return require("common.UIView").new()
end)

UIShopBuyHero.coinType = {
    gold    = 1,    -- 金币
    arena   = 2,    -- 竞技场
    tower   = 3,    -- 爬塔
    diamond = 4,    -- 钻石
    union   = 5,    -- 公会币
}

UIShopBuyHero.coinImage = {
    [1] = "pub_gold.png",       -- 金币
    [2] = "pub_fightcoin.png",  -- 竞技场
    [3] = "pub_enfragment.png", -- 爬塔
    [4] = "pub_gem.png",        -- 钻石
    [5] = "pub_points.png",     -- 公会币
    [6] = "pub_rmb.png",        -- 人民币
}


-- 构造函数
function UIShopBuyHero:ctor()
    self.rootPath = ResConfig.UIShopBuyHero.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 语言包
    local titleLabel = getChild(self.root, "BagSale/SaleFontLabel")
    local priceText  = getChild(self.root, "BagSale/BuyPrice")
    local ConfrimText = getChild(self.root, "BagSale/SaleButton/NameText")
    titleLabel:setString(CommonHelper.getUIString(173))
    priceText:setString(CommonHelper.getUIString(71))
    ConfrimText:setString(CommonHelper.getUIString(971))

    -- 关闭按钮
    local btnClose = getChild(self.root, "BagSale/Button_Close")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 确认按钮
    self.btnConfrim = getChild(self.root, "BagSale/SaleButton")
    CsbTools.initButton(self.btnConfrim, handler(self, self.onClick),nil ,nil, "NameText")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIShopBuyHero:init(...)

end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIShopBuyHero:onOpen(openerUIID, shopType, data, index)
    if nil == data then
        return
    end

    self.shopType   = shopType        -- 商店id
    self.goodsData  = data
    self.cellIndex  = index
    self.index      = nil
    self.num        = nil

    self:initNetwork()
    self:initEvent()
    -- 设置物品信息
    self:setGoodsInfo()
    --
    self.btnConfrim:setTouchEnabled(true)
end

-- 每次界面Open动画播放完毕时回调
function UIShopBuyHero:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIShopBuyHero:onClose()
    self:removeNetwork()
    self:removeEvent()

    return self.index, self.num
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIShopBuyHero:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIShopBuyHero:onClick(obj)
    local btnName = obj:getName()
    if btnName == "Button_Close" then
        UIManager.close()
    elseif btnName == "SaleButton" then
        obj.soundId = nil
        -- 公会商店
        if self.shopType == ShopType.UnionShop then
            if not self:sendUnionBuyCmd() then
                obj.soundId = MusicManager.commonSound.fail
            end
        else
            if not self:sendBuyCmd() then
                obj.soundId = MusicManager.commonSound.fail
            end
        end
    end
end

-- 设置商品信息(图片、名称、描述、价格、货币类型)
function UIShopBuyHero:setGoodsInfo()
    if nil == self.goodsData then
        return
    end
    local nGoodsID = self.goodsData.nGoodsID
    if nil == nGoodsID or nGoodsID <= 0 then
        return
    end
    local nCoinType = self.goodsData.nCoinType
    if nCoinType < UIShopBuyHero.coinType.gold or nCoinType > UIShopBuyHero.coinType.union then
        return
    end
    local propCfg = getPropConfItem(nGoodsID)
    if nil == propCfg then
        return
    end
    self.propCfg = propCfg    
    
    local icon      = getChild(self.root, "BagSale/IconImage")              -- 物品图片
    local frame     = getChild(self.root, "BagSale/LevelImage")              -- 物品边框
    local name      = getChild(self.root, "BagSale/Name")                   -- 物品名称
    local desc      = getChild(self.root, "BagSale/Lv")                     -- 物品描述
    local price     = getChild(self.root, "BagSale/PriceLabel")             -- 物品价格
    local coin      = getChild(self.root, "BagSale/Image_bg/pub_gold_4")    -- 货币类型

    icon:loadTexture(propCfg.Icon, 1)
    frame:loadTexture(IconHelper.getSoldierHeadFrame(propCfg.Quality), 1)
    desc:setString(getHSLanConfItem(propCfg.Desc))
    coin:setSpriteFrame(UIShopBuyHero.coinImage[nCoinType])
    -- 名称
    local color = getItemLevelSettingItem(propCfg.Quality).Color
    name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
    name:setString(getHSLanConfItem(propCfg.Name))
    -- 价格
    local nSale = self.goodsData.nSale
    local nCoinNum  = self.goodsData.nCoinNum
    local cost = math.ceil(nCoinNum * nSale / 100)
    price:setString(string.format("%d", cost))
end


-- 初始化网络回调
function UIShopBuyHero:initNetwork()
    -- 注册普通商店购买网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopBuySC)
    self.buyHandler = handler(self, self.acceptBuyCmd)
    NetHelper.setResponeHandler(cmd, self.buyHandler)
end
-- 移除网络回调
function UIShopBuyHero:removeNetwork()
    -- 移除普通商店购买网络回调
    if self.buyHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopBuySC)
        NetHelper.removeResponeHandler(cmd, self.buyHandler)
        self.buyHandler = nil
    end
end

-- 发送普通商店购买请求
function UIShopBuyHero:sendBuyCmd()
    if nil == self.goodsData then
        return false
    end

    -- 价格
    local nSale = self.goodsData.nSale
    local nCoinNum  = self.goodsData.nCoinNum
    local cost = math.ceil(nCoinNum * nSale / 100)
    if self:checkBuy(cost) then
        self.btnConfrim:setTouchEnabled(false)
        --
        local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopBuyCS)
        buffData:writeInt(1)           -- 商品数量
        buffData:writeChar(self.shopType)      -- 商店类型
        buffData:writeChar(self.goodsData.nIndex) -- 商品索引
       
        NetHelper.request(buffData)
        return true
    end

    return false
end

-- 接收普通商店购买请求
function UIShopBuyHero:acceptBuyCmd(mainCmd, subCmd, buffData)
    self.num = buffData:readInt()
    self.index = buffData:readChar()
  

    EventManager:raiseEvent(GameEvents.EventShopBuy, {shopType = self.shopType, count = self.num})

    UIManager.close()
end

-- 发送公会商店购买请求
function UIShopBuyHero:sendUnionBuyCmd()
    if nil == self.goodsData then
        return false
    end

    local goods = shopModel:getUnionSHopGoodsData(self.goodsData.nGoodsShopID)
    if goods and goods.nGoodsNum < 1 then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2055))
        return false
    end

    -- 价格
    local nSale = self.goodsData.nSale
    local nCoinNum = self.goodsData.nCoinNum
    local cost = math.ceil(nCoinNum * nSale / 100)
    if self:checkBuy(cost) then
        self.btnConfrim:setTouchEnabled(false)
        --
        local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopUnionBuyCS)
        buffData:writeShort(self.goodsData.nGoodsShopID)      -- 商品id
        buffData:writeChar(1)                                -- 商品数量
        NetHelper.request(buffData)
        return true
    end

    return false
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIShopBuyHero:initEvent()
    -- 添加公会商店购买事件监听
    self.eventUnionBuyHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionShopBuy, self.eventUnionBuyHandler)
    -- 添加公会操作事件监听
    self.eventUnionFuncHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionFunc, self.eventUnionFuncHandler)
end

-- 移除事件回调
function UIShopBuyHero:removeEvent()
    -- 移除公会商店购买事件监听
    if self.eventUnionBuyHandler then
        EventManager:removeEventListener(GameEvents.EventUnionShopBuy, self.eventUnionBuyHandler)
        self.eventUnionBuyHandler = nil
    end
    -- 移除公会操作事件监听
    if self.eventUnionFuncHandler then
        EventManager:removeEventListener(GameEvents.EventUnionFunc, self.eventUnionFuncHandler)
        self.eventUnionFuncHandler = nil
    end
end

-- 公会商店购买
function UIShopBuyHero:onEventCallback(eventName, args)
    if eventName == GameEvents.EventUnionShopBuy then
        local userModel = getGameModel():getUserModel()
        local userID = userModel:getUserID()
        if userID == args.userID then
            self.num = args.buyNum
            self.index = self.cellIndex

            EventManager:raiseEvent(GameEvents.EventShopBuy, {shopType = self.shopType, count = args.buyNum})

            UIManager.close()
        end
    elseif eventName == GameEvents.EventUnionFunc then
        -- 被踢出公会
        if args.funcType == UnionHelper.FuncType.Kick then
            UIManager.close()
        end
    end
end


-- 检测购买的物品,弹出相关提示
function UIShopBuyHero:checkBuy(cost)
    if nil == self.goodsData then
        return
    end

    local nCoinType = self.goodsData.nCoinType
    if nCoinType == UIShopBuyHero.coinType.gold then     -- 金币
        if userModel:getGold() < cost then
            UIManager.open(UIManager.UI.UIGold)
            return false
        end
    elseif nCoinType == UIShopBuyHero.coinType.arena then    -- 竞技场
        if userModel:getPVPCoin() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1304))
            return false
        end
    elseif nCoinType == UIShopBuyHero.coinType.tower then    -- 爬塔
        if userModel:getTowerCoin() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1305))
            return false
        end
    elseif nCoinType == UIShopBuyHero.coinType.union then    -- 公会币
        if userModel:getUnionContrib() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2043))
            return false
        end
    elseif nCoinType == UIShopBuyHero.coinType.diamond then  -- 钻石
        if userModel:getDiamond() < cost then
            -- 进入充值提示界面
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
            return false
        end
    end

    -- 提示框
    local function dialogTips(lang)
        local params = {}
        params.msg = CommonHelper.getUIString(lang)
        params.confirmFun = function () UIManager.close() end
        params.cancelFun = function () print("nothing to do...") end
        UIManager.open(UIManager.UI.UIDialogBox, params)
    end

    if 3 ~= self.propCfg.Type and 4 ~= self.propCfg.Type then
        if not ModelHelper.checkBagCapacity(self.goodsData.nGoodsID, 1) then
            dialogTips(118)
            return false
        end
    end

    return true
end

-- 如果自动刷新商店的时候该界面显示了就调用
function UIShopBuyHero:autoRefresh(nowTime)
    local shopModelData = shopModel:getShopModelData(self.shopType)
    if shopModelData then
        self.goodsData  = shopModelData.GoodsData[self.cellIndex]
    end
    if nil == self.goodsData then
        return
    end
    -- 设置物品信息
    self:setGoodsInfo()
end

return UIShopBuyHero