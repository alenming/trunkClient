--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征区域地图
** 应  用:
********************************************************************/
--]]
local scheduler = require("framework.scheduler")

local expeditionModel = getGameModel():getExpeditionModel()

local UIExpeditionHelpTips = class("UIExpeditionHelpTips", function()
    return require("common.UIView").new()
end)

function UIExpeditionHelpTips:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionHelpTips:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionHelpTips.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    mainPanel:setTouchEnabled(true)
    CsbTools.initButton(mainPanel, handler(self, self.onClick))

    local layout = ccui.Layout:create()
    layout:setBackGroundColorType(1);
    layout:setBackGroundColor(cc.c3b(8, 12, 18))
    layout:setBackGroundColorOpacity(225)
    layout:setName("preventTouch")
    layout:setContentSize(display.width, display.height)
    layout:setTouchEnabled(false)
    self.root:addChild(layout, -1)
    ccui.Helper:doLayout(layout)
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionHelpTips:onOpen(openerUIID, stage)
    local descText = CsbTools.getChildFromPath(self.root, "MainPanel/TalkText")
    descText:setString(CommonHelper.getStageString(stage.headDesc or 0))
    local nameText = CsbTools.getChildFromPath(self.root, "MainPanel/TitleText")
    nameText:setString(CommonHelper.getStageString(stage.headName or 0))
    local headNode = CsbTools.getChildFromPath(self.root, "MainPanel/Head")
    local head = cc.CSLoader:createNode(stage.headRes)
    if head then
        local action = cc.CSLoader:createTimeline(stage.headRes)
        head:runAction(action)
        action:play(stage.headTag, false)
        headNode:addChild(head)
    else
        print("Head Res Load Error", stage.headRes)
    end
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionHelpTips:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionHelpTips:onClose()

end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionHelpTips:onTop(preUIID, ...)

end

-- 当前界面点击回调
function UIExpeditionHelpTips:onClick(obj)
    local btnName = obj:getName()
    if btnName == "MainPanel" then             -- 返回
        UIManager.close()
    end
end

return UIExpeditionHelpTips