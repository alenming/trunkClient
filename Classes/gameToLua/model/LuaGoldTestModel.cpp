#include "LuaTools.h"
#include "ModelData.h"
#include "LuaEquipModel.h"

int getCount(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -1, "Summoner.GoldTestModel");
    if (NULL != model)
    {
        int data = model->getCount();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int addCount(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addCount(data);
    }
    return 0;
}

int getStamp(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -1, "Summoner.GoldTestModel");
    if (NULL != model)
    {
        int data = model->getStamp();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int setStamp(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setStamp(data);
    }
    return 0;
}

int getDamage(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -1, "Summoner.GoldTestModel");
    if (NULL != model)
    {
        int data = model->getDamage();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int addDamage(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addDamage(data);
    }
    return 0;
}

int getState(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int index = luaL_checkint(L, -1);
    if (NULL != model)
    {
        int data = model->getState(index);
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int setState(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int index = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setState(index);
    }
    return 0;
}

int setGoldTestFlag(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int flag = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setFlag(flag);
    }
    return 0;
}

int resetGoldTest(lua_State* L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    int nNewStamp = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->resetGoldTest(nNewStamp);
    }

    return 0;
}

int newGoldTestModel(lua_State *L)
{
    CGoldTestModel* model = new CGoldTestModel();
    LuaTools::pushClass(L, model, "Summoner.GoldTestModel");
    return 1;
}

int deleteGoldTestModel(lua_State *L)
{
    CGoldTestModel* model = LuaTools::checkClass<CGoldTestModel>(L, -2, "Summoner.GoldTestModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}

static const struct luaL_reg funGoldTest[] =
{
    { "getCount", getCount },
    { "getStamp", getStamp },
    { "getDamage", getDamage },
    { "getState", getState },
    { "addCount", addCount },
    { "setStamp", setStamp },
    { "addDamage", addDamage },
    { "setState", setState },
    { "setGoldTestFlag", setGoldTestFlag },
    { "resetGoldTest", resetGoldTest },
    { NULL, NULL }
};

bool regiestGoldTestModel()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.GoldTestModel");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funGoldTest, 0);

    lua_register(luaState, "newGoldTestModel", newGoldTestModel);
    lua_register(luaState, "deleteGoldTestModel", deleteGoldTestModel);

    return true;
}
