--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征区域设置界面
** 应  用:
********************************************************************/
--]]

local UIExpeditionAreaSet = class("UIExpeditionAreaSet", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIExpeditionAreaSet:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionAreaSet:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionAreaSet.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel1"):setString(CommonHelper.getUIString(1922))
    CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel2"):setString(CommonHelper.getUIString(1923))
    CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel5"):setString(CommonHelper.getUIString(1924))

    -- 取消按钮
    local cancelButton = CsbTools.getChildFromPath(self.root, "MainPanel/CancelButton")
    local cancelText =CsbTools.getChildFromPath(cancelButton, "ButtonName")
    CsbTools.initButton(cancelButton, handler(self, self.onClick),
        CommonHelper.getUIString(501), cancelText)
    -- 确定按钮
    local confrimButton = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
    local confrimText = CsbTools.getChildFromPath(confrimButton, "ButtonName")
    CsbTools.initButton(confrimButton, handler(self, self.onClick),
        CommonHelper.getUIString(500), confrimText)
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionAreaSet:onOpen(openerUIID, index)
print("UIExpeditionAreaSet:onOpen index", index)
    self.index = index

    local areaConf = getExpeditionItem(index)
    if not areaConf then return end

    -- 远征目标
    local nameLabel = CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel3")
    nameLabel:setString(CommonHelper.getStageString(areaConf.Expedition_Name))
    -- 远征期限
    local days = areaConf.Expedition_FightTime / 86400
    local daysLabel = CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel4")
    daysLabel:setString(string.format(CommonHelper.getUIString(1925), days))
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionAreaSet:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionAreaSet:onClose()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionAreaSet:onTop(preUIID, ...)
end

-- 当前界面点击事件回调
function UIExpeditionAreaSet:onClick(obj)
    local btnName = obj:getName()
    if btnName == "CancelButton" then             -- 返回
        UIManager.close()
    elseif btnName == "ConfrimButton" then      -- 远征排行
        self:sendAreaSetCmd()
    end
end

-- 发送区域设置的请求
function UIExpeditionAreaSet:sendAreaSetCmd()
    local areaConf = getExpeditionItem(self.index)
    if not areaConf then return end

    -- 区域ID
    local areaId = areaConf.Expedition_ID
print("UIExpeditionAreaSet:sendAreaSetCmd areaId", areaId)

    local buffData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.MapSetCS)
    buffData:writeInt(areaId)
    NetHelper.request(buffData)

    UIManager.close()
end

return UIExpeditionAreaSet