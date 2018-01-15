--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征战斗回调(请求战斗, 战斗结束)
** 应  用:
********************************************************************/
--]]

local ExpeditionBattle = class("ExpeditionBattle")

--[[
/*******************************************************************
**    属性: summonerId, heroIds, stageId, mercenaryId
********************************************************************/
--]]
ExpeditionBattle.summonerId = 0
ExpeditionBattle.heroIds = {}
ExpeditionBattle.stageId = 0
ExpeditionBattle.damage = 0
ExpeditionBattle.mercenaryId = 0

--[[
/*******************************************************************
** 方法
********************************************************************/
--]]
-- 请求进入战斗回调
function ExpeditionBattle:onExpeditionBattle(mainCmd, subCmd, bufferData)
    print("ExpeditionBattle:onExpeditionBattle Start ......")
    -- 初始化房间
    openAndinitRoom(bufferData)
    -- 保存界面栈
    UIManager.saveUI(2)
    -- 跳转战斗界面
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
    -- 设置结束回调
    if BattleHelper.finishCallback then
        print("ExpeditionBattle:onExpeditionBattle: set finish callback, but finishCallback NOT nil!")
    end
    BattleHelper.finishCallback = handler(self, self.onExpeditionOver)

    if ExpeditionBattle.mercenaryId ~= 0 then
        EventManager:raiseEvent(GameEvents.EventUseMercenary, {})
    end
end

-- 战斗结束的本地回调
function ExpeditionBattle:onExpeditionOver()
    local settleModel = getGameModel():getRoom():getSettleAccount()
    local damage = 0
    if settleModel:getChallengeResult() ~= -1 then
        damage = settleModel:getHitBossHP()
    end
    self.damage = damage
    print("ExpeditionBattle:onExpeditionOver Over Send damage", damage)

    -- 发送请求
    local bufferData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.StageFinishCS)
    bufferData:writeInt(damage)
    bufferData:writeInt(self.summonerId)
    for i = 1, 7 do
        bufferData:writeInt(self.heroIds[i] or 0)
    end
    local heroBagModel = getGameModel():getHeroCardBagModel()
    for i = 1, 7 do
        local heroId = self.heroIds[i] or 0
        local heroModel = heroBagModel:getHeroCard(heroId)
        local star = heroModel and heroModel:getStar() or 0
        bufferData:writeInt(star)
    end
    bufferData:writeInt(self.mercenaryId)
    
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StageFinishSC), 
        handler(self, self.onExpeditionResultShow)) 

	BattleHelper.finishCallback = nil
end

-- 战斗结果网络回调
function ExpeditionBattle:onExpeditionResultShow(mainCmd, subCmd, bufferData)
    -- 移除使用过的佣兵
    getGameModel():getUnionMercenaryModel():deleteHeroToMercenaryBag(self.mercenaryId)
    -- 打开结算界面
    UIManager.open(UIManager.UI.UIExpeditionWin, self.damage)
end

return ExpeditionBattle