

local InstanceBattle = {}

local UISettleAccountNormal = require("game.battle.UISettleAccountNormal")

--请求进入战斗网络回调
function InstanceBattle:onInstanceBattle(mainCmd, subCmd, bufferData)
	self.id = bufferData:readInt()
    self.lv = bufferData:readInt()
    print("onInstanceBattle Start : ", mainCmd, subCmd, self.id, self.lv)

    local count = getGameModel():getActivityInstanceModel():getActivityInstance()[self.id].useTimes
    getGameModel():getActivityInstanceModel():setInstanceCount(self, count - 1)

    openAndinitRoom(bufferData)
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)

	if BattleHelper.finishCallback then
		print("StageBattle:InstanceBattle set finish callback, but finishCallback NOT nil!")
	end
	BattleHelper.finishCallback = handler(self, self.onInstanceBattleOver)
end

--战斗结束本地回调
function InstanceBattle:onInstanceBattleOver()
	local settleModel = getGameModel():getRoom():getSettleAccount()
	local result = settleModel:getChallengeResult()
	local tick = settleModel:getTick()
	local hpPercent = settleModel:getHPPercent()
	local crystal = settleModel:getCostCrystal()

	local bufferData = NetHelper.createBufferData(MainProtocol.Instance, InstanceProtocol.FinishCS)
	bufferData:writeInt(result)
    bufferData:writeInt(tick)
    bufferData:writeInt(hpPercent)
    bufferData:writeInt(crystal)

    print("onInstanceBattle Over Send : ", winOrFail, tick, hpPercent, crystal)
	NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Instance, InstanceProtocol.FinishSC), 
        handler(self, self.onInstanceResultShow))

	BattleHelper.finishCallback = nil
end

--战斗结果网络回调
function InstanceBattle:onInstanceResultShow(mainCmd, subCmd, bufferData)
    BattleAccountHelper.BattleAccount(UIManager.UI.UISettleAccountNormal,nil,bufferData)

    -- 副本结束事件
    EventManager:raiseEvent(GameEvents.EventFBTestStageOver
        , {stageId = instanceId, stageDifficulty = difficulty, battleResult = wonOrFailed})
    EventManager:raiseEvent(GameEvents.EventBattleOver, wonOrFailed)
end

return InstanceBattle
