require"model.ModelConst"

-- PVP模型
local PvpModel = class("PvpModel")

function PvpModel:ctor()
	self.mBattleId = 0
	self.mRank = 0
	self.mIntegral = 0
	self.mContinueWinTimes = 0
	self.mHistoryHighestRank = 0
	self.mHistoryHighestIntegral = 0
	self.mHistoryContinueWinTimes = 0

	self.mCpRank = 0
	self.mCpWeekResetStamp = 0
	self.mCpGradingNum = 0
	self.mCpGradingDval = 0
	self.mCpIntegral = 0
	self.mCpContinueWinTimes = 0
	self.mCpHistoryHighestRank = 0
	self.mCpHistoryHighestIntegral = 0
	self.mCpHistoryContinueWinTimes = 0

	self.mDayResetStamp = 0
	self.mDayWinTimes = 0
	self.mDayContinueWinTimes = 0
	self.mDayMaxContinueWinTimes = 0
	self.mDayBattleTimes = 0
	self.mRewardFlag = 0

	self.mIsReconnect = false
	self.mRoomType = EPvpRoomType.PVPROOMTYPE_NONE
end

function PvpModel:init(buffData)
	self.mBattleId = buffData:readInt()					-- 战斗id, 如果战斗id不为0, 请求断线重连
	self.mRank = buffData:readInt()						-- 当前排名
	self.mIntegral = buffData:readInt()					-- 竞技积分
	self.mContinueWinTimes = buffData:readInt()			-- 连续胜场
	self.mHistoryHighestRank = buffData:readInt()		-- 历史最高排名
	self.mHistoryHighestIntegral = buffData:readInt()	-- 历史最高积分
	self.mHistoryContinueWinTimes = buffData:readInt()	-- 历史最高连胜

	self.mDayResetStamp = buffData:readInt()			-- 日重置时间
	self.mDayWinTimes = buffData:readInt()				-- 日胜场
	self.mDayContinueWinTimes = buffData:readInt()		-- 日连续胜场数
	self.mDayMaxContinueWinTimes = buffData:readInt()	-- 日最高连胜场数
	self.mDayBattleTimes = buffData:readInt()			-- 日战斗场数
	self.mRewardFlag = buffData:readInt()				-- 日奖励领取标示符

	return true
end

-- 重置任务状态
function PvpModel:resetPvpTask()
	self.mDayBattleTimes = 0
	self.mDayContinueWinTimes = 0
	self.mDayWinTimes = 0
	self.mRewardFlag = 0
	self.mDayMaxContinueWinTimes = 0
	self.mDayResetStamp = self.mDayResetStamp + 24 * 3600	-- 直接用服务器的时间加一天
end

function PvpModel:getPvpInfo()
	return {
		BattleId 							= self.mBattleId,
        ResetStamp 							= self.mDayResetStamp,
        Score 								= self.mIntegral,
        Rank 								= self.mRank,
        ContinusWinTimes 					= self.mContinueWinTimes,
        DayWin 								= self.mDayWinTimes,
        DayContinusWin 						= self.mDayContinueWinTimes,
        DayMaxContinusWinTimes 				= self.mDayMaxContinueWinTimes,
        DayBattleCount 						= self.mDayBattleTimes,
        HistoryRank 						= self.mHistoryHighestRank,
        HistoryScore 						= self.mHistoryHighestIntegral,
        RewardFlag 							= self.mRewardFlag,
        HistoryContinusWinTimes 			= self.mHistoryContinueWinTimes,

        CpnRank 							= self.mCpRank,
        CpnWeekResetStamp 					= self.mCpWeekResetStamp,
        CpnGradingNum 						= self.mCpGradingNum,
        CpnGradingDval 						= self.mCpGradingDval,
        CpnIntegral 						= self.mCpIntegral,
        CpnContinusWinTimes 				= self.mCpContinueWinTimes,
        CpnHistoryHigestRank 				= self.mCpHistoryHighestRank,
        CpnHistoryHigestIntegral 			= self.mCpHistoryHighestIntegral,
        CpnHistoryContinusWinTimes 			= self.mCpHistoryContinueWinTimes,
	}
end

-- 是否重连
function PvpModel:isReconnect()
	return self.mIsReconnect
end

-- 设置是否重连
-- @param i: 0-false, else true
function PvpModel:setReconnect(i)
	self.mIsReconnect = i ~= 0
end

function PvpModel:setBattleId(id)
	self.mBattleId = id
end

-- 设置排名
function PvpModel:setRank(matchType, rank)
	if matchType == MatchType.MATCH_FAIRPVP then
		self.mRank = rank
	else
		self.mCpRank = rank
	end
