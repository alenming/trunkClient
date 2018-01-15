#include "LuaFMODAudioEngine.h"
#include "LuaTools.h"
#include "FMODAudioEngine.h"

int playMusic(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    const char *path = luaL_checkstring(l, -1);
    fmod->playBackgroundMusic(path);

    return 0;
}

int playEffect(lua_State* l)
{
    int argc = lua_gettop(l) - 1;

    if (1 == argc)
    {
        CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
        const char *path = luaL_checkstring(l, -1);
        lua_pushinteger(l, fmod->playEffect(path));
        return 1;
    }
    else if (2 == argc)
    {
        CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -3, "Summoner.FMODAudioEngine");
        const char *path = luaL_checkstring(l, -2);
        float volume = luaL_checknumber(l, -1);
        lua_pushinteger(l, fmod->playEffect(path, volume));
        return 1;
    }
    else
    {
#if COCOS2D_DEBUG >= 1
        tolua_error(l, "playEffect param is error", nullptr);
        return 0;
#endif
    }

    return 0;
}

int setMusicParam(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -3, "Summoner.FMODAudioEngine");
    const char *param = luaL_checkstring(l, -2);
    float vaule = luaL_checknumber(l, -1);
    fmod->setBackgroundMusicParam(param, vaule);

    return 0;
}

int setPaused(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    bool pause = lua_toboolean(l, -1) == 1;
    fmod->setPaused(pause);

    return 0;
}

int setMusicVolume(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    float volume = luaL_checknumber(l, -1);
    fmod->setMusicVolume(volume);

    return 0;
}

int getMusicVolume(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -1, "Summoner.FMODAudioEngine");
    float volume = fmod->getMusicVolume();
    lua_pushinteger(l, volume);

    return 1;
}

int stopBackgroundMusic(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -1, "Summoner.FMODAudioEngine");
    fmod->stopBackgroundMusic();

    return 0;
}

int setOpenEffect(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    bool isOpen = lua_toboolean(l, -1) == 1;
    fmod->setOpenEffect(isOpen);

    return 0;
}

int stopEffect(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    int effectId = lua_tointeger(l, -1);
    fmod->stopEffect(effectId);

    return 0;
}

int loadBank(lua_State* l)
{
    CFMODAudioEngine* fmod = LuaTools::checkClass<CFMODAudioEngine>(l, -2, "Summoner.FMODAudioEngine");
    const char *bankFile = luaL_checkstring(l, -1);
    
    lua_pushboolean(l, fmod->loadBankFile(bankFile));

    return 1;
}

static const struct luaL_reg funcFMOD[] =
{
    { "playMusic", playMusic },
    { "playEffect", playEffect },
    { "setMusicParam", setMusicParam },
    { "setPaused", setPaused },
    { "setMusicVolume", setMusicVolume },
    { "getMusicVolume", getMusicVolume },
    { "stopBackgroundMusic", stopBackgroundMusic },
    { "setOpenEffect", setOpenEffect },
    { "stopEffect", stopEffect },
    { "loadBank", loadBank },
    { NULL, NULL }
};

int getFMODAudioEngine(lua_State* l)
{
    LuaTools::pushClass(l, CFMODAudioEngine::getInstance(), "Summoner.FMODAudioEngine");
    return 1;
}

bool registeFMODAudioEngine()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.FMODAudioEngine");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funcFMOD, 0);

    lua_register(luaState, "getFMODAudioEngine", getFMODAudioEngine);

    return true;
}

