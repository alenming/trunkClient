--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-13 19:59
** 版  本:	1.0
** 描  述:  背包物品出售界面
** 应  用:
********************************************************************/
--]]
require("common.WidgetExtend")
require("game.comm.UIAwardHelper")

local UIBagSale = class("UIBagSale", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIBagSale:ctor()
    self.rootPath = ResConfig.UIBagSale.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 关闭按钮
    local btnClose = getChild(self.root, "BagSale/Button_Close")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 长按时间
    self.holdTime = 0
    -- 减
    local btnDel = getChild(self.root, "BagSale/DelButton")
    WidgetExtend.extendHold(btnDel)
    btnDel:addHoldCallbackEX(0.5, 0, handler(self, self.delBuyNum), handler(self, self.resetHoldTime))
    CsbTools.initButton(btnDel, handler(self, self.delBuyNum))

    --加
    local btnAdd = getChild(self.root, "BagSale/AddButton")
    WidgetExtend.extendHold(btnAdd)
    btnAdd:addHoldCallbackEX(0.5, 0, handler(self, self.addBuyNum), handler(self, self.resetHoldTime))
    CsbTools.initButton(btnAdd, handler(self, self.addBuyNum))

    -- Max 按钮
    local btnMax = getChild(self.root, "BagSale/MaxButton")
    CsbTools.initButton(btnMax, handler(self, self.maxBuyNum))

    -- 确认按钮
    local btnConfrim = getChild(self.root, "BagSale/SaleButton")
    CsbTools.initButton(btnConfrim, handler(self, self.onClick), nil, nil, "NameText")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIBagSale:init(...)

end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIBagSale:onOpen(openerUIID, data, callback)
    if nil == data then
        return
    end
    self.itemData   = data
    self.callback   = callback
    self.saleNum    = 1

    -- 设置物品信息
    self:setItemInfo()
    -- 设置出售信息
    self:setSaleInfo()
end

-- 每次界面Open动画播放完毕时回调
function UIBagSale:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIBagSale:onClose()
    if self.saleHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.SaleSC)
        NetHelper.removeResponeHandler(cmd, self.saleHandler)
        self.saleHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIBagSale:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIBagSale:onClick(obj)
    local btnName = obj:getName()
    if btnName == "Button_Close" then
        UIManager.close()
    elseif btnName == "SaleButton" then
        self:sendSaleCmd()
    end
end

-- 设置物品信息(图片、名称、个数)
function UIBagSale:setItemInfo()
    if nil == self.itemData then
        return
    end
    --信息
    local icon  = getChild(self.root, "BagSale/Image_bg/IconImage")
    local level = getChild(self.root, "BagSale/Image_bg/LevelImage")
    local name  = getChild(self.root, "BagSale/NameLabel")
    local count = getChild(self.root, "BagSale/CountLabel")

    local cfg = getPropConfItem(self.itemData.config_id)
    if cfg then
        CsbTools.replaceImg(icon, cfg.Icon)
        CsbTools.replaceImg(level, getItemLevelSettingItem(cfg.Quality).ItemFrame)
        name:setString(getPropLanConfItem(cfg.Name))
        local color = getItemLevelSettingItem(cfg.Quality).Color
        name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
    end
    count:setString(tostring(self.itemData.count))
end

-- 设置出售信息(个数、价格)
function UIBagSale:setSaleInfo()
    if nil == self.itemData then
        return
    end
    local number    = getChild(self.root, "BagSale/NumLabel")             -- 购买数量
    local price     = getChild(self.root, "BagSale/PriceLabel")           -- 购买价格

    if self.saleNum > self.itemData.count then
        self.saleNum = self.itemData.count
    elseif self.saleNum < 1 then
        self.saleNum = 1
    end
    local cfg = getPropConfItem(self.itemData.config_id)
    local cost = cfg.SellPrice * self.saleNum

    number:setString(tostring(self.saleNum))
    price:setString(string.format("%d", cost))
end

-- 减出售个数
function UIBagSale:delBuyNum()
    self.holdTime = self.holdTime + 0.5
    if self.saleNum > 1 then
        if self.holdTime >= 4 then
            self.saleNum = self.saleNum - (5 * math.floor(self.holdTime) - 15)
        else
            self.saleNum = self.saleNum - 1
        end
        self:setSaleInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(67))
    end
end

-- 加出售个数
function UIBagSale:addBuyNum()
    if nil == self.itemData then
        return
    end
    self.holdTime = self.holdTime + 0.5
    if self.saleNum < self.itemData.count then
        if self.holdTime >= 4 then
            self.saleNum = self.saleNum + (5 * math.floor(self.holdTime) - 15)
        else
            self.saleNum = self.saleNum + 1
        end
        self:setSaleInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(66))
    end
end

-- 最大出售个数
function UIBagSale:maxBuyNum()
    if nil == self.itemData then
        return
    end
    self.saleNum = self.itemData.count
    self:setSaleInfo()
end

-- 重置长按时间
function UIBagSale:resetHoldTime()
    self.holdTime = 0
end

-- 发送出售请求
function UIBagSale:sendSaleCmd()
    if nil == self.itemData then
        return
    end
    -- 注册出售命令
    local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.SaleSC)
    self.saleHandler = handler(self, self.acceptSaleCmd)
    NetHelper.setResponeHandler(cmd, self.saleHandler)

    local buffData = NetHelper.createBufferData(MainProtocol.Bag, BagProtocol.SaleCS)
    buffData:writeInt(self.itemData.unique_id)   -- 出售ID
    buffData:writeInt(self.saleNum)              -- 出售数量
    NetHelper.request(buffData)
end

-- 接收出售请求
function UIBagSale:acceptSaleCmd(mainCmd, subCmd, buffData)
    -- 注销出售命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.saleHandler)
    self.saleHandler = nil

    local id    = buffData:readInt()     -- 出售id
    local num   = buffData:readInt()     -- 出售数量
    local gold  = buffData:readInt()     -- 获得金币
    if self.callback and type(self.callback) == "function" then
        self.callback(id, num)
    end
    -- 设置金币信息
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, gold)

    UIManager.close()
end

return UIBagSale