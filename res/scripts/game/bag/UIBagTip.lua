--[[
金币购买界面
]]

local UIBagTip = class("UIBagTip", function()
    return require("common.UIView").new()
end)


function UIBagTip:ctor()
end

function UIBagTip:init()

    self.rootPath = ResConfig.UITowerTest.Csb2.tip
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)
    self.root:setVisible(false)
    self.saleNum    = 1
    self:initUI()
end

function UIBagTip:initUI()
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
        , handler(self, self.sendSaleCmd), CommonHelper.getUIString(500)
        , "Button_Confrim/Text", "Text")
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
        , function () UIManager.close() end, CommonHelper.getUIString(501)
        , "Button_Cancel/Text", "Text")

    self.mTitel = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BarNameLabel")
    self.mTitel:setString(CommonHelper.getUIString(62))  --出售

    self.mTipLabel1_0 = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel1")
    self.mTipLabel1_0:setString(CommonHelper.getUIString(398))

end

function UIBagTip:onOpen(preId, itemData,callBack)
    self.mCallBack = callBack
    self.itemData = itemData
    local propConf = getPropConfItem(self.itemData.config_id)
    if propConf.Type == 1 and propConf.Quality >2 then
        self.root:setVisible(true)
    elseif propConf.Type == 1 and propConf.Quality <=2 then
        self:sendSaleCmd()
    end
end

function UIBagTip:onClose()
    if self.saleHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.SaleSC)
        NetHelper.removeResponeHandler(cmd, self.saleHandler)
        self.saleHandler = nil
    end
end

function UIBagTip:onTop()

end

-- 发送出售请求
function UIBagTip:sendSaleCmd()
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
function UIBagTip:acceptSaleCmd(mainCmd, subCmd, buffData)
    -- 注销出售命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.saleHandler)
    self.saleHandler = nil

    local id    = buffData:readInt()     -- 出售id
    local num   = buffData:readInt()     -- 出售数量
    local gold  = buffData:readInt()     -- 获得金币
    if self.mCallBack and type(self.mCallBack) == "function" then
        self.mCallBack(id, num)
    end
    -- 设置金币信息
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, gold)
    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(134))
    UIManager.close()
end

function UIBagTip:sureCallBack(obj)
    self.mCallBack()
    UIManager.close()
end

return UIBagTip


