#include "LuaTools.h"
#include "ModelData.h"
#include "LuaTaskModel.h"

int addTask(lua_State *L)
{
	CTaskModel* model = LuaTools::checkClass<CTaskModel>(L, -2, "Summoner.TaskModel");
	if (NULL != model)
	{
		TaskInfo info;
		lua_getfield(L, -1, "taskID");
		info.taskID = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "taskVal");
		info.taskVal = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "taskStatus");
		info.taskStatus = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "resetTime");
		info.resetTime = lua_tointeger(L, -1);
		lua_pop(L, 1);

		bool ret = model->addTask(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int delTask(lua_State *L)
{
	CTaskModel* model = LuaTools::checkClass<CTaskModel>(L, -2, "Summoner.TaskModel");
	if (NULL != model)
	{
		int id = luaL_checkint(L, -1);
		bool ret = model->delTask(id);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int setTask(lua_State *L)
{
	CTaskModel* model = LuaTools::checkClass<CTaskModel>(L, -2, "Summoner.TaskModel");
	if (NULL != model)
	{
		TaskInfo info;
		lua_getfield(L, -1, "taskID");
		info.taskID = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "taskVal");
		info.taskVal = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "taskStatus");
		info.taskStatus = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "resetTime");
		info.resetTime = lua_tointeger(L, -1);
		lua_pop(L, 1);

		bool ret = model->setTask(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getTasksData(lua_State *L)
{
	CTaskModel* model = LuaTools::checkClass<CTaskModel>(L, -1, "Summoner.TaskModel");
	if (NULL != model)
	{
		const std::map<int, TaskInfo>& data = model->getTasksData();
		lua_newtable(L);
		for (auto& task : data)
		{
			lua_newtable(L);
			LuaTools::pushBaseKeyValue(L, task.second.taskID, "taskID");
			LuaTools::pushBaseKeyValue(L, task.second.taskVal, "taskVal");
			LuaTools::pushBaseKeyValue(L, task.second.taskStatus, "taskStatus");
			LuaTools::pushBaseKeyValue(L, task.second.resetTime, "resetTime");

			lua_rawseti(L, -2, task.first);
		}
		return 1;
	}
	return 0;
}

int newTaskModel(lua_State *L)
{
	CTaskModel *model = new CTaskModel();
	LuaTools::pushClass(L, model, "Summoner.TaskModel");
	return 1;
}

int deleteTaskModel(lua_State *L)
{
	CTaskModel* model = LuaTools::checkClass<CTaskModel>(L, -1, "Summoner.TaskModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funTask[] =
{
	{ "addTask", addTask },
	{ "delTask", delTask },
	{ "setTask", setTask },
	{ "getTasksData", getTasksData },
	{ NULL, NULL }
};


bool registeTaskModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.TaskModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funTask, 0);

	lua_register(luaState, "newTaskModel", newTaskModel);
	lua_register(luaState, "deleteTaskModel", deleteTaskModel);

	return true;
}
