#include "LuaTools.h"
#include "ModelData.h"
/*
int setFrag(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
        model->setFrag(data);
	}
	return 0;
}
int setLevel(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
        model->setLevel(data);
	}
	return 0;
}

int setStar(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
        model->setStar(data);
	}
	return 0;
}

int setExp(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
        model->setExp(data);
	}
	return 0;
}

int setTalent(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setTalent(data);
    }
    return 0;
}

int setSkillLevel(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -3, "Summoner.HeroCardModel");
    int data1 = luaL_checkint(L, -2);
    int data2 = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setSkillLevel(data1, data2);
    }
    return 0;
}

int setEquip(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -3, "Summoner.HeroCardModel");
    int data1 = luaL_checkint(L, -2);
    int data2 = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setEquip((EquipPartType)data1, data2);
    }
    return 0;
}

int getID(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
	if (NULL != model)
	{
        int data = model->getID();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int getFrag(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
    if (NULL != model)
    {
        int data = model->getFrag();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getLevel(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
	if (NULL != model)
	{
        int data = model->getLevel();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int getStar(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
	if (NULL != model)
	{
        int data = model->getStar();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int getExp(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
	if (NULL != model)
	{
        int data = model->getExp();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int getTalent(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
    if (NULL != model)
    {
        int data = model->getTalent();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getSkillLevel(lua_State* L)
{
    CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        int lv = model->getSkillLevel(data);
        lua_pushinteger(L, lv);
        return 1;
    }
    return 0;
}

int getEquip(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -2, "Summoner.HeroCardModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
	{
        int id = model->getEquip((EquipPartType)data);
        lua_pushinteger(L, id);
        return 1;
	}
	return 0;
}

int getEquips(lua_State* L)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(L, -1, "Summoner.HeroCardModel");
	if (NULL != model)
	{
        auto equips = model->getEquips();

        lua_newtable(L);
        for (int i = 0; i < 6; ++i)
        {
            lua_pushinteger(L, equips[i]);
            lua_rawseti(L, -2, i + 1);
        }
		return 1;
	}
	return 0;
}

int newHeroCardModel(lua_State* L)
{
	CHeroCardModel* model = new CHeroCardModel();
	LuaTools::pushClass(L, model, "Summoner.HeroCardModel");
	return 1;
}

int deleteHeroCardModel(lua_State* l)
{
	CHeroCardModel* model = LuaTools::checkClass<CHeroCardModel>(l, -2, "Summoner.HeroCardModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funHeroCard[] =
{
	{ "setFrag",    setFrag },
    { "setLevel",   setLevel },
    { "setStar",    setStar },
    { "setExp",     setExp },
    { "setTalent",  setTalent },
    { "setSkillLevel", setSkillLevel },
    { "setEquip",   setEquip },

    { "getID",      getID },
    { "getFrag",    getFrag },
    { "getLevel",   getLevel },
    { "getStar",    getStar },
    { "getExp",     getExp },
    { "getTalent",  getTalent },
    { "getSkillLevel", getSkillLevel },
    { "getEquip",   getEquip },
    { "getEquips",  getEquips },
	{ NULL, NULL }
};
*/

bool registeHeroCardModel()
{
	//auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	//auto luaState = luaStack->getLuaState();

	//luaL_newmetatable(luaState, "Summoner.HeroCardModel");
	//lua_pushstring(luaState, "__index");
	//lua_pushvalue(luaState, -2);

	//lua_settable(luaState, -3);
	//luaL_openlib(luaState, NULL, funHeroCard, 0);

	//lua_register(luaState, "newHeroCardModel", newHeroCardModel);
	//lua_register(luaState, "deleteHeroCardModel", deleteHeroCardModel);

	return true;
}