#include "LuaTools.h"
#include "ModelData.h"

int getActives(lua_State* L)
{
	CGuideModel* model = LuaTools::checkClass<CGuideModel>(L, -1, "Summoner.GuideModel");
	if (NULL != model)
	{
		auto ids = model->getActives();
		lua_newtable(L);
		int i = 1;
		for (auto id : ids)
		{
			lua_pushinteger(L, id);
			lua_rawseti(L, -2, i++);
		}
		return 1;
	}
	return 0;
}

int delGuide(lua_State* L)
{
	CGuideModel* model = LuaTools::checkClass<CGuideModel>(L, -2, "Summoner.GuideModel");
	int id = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->del(id);
	}
	return 0;
}

int addGuide(lua_State* L)
{
	CGuideModel* model = LuaTools::checkClass<CGuideModel>(L, -2, "Summoner.GuideModel");
	int id = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->add(id);
	}
	return 0;
}

int newGuideModel(lua_State* L)
{
	CGuideModel* model = new CGuideModel();

	LuaTools::pushClass(L, model, "Summoner.GuideModel");
	return 1;
}

int deleteGuideModel(lua_State* l)
{
	CGuideModel* model = LuaTools::checkClass<CGuideModel>(l, -2, "Summoner.GuideModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funGuide[] =
{
	{ "getActives", getActives },
	{ "delGuide", delGuide },
	{ "addGuide", addGuide },
	{ NULL, NULL }
};

bool registerGuideModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.GuideModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funGuide, 0);

	lua_register(luaState, "newGuideModel", newGuideModel);
	lua_register(luaState, "deleteGuideModel", deleteGuideModel);

	return true;
}