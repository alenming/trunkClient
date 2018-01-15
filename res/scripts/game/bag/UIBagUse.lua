--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-13 19:59
** 版  本:	1.0
** 描  述:  背包物品使用界面
** 应  用:
********************************************************************/
--]]
require("common.WidgetExtend")
require("game.comm.UIAwardHelper")

local MaxUseCount = 99

local UIBagUse = class("UIBagUse", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIBagUse:ctor()
    self.rootPath = ResConfig.UIBagUse.Csb2.main
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    getChild(self.root, "BagSale/Text_1_0"):setVisible(false)
    getChild(self.root, "BagSale/PriceLabel"):setVisible(false)
    getChild(self.root, "BagSale/Image_bg/pub_gold_4"):setVisible(false)
    getChild(self.root, "BagSale/Image_bg/Image_5"):setVisible(false)

    --语言包相关
    local titleLabel = getChild(self.root, "BagSale/SaleFontLabel")
    local buyNumText = getChild(self.root, "BagSale/Text_1")
    titleLabel:setString(CommonHelper.getUIString(1014))
    buyNumText:setString(CommonHelper.getUIString(1015))

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
    CsbTools.initButton(btnConfrim, handler(self, self.onClick))
end

-- 当界面被创建时回调
-- 只初始化一次
function UIBagUse:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIBagUse:onOpen(openerUIID, data, callback)
    if nil == data then
        return
    end

    self.itemData   = data
    self.callback   = callback
    self.useNum     = 1

    self:setItemInfo()
    self:setUseInfo()
end

-- 每次界面Open动画播放完毕时回调
function UIBagUse:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIBagUse:onClose()
    if self.useHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.UseSC)
        NetHelper.removeResponeHandler(cmd, self.useHandler)
        self.useHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIBagUse:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIBagUse:onClick(obj)
    local btnName = obj:getName()
    if btnName == "Button_Close" then
        UIManager.close()
    elseif btnName == "SaleButton" then
        self:sendUseCmd()
    end
end

-- 设置物品信息(图片、名称、个数)
function UIBagUse:setItemInfo()
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

-- 设置使用信息(个数)
function UIBagUse:setUseInfo()
    if nil == self.itemData then
        return
    end
    local number    = getChild(self.root, "BagSale/NumLabel")             -- 购买数量
    local count = self.itemData.count > MaxUseCount and MaxUseCount or self.itemData.count
    if self.useNum > count then
        self.useNum = count
    elseif self.useNum < 1 then
        self.useNum = 1
    end
    number:setString(tostring(self.useNum))
end

-- 减使用个数
function UIBagUse:delBuyNum()
    self.holdTime = self.holdTime + 0.5
    if self.useNum > 1 then
        if self.holdTime >= 4 then
            self.useNum = self.useNum - (5 * math.floor(self.holdTime) - 15)
        else
            self.useNum = self.useNum - 1
        end
        self:setUseInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1043))
    end
end

-- 加使用个数
function UIBagUse:addBuyNum()
    if nil == self.itemData then
        return
    end
    self.holdTime = self.holdTime + 0.5
    if self.useNum < self.itemData.count then
        if self.holdTime >= 4 then
            self.useNum = self.useNum + (5 * math.floor(self.holdTime) - 15)
        else
            self.useNum = self.useNum + 1
        end
        self:setUseInfo()
    else
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1017))
    end
end

-- 最大使用个数
function UIBagUse:maxBuyNum()
    if nil == self.itemData then
        return
    end
    self.useNum = self.itemData.count >= MaxUseCount and MaxUseCount or self.itemData.count
    self:setUseInfo()
end

-- 重置长按时间
function UIBagUse:resetHoldTime()
    self.holdTime = 0
end

-- 发送使用请求
function UIBagUse:sendUseCmd()
    if nil == self.itemData then
        return
    end
    -- 注册使用命令
    local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.UseSC)
    self.useHandler = handler(self, self.acceptUseCmd)
    NetHelper.setResponeHandler(cmd, self.useHandler)

    local buffData = NetHelper.createBufferData(MainProtocol.Bag, BagProtocol.UseCS)
    buffData:writeInt(self.itemData.unique_id)    -- 物品id
    buffData:writeInt(self.useNum)                -- 物品数量或装备配置id
    NetHelper.request(buffData)
    print("time is"..os.time())
end

-- 接收使用请求
function UIBagUse:acceptUseCmd(mainCmd, subCmd, buffData)
    -- 注销使用命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.useHandler)
    self.useHandler = nil
    print("time is"..os.time())
    -- 构造table, 显示奖励
    local propCount = buffData:readInt()    -- 打开个数
    local awardData = {}
    local dropInfo  = {}
    for i=1, propCount do
        dropInfo.id     = buffData:readInt()    -- 物品id
        dropInfo.num    = buffData:readInt()    -- 物品个数
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end

    if self.callback and type(self.callback) == "function" and nil ~= self.itemData then
        self.callback(self.itemData.unique_id, self.useNum)
    end
    print("time is"..os.time())
    -- 显示奖励
    UIManager.replace(UIManager.UI.UIAward, awardData)
    print("time is"..os.time())
end

return UIBagUse