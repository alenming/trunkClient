local SceneTowerTrial = class("SceneTowerTrial", function()
    return display.newScene("SceneTowerTrial")
end)

function SceneTowerTrial:ctor()
	self:setNodeEventEnabled(true) -- 开启调用onExit()
end

function SceneTowerTrial:onEnter()
	print("SceneTowerTrial:onEnter()")
    if UIManager.hasSave() then
        UIManager.loadUI()
    else
        UIManager.open(UIManager.UI.UITowerTest)
    end
end

return SceneTowerTrial
