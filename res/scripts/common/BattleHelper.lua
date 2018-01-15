--[[
	BattleHelper主要用于处理进入战斗相关的逻辑，正常的进入战斗包含以下流程：
	1.准备数据：玩家选择要出的兵，战斗类型（PVP、PVE或公会团战之类）以及其他数据（爬塔）等等
	2.请求战斗：这一阶段需要将准备好的数据封装后发送到服务器
	3.Loading：在接收到服务器响应时，应该跳转到对应的Loading界面
	4.进入战斗：在加载完成后，切换战斗场景

	BattleHelper主要负责2和3阶段的实现，提供请求战斗的函数，以及处理服务器的返回结果
	包含：单机关卡、PVP的进入

	2015-9-28 by 宝爷
]]

BattleHelper = {}

require "common.NetHelper"

local PvpBattle = require("game.battle.PvpBattle")
local StageBattle = require("game.battle.StageBattle")
local InstanceBattle = require("game.battle.InstanceBattle")
local GoldTestBattle = require("game.battle.GoldTestBattle")
local HeroTestBattle = require("game.battle.HeroTestBattle")
local TowerTestBattle = require("game.battle.TowerTestBattle")
local ExpeditionBattle = require("game.battle.ExpeditionBattle")

function BattleHelper.quitBattle()
    -- 策划说要强制退出战斗
	print("lua quitBattle")
    -- 执行结束回调，可能会请求服务器，C++层需要设置战斗失败
	if BattleHelper.finishCallback then
		BattleHelper.finishCallback = nil
	end

    -- 移除结算回调，每新增一种战斗类型，如果需要强制退出，必须在此移除其结算回调，实在是没办法了......
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.FinishSC))
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.TowerTest, TowerTestProtocol.TowerFinishSC))
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.Instance, InstanceProtocol.FinishSC))
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.HeroTest, HeroTestProtocol.BattleOverSC))
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.GoldTest, GoldTestProtocol.BattleOverSC))
--	NetHelper.removeResponeHandler(NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StageFinishSC))
    
    -- 释放房间资源
    finishBattle()
	
    -- 退出战斗场景
	if SceneManager.PrevScene then
		SceneManager.loadScene(SceneManager.PrevScene)
	else
		SceneManager.loadScene(SceneManager.Scene.SceneHall)
	end
end

function BattleHelper.onBattleStart(stageId)
    -- 战斗开始时回调
    print(stageId .. " onBattleStart")
    EventManager:raiseEvent(GameEvents.EventBattleStart, {stageId = stageId})
end

function BattleHelper.onBattleOver()
	print("lua onBattleOver")
	if BattleHelper.finishCallback then
		print("BattleHelper call finishCallback")
		BattleHelper.finishCallback()
	end
end

function BattleHelper.sendTeamSet(teamType, summonerId, heroIds)
    -- 更新本地队伍信息
	getGameModel():getTeamModel():setTeamInfo(teamType, summonerId, heroIds)
    --[[
    local bufferData = NetHelper.createBufferData(MainProtocol.Team, TeamProtocol.SetTeamCS)
    bufferData:writeInt(teamType)
    bufferData:writeInt(summonerId)
    for i = 1, 7 do
        local heroId = heroIds[i] or 0
        bufferData:writeInt(heroId)
    end
    -- 发送队伍设置
    NetHelper.request(bufferData)]]
end

