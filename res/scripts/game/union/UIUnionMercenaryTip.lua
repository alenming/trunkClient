--[[
    派遣人数不足时的,提示充值
]]

local UIUnionMercenaryTip = class("UIUnionMercenaryTip", function()
    return require("common.UIView").new()
end)


function UIUnionMercenaryTip:ctor()
end

function UIUnionMercenaryTip:init()

    self.rootPath = ResConfig.UITowerTest.Csb2.tip
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    self:initUI()
end

function UIUnionMercenaryTip:initUI()

    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
        , handler(self, self.sureCallBack), CommonHelper.getUIString(500)
        , "Button_Confrim/Text", "Text")
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
        , function () UIManager.close() end, CommonHelper.getUIString(501)
        , "Button_Cancel/Text", "Text")


    self.mTitel = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BarNameLabel")
    self.mTitel:setString(CommonHelper.getUIString(605))  --分解


    self.mTipLabel1_0 = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel1")
    self.mTipLabel1_0:setString(CommonHelper.getUIString(2038))

end

function UIUnionMercenaryTip:onOpen()

end

function UIUnionMercenaryTip:onClose()
end

function UIUnionMercenaryTip:onTop()

end

function UIUnionMercenaryTip:sureCallBack(obj)
    
end



return UIUnionMercenaryTip
