--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-8-30 14:31
** 版  本:	1.0
** 描  述:  队伍信息存取
** 应  用:
********************************************************************/
--]]

local UserDefault = { TEAM_ID = "TEAM_ID_", TEAM_SUMMONER = "TEAM_SUMMONER_", TEAM_HEROS = "TEAM_HEROS_"}

TeamHelper = TeamHelper or {}

function TeamHelper.init()

end

-- 获取当前队伍信息
function TeamHelper.getTeamInfo()
    local teamId = TeamHelper.getTeamId()
    local summonerID = TeamHelper.getTeamSummoner(teamId)
    local heroList = TeamHelper.getTeamHeros(teamId)

    return summonerID, heroList
end

-- 获取当前队伍id
function TeamHelper.getTeamId()
    local userId = getGameModel():getUserModel():getUserID()

    local key = UserDefault.TEAM_ID .. gServerID .. "_" .. userId
    local teamId = cc.UserDefault:getInstance():getIntegerForKey(key, 1)
    return teamId
end

function TeamHelper.getTeamSummoner(teamId)
    local userId = getGameModel():getUserModel():getUserID()

    local key = UserDefault.TEAM_SUMMONER .. gServerID .. "_" .. userId .. "_" .. teamId
    local summonerId = cc.UserDefault:getInstance():getIntegerForKey(key)
    return summonerId
end

function TeamHelper.setTeamSummoner(summonerId, teamId)
    local userId = getGameModel():getUserModel():getUserID()
    local teamId = teamId and teamId or TeamHelper.getTeamId()

    local key = UserDefault.TEAM_SUMMONER .. gServerID .. "_" .. userId .. "_" .. teamId
    cc.UserDefault:getInstance():setIntegerForKey(key, summonerId)
end


function TeamHelper.getTeamHeros(teamId)
    local userId = getGameModel():getUserModel():getUserID()

    local key = UserDefault.TEAM_HEROS .. gServerID .. "_" .. userId .. "_" .. teamId
    local heros = cc.UserDefault:getInstance():getStringForKey(key)
    heros = string.split(heros, ",")
    local herosId = {}
    for _, id in pairs(heros) do
        if "" ~= id then
            table.insert(herosId, tonumber(id))
        end
    end
    return herosId
end

function TeamHelper.setTeamInfo(teamId, summonerId, herosId)
    local userId = getGameModel():getUserModel():getUserID()
    --
    local key = UserDefault.TEAM_ID .. gServerID .. "_" .. userId
    cc.UserDefault:getInstance():setIntegerForKey(key, teamId)
    --
    key = UserDefault.TEAM_SUMMONER .. gServerID .. "_" .. userId .. "_" .. teamId
    cc.UserDefault:getInstance():setIntegerForKey(key, summonerId)
    --
    key = UserDefault.TEAM_HEROS .. gServerID .. "_" .. userId .. "_" .. teamId
    if herosId and #herosId > 0 then
        local str = ""
        for _, id in pairs(herosId) do
            str = str .. id .. ","
        end
        cc.UserDefault:getInstance():setStringForKey(key, str)
    else
        cc.UserDefault:getInstance():setStringForKey(key, ",")
    end

    cc.UserDefault:getInstance():flush()
end

-- 是否存在当前队伍中
function TeamHelper.isExistCurTeam(heroId)
    local teamId = TeamHelper.getTeamId()
    local heroList = TeamHelper.getTeamHeros(teamId) or {}
    for _, id in ipairs(heroList) do
        if id == heroId then
            return true
        end
    end
    
    return false
end

return TeamHelper