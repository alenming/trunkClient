#include "LuaTools.h"
#include "ModelData.h"
#include "luaStageModel.h"

int getChapterStates(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -1, "Summoner.StageModel");
	if (NULL != model)
	{
		auto items = model->getChapterStates();
		LuaTools::pushMapIntInt(items);
		return 1;
	}
	return 0;
}

int getComonStageStates(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -1, "Summoner.StageModel");
	if (NULL != model)
	{
        auto items = model->getComonStageStates();
		LuaTools::pushMapIntInt(items);
		return 1;
	}
	return 0;
}

int getEliteStageStates(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -1, "Summoner.StageModel");
	if (NULL != model)
	{
        auto items = model->getEliteStageStates();
		LuaTools::pushMapIntInt(items);
		return 1;
	}
	return 0;
}

int getCurrentComonStageID(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -1, "Summoner.StageModel");
	if (NULL != model)
	{
		auto s = model->getCurrentComonStageID();
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getCurrentEliteStageID(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -1, "Summoner.StageModel");
	if (NULL != model)
	{
		auto s = model->getCurrentEliteStageID();
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getChapterState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int ch = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto s = model->getChapterState(ch);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getComonStageState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int stage = luaL_checkint(L, -1);
	if (NULL != model)
	{
        auto s = model->getComonStageState(stage);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getEliteStageState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int stage = luaL_checkint(L, -1);
	if (NULL != model)
	{
        auto s = model->getEliteStageState(stage);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getEliteChallengeCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int lv = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto s = model->getEliteChallengeCount(lv);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getEliteBuyCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int lv = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto s = model->getEliteBuyCount(lv);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getEliteChallengeTimestamp(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int lv = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto s = model->getEliteChallengeTimestamp(lv);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int getEliteBuyTimestamp(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int lv = luaL_checkint(L, -1);
	if (NULL != model)
	{
		auto s = model->getEliteBuyTimestamp(lv);
		lua_pushnumber(L, s);
		return 1;
	}
	return 0;
}

int setCurrentComonStageID(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setCurrentComonStageID(s);
	}
	return 0;
}

int setCurrentEliteStageID(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setCurrentEliteStageID(s);
	}
	return 0;
}

int setChapterState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setChapterState(lv, s);
	}
	return 0;
}

int setComonStageState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setComonStageState(lv, s);
	}
	return 0;
}

int setEliteStageState(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setEliteStageState(lv, s);
	}
	return 0;
}

int setEliteChallengeCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setEliteChallengeCount(lv, s);
	}
	return 0;
}

int setEliteBuyCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setEliteBuyCount(lv, s);
	}
	return 0;
}

int setEliteChallengeTimestamp(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setEliteChallengeTimestamp(lv, s);
	}
	return 0;
}

int setEliteBuyTimestamp(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -3, "Summoner.StageModel");
	int lv = luaL_checkint(L, -2);
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setEliteBuyTimestamp(lv, s);
	}
	return 0;
}

int resetEliteChallengeCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->resetEliteChallengeCount(s);
	}
	return 0;
}

int resetEliteBuyCount(lua_State* L)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(L, -2, "Summoner.StageModel");
	int s = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->resetEliteBuyCount(s);
	}
	return 0;
}

int newStageModel(lua_State* L)
{
	CStageModel* model = new CStageModel();
	LuaTools::pushClass(L, model, "Summoner.StageModel");
	return 1;
}

int deleteStageModel(lua_State* l)
{
	CStageModel* model = LuaTools::checkClass<CStageModel>(l, -2, "Summoner.StageModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funLevel[] =
{
	{ "getChapterStates",			getChapterStates },
	{ "getComonStageStates",		getComonStageStates },
	{ "getEliteStageStates",		getEliteStageStates },

	{ "getCurrentComonStageID",		getCurrentComonStageID },
	{ "getCurrentEliteStageID",		getCurrentEliteStageID },
	{ "getChapterState",			getChapterState },
	{ "getComonStageState",			getComonStageState },
	{ "getEliteStageState",			getEliteStageState },
	{ "getEliteChallengeCount",		getEliteChallengeCount },
	{ "getEliteBuyCount",			getEliteBuyCount },
	{ "getEliteChallengeTimestamp", getEliteChallengeTimestamp },
	{ "getEliteBuyTimestamp",		getEliteBuyTimestamp },

	{ "setCurrentComonStageID",		setCurrentComonStageID },
	{ "setCurrentEliteStageID",		setCurrentEliteStageID },
	{ "setChapterState",			setChapterState },
	{ "setComonStageState",			setComonStageState },
	{ "setEliteStageState",			setEliteStageState },
	{ "setEliteChallengeCount",		setEliteChallengeCount },
	{ "setEliteBuyCount",			setEliteBuyCount },
	{ "setEliteChallengeTimestamp", setEliteChallengeTimestamp },
	{ "setEliteBuyTimestamp",		setEliteBuyTimestamp },
	
	{ "resetEliteChallengeCount",	resetEliteChallengeCount },
	{ "resetEliteBuyCount",			resetEliteBuyCount },

	{ NULL, NULL }
};

bool regiestStageModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.StageModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funLevel, 0);

	lua_register(luaState, "newStageModel", newStageModel);
	lua_register(luaState, "deleteStageModel", deleteStageModel);

	return true;
}