--世界场景
local SceneWorld = class("SceneWorld", function()
    return display.newScene("SceneWorld")
end)

--构造函数
function SceneWorld:ctor()
    self:setNodeEventEnabled(true) 
end

function SceneWorld:onEnter()
    if UIManager.hasSave() then
        UIManager.loadUI()
    else
        UIManager.open(UIManager.UI.UIMap)
    end
end

return SceneWorld