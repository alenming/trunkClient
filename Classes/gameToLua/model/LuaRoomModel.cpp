#include "LuaTools.h"
#include "ModelData.h"
#include "BattleModels.h"

int initByRoomData(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -2, "Summoner.RoomModel");
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != model && NULL != buffer)
	{
        auto room = reinterpret_cast<RoomData*>(buffer->getBuffer() + buffer->getOffset());
        model->initByRoomData(room);
	}
	return 0;
}

int getPlayers(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -1, "Summoner.RoomModel");
    if (NULL != model)
    {
        auto& players = model->getPlayers();
        lua_newtable(l);
        for (auto& item : players)
        {
            LuaTools::pushClass(l, item.second, "Summoner.BattlePlayerModel");
            lua_rawseti(l, -2, item.first);
        }
        return 1;
    }
    return 0;
}

int getPlayer(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -2, "Summoner.RoomModel");
    int playerId = luaL_checkint(l, -1);
    if (NULL != model)
    {
        auto player = model->getPlayer(playerId);
        if (NULL != player)
        {
            LuaTools::pushClass(l, player, "Summoner.BattlePlayerModel");
            return 1;
        }
    }
    return 0;
}

int getMaster(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -1, "Summoner.RoomModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getMaster());
    }
    return 1;
}

int getSettleAccount(lua_State* l)
{
	CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -1, "Summoner.RoomModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getSettleAccountModel(), "Summoner.SettleAccountModel");
		return 1;
	}
	return 0;
}

int getStageId(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -1, "Summoner.RoomModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getStageId());
    }
    return 1;
}

int getBattleType(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -1, "Summoner.RoomModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getBattleType());
    }
    return 1;
}

int setRobotName(lua_State* l)
{
    CRoomModel* model = LuaTools::checkClass<CRoomModel>(l, -2, "Summoner.RoomModel");
    std::string robotName = luaL_checkstring(l, -1);
    if (model != NULL)
    {
        auto &players = model->getPlayers();
        for (auto &player : players)
        {
            if (EDefaultNpc == player.second->getUserId())
            {
                player.second->setUserName(robotName);
                lua_pushboolean(l, 1);
                return 1;
            }
        }
    }

    lua_pushboolean(l, 0);
    return 1;
}

static const struct luaL_reg funRoom[] =
{
    { "init", initByRoomData },
    { "getPlayers", getPlayers },
    { "getPlayer", getPlayer },
    { "getMaster", getMaster },
	{ "getSettleAccount", getSettleAccount },
    { "getStageId", getStageId },
    { "getBattleType", getBattleType },
    { "setRobotName", setRobotName },
	{ NULL, NULL }
};

bool registerRoomModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.RoomModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funRoom, 0);
	return true;
}

int getSoldiers(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        CPlayerModel *pPlayerModel = dynamic_cast<CPlayerModel*>(model);
        if (pPlayerModel)
        {
            auto soldiers = pPlayerModel->getSoldierCards();
            // 压入多个士兵的信息...
            lua_newtable(l);
            int index = 1;
            for (auto soldier : soldiers)
            {
                lua_pushinteger(l, soldier->getSoldId());
                lua_rawseti(l, -2, index++);
            }

            return 1;
        }
    }
    return 0;
}

int getSoldierInfo(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -2, "Summoner.BattlePlayerModel");
    int playerId = luaL_checkint(l, -1);
    if (NULL != model)
    {
        CPlayerModel *pPlayerModel = dynamic_cast<CPlayerModel*>(model);
        if (pPlayerModel)
        {
            CSoldierModel* soldier = pPlayerModel->getSoldierCard(playerId);
            if (NULL != soldier)
            {
                lua_newtable(l);
                LuaTools::pushBaseKeyValue(l, soldier->getStar(), "Star");
                LuaTools::pushBaseKeyValue(l, soldier->getSoldId(), "Id");
                return 1;
            }
        }
    }
    return 0;
}

int getUserId(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getUserId());
        return 1;
    }
    return 0;
}

