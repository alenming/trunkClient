#include "LuaTowerTestModel.h"
#include "LuaTools.h"
#include "ModelData.h"
/*
int getTowerTestTimes(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getTimes();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestStamp(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getStamp();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestFloor(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getFloor();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestBestF(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getBestF();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestEvent(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getEvent();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestParam(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getParam();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestScore(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getScore();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestStar(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getStar();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int getTowerTestBuff(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		std::map<int, int>& data = model->getBuff();
		LuaTools::pushMapIntInt(data);
		return 1;
	}
	return 0;
}

int getTowerTestCrystal(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -1, "Summoner.TowerTestModel");
	if (model)
	{
		int n = model->getCrystal();
		lua_pushnumber(L, n);
		return 1;
	}
	return 0;
}

int setTowerTestTimes(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setTimes(n);
	}
	return 0;
}


int setTowerTestStamp(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setStamp(n);
	}
	return 0;
}

int setTowerTestFloor(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setFloor(n);
	}
	return 0;
}

int setTowerTestBestF(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setBestF(n);
	}
	return 0;
}


int setTowerTestEvent(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setEvent(n);
	}
	return 0;
}

int setTowerTestParam(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setParam(n);
	}
	return 0;
}

int setTowerTestScore(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setScore(n);
	}
	return 0;
}

int setTowerTestStar(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setStar(n);
	}
	return 0;
}

int setTowerTestBuff(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int id = luaL_checkint(L, -1);
	if (model)
	{
		model->addBuff(id);
	}
	return 0;
}

int setTowerTestCrystal(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	int n = luaL_checkint(L, -1);
	if (model)
	{
		model->setCrystal(n);
	}
	return 0;
}

static const struct luaL_reg funTower[] =
{
	{ "getTowerTestTimes", getTowerTestTimes },
	{ "getTowerTestStamp", getTowerTestStamp },
	{ "getTowerTestFloor", getTowerTestFloor },
	{ "getTowerTestBestF", getTowerTestBestF },
	{ "getTowerTestEvent", getTowerTestEvent },
	{ "getTowerTestParam", getTowerTestParam },
	{ "getTowerTestScore", getTowerTestScore },
	{ "getTowerTestStar",  getTowerTestStar },
	{ "getTowerTestBuff",  getTowerTestBuff },
	{ "getTowerTestCrystal", getTowerTestCrystal },

	{ "setTowerTestTimes", setTowerTestTimes },
	{ "setTowerTestStamp", setTowerTestStamp },
	{ "setTowerTestFloor", setTowerTestFloor },
	{ "setTowerTestBestF", setTowerTestBestF },
	{ "setTowerTestEvent", setTowerTestEvent },
	{ "setTowerTestParam", setTowerTestParam },
	{ "setTowerTestScore", setTowerTestScore },
	{ "setTowerTestStar", setTowerTestStar },
	{ "setTowerTestBuff", setTowerTestBuff },
	{ "setTowerTestCrystal", setTowerTestCrystal },

	{ NULL, NULL }
};

int newTowerTestModel(lua_State *L)
{
	CTowerTestModel *model = new CTowerTestModel();
	LuaTools::pushClass(L, model, "Summoner.TowerTestModel");
	return 1;
}

int deleteTowerTestModel(lua_State *L)
{
	CTowerTestModel* model = LuaTools::checkClass<CTowerTestModel>(L, -2, "Summoner.TowerTestModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}*/

bool registerTowerTestModel()
{
	//auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	//auto luaState = luaStack->getLuaState();

	//luaL_newmetatable(luaState, "Summoner.TowerTestModel");
	//lua_pushstring(luaState, "__index");
	//lua_pushvalue(luaState, -2);
	//lua_settable(luaState, -3);
	//luaL_openlib(luaState, NULL, funTower, 0);

	//lua_register(luaState, "newTowerTestModel", newTowerTestModel);
	//lua_register(luaState, "deleteTowerTestModel", deleteTowerTestModel);

	return true;
}

