#include "LuaTools.h"
#include "ModelData.h"

int addHeroCard(lua_State* L)
{
	CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(L, -2, "Summoner.HeroCardBagModel");
	int id = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->addHeroCard(id);
		lua_pushboolean(L, ret);
		return 1;
	}
	lua_pushboolean(L, 0);
	return 1;
}

int hasHeroCard(lua_State* L)
{
    CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(L, -2, "Summoner.HeroCardBagModel");
    int id = luaL_checkint(L, -1);
    if (NULL != model)
    {
        bool ret = model->hasHeroCard(id);
        lua_pushboolean(L, ret);
        return 1;
    }
    lua_pushboolean(L, 0);
    return 1;
}

int getHeroCard(lua_State* L)
{
	CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(L, -2, "Summoner.HeroCardBagModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto card = model->getHeroCard(data);
        if (NULL != card)
        {
            LuaTools::pushClass(L, card, "Summoner.HeroCardModel");
            return 1;
        }
	}
	return 0;
}

int getHeroCards(lua_State* L)
{
	CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(L, -1, "Summoner.HeroCardBagModel");
	if (NULL != model)
	{
		auto cards = model->getHeroCards();
		LuaTools::pushMapKeys(cards);
		return 1;
	}
	return 0;
}

int getHeroCardCount(lua_State* L)
{
    CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(L, -1, "Summoner.HeroCardBagModel");
    if (NULL != model)
    {
        auto count = model->getHeroCardCount();
        lua_pushnumber(L, count);
        return 1;
    }
    return 0;
}

int newHeroCardBagModel(lua_State* L)
{
	CHeroCardBagModel* model = new CHeroCardBagModel();
	LuaTools::pushClass(L, model, "Summoner.HeroCardBagModel");	
	return 1;
}

int deleteHeroCardBagModel(lua_State* l)
{
	CHeroCardBagModel* model = LuaTools::checkClass<CHeroCardBagModel>(l, -2, "Summoner.HeroCardBagModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funHeroCardBag[] =
{
	{ "addHeroCard", addHeroCard },
    { "hasHeroCard", hasHeroCard },
    { "getHeroCard", getHeroCard },
    { "getHeroCards", getHeroCards },
    { "getHeroCardCount", getHeroCardCount },
	{ NULL, NULL }
};

bool registeHeroCardBagModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.HeroCardBagModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);

	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funHeroCardBag, 0);

	lua_register(luaState, "newHeroCardBagModel", newHeroCardBagModel);
	lua_register(luaState, "deleteHeroCardBagModel", deleteHeroCardBagModel);

	return true;
}