#include "LuaTools.h"
#include "ModelData.h"
#include "GameModel.h"

int init(lua_State* L)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(L, -1, "Summoner.GameModel");
    CBufferData* bufferData = LuaTools::checkClass<CBufferData>(L, -1, "Summoner.BufferData");
    if (NULL != model && NULL != bufferData)
	{
        model->init(bufferData->getBuffer());
	}
	return 0;
}

int openRoom(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->openRoom(), "Summoner.RoomModel");
    }
    return 1;
}

int getRoom(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getRoom(), "Summoner.RoomModel");
    }
    return 1;
}

int closeRoom(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        model->closeRoom();
    }
    return 0;
}

int getUserModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getUserModel(), "Summoner.UserModel");
    }
    return 1;
}

int getBagModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getBagModel(), "Summoner.BagModel");
    }
    return 1;
}

int getEquipModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getEquipModel(), "Summoner.EquipModel");
    }
    return 1;
}

int getHeroCardBagModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getHeroCardBagModel(), "Summoner.HeroCardBagModel");
    }
    return 1;
}

int getSummonersModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getSummonersModel(), "Summoner.SummonersModel");
    }
    return 1;
}

int getStageModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getStageModel(), "Summoner.StageModel");
    }
    return 1;
}

int getTeamModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getTeamModel(), "Summoner.TeamModel");
    }
    return 1;
}

int getTaskModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getTaskModel(), "Summoner.TaskModel");
	}
	return 1;
}

int getAchieveModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getAchieveModel(), "Summoner.AchieveModel");
	}
	return 1;
}

int getGuideModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getGuideModel(), "Summoner.GuideModel");
	}
	return 1;
}

int getUnionModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getUnionModel(), "Summoner.UnionModel");
	}
	return 1;
}

int getActivityInstanceModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getActivityInstanceModel(), "Summoner.ActivityInstanceModel");
	}
	return 1;
}

int getGoldTestModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getGoldTestModel(), "Summoner.GoldTestModel");
	}
	return 1;
}

int getHeroTestModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getHeroTestModel(), "Summoner.HeroTestModel");
	}
	return 1;
}

int getTowerTestModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getTowerTestModel(), "Summoner.TowerTestModel");
	}
	return 1;
}

int getMailModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getMailModel(), "Summoner.MailModel");
	}
	return 1;
}

int getPersonalTaskModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getPersonalTaskModel(), "Summoner.PersonalTaskModel");
	}
	return 1;
}

int getTeamTaskModel(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		LuaTools::pushClass(l, model->getTeamTaskModel(), "Summoner.TeamTaskModel");
	}
	return 1;
}

int getPvpModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getPvpModel(), "Summoner.PvpModel");
    }
    return 1;
}

int getShopModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getShopModel(), "Summoner.ShopModel");
    }
    return 1;
}

int getOperateActiveModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getOperateActiveModel(), "Summoner.OperateActiveModel");
    }
    return 1;
}

int getHeadModel(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        LuaTools::pushClass(l, model->getHeadModel(), "Summoner.HeadModel");
    }
    return 1;
}

int getNow(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getNow());
    }
    return 1;
}

int getLoginServerTime(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getLoginServerTime());
    }
    return 1;
}

int getLoginClientTime(lua_State* l)
{
    CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
    if (NULL != model)
    {
        lua_pushinteger(l, model->getLoginClientTime());
    }
    return 1;
}

int isFreePickCard(lua_State* l)
{
	CGameModel* model = LuaTools::checkClass<CGameModel>(l, -1, "Summoner.GameModel");
	if (NULL != model)
	{
		lua_pushboolean(l, model->isFreePickCard());
	}
	return 1;
}

int getGameModel(lua_State* l)
{
    LuaTools::pushClass(l, CGameModel::getInstance(), "Summoner.GameModel");
    /*void** p = new void*();
    *p = CGameModel::getInstance();
    lua_pushlightuserdata(l, p);
    luaL_getmetatable(l, "Summoner.GameModel");
    lua_setmetatable(l, -2);*/
    return 1;
}

static const struct luaL_reg funGame[] =
{
    { "init", init },
    { "openRoom", openRoom },
    { "getRoom", getRoom },
    { "closeRoom", closeRoom },
    { "getUserModel", getUserModel },
    { "getBagModel", getBagModel },
    { "getEquipModel", getEquipModel },
    { "getHeroCardBagModel", getHeroCardBagModel },
	{ "getSummonersModel", getSummonersModel },
    { "getStageModel", getStageModel },
	{ "getTeamModel", getTeamModel },
	{ "getTaskModel", getTaskModel },
	{ "getAchieveModel", getAchieveModel },
	{ "getGuideModel", getGuideModel },
	{ "getUnionModel", getUnionModel },
	{ "getActivityInstanceModel", getActivityInstanceModel },
	{ "getGoldTestModel", getGoldTestModel },
	{ "getHeroTestModel", getHeroTestModel },
	{ "getTowerTestModel", getTowerTestModel },
	{ "getMailModel", getMailModel },
	{ "getPersonalTaskModel", getPersonalTaskModel },
	{ "getTeamTaskModel", getTeamTaskModel },
    { "getPvpModel", getPvpModel },
    { "getShopModel", getShopModel },
    { "getOperateActiveModel", getOperateActiveModel },
    { "getHeadModel", getHeadModel },
    { "getNow", getNow },
    { "getLoginServerTime", getLoginServerTime },
    { "getLoginClientTime", getLoginClientTime },
	{ "isFreePickCard", isFreePickCard },
	{ NULL, NULL }
};

bool regiestGameModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.GameModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funGame, 0);

    lua_register(luaState, "getGameModel", getGameModel);

	return true;
}