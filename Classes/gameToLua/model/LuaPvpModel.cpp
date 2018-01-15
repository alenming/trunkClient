#include "LuaPvpModel.h"
#include "LuaTools.h"
#include "ModelData.h"

int resetPvp(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        model->resetPvp();
    }

    return 0;
}

int getPvpInfo(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        lua_newtable(L);
        const PvpInfo& pvpInfo = model->getPvpInfo();
		LuaTools::pushBaseKeyValue(L, pvpInfo.BattleId, "BattleId");
        LuaTools::pushBaseKeyValue(L, pvpInfo.ResetStamp, "ResetStamp");
        LuaTools::pushBaseKeyValue(L, pvpInfo.DayBattleCount, "DayBattleCount");
        LuaTools::pushBaseKeyValue(L, pvpInfo.DayContinusWin, "DayContinusWin");
        LuaTools::pushBaseKeyValue(L, pvpInfo.DayWin, "DayWin");
        LuaTools::pushBaseKeyValue(L, pvpInfo.HistoryRank, "HistoryRank");
        LuaTools::pushBaseKeyValue(L, pvpInfo.HistoryScore, "HistoryScore");
        LuaTools::pushBaseKeyValue(L, pvpInfo.RewardFlag, "RewardFlag");
        LuaTools::pushBaseKeyValue(L, pvpInfo.Rank, "Rank");
        LuaTools::pushBaseKeyValue(L, pvpInfo.Score, "Score");
        LuaTools::pushBaseKeyValue(L, pvpInfo.ContinusWinTimes, "ContinusWinTimes");
        LuaTools::pushBaseKeyValue(L, pvpInfo.DayMaxContinusWinTimes, "DayMaxContinusWinTimes");

        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnRank, "CpnRank");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnWeekResetStamp, "CpnWeekResetStamp");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnGradingNum, "CpnGradingNum");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnGradingDval, "CpnGradingDval");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnIntegral, "CpnIntegral");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnContinusWinTimes, "CpnContinusWinTimes");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnHistoryHigestRank, "CpnHistoryHigestRank");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnHistoryHigestIntegral, "CpnHistoryHigestIntegral");
        LuaTools::pushBaseKeyValue(L, pvpInfo.CpnHistoryContinusWinTimes, "CpnHistoryContinusWinTimes");

        LuaTools::pushBaseKeyValue(L, pvpInfo.LastChestTime, "LastChestTime");
        LuaTools::pushBaseKeyValue(L, pvpInfo.ChestStatus, "ChestStatus");
        LuaTools::pushBaseKeyValue(L, pvpInfo.DayBuyChestTimes, "DayBuyChestTimes");

        return 1;
    }

    return 0;
}

int isReconnect(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
	if (model)
	{
		lua_pushboolean(L, model->isReconnect());
		return 1;
	}
	return 0;
}

int setReconnect(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
	int isReconn = luaL_checkint(L, -1);
	if (model)
	{
		bool bIsReconn = isReconn == 0 ? false : true;
		model->setReconnect(bIsReconn);
	}
	return 0;
}

int setBattleId(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
	int nBattleId = luaL_checkint(L, -1);
	if (model)
	{
		model->setBattleId(nBattleId);
	}
	return 0;
}

int setRank(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -3, "Summoner.PvpModel");
    int type = luaL_checkint(L, -2);
    int rank = luaL_checkint(L, -1);
    if (model)
    {
        model->setRank(type, rank);
    }
    return 0;
}

int getRank(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
	if (model)
	{
		lua_pushinteger(L, model->getRank());
		return 1;
	}
	return 0;
}

int setScore(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -3, "Summoner.PvpModel");
    int type = luaL_checkint(L, -2);
    int score = luaL_checkint(L, -1);
    if (model)
    {
        model->setScore(type, score);
    }
    return 0;
}

int getScore(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
    if (model)
    {
        lua_pushinteger(L, model->getScore(type));
        return 1;
    }
    return 0;
}

int setHistoryRank(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -3, "Summoner.PvpModel");
    int type = luaL_checkint(L, -2);
    int rank = luaL_checkint(L, -1);
    if (model)
    {
        model->setHistoryRank(type, rank);
    }
    return 0;
}

int getHistoryRank(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
	if (model)
	{
        lua_pushinteger(L, model->getHistoryRank(type));
		return 1;
	}
	return 0;
}

