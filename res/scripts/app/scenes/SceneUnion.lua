--[[
	公会场景，主要实现以下内容
	1. 空场景, 用来添加工会的UI
--]]

local SceneUnion = class("SceneUnion", function()
    return display.newScene("SceneUnion")
end)

function SceneUnion:ctor()
    self:setNodeEventEnabled(true)	--开启调用onExit
end

function SceneUnion:onEnter()
    print("SceneUnion:onEnter()")
    if UIManager.hasSave() then
        UIManager.loadUI()
    else
        UIManager.open(UIManager.UI.UIUnion)
    end
end

return SceneUnion
