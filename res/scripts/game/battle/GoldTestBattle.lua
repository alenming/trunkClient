--[[
金币试炼相关回调
]]

local GoldTestBattle = {}
GoldTestBattle.summonerId = 0
GoldTestBattle.heroIds = {}
GoldTestBattle.mercenaryId = 0

--请求进入战斗网络回调
function GoldTestBattle:onGoldTestBattle(mainCmd, subCmd, bufferData)
    print("GoldTestBattle:onGoldTestBattle Start ......")
    -- 初始化房间
    openAndinitRoom(bufferData)
    -- 保存界面栈(返回到金币试炼界面)
    UIManager.saveToLastUI(UIManager.UI.UIGoldTest)
    -- 跳转战斗界面
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
    -- 设置结束回调
    if BattleHelper.finishCallback then
        print("GoldTestBattle:onGoldTestBattle set finish callback, but finishCallback NOT nil!")
    end
    BattleHelper.finishCallback = handler(self, self.onGoldTestOver)	

    if GoldTestBattle.mercenaryId ~= 0 then
        EventManager:raiseEvent(GameEvents.EventUseMercenary, {})
    end	
end

--战斗结束本地回调
function GoldTestBattle:onGoldTestOver()
    local settleModel = getGameModel():getRoom():getSettleAccount()
    local damage = -1
    if settleModel:getChallengeResult() ~= -1 then
        damage = settleModel:getHitBossHP()
    end

    local bufferData = NetHelper.createBufferData(MainProtocol.GoldTest, GoldTestProtocol.BattleOverCS)
    bufferData:writeInt(damage)
    bufferData:writeInt(self.summonerId)
    for i = 1, 7 do
        bufferData:writeInt(self.heroIds[i] or 0)
    end
    bufferData:writeInt(self.mercenaryId)

    print("onGoldTestOver Over Send : ", damage)
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.GoldTest, GoldTestProtocol.BattleOverSC), 
        handler(self, self.onGoldTestResultShow)) 
    BattleHelper.finishCallback = nil
end

--战斗结果网络回调
function GoldTestBattle:onGoldTestResultShow(mainCmd, subCmd, bufferData)
    local damage = bufferData:readInt()
    local damageReward = bufferData:readInt()
    local levelReward = bufferData:readInt()

    -- 移除使用过的佣兵
    getGameModel():getUnionMercenaryModel():deleteHeroToMercenaryBag(self.mercenaryId)

    UIManager.open(UIManager.UI.UIGoldTestWin, damage, damageReward, levelReward)

    -- 金币试炼结束事件
    EventManager:raiseEvent(GameEvents.EventGoldTestStageOver, {stageId = stageId, battleResult = 1})
    EventManager:raiseEvent(GameEvents.EventBattleOver, 1)
end

return GoldTestBattle
