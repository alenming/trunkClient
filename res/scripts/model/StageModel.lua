require"model.ModelConst"

-- 关卡模型
local StageModel = class("StageModel")

function StageModel:ctor()
	self.mCurrentCommonStageID = 0
	self.mCurrentEliteStageID = 0
	self.mChapterCount = 0
	self.mEliteChapterCount = 0
	self.mStageCount = 0
	self.mEliteCount = 0
	self.mEliteRecordCount = 0
	self.mChapterStates = {}
	self.mCommonStageStates = {}
	self.mEliteStageStates = {}
	self.mEliteStageChallengeCount = {}
	self.mEliteStageChallengeTimestamp = {}
	self.mEliteStageBuyCount = {}
	self.mEliteStageBuyTimestamp = {}
	-- 章节宝箱数据
	self.mChapterBox = {}
end

function StageModel:init(buffData)
	self.mCurrentCommonStageID = buffData:readInt()				-- 当前普通关卡id
	self.mCurrentEliteStageID = buffData:readInt()				-- 当前精英关卡id
	self.mChapterCount = buffData:readUShort()					-- 普通章节个数
	self.mEliteChapterCount = buffData:readUShort()				-- 精英章节个数
	self.mStageCount = buffData:readUShort()					-- 普通关卡个数
	self.mEliteCount = buffData:readUShort()					-- 精英关卡个数
	self.mEliteRecordCount = buffData:readUShort()				-- 精英关卡记录个数

	self.mChapterStates = {}									-- 普通章节状态
	for i = 1, self.mChapterCount do
		local chapterID = buffData:readInt()					-- 普通章节id
		local chapterStatus = buffData:readUChar()				-- 普通章节状态
		self.mChapterStates[chapterID] = chapterStatus
		local boxCount = buffData:readUChar()
        self.mChapterBox[chapterID] = {}
		for j=1,boxCount do
			local boxId = buffData:readUChar()
			table.insert(self.mChapterBox[chapterID], boxId, boxId)
		end
	end
	for i = 1, self.mEliteChapterCount do
		local chapterID = buffData:readInt()					-- 精英章节id
		local chapterStatus = buffData:readUChar()				-- 精英章节状态
		self.mChapterStates[chapterID] = chapterStatus
	end

	self.mCommonStageStates = {}								-- 各普通关卡状态
	for i = 1, self.mStageCount do
		local stageId = buffData:readInt() 						-- 关卡id
		local stageStatus = buffData:readUChar()				-- 关卡状态
		self.mCommonStageStates[stageId] = stageStatus
	end

	self.mEliteStageStates = {}									-- 各精英关卡状态
	for i = 1, self.mEliteCount do
		local stageId = buffData:readInt() 						-- 精英关卡id
		local stageStatus = buffData:readUChar()				-- 精英关卡状态
		self.mEliteStageStates[stageId] = stageStatus
	end

	self.mEliteStageChallengeCount = {}							-- 精英关卡已经挑战的次数
	self.mEliteStageChallengeTimestamp = {}						-- 精英关卡挑战时间戳
	self.mEliteStageBuyCount = {}								-- 精英关卡购买次数
	self.mEliteStageBuyTimestamp = {}							-- 精英关卡购买时间戳
	for i = 1, self.mEliteRecordCount do
		local stageId = buffData:readInt()					  	-- 精英关卡id
    	local canUseTimes = buffData:readChar() 			  	-- 可使用次数
    	local useStamp = buffData:readInt() 				  	-- 上次使用的时间戳
    	local buyTimes = buffData:readChar() 				  	-- 购买次数
    	local buyStamp = buffData:readInt()				  		-- 购买时间戳
    	self.mEliteStageChallengeCount[stageId] = canUseTimes
    	self.mEliteStageChallengeTimestamp[stageId] = useStamp
    	self.mEliteStageBuyCount[stageId] = buyTimes
    	self.mEliteStageBuyTimestamp[stageId] = buyStamp
	end

	return true
end

function StageModel:getChapterIDByStageID(stageId)
	return StageHelper.getChapterByStage(stageId)
end

function StageModel:getChapterStates()
	return self.mChapterStates
end

function StageModel:getComonStageStates()
	return self.mCommonStageStates
end

function StageModel:getEliteStageStates()
	return self.mEliteStageStates
end

-- 获取当前普通关卡
function StageModel:getCurrentComonStageID()
	return self.mCurrentCommonStageID
end

-- 设置当前普通关卡
function StageModel:setCurrentComonStageID(id)
	self.mCurrentCommonStageID = id
end

-- 获取当前精英关卡
function StageModel:getCurrentEliteStageID()
	return self.mCurrentEliteStageID
end

-- 设置当前精英关卡
function StageModel:setCurrentEliteStageID(id)
	self.mCurrentEliteStageID = id
end

-- 获取章节状态
function StageModel:getChapterState(chapter)
	return self.mChapterStates[chapter] or EChapterState.ECS_LOCK
end

-- 设置章节状态
function StageModel:setChapterState(chapter, state)
    if not self.mChapterStates[chapter] or state > self.mChapterStates[chapter] then
        self.mChapterStates[chapter] = state
    end
end

