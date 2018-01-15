--[[
金币购买界面
]]

local UIEquipMakeTip = class("UIEquipMakeTip", function()
    return require("common.UIView").new()
end)


function UIEquipMakeTip:ctor()
end

function UIEquipMakeTip:init()

    self.rootPath = ResConfig.UITowerTest.Csb2.tip
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    self:initUI()
end

function UIEquipMakeTip:initUI()
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
        , handler(self, self.sureCallBack), CommonHelper.getUIString(500)
        , "Button_Confrim/Text", "Text")
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
        , function () UIManager.close() end, CommonHelper.getUIString(501)
        , "Button_Cancel/Text", "Text")


    self.mTitel = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BarNameLabel")
    self.mTitel:setString(CommonHelper.getUIString(605))  --分解


    self.mTipLabel1_0 = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel1")
    self.mTipLabel1_0:setString(CommonHelper.getUIString(1249))

end

function UIEquipMakeTip:onOpen(preId, callBack)
    self.mCallBack = callBack
end

function UIEquipMakeTip:onClose()
end

function UIEquipMakeTip:onTop()

end

function UIEquipMakeTip:sureCallBack(obj)
    self.mCallBack()
    UIManager.close()
end

return UIEquipMakeTip


