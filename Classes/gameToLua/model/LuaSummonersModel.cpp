#include "LuaTools.h"
#include "ModelData.h"

int addSummoner(lua_State* L)
{
	CSummonersModel* model = LuaTools::checkClass<CSummonersModel>(L, -2, "Summoner.SummonersModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->addSummoner(data);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int hasSummoner(lua_State* L)
{
	CSummonersModel* model = LuaTools::checkClass<CSummonersModel>(L, -2, "Summoner.SummonersModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->hasSummoner(data);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getSummonerCount(lua_State* L)
{
	CSummonersModel* model = LuaTools::checkClass<CSummonersModel>(L, -1, "Summoner.SummonersModel");
	if (NULL != model)
	{
		int ret = model->getSummonerCount();
		lua_pushinteger(L, ret);
		return 1;
	}
	return 0;
}

int getSummoners(lua_State* L)
{
	CSummonersModel* model = LuaTools::checkClass<CSummonersModel>(L, -1, "Summoner.SummonersModel");
	if (NULL != model)
	{
		auto items = model->getSummoners();
		LuaTools::pushVecIntToArray(items, L);
		return 1;
	}
	return 0;
}

int newSummonersModel(lua_State* L)
{
	CSummonersModel* model = new CSummonersModel();
	LuaTools::pushClass(L, model, "Summoner.SummonersModel");
	return 1;
}

int deleteSummonersModel(lua_State* l)
{
	CSummonersModel* model = LuaTools::checkClass<CSummonersModel>(l, -2, "Summoner.SummonersModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funSummoners[] =
{
	{ "addSummoner", addSummoner },
	{ "hasSummoner", hasSummoner },
	{ "getSummonerCount", getSummonerCount },
	{ "getSummoners", getSummoners },
	{ NULL, NULL }
};

bool registeSummonersModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.SummonersModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funSummoners, 0);

	lua_register(luaState, "newSummonersModel", newSummonersModel);
	lua_register(luaState, "deleteSummonersModel", deleteSummonersModel);

	return true;
}