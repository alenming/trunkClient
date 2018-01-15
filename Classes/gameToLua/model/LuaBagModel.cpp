#include "LuaTools.h"
#include "ModelData.h"

int extra(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -2, "Summoner.BagModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->extra(data);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int addItem(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -3, "Summoner.BagModel");
	int data = luaL_checkint(L, -2);
	int data2 = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->addItem(data, data2);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int removeItem(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -2, "Summoner.BagModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->removeItem(data);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int removeItems(lua_State* L)
{
    CBagModel* model = LuaTools::checkClass<CBagModel>(L, -3, "Summoner.BagModel");
    int id = luaL_checkint(L, -2);
    int val = luaL_checkint(L, -1);
    if (NULL != model)
    {
        bool ret = model->removeItems(id, val);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}

int hasItem(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -2, "Summoner.BagModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->hasItem(data);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getItems(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -1, "Summoner.BagModel");
	if (NULL != model)
	{
		auto items = model->getItems();
		LuaTools::pushMapIntInt(items);
		return 1;
	}
	return 0;
}

int getCurCapacity(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -1, "Summoner.BagModel");
	if (NULL != model)
	{
		auto cur = model->getCurCapacity();
		lua_pushnumber(L, cur);
		return 1;
	}
	return 0;
}

int setCurCapacity(lua_State* L)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(L, -2, "Summoner.BagModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setCurCapacity(data);
	}
	return 0;
}

int getItemCount(lua_State* L)
{
    CBagModel* model = LuaTools::checkClass<CBagModel>(L, -1, "Summoner.BagModel");
    if (NULL != model)
    {
        auto count = model->getItemCount();
        lua_pushnumber(L, count);
        return 1;
    }
    return 0;
}

int newBagModel(lua_State* L)
{
	CBagModel* model = new CBagModel();

	LuaTools::pushClass(L, model, "Summoner.BagModel");
	return 1;
}

int deleteBagModel(lua_State* l)
{
	CBagModel* model = LuaTools::checkClass<CBagModel>(l, -2, "Summoner.BagModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funBag[] =
{
	{ "extra", extra },
	{ "addItem", addItem },
	{ "removeItem", removeItem },
    { "removeItems", removeItems },
	{ "hasItem", hasItem },
	{ "getItems", getItems },
    { "getItemCount", getItemCount },
	{ "getCurCapacity", getCurCapacity},
	{ "setCurCapacity", setCurCapacity },
	{ NULL, NULL }
};

bool registeBagModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.BagModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funBag, 0);

	lua_register(luaState, "newBagModel", newBagModel);
	lua_register(luaState, "deleteBagModel", deleteBagModel);

	return true;
}