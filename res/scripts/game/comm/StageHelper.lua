--[[
    关卡辅助类
    提供关卡相关的辅助方法

    2016-3-8 by 宝爷
]]

StageHelper = {}

--章节模式
StageHelper.ChapterMode = 
{
    CM_COMON    = 1,      --普通模式
    CM_ELITE    = 2,      --精英模式
}

--章节状态
StageHelper.ChapterState = 
{
    CS_LOCK     = 0,      --未解锁
    CS_UNLOCK   = 1,      --已解锁
    CS_FINISH   = 2,      --已完成
    CS_REWARD   = 3,      --已领取
}

--关卡状态
StageHelper.StageState =
{
    SS_HIDE     = 0,      --未显示
    SS_LOCK     = 1,      --未解锁
    SS_UNLOCK   = 2,      --已解锁
    SS_ONE      = 3,      --单颗星
    SS_TWO      = 4,      --两个星
    SS_TRI      = 5,      --三个星  
}

--无效章节
StageHelper.InvalidChapter = 0
--无效关卡
StageHelper.InvalidStage = 0
--章节记录
StageHelper.CurChapter = nil
-- 快速前往关卡ID
StageHelper.QuickStageId = nil

--获取章节类型
function StageHelper.getChapterType(chapterID)
    local conf = getChapterConfItem(chapterID)
    return conf and conf.Type or nil
end

--获取章节状态
function StageHelper.getChapterState(chapterID)
    local s = getGameModel():getStageModel():getChapterState(chapterID)
    return s or StageHelper.InvalidChapter
end

--获取关卡状态
function StageHelper.getStageState(chapterID, stageID)
    local conf = getChapterConfItem(chapterID)
    if StageHelper.ChapterMode.CM_COMON == conf.Type then
        return getGameModel():getStageModel():getComonStageState(stageID)
    elseif StageHelper.ChapterMode.CM_ELITE == conf.Type then
        return getGameModel():getStageModel():getEliteStageState(stageID)
    end
    return StageHelper.StageState.SS_HIDE
end

--检查是否恢复
function StageHelper.checkNextTimestamp(chapterId, stageId)
    local conf = getChapterConfItem(chapterId)
    if StageHelper.ChapterMode.CM_ELITE == conf.Type then
        local nowStamp = getGameModel():getNow()
        local resetStamp = getGameModel():getStageModel():getEliteChallengeTimestamp(stageId)
        if nowStamp >= resetStamp or resetStamp == 0 then
           --恢复次数刷新
           local hour = 0--getTimeRecoverSetting().AllTimeReset / 60
           local min = 0--getTimeRecoverSetting().AllTimeReset % 60

           local nextStamp = getNextTimeStamp(nowStamp, min, hour)
           getGameModel():getStageModel():setEliteChallengeTimestamp(stageId, nextStamp)
           getGameModel():getStageModel():setEliteChallengeCount(stageId, 0)
           -- 购买次数刷新
           getGameModel():getStageModel():setEliteBuyTimestamp(stageId, nextStamp)
           getGameModel():getStageModel():setEliteBuyCount(stageId, 0)
        end
    end
end

--快速获取关卡ID对应的状态
function StageHelper.quickGetStageState(stageId)
    return StageHelper.getStageState(StageHelper.getChapterByStage(stageId), stageId)
end

--由关卡ID获取章节ID
function StageHelper.getChapterByStage(stageID)
    if stageID <= 0 then
        return StageHelper.InvalidChapter
    end
    local list = getChapterItemList()
    for _,id in pairs(list) do
        local conf = getChapterConfItem(id)  
        for k,v in pairs(conf.Stages) do
            if k == stageID then
                return id
            end
        end
    end
    return StageHelper.InvalidChapter
end

--获取当前关卡状态
function StageHelper.getCurrentStage(chapterType)
    local stageID = StageHelper.InvalidStage
    if StageHelper.ChapterMode.CM_COMON == chapterType then
        stageID = getGameModel():getStageModel():getCurrentComonStageID()
    elseif StageHelper.ChapterMode.CM_ELITE == chapterType then
        stageID = getGameModel():getStageModel():getCurrentEliteStageID()
    end
    if stageID then
        return stageID
    end
end

--获取当前章节
function StageHelper.getCurrentChapter(chapterType)
    local stageID = StageHelper.getCurrentStage(chapterType)
    return StageHelper.getChapterByStage(stageID)
end

--获取章节星星
function StageHelper.getChapterStar(chapterID)
    local conf = getChapterConfItem(chapterID)
    if conf == nil then
        return 0
    end 
    local star = 0
    for id, v in pairs(conf.Stages) do
        local state = StageHelper.StageState.SS_HIDE
        if StageHelper.ChapterMode.CM_COMON == conf.Type then
            local temp = math.mod(id, 100) 
            if math.mod(temp, 3) == 0 then
                state = getGameModel():getStageModel():getComonStageState(id)
            end
        elseif StageHelper.ChapterMode.CM_ELITE == conf.Type then
            state = getGameModel():getStageModel():getEliteStageState(id)
        end
        if StageHelper.StageState.SS_ONE == state then
            star = star + 1
        elseif StageHelper.StageState.SS_TWO == state then
            star = star + 2
        elseif StageHelper.StageState.SS_TRI == state then
            star = star + 3
        end
    end
    return star
