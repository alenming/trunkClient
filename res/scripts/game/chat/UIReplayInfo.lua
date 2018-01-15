--[[
回放战斗信息
]]

local UIReplayInfo = class("UIReplayInfo", function()
    return require("common.UIView").new()
end)

function UIReplayInfo:ctor()

end

function UIReplayInfo:init()
    self.rootPath = ResConfig.UIReplayInfo.Csb2.replayInfo
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.replayPanel = CsbTools.getChildFromPath(self.root, "MainPanel/ReplayPanel")
    self.timeLb = CsbTools.getChildFromPath(self.replayPanel, "Time")
end

function UIReplayInfo:onOpen(fromUI, replayInfo)
    UIReplayHelper.setReplayNode(self.replayPanel, replayInfo)
end

function UIReplayInfo:onClose()

end

return UIReplayInfo