--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  商店材料购买界面
** 应  用:
********************************************************************/
--]]
require("common.WidgetExtend")
local PropTips = require("game.comm.PropTips")

local userModel = getGameModel():getUserModel()
local shopModel = getGameModel():getShopModel()

local UIShopBuyMeterial = class("UIShopBuyMeterial", function()
    return require("common.UIView").new()
end)

UIShopBuyMeterial.coinType = {
    gold    = 1,    -- 金币
    arena   = 2,    -- 竞技场
    tower   = 3,    -- 爬塔
    diamond = 4,    -- 钻石
    union   = 5,    -- 公会币
}

UIShopBuyMeterial.coinImage = {
    [1] = "pub_gold.png",       -- 金币
    [2] = "pub_fightcoin.png",  -- 竞技场
    [3] = "pub_enfragment.png", -- 爬塔
    [4] = "pub_gem.png",        -- 钻石
    [5] = "pub_points.png",     -- 公会币
    [6] = "pub_rmb.png",        -- 人民币
}

-- 构造函数
function UIShopBuyMeterial:ctor()
    self.rootPath = ResConfig.UIShopBuyMeterial.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 语言包
    local titleLabel = getChild(self.root, "BagSale/SaleFontLabel")
    local buyNumText = getChild(self.root, "BagSale/Text_1")
    local priceText  = getChild(self.root, "BagSale/BuyPrice")
    local ConfrimText = getChild(self.root, "BagSale/SaleButton/NameText")
    titleLabel:setString(CommonHelper.getUIString(173))
    buyNumText:setString(CommonHelper.getUIString(69))
    priceText:setString(CommonHelper.getUIString(71))
    ConfrimText:setString(CommonHelper.getUIString(971))

    -- 关闭按钮
    local btnClose = getChild(self.root, "BagSale/Button_Close")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 减
    local btnDel = getChild(self.root, "BagSale/DelButton")
    WidgetExtend.extendHold(btnDel)
    btnDel:addHoldCallbackEX(0.1, 0, handler(self, self.onClick))
    CsbTools.initButton(btnDel, handler(self, self.onClick))

    --加
    local btnAdd = getChild(self.root, "BagSale/AddButton")
    WidgetExtend.extendHold(btnAdd)
    btnAdd:addHoldCallbackEX(0.1, 0, handler(self, self.onClick))
    CsbTools.initButton(btnAdd, handler(self, self.onClick))

    -- Max 按钮
    local btnMax = getChild(self.root, "BagSale/MaxButton")
    CsbTools.initButton(btnMax, handler(self, self.onClick))
    btnMax:setTitleText(CommonHelper.getUIString(65))

    -- 确认按钮
    self.btnConfrim = getChild(self.root, "BagSale/SaleButton")
    CsbTools.initButton(self.btnConfrim, handler(self, self.onClick), nil, nil, "NameText")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIShopBuyMeterial:init(...)

end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIShopBuyMeterial:onOpen(openerUIID, shopType, data, index)
    if nil == data then
        return
    end

    self.propTips   = PropTips.new()
    self.shopType   = shopType        -- 商店id
    self.goodsData  = data
    self.cellIndex  = index
    self.buyNum     = 1             -- 购买个数
    self.index      = nil
    self.num        = nil

    self:initNetwork()
    self:initEvent()
    -- 设置物品信息
    self:setGoodsInfo()
    -- 设置购买信息
    self:setBuyInfo() 
    self:hideDelBtn()
    --
    self.btnConfrim:setTouchEnabled(true)
end

-- 每次界面Open动画播放完毕时回调
function UIShopBuyMeterial:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIShopBuyMeterial:onClose()
    self:removeNetwork()
    self:removeEvent()

    if self.propTips then
        self.propTips:removePropAllTips()
        self.propTips = nil
    end

    return self.index, self.num
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIShopBuyMeterial:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIShopBuyMeterial:onClick(obj)
    local btnName = obj:getName()
    if btnName == "Button_Close" then
        UIManager.close()
    elseif btnName == "DelButton" then
        self:delBuyNum()
    elseif btnName == "AddButton" then
        self:addBuyNum()
    elseif btnName == "MaxButton" then
        self:maxBuyNum()
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

