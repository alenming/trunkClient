local SceneLogin = class("SceneLogin", function()
    return display.newScene("SceneLogin")
end)

function SceneLogin:ctor()
	self:setNodeEventEnabled(true) -- ¿ªÆôµ÷ÓÃonExit()
end

function SceneLogin:onEnter()
    httpAnchor(1001)
	print("SceneLogin:onEnter()")
    if UIManager.hasSave() then
        UIManager.loadUI()
    else
        UIManager.open(UIManager.UI.UILogin)
    end
end

return SceneLogin