int setHistoryScore(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -3, "Summoner.PvpModel");
    int type = luaL_checkint(L, -2);
    int score = luaL_checkint(L, -1);
    if (model)
    {
        model->setHistoryScore(type, score);
    }
    return 0;
}

int getHistoryScore(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
	if (model)
	{
        lua_pushinteger(L, model->getHistoryScore(type));
		return 1;
	}
	return 0;
}

int setRoomType(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
    if (model)
    {
        model->setRoomType(type);
    }
    return 0;
}

int getRoomType(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        lua_pushinteger(L, model->getRoomType());
        return 1;
    }
    return 0;
}

int getPvpTaskStatus(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
    if (model)
    {
        lua_pushinteger(L, model->getPvpTaskStatus(type));
        return 1;
    }
    return 0;
}

int setPvpTaskStatus(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int type = luaL_checkint(L, -1);
    if (model)
    {
        model->setPvpTaskStatus(type);
    }
    return 0;
}

int setDayTask(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
	int result = luaL_checkint(L, -1);
	if (model)
	{
		model->setDayTask(result);
	}
	return 0;
}

int resetPvpTaskWithType(lua_State *L)
{
	CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
	int type = luaL_checkint(L, -1);
	if (model)
	{
		model->resetPvpTaskWithType(type);
	}
	return 0;
}

int setContinueWinTimes(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int result = luaL_checkint(L, -1);
    if (model)
    {
        model->setContinueWinTimes(result == 1);
    }
    return 0;
}

int getHistoryContinueWinTimes(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        lua_pushinteger(L, model->getHistoryContinueWinTimes());
        return 1;
    }
    return 0;
}

int resetChampionArena(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        model->resetChampionArena();
        return 1;
    }
    return 0;
}

int addGradingNum(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        model->addGradingNum();
    }
    return 0;
}

int setLastChestTime(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int time = luaL_checkint(L, -1);
    if (model)
    {
        model->setLastChestTime(time);
    }
    return 0;
}

int setChestStatus(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int status = luaL_checkint(L, -1);
    if (model)
    {
        model->setChestStatus(status);
    }
    return 0;
}

int setDayBuyChestTimes(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    int times = luaL_checkint(L, -1);
    if (model)
    {
        model->setDayBuyChestTimes(times);
    }
    return 0;
}

int getLastChestTime(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -1, "Summoner.PvpModel");
    if (model)
    {
        lua_pushinteger(L, model->getLastChestTime());
        return 1;
    }
    return 0;
}

static const struct luaL_reg funcPvp[] =
{
    { "resetPvp", resetPvp },
    { "getPvpInfo", getPvpInfo },
	{ "isReconnect", isReconnect },
	{ "setReconnect", setReconnect },
	{ "setBattleId", setBattleId},
    { "setRank", setRank },
	{ "getRank", getRank },
    { "setScore", setScore },
    { "getScore", getScore },
    { "setHistoryRank", setHistoryRank },
	{ "getHistoryRank", getHistoryRank },
    { "setHistoryScore", setHistoryScore },
	{ "getHistoryScore", getHistoryScore },
	{ "setRoomType", setRoomType },
    { "getRoomType", getRoomType },
    { "getPvpTaskStatus", getPvpTaskStatus },
    { "setPvpTaskStatus", setPvpTaskStatus },
	{ "setDayTask", setDayTask },
	{ "resetPvpTaskWithType", resetPvpTaskWithType },
    { "setContinueWinTimes", setContinueWinTimes },
    { "getHistoryContinueWinTimes", getHistoryContinueWinTimes },
    { "resetChampionArena", resetChampionArena },
    { "addGradingNum", addGradingNum },
    { "setLastChestTime", setLastChestTime },
    { "setChestStatus", setChestStatus },
    { "setDayBuyChestTimes", setDayBuyChestTimes },
    { "getLastChestTime", getLastChestTime },
    { NULL, NULL }
};

int newPvpModel(lua_State *L)
{
    CPvpModel *model = new CPvpModel();
    LuaTools::pushClass(L, model, "Summoner.PvpModel");
    return 1;
}

int deletePvpModel(lua_State *L)
{
    CPvpModel* model = LuaTools::checkClass<CPvpModel>(L, -2, "Summoner.PvpModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}

bool registerPvpModel()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.PvpModel");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funcPvp, 0);

    lua_register(luaState, "newPvpModel", newPvpModel);
    lua_register(luaState, "deleteTeamModel", deletePvpModel);

    return true;
}

