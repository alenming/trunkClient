--读取来自服务器的网路数据并通用显示
local BattleAccountHelper = {}

function BattleAccountHelper.BattleAccount(UIWin,UIFail,bufferData)

end

function BattleAccountHelper.toWinnerNormalSettle(stageId, bufferData)
    --构造常规界面信息table
    local resultData = {}
    resultData.stageId = stageId
	resultData.showLayer = "WinLayer"	
    --StageReward 该种类关卡特定信息
	resultData.star = bufferData:readInt()
	--2个星星获得理由
	resultData.star2Reason = bufferData:readInt()
	resultData.star3Reason = bufferData:readInt()
    --道具个数
    resultData.realItems = {}
    local rewardCount = bufferData:readInt()
    resultData.Gold = 0
    resultData.Exp = 0
    resultData.Diamond = 0
    resultData.TowerCoin = 0
    for i = 1, rewardCount do
        --解析每个道具的数据
        local id = bufferData:readInt()
        local num = bufferData:readInt()
--        if id == UIAwardHelper.ResourceID.Gold then 
--            resultData.Gold = num
--        elseif id == UIAwardHelper.ResourceID.Energy then
--            resultData.Energy = num
--        elseif id == UIAwardHelper.ResourceID.Exp then
--            resultData.Exp = num
        if id == UIAwardHelper.ResourceID.Diamond then
            resultData.Diamond = num
        elseif id == UIAwardHelper.ResourceID.TowerCoin then
            resultData.TowerCoin = num
        elseif id == UIAwardHelper.ResourceID.UnionContrib then
            resultData.UnionContrib = num
        elseif id == UIAwardHelper.ResourceID.PvpCoin then
            resultData.PvpCoin = num
        else
            table.insert(resultData.realItems, {id = id, num = num})
        end
    end

    resultData.rewardCountType = "Multiple"
    return resultData
end

function BattleAccountHelper.toLoserNormalSettle()
    local resultData = {}
    resultData.showLayer = "LoseLayer"
    return resultData
end

return BattleAccountHelper