int getUserLv(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getUserLv());
        return 1;
    }
    return 0;
}

int getCamp(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getCamp());
        return 1;
    }
    return 0;
}

int getPlayerName(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushstring(l, model->getUserName().c_str());
        return 1;
    }
    return 0;
}

int getHeroId(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getMainRoleId());
        return 1;
    }
    return 0;
}

int getHeroLv(lua_State* l)
{
    CBattlePlayerModel* model = LuaTools::checkClass<CBattlePlayerModel>(l, -1, "Summoner.BattlePlayerModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getMainRoleLv());
        return 1;
    }
    return 0;
}

static const struct luaL_reg funPlayer[] =
{
    { "getSoldiers", getSoldiers },
    { "getSoldierInfo", getSoldierInfo },
    { "getUserId", getUserId },
    { "getUserLv", getUserLv },
    { "getCamp", getCamp },
    { "getUserName", getPlayerName },
    { "getHeroId", getHeroId },
    { "getHeroLv", getHeroLv },
    { NULL, NULL }
};

bool registerPlayerModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();
	luaL_newmetatable(luaState, "Summoner.BattlePlayerModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funPlayer, 0);
	return true;
}

int setChallengeResult(lua_State *L)
{
	int result = luaL_checkint(L, -1);
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
        model->setChallengeResult(result);
	}
	return 0;
}

int getChallengeResult(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
        lua_pushinteger(L, model->getChallengeResult());
		return 1;
	}
	return 0;
}

int settleSetTick(lua_State *L)
{
	int tick = luaL_checkint(L, -1);
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		model->setTick(tick);
	}
	return 0;
}

int settleGetTick(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		lua_pushinteger(L, model->getTick());
		return 1;
	}
	return 0;
}

int settleSetHPPercent(lua_State *L)
{
	int heroPercent = luaL_checkint(L, -1);
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		model->setHPPercent(heroPercent);
	}
	return 0;
}

int settleGetHPPercent(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		lua_pushinteger(L, model->getHPPercent());
		return 1;
	}
	return 0;
}

int settleAddHitBossHP(lua_State *L)
{
	int hitBossHP = luaL_checkint(L, -1);
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		model->addHitBossHP(hitBossHP);
	}
	return 0;
}

int settleGetHitBossHP(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		lua_pushinteger(L, model->getHitBossHP());
		return 1;
	}
	return 0;
}

int settleAddCostCrystal(lua_State *L)
{
	int costCrystal = luaL_checkint(L, -1);
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		model->addCostCrystal(costCrystal);
	}
	return 0;
}

int settleGetCostCrystal(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		lua_pushinteger(L, model->getCostCrystal());
		return 1;
	}
	return 0;
}

int settleGetCrystal(lua_State *L)
{
    CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
    if (NULL != model)
    {
        lua_pushinteger(L, model->getCrystal());
        return 1;
    }
    return 0;
}

int settleGetCrystalLv(lua_State *L)
{
	CSettleAccountModel* model = LuaTools::checkClass<CSettleAccountModel>(L, -1, "Summoner.SettleAccountModel");
	if (NULL != model)
	{
		lua_pushinteger(L, model->getCrystalLv());
		return 1;
	}
	return 0;
}

static const struct luaL_reg funcSettleAccount[] =
{
    { "setChallengeResult", setChallengeResult },
    { "getChallengeResult", getChallengeResult },
	{ "setTick", settleSetTick },
	{ "getTick", settleGetTick },
	{ "setHPPercent", settleSetHPPercent },
	{ "getHPPercent", settleGetHPPercent },
	{ "addHitBossHP", settleAddHitBossHP },
	{ "getHitBossHP", settleGetHitBossHP },
	{ "addCostCrystal", settleAddCostCrystal },
    { "getCostCrystal", settleGetCostCrystal },
    { "getCrystal", settleGetCrystal },
	{ "getCrystalLv", settleGetCrystalLv},
	{ NULL, NULL }
};

bool registerSettleAccountModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.SettleAccountModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funcSettleAccount, 0);

	return true;
}