-- 请求挑战关卡，传入关卡Id、召唤师Id、出征的英雄Id列表
function BattleHelper.requestStage(summonerId, heroIds, chapterId, stageId, mercenaryId)
    BattleHelper.sendTeamSet(0, summonerId, heroIds)

    -- 先初始化测试用的StageProxy
    -- 更新本地队伍信息
    StageBattle.chapterId = chapterId
    StageBattle.stageId = stageId
    StageBattle.summonerId = summonerId
    StageBattle.heroIds = heroIds
    StageBattle.mercenaryId = mercenaryId or 0
    print("\n")
    print("------------------------------------------------------")
    print("BattleHelper.requestStage summonerId", summonerId)
    dump(heroIds, "BattleHelper.requestStage heroIds")
    print("BattleHelper.requestStage chapterId", chapterId)
    print("BattleHelper.requestStage stageId", stageId)
    print("BattleHelper.requestStage mercenaryId", mercenaryId)
    print("------------------------------------------------------")
    print("\n")
    -- 封包
    local bufferData = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.ChangeCS)
    bufferData:writeInt(chapterId)-- 章节ID
    bufferData:writeInt(stageId) -- 关卡ID
    bufferData:writeInt(summonerId) -- 召唤师ID
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送关卡挑战
    print("Stage Challenge .....")
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.ChangeSC), 
        handler(StageBattle, StageBattle.onStageBattle)) 
end

-- PVP战斗相关回调
function BattleHelper.overPVP(isRobotPvp)
	-- 注册回调
    local endCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.EndSC)
    PvpBattle.onBattleEndCallBack = handler(PvpBattle, PvpBattle.onPvpBattleEnd)
	NetHelper.setResponeHandler(endCmd, PvpBattle.onBattleEndCallBack)

	local resultCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ResultSC)
    PvpBattle.onBattleResultCallBack = handler(PvpBattle, PvpBattle.onPvpBattleResult)
	NetHelper.setResponeHandler(resultCmd, PvpBattle.onBattleResultCallBack)

    if isRobotPvp then
        BattleHelper.finishCallback = handler(PvpBattle, PvpBattle.onPvpBattleOver)	
    end

    print("register pvp over cmd!!!")
end

-- 请求挑战金币试炼,出征的英雄Id列表
function BattleHelper.requestGoldTest(summonerId, heroIds, mercenaryId)
    -- 更新本地队伍信息
    BattleHelper.sendTeamSet(0, summonerId, heroIds)

    GoldTestBattle.summonerId = summonerId
    GoldTestBattle.heroIds = heroIds
    GoldTestBattle.mercenaryId = mercenaryId or 0
    print("\n")
    print("------------------------------------------------------")
    print("BattleHelper.requestGoldTest summonerId", summonerId)
    dump(heroIds, "BattleHelper.requestGoldTest heroIds")
    print("BattleHelper.requestGoldTest mercenaryId", mercenaryId)
    print("------------------------------------------------------")
    print("\n")

    local bufferData = NetHelper.createBufferData(MainProtocol.GoldTest, GoldTestProtocol.BattleCS)
    bufferData:writeInt(summonerId)
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送挑战金币试炼
    print("GoldTest Challenge .....")
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.GoldTest, GoldTestProtocol.BattleSC), 
        handler(GoldTestBattle, GoldTestBattle.onGoldTestBattle)) 
end

-- 请求挑战英雄试炼,出征的英雄Id列表
function BattleHelper.requestHeroTest(summonerId, heroIds, id, lv, mercenaryId)
    -- 更新本地队伍信息
    BattleHelper.sendTeamSet(0, summonerId, heroIds)

    HeroTestBattle.challengeId = id
    HeroTestBattle.diff = lv
    HeroTestBattle.summonerId = summonerId
    HeroTestBattle.heroIds = heroIds
    HeroTestBattle.mercenaryId = mercenaryId or 0
    print("\n")
    print("------------------------------------------------------")
    print("BattleHelper.requestHeroTest summonerId", summonerId)
    dump(heroIds, "BattleHelper.requestHeroTest heroIds")
    print("BattleHelper.requestHeroTest id", id)
    print("BattleHelper.requestHeroTest lv", lv)
    print("BattleHelper.requestHeroTest mercenaryId", mercenaryId)
    print("------------------------------------------------------")
    print("\n")

    -- 封包
    local bufferData = NetHelper.createBufferData(MainProtocol.HeroTest, HeroTestProtocol.BattleCS)
    bufferData:writeInt(id)
    bufferData:writeInt(lv)
    bufferData:writeInt(summonerId) -- 召唤师ID
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送挑战英雄试炼
    print("HeroTest Challenge .....", id, lv)
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.HeroTest, HeroTestProtocol.BattleSC), 
        handler(HeroTestBattle, HeroTestBattle.onHeroTestBattle)) 
