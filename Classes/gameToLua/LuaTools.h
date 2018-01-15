#ifndef _SUM_LUA_TOOLS_
#define _SUM_LUA_TOOLS_

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "base/CCScriptSupport.h"

namespace LuaTools
{
    template<typename T>
    void pushMapKeys(std::map<int, T>& m)
    {
        auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
        auto luaState = luaStack->getLuaState();
        lua_newtable(luaState);
        // table 的下标需从1开始
        int index = 1;
        for (auto& item : m)
        {
            lua_pushinteger(luaState, item.first);
			lua_rawseti(luaState, -2, index++);
        }
    }

    template<typename T>
    T* checkClass(lua_State* l, int index, const char* name)
    {
        T **p = reinterpret_cast<T**>(lua_touserdata(l, index));
        if (p != NULL)
        {
            if (lua_getmetatable(l, index))
            {
                luaL_getmetatable(l, name);
                if (!lua_rawequal(l, -1, -2))
                    *p = NULL;
                lua_pop(l, 2);
            }
		}
		else
		{
			return NULL;
		}
        return *p;
    }

    // push一个类对象
    void pushClass(lua_State* l, void* p, const char* className);

	void pushMapIntInt(std::map<int, int>& m);
	void pushMapIntIntToTableField(const std::map<int, int>& m, lua_State* luaState, const char* tableName);
	void pushMapIntStrToTableField(const std::map<int, std::string>& m, lua_State* luaState, const char* tableName);

	//把vector<int>容器放入lua栈中
	void pushVecFloatToArray(const std::vector<float>& v, lua_State* luaState);
	//把vector<int>容器放入lua栈中
	void pushVecIntToArray(const std::vector<int>& v, lua_State* luaState);
    void pushVecStringToArray(const std::vector<std::string>& v, lua_State* luaState);

	//把vector<int>容器放入lua栈中, 并设置table名
	void pushVecIntToTableField(const std::vector<int>& v, lua_State* luaState, const char* tableName);
	void pushVecFloatToTableField(const std::vector<float>& v, lua_State* luaState, const char* tableName);
    void pushVecStringToTableField(const std::vector<std::string>& v, lua_State* luaState, const char* tableName);

	void pushSetIntToArray(const std::set<int>& v, lua_State* luaState);
	void pushSetIntToTableField(const std::set<int>& v, lua_State* luaState, const char* tableName);

	//把rgb放入lua栈中
	void pushRGBToTableField(const cocos2d::Color3B& color, lua_State* luaState, const char* tableName);

	//把坐标放入lua栈中
	void pushVec2ToTableField(const cocos2d::Vec2& pos, lua_State* luaState, const char* tableName);
    
    //从lua talbe中取出key的值
    void getStructBoolValueByKey(lua_State* luaState, const char* key, bool& value);
    void getStructIntValueByKey(lua_State* luaState, const char* key, int& value);
    void getStructStringValueByKey(lua_State* luaState, const char* key, char* value, int len);
    void getStructStringValueByKey(lua_State* luaState, const char* key, std::string& value);

	///////////////////////////将基础数据(整形, 浮点, 字符串)存入lua栈中///////////////////////////////////////////////
	void pushBaseKeyValue(lua_State* luaState, const int& value, const char* key);
	void pushBaseKeyValue(lua_State* luaState, const float& value, const char* key);
	void pushBaseKeyValue(lua_State* luaState, const double& value, const char* key);
	void pushBaseKeyValue(lua_State* luaState, const bool& value, const char* key);
	void pushBaseKeyValue(lua_State* luaState, const char* value, const char* key);
	void pushBaseKeyValue(lua_State* luaState, const std::string& value, const char* key);
}

#endif