-- 设置商品信息(图片、名称、描述)
function UIShopBuyMeterial:setGoodsInfo()
    if nil == self.goodsData then
        return
    end
    local nGoodsID = self.goodsData.nGoodsID
    if nil == nGoodsID or nGoodsID <= 0 then
        return
    end
    local nCoinType = self.goodsData.nCoinType
    if nCoinType < UIShopBuyMeterial.coinType.gold or nCoinType > UIShopBuyMeterial.coinType.union then
        return
    end
    local propConf = getPropConfItem(nGoodsID)
    if nil == propConf then
        return
    end
    self.propConf = propConf

    -- 道具图标
    local allItem 	= getChild(self.root, "BagSale/AllItem")
    UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
    -- 道具tips
    local touchPanel = getChild(allItem, "MainPanel")
    self.propTips:addPropTips(touchPanel, self.propConf)

    local name      = getChild(self.root, "BagSale/Name")                 -- 物品名称
    local desc      = getChild(self.root, "BagSale/Text_3")               -- 物品描述
    local color = getItemLevelSettingItem(propConf.Quality).Color
    name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
    name:setString(getPropLanConfItem(propConf.Name))
    desc:setString(getPropLanConfItem(propConf.Desc))
end

-- 设置购买信息(个数、价格、货币类型)
function UIShopBuyMeterial:setBuyInfo()
    if nil == self.goodsData then
        return
    end

    local number    = getChild(self.root, "BagSale/NumLabel")             -- 购买数量
    local price     = getChild(self.root, "BagSale/PriceLabel")           -- 购买价格
    local coin      = getChild(self.root, "BagSale/Image_bg/pub_gold_4")  -- 货币类型

    -- 数量
    if self.buyNum > self.goodsData.nGoodsNum then
        self.buyNum = self.goodsData.nGoodsNum
    end
    number:setString(self.buyNum)
    -- 货币类型
    local nCoinType = self.goodsData.nCoinType
    coin:setSpriteFrame(UIShopBuyMeterial.coinImage[nCoinType])
    -- 价格
    local nSale     = self.goodsData.nSale
    local nCoinNum  = self.goodsData.nCoinNum
    local buyNum    = self.buyNum
    local cost      = math.ceil(nCoinNum * buyNum * nSale / 100)
    price:setString(string.format("%d", cost))
end

-- 当物品个数只有一个，隐藏减按钮
function UIShopBuyMeterial:hideDelBtn()
    if 1 == self.goodsData.nGoodsNum then
        --getChild(self.root, "BagSale/DelButton"):setVisible(false)
    else
        getChild(self.root, "BagSale/DelButton"):setVisible(true)
    end
end

-- 减购买个数
function UIShopBuyMeterial:delBuyNum()
    if self.buyNum > 1 then
        self.buyNum = self.buyNum - 1
        self:setBuyInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(73))
    end
end

-- 加购买个数
function UIShopBuyMeterial:addBuyNum()
    if nil == self.goodsData then
        return
    end

    if self.buyNum < self.goodsData.nGoodsNum then
        self.buyNum = self.buyNum + 1
        self:setBuyInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(72))
    end
end

-- 最大购买个数
function UIShopBuyMeterial:maxBuyNum()
    if nil == self.goodsData then
        return
    end

    self.buyNum = self.goodsData.nGoodsNum
    self:setBuyInfo()
end


-- 初始化网络回调
function UIShopBuyMeterial:initNetwork()
    -- 注册普通商店购买网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopBuySC)
    self.buyHandler = handler(self, self.acceptBuyCmd)
    NetHelper.setResponeHandler(cmd, self.buyHandler)
end
-- 移除网络回调
function UIShopBuyMeterial:removeNetwork()
    -- 移除普通商店购买网络回调
    if self.buyHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopBuySC)
        NetHelper.removeResponeHandler(cmd, self.buyHandler)
        self.buyHandler = nil
    end
end

