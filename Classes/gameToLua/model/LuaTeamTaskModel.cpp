#include "LuaTeamTaskModel.h"
#include "LuaTools.h"
#include "ModelData.h"

int getTeamTask(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -1, "Summoner.TeamTaskModel");
	if (model)
	{
		auto task = model->getTeamTask();
		lua_newtable(L);
		LuaTools::pushBaseKeyValue(L, task.curTaskID, "curTaskID");
		LuaTools::pushBaseKeyValue(L, task.endTime, "endTime");
		LuaTools::pushBaseKeyValue(L, task.stage, "stage");
		LuaTools::pushBaseKeyValue(L, task.bossHp, "bossHp");
		LuaTools::pushBaseKeyValue(L, task.rewardBox, "rewardBox");
		LuaTools::pushBaseKeyValue(L, task.challengeCDTime, "challengeCDTime");
		LuaTools::pushBaseKeyValue(L, task.challengeTimes, "challengeTimes");
		LuaTools::pushBaseKeyValue(L, task.nextTargetTime, "nextTargetTime");
		return 1;
	}
	return 0;
}

int setTeamTask(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");
	
	TeamTaskInfo info;
	lua_getfield(L, -1, "curTaskID");
	info.curTaskID = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "endTime");
	info.endTime = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "stage");
	info.stage = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "bossHp");
	info.bossHp = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "rewardBox");
	info.rewardBox = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "challengeCDTime");
	info.challengeCDTime = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "challengeTimes");
	info.challengeTimes = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "nextTargetTime");
	info.nextTargetTime = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (model)
	{
		model->setTeamTask(info);
	}
	return 0;
}

int getNextTeamTasks(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -1, "Summoner.TeamTaskModel");
	if (model)
	{
		auto tasks = model->getNextTeamTasks();
		lua_newtable(L);
		LuaTools::pushVecIntToArray(tasks, L);
		return 1;
	}
	return 0;
}

int setNextTeamTask(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");
	int count = luaL_getn(L, -1);
	std::vector<int> vecTaskID;
	for (int i = 1; i <= count; i++)
	{
		// 获取栈顶的table,依次取出各个KEY的值,最后pop保持栈顶是table
		lua_rawgeti(L, -1, i);
		int taskID = lua_tointeger(L, -1);
		vecTaskID.push_back(taskID);
		lua_pop(L, 1);
	}
	if (model)
	{
		model->setNextTeamTask(vecTaskID);
	}
	return 0;
}

int setNextTeamTaskID(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");	
	int taskID = lua_tointeger(L, -1);
	if (model)
	{
		model->setNextTeamTaskID(taskID);
	}
	return 0;
}

int getNextTeamTaskID(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -1, "Summoner.TeamTaskModel");
	if (model)
	{
		int id = model->getNextTeamTaskID();
		lua_pushinteger(L, id);
		return 1;
	}
	return 0;
}

int getHurtsInfo(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -1, "Summoner.TeamTaskModel");
	if (model)
	{
		auto hurtsInfo = model->getHurtsInfo();
		lua_newtable(L);
		for (const auto& info : hurtsInfo)
		{
			lua_newtable(L);
			LuaTools::pushBaseKeyValue(L, info.second.userID, "userID");
			LuaTools::pushBaseKeyValue(L, info.second.userName, "userName");
			LuaTools::pushBaseKeyValue(L, info.second.job, "job");
			LuaTools::pushBaseKeyValue(L, info.second.headID, "headID");
			LuaTools::pushBaseKeyValue(L, info.second.hurt, "hurt");
			lua_rawseti(L, -2, info.first);
		}
		return 1;
	}
	return 0;
}

int setHurtInfo(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");

	TeamHurtInfo info;
	lua_getfield(L, -1, "userID");
	info.userID = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "userName");
	strcpy(info.userName, luaL_checkstring(L, -1));
	lua_pop(L, 1);
	lua_getfield(L, -1, "job");
	info.job = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "headID");
	info.headID = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "hurt");
	info.hurt = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (model)
	{
		bool ret = model->setHurtInfo(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int addHurtInfo(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");

	TeamHurtInfo info;
	lua_getfield(L, -1, "userID");
	info.userID = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "userName");
	strcpy(info.userName, luaL_checkstring(L, -1));
	lua_pop(L, 1);
	lua_getfield(L, -1, "job");
	info.job = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "headID");
	info.headID = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "hurt");
	info.hurt = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (model)
	{
		bool ret = model->addHurtInfo(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int clearTeamTask(lua_State *L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -6, "Summoner.TeamTaskModel");
	if (model)
	{
		model->clearTask();
	}
	return 0;
}

int newTeamTaskModel(lua_State* L)
{
	CTeamTaskModel* model = new CTeamTaskModel();
	LuaTools::pushClass(L, model, "Summoner.TeamTaskModel");
	return 1;
}

int deleteTeamTaskModel(lua_State* L)
{
	CTeamTaskModel* model = LuaTools::checkClass<CTeamTaskModel>(L, -2, "Summoner.TeamTaskModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funTeamTask[] =
{
	{ "getTeamTask", getTeamTask },
	{ "setTeamTask", setTeamTask },
	{ "getNextTeamTasks", getNextTeamTasks },
	{ "setNextTeamTask", setNextTeamTask },
	{ "setNextTeamTaskID", setNextTeamTaskID },
	{ "getNextTeamTaskID", getNextTeamTaskID },
	{ "getHurtsInfo", getHurtsInfo },
	{ "setHurtInfo", setHurtInfo },
	{ "addHurtInfo", addHurtInfo },
	{ "clearTeamTask", clearTeamTask },
	{ NULL, NULL }
};

bool registeTeamTaskModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.TeamTaskModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funTeamTask, 0);

	lua_register(luaState, "newTeamTaskModel", newTeamTaskModel);
	lua_register(luaState, "deleteTeamTaskModel", deleteTeamTaskModel);

	return true;
}

