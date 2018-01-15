#include "LuaPersonalTaskModel.h"
#include "LuaTools.h"
#include "ModelData.h"

int getPersonalTaskResetTime(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -1, "Summoner.PersonalTaskModel");
	if (model)
	{
		lua_pushinteger(L, model->getResetTime());
		return 1;
	}
	return 0;
}

int setPersonalTaskResetTime(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -2, "Summoner.PersonalTaskModel");
	int resetTime = luaL_checkint(L, -1);
	if (model)
	{
		model->setResetTime(resetTime);
	}
	return 0;
}

int addPersonalTask(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -2, "Summoner.PersonalTaskModel");
	PersonalTaskInfo info;
	lua_getfield(L, -1, "id");
	info.id = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "stage");
	info.stage = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "status");
	info.status = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "enemyLv");
	info.enemyLv = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (model)
	{
		bool ret = model->addTask(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getPersonalTasks(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -1, "Summoner.PersonalTaskModel");
	if (model)
	{
		auto tasks = model->getTasks();

		lua_newtable(L);
		for (const auto& info:tasks)
		{
			lua_newtable(L);
			LuaTools::pushBaseKeyValue(L, info.second.id, "id");
			LuaTools::pushBaseKeyValue(L, info.second.stage, "stage");
			LuaTools::pushBaseKeyValue(L, info.second.status, "status");
			LuaTools::pushBaseKeyValue(L, info.second.enemyLv, "enemyLv");
			lua_rawseti(L, -2, info.first);
		}
		return 1;
	}
	return 0;
}

int setPersonalTask(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -2, "Summoner.PersonalTaskModel");
	PersonalTaskInfo info;
	lua_getfield(L, -1, "id");
	info.id = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "stage");
	info.stage = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "status");
	info.status = lua_tointeger(L, -1);
	lua_pop(L, 1);
	lua_getfield(L, -1, "enemyLv");
	info.enemyLv = lua_tointeger(L, -1);
	lua_pop(L, 1);
	if (model)
	{
		bool ret = model->setTask(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int clearPersonaTasks(lua_State *L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -1, "Summoner.PersonalTaskModel");
	if (model)
	{
		model->clearPersonaTasks();
	}
	return 0;
}

int newPersonalTaskModel(lua_State* L)
{
	CPersonalTaskModel* model = new CPersonalTaskModel();
	LuaTools::pushClass(L, model, "Summoner.PersonalTaskModel");
	return 1;
}

int deletePersonalTaskModel(lua_State* L)
{
	CPersonalTaskModel* model = LuaTools::checkClass<CPersonalTaskModel>(L, -2, "Summoner.PersonalTaskModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funPersonalTask[] =
{
	{ "getPersonalTaskResetTime", getPersonalTaskResetTime },
	{ "setPersonalTaskResetTime", setPersonalTaskResetTime },
	{ "addPersonalTask", addPersonalTask },
	{ "getPersonalTasks", getPersonalTasks },
	{ "setPersonalTask", setPersonalTask },
	{ "clearPersonaTasks", clearPersonaTasks },
	{ NULL, NULL }
};

bool registePersonalTaskModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.PersonalTaskModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funPersonalTask, 0);

	lua_register(luaState, "newPersonalTaskModel", newPersonalTaskModel);
	lua_register(luaState, "deletePersonalTaskModel", deletePersonalTaskModel);

	return true;
}