-- 发送普通商店购买请求
function UIShopBuyMeterial:sendBuyCmd()
    if nil == self.goodsData then
        return false
    end

    -- 价格
    local nSale     = self.goodsData.nSale
    local nCoinNum  = self.goodsData.nCoinNum
    local buyNum    = self.buyNum
    local cost      = math.ceil(nCoinNum * buyNum * nSale / 100)
    if self:checkBuy(cost) then
        self.btnConfrim:setTouchEnabled(false)
        --
        local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopBuyCS)
        buffData:writeInt(buyNum)           -- 商品数量
        buffData:writeChar(self.shopType)      -- 商店类型
        buffData:writeChar(self.goodsData.nIndex) -- 商品索引
        
        NetHelper.request(buffData)
        return true
    end

    return false
end

-- 接收普通商店购买请求
function UIShopBuyMeterial:acceptBuyCmd(mainCmd, subCmd, buffData)
    self.num = buffData:readInt()
    self.index = buffData:readChar()
    
    EventManager:raiseEvent(GameEvents.EventShopBuy, {shopType = self.shopType, count = self.num})

    UIManager.close()
end

-- 发送公会商店购买请求
function UIShopBuyMeterial:sendUnionBuyCmd()
    if nil == self.goodsData then
        return false
    end

    local goods = shopModel:getUnionSHopGoodsData(self.goodsData.nGoodsShopID)
    if goods and goods.nGoodsNum < 1 then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2055))
        return false
    end
    if goods and goods.nGoodsNum < self.buyNum then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2056))
        return false
    end

    -- 价格
    local nSale = self.goodsData.nSale
    local nCoinNum = self.goodsData.nCoinNum
    local buyNum    = self.buyNum
    local cost      = math.ceil(nCoinNum * buyNum * nSale / 100)
    if self:checkBuy(cost) then
        self.btnConfrim:setTouchEnabled(false)
        --
        local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopUnionBuyCS)
        buffData:writeShort(self.goodsData.nGoodsShopID)      -- 商品id
        buffData:writeChar(buyNum)                           -- 商品数量
        NetHelper.request(buffData)
        return true
    end

    return false
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIShopBuyMeterial:initEvent()
    -- 添加公会商店购买事件监听
    self.eventUnionBuyHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionShopBuy, self.eventUnionBuyHandler)
    -- 添加公会操作事件监听
    self.eventUnionFuncHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionFunc, self.eventUnionFuncHandler)
end

-- 移除事件回调
function UIShopBuyMeterial:removeEvent()
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
function UIShopBuyMeterial:onEventCallback(eventName, args)
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
function UIShopBuyMeterial:checkBuy(cost)
    if nil == self.goodsData then
        return
    end

    local nCoinType = self.goodsData.nCoinType
    if nCoinType == UIShopBuyMeterial.coinType.gold then     -- 金币
        if userModel:getGold() < cost then
            UIManager.open(UIManager.UI.UIGold)
            return false
        end
    elseif nCoinType == UIShopBuyMeterial.coinType.arena then    -- 竞技场
        if userModel:getPVPCoin() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1304))
            return false
        end
    elseif nCoinType == UIShopBuyMeterial.coinType.tower then    -- 爬塔
        if userModel:getTowerCoin() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1305))
            return false
        end
    elseif nCoinType == UIShopBuyMeterial.coinType.union then    -- 公会币
        if userModel:getUnionContrib() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2043))
            return false
        end
    elseif nCoinType == UIShopBuyMeterial.coinType.diamond then  -- 钻石
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

    if 3 ~= self.propConf.Type and 4 ~= self.propConf.Type then
        if not ModelHelper.checkBagCapacity(self.goodsData.nGoodsID, 1) then
            dialogTips(118)
            return false
        end
    end

    return true
end

-- 如果自动刷新商店的时候该界面显示了就调用
function UIShopBuyMeterial:autoRefresh(nowTime)
    local shopModelData = shopModel:getShopModelData(self.shopType)
    if shopModelData then
        self.goodsData  = shopModelData.GoodsData[self.cellIndex]
    end
    if nil == self.goodsData then
        return
    end
    self.buyNum     = 1             -- 购买个数
    -- 设置物品信息
    self:setGoodsInfo()
    -- 设置购买信息
    self:setBuyInfo()
end

return UIShopBuyMeterial