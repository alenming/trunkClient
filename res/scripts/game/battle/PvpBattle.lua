
local PvpBattle = {}

function PvpBattle:onPvpBattleEnd(mainCmd, subCmd, bufferData)
    print("Pvp End! Waiting to receive result......")
end

-- PVP结果回调
function PvpBattle:onPvpBattleResult(mainCmd, subCmd, bufferData)
    print("Pvp Result! result......", mainCmd, subCmd)

    local endCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.EndSC)
	NetHelper.removeResponeHandler(endCmd, self.onBattleEndCallBack)

    -- 结算数值
    local resultData = {}
    resultData.pvpType = -1
    resultData.roomType = bufferData:readInt()
    resultData.battleResult = bufferData:readInt()
    resultData.integral = bufferData:readInt()
    resultData.rankNow = bufferData:readInt()
    
    local count = bufferData:readInt()
    resultData.dropInfo = {}
	for i = 1, count do
        local dropInfo = {}
		dropInfo.id = bufferData:readInt()
		dropInfo.num = bufferData:readInt()
		
        table.insert(resultData.dropInfo, dropInfo)
	end

    self:openUI(resultData)
end

function PvpBattle:openUI(resultData)
    -- pvp模型数据
    local pvpModel = getGameModel():getPvpModel()
    local pvpInfo = pvpModel:getPvpInfo()
    local historyRank = 0
    local historyScore = 0
    -- 1为公平竞技房间,2为锦标赛房间
    if 1 == resultData.roomType or resultData.roomType == 3 then
        resultData.rankDV = resultData.rankNow - pvpInfo.Rank
        resultData.integralDV = resultData.integral - pvpInfo.Score
        historyScore = pvpInfo.HistoryScore
        historyRank = pvpInfo.HistoryRank
        resultData.pvpType = 0
        getGameModel():getUnionModel():addPVPLiveness(10)

    elseif 2 == resultData.roomType then
        resultData.rankDV = resultData.rankNow - pvpInfo.CpnRank
        resultData.integralDV = resultData.integral - pvpInfo.CpnIntegral
        historyScore = pvpInfo.CpnHistoryHigestIntegral
        historyRank = pvpInfo.CpnHistoryHigestRank
        resultData.pvpType = 1
        -- 添加定级赛
        pvpInfo.CpnGradingNum = pvpInfo.CpnGradingNum + 1
        resultData.extend = getArenaSetting().GradingNum - pvpInfo.CpnGradingNum
        if resultData.extend >= 0 then
            pvpModel:addGradingNum()
        else
            resultData.isShow = true
        end

        getGameModel():getUnionModel():addPVPLiveness(10)
    end
    -- 设置日任务
    pvpModel:setDayTask(resultData.battleResult)
    -- 设置连胜
    pvpModel:setContinueWinTimes(resultData.battleResult)
    -- 设置宝箱是否可领取(胜利并且有宝箱)
    if 1 == resultData.battleResult and getGameModel():getPvpChestModel():hasChest() then
        pvpModel:setChestStatus(1)
    end

    -- 更新本地模型
    -- 排名
    resultData.historyRank = historyRank
    resultData.newHistoryRank = historyRank
    if resultData.rankNow > 0 
      and (historyRank <= 0 or resultData.rankNow < historyRank) then
        pvpModel:setHistoryRank(resultData.pvpType, resultData.rankNow)
        resultData.newHistoryRank = resultData.rankNow
    end

    if resultData.integral > historyScore then
        pvpModel:setHistoryScore(resultData.pvpType, resultData.integral)
        historyScore = resultData.integral
    end

    -- 当前排名
    pvpModel:setRank(resultData.pvpType, resultData.rankNow)

    local lastTLevel = getArenaTLevel(pvpModel:getScore(resultData.pvpType))
    local curTLevel = getArenaTLevel(resultData.integral)
    -- 竞技场是否段位升级
    local isUpTLevel = curTLevel > lastTLevel
    -- 竞技场是否段位降级
    local isDownTLevel = curTLevel < lastTLevel
    -- 如果胜利，判断T级是否上升来决定解锁主线的未解锁章节
    if resultData.pvpType == 0 and resultData.battleResult == 1 then
        if isUpTLevel then
            local stageModel = getGameModel():getStageModel()
            local chapterState = stageModel:getChapterState(curTLevel)
            if chapterState == EChapterState.ECS_LOCK then
                stageModel:setChapterState(curTLevel, EChapterState.ECS_UNLOCK)
            end 
        end
    end

    -- 当前积分
    pvpModel:setScore(resultData.pvpType, resultData.integral)

    UIManager.open(UIManager.UI.UIArenaAccount, resultData)

    display:getRunningScene():runAction(cc.Sequence:create(
        cc.DelayTime:create(1.5),
        cc.CallFunc:create(function () 
            if resultData.pvpType == 0 then
                if isUpTLevel then
                    UIManager.open(UIManager.UI.UIArenaLevel, true, curTLevel)
                elseif isDownTLevel then
                    UIManager.open(UIManager.UI.UIArenaLevel, false, curTLevel)
                end
            end
        end)
    ))

    local resultCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ResultSC)
	NetHelper.removeResponeHandler(resultCmd, self.onBattleResultCallBack)
    -- PVP结束事件
    print("pvp over lalala")
    EventManager:raiseEvent(GameEvents.EventPVPOver
        , {battleResult = resultData.battleResult, pvpType = resultData.pvpType})
    print("pvp over lelele")
    EventManager:raiseEvent(GameEvents.EventBattleOver, resultData.battleResult)
end

-------------------------------pvp机器人相关------------------------------------------
function PvpBattle:onPvpBattleOver()
	print("PvpBattle:onPvpBattleOver!!")
	local roomModel = getGameModel():getRoom()
	local settleModel = roomModel:getSettleAccount()
    -- PVP不能取消
	local winOrFail = settleModel:getChallengeResult()
	
	--发送结束请求
	local bufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.FinishRobotRoomCS)
	bufferData:writeInt(winOrFail)
    NetHelper.request(bufferData)

	--回调之后, 将回调函数移除
	BattleHelper.finishCallback = nil
end

-------------------------------pvp纯人机相关------------------------------------------
function PvpBattle:onPvpComputerBattleOver()
	print("PvpBattle:onPvpComputerBattleOver!!")
	local roomModel = getGameModel():getRoom()
	local settleModel = roomModel:getSettleAccount()
	local result = settleModel:getChallengeResult()

    -- 不是取消退出
    if -1 ~= result then
        local resultData = {}
	    resultData.battleResult = result
        resultData.pvpType = -1

	    UIManager.open(UIManager.UI.UIArenaAccount, resultData)
    end

	BattleHelper.finishCallback = nil
    -- pvp人机结束
    EventManager:raiseEvent(GameEvents.EventPVPOver, {battleResult = result, pvpType = -1})
    EventManager:raiseEvent(GameEvents.EventBattleOver, result)
end

return PvpBattle
