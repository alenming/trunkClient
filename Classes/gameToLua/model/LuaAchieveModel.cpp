#include "LuaTools.h"
#include "ModelData.h"
#include "LuaAchieveModel.h"

int addAchieve(lua_State *L)
{
	CAchieveModel* model = LuaTools::checkClass<CAchieveModel>(L, -2, "Summoner.AchieveModel");
	if (NULL != model)
	{
		AchieveInfo info;
		lua_getfield(L, -1, "achieveID");
		info.achieveID = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "achieveVal");
		info.achieveVal = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "achieveStatus");
		info.achieveStatus = lua_tointeger(L, -1);
		lua_pop(L, 1);

		bool ret = model->addAchieve(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int delAchieve(lua_State* L)
{
	CAchieveModel* model = LuaTools::checkClass<CAchieveModel>(L, -2, "Summoner.AchieveModel");
	if (NULL != model)
	{
		int id = luaL_checkint(L, -1);
		bool ret = model->delAchieve(id);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int setAchieve(lua_State *L)
{
	CAchieveModel* model = LuaTools::checkClass<CAchieveModel>(L, -2, "Summoner.AchieveModel");
	if (NULL != model)
	{
		AchieveInfo info;
		lua_getfield(L, -1, "achieveID");
		info.achieveID = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "achieveVal");
		info.achieveVal = lua_tointeger(L, -1);
		lua_pop(L, 1);

		lua_getfield(L, -1, "achieveStatus");
		info.achieveStatus = lua_tointeger(L, -1);
		lua_pop(L, 1);

		bool ret = model->setAchieve(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getAchievesData(lua_State* L)
{
	CAchieveModel* model = LuaTools::checkClass<CAchieveModel>(L, -1, "Summoner.AchieveModel");
	if (NULL != model)
	{
		const std::map<int, AchieveInfo>& data = model->getAchievesData();
		lua_newtable(L);
		for (auto& achieve : data)
		{
			lua_newtable(L);
			LuaTools::pushBaseKeyValue(L, achieve.second.achieveID, "achieveID");
			LuaTools::pushBaseKeyValue(L, achieve.second.achieveVal, "achieveVal");
			LuaTools::pushBaseKeyValue(L, achieve.second.achieveStatus, "achieveStatus");
			lua_rawseti(L, -2, achieve.first);
		}
		return 1;
	}
	return 0;
}

int newAchieveModel(lua_State *L)
{
	CAchieveModel *model = new CAchieveModel();
	LuaTools::pushClass(L, model, "Summoner.AchieveModel");
	return 1;
}

int deleteAchieveModel(lua_State *L)
{
	CAchieveModel* model = LuaTools::checkClass<CAchieveModel>(L, -1, "Summoner.AchieveModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funAchieve[] =
{
	{ "addAchieve", addAchieve },
	{ "delAchieve", delAchieve },
	{ "setAchieve", setAchieve },
	{ "getAchievesData", getAchievesData },
	{ NULL, NULL }
};


bool registeAchieveModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.AchieveModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funAchieve, 0);

	lua_register(luaState, "newAchieveModel", newAchieveModel);
	lua_register(luaState, "deleteAchieveModel", deleteAchieveModel);

	return true;
}
