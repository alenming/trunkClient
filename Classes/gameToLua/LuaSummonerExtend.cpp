#include "LuaSummonerExtend.h"
#include "LuaTools.h"
#include "LuaBasicConversions.h"
#include <spine/spine-cocos2dx.h>
#include "SimpleShader.h"

using namespace spine;

static int lua_summoner_extend_spine_existAnimation(lua_State* tolua_S)
{
    if (nullptr == tolua_S)
        return 0;

    int argc = 0;
    spine::SkeletonAnimation* cobj = nullptr;
    bool ok = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S, 1, "sp.SkeletonAnimation", 0, &tolua_err)) goto tolua_lerror;
#endif

    cobj = (spine::SkeletonAnimation*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
    if (!cobj)
    {
        tolua_error(tolua_S, "invalid 'cobj' in function 'lua_summoner_extend_spine_existAnimation'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    if (argc == 1)
    {
        const char* arg;

        std::string arg_tmp; 
        ok &= luaval_to_std_string(tolua_S, 2, &arg_tmp, "sp.SkeletonAnimation:existAnimation");
        arg = arg_tmp.c_str();

        if (!ok)
            return 0;

        spAnimationState* state = cobj->getState();
        if (state && state->data)
        {
            spSkeletonData* const data = state->data->skeletonData;
            if (data)
            {
                for (int i = 0; i < data->animationsCount; i++)
                {
                    if (0 == strcmp(data->animations[i]->name, arg))
                    {
                        lua_pushboolean(tolua_S, 1);
                        //lua_settop(tolua_S, 1);
                        return 1;
                    }
                }
            }
        }
        
        lua_pushboolean(tolua_S, 0);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "existAnimation", argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'lua_summoner_extend_spine_existAnimation'.", &tolua_err);
#endif

    return 0;
}

static int lua_summoner_extend_spine_animationState_apply(lua_State* tolua_S)
{
    if (nullptr == tolua_S)
        return 0;

    int argc = 0;
    spine::SkeletonAnimation* cobj = nullptr;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S, 1, "sp.SkeletonAnimation", 0, &tolua_err)) goto tolua_lerror;
#endif

    cobj = (spine::SkeletonAnimation*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
    if (!cobj)
    {
        tolua_error(tolua_S, "invalid 'cobj' in function 'lua_summoner_extend_spine_animationState_apply'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    if (argc == 0)
    {
        spAnimationState* state = cobj->getState();
        spSkeleton* skeleton = cobj->getSkeleton();
        if (state && skeleton)
        {
            spAnimationState_apply(state, skeleton);
            lua_pushboolean(tolua_S, 1);
            return 1;
        }

        lua_pushboolean(tolua_S, 0);
        return 1;
    }
    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "animationStateApply", argc, 0);
    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'lua_summoner_extend_spine_animationState_apply'.", &tolua_err);
#endif

    return 0;
}

static void extendSpine(lua_State* L)
{
    lua_pushstring(L, "sp.SkeletonAnimation");
    lua_rawget(L, LUA_REGISTRYINDEX);
    if (lua_istable(L, -1))
    {
        tolua_function(L, "existAnimation", lua_summoner_extend_spine_existAnimation);
        tolua_function(L, "animationStateApply", lua_summoner_extend_spine_animationState_apply);
    }
    lua_pop(L, 1);
}

int applyGray(lua_State* L)
{
    bool ok = true;
    int argc = lua_gettop(L);

    do
    {
        if (argc == 1)
        {
            cocos2d::Node* arg0;
            ok &= luaval_to_object<cocos2d::Node>(L, 1, "cc.Node", &arg0);
            if (!ok) break;

            CSimpleShader::applyGray(arg0);
        }
    } while (0);

    lua_pushboolean(L, ok);
    return 1;
}

int removeGray(lua_State* L)
{
    bool ok = true;
    int argc = lua_gettop(L);

    do
    {
        if (argc == 1)
        {
            cocos2d::Node* arg0;
            ok &= luaval_to_object<cocos2d::Node>(L, 1, "cc.Node", &arg0);
            if (!ok) break;

            CSimpleShader::removeGray(arg0);
        }
    } while (0);

    lua_pushboolean(L, ok);
    return 1;
}

void extendShaderTools(lua_State* L)
{
    lua_register(L, "applyGray", applyGray);
    lua_register(L, "removeGray", removeGray);
}

static int lua_summoner_extend_dispatcher_setMultiTouchEnable(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::EventDispatcher* cobj = nullptr;
    bool ok = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S, 1, "cc.EventDispatcher", 0, &tolua_err)) goto tolua_lerror;
#endif

    cobj = (cocos2d::EventDispatcher*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
    if (!cobj)
    {
        tolua_error(tolua_S, "invalid 'cobj' in function 'lua_summoner_extend_dispatcher_setMultiTouchEnable'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    if (argc == 1)
    {
        bool arg0;

        ok &= luaval_to_boolean(tolua_S, 2, &arg0, "cc.EventDispatcher:setMultiTouchEnable");
        if (!ok)
        {
            tolua_error(tolua_S, "invalid arguments in function 'lua_summoner_extend_dispatcher_setMultiTouchEnable'", nullptr);
            return 0;
        }
        cobj->setMultiTouchEnable(arg0);
        return 0;
    }

    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.EventDispatcher:setMultiTouchEnable", argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'lua_summoner_extend_dispatcher_setMultiTouchEnable'.", &tolua_err);
#endif

    return 0;
}

static int lua_summoner_extend_dispatcher_isMultiTouchEnable(lua_State* tolua_S)
{
    int argc = 0;
    cocos2d::EventDispatcher* cobj = nullptr;
    bool ok = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S, 1, "cc.EventDispatcher", 0, &tolua_err)) goto tolua_lerror;
#endif

    cobj = (cocos2d::EventDispatcher*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
    if (!cobj)
    {
        tolua_error(tolua_S, "invalid 'cobj' in function 'lua_summoner_extend_dispatcher_isMultiTouchEnable'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    if (argc == 0)
    {
        if (!ok)
        {
            tolua_error(tolua_S, "invalid arguments in function 'lua_summoner_extend_dispatcher_isMultiTouchEnable'", nullptr);
            return 0;
        }

        bool ret = cobj->isMultiTouchEnable();
        tolua_pushboolean(tolua_S, ret);
        return 1;
    }

    luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "cc.EventDispatcher:isMultiTouchEnable", argc, 1);
    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'lua_summoner_extend_dispatcher_isMultiTouchEnable'.", &tolua_err);
#endif

    return 0;
}

static void extendEventDispatcher(lua_State* L)
{
    lua_pushstring(L, "cc.EventDispatcher");
    lua_rawget(L, LUA_REGISTRYINDEX);
    if (lua_istable(L, -1))
    {
        tolua_function(L, "setMultiTouchEnable", lua_summoner_extend_dispatcher_setMultiTouchEnable);
        tolua_function(L, "isMultiTouchEnable", lua_summoner_extend_dispatcher_isMultiTouchEnable);
    }
    lua_pop(L, 1);
}

int register_all_summoner_extend_manual(lua_State* L)
{
    if (nullptr == L)
        return 0;

    extendSpine(L);
    extendShaderTools(L);
    extendEventDispatcher(L);

    return 0;
}

bool regiestSummonerExtend()
{
    auto L = LuaEngine::getInstance()->getLuaStack()->getLuaState();

    register_all_summoner_extend_manual(L);

    return true;
}

