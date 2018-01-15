#include "LuaTools.h"
#include "ModelData.h"
#include "LuaEquipModel.h"

int getHeroTestCount(lua_State* L)
{
	CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -2, "Summoner.HeroTestModel");
	int i = luaL_checkint(L, -1);
	if (NULL != model)
	{
		int data = model->getCount(i);
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int setHeroTestCount(lua_State* L)
{
	CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -3, "Summoner.HeroTestModel");
	int v = luaL_checkint(L, -1);
	int i = luaL_checkint(L, -2);
	if (NULL != model)
	{
		model->setCount(i, v);
	}
	return 0;
}

int getHeroTestStamp(lua_State* L)
{
	CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -1, "Summoner.HeroTestModel");
	if (NULL != model)
	{
		int data = model->getStamp();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int setHeroTestStamp(lua_State* L)
{
	CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -2, "Summoner.HeroTestModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setStamp(data);
	}
	return 0;
}

int addHeroTestCount(lua_State* L)
{
    CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -3, "Summoner.HeroTestModel");
    int id = luaL_checkint(L, -2);
    int count = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addCount(id, count);
    }
    return 0;
}

int resetHeroTest(lua_State* L)
{
    CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -2, "Summoner.HeroTestModel");
    int useStamp = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->resetHeroTest(useStamp);
    }
    return 0;
}

int newHeroTestModel(lua_State *L)
{
	CHeroTestModel* model = new CHeroTestModel();
	LuaTools::pushClass(L, model, "Summoner.HeroTestModel");
	return 1;
}

int deleteHeroTestModel(lua_State *L)
{
	CHeroTestModel* model = LuaTools::checkClass<CHeroTestModel>(L, -2, "Summoner.HeroTestModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funHeroTest[] =
{
	{ "getHeroTestCount", getHeroTestCount },
	{ "getHeroTestStamp", getHeroTestStamp },
	{ "setHeroTestCount", setHeroTestCount },
	{ "setHeroTestStamp", setHeroTestStamp },
    { "addHeroTestCount", addHeroTestCount },
    { "resetHeroTest", resetHeroTest },
	{ NULL, NULL }
};

bool registerHeroTestModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.HeroTestModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funHeroTest, 0);

	lua_register(luaState, "newHeroTestModel", newHeroTestModel);
	lua_register(luaState, "deleteHeroTestModel", deleteHeroTestModel);

	return true;
}
