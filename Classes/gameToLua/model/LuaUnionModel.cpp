#include "LuaTools.h"
#include "ModelData.h"
#include "LuaUnionModel.h"
#include "LoginProtocol.h"

int getHasUnion(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        bool value = model->getHasUnion();
        lua_pushboolean(L, model->getHasUnion());
        return 1;
    }
    return 0;
}

int setHasUnion(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = lua_toboolean(L, -1) == 1 ? true : false;
    if (NULL != model)
    {
        bool hasUnion = value == 0 ? false : true;
        model->setHasUnion(hasUnion);
    }
    return 0;
}

int getHasAudit(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        bool value = model->getHasAudit();
        lua_pushboolean(L, value);
        return 1;
    }
    return 0;
}

int getUnionID(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getUnionID();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getTodayLiveness(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getTodayLiveness();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getTotalContribution(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getTotalContribution();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getPos(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getPos();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getUnionName(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        const char* value = model->getUnionName();
        lua_pushstring(L, value);
        return 1;
    }
    return 0;
}

int getUnionNotice(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        const char* value = model->getUnionNotice();
        lua_pushstring(L, value);
        return 1;
    }
    return 0;
}

int setHasAudit(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        bool hasAudit = value == 0 ? false : true;
        model->setHasAudit(hasAudit);
    }
    return 0;
}

int setUnionID(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setUnionID(value);
    }
    return 0;
}

int setTodayLiveness(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setTodayLiveness(value);
    }
    return 0;
}

int setTotalContribution(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setTotalContribution(value);
    }
    return 0;
}

int setPos(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setPos(value);
    }
    return 0;
}

int setUnionName(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    std::string value = luaL_checkstring(L, -1);
    if (NULL != model)
    {
        model->setUnionName(value.c_str());
    }
    return 0;
}

int setUnionNotice(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    std::string value = luaL_checkstring(L, -1);
    if (NULL != model)
    {
        model->setUnionNotice(value.c_str());
    }
    return 0;
}

int getApplyCount(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getApplyCount();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getApplyStamp(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        int value = model->getApplyStamp();
        lua_pushinteger(L, value);
        return 1;
    }
    return 0;
}

int getApplyInfo(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
    if (NULL != model)
    {
        const std::vector<ApplyInfo> applyInfo = model->getApplyInfo();       
        lua_newtable(L);
        for (unsigned int i = 0; i < applyInfo.size(); ++i)
        {
            lua_newtable(L);
            LuaTools::pushBaseKeyValue(L, applyInfo[i].applyTime, "applyTime");
            LuaTools::pushBaseKeyValue(L, applyInfo[i].unionID, "unionID");
            lua_rawseti(L, -2, i + 1);
        }        
        return 1;
    }
    return 0;
}

int setApplyCount(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setApplyCount(value);
    }
    return 0;
}

int setApplyStamp(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setApplyStamp(value);
    }
    return 0;
}

int addApplyInfo(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -3, "Summoner.UnionModel");
    ApplyInfo info;
    info.unionID = luaL_checkint(L, -2);
    info.applyTime = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addApplyInfo(info);
    }
    return 0;
}

int delApplyInfo(lua_State *L)
{
    CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -2, "Summoner.UnionModel");
    int value = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->delApplyInfo(value);
    }
    return 0;
}

int newUnionModel(lua_State *L)
{
	CUnionModel *model = new CUnionModel();
	LuaTools::pushClass(L, model, "Summoner.UnionModel");
	return 1;
}

int deleteUnionModel(lua_State *L)
{
	CUnionModel* model = LuaTools::checkClass<CUnionModel>(L, -1, "Summoner.UnionModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funUnion[] =
{
    { "getHasUnion", getHasUnion },
    { "setHasUnion", setHasUnion },

    { "getHasAudit", getHasAudit },
    { "getUnionID", getUnionID },
    { "getTodayLiveness", getTodayLiveness },
    { "getTotalContribution", getTotalContribution },
    { "getPos", getPos },
    { "getUnionName", getUnionName },
    { "getUnionNotice", getUnionNotice },

    { "setHasAudit", setHasAudit },
    { "setUnionID", setUnionID },
    { "setTodayLiveness", setTodayLiveness },
    { "setTotalContribution", setTotalContribution },
    { "setPos", setPos },
    { "setUnionName", setUnionName },
    { "setUnionNotice", setUnionNotice },

    { "getApplyCount", getApplyCount },
    { "getApplyStamp", getApplyStamp },
    { "getApplyInfo", getApplyInfo },

    { "setApplyCount", setApplyCount },
    { "setApplyStamp", setApplyStamp },
    { "addApplyInfo", addApplyInfo },
    { "delApplyInfo", delApplyInfo },
	{ NULL, NULL }
};


bool registeUnionModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.UnionModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funUnion, 0);

	lua_register(luaState, "newUnionModel", newUnionModel);
	lua_register(luaState, "deleteUnionModel", deleteUnionModel);

	return true;
}
