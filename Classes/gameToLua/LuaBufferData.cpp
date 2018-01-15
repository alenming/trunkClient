#include "LuaBufferData.h"
#include "LuaTools.h"
#include "ConfManager.h"
#include "ConfOther.h"
#include "BufferData.h"

int newBufferData(lua_State* l)
{
    CBufferData* buffer = new CBufferData();
    buffer->init(256);
	LuaTools::pushClass(l, buffer, "Summoner.BufferData");
    return 1;
}

int deleteBufferData(lua_State* l)
{
    // 之所以不用luaL_checkudata(l, -2, "Summoner.BufferData")
    // 是因为lightuserdata并不支持(应该是这个版本lua的bug)
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer)
    {
        delete buffer;
    }
    return 0;
}

int writeIntToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    int data = luaL_checkint(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeCharToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    char data = lua_tointeger(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeUCharFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    unsigned char data = lua_tointeger(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeShortFromBufferData(lua_State* l)
{
	CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
	short data = lua_tointeger(l, -1);
	if (NULL != buffer)
	{
		buffer->writeData(data);
	}
	return 0;
}

int writeUShortFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    unsigned short data = lua_tointeger(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeFloatToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    float data = luaL_checknumber(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeBoolToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    bool data = lua_toboolean(l, -1) == 1;
    if (NULL != buffer)
    {
        buffer->writeData(data);
    }
    return 0;
}

int writeStringToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    const char* data = luaL_checkstring(l, -1);
    if (NULL != buffer)
    {
        buffer->writeData(data, strlen(data) + 1);
    }
    return 0;
}

int writeBufferToBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    size_t len;
    const char* data = luaL_checklstring(l, 1, &len);
    if (NULL != buffer)
    {
        buffer->writeData(data, len);
    }
    return 0;
}

int readIntFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    int data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushinteger(l, data);
        return 1;
    }
    return 0;
}

int readCharFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    char data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushinteger(l, data);
        return 1;
    }
    return 0;
}

int readUCharFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    unsigned char data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushinteger(l, data);
        return 1;
    }
    return 0;
}

int readShortFromBufferData(lua_State* l)
{
	CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
	short data;
	if (NULL != buffer && buffer->readData(data))
	{
		lua_pushinteger(l, data);
		return 1;
	}
	return 0;
}

int readUShortFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    unsigned short data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushinteger(l, data);
        return 1;
    }
    return 0;
}

int readFloatFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    float data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushnumber(l, data);
        return 1;
    }
    return 0;
}

int readBoolFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    bool data;
    if (NULL != buffer && buffer->readData(data))
    {
        lua_pushboolean(l, data);
        return 1;
    }
    return 0;
}

int readStringFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer && buffer->getDataLength() > buffer->getOffset())
    {
        // 将当期内容视为字符串
        char* data = buffer->getBuffer() + buffer->getOffset();
        unsigned int len = strlen(data) + 1;
        if (len > 0 && len <= buffer->getDataLength() - buffer->getOffset())
        {
            buffer->updateOffset(buffer->getOffset() + len);
            lua_pushstring(l, data);
            return 1;
        }
    }
    return 0;
}

int readCharArrayFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    unsigned int len = luaL_checkint(l, -1);
    if (NULL != buffer && buffer->getDataLength() > buffer->getOffset())
    {
        char* data = buffer->getBuffer() + buffer->getOffset();
        if (len > 0 && len <= buffer->getDataLength() - buffer->getOffset())
        {
            buffer->updateOffset(buffer->getOffset() + len);
            lua_pushstring(l, data);
            return 1;
        }
    }
    return 0;
}

int readBufferFromBufferData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    unsigned int bufferLen = luaL_checkint(l, -1);
    if (buffer != NULL && bufferLen < buffer->getDataLength() - buffer->getOffset())
    {
        char* data = new char[bufferLen];
        buffer->readData(data, bufferLen);
        lua_pushlstring(l, data, bufferLen);
        delete data;
        return 1;
    }
    return 0;
}

int resetOffsetBufferData(lua_State* l)
{
	CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
	if (NULL != buffer)
	{
		buffer->resetOffset();
	}
	return 0;
}

int writeCharArray(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -3, "Summoner.BufferData");
    std::string str = luaL_checkstring(l, -2);
    unsigned int strLength = luaL_checkint(l, -1);
    if (NULL != buffer)
    {
        if (str.length() <= strLength)
        {
            buffer->writeData(str.c_str(), str.length());
			strLength -= str.length();
			for (unsigned int i = 0; i < strLength; ++i)
			{
				buffer->writeData<char>('\0');
			}
        }
        else
        {
            buffer->writeData(str.c_str(), strLength);
        }
    }
    return 0;
}

// BufferData的Lua方法
static const struct luaL_reg bufferData_m[] = 
{
    { "readInt", readIntFromBufferData },
    { "writeInt", writeIntToBufferData },
    { "readBool", readBoolFromBufferData },
    { "writeBool", writeBoolToBufferData },
    { "readFloat", readFloatFromBufferData },
    { "writeFloat", writeFloatToBufferData },
    { "readChar", readCharFromBufferData },
    { "readUChar", readUCharFromBufferData },
	{ "readShort", readShortFromBufferData },
    { "readUShort", readUShortFromBufferData },
    { "writeChar", writeCharToBufferData },
    { "writeUChar", writeUCharFromBufferData },
	{ "writeShort", writeShortFromBufferData },
    { "writeUShort", writeUShortFromBufferData },
    { "readBuffer", readBufferFromBufferData },
    { "writeBuffer", writeBufferToBufferData },
    { "readString", readStringFromBufferData },
    { "readCharArray", readCharArrayFromBufferData },
	{ "writeString", writeStringToBufferData },
	{ "resetOffset", resetOffsetBufferData },
    { "writeCharArray", writeCharArray },
    { NULL, NULL }
};

bool regiestBufferData()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    // 注册BufferData的Lua类
    luaL_newmetatable(luaState, "Summoner.BufferData");
    lua_pushstring(luaState, "__index");
    // pushes the metatable
    lua_pushvalue(luaState, -2);
    // metatable.__index = metatable 
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, bufferData_m, 0);

    lua_register(luaState, "newBufferData", newBufferData);
    lua_register(luaState, "deleteBufferData", deleteBufferData);
    return true;
}