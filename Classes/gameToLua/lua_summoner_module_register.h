#ifndef __LUA_SUMMONER_MODULE_REGISTER_H__
#define __LUA_SUMMONER_MODULE_REGISTER_H__

#include "cocosbuilder/lua_cocos2dx_cocosbuilder_manual.h"
#include "cocostudio/lua_cocos2dx_coco_studio_manual.hpp"
#include "extension/lua_cocos2dx_extension_manual.h"
#include "ui/lua_cocos2dx_ui_manual.hpp"
#include "spine/lua_cocos2dx_spine_manual.hpp"
#include "3d/lua_cocos2dx_3d_manual.h"
#include "lua_cocos2dx_quick_manual.hpp"

static int lua_summoner_module_register(lua_State* L)
{
    //Dont' change the module register order unless you know what your are doing
    register_cocosbuilder_module(L);
    register_cocostudio_module(L);
    register_ui_moudle(L);
    register_extension_module(L);
    register_spine_module(L);
    register_cocos3d_module(L);
    register_all_quick_manual(L);
    return 1;
}

#endif  // __LUA_SUMMONER_MODULE_REGISTER_H__

