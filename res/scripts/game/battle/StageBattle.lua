
local UISettleAccountNormal = require("game.battle.UISettleAccountNormal")
local BattleAccountHelper = require("game.comm.BattleAccountHelper")

local StageBattle = {}
StageBattle.chapterId = 0
StageBattle.stageId = 0
StageBattle.summonerId = 0
StageBattle.heroIds = {}
StageBattle.mercenaryId = 0

--请求进入战斗网络回调
function StageBattle:onStageBattle(mainCmd, subCmd, bufferData)
    print("StageBattle:onStageBattle Start ......")
    -- 切换到Loading界面
    local result = bufferData:readInt()
    if result == 1 then
        -- 初始化房间
        openAndinitRoom(bufferData)
        -- 保存界面栈
        UIManager.saveUI(2)
        -- 跳转战斗界面
        SceneManager.loadScene(SceneManager.Scene.SceneBattle)
        -- 设置结束回调
        if BattleHelper.finishCallback then
            print("StageBattle:onStageBattle set finish callback, but finishCallback NOT nil!")
        end
        BattleHelper.finishCallback = handler(self, self.onStageBattleOver)

        if StageBattle.mercenaryId ~= 0 then
            EventManager:raiseEvent(GameEvents.EventUseMercenary, {})
        end
    end
end

--战斗结束本地回调
function StageBattle:onStageBattleOver()
    --获得基本战斗信息, 发送到后端验证
    local roomModel = getGameModel():getRoom()
    local settleModel = roomModel:getSettleAccount()

    local result = settleModel:getChallengeResult()
    local tick = settleModel:getTick()
    local hpPercent = settleModel:getHPPercent()
    local crystal = settleModel:getCostCrystal()
    local crystalLv = settleModel:getCrystalLv()

    --封包
    local bufferData = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.FinishCS)
    --结束命令加验证信息
    bufferData:writeInt(self.chapterId)
    bufferData:writeInt(self.stageId)
    bufferData:writeInt(result)

    --if result == 1 then
    bufferData:writeInt(self.summonerId)
    for i = 1, 7 do
        bufferData:writeInt(self.heroIds[i] or 0)
    end
    bufferData:writeInt(self.mercenaryId)
    bufferData:writeInt(tick)
    bufferData:writeInt(crystal)
    bufferData:writeInt(hpPercent)
    bufferData:writeInt(crystalLv)
   --end

    --发送关卡结束请求
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.FinishSC), 
        handler(self, self.onStageResultShow)) 

    --回调之后, 将回调函数移除
    BattleHelper.finishCallback = nil
end

--战斗结果网络回调
function StageBattle:onStageResultShow(mainCmd, subCmd, bufferData)
    --显示的数据
    local resultData = {}
    local chapterId = bufferData:readInt()
    local stageId = bufferData:readInt()
    local result = bufferData:readInt()
    --胜利	 
    if result == 1 then
        -- 移除使用过的佣兵
        getGameModel():getUnionMercenaryModel():deleteHeroToMercenaryBag(self.mercenaryId)

        --章节中关卡信息
        resultData = BattleAccountHelper.toWinnerNormalSettle(stageId, bufferData)
        local chapterConf = getChapterConfItem(chapterId)
        local chapterStageInfo = chapterConf.Stages[stageId]
        -- 如果需要显示单个及跑马灯
        if false then          
            --如果下面找不到指定关卡, 则借用101的物品显示  
            local dropId = 101 
            local stageConf = getStageConfItem(stageId)
            if stageConf then
                dropId = stageConf.ItemDrop[resultData.star]
            end
            resultData.rewardCountType = "Single"
            resultData.PNDropId = dropId
            resultData.autoItem = nil
        end

        --设置关卡状态
        StageHelper.finishStage(chapterId, stageId, resultData.star + 2)
    else
        --显示失败界面
        resultData.showLayer = "LoseLayer"
    end

    -- 关卡结束事件
    EventManager:raiseEvent(GameEvents.EventStageOver, {stageId = stageId, chapterId = chapterId, battleResult = result})
    --打开常规的显示界面
    UIManager.open(UIManager.UI.UISettleAccountNormal, resultData)
    EventManager:raiseEvent(GameEvents.EventBattleOver, result)
end

return StageBattle