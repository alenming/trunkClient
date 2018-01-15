--[[
    PVP匹配场景
]]

local ScenePvp = class("ScenePvp", function()
    return display.newScene("ScenePvp")
end)

function ScenePvp:ctor()
	self:setNodeEventEnabled(true) -- 开启调用onExit()
end

function ScenePvp:onEnter()
	print("ScenePvp:onEnter()")
    local pvpModel = getGameModel():getPvpModel()
    if pvpModel:getPvpInfo().BattleId > 0 then
        UIManager.open(UIManager.UI.UIReconnect)
    else
        UIManager.open(UIManager.UI.UIArenaMatch)
    end
end

return ScenePvp