end

-- 请求挑战爬塔试炼,出征的英雄Id列表
function BattleHelper.requestTowerTest(summonerId, heroIds, lv, mercenaryId)
    -- 更新本地队伍信息
    BattleHelper.sendTeamSet(0, summonerId, heroIds)

    TowerTestBattle.diff = lv
    TowerTestBattle.summonerId = summonerId
    TowerTestBattle.heroIds = heroIds
    TowerTestBattle.mercenaryId = mercenaryId or 0
    print("\n")
    print("------------------------------------------------------")
    print("BattleHelper.requestTowerTest summonerId", summonerId)
    dump(heroIds, "BattleHelper.requestTowerTest heroIds")
    print("BattleHelper.requestTowerTest lv", lv)
    print("BattleHelper.requestTowerTest mercenaryId", mercenaryId)
    print("------------------------------------------------------")
    print("\n")

    -- 封包
    local bufferData = NetHelper.createBufferData(MainProtocol.TowerTest, TowerTestProtocol.TowerFightingCS)
    --bufferData:writeInt(lv)
    bufferData:writeInt(summonerId) -- 召唤师ID
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送爬塔挑战
    print("TowerTest Challenge .....", lv)
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.TowerTest, TowerTestProtocol.TowerFightingSC), 
        handler(TowerTestBattle, TowerTestBattle.onTowerTestBattle)) 
end

function BattleHelper.requestInstance(summonerId, heroIds, id, lv, mercenaryId)
    -- 更新本地队伍信息
    BattleHelper.sendTeamSet(0, summonerId, heroIds)
    local bufferData = NetHelper.createBufferData(MainProtocol.Instance, InstanceProtocol.ChallengeCS)
    bufferData:writeInt(id)
    bufferData:writeInt(lv)
    bufferData:writeInt(summonerId)
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送活动副本挑战
    print("ActivityInstance Challenge : ", id, lv)
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Instance, InstanceProtocol.ChallengeSC), 
        handler(InstanceBattle, InstanceBattle.onInstanceBattle)) 
end

--1召唤师血量;2时间;3消耗水晶
local StarReason = {win = 219, time = 224, hp = 221, crystal = 232}
function BattleHelper.getStarReason(reason, val)
    local starReason = ""
    if reason == 1 then
        starReason = string.format(CommonHelper.getUIString(StarReason.hp), val)
    elseif reason == 2 then
        starReason = string.format(CommonHelper.getUIString(StarReason.time), val)
    elseif reason == 3 then
        starReason = string.format(CommonHelper.getUIString(StarReason.crystal), val)
    else
        starReason = CommonHelper.getUIString(StarReason.win)
    end

    return starReason
end

