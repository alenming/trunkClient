--[[
    爬塔试炼
]]

local TowerTestBattle = {}
TowerTestBattle.diff = 0
TowerTestBattle.summonerId = 0
TowerTestBattle.heroIds = {}
TowerTestBattle.mercenaryId = 0

local BattleAccountHelper = require("game.comm.BattleAccountHelper")

--请求进入战斗网络回调
function TowerTestBattle:onTowerTestBattle(mainCmd, subCmd, bufferData)
    print("TowerTestBattle:onTowerTestBattle Start ......")
    --楼层、难度
    local floor = bufferData:readInt()     
    --local diff = bufferData:readInt()

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
    BattleHelper.finishCallback = handler(self, self.onTowerTestOver)

    if TowerTestBattle.mercenaryId ~= 0 then
        EventManager:raiseEvent(GameEvents.EventUseMercenary, {})
    end
end

--战斗结束本地回调
function TowerTestBattle:onTowerTestOver()
    local settleModel = getGameModel():getRoom():getSettleAccount()
    local cost = settleModel:getCostCrystal()
    local useCrystal = settleModel:getCrystal()
    local result = settleModel:getChallengeResult()
	local tick = settleModel:getTick()
	local hpPercent = settleModel:getHPPercent()

    local bufferData = NetHelper.createBufferData(MainProtocol.TowerTest, TowerTestProtocol.TowerFinishCS)
    --bufferData:writeInt(self.diff) --挑战的难度
    --bufferData:writeInt(cost)  --使用的水晶数
    --bufferData:writeInt(useCrystal)  --回收的水晶数
	bufferData:writeInt(result)
    bufferData:writeInt(self.summonerId)
    for i = 1, 7 do
        bufferData:writeInt(self.heroIds[i] or 0)
    end
    bufferData:writeInt(self.mercenaryId)
    
	bufferData:writeInt(tick)
    bufferData:writeInt(cost)
	bufferData:writeInt(hpPercent)
    bufferData:writeInt(0) --水晶等级,没用这个参数了
	NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.TowerTest, TowerTestProtocol.TowerFinishSC), 
        handler(self, self.onTowerTestResultShow)) 

	BattleHelper.finishCallback = nil
end

--战斗结果网络回调
function TowerTestBattle:onTowerTestResultShow(mainCmd, subCmd, bufferData)
    --显示的数据
    local resultData = {}
    resultData.floor = bufferData:readInt()
    local wonOrFailed = bufferData:readInt()
    
    if wonOrFailed == 1 then
        -- 移除使用过的佣兵
        getGameModel():getUnionMercenaryModel():deleteHeroToMercenaryBag(self.mercenaryId)
     
        --物品结构体
        local propCount = bufferData:readInt()
        resultData.Prop = {}
        for i = 1, propCount do
            local newPropInfo = {}
            newPropInfo.id = bufferData:readInt()
            newPropInfo.num = bufferData:readInt()
            if newPropInfo.id == UIAwardHelper.ResourceID.Gold then
                resultData.Gold = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.Energy then
                resultData.Energy = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.Exp then
                resultData.Exp = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.Diamond then
                resultData.Diamond = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.TowerCoin then
                resultData.TowerCoin = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.UnionContrib then
                resultData.UnionContrib = newPropInfo.num
            elseif newPropInfo.id == UIAwardHelper.ResourceID.PvpCoin then
                resultData.PvpCoin = newPropInfo.num
            else
                table.insert(resultData.Prop, newPropInfo)
            end
        end

        UIManager.open(UIManager.UI.UITowerTestWin, resultData)
    else
        resultData.showLayer = "LoseLayer"
        UIManager.open(UIManager.UI.UISettleAccountNormal, resultData)
    end

    -- 爬塔试炼结束事件
    EventManager:raiseEvent(GameEvents.EventTowerTestStageOver
        , {stageId = stageId, stageDifficulty = resultData.lv, battleResult = wonOrFailed})
    EventManager:raiseEvent(GameEvents.EventBattleOver, wonOrFailed)
end 

return TowerTestBattle
