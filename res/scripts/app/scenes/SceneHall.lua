local SceneHall = class("SceneHall", function()
    return display.newScene("SceneHall")
end)

function SceneHall:ctor()
	self:setNodeEventEnabled(true) -- ¿ªÆôµ÷ÓÃonExit()
end

function SceneHall:onEnter()
	print("SceneHall:onEnter()")
    if UIManager.hasSave() then
        UIManager.loadUI()
    else
        UIManager.open(UIManager.UI.UIHallBG)
    end
end

return SceneHall
