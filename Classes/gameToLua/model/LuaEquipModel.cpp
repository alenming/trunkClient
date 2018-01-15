#include "LuaTools.h"
#include "ModelData.h"
#include "LuaEquipModel.h"

#define EQUIP_EFFECT_MAX 8

int equipAddEquip(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -6, "Summoner.EquipModel");
    int equipId = luaL_checkint(L, -5);
    int confId = luaL_checkint(L, -4);
	int nMianPropNum = luaL_checkint(L, -3);
	int equipEffectIdCount = luaL_getn(L, -2);
    int equipEffectValCount = luaL_getn(L, -1);
    if (model 
        && EQUIP_EFFECT_MAX == equipEffectIdCount && EQUIP_EFFECT_MAX == equipEffectValCount)
	{
		EquipItemInfo Info;
		memset(&Info, 0, sizeof(Info));
        Info.equipId = equipId;
        Info.confId = confId;
		Info.cMainPropNum = nMianPropNum;

        for (int i = 1; i <= equipEffectIdCount; i++)
        {
            // 获取-2位的table,依次取出各个KEY的值
            lua_rawgeti(L, -2, i);
            Info.cEffectID[i - 1] = lua_tointeger(L, -1);

            lua_pop(L, 1);
        }

        for (int j = 1; j <= equipEffectValCount; j++)
        {
            // 获取-1位的table,依次取出各个KEY的值
            lua_rawgeti(L, -1, j);
            Info.sEffectValue[j - 1] = lua_tointeger(L, -1);

            lua_pop(L, 1);
        }

		bool ret = model->addEquip(Info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int equipHasEquip(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -2, "Summoner.EquipModel");
	int arg1 = luaL_checkint(L, -1);
	if (NULL != model)
	{
		bool ret = model->haveEquip(arg1);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int getEquipConfId(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -2, "Summoner.EquipModel");
	int arg1 = luaL_checkint(L, -1);
	if (NULL != model)
	{
		int id = model->getEquipConfId(arg1);
		lua_pushinteger(L, id);
		return 1;
	}
	return 0;
}

int equipRemoveEquip(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -2, "Summoner.EquipModel");
	int arg1 = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->removeEquip(arg1);
		return 0;
	}
	return 0;
}

int equipGetEquips(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -1, "Summoner.EquipModel");
	if (NULL != model)
	{
		auto items = model->getEquips();

		lua_newtable(L);
		for (auto iter = items.begin(); iter != items.end(); ++iter)
		{
			lua_newtable(L);

			LuaTools::pushBaseKeyValue(L, iter->second.confId, "confId");
			LuaTools::pushBaseKeyValue(L, iter->second.equipId, "equipId");
			LuaTools::pushBaseKeyValue(L, iter->second.cMainPropNum, "nMainPropNum");

			lua_newtable(L);
			for (unsigned int i = 0; i < EQUIP_EFFECT_MAX; ++i)
			{
				lua_pushinteger(L, iter->second.cEffectID[i]);
				lua_rawseti(L, -2, i + 1);
			}
			lua_setfield(L, -2, "eqEffectIDs");

			lua_newtable(L);
			for (unsigned int i = 0; i < EQUIP_EFFECT_MAX; ++i)
			{
				lua_pushinteger(L, iter->second.sEffectValue[i]);
				lua_rawseti(L, -2, i + 1);
			}
			lua_setfield(L, -2, "eqEffectValues");

			lua_rawseti(L, -2, iter->first);
		}

		return 1;
	}
	return 0;
}

int getEquipInfo(lua_State *L)
{
    CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -2, "Summoner.EquipModel");
    int equipId = luaL_checkint(L, -1);
    if (NULL != model)
    {
        EquipItemInfo info;
        auto b = model->getEquipInfo(equipId, info);
        if (b)
        {
            lua_newtable(L);
            LuaTools::pushBaseKeyValue(L, info.equipId, "equipId");
            LuaTools::pushBaseKeyValue(L, info.confId, "confId");
			LuaTools::pushBaseKeyValue(L, info.cMainPropNum, "nMainPropNum");
            lua_newtable(L);
            for (int i = 1; i <= EQUIP_EFFECT_MAX; ++i)
            {
                lua_pushinteger(L, info.cEffectID[i - 1]);
                lua_rawseti(L, -2, i);
            }
            lua_setfield(L, -2, "eqEffectIDs");

            lua_newtable(L);
            for (int j = 1; j <= EQUIP_EFFECT_MAX; ++j)
            {
                lua_pushinteger(L, info.sEffectValue[j - 1]);
                lua_rawseti(L, -2, j);
            }
            lua_setfield(L, -2, "eqEffectValues");

            return 1;
        }
    }
    return 0;
}

int newEquipModel(lua_State *L)
{
	CEquipModel* model = new CEquipModel();
	LuaTools::pushClass(L, model, "Summoner.EquipModel");
	return 1;
}

int deleteEquipModel(lua_State *L)
{
	CEquipModel* model = LuaTools::checkClass<CEquipModel>(L, -2, "Summoner.EquipModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}

static const struct luaL_reg funEquip[] =
{
	{ "addEquip", equipAddEquip },
	{ "removeEquip", equipRemoveEquip },
	{ "hasEquip", equipHasEquip },
	{ "getEquipConfId", getEquipConfId },
    { "getEquipInfo", getEquipInfo },
	{ "getEquips", equipGetEquips },
	{ NULL, NULL }
};

bool registeEquipModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.EquipModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funEquip, 0);

	lua_register(luaState, "newEquipModel", newEquipModel);
	lua_register(luaState, "deleteEquipModel", deleteEquipModel);

	return true;
}
