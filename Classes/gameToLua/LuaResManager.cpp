#include "LuaTools.h"
#include "ResManager.h"
#include "LuaBasicConversions.h"
//#include "tolua_fix.h"
#include "LuaSummonerBase.h"

int addPreloadRes(lua_State* L)
{
	int num = lua_gettop(L);
	LUA_FUNCTION handler = (toluafix_ref_function(L, num, 0));
    std::function<void(const std::string&, bool)> func = nullptr;
	if (0 != handler)
	{
        func = [handler](const std::string& resName, bool success)
        {
            LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
            stack->pushString(resName.c_str());
            stack->pushBoolean(success);
            stack->executeFunctionByHandler(handler, 2);
            stack->clean();
        };
	}

	if (num == 3)
	{
		std::string res = luaL_checkstring(L, 2);
		bool ret = CResManager::getInstance()->addPreloadRes(res, func);
		lua_pushboolean(L, ret);
	}
	else if (num == 4)
	{
		std::string res = luaL_checkstring(L, 3);
		std::string res2 = luaL_checkstring(L, 2);
		bool ret = CResManager::getInstance()->addPreloadRes(res2, res, func);
		lua_pushboolean(L, ret);
	}
	return 1;
}

int addPreloadArmature(lua_State* L)
{
	LUA_FUNCTION handler = (toluafix_ref_function(L, 3, 0));
    std::function<void(const std::string&, bool)> func = nullptr;
    if (0 != handler)
    {
        func = [handler](const std::string& resName, bool success)
        {
            LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
            stack->pushString(resName.c_str());
            stack->pushBoolean(success);
            stack->executeFunctionByHandler(handler, 2);
            stack->clean();
        };
    }

	std::string res = luaL_checkstring(L, 2);
	bool ret = CResManager::getInstance()->addPreloadArmature(res, func);
	lua_pushboolean(L, ret);
	return 1;
}

int startResAsyn(lua_State* L)
{
	bool ret = CResManager::getInstance()->startResAsyn();
	lua_pushboolean(L, ret);
	return 1;
}

int setFinishCallback(lua_State* L)
{
	LUA_FUNCTION handler = (toluafix_ref_function(L, 2, 0));
    std::function<void(int, int)> func = nullptr;
    if (handler != 0)
    {
        func = [handler](int param1, int param2)
        {
            LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
            stack->pushInt(param1);
            stack->pushInt(param2);
            stack->executeFunctionByHandler(handler, 2);
            stack->clean();
        };
    }

	CResManager::getInstance()->setFinishCallback(func);
	return 0;
}

int createSpine(lua_State* L)
{
	std::string res = luaL_checkstring(L, -1);
	auto node = CResManager::getInstance()->createSpine(res);
	if (!node) return 0;
	object_to_luaval<spine::SkeletonAnimation>(L, "sp.SkeletonAnimation", (spine::SkeletonAnimation*)node);
	return 1;
}

int getCsbNode(lua_State* L)
{
    bool debug = false;
    if (debug)
    {
        debugLuaStack();
    }

	std::string res = luaL_checkstring(L, -1);
	auto node = CResManager::getInstance()->getCsbNode(res);
	if (!node) return 0;
	object_to_luaval<Node>(L, "cc.Node", (Node*)node);
	return 1;
}

int cloneCsbNode(lua_State* L)
{
	std::string res = luaL_checkstring(L, -1);
	auto node = CResManager::getInstance()->cloneCsbNode(res);
	if (!node) return 0;
	object_to_luaval<Node>(L, "cc.Node", (Node*)node);
	return 1;
}

int removeRes(lua_State* L)
{
	std::string res = luaL_checkstring(L, -1);
	bool ret = CResManager::getInstance()->removeRes(res);
	lua_pushboolean(L, ret);
	return 1;
}

int removeArmature(lua_State* L)
{
	std::string res = luaL_checkstring(L, -1);
	bool ret = CResManager::getInstance()->removeArmature(res);
	lua_pushboolean(L, ret);
	return 1;
}

int cacheResInt(lua_State* L)
{
	int type = luaL_checkint(L, -1);
	CResManager::getInstance()->cacheRes(type);
	return 0;
}

int cacheResStr(lua_State* L)
{
	std::string res = luaL_checkstring(L, -1);
	CResManager::getInstance()->cacheRes(res);
	return 0;
}

int clearRes(lua_State* L)
{
	CResManager::getInstance()->clearRes();
	return 0;
}

int hasRes(lua_State* L)
{
    std::string resName = luaL_checkstring(L, -1);
    bool ret = CResManager::getInstance()->hasRes(resName);
    lua_pushboolean(L, ret);
    return 1;
}

int hasArmature(lua_State* L)
{
    std::string resName = luaL_checkstring(L, -1);
    bool ret = CResManager::getInstance()->hasArmature(resName);
    lua_pushboolean(L, ret);
    return 1;
}

static const struct luaL_reg funResManager[] =
{
	{ "addPreloadRes", addPreloadRes },
	{ "addPreloadArmature", addPreloadArmature },
	{ "startResAsyn", startResAsyn },
	{ "setFinishCallback", setFinishCallback },
	{ "createSpine", createSpine },
	{ "getCsbNode", getCsbNode },
	{ "cloneCsbNode", cloneCsbNode },
	{ "removeRes", removeRes },
	{ "removeArmature", removeArmature },
	{ "cacheResInt", cacheResInt },
	{ "cacheResStr", cacheResStr },
    { "clearRes", clearRes },
    { "hasRes", hasRes },
    { "hasArmature", hasArmature },
	{ NULL, NULL }
};

int getResManager(lua_State* L)
{
	LuaTools::pushClass(L, CResManager::getInstance(), "Summoner.ResManager");
	return 1;
}

bool registerResManager()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.ResManager");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funResManager, 0);

	lua_register(luaState, "getResManager", getResManager);

	return true;
}