-- 单机挑战
-- stageInfo包含关卡信息,如关卡id、等级、类型
function BattleHelper.challengeComputer(summonerID, herosID, stageInfo, finishCallback)
    local stageConf = getStageConfItem(stageInfo.stageId)
    if not stageConf then
        print("challenge computer is error, stageid", stageInfo.stageId)
        return
    end

    local userModel = getGameModel():getUserModel()
    local heroBagModel = getGameModel():getHeroCardBagModel()
    local equipModel = getGameModel():getEquipModel()
    local userId = userModel:getUserID()
    local userLv = userModel:getUserLevel()
    local userName = userModel:getUserName()

    local bufferData = newBufferData()
    bufferData:writeInt(stageInfo.stageId)    -- 关卡ID
    bufferData:writeInt(stageInfo.stageLv)    -- 关卡等级
    bufferData:writeInt(stageInfo.battleType) -- 房间对战类型
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 战斗内buff字段
    bufferData:writeInt(1) -- 房间内的玩家数量

    -- 玩家属性
    bufferData:writeInt(userId) -- 玩家id
    bufferData:writeInt(userLv) -- 玩家等级
    bufferData:writeInt(1) -- 玩家阵营
    bufferData:writeInt(0) -- BUFF数量
    bufferData:writeInt(#herosID) -- 玩家士兵个数
    bufferData:writeInt(0) -- 佣兵数量
    bufferData:writeInt(userModel:getBDLv() * 10 + userModel:getBDType()) -- 玩家身份
    bufferData:writeString(userName) -- 玩家名字 32字节
    -- 写入后面额外的字节
    for i = string.len(userName) + 2, 32 do
        bufferData:writeChar(0)
    end

    -- 召唤师
    bufferData:writeInt(summonerID)

    -- 士兵列表
    for _, heroId in ipairs(herosID) do
        local heroModel = heroBagModel:getHeroCard(heroId)
        local lv = heroModel:getLevel()
        local star = heroModel:getStar()
        local exp = heroModel:getExp()
        local talent = heroModel:getTalent()
        local equips = heroModel:getEquips()

        -- 装备件数
        local equipCount = 0
        for part, equipDynId in pairs(equips) do
            if equipDynId > 0 then
                equipCount = equipCount + 1
            else
                equips[part] = nil
            end
        end
        
        bufferData:writeInt(heroId)     -- 士兵id
        bufferData:writeInt(lv)         -- 士兵等级
        bufferData:writeInt(star)       -- 士兵星级
        bufferData:writeInt(exp)        -- 士兵经验
        for j = 1, 8 do
            bufferData:writeChar(0)     -- 天赋
        end
        bufferData:writeInt(equipCount) -- 装备个数

        -- 装备信息
        for _, equipDynId in pairs(equips) do
            local equipInfo = equipModel:getEquipInfo(equipDynId)

            bufferData:writeInt(equipInfo.confId)             -- 装备配置ID
            --bufferData:writeInt(equipInfo.equipId)            -- 装备动态ID
            --bufferData:writeChar(equipInfo.nMainPropNum)       -- 装备主属性数
            -- 装备属性ID
            for i = 1, 8 do
                local effectID = equipInfo.eqEffectIDs[i] or 0
                bufferData:writeChar(effectID)
            end
            
            -- 装备属性值
            for j = 1, 8 do
                local effectVal = equipInfo.eqEffectValues[j] or 0
                bufferData:writeShort(effectVal)
            end
        end
    end

    bufferData:resetOffset()
    -- 打开房间
    openAndinitRoom(bufferData)
    deleteBufferData(bufferData)

    -- 注册结束回调
    BattleHelper.finishCallback = finishCallback

    -- 切换战斗场景
    local SceneManager = require("common.SceneManager")
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
end

-- 请求挑战公会远征(召唤师id, 英雄列表, 关卡序列索引, 佣兵id)
function BattleHelper.requestExpedition(summonerId, heroIds, index, mercenaryId)
    -- 更新本地队伍信息
    BattleHelper.sendTeamSet(0, summonerId, heroIds)

    ExpeditionBattle.summonerId = summonerId
    ExpeditionBattle.heroIds = heroIds
    ExpeditionBattle.index = index
    ExpeditionBattle.mercenaryId = mercenaryId or 0
    print("\n")
    print("------------------------------------------------------")
    print("BattleHelper.requestExpedition summonerId", summonerId)
    dump(heroIds, "BattleHelper.requestExpedition heroIds")
    print("BattleHelper.requestExpedition index", index)
    print("BattleHelper.requestExpedition mercenaryId", mercenaryId)
    print("------------------------------------------------------")
    print("\n")

    -- 封包
    local bufferData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.StageStartCS)
    bufferData:writeInt(index)  -- 关卡序列索引
    bufferData:writeInt(summonerId) -- 召唤师ID
    for i = 1, 7 do
        bufferData:writeInt(heroIds[i] or 0)
    end
    bufferData:writeInt(mercenaryId or 0)

    -- 发送远征挑战
    NetHelper.requestWithTimeOut(bufferData, 
        NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StageStartSC), 
        handler(ExpeditionBattle, ExpeditionBattle.onExpeditionBattle)) 
end

return BattleHelper