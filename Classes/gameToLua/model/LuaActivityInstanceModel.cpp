#include "LuaTools.h"
#include "ModelData.h"

int getActivityInstance(lua_State* L)
{
	CActivityInstanceModel* model = LuaTools::checkClass<CActivityInstanceModel>(L, -1, "Summoner.ActivityInstanceModel");
	if (NULL != model)
	{
		std::map<int, InstanceInfo>& infos = model->getActivityInstance();

		lua_newtable(L);
		for (auto& i : infos)
		{
			lua_newtable(L);
			LuaTools::pushBaseKeyValue(L, i.second.activityId, "activityId");
			LuaTools::pushBaseKeyValue(L, i.second.useTimes, "useTimes");
			LuaTools::pushBaseKeyValue(L, i.second.useStamp, "useStamp");
			LuaTools::pushBaseKeyValue(L, i.second.buyTimes, "buyTimes");
			LuaTools::pushBaseKeyValue(L, i.second.buyStamp, "buyStamp");
			LuaTools::pushBaseKeyValue(L, i.second.easy, "easy");
			LuaTools::pushBaseKeyValue(L, i.second.normal, "normal");
			LuaTools::pushBaseKeyValue(L, i.second.difficult, "difficult");
			LuaTools::pushBaseKeyValue(L, i.second.hell, "hell");
			LuaTools::pushBaseKeyValue(L, i.second.legend, "legend");
			lua_rawseti(L, -2, i.first);
		}
		return 1;
	}
	return 0;
}

int setInstanceCount(lua_State* L)
{
	CActivityInstanceModel* model = LuaTools::checkClass<CActivityInstanceModel>(L, -3, "Summoner.ActivityInstanceModel");
	int id = luaL_checkint(L, -2);
	int cn = luaL_checkint(L, -1);
	if (NULL != model)
	{
		std::map<int, InstanceInfo>& infos = model->getActivityInstance();
		infos[id].useTimes = cn;
		return 1;
	}
	return 0;
}

int newActivityInstanceModel(lua_State* L)
{
	CActivityInstanceModel* model = new CActivityInstanceModel();

	LuaTools::pushClass(L, model, "Summoner.ActivityInstanceModel");
	return 1;
}

int deleteActivityInstanceModel(lua_State* l)
{
	CActivityInstanceModel* model = LuaTools::checkClass<CActivityInstanceModel>(l, -2, "Summoner.ActivityInstanceModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funInstance[] =
{
	{ "getActivityInstance", getActivityInstance },
	{ "setInstanceCount", setInstanceCount },
	{ NULL, NULL }
};

bool registerActivityModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.ActivityInstanceModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funInstance, 0);

	lua_register(luaState, "newActivityInstanceModel", newActivityInstanceModel);
	lua_register(luaState, "deleteActivityInstanceModel", deleteActivityInstanceModel);

	return true;
}