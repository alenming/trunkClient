#include "LuaTools.h"
#include "Shake.h"

int doShake(lua_State* l)
{
	float strength = luaL_checknumber(l, -1);
    float time = luaL_checknumber(l, -2);
    Node* node = reinterpret_cast<Node*>(tolua_tousertype(l, -3, nullptr));
	if (NULL != node)
	{
		auto shake = CShake::create(time, strength);
		node->runAction(shake);
	}
	return 0;
}

/*static const struct luaL_reg funGame[] =
{
	{ NULL, NULL }
};*/

bool regiestShake()
{
	/*auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();
	luaL_newmetatable(luaState, "Summoner.Shake");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funGame, 0);
   	lua_register(luaState, "doShake", doShake);*/
    auto luaState = cocos2d::LuaEngine::getInstance()->getLuaStack()->getLuaState();
    lua_register(luaState, "doShake", doShake);
	return true;
}