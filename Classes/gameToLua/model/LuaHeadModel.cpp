
#include "LuaTools.h"
#include "ModelData.h"

int getUnlockedHeads(lua_State* L)
{
    CHeadModel* model = LuaTools::checkClass<CHeadModel>(L, -1, "Summoner.HeadModel");
    if (NULL != model)
    {
        auto heads = model->getUnlockedHeads();
        LuaTools::pushVecIntToArray(heads, L);
        return 1;
    }
    return 0;
}

int isUnlocked(lua_State* L)
{
    CHeadModel* model = LuaTools::checkClass<CHeadModel>(L, -2, "Summoner.HeadModel");
    const int headID = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        const bool ret = model->isUnlocked(headID);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}

int addHead(lua_State* L)
{
    CHeadModel* model = LuaTools::checkClass<CHeadModel>(L, -2, "Summoner.HeadModel");
    const int headID = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        const bool ret = model->addHead(headID);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}

int newHeadModel(lua_State* L)
{
    CHeadModel* model = new CHeadModel();
    LuaTools::pushClass(L, model, "Summoner.HeadModel");
    return 1;
}

int deleteHeadModel(lua_State* l)
{
    CHeadModel* model = LuaTools::checkClass<CHeadModel>(l, -2, "Summoner.HeadModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}

static const struct luaL_reg funUser[] =
{
    { "getUnlockedHeads", getUnlockedHeads },
    { "isUnlocked", isUnlocked },
    { "addHead", addHead },

    { NULL, NULL }
};

bool registeHeadModel()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.HeadModel");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funUser, 0);

    lua_register(luaState, "newHeadModel", newHeadModel);
    lua_register(luaState, "deleteHeadModel", deleteHeadModel);

    return true;
}