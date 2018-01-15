require "game.qqHall.QQHallHelper"
local GameModel = getGameModel()
local BlueGemModel = GameModel:getBlueGemModel()
local UserModel = GameModel:getUserModel()

local NewPlayerPanelHelper = {}

local activeId = 2001
local taskId = 1

function NewPlayerPanelHelper.init(node)
	NewPlayerPanelHelper.mRoot = node

	NewPlayerPanelHelper.mNewBiePanel = CsbTools.getChildFromPath(NewPlayerPanelHelper.mRoot, "NewBiePanel")

	local blueDiamondCfgItem = getBlueDiamondConfig(activeId, taskId)
	if blueDiamondCfgItem then
		for i = 1, 5 do
			local reward = blueDiamondCfgItem.Reward3[i]
			if reward then
				local allItem = CsbTools.getChildFromPath(NewPlayerPanelHelper.mNewBiePanel, "AllItem_"..i)
				local propConf = getPropConfItem(reward.ID)
				UIAwardHelper.setAllItemOfConf(allItem, propConf, reward.num)
			end
		end
	end

	NewPlayerPanelHelper.mReceiveBtn = CsbTools.getChildFromPath(NewPlayerPanelHelper.mNewBiePanel, "ReceiveButton")
	NewPlayerPanelHelper.mReceiveBtnTex = CsbTools.getChildFromPath(NewPlayerPanelHelper.mNewBiePanel, "ReceiveButton/Text")
	CsbTools.initButton(NewPlayerPanelHelper.mReceiveBtn, function () 
		-- 领取礼包
		local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, BlueGemProtocol.BlueGemGetCS)
	    buffData:writeShort(activeId)
	    buffData:writeChar(taskId)
	    NetHelper.request(buffData)
	end)

	local blueGemType = UserModel:getBDType()
	local isBd = QQHallHelper:getBDInfo(blueGemType)
	NewPlayerPanelHelper.mReceiveBtn:setEnabled(isBd ~= 0)

	local adAttribute = BlueGemModel:getActivityById(activeId, taskId)
	if adAttribute and isBd ~= 0 then
		NewPlayerPanelHelper.mReceiveBtn:setEnabled(adAttribute == 0)
		NewPlayerPanelHelper.mReceiveBtnTex:setString(adAttribute == 0 and "领取" or "已领取")
	end
end

return NewPlayerPanelHelper