-- 获取普通关卡状态
function StageModel:getComonStageState(stageId)
	if stageId > self.mCurrentCommonStageID + 1 then
		return ELevelState.ESS_HIDE
	elseif stageId > self.mCurrentCommonStageID then
		return ELevelState.ESS_LOCK
	elseif stageId == self.mCurrentCommonStageID then
		local chapter = self:getChapterIDByStageID(stageId)
		local chapterState = self:getChapterState(chapter)
		if chapterState == EChapterState.ECS_FINISH or chapterState == EChapterState.ECS_REWARD then
			return self.mCommonStageStates[stageId] or ELevelState.ESS_TRI
		end
		return ELevelState.ESS_UNLOCK
	else
		return self.mCommonStageStates[stageId] or ELevelState.ESS_TRI
	end
end

-- 设置普通关卡状态
function StageModel:setComonStageState(stageId, state)
    if stageId == self.mCurrentCommonStageID then
        if not self.mCommonStageStates[stageId] or state > self.mCommonStageStates[stageId] then
            self.mCommonStageStates[stageId] = state
        end
    elseif stageId < self.mCurrentCommonStageID then
        if state == ELevelState.ESS_TRI then
            self.mCommonStageStates[stageId] = nil
        elseif state == ELevelState.ESS_ONE or state == ELevelState.ESS_TWO then
            if self.mCommonStageStates[stageId] and state > self.mCommonStageStates[stageId] then
                self.mCommonStageStates[stageId] = state
            end
        end
    end
end

-- 获取精英关卡状态
function StageModel:getEliteStageState(stageId)
	if stageId > self.mCurrentEliteStageID + 1 then
		return ELevelState.ESS_HIDE
	elseif stageId > self.mCurrentEliteStageID then
		return ELevelState.ESS_LOCK
	elseif stageId == self.mCurrentEliteStageID then
		local chapter = self:getChapterIDByStageID(stageId)
		local chapterState = self:getChapterState(chapter)
		if chapterState == EChapterState.ECS_FINISH or chapterState == EChapterState.ECS_REWARD then
			return self.mEliteStageStates[stageId] or ELevelState.ESS_TRI
		end
		return ELevelState.ESS_UNLOCK
	else
		return self.mEliteStageStates[stageId] or ELevelState.ESS_TRI
	end
end

-- 设置精英关卡状态
function StageModel:setEliteStageState(stageId, state)
    if stageId == self.mCurrentEliteStageID then
        if not self.mEliteStageStates[stageId] or state > self.mEliteStageStates[stageId] then
            self.mEliteStageStates[stageId] = state
        end
    elseif stageId < self.mCurrentEliteStageID then
        if state == ELevelState.ESS_TRI then
            self.mEliteStageStates[stageId] = nil
        elseif state == ELevelState.ESS_ONE or state == ELevelState.ESS_TWO then
            if self.mEliteStageStates[stageId] and state > self.mEliteStageStates[stageId] then
                self.mEliteStageStates[stageId] = state
            end
        end
    end
end

-- 获取精英关卡已经挑战的次数
function StageModel:getEliteChallengeCount(stageId)
	return self.mEliteStageChallengeCount[stageId] or 0
end

-- 设置精英关卡已经挑战的次数
function StageModel:setEliteChallengeCount(stageId, count)
	self.mEliteStageChallengeCount[stageId] = count
end

-- 获取精关关卡购买次数
function StageModel:getEliteBuyCount(stageId)
	return self.mEliteStageBuyCount[stageId] or 0
end

-- 设置精英关卡购买次数
function StageModel:setEliteBuyCount(stageId, count)
	self.mEliteStageBuyCount[stageId] = count
end

-- 获取精英挑战时间戳
function StageModel:getEliteChallengeTimestamp(stageId)
	return self.mEliteStageChallengeTimestamp[stageId] or 0
end

-- 设置精英挑战时间戳
function StageModel:setEliteChallengeTimestamp(stageId, time)
	self.mEliteStageChallengeTimestamp[stageId] = time
end

-- 获取精英购买时间戳
function StageModel:getEliteBuyTimestamp(stageId)
	return self.mEliteStageBuyTimestamp[stageId] or 0
end

-- 设置精英购买时间戳
function StageModel:setEliteBuyTimestamp(stageId, time)
	self.mEliteStageBuyTimestamp[stageId] = time
end

-- 重置精英关卡挑战次数	
function StageModel:resetEliteChallengeCount(stageId)
	if self.mEliteStageChallengeCount[stageId] then
		self.mEliteStageChallengeCount[stageId] = 0
	end
end

-- 重置精英关卡购买次数
function StageModel:resetEliteBuyCount(stageId)
	if self.mEliteStageBuyCount[stageId] then
		self.mEliteStageBuyCount[stageId] = 0
	end
end

-- 获取章节宝箱领取状态
function StageModel:getChapterBoxState(chapterID)
	if not self.mChapterBox[chapterID] then
		self.mChapterBox[chapterID] = {}
	end

	return self.mChapterBox[chapterID]
end

-- 设置章节宝箱领取状态
function StageModel:setChapterBoxState(chapterID, index)
	if not self.mChapterBox[chapterID] then
		self.mChapterBox[chapterID] = {}
	end
	--table.insert(self.mChapterBox[chapterID], index, index)
	self.mChapterBox[chapterID][index] = index
end

return StageModel