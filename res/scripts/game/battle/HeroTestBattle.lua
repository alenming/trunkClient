--[[
英雄试炼相关回调
]]

local HeroTestBattle = {}
HeroTestBattle.challengeId = 0
HeroTestBattle.diff = 0
HeroTestBattle.summonerId = 0
HeroTestBattle.heroIds = {}
HeroTestBattle.mercenaryId = 0

local BattleAccountHelper = require("game.comm.BattleAccountHelper")

--请求进入战斗网络回调
function HeroTestBattle:onHeroTestBattle(mainCmd, subCmd, bufferData)
    print("HeroTestBattle:onHeroTestBattle Start ......")
    -- 初始化房间
    openAndinitRoom(bufferData)
    --恢复到指定界面(返回到英雄试练种类选择界面)
    UIManager.saveToLastUI(UIManager.UI.UIHeroTestChoose)
    -- 跳转战斗界面
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
    -- 设置结束回调
    if BattleHelper.finishCallback then
        print("HeroTestBattle:onHeroTestBattle set finish callback, but finishCallback NOT nil!")
    end
    BattleHelper.finishCallback = handler(self, self.onHeroTestOver)

    if HeroTestBattle.mercenaryId ~= 0 then
        EventManager:raiseEvent(GameEvents.EventUseMercenary, {})
    end 
end

--战斗结束本地回调
function HeroTestBattle:onHeroTestOver()
    local settleModel = getGameModel():getRoom():getSettleAccount()

    local bufferData = NetHelper.createBufferData(MainProtocol.HeroTest, HeroTestProtocol.BattleOverCS)
    bufferData:writeInt(self.challengeId)
    bufferData:writeInt(self.diff)
    bufferData:writeInt(settleModel:getChallengeResult())
    bufferData:writeInt(self.summonerId)
    for i = 1, 7 do
        bufferData:writeInt(self.heroIds[i] or 0)
    end
    bufferData:writeInt(self.mercenaryId)

    bufferData:writeInt(settleModel:getTick())
    bufferData:writeInt(settleModel:getCostCrystal())
    bufferData:writeInt(settleModel:getHPPercent())
    
    print("onHeroTestOver Over Send : ", settleModel:getChallengeResult(), settleModel:getTick(), settleModel:getHPPercent(), settleModel:getCostCrystal())
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.HeroTest, HeroTestProtocol.BattleOverSC), 
        handler(self, self.onHeroTestResultShow)) 
    BattleHelper.finishCallback = nil
end

--战斗结果网络回调
function HeroTestBattle:onHeroTestResultShow(mainCmd, subCmd, bufferData)
    --显示的数据
    local resultData = {}
    --StageFinishSC
    local id = bufferData:readInt()
    local lv = bufferData:readInt()
    local result = bufferData:readInt()

    local heroTestConf = getHeroTestConfItem(id)
    local stageId = heroTestConf.Diff[lv].DiffID

    print("stageId", stageId)
    if result == 1 then
        -- 设置挑战次数
        getGameModel():getHeroTestModel():addHeroTestCount(id, 1)
        -- 移除使用过的佣兵
        getGameModel():getUnionMercenaryModel():deleteHeroToMercenaryBag(self.mercenaryId)
        --成功信息
        resultData = BattleAccountHelper.toWinnerNormalSettle(stageId, bufferData)
        UIManager.open(UIManager.UI.UIHeroTestWin, resultData)
    else
        --失败信息
        UIManager.open(UIManager.UI.UISettleAccountLose)
    end

    -- 英雄试炼结束事件
    EventManager:raiseEvent(GameEvents.EventHeroTestStageOver, 
        {stageId = stageId, stageDifficulty = lv, battleResult = result})
    EventManager:raiseEvent(GameEvents.EventBattleOver, result)
end 

return HeroTestBattle