end

--获取章节星星
function StageHelper.getChapterStarEx(chapterID)
    local conf = getChapterConfItem(chapterID)
    local star = 0
    for k,v in pairs(conf.Stages) do
        local id = k
        local state = StageHelper.StageState.SS_HIDE
        if StageHelper.ChapterMode.CM_COMON == conf.Type then
            state = getGameModel():getStageModel():getComonStageState(id)
        elseif StageHelper.ChapterMode.CM_ELITE == conf.Type then
            state = getGameModel():getStageModel():getEliteStageState(id)
        end
        if StageHelper.StageState.SS_ONE == state then
            star = star + 1
        elseif StageHelper.StageState.SS_TWO == state then
            star = star + 2
        elseif StageHelper.StageState.SS_TRI == state then
            star = star + 3
        end
    end
    return star
end

--获取所有章节星星
function StageHelper.getAllChapterStar()
    local star = 0
    local states = getGameModel():getStageModel():getChapterStates()
    for k,v in pairs(states) do
        local id = k
        star = star + StageHelper.getChapterStar(id)
    end
    return star
end

--解锁关卡
function StageHelper.finishStage(chapterID, stageID, state)
    local confChapter = getChapterConfItem(chapterID)
    local confStage = confChapter.Stages[stageID]
    if StageHelper.ChapterMode.CM_COMON == confChapter.Type then
        getGameModel():getStageModel():setComonStageState(stageID, state)
        local cur = getGameModel():getStageModel():getCurrentComonStageID()
        if cur == stageID then
            if confStage.NextID > 0 then
                getGameModel():getStageModel():setCurrentComonStageID(confStage.NextID)
            elseif confStage.NextID == 0 then
                getGameModel():getStageModel():setChapterState(chapterID, StageHelper.ChapterState.CS_FINISH)
                StageHelper.updateCurChapter(chapterID)
            end
        end
    elseif StageHelper.ChapterMode.CM_ELITE == confChapter.Type then
        local challengeCount = getGameModel():getStageModel():getEliteChallengeCount(stageID)
        getGameModel():getStageModel():setEliteChallengeCount(stageID, challengeCount + 1)

        getGameModel():getStageModel():setEliteStageState(stageID, state)
        local cur = getGameModel():getStageModel():getCurrentEliteStageID()
        if cur == stageID then
            if confStage.NextID > 0 then
                getGameModel():getStageModel():setCurrentEliteStageID(confStage.NextID)
            elseif confStage.NextID == 0 then
                getGameModel():getStageModel():setChapterState(chapterID, StageHelper.ChapterState.CS_FINISH)
                StageHelper.updateCurChapter(chapterID)
            end
        end
    end
end

--更新关卡模型
function StageHelper.updateStageModel()
    for i = StageHelper.ChapterMode.CM_COMON, StageHelper.ChapterMode.CM_ELITE do
        local curStageID = StageHelper.InvalidStage
        if StageHelper.ChapterMode.CM_COMON == i then
            curStageID = getGameModel():getStageModel():getCurrentComonStageID()
        elseif StageHelper.ChapterMode.CM_ELITE == i then
            curStageID = getGameModel():getStageModel():getCurrentEliteStageID()
        end

        if curStageID and curStageID > 0 then
            local curChapterID = StageHelper.getChapterByStage(curStageID)
            StageHelper.updateCurChapter(curChapterID)
        end
    end
end

-- 更新当前章节ID
function StageHelper.updateCurChapter(chapterID)
    local state = getGameModel():getStageModel():getChapterState(chapterID)
    if state < StageHelper.ChapterState.CS_FINISH then
        return
    end
    StageHelper.CurChapter = chapterID
    
    --[[
    local userLV = getGameModel():getUserModel():getUserLevel()
    local curConf = getChapterConfItem(chapterID)
    if curConf and curConf.Type == conf.Type then
        StageHelper.CurChapter = id
    end
    for k, id in pairs(confChapter.UnlockChapters) do
        local conf = getChapterConfItem(id)
        -- 是否达到解锁等级
        if conf and userLV >= conf.UnlockLevel then
            -- if confChapter.Type == conf.Type then
                -- StageHelper.CurChapter = id
                -- break
            -- end
            --
            local curConf = getChapterConfItem(StageHelper.CurChapter or 1)
            if curConf and curConf.Type == conf.Type then
                StageHelper.CurChapter = id
                break
            end
        end
    end 
    ]]
end

-- 获取章节宝箱领取状态
function StageHelper.getChapterBoxState(chapterID)
    return getGameModel():getStageModel():getChapterBoxState(chapterID)
end
-- 设置章节宝箱领取状态
-- state为0为未领取,1为领取
function StageHelper.setChapterBoxState(chapterID, index, state)
    getGameModel():getStageModel():setChapterBoxState(chapterID, index, state)
end