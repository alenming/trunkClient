--
-- Author: dadada
-- Date: 2015-11-20 18:20:50
--

local BattleConfig = {}

function BattleConfig:OnStageBegin(stageId)

end

function BattleConfig:OnStageEnd()
	print("=======================!!!!!!!! callOnStageEnd!!!")
	--获得RoomModel获得结算信息
	local model = getGameModel():getRoom()
	if true then
		--打开ui结算场景
		UIManager.open(UIManager.UI.UISettleAccount, model:getStageId())

		--local uiSettle = require("ui.UISettleAccount").new()
		--[[local layer= require("ui.UISettleAccount").new()
   		layer:init(model:getStageId())
		layer:setGlobalZOrder(5)
		display.getRunningScene():addChild(layer, 5, 100000)
		--layer:showLose()
		layer:initWithModelAndShow()]]
		print("=======================!!!!!!!! show!!")
	else
		--其它结算界面
		-- ...
	end
end

return BattleConfig