end

-- 获得pvp排名
function PvpModel:getRank()
	return self.mRank
end

-- 设置积分
function PvpModel:setScore(matchType, score)
	if matchType == MatchType.MATCH_FAIRPVP then
		self.mIntegral = score
	else
		self.mCpIntegral = score
	end
end

-- 获取积分
function PvpModel:getScore(matchType)
	if matchType == MatchType.MATCH_FAIRPVP then
		return self.mIntegral
	else
		return self.mCpIntegral
	end
end

-- 设置历史最高排名
function PvpModel:setHistoryRank(matchType, rank)
	if matchType == MatchType.MATCH_FAIRPVP then
		self.mHistoryHighestRank = rank
	else
		self.mCpHistoryHighestRank = rank
	end
end

-- 获得历史最高排名
function PvpModel:getHistoryRank(matchType)
	if matchType == MatchType.MATCH_FAIRPVP then
		return self.mHistoryHighestRank
	else
		return self.mCpHistoryHighestRank
	end
end

-- 设置历史最高积分
function PvpModel:setHistoryScore(matchType, score)
	if matchType == MatchType.MATCH_FAIRPVP then
		self.mHistoryHighestIntegral = score
	else
		self.mCpHistoryHighestIntegral = score
	end
end

-- 获得历史最高积分
function PvpModel:getHistoryScore(matchType)
	if matchType == MatchType.MATCH_FAIRPVP then
		return self.mHistoryHighestIntegral
	else
		return self.mCpHistoryHighestIntegral
	end
end

-- 设置房间类型
function PvpModel:setRoomType(roomType)
	self.mRoomType = roomType
end

-- 获取房间类型
function PvpModel:getRoomType()
	return self.mRoomType
end

-- 获取任务奖励状态
function PvpModel:getPvpTaskStatus(rewardType)
	if rewardType < 0 or rewardType > 32 then
		return -1
	end
	return bit.band(bit.brshift(self.mRewardFlag, rewardType), 1)
end

-- 设置任务奖励状态
function PvpModel:setPvpTaskStatus(rewardType)
	if rewardType < 0 or rewardType > 32 then
		return
	end
	self.mRewardFlag = bit.bor(self.mRewardFlag, bit.blshift(1, rewardType))
end

-- 根据胜利失败计算日胜场等任务
function PvpModel:setDayTask(result)
	if result == 1 then
		self.mDayContinueWinTimes = self.mDayContinueWinTimes + 1
		self.mDayWinTimes = self.mDayWinTimes + 1
		if self.mDayContinueWinTimes > self.mDayMaxContinueWinTimes then
			self.mDayMaxContinueWinTimes = self.mDayContinueWinTimes
		end
	else
		self.mDayContinueWinTimes = 0
	end

	self.mDayBattleTimes = self.mDayBattleTimes + 1
end

function PvpModel:resetPvpTask(taskType)
    if taskType == 0 then
        self.mDayBattleTimes = 0
    elseif taskType == 1 then
        self.mDayWinTimes = 0
    elseif taskType == 2 then
        self.mDayMaxContinueWinTimes =0
    end
end

-- 设置pvp连续胜场
function PvpModel:setContinueWinTimes(result)
	if result == 1 then
		if self.mContinueWinTimes < 0 then
			self.mContinueWinTimes = 1
		else
			self.mContinueWinTimes = self.mContinueWinTimes + 1
		end

		if self.mContinueWinTimes > self.mHistoryContinueWinTimes then
			self.mHistoryContinueWinTimes = self.mContinueWinTimes
		end
	else
		if self.mContinueWinTimes > 0 then
			self.mContinueWinTimes = -1
		else
			self.mContinueWinTimes = self.mContinueWinTimes - 1
		end
	end
end

-- 获取pvp历史最高连胜
function PvpModel:getHistoryContinueWinTimes()
	return self.mHistoryContinueWinTimes
end

-- 锦标赛赛季重置
function PvpModel:resetChampionArena()
	self.mCpContinueWinTimes = 0
	self.mCpRank = 0
	self.mCpWeekResetStamp = self.mCpWeekResetStamp + 7 * 24 * 3600
	self.mCpGradingNum = 0
	self.mCpGradingDval = 0
	self.mCpIntegral = 0
	self.mCpContinueWinTimes = 0
	self.mCpHistoryContinueWinTimes = 0
end

-- 定级赛次数+1
function PvpModel:addGradingNum()
	self.mCpGradingNum = self.mCpGradingNum + 1
end

return PvpModel