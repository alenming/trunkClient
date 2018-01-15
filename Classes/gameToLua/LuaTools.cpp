#include "LuaTools.h"

void LuaTools::pushClass(lua_State* l, void* p, const char* className)
{
    if (p == NULL)
    {
        lua_pushnil(l);
    }
    else
    {
        void** up = reinterpret_cast<void**>(lua_newuserdata(l, sizeof(p)));
        *up = p;
        luaL_getmetatable(l, className);
        lua_setmetatable(l, -2);
    }

    /*LOG("---------------------------");
    LOG("%d", lua_gettop(l));
    lua_pushlightuserdata(l, p);
    LOG("%d", lua_gettop(l));
    luaL_getmetatable(l, className);
    LOG("%d", lua_gettop(l));
    lua_setmetatable(l, -2);
    LOG("%d", lua_gettop(l));
    LOG("---------------------------");*/
}

void LuaTools::pushMapIntInt(std::map<int, int>& m)
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();
	lua_newtable(luaState);
	// table 的下标需从1开始
	for (auto& item : m)
	{
		lua_pushinteger(luaState, item.second);
		lua_rawseti(luaState, -2, item.first);
	}
}

void LuaTools::pushMapIntIntToTableField(const std::map<int, int>& m, lua_State* luaState, const char* tableName)
{
	lua_newtable(luaState);
	for (auto& item : m)
	{
		lua_pushinteger(luaState, item.second);
		lua_rawseti(luaState, -2, item.first);
	}
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushMapIntStrToTableField(const std::map<int, std::string>& m, lua_State* luaState, const char* tableName)
{
	lua_newtable(luaState);
	for (auto& item : m)
	{
		lua_pushstring(luaState, item.second.c_str());
		lua_rawseti(luaState, -2, item.first);
	}
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushVecFloatToArray(const std::vector<float>& v, lua_State* luaState)
{
	lua_newtable(luaState);
	for (unsigned int i = 0; i < v.size(); ++i)
	{
		lua_pushnumber(luaState, v[i]);
		lua_rawseti(luaState, -2, i + 1);
	}
}

void LuaTools::pushVecIntToArray(const std::vector<int>& v, lua_State* luaState)
{
	lua_newtable(luaState);
	for (unsigned int i = 0; i < v.size(); ++i)
	{
		lua_pushinteger(luaState, v[i]);
		lua_rawseti(luaState, -2, i + 1);
	}
}

void LuaTools::pushVecStringToArray(const std::vector<std::string>& v, lua_State* luaState)
{
    lua_newtable(luaState);
    for (unsigned int i = 0; i < v.size(); ++i)
    {
        lua_pushstring(luaState, v[i].c_str());
        lua_rawseti(luaState, -2, i + 1);
    }
}

void LuaTools::pushVecIntToTableField(const std::vector<int>& v, lua_State* luaState, const char* tableName)
{
	pushVecIntToArray(v, luaState);
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushVecFloatToTableField(const std::vector<float>& v, lua_State* luaState, const char* tableName)
{
	pushVecFloatToArray(v, luaState);
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushVecStringToTableField(const std::vector<std::string>& v, lua_State* luaState, const char* tableName)
{
    pushVecStringToArray(v, luaState);
    lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushSetIntToArray(const std::set<int>& v, lua_State* luaState)
{
	lua_newtable(luaState);
	int i = 0;
	for (auto s : v)
	{
		lua_pushinteger(luaState, s);
		lua_rawseti(luaState, -2, ++i);
	}
}

void LuaTools::pushSetIntToTableField(const std::set<int>& v, lua_State* luaState, const char* tableName)
{
	pushSetIntToArray(v, luaState);
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushRGBToTableField(const cocos2d::Color3B& color, lua_State* luaState, const char* tableName)
{
	lua_newtable(luaState);
	lua_pushinteger(luaState, color.r);
	lua_setfield(luaState, -2, "r");
	lua_pushinteger(luaState, color.g);
	lua_setfield(luaState, -2, "g");
	lua_pushinteger(luaState, color.b);
	lua_setfield(luaState, -2, "b");
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::pushVec2ToTableField(const cocos2d::Vec2& pos, lua_State* luaState, const char* tableName)
{
	lua_newtable(luaState);
	lua_pushnumber(luaState, pos.x);
	lua_setfield(luaState, -2, "x");
	lua_pushnumber(luaState, pos.y);
	lua_setfield(luaState, -2, "y");
	lua_setfield(luaState, -2, tableName);
}

void LuaTools::getStructBoolValueByKey(lua_State* luaState, const char* key, bool& value)
{
    // 需保证栈顶为table
    lua_getfield(luaState, -1, key);
    value = lua_toboolean(luaState, -1);
    lua_pop(luaState, 1);
}

void LuaTools::getStructIntValueByKey(lua_State* luaState, const char* key, int& value)
{
    // 需保证栈顶为table
    lua_getfield(luaState, -1, key);
    value = lua_tointeger(luaState, -1);
    lua_pop(luaState, 1);
}

void LuaTools::getStructStringValueByKey(lua_State* luaState, const char* key, char* value, int len)
{
    lua_getfield(luaState, -1, key);
    const char *v = lua_tostring(luaState, -1);
    memcpy(value, v, len);
    lua_pop(luaState, 1);
}

void LuaTools::getStructStringValueByKey(lua_State* luaState, const char* key, std::string& value)
{
    lua_getfield(luaState, -1, key);
    const char *p = lua_tostring(luaState, -1);
    value = p == NULL ? "" : p;
    lua_pop(luaState, 1);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const int& value, const char* key)
{
	lua_pushinteger(luaState, value);
	lua_setfield(luaState, -2, key);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const float& value, const char* key)
{
	lua_pushnumber(luaState, value);
	lua_setfield(luaState, -2, key);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const double& value, const char* key)
{
	lua_pushnumber(luaState, value);
	lua_setfield(luaState, -2, key);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const bool& value, const char* key)
{
	lua_pushboolean(luaState, value);
	lua_setfield(luaState, -2, key);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const char* value, const char* key)
{
	lua_pushstring(luaState, value);
	lua_setfield(luaState, -2, key);
}

void LuaTools::pushBaseKeyValue(lua_State* luaState, const std::string& value, const char* key)
{
	lua_pushstring(luaState, value.c_str());
	lua_setfield(luaState, -2, key);
}

