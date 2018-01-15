-- 远征模型
local ExpeditionModel = class("ExpeditionModel")

function ExpeditionModel:ctor()
    self.fightCount = 0             -- 远征剩余次数
    self.warEndTime = 0             -- 远征交战结束时间
    self.restEndTime = 0            -- 远征休息结束时间
    self.areaId = 0                 -- 远征区域id
    self.mapId = 0                  -- 远征地图id
    self.awardSendTime = 0          -- 远征奖励发放时间
    self.awardFlag = 0              -- 远征奖励领取标识
    self.stages = {}                -- 远征可挑战关卡: self.stages[index] = bossHp
    self.rankTime = 0               -- 远征伤害排行榜请求时间
    self.rankMapId = 0              -- 远征伤害排行榜地图id
    self.myRank = 0                 -- 我的远征伤害排行名次
    self.rankList = {}              -- 远征伤害排行榜列表
    self.isWin = false
end

function ExpeditionModel:init(buffData)
    self.fightCount = buffData:readChar()
    self.warEndTime = buffData:readInt()
    self.restEndTime = buffData:readInt()
    self.awardSendTime = buffData:readInt()
    self.areaId = buffData:readInt()
    self.mapId = buffData:readInt()
    self.awardFlag  = buffData:readChar()      --奖励领取标识
    local stageNum = buffData:readChar()
    self.stages = {}
    for i = 1, stageNum or 0 do
		local index = buffData:readInt()        -- 关卡序列(1 ~ 15)
		local bossHp = buffData:readInt()       -- Boss血量
        self.stages[index] = bossHp
    end
end

-- 获取/重置 剩余次数
function ExpeditionModel:getFightCount()
    return self.fightCount
end
function ExpeditionModel:resetFightCount(_count)
    self.fightCount = _count or 0
end

-- 获取/设置 公会远征结束时间点
function ExpeditionModel:getWarEndTime()
    return self.warEndTime
end
function ExpeditionModel:setWarEndTime(_time)
    self.warEndTime = _time
end

-- 获取/设置 公会远征休息时间点
function ExpeditionModel:getRestEndTime()
    return self.restEndTime
end
function ExpeditionModel:setRestEndTime(_time)
    self.restEndTime = _time
end

-- 获取/设置 公会远征区域ID
function ExpeditionModel:getAreaId()
    return self.areaId
end
function ExpeditionModel:setAreaId(_areaId)
    self.areaId = _areaId
end

-- 获取/设置 公会远征地图ID
function ExpeditionModel:getMapId()
    return self.mapId
end
function ExpeditionModel:setMapId(_mapId)
    self.mapId = _mapId
end

-- 获取/设置 公会奖励领取标识
function ExpeditionModel:getAwardFlag()
    return self.awardFlag
end
function ExpeditionModel:setAwardFlag(_flag)
    self.awardFlag = _flag
end

-- 获取/设置 公会奖励发放时间
function ExpeditionModel:getAwardSendTime()
    return self.awardSendTime
end
function ExpeditionModel:setAwardSendTime(_time)
    self.awardSendTime = _time
end

-- 添加/移除/清空 公会远征关卡ID
function ExpeditionModel:addStage(_index, _bossHp)
    for id, _ in pairs(self.stages or {}) do
        if id == _index then 
            return false
        end
    end
    self.stages[_index] = _bossHp
end
function ExpeditionModel:removeStage(_index)
    for id, _ in pairs(self.stages or {}) do
        if id == _index then
            table.remove(self.stages, _index)
            break
        end
    end
end
function ExpeditionModel:clearStages()
    self.stages = {}
end

-- 获取/设置 关卡血量
function ExpeditionModel:getStageHp(_index)
    for i, v in pairs(self.stages or {}) do
        if i == _index then
            return v
        end
    end
    return nil
end
function ExpeditionModel:setStageHp(_index, _bossHp)
    for i, v in pairs(self.stages or {}) do
        if i == _index then
            self.stages[_index] = _bossHp
        end
    end
    return true
end

-- 获取/设置 排行榜获取时间
function ExpeditionModel:getRankTime()
    return self.rankTime or os.time()
end
function ExpeditionModel:setRankTime()
    self.rankTime = os.time()
end

-- 获取/设置 排行榜地图id
function ExpeditionModel:getRankMapId()
    return self.rankMapId
end
function ExpeditionModel:setRankMapId(_mapId)
    self.rankMapId = _mapId
end

-- 获取/设置 我的排行名次
function ExpeditionModel:getMyRank()
    return self.myRank
end
function ExpeditionModel:setMyRank(_rank)
    self.myRank = _rank
end

-- 获取/设置/清空 排行榜列表
function ExpeditionModel:getRankList()
    return self.rankList or {}
end
function ExpeditionModel:setRankList(_list)
    self.rankList = _list or {}
end
function ExpeditionModel:clearRankList()
    self.rankList = {}
end

-- 
function ExpeditionModel:getWinState()
    return self.isWin
end
function ExpeditionModel:setWinState(state)
    self.isWin = state
end

return ExpeditionModel