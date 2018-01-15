---------------------------------------------------
--名称:GuideCondition
--描述:引导条件
--时间:20160406
--作者:Azure
-------------------------------------------------

GuideCondition = {}

--判定类型
GuideCondition.JudgeType = 
{
    GJT_LESS            = 0,    --小于
    GJT_MORE_EQUAL      = 1,    --大于等于
    GJT_EQUAL           = 2,    --等于
    GJT_NOT_EQUAL       = 3,    --不等于
}

--条件类型
GuideCondition.Type = 
{   
    GCT_IS_GUIDE        = 1,    --当前是否有引导（是否取反）
    GCT_USER_LV         = 2,    --用户等级（判定+参数）
    GCT_SUM_NUM         = 3,    --召唤师数量（判定+参数）
    GCT_HERO_NUM        = 4,    --英雄数量（判定+参数）
    GCT_HERO_MAX_LV     = 5,    --英雄最高等级（英雄ID+判定+参数）
    GCT_HERO_MAX_STAR   = 6,    --英雄最高星级（英雄ID+判定+参数）
    GCT_UI_CLICK        = 7,    --界面点击(界面ID)
    GCT_HERO_READY      = 8,    --卡片是否可以出战(序号1-7)
    GCT_SUM_SKILL_READY = 9,    --召唤师技能是否准备好(序号1-3)
    GCT_CRYSTAL_NUM     = 10,   --水晶数量（判定+参数）
    GCT_STAGE_RESULT    = 11,   --判断关卡（关卡ID（是否相等）,判断+结果参数，0失败，123表示胜利的星级）
    GCT_PVP_RESULT      = 12,   --判断PVP结果,（0失败，1表示胜利）
    GCT_STAGE_ID        = 13,
    GCT_IS_UI_TOP       = 14,   --判断某界面是否在顶端
    GCT_IS_UI_OPENED    = 15,   --判断某界面当前是否处于打开状态（不一定在顶端）
    GCT_IS_ARGS_EQUAL   = 16,   --判断传入的参数是否等于某值
    GCT_IS_ENERGY       = 17,   --判断体力（判定+参数）
}

--判定过程
function GuideCondition.judgeResult(tp, src, aim)
    print(tp .. " ~~~ " .. src .. " ~~~ " .. aim)
    if GuideCondition.JudgeType.GJT_LESS == tp then
        return aim < src
    elseif GuideCondition.JudgeType.GJT_MORE_EQUAL == tp then
        return aim >= src
    elseif GuideCondition.JudgeType.GJT_EQUAL == tp then
        return aim == src
    elseif GuideCondition.JudgeType.GJT_NOT_EQUAL == tp then
        return aim ~= src
    end
    return false
end

--判定条件
function GuideCondition.judgeCondition(condition, ...)
    if GuideCondition.Type.GCT_IS_GUIDE == condition.Type then
        local flag = condition.Param[1]
        if flag == 1 then
            return GuideManager.currentGuide ~= nil
        else
            return GuideManager.currentGuide == nil
        end
    elseif GuideCondition.Type.GCT_USER_LV == condition.Type then
        local lv = getGameModel():getUserModel():getUserLevel()
        print("judge lv "..lv .. " type " .. condition.Param[1] .. " lv " .. condition.Param[2] .. " result ")
        print(GuideCondition.judgeResult(condition.Param[1], condition.Param[2], lv))
        return GuideCondition.judgeResult(condition.Param[1], condition.Param[2], lv)
    elseif GuideCondition.Type.GCT_SUM_NUM == condition.Type then
        local count = getGameModel():getSummonersModel():getSummonerCount()
        return GuideCondition.judgeResult(condition.Param[1], condition.Param[2], count)
    elseif GuideCondition.Type.GCT_HERO_NUM == condition.Type then
        local count = getGameModel():getHeroCardBagModel():getHeroCardCount()
        return GuideCondition.judgeResult(condition.Param[1], condition.Param[2], count)
    elseif GuideCondition.Type.GCT_HERO_MAX_LV == condition.Type then
        local soilderID = condition.Param[1]
        local lv = 0
        if soilderID > 0 then
            local model = getGameModel():getHeroCardBagModel():getHeroCard(soilderID)
            lv = model:getLevel()
        elseif soilderID == 0 then
            local cards = getGameModel():getHeroCardBagModel():getHeroCards()
            for k, v in pairs(cards) do
                local model = getGameModel():getHeroCardBagModel():getHeroCard(v)
                if model:getLevel() > lv then
                    lv = model:getLevel()
                end
            end
        end
        return GuideCondition.judgeResult(condition.Param[2], condition.Param[3], lv) 
    elseif GuideCondition.Type.GCT_HERO_MAX_STAR == condition.Type then
        local soilderID = condition.Param[1]
        local star = 0
        if soilderID > 0 then
            local model = getGameModel():getHeroCardBagModel():getHeroCard(soilderID)
            star = model:getStar()
        elseif soilderID == 0 then
            local cards = getGameModel():getHeroCardBagModel():getHeroCards()
            for k, v in pairs(cards) do
                local model = getGameModel():getHeroCardBagModel():getHeroCard(v)
                if model:getLevel() > star then
                    star = model:getStar()
                end
            end
        end
        return GuideCondition.judgeResult(condition.Param[2], condition.Param[3], star) 
    elseif GuideCondition.Type.GCT_UI_CLICK == condition.Type then
        local id = select(1, ...)
        for k,v in pairs(condition.Param) do
            if GuideCondition.judgeResult(GuideCondition.JudgeType.GJT_EQUAL, v, id) then
                return true
            end
        end
        return false
    elseif GuideCondition.Type.GCT_HERO_READY == condition.Type then
        local index = select(1, ...)
        local ret = isHeroCardReady(index)
        return ret
    elseif GuideCondition.Type.GCT_SUM_SKILL_READY == condition.Type then
        local index = select(1, ...)
        local ret = isSkillReady(index)
        return ret
    elseif GuideCondition.Type.GCT_CRYSTAL_NUM == condition.Type then
        return false
    elseif GuideCondition.Type.GCT_STAGE_RESULT == condition.Type then
        local stageState = StageHelper.quickGetStageState(condition.Param[1])
        stageState = stageState - StageHelper.StageState.SS_ONE + 1
        print("GuideCondition.Type.GCT_STAGE_RESULT " .. stageState .. " stageId " .. condition.Param[1])
        if stageState < 0 then
            stageState = 0
        end
        if  GuideCondition.judgeResult(condition.Param[2], condition.Param[3], stageState) then
            return true
        end
    elseif GuideCondition.Type.GCT_PVP_RESULT == condition.Type then
        local args = select(1, ...)
        print("GCT_PVP_RESULT pvp result " .. args.battleResult .. " param " .. condition.Param[1])
        return condition.Param[1] == args.battleResult
    elseif GuideCondition.Type.GCT_STAGE_ID == condition.Type then
        -- Lua传入的参数为table，应该取其stageId字段进行判断
        -- C++传入的参数为int，可以直接进行判断
        print("args is " .. type(args))
        print("param is " .. condition.Param[1])
        local args = select(1, ...)
        if type(args) == "table" then
            print("param " .. condition.Param[1]  .. " args.stageId ".. args.stageId)
            return condition.Param[1] == args.stageId
        else
            return condition.Param[1] == args
        end
    elseif GuideCondition.Type.GCT_IS_UI_TOP == condition.Type then
        return UIManager.isTopUI(condition.Param[1])
    elseif GuideCondition.Type.GCT_IS_UI_OPENED == condition.Type then
        print("查询UI index " .. condition.Param[1])
        return UIManager.getUIIndex(condition.Param[1]) ~= -1
    elseif GuideCondition.Type.GCT_IS_ARGS_EQUAL == condition.Type then
        print("GuideCondition.Type.GCT_IS_ARGS_EQUAL")
        return condition.Param[1] ==  select(1, ...)
    elseif GuideCondition.Type.GCT_IS_ENERGY == condition.Type then
        --local userModel = getGameModel():getUserModel()
        --return GuideCondition.judgeResult(condition.Param[1], condition.Param[2], userModel:getEnergy())
    end
    print("没有配置条件" )
    return false
end