#include "LuaConfigFunc.h"
#include "ConfManager.h"
#include "ConfAnalytic.h"

#include "ConfStage.h"
#include "ConfRole.h"
#include "ConfGuide.h"
#include "ConfFight.h"
#include "ConfHall.h"
#include "ConfUnion.h"
#include "ConfLanguage.h"
#include "ConfGameSetting.h"
#include "ConfMusic.h"
#include "ConfOther.h"
#include "ConfActive.h"
#include "ConfArena.h"
#include "TimeCalcTool.h"
//将Role的common,key_value放入lua栈中
void insertRoleCommonTable(const Role& roleCommon, lua_State* luaState)
{
	lua_newtable(luaState);
	LuaTools::pushBaseKeyValue(luaState, roleCommon.ClassID, "ClassID");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.AnimationID, "AnimationID");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.StatusID, "StatusID");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.AIID, "AIID");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Speed, "Speed");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.FireRange, "FireRange");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.FarFireRange, "FarFireRange");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.PAttack, "PAttack");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.PAttackGrowUp, "PAttackGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MAttack, "MAttack");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MAttackGrowUp, "MAttackGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.HP, "HP");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.HPGrowUp, "HPGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.PGuard, "PGuard");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.PGuardGrowUp, "PGuardGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MGuard, "MGuard");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MGuardGrowUp, "MGuardGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.PPenetrate, "PPenetrate");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MPenetrate, "MPenetrate");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.AttackSpeed, "AttackSpeed");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Rage, "Rage");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.RageRecover, "RageRecover");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MP, "MP");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.MPRecover, "MPRecover");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Strong, "Strong");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.StrongRecover, "StrongRecover");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Haterd, "Haterd");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Defend, "Defend");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Resustance, "Resustance");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Mass, "Mass");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Scale, "Scale");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.EffectScale, "EffectScale");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Vampire, "Vampire");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Rebound, "Rebound");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Miss, "Miss");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Crit, "Crit");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.CritGrowUp, "CritGrowUp");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.CritDamage, "CritDamage");

	LuaTools::pushVec2ToTableField(roleCommon.FireOffset, luaState, "FireOffset");
	LuaTools::pushVec2ToTableField(roleCommon.HeadOffset, luaState, "HeadOffset");
	LuaTools::pushVec2ToTableField(roleCommon.HitOffset, luaState, "HitOffset");

	LuaTools::pushVecIntToTableField(roleCommon.Skill, luaState, "Skill");
	LuaTools::pushVecIntToTableField(roleCommon.HPLine, luaState, "HPLine");

	LuaTools::pushBaseKeyValue(luaState, roleCommon.Name, "Name");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Desc, "Desc");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Race, "Race");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Sex, "Sex");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.AttackType, "AttackType");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Vocation, "Vocation");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.AttackDistance, "AttackDistance");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.Picture, "Picture");
	LuaTools::pushBaseKeyValue(luaState, roleCommon.HeadIcon, "HeadIcon");
	lua_setfield(luaState, -2, "Common");
}

//把CardEnhance表放入lua栈中
void insertCardEnhanceTable(const CardEnhance& cardEnhance, lua_State* luaState, const char* tableName)
{
	lua_newtable(luaState);
	LuaTools::pushBaseKeyValue(luaState, cardEnhance.EnhanceType, "EnhanceType");
	LuaTools::pushBaseKeyValue(luaState, cardEnhance.CDParam, "CDParam");
	LuaTools::pushBaseKeyValue(luaState, cardEnhance.ConsumeParam, "ConsumeParam");
	lua_setfield(luaState, -2, tableName);
}

int getPropLanConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_PROP_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getStageLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_STAGE_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getUILanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_UI_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getBMCLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_BMC_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getBMCSkillLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_BMC_SKILL_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getHSLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_HS_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getHSSkillLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_HS_SKILL_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getStoryLanConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	const char* str = getLanguageString(CONF_STORY_LAN, id);
	if (NULL != str)
	{
		lua_pushstring(l, str);
		return 1;
	}
	return 0;
}

int getTaskLanConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	const char* str = getLanguageString(CONF_TASK_LAN, id);
	if (NULL != str)
	{
		lua_pushstring(l, str);
		return 1;
	}
	return 0;
}

int getAchieveLanConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	const char* str = getLanguageString(CONF_ACHIEVE_LAN, id);
	if (NULL != str)
	{
		lua_pushstring(l, str);
		return 1;
	}
	return 0;
}

int getRoleAttributeLanConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_ROLE_ATTRIBUT_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getErrorCodeConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_ERROR_CODE_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getLoadingTipsConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const char* str = getLanguageString(CONF_LOADING_TIPS_LAN, id);
    if (NULL != str)
    {
        lua_pushstring(l, str);
        return 1;
    }
    return 0;
}

int getLoadingTipsCount(lua_State* l)
{
    CConfLanguage* confLan = dynamic_cast<CConfLanguage*>(
        CConfManager::getInstance()->getConf(CONF_LOADING_TIPS_LAN));
    if (NULL != confLan)
    {
        int count = confLan->getLanCount();
        lua_pushnumber(l, count);
        return 1;
    }

    return 0;
}

int getCameraConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
	CConfCamera* cameraConf = reinterpret_cast<CConfCamera*>(CConfManager::getInstance()->getConf(CONF_CAMERA));
	const CameraConfItem* const item = reinterpret_cast<CameraConfItem*>(cameraConf->getData(id));
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
    LuaTools::pushBaseKeyValue(l, item->MoveX, "MoveX");
    LuaTools::pushBaseKeyValue(l, item->MoveType, "MoveType");
	LuaTools::pushBaseKeyValue(l, item->MoveTime, "MoveTime");
	LuaTools::pushBaseKeyValue(l, item->Scale, "Scale");
	LuaTools::pushBaseKeyValue(l, item->ScaleTime, "ScaleTime");
	LuaTools::pushBaseKeyValue(l, item->Time, "Time");
	LuaTools::pushBaseKeyValue(l, item->NextCamera, "NextCamera");
    return 1;
}

int getSkillConfItem(lua_State* l)
{
	const int skillId = luaL_checkinteger(l, -1);
	auto skillConf = reinterpret_cast<CConfSkill*>(CConfManager::getInstance()->getConf(CONF_SKILL));
	const SkillConfItem* const item = reinterpret_cast<SkillConfItem*>(skillConf->getData(skillId));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->CanBreak, "CanBreak");
	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->CastType, "CastType");
    LuaTools::pushBaseKeyValue(l, item->CastRange, "CastRange");
	LuaTools::pushBaseKeyValue(l, item->LockType, "LockType");
	LuaTools::pushBaseKeyValue(l, item->LockTypePrarm, "LockTypePrarm");
	LuaTools::pushBaseKeyValue(l, item->CD, "CD");
	LuaTools::pushBaseKeyValue(l, item->CostType, "CostType");
	LuaTools::pushBaseKeyValue(l, item->CostTypeParam, "CostTypeParam");
	LuaTools::pushBaseKeyValue(l, item->MaxCast, "MaxCast");
	LuaTools::pushBaseKeyValue(l, item->TargetBulletDelay, "TargetBulletDelay");
	LuaTools::pushBaseKeyValue(l, item->TargetBulletInterval, "TargetBulletInterval");
	LuaTools::pushBaseKeyValue(l, item->PointBulletDelay, "PointBulletDelay");
	LuaTools::pushBaseKeyValue(l, item->PointPointBulletInterval, "PointPointBulletInterval");
	LuaTools::pushBaseKeyValue(l, item->BulletParam, "BulletParam");
	LuaTools::pushBaseKeyValue(l, item->Name, "Name");
	LuaTools::pushBaseKeyValue(l, item->CostDesc1, "CostDesc1");
	LuaTools::pushBaseKeyValue(l, item->CostDesc2, "CostDesc2");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->StateID, "StateID");
	LuaTools::pushBaseKeyValue(l, item->CDParam, "CDParam");
    LuaTools::pushBaseKeyValue(l, item->CastTime, "CastTime");

	LuaTools::pushVecIntToTableField(item->TargetBullet, l, "TargetBullet");
	LuaTools::pushVecIntToTableField(item->PointBullet, l, "PointBullet");
	LuaTools::pushVecIntToTableField(item->Call, l, "Call");
	lua_newtable(l);
	const std::vector<ID_Num>& buff = item->Buff;
	for (unsigned int i = 0; i < buff.size(); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, buff[i].ID, "buffID");
		LuaTools::pushBaseKeyValue(l, buff[i].num, "buffStack");
		lua_setfield(l, -2, String::createWithFormat("%d", i+1)->getCString());
	}
	lua_setfield(l, -2, "Buff");

	LuaTools::pushBaseKeyValue(l, item->IconName, "IconName");
	return 1;
}

int getHeroConfItem(lua_State* l)
{
	const int heroId = luaL_checkinteger(l, -1);
	const HeroConfItem* const item = queryConfHero(heroId);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	insertRoleCommonTable(item->Common, l);

	LuaTools::pushBaseKeyValue(l, item->CrystalSpeedPrarm, "CrystalSpeedPrarm");
	LuaTools::pushBaseKeyValue(l, item->BasicExp, "BasicExp");
	LuaTools::pushBaseKeyValue(l, item->ExpRatio, "ExpRatio");
	LuaTools::pushBaseKeyValue(l, item->RacialRatio, "RacialRatio");

	LuaTools::pushVecIntToTableField(item->PlayerSkill, l, "PlayerSkill");

	insertCardEnhanceTable(item->RaceEnhance, l, "RaceEnhance");
	insertCardEnhanceTable(item->VocationEnhance, l, "VocationEnhance");
	insertCardEnhanceTable(item->SexEnhance, l, "SexEnhance");
	insertCardEnhanceTable(item->AttackTypeEnhance, l, "AttackTypeEnhance");
	return 1;
}

int getSoldierConfItem(lua_State* l)
{
	const int soldierId = luaL_checkinteger(l, -2);
	const int soldierStar = luaL_checkinteger(l, -1);
	const SoldierConfItem* const item = queryConfSoldier(soldierId, soldierStar);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	insertRoleCommonTable(item->Common, l);

	LuaTools::pushBaseKeyValue(l, item->Star, "Star");
	LuaTools::pushBaseKeyValue(l, item->Rare, "Rare");
	LuaTools::pushBaseKeyValue(l, item->Cost, "Cost");
	LuaTools::pushBaseKeyValue(l, item->CD, "CD");
	LuaTools::pushBaseKeyValue(l, item->IsSingo, "IsSingo");

	return 1;
}

int getBossConfItem(lua_State* l)
{
	const int bossId = luaL_checkinteger(l, -1);
	const BossConfItem* const item = queryConfBoss(bossId);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	insertRoleCommonTable(item->Common, l);
	return 1;
}

int getMonsterConfItem(lua_State* l)
{
	const int monsterId = luaL_checkinteger(l, -1);
	const MonsterConfItem* const item = queryConfMonster(monsterId);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	insertRoleCommonTable(item->Common, l);
	return 1;
}

int getCallConfItem(lua_State* l)
{
	const int callId = luaL_checkinteger(l, -1);
	const CallConfItem* const item = queryConfCall(callId);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	insertRoleCommonTable(item->Common, l);
	//call里面没有AttackDistance, 将原有值覆盖掉
	LuaTools::pushBaseKeyValue(l, -1.f, "AttackDistance");

	LuaTools::pushBaseKeyValue(l, item->CardCurrentLevel, "CardCurrentLevel");
	LuaTools::pushBaseKeyValue(l, item->RoleLifeTime, "RoleLifeTime");
	LuaTools::pushBaseKeyValue(l, item->RoleType, "RoleType");
	LuaTools::pushBaseKeyValue(l, item->RoleIdentity, "RoleIdentity");
	LuaTools::pushBaseKeyValue(l, item->RoleMoveType, "RoleMoveType");
	LuaTools::pushBaseKeyValue(l, item->RoleMoveDirection, "RoleMoveDirection");
	return 1;
}

int getEffectConfItem(lua_State* l)
{
	const int effectId = luaL_checkinteger(l, -1);
	const EffectConfItem* const item = queryConfEffect(effectId);

	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ZOrderType, "ZOrderType");
	LuaTools::pushBaseKeyValue(l, item->EffectId, "EffectId");
	LuaTools::pushBaseKeyValue(l, item->Loop, "Loop");
	LuaTools::pushBaseKeyValue(l, item->ZOrder, "ZOrder");
	LuaTools::pushBaseKeyValue(l, item->AudioId, "AudioId");
	LuaTools::pushBaseKeyValue(l, item->ResID, "ResID");
	LuaTools::pushBaseKeyValue(l, item->FadeInTime, "FadeInTime");
	LuaTools::pushBaseKeyValue(l, item->FadeOutTime, "FadeOutTime");
	LuaTools::pushBaseKeyValue(l, item->AnimationSpeed, "AnimationSpeed");

	LuaTools::pushVec2ToTableField(item->Offset, l, "Offset");
	LuaTools::pushVec2ToTableField(item->Scale, l, "Scale");

    LuaTools::pushVecFloatToTableField(item->AddColor, l, "AddColor");

	LuaTools::pushBaseKeyValue(l, item->AnimationName, "AnimationName");
	return 1;
}

int getMapConfItem(lua_State* l)
{
	const int mapID = luaL_checkinteger(l, -1);
	CConfMap* chapterConf = reinterpret_cast<CConfMap*>(CConfManager::getInstance()->getConf(CONF_MAP));
	const MapConfItem* const item = reinterpret_cast<MapConfItem*>(chapterConf->getData(mapID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Sky, "Sky");
	LuaTools::pushBaseKeyValue(l, item->Map, "Map");
	LuaTools::pushBaseKeyValue(l, item->Fog, "Fog");
    LuaTools::pushVecStringToTableField(item->MoodEffect, l, "MoodEffect");
	return 1;
}

int getStageInfoInChapter(lua_State* l)
{
	const int chapterId = luaL_checkinteger(l, -2);
	const int stageId = luaL_checkinteger(l, -1);
	const ChapterConfItem * pChapterConf = queryConfChapter(chapterId);
	if (NULL == pChapterConf)
	{
		lua_pushnil(l);
		return 1;
	}

	for (auto item : pChapterConf->Stages)
	{
		if (item.second.ID[0] == stageId)
		{
			lua_newtable(l);
			LuaTools::pushBaseKeyValue(l, item.second.ID[0], "StageID");
			LuaTools::pushBaseKeyValue(l, item.second.ID[1], "Level");
			LuaTools::pushBaseKeyValue(l, item.second.ID[1], "Title");
			LuaTools::pushBaseKeyValue(l, item.second.Desc, "Desc");
			LuaTools::pushVecIntToTableField(item.second.Drop, l, "Drop");
			LuaTools::pushBaseKeyValue(l, item.second.Thumbnail, "Thumbnail");
			return 1;
		}
	}
	
	lua_pushnil(l);
	return 1;
}

int getStageConfItem(lua_State* l)
{
	const int stageId = luaL_checkinteger(l, -1);
	const StageConfItem* item = queryConfStage(stageId);
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->StageSenceID, "StageSenceID");
	LuaTools::pushBaseKeyValue(l, item->Boss, "Boss");
	LuaTools::pushVecIntToTableField(item->Monsters, l, "Monsters");
	LuaTools::pushBaseKeyValue(l, item->Type, "Type");
	LuaTools::pushVecFloatToTableField(item->TypeParam, l, "TypeParam");
	LuaTools::pushBaseKeyValue(l, item->TimeLimit, "TimeLimit");
	LuaTools::pushVecIntToTableField(item->Win, l, "Win");
	LuaTools::pushVecIntToTableField(item->Fail, l, "Fail");
	LuaTools::pushBaseKeyValue(l, item->WinStar1, "WinStar1");
	LuaTools::pushBaseKeyValue(l, item->WinStar1Param, "WinStar1Param");
	LuaTools::pushBaseKeyValue(l, item->WinStar2, "WinStar2");
	LuaTools::pushBaseKeyValue(l, item->WinStar2Param, "WinStar2Param");
	LuaTools::pushVecIntToTableField(item->ItemDrop, l, "ItemDrop");

	return 1;
}

void pushEquipmentEffect(lua_State *l, const EquipmentEffect& effect)
{
    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, effect.SoliderId, "SoliderId");
    LuaTools::pushBaseKeyValue(l, effect.SoliderStart, "SoliderStart");

    lua_newtable(l);
    int i = 0;
    for (auto &buff : effect.Buff)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, buff.first, "BuffId");
        LuaTools::pushBaseKeyValue(l, buff.second, "BuffNum"); // buff层数
        lua_rawseti(l, -2, i++);
    }
    lua_setfield(l, -2, "Buff");
    lua_setfield(l, -2, "ExtEffect");
}

int getEquipmentConfItem(lua_State* l)
{
	const int equipID = luaL_checkinteger(l, -1);
	auto equipment = reinterpret_cast<CConfEquipment*>(CConfManager::getInstance()->getConf(CONF_EQUIPMENT));
	const EquipmentItem* const item = reinterpret_cast<EquipmentItem*>(equipment->getData(equipID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Suit, "Suit");
	LuaTools::pushBaseKeyValue(l, item->Level, "Level");
	LuaTools::pushBaseKeyValue(l, item->Parts, "Parts");
    LuaTools::pushBaseKeyValue(l, item->Gold, "Gold");
    LuaTools::pushBaseKeyValue(l, item->Rank, "Rank");
    pushEquipmentEffect(l, item->ExtEffect);

    LuaTools::pushVecIntToTableField(item->Vocation, l, "Vocation");

	lua_newtable(l);
	const std::vector<DecompositMaterial>& decomposit = item->Decomposit;
	for (unsigned int i = 0; i < decomposit.size(); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, decomposit[i].Decomposit, "Decomposit");
		LuaTools::pushBaseKeyValue(l, decomposit[i].DecompositionParam, "DecompositionParam");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "Decomposit");

	//lua_newtable(l);
	//const std::vector<SynthMaterial>& synth = item->Synth;
	//for (unsigned int i = 0; i < synth.size(); ++i)
	//{
	//	lua_newtable(l);
	//	LuaTools::pushBaseKeyValue(l, synth[i].Synthesis, "Synthesis");
	//	LuaTools::pushBaseKeyValue(l, synth[i].SynthesisParam, "SynthesisParam");
	//	lua_rawseti(l, -2, i + 1);
	//}
	//lua_setfield(l, -2, "Synth");
	return 1;
}

int getSuitConfItem(lua_State* l)
{
	const int suitID = luaL_checkinteger(l, -1);
	auto suit = reinterpret_cast<CConfSuit*>(CConfManager::getInstance()->getConf(CONF_SUIT));
	const SuitItem* const item = reinterpret_cast<SuitItem*>(suit->getData(suitID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Name, "Name");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	
	int index1 = 1;
	lua_newtable(l);
	for (auto &it : item->Eq)
	{
		lua_pushinteger(l, it.second);
		lua_rawseti(l, -2, it.first);
	}
	lua_setfield(l, -2, "Eq");

	lua_newtable(l);
	for (auto &it : item->SuitAbility)
	{
		lua_newtable(l);
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, it.second.AbilityID, "Ability");
		LuaTools::pushBaseKeyValue(l, it.second.AbilityParam, "AbilityParam");
		LuaTools::pushBaseKeyValue(l, it.second.AbilityDesc, "AbilityDesc");
		lua_setfield(l, -2, "EquipEffect");
		lua_rawseti(l, -2, it.first);
	}
	lua_setfield(l, -2, "Ability");

    lua_newtable(l);
    for (auto &extEffect : item->SuitExtEffect)
    {
        lua_newtable(l);
        pushEquipmentEffect(l, extEffect.second);
        lua_rawseti(l, -2, extEffect.first);
    }
    lua_setfield(l, -2, "SuitExtEffect");

	return 1;
}

int getPropConfItem(lua_State* l)
{
	const int propID = luaL_checkinteger(l, -1);
	auto prop = reinterpret_cast<CConfProp*>(CConfManager::getInstance()->getConf(CONF_ITEM));
	const PropItem* const item = reinterpret_cast<PropItem*>(prop->getData(propID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Name, "Name");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->Quality, "Quality");
	LuaTools::pushBaseKeyValue(l, item->Type, "Type");
	LuaTools::pushBaseKeyValue(l, item->SellPrice, "SellPrice");
	LuaTools::pushBaseKeyValue(l, item->UseLevel, "UseLevel");
	LuaTools::pushBaseKeyValue(l, item->BagLabel, "BagLabel");
	LuaTools::pushBaseKeyValue(l, item->Ratio, "Ratio");
	LuaTools::pushBaseKeyValue(l, item->Icon, "Icon");
	LuaTools::pushVecIntToTableField(item->TypeParam, l, "TypeParam");
	lua_newtable(l);
	for (unsigned int n = 0; n < item->QuickToStage.size(); ++n)
	{
		LuaTools::pushVecIntToArray(item->QuickToStage[n], l);
		lua_rawseti(l, -2, n+1);
	}
	lua_setfield(l, -2, "QuickToStage");
	return 1;
}

int getActivityInstanceItem(lua_State* l)
{
	const int actID = luaL_checkinteger(l, -1);
	auto act = reinterpret_cast<CConfActivityInstance*>(CConfManager::getInstance()->getConf(CONF_ACTIVITY_INSTANCE));
	const ActivityInstanceItem* const item = reinterpret_cast<ActivityInstanceItem*>(act->getData(actID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Title, "Title");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->Place, "Place");
	LuaTools::pushBaseKeyValue(l, item->Show, "Show");
	LuaTools::pushBaseKeyValue(l, item->Type, "Type");
	LuaTools::pushBaseKeyValue(l, item->CompleteTimes, "CompleteTimes");
	LuaTools::pushBaseKeyValue(l, item->BuyTimes, "BuyTimes");
	LuaTools::pushBaseKeyValue(l, item->RecoverType, "RecoverType");
	LuaTools::pushBaseKeyValue(l, item->RecoverParam, "RecoverParam");
	LuaTools::pushBaseKeyValue(l, item->Pic, "Pic");

	LuaTools::pushVecIntToTableField(item->PlaceTime, l, "PlaceTime");
	LuaTools::pushVecIntToTableField(item->StartTime, l, "StartTime");
	LuaTools::pushVecIntToTableField(item->EndTime, l, "EndTime");
	LuaTools::pushVecIntToTableField(item->RecoverTime, l, "RecoverTime");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->Diffcult.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->Diffcult[i].DiffID, "DiffID");
		LuaTools::pushBaseKeyValue(l, item->Diffcult[i].MaxLevel, "MaxLevel");
		LuaTools::pushBaseKeyValue(l, item->Diffcult[i].BasicLevel, "BasicLevel");
		LuaTools::pushBaseKeyValue(l, item->Diffcult[i].ExLevel, "ExLevel");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "Diffcult");

	return 1;
}

int getTaskConfItem(lua_State* l)
{
	const int taskID = luaL_checkinteger(l, -1);
	auto task = reinterpret_cast<CConfTask*>(CConfManager::getInstance()->getConf(CONF_TASK));
	const TaskItem* const item = reinterpret_cast<TaskItem*>(task->getData(taskID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Title, "Title");
	LuaTools::pushBaseKeyValue(l, item->Type, "Type");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->UnlockLv, "UnlockLv");
	LuaTools::pushBaseKeyValue(l, item->Show, "Show");
	LuaTools::pushBaseKeyValue(l, item->FinishCondition, "FinishCondition");
	LuaTools::pushBaseKeyValue(l, item->CompleteTimes, "CompleteTimes");
	LuaTools::pushBaseKeyValue(l, item->Tips, "Tips");
	LuaTools::pushBaseKeyValue(l, item->AwardExp, "AwardExp");
	LuaTools::pushBaseKeyValue(l, item->AwardCoin, "AwardCoin");
	LuaTools::pushBaseKeyValue(l, item->AwardDiamond, "AwardDiamond");
	LuaTools::pushBaseKeyValue(l, item->AwardEnergy, "AwardEnergy");
	LuaTools::pushBaseKeyValue(l, item->AwardFlashcard, "AwardFlashcard");
	LuaTools::pushBaseKeyValue(l, item->TaskReset, "TaskReset");
	LuaTools::pushBaseKeyValue(l, item->Icon, "Icon");
	LuaTools::pushVecIntToTableField(item->QuickTo, l, "QuickTo");
	LuaTools::pushVecIntToTableField(item->FinishParameters, l, "FinishParameters");
	LuaTools::pushVecIntToTableField(item->EndStartID, l, "EndStartID");
	LuaTools::pushVecIntToTableField(item->TaskResetParameters, l, "TaskResetParameters");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->AwardItems.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->AwardItems[i].ID, "ID");
		LuaTools::pushBaseKeyValue(l, item->AwardItems[i].num, "num");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "AwardItems");

	return 1;
}

int getAchieveConfItem(lua_State* l)
{
	const int achieveID = luaL_checkinteger(l, -1);
	auto achieve = reinterpret_cast<CConfAchieve*>(CConfManager::getInstance()->getConf(CONF_ACHIEVE));
	const AchieveItem* const item = reinterpret_cast<AchieveItem*>(achieve->getData(achieveID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Title, "Title");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->UnLockLv, "UnLockLv");
	LuaTools::pushBaseKeyValue(l, item->Show, "Show");
	LuaTools::pushBaseKeyValue(l, item->FinishCondition, "FinishCondition");
	LuaTools::pushBaseKeyValue(l, item->CompleteTimes, "CompleteTimes");
	LuaTools::pushBaseKeyValue(l, item->Tips, "Tips");
	LuaTools::pushBaseKeyValue(l, item->AwardExp, "AwardExp");
	LuaTools::pushBaseKeyValue(l, item->AwardCoin, "AwardCoin");
	LuaTools::pushBaseKeyValue(l, item->AwardDiamond, "AwardDiamond");
	LuaTools::pushBaseKeyValue(l, item->AwardEnergy, "AwardEnergy");
	LuaTools::pushBaseKeyValue(l, item->PosType, "PosType");
	LuaTools::pushBaseKeyValue(l, item->AchieveStar, "AchieveStar");
	LuaTools::pushBaseKeyValue(l, item->CloseDisplay, "CloseDisplay");
	LuaTools::pushBaseKeyValue(l, item->Icon, "Icon");
	LuaTools::pushVecIntToTableField(item->FinishParameters, l, "FinishParameters");
	LuaTools::pushVecIntToTableField(item->EndStartID, l, "EndStartID");

	lua_newtable(l);
    for (int i = 0; i < static_cast<int>(item->AwardItems.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->AwardItems[i].ID, "ID");
		LuaTools::pushBaseKeyValue(l, item->AwardItems[i].num, "num");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "AwardItems");

	return 1;
}

int getGuideConfItem(lua_State* l)
{
	const int guideID = luaL_checkinteger(l, -1);
	auto guide = reinterpret_cast<CConfGuide*>(CConfManager::getInstance()->getConf(CONF_GUIDE));
	const GuideConfItem* const item = reinterpret_cast<GuideConfItem*>(guide->getData(guideID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Listen, "Listen");
    LuaTools::pushVecIntToTableField(item->Nexts, l, "Nexts");
    LuaTools::pushVecIntToTableField(item->Closes, l, "Closes");

	lua_newtable(l);
    for (int i = 0; i < static_cast<int>(item->StartCondition.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->StartCondition[i].Type, "Type");
		LuaTools::pushVecIntToTableField(item->StartCondition[i].Param, l, "Param");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "StartCondition");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->SkipCondition.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->SkipCondition[i].Type, "Type");
		LuaTools::pushVecIntToTableField(item->SkipCondition[i].Param, l, "Param");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "SkipCondition");

	return 1;
}

int getGuideStepConfItem(lua_State* l)
{
	const int stepID = luaL_checkinteger(l, -1);
	const int guideID = luaL_checkinteger(l, -2);
	const GuideStepConfItem* const item = queryConfGuideStep(guideID, stepID);
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->GuideID, "GuideID");
    LuaTools::pushBaseKeyValue(l, item->StepID, "StepID");
    LuaTools::pushBaseKeyValue(l, item->EndType, "EndType");
	LuaTools::pushBaseKeyValue(l, item->IsLock, "IsLock");
	LuaTools::pushBaseKeyValue(l, item->IsPause, "IsPause");
	LuaTools::pushBaseKeyValue(l, item->ButtonID, "ButtonID");
	LuaTools::pushBaseKeyValue(l, item->TipsContent, "TipsContent");
	LuaTools::pushBaseKeyValue(l, item->DialogContent, "DialogContent");
	LuaTools::pushBaseKeyValue(l, item->HeadName, "HeadName");
	LuaTools::pushBaseKeyValue(l, item->CameraID, "CameraID");
	LuaTools::pushBaseKeyValue(l, item->IsHideUI, "IsHideUI");
	LuaTools::pushBaseKeyValue(l, item->EffectType, "EffectType");
	LuaTools::pushBaseKeyValue(l, item->EffectParam, "EffectParam");
	LuaTools::pushBaseKeyValue(l, item->EffectTime, "EffectTime");
    LuaTools::pushBaseKeyValue(l, item->TotalTime, "TotalTime");
    LuaTools::pushBaseKeyValue(l, item->Anchor, "Anchor");
    LuaTools::pushBaseKeyValue(l, item->HighlightRes, "HighlightRes");
    LuaTools::pushBaseKeyValue(l, item->HighlightAni, "HighlightAni");
    LuaTools::pushBaseKeyValue(l, item->TipsRes, "TipsRes");
    LuaTools::pushBaseKeyValue(l, item->TipsAni, "TipsAni");
	LuaTools::pushBaseKeyValue(l, item->DialogRes, "DialogRes");
    LuaTools::pushBaseKeyValue(l, item->DialogAni, "DialogAni");
	LuaTools::pushBaseKeyValue(l, item->HeadRes, "HeadRes");
    LuaTools::pushBaseKeyValue(l, item->HeadTag, "HeadTag");
	LuaTools::pushBaseKeyValue(l, item->BgRes, "BgRes");
	LuaTools::pushBaseKeyValue(l, item->BgTag, "BgTag");
	LuaTools::pushBaseKeyValue(l, item->ShowCSB, "ShowCSB");
	LuaTools::pushBaseKeyValue(l, item->ShowTag, "ShowTag");
	LuaTools::pushVecIntToTableField(item->HighlightPos, l, "HighlightPos");
	LuaTools::pushVecIntToTableField(item->TipsPos, l, "TipsPos");
	LuaTools::pushVecIntToTableField(item->DialogPos, l, "DialogPos");
	LuaTools::pushVecIntToTableField(item->ShowButton, l, "ShowButton");

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->EndCondition.Type, "Type");
	LuaTools::pushVecIntToTableField(item->EndCondition.Param, l, "Param");
	lua_setfield(l, -2, "EndCondition");

	return 1;
}

int getUINodeConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto ui = reinterpret_cast<CConfUINode*>(CConfManager::getInstance()->getConf(CONF_UI_NODE));
	const UINodeConfItem* const item = reinterpret_cast<UINodeConfItem*>(ui->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->NodeID, "NodeID");
	LuaTools::pushBaseKeyValue(l, item->UIID, "UIID");
	LuaTools::pushBaseKeyValue(l, item->NodePath, "NodePath");

	return 1;
}

int getUIStatusConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -2);
	const int count = luaL_checkinteger(l, -1);
	const UIStatusConfItem* const item = queryConfUIStatus(id, count);
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->UIID, "UIID");
	LuaTools::pushBaseKeyValue(l, item->ButtonLockCount, "ButtonLockCount");
	LuaTools::pushBaseKeyValue(l, item->NodeID, "NodeID");
	LuaTools::pushBaseKeyValue(l, item->CSB, "CSB");

	return 1;
}

int getMailConfItem(lua_State* l)
{
	const int mailID = luaL_checkinteger(l, -1);
	auto mail = reinterpret_cast<CConfMail*>(CConfManager::getInstance()->getConf(CONF_MAIL));
	const MailItem* const item = reinterpret_cast<MailItem*>(mail->getData(mailID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Topic, "Topic");
	LuaTools::pushBaseKeyValue(l, item->Sender, "Sender");
	LuaTools::pushBaseKeyValue(l, item->Content, "Content");
	LuaTools::pushBaseKeyValue(l, item->LiveTime, "LiveTime");

	return 1;
}

int getResPathInfoByID(lua_State* l)
{
	int resID = luaL_checkint(l, -1);
	const SResPathItem* conf = queryConfSResInfo(resID);
	if (conf)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, conf->ResType, "ResType");
		LuaTools::pushBaseKeyValue(l, conf->AnimationID, "AnimationID");
		LuaTools::pushBaseKeyValue(l, conf->ResName, "ResName");
		LuaTools::pushBaseKeyValue(l, conf->Path, "Path");
		LuaTools::pushBaseKeyValue(l, conf->AtlasPath, "AtlasPath");
		LuaTools::pushBaseKeyValue(l, conf->Skin, "Skin");
		return 1;
	}
	return 0;
}

int getResIDsByIDStar(lua_State* l)
{
	int roleID = luaL_checkint(l, -2);
	int star = luaL_checkint(l, -1);
	const SRoleResItem* roleResConf = queryConfSRoleResInfo(roleID, star);
	if (roleResConf)
	{
        lua_newtable(l);
        LuaTools::pushVecIntToTableField(roleResConf->ResIDs, l, "ResIDs");
        LuaTools::pushVecStringToTableField(roleResConf->MusicRess, l, "MusicRess");

		return 1;
	}
	return 0;
}

int getSaleSummonerConfItem(lua_State* l)
{
	const int saleID = luaL_checkinteger(l, -1);
	auto sale = reinterpret_cast<CConfSaleSummoner*>(CConfManager::getInstance()->getConf(CONF_SALESUMMONER));
	const SaleSummonerConfItem* const item = reinterpret_cast<SaleSummonerConfItem*>(sale->getData(saleID));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Type, "Type");
	LuaTools::pushBaseKeyValue(l, item->Num, "Num");
	LuaTools::pushBaseKeyValue(l, item->SummonerMusic, "SummonerMusic");
    LuaTools::pushBaseKeyValue(l, item->NewLabel, "NewLabel");
	LuaTools::pushBaseKeyValue(l, item->Head_Name, "Head_Name");
	LuaTools::pushBaseKeyValue(l, item->Bg_Name, "Bg_Name");
    LuaTools::pushBaseKeyValue(l, item->Bg_Texture, "Bg_Texture");
    LuaTools::pushBaseKeyValue(l, item->HeadID, "HeadID");
	return 1;
}

int getIncreasePayConfItem(lua_State* l)
{
	const int buyTiems = luaL_checkinteger(l, -1);
	auto buy = reinterpret_cast<CConfIncreasePaymentPrice*>(CConfManager::getInstance()->getConf(CONF_INCREASE_PAY));
	const IncreasePayItem* const item = reinterpret_cast<IncreasePayItem*>(buy->getData(buyTiems));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->BuyTimes, "BuyTimes");
	LuaTools::pushBaseKeyValue(l, item->GoldCost, "GoldCost");
	LuaTools::pushVecIntToTableField(item->EnergyCost, l, "EnergyCost");
    LuaTools::pushBaseKeyValue(l, item->ChallengeCost, "ChallengeCost");
	LuaTools::pushBaseKeyValue(l, item->TowerTreasureCost, "TowerTreasureCost");
    LuaTools::pushBaseKeyValue(l, item->FreshShopCost, "FreshShopCost");

	return 1;
}

int getRoleZoom(lua_State* l)
{
    const int nRoleID = luaL_checkinteger(l, -1);
    auto zoomConf = reinterpret_cast<CConfZoom*>(CConfManager::getInstance()->getConf(CONF_ROLE_ZOOM));
    if (!zoomConf)
    {
        lua_pushnil(l);
        return 1;
    }

    const ZoomItem* const item = reinterpret_cast<ZoomItem*>(zoomConf->getData(nRoleID));
    if (item)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->RoleID, "RoleID");
		LuaTools::pushBaseKeyValue(l, item->ZoomNumber, "ZoomNumber");
        LuaTools::pushVec2ToTableField(item->StandOffSet, l, "StandOffSet");
		LuaTools::pushBaseKeyValue(l, item->HallZoom, "HallZoom");
        LuaTools::pushBaseKeyValue(l, item->Priority, "Priority");

        return 1;
    }

    return 0;
}

int getConfOutterBonusItem(lua_State* l)
{
    const int bonusID = luaL_checkinteger(l, -1);
    auto setting = reinterpret_cast<CConfOutterBonus*>(CConfManager::getInstance()->getConf(CONF_OUTTER_BONUS));
    auto item = reinterpret_cast<OutterBonusItem*>(setting->getData(bonusID));
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushBaseKeyValue(l, item->Name, "Name");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");

    lua_newtable(l);
    for (unsigned int i = 0; i < item->EnhanceConditions.size(); ++i)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->EnhanceConditions[i].Type, "Type");
        LuaTools::pushVecIntToTableField(item->EnhanceConditions[i].Param, l, "Param");
        lua_rawseti(l, -2, i + 1);
    }
    lua_setfield(l, -2, "EnhanceConditions");

    lua_newtable(l);
    for (unsigned int j = 0; j < item->Enhances.size(); ++j)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->Enhances[j].EffectId, "EffectId");
        LuaTools::pushBaseKeyValue(l, item->Enhances[j].Param, "Param");
        LuaTools::pushBaseKeyValue(l, item->Enhances[j].EffectLanID, "EffectLanID");
        lua_rawseti(l, -2, j + 1);
    }
    lua_setfield(l, -2, "Enhances");

	LuaTools::pushBaseKeyValue(l, item->Pic, "Pic");
	LuaTools::pushBaseKeyValue(l, item->PicS, "PicS");

    return 1;
}

int getConfArenaComputerItem(lua_State* l)
{
    auto conf = reinterpret_cast<CConfArenaScrollBar*>(CConfManager::getInstance()->getConf(CONF_ARENA_SCORLLBAR));
    std::map<int, void*>& datas = conf->getDatas();
    std::map<int, void*>::iterator iter = datas.begin();
    lua_newtable(l);
    int n = 1;
    for (; iter != datas.end(); ++iter)
    {
		auto item = reinterpret_cast<ArenaScollNameItem*>(iter->second);
        if (item)
        {
            lua_newtable(l);
            LuaTools::pushBaseKeyValue(l, item->ComputerID, "ComputerID");
            LuaTools::pushBaseKeyValue(l, item->ComputerName, "ComputerName");
            LuaTools::pushBaseKeyValue(l, item->ComputerPic, "ComputerPic");
            lua_rawseti(l, -2, n++);
        }
    }

    return 1;
}

int getConfAnimationPlayOrderItem(lua_State* l)
{
    const int resID = luaL_checkinteger(l, -1);
	auto item = queryConfAnimationPlayOrder(resID);
    if (!item)
	{
		lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ResID, "resID");

	lua_newtable(l);
	for (unsigned int i = 0; i < item->VecAnimations.size(); ++i)
	{
		lua_newtable(l);
		for (unsigned int j = 0; j < item->VecAnimations[i].size(); ++j)
		{
			lua_pushstring(l, item->VecAnimations[i][j].c_str());
			lua_rawseti(l, -2, j + 1);
		}
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "vecAnimations");

    return 1;
}

int getConfHallStandingItem(lua_State* l)
{
    const int order = luaL_checkinteger(l, -1);
    auto item = queryConfHallStanding(order);
    if (item)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->SpotOrder, "SpotOrder");
        LuaTools::pushVec2ToTableField(item->Position, l, "Position");
        LuaTools::pushBaseKeyValue(l, item->ZOrder, "ZOrder");

        return 1;
    }

    return 0;
}

int getEquipBaseAttriteCount(lua_State* l)
{
    const int eqConfID = luaL_checkinteger(l, -1);
	auto item = queryConfEquipCreat(eqConfID);
    if (item)
    {
		lua_pushinteger(l, item->VectBaseProp.size());
        return 1;
    }

    return 0;
}

int getEquipPropCreateConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = queryConfEquipCreat(id);
    if (conf)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, conf->nEquipID, "nEquipID");

        lua_newtable(l);
        const std::vector<EffectData>& baseProp = conf->VectBaseProp;
        for (unsigned int i = 0; i < baseProp.size(); ++i)
        {
            lua_newtable(l);
            LuaTools::pushBaseKeyValue(l, baseProp[i].nEffectID, "nEffectID");
            LuaTools::pushBaseKeyValue(l, baseProp[i].nMinValue, "nMinValue");
            LuaTools::pushBaseKeyValue(l, baseProp[i].nMaxValue, "nMaxValue");
            LuaTools::pushBaseKeyValue(l, baseProp[i].nWeight, "nWeight");
            lua_rawseti(l, -2, i + 1);
        }
        lua_setfield(l, -2, "BaseProp");

        lua_newtable(l);
        const std::vector<EffectData>& extraProp = conf->VectExtraProp;
        for (unsigned int i = 0; i < extraProp.size(); ++i)
        {
            lua_newtable(l);
            LuaTools::pushBaseKeyValue(l, extraProp[i].nEffectID, "nEffectID");
            LuaTools::pushBaseKeyValue(l, extraProp[i].nMinValue, "nMinValue");
            LuaTools::pushBaseKeyValue(l, extraProp[i].nMaxValue, "nMaxValue");
            LuaTools::pushBaseKeyValue(l, extraProp[i].nWeight, "nWeight");
            lua_rawseti(l, -2, i + 1);
        }
        lua_setfield(l, -2, "ExtraProp");

        return 1;
    }
    return 0;
}

int getEquipPropMaxCount(lua_State* l)
{
    const int quality = luaL_checkinteger(l, -1);
    auto count = queryConfQualityProp(quality);
    lua_pushinteger(l, count);

    return 1;
}

int getTalentConf(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    const STalentData* data = queryTalentData(id);

    if (data)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, data->TalentID, "TalentID");
        LuaTools::pushBaseKeyValue(l, data->TalentName, "TalentName");
        LuaTools::pushBaseKeyValue(l, data->TalentDes, "TalentDes");
        LuaTools::pushBaseKeyValue(l, data->TalentPic, "TalentPic");
        return 1;
    }
    else
    {
        return 0;
    }
}

int getUnionLevelConfItem(lua_State* l)
{
    const int lv = luaL_checkinteger(l, -1);

    const UnionLevelItem* item = queryConfUnionLevel(lv);
    if (item)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->UnionLv, "UnionLv");
        LuaTools::pushBaseKeyValue(l, item->ViceChairmanNum, "ViceChairmanNum");
        LuaTools::pushBaseKeyValue(l, item->MemberLimit, "MemberLimit");
        LuaTools::pushBaseKeyValue(l, item->ActiveMin, "ActiveMin");
        LuaTools::pushBaseKeyValue(l, item->ActiveReward, "ActiveReward");
        LuaTools::pushBaseKeyValue(l, item->RewardID, "RewardID");
        LuaTools::pushBaseKeyValue(l, item->ActiveSReward, "ActiveSReward");
        LuaTools::pushBaseKeyValue(l, item->SRewardID, "SRewardID");
        LuaTools::pushBaseKeyValue(l, item->UpLevelCost, "UpLevelCost");
        LuaTools::pushBaseKeyValue(l, item->DownLevelCost, "DownLevelCost");
        LuaTools::pushBaseKeyValue(l, item->UnActiveReduce, "UnActiveReduce");
        return 1;
    }
    return 0;
}

int getUnionConfItem(lua_State* l)
{
   const UnionItem item = queryConfUnion();
   lua_newtable(l);
   LuaTools::pushBaseKeyValue(l, item.UnLockLv, "UnLockLv");
   LuaTools::pushBaseKeyValue(l, item.CostCoin, "CostCoin");
   LuaTools::pushBaseKeyValue(l, item.AuditTime, "AuditTime");
   LuaTools::pushBaseKeyValue(l, item.ApplyCD, "ApplyCD");
   LuaTools::pushBaseKeyValue(l, item.ApplyCount, "ApplyCount");
   LuaTools::pushBaseKeyValue(l, item.ChangeNameCost, "ChangeNameCost");
   return 1;
}

int getUnionBadgeConfItem(lua_State* l)
{
    CConfUnionBadge* conf = dynamic_cast<CConfUnionBadge*>(
        CConfManager::getInstance()->getConf(CONF_UNIONBADGE));

    std::map<int, std::string>& mapBadges = conf->getBadges();

    lua_newtable(l);
    for (auto iter = mapBadges.begin(); iter != mapBadges.end(); ++iter)
    {
        lua_pushstring(l, iter->second.c_str());
        lua_rawseti(l, -2, iter->first);
    }
    return 1;
}

int getTowerSetting(lua_State* l)
{
    const int count = luaL_checkinteger(l, -1);
	auto item = queryConfTowerSetting();
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }
	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->FirstCrystal, "FirstCrystal");
    return 1;
}

int getChapterSetting(lua_State* l)
{
    const int count = luaL_checkinteger(l, -1);
	auto setting = reinterpret_cast<CConfChapterSetting*>(CConfManager::getInstance()->getConf(CONF_CHAPTER_SETTING));
    const ChapterSettingItem& item = setting->getData();

    lua_newtable(l);

    LuaTools::pushBaseKeyValue(l, item.NormalLastChapter, "NormalLastChapter");
    LuaTools::pushBaseKeyValue(l, item.EliteLastChapter, "EliteLastChapter");

    return 1;
}

int getChatSetting(lua_State* l)
{
    auto setting = reinterpret_cast<CConfChatSetting*>(CConfManager::getInstance()->getConf(CONF_CHAT_SETTING));
    const ChatSettingItem& item = setting->getData();

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item.ChatUnlockLv, "ChatUnlockLv");
    LuaTools::pushBaseKeyValue(l, item.RecoverTimes, "RecoverTimes");
    LuaTools::pushBaseKeyValue(l, item.SpeedTimesLimit, "SpeedTimesLimit");
    LuaTools::pushBaseKeyValue(l, item.WordNumLimit, "WordNumLimit");
    LuaTools::pushBaseKeyValue(l, item.IntervalTime, "IntervalTime");
    LuaTools::pushVecIntToTableField(item.RecoverTime, l, "RecoverTime");
    
    return 1;
}

int getSystemHeadIconItem(lua_State* l)
{
    auto systemHeadIcon = reinterpret_cast<CConfSystemHeadIcon*>(CConfManager::getInstance()->getConf(CONF_SYSTEM_HEAD_ICON));
    const std::map<int, SSystemHeadIconItem>& item = systemHeadIcon->getAllHeadIcon();

    lua_newtable(l);
	for (auto& iter : item)
	{
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, iter.second.IconName, "IconName");
        LuaTools::pushBaseKeyValue(l, iter.second.IconTips, "IconTips");
		lua_rawseti(l, -2, iter.first);
	}
    return 1;
}

int getItemLevelSettingItem(lua_State* l)
{
    const int quality = luaL_checkinteger(l, -1);
    auto setting = reinterpret_cast<CConfItemLevelSetting*>(CConfManager::getInstance()->getConf(CONF_ITEM_LEVEL_SETTING));
    const ItemLevelSettingItem* const item = reinterpret_cast<ItemLevelSettingItem*>(setting->getData(quality));
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item->ItemLevel, "ItemLevel");
    LuaTools::pushBaseKeyValue(l, item->ItemFrame, "ItemFrame");
	LuaTools::pushVecIntToTableField(item->Color, l, "Color");

    return 1;
}

int getTimeRecoverSetting(lua_State* l)
{
	auto setting = reinterpret_cast<CConfTimeRecover*>(CConfManager::getInstance()->getConf(CONF_TIMERECOVER));
	const TimeRecoverItem *item = reinterpret_cast<TimeRecoverItem*>(setting->getData(1));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->AllTimeReset, "AllTimeReset");
	return 1;
}

int getArenaRankItem(lua_State* l)
{
	const int rankScore = luaL_checkinteger(l, -1);
	auto setting = reinterpret_cast<CConfArenaRank*>(CConfManager::getInstance()->getConf(CONF_ARENA_RANK));
	std::map<int, void*>& mapData = setting->getDatas();
	std::map<int, void*>::iterator iter = mapData.begin();
	for (; iter != mapData.end(); ++iter)
	{
		const ArenaRankItem* item = reinterpret_cast<ArenaRankItem*>(iter->second);
		if (item)
		{
			if (item->GNRank.size() > 1
				&& (rankScore >= item->GNRank[0] && item->GNRank[1] > rankScore))
			{
				lua_newtable(l);
				LuaTools::pushBaseKeyValue(l, item->ArenaLevel, "ArenaLevel");
				LuaTools::pushBaseKeyValue(l, item->MMR_K, "MMR_K");
				LuaTools::pushBaseKeyValue(l, item->MMR_kx, "MMR_kx");
				LuaTools::pushBaseKeyValue(l, item->Arena_K, "Arena_K");
				LuaTools::pushBaseKeyValue(l, item->GNPic, "GNPic");
				LuaTools::pushVecIntToTableField(item->MMR_Range, l, "MMRRange");
				LuaTools::pushVecIntToTableField(item->GNRank, l, "GNRank");
				return 1;
			}
		}
	}

	lua_pushnil(l);
	return 1;
}

void setArenaTaskItem(lua_State* l, ArenaRewardItem *item, const char *name)
{
    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item->Reward_ID, "RewardID");
    LuaTools::pushBaseKeyValue(l, item->Reward_Type, "RewardType");
    LuaTools::pushBaseKeyValue(l, item->WinNum_Text, "WinNumText");
    LuaTools::pushBaseKeyValue(l, item->Award_Coin, "AwardCoin");
    LuaTools::pushBaseKeyValue(l, item->Award_Diamond, "AwardDiamond");
    LuaTools::pushBaseKeyValue(l, item->Award_PvpCoin, "AwardPvpCoin");
	LuaTools::pushBaseKeyValue(l, item->Award_Flashcard, "AwardFlashcard");
    LuaTools::pushBaseKeyValue(l, item->WinNum_Pic, "WinNumPic");
    LuaTools::pushVecIntToTableField(item->Type_Parameter, l, "TypeParameter");
    LuaTools::pushVecIntToTableField(item->AwardPic, l, "AwardPic");
	LuaTools::pushBaseKeyValue(l, item->Award_Items, "AwardItems");
    lua_setfield(l, -2, name);
}

int getArenaRankTask(lua_State* l)
{
    auto setting = reinterpret_cast<CConfArenaReward*>(CConfManager::getInstance()->getConf(CONF_ARENA_REWARD));
    if (setting)
    {
        lua_newtable(l);
        if (setting->m_pDayBattleItem)//日战斗场次奖励
        {
            setArenaTaskItem(l, setting->m_pDayBattleItem, "DayBattleItem");
        }

        if (setting->m_pDayContinusWinItem)//日连胜场奖励
        {
            setArenaTaskItem(l, setting->m_pDayContinusWinItem, "DayContinusWinItem");
        }

        if (setting->m_pDayWinItem)//日累计胜场奖励
        {
            setArenaTaskItem(l, setting->m_pDayWinItem, "DayWinItem");
        }

        return 1;
    }

    lua_pushnil(l);
    return 1;
}

int getArenaTypeRankReward(lua_State* l)
{
    const int rank = luaL_checkinteger(l, -2);
    const int rewardType = luaL_checkinteger(l, -1);
    auto setting = reinterpret_cast<CConfArenaReward*>(CConfManager::getInstance()->getConf(CONF_ARENA_REWARD));
    if (setting)
    {
        std::vector<ArenaRewardItem *> vecRewardItems;
        // 公平竞技
        if (2 == rewardType)
        {
            vecRewardItems = setting->m_RankRewards;
        }
        // 锦标赛
        else if (3 == rewardType)
        {
            vecRewardItems = setting->m_CampionRankRewards;
        }
        else
        {
            return 0;
        }
        
        std::vector<ArenaRewardItem *>::iterator iter = vecRewardItems.begin();
        for (; iter != vecRewardItems.end(); ++iter)
        {
            ArenaRewardItem *item = *iter;
            if (NULL == item)
            {
                continue;
            }

            if (rewardType == item->Reward_Type)
            {
                if (item->Type_Parameter.size() > 1
                    && rank >= item->Type_Parameter[0] && item->Type_Parameter[1] >= rank)
                {
                    lua_newtable(l);
                    setArenaTaskItem(l, item, "RankTypeReward");

                    return 1;
                }
            }
        }
    }

    lua_pushnil(l);
    return 1;
}

int getArenaRankReward(lua_State* l)
{
    const int rewardID = luaL_checkinteger(l, -1);
    auto setting = reinterpret_cast<CConfArenaReward*>(CConfManager::getInstance()->getConf(CONF_ARENA_REWARD));
    if (setting)
    {
        ArenaRewardItem *item = reinterpret_cast<ArenaRewardItem *>(setting->getData(rewardID));
        if (item)
        {
            lua_newtable(l);
            setArenaTaskItem(l, item, "RankReward");

            return 1;
        }
    }

    lua_pushnil(l);
    return 1;
}

int getArenaTrainings(lua_State* l)
{
    auto trainings = reinterpret_cast<CConfArenaTraining*>(CConfManager::getInstance()->getConf(CONF_ARENA_TRAINING));
    if (trainings)
    {
        lua_newtable(l);
        for (auto& item : trainings->getArenaTrainings())
        {
            lua_pushinteger(l, item.second);
            lua_rawseti(l, -2, item.first);
        }

        return 1;
    }

    lua_pushnil(l);
    return 1;
}

int getArenaLevel(lua_State* l)
{
    auto level = reinterpret_cast<CConfArenaLevel*>(CConfManager::getInstance()->getConf(CONF_ARENA_LEVEL));
    if (level)
    {
        lua_newtable(l);
        for (auto& item : level->getArenaLevels())
        {
            lua_pushinteger(l, item.second);
            lua_rawseti(l, -2, item.first);
        }

        return 1;
    }

    lua_pushnil(l);
    return 1;
}

int getArenaSetting(lua_State* l)
{
    auto setting = reinterpret_cast<CConfPvpSetting*>(CConfManager::getInstance()->getConf(CONF_PVP_SETTING));
    if (setting)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, setting->m_PvpSetting.GradingNum, "GradingNum");
        LuaTools::pushVecIntToTableField(setting->m_PvpSetting.ArenaDay, l, "ArenaDay");
        LuaTools::pushVecIntToTableField(setting->m_PvpSetting.ArenaTime, l, "ArenaTime");

        return 1;
    }

    lua_pushnil(l);
    return 1;
}

int getUIBgMusic(lua_State* l)
{
    const int uiID = luaL_checkinteger(l, -1);
    auto bgMusicSetting = queryConfBgMusicSetting(uiID);
    if (NULL == bgMusicSetting)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, bgMusicSetting->BgMusicID, "BgMusicID");
    LuaTools::pushBaseKeyValue(l, bgMusicSetting->EffectID, "EffectID");
    LuaTools::pushVecStringToTableField(bgMusicSetting->MoodEffect, l, "MoodEffect");
    return 1;
}

int getBgMusic(lua_State* l)
{
    const int bgmID = luaL_checkinteger(l, -1);
    auto item = queryConfBgMusic(bgmID);
    if (NULL == item)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item->BgMusicID, "BgMusicID");
    LuaTools::pushBaseKeyValue(l, item->FadeInTime, "FadeInTime");
    LuaTools::pushBaseKeyValue(l, item->FadeOutTime, "FadeOutTime");
    LuaTools::pushBaseKeyValue(l, item->IsRepeate, "IsRepeate");
    LuaTools::pushBaseKeyValue(l, item->FileName, "FileName");
    return 1;
}

int getButtonEffectPath(lua_State* l)
{
    const char* btnName = luaL_checkstring(l, -1);
    auto btnEffectItem = reinterpret_cast<CConfUIButtonEffect*>(CConfManager::getInstance()->getConf(CONF_BUTTON_EFFECT));
    if (NULL != btnEffectItem)
    {
        int nEffectID = btnEffectItem->getButtonEffectId(btnName);
        auto item = reinterpret_cast<CConfUISoundEffect*>(CConfManager::getInstance()->getConf(CONF_SOUND_EFFECT));
        if (NULL != item)
        {
            std::string path = "";
            if (item->getEffectPath(nEffectID, path))
            {
                lua_pushstring(l, path.c_str());
                return 1;
            }
        }
    }

    lua_pushnil(l);
    return 1;
}

int getUISoundEffectPath(lua_State* l)
{
    const int effectId = luaL_checkinteger(l, -1);
    auto item = reinterpret_cast<CConfUISoundEffect*>(CConfManager::getInstance()->getConf(CONF_SOUND_EFFECT));
    if (NULL != item)
    {
        std::string path = "";
        if (item->getEffectPath(effectId, path))
        {
            lua_pushstring(l, path.c_str());
            return 1;
        }
    }

    lua_pushnil(l);
    return 1;
}

int getCameraItemList(lua_State* l)
{
	CConfCamera* cameraConf = reinterpret_cast<CConfCamera*>(CConfManager::getInstance()->getConf(CONF_CAMERA));
    LuaTools::pushMapKeys(cameraConf->getDatas());
    return 1;
}

int getHeroItemList(lua_State* l)
{
	CConfHero* heroConf = reinterpret_cast<CConfHero*>(CConfManager::getInstance()->getConf(CONF_HERO));
	LuaTools::pushMapKeys(heroConf->getDatas());
	return 1;
}

int getSoldierItemList(lua_State* l)
{
	CConfSoldier* soliderConf = reinterpret_cast<CConfSoldier*>(CConfManager::getInstance()->getConf(CONF_SOLDIER));

	int index = 1;
	lua_newtable(l);
	for (auto item : soliderConf->getSoldiersConfig())
	{
		lua_newtable(l);
		LuaTools::pushMapKeys(item.second);
		lua_rawseti(l, -2, item.first);
		lua_rawseti(l, -2, index++);
	}

	return 1;
}

int getBossItemList(lua_State* l)
{
	CConfBoss* bossConf = reinterpret_cast<CConfBoss*>(CConfManager::getInstance()->getConf(CONF_BOSS));
	LuaTools::pushMapKeys(bossConf->getDatas());
	return 1;
}

int getMonsterItemList(lua_State* l)
{
	CConfMonster* monsterConf = reinterpret_cast<CConfMonster*>(CConfManager::getInstance()->getConf(CONF_MONSTER));
	LuaTools::pushMapKeys(monsterConf->getDatas());
	return 1;
}

int getCallItemList(lua_State* l)
{
	CConfCall* callConf = reinterpret_cast<CConfCall*>(CConfManager::getInstance()->getConf(CONF_CALL));
	LuaTools::pushMapKeys(callConf->getDatas());
	return 1;
}

int getMapItemList(lua_State* l)
{
	CConfMap* chapterConf = reinterpret_cast<CConfMap*>(CConfManager::getInstance()->getConf(CONF_MAP));
	LuaTools::pushMapKeys(chapterConf->getDatas());
	return 1;
}

int getStageItemList(lua_State* l)
{
	CConfStage *stageConf = dynamic_cast<CConfStage*>(CConfManager::getInstance()->getConf(CONF_STAGE));
	LuaTools::pushMapKeys(stageConf->getDatas());
	return 1;
}

int getEquipmentItemList(lua_State* l)
{
	auto equipment = reinterpret_cast<CConfEquipment*>(CConfManager::getInstance()->getConf(CONF_EQUIPMENT));
	LuaTools::pushMapKeys(equipment->getDatas());
	return 1;
}

int getSuitItemList(lua_State* l)
{
	auto suit = reinterpret_cast<CConfSuit*>(CConfManager::getInstance()->getConf(CONF_SUIT));
	LuaTools::pushMapKeys(suit->getDatas());
	return 1;
}

int getPropItemList(lua_State* l)
{
	auto prop = reinterpret_cast<CConfProp*>(CConfManager::getInstance()->getConf(CONF_ITEM));
	LuaTools::pushMapKeys(prop->getDatas());
	return 1;
}

int getActivityInstanceList(lua_State* l)
{
	auto act = reinterpret_cast<CConfActivityInstance*>(CConfManager::getInstance()->getConf(CONF_ACTIVITY_INSTANCE));
	LuaTools::pushMapKeys(act->getDatas());
	return 1;
}

int getDropPropItem(lua_State* l)
{
	int dropId = luaL_checkinteger(l, -1);
	auto pItem = queryConfDropProp(dropId);
	if (NULL != pItem)
	{
		lua_newtable(l);

		LuaTools::pushBaseKeyValue(l, pItem->DropRuleID, "DropRuleID");
		LuaTools::pushBaseKeyValue(l, pItem->IsCrit, "IsCrit");
		LuaTools::pushBaseKeyValue(l, pItem->IsRepeat, "IsRepeat");
		LuaTools::pushBaseKeyValue(l, pItem->IsRepeat, "IsRepeat");

		LuaTools::pushVecIntToTableField(pItem->MeanwhileDropNum, l, "MeanwhileDropNum");
		lua_newtable(l);
		for (int i = 0; i < static_cast<int>(pItem->DropCurrencys.size()); ++i)
		{
			lua_newtable(l);
			LuaTools::pushBaseKeyValue(l, pItem->DropCurrencys[i].CurrencyId, "CurrencyId");
			LuaTools::pushBaseKeyValue(l, pItem->DropCurrencys[i].LowerLimit, "LowerLimit");
			LuaTools::pushBaseKeyValue(l, pItem->DropCurrencys[i].UpperLimit, "UpperLimit");
			lua_rawseti(l, -2, i + 1);
		}
		lua_setfield(l, -2, "DropCurrencys");

		lua_newtable(l);
		for (int i = 0; i < static_cast<int>(pItem->DropIDs.size()); ++i)
		{
			lua_newtable(l);
			LuaTools::pushBaseKeyValue(l, pItem->DropIDs[i].DropID, "DropID");
			LuaTools::pushVecIntToTableField(pItem->DropIDs[i].DropNum, l, "DropNum");
			LuaTools::pushBaseKeyValue(l, pItem->DropIDs[i].DropRate, "DropRate");
			lua_rawseti(l, -2, i + 1);
		}
		lua_setfield(l, -2, "DropIDs");
		return 1;
	}
	return 0;
}

int getStageSceneConfItem(lua_State* l)
{
    int id  = luaL_checkinteger(l, -1);
    auto item = queryConfStageScene(id);
    if (item)
    {
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, item->FrontScene_ccs, "FrontScene_ccs");
        LuaTools::pushBaseKeyValue(l, item->FightScene_ccs, "FightScene_ccs");
        LuaTools::pushBaseKeyValue(l, item->BgScene_ccs, "BgScene_ccs");
        LuaTools::pushBaseKeyValue(l, item->FarScene_ccs, "FarScene_ccs");
        return 1;
    }
    return 0;
}

// int getDropItemList(lua_State* l)
// {
// 	auto prop = reinterpret_cast<CConfStageDrop*>(CConfManager::getInstance()->getConf(CONF_DROP));
// 	LuaTools::pushMapKeys(prop->getDatas());
// 	return 1;
// }

int	getTaskItemList(lua_State* l)
{
	auto task = reinterpret_cast<CConfTask*>(CConfManager::getInstance()->getConf(CONF_TASK));
	LuaTools::pushMapKeys(task->getDatas());
	return 1;
}

int getAchieveItemList(lua_State* l)
{
	auto achieve = reinterpret_cast<CConfAchieve*>(CConfManager::getInstance()->getConf(CONF_ACHIEVE));
	LuaTools::pushMapKeys(achieve->getDatas());
	return 1;
}

int getGuideItemList(lua_State* l)
{
	auto guide = reinterpret_cast<CConfGuide*>(CConfManager::getInstance()->getConf(CONF_GUIDE));
	LuaTools::pushMapKeys(guide->getDatas());
	return 1;
}

int getGuideStepItemList(lua_State* l)
{
	int guideID = luaL_checkinteger(l, -1);
	auto data = reinterpret_cast<CConfGuideStep*>(CConfManager::getInstance()->getConf(CONF_GUIDE_STEP));
	auto steps = data->getSteps(guideID);
	if (nullptr == steps)
	{
		return 0;
	}
	LuaTools::pushMapKeys(*steps);
	return 1;
}

int getUINodeItemList(lua_State* l)
{
	auto ui = reinterpret_cast<CConfUINode*>(CConfManager::getInstance()->getConf(CONF_UI_NODE));
	LuaTools::pushMapKeys(ui->getDatas());
	return 1;
}

int getUIStatusItemList(lua_State* l)
{
	auto ui = reinterpret_cast<CConfUIStatus*>(CConfManager::getInstance()->getConf(CONF_UI_STATUS));
	LuaTools::pushMapKeys(ui->getDatas());
	return 1;
}

int getGuideBattleConfItem(lua_State* l)
{
    auto conf = reinterpret_cast<CConfGuideBattle*>(CConfManager::getInstance()->getConf(CONF_GUIDE_BATTLE));
    if (conf == NULL)
    {
        return 0;
    }
    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, conf->getConfItem()->StageId, "StageId");
    LuaTools::pushBaseKeyValue(l, conf->getConfItem()->HeroId, "HeroId");
    LuaTools::pushBaseKeyValue(l, conf->getConfItem()->HeroLv, "HeroLv");
    // soldiers
    lua_newtable(l);
    for (unsigned int i = 0; i < conf->getConfItem()->Soliders.size(); ++i)
    {
        // soldierInfo
        lua_newtable(l);
        LuaTools::pushBaseKeyValue(l, conf->getConfItem()->Soliders[i].SoliderId, "SoliderId");
        LuaTools::pushBaseKeyValue(l, conf->getConfItem()->Soliders[i].SoliderLevel, "SoliderLevel");
        LuaTools::pushBaseKeyValue(l, conf->getConfItem()->Soliders[i].SoliderStar, "SoliderStar");
        // 将soldierInfo 设置到 soldiers中
        lua_rawseti(l, -2, i + 1);
    }
    // 将soldiers设置到root中
    lua_setfield(l, -2, "Soliders");
    return 1;
}

int getSaleSummonerItemList(lua_State* l)
{
	auto sale = reinterpret_cast<CConfSaleSummoner*>(CConfManager::getInstance()->getConf(CONF_SALESUMMONER));
	LuaTools::pushMapKeys(sale->getDatas());
	return 1;
}

int getIncreasePayItemList(lua_State* l)
{
	auto buy = reinterpret_cast<CConfIncreasePaymentPrice*>(CConfManager::getInstance()->getConf(CONF_INCREASE_PAY));
	LuaTools::pushMapKeys(buy->getDatas());
	return 1;
}

int getGoldTestItemList(lua_State* l)
{
	auto conf = reinterpret_cast<CConfGoldTest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST));
	LuaTools::pushMapKeys(conf->getDatas());
	return 1;
}

int getGoldTestChestItemList(lua_State* l)
{
	auto conf = reinterpret_cast<CConfGoldTestChest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST_CHEST));
	LuaTools::pushMapKeys(conf->getDatas());
	return 1;
}

int getHeroTestItemList(lua_State* l)
{
	auto conf = reinterpret_cast<CConfHeroTest*>(CConfManager::getInstance()->getConf(CONF_HERO_TEST));
	LuaTools::pushMapKeys(conf->getDatas());
	return 1;
}

int getTowerFloorItemList(lua_State* l)
{
    auto conf = reinterpret_cast<CConfTowerFloor*>(CConfManager::getInstance()->getConf(CONF_TOWER_FLOOR));
    LuaTools::pushMapKeys(conf->getDatas());
    return 1;
}

int getTowerBuffItemList(lua_State* l)
{
	auto conf = reinterpret_cast<CConfTowerBuff*>(CConfManager::getInstance()->getConf(CONF_TOWER_BUFF));
	LuaTools::pushMapKeys(conf->getDatas());
	return 1;
}

int getTowerRankItemList(lua_State* l)
{
	auto conf = reinterpret_cast<CConfTowerRank*>(CConfManager::getInstance()->getConf(CONF_TOWER_RANK));
	LuaTools::pushMapKeys(conf->getDatas());
	return 1;
}

int getUserMaxLevel(lua_State* l)
{
    auto userLvConf = reinterpret_cast<CConfUserLevelSetting*>(
		CConfManager::getInstance()->getConf(CONF_USER_LEVEL_SETTING));
    if (userLvConf)
    {
        int nUserMaxLv = userLvConf->GetUserMaxLv();
        lua_pushinteger(l, nUserMaxLv);
        return 1;
    }
    
    return 0;
}

int getPreAchieveID(lua_State* l)
{
    const int nCurAchieveID = luaL_checkinteger(l, -1);
    auto achieveConf = reinterpret_cast<CConfAchieve*>(CConfManager::getInstance()->getConf(CONF_ACHIEVE));
    if (achieveConf)
    {
        int nPreAchieveID = achieveConf->getPreAchieveID(nCurAchieveID);
        lua_pushinteger(l, nPreAchieveID);
        return 1;
    }

    return 0;
}

int getNextTimeStampToLua(lua_State* l)
{
	const int prev = luaL_checkinteger(l, -3);
	const int nextMin = luaL_checkinteger(l, -2);
	const int nextHour = luaL_checkinteger(l, -1);

	int time = CTimeCalcTool::getNextTimeStamp(prev, nextMin, nextHour);
	lua_pushinteger(l, time);
	return 1;
}

int getWNextTimeStampToLua(lua_State* l)
{
	const int prev = luaL_checkinteger(l, -4);
	const int nextMin = luaL_checkinteger(l, -3);
	const int nextHour = luaL_checkinteger(l, -2);
	const int wDay = luaL_checkinteger(l, -1);

	int time = CTimeCalcTool::getWNextTimeStamp(prev, nextMin, nextHour, wDay);
	lua_pushinteger(l, time);
	return 1;
}
////////////////////////////////gameSetting//////////////////////////////////////////

int getCardGambleSettingConfItem(lua_State* l)
{
	CardGambleSettingItem item = queryConfCardGambleSetting();

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item.DiamondCardGamblePrice, "DiamondCardGamblePrice");
	LuaTools::pushBaseKeyValue(l, item.DiamondCardGamble10Price, "DiamondCardGamble10Price");
	LuaTools::pushBaseKeyValue(l, item.exchangeRatio, "exchangeRatio");
	LuaTools::pushVecIntToTableField(item.SoldierLvUpScuccessRate, l, "SoldierLvUpScuccessRate");	
	LuaTools::pushVecIntToTableField(item.FirstDrawCard, l, "FirstDrawCard");
	lua_newtable(l);
	for (auto &it : item.RareRatios)
	{
		lua_newtable(l);
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, it.second.Probability, "Probability");
		LuaTools::pushBaseKeyValue(l, it.second.Ratio, "Ratio");
		lua_setfield(l, -2, "Prob");
		lua_rawseti(l, -2, it.first);
	}
	lua_setfield(l, -2, "RareRatios");
	return 1;
}

int getIconSettingConfItem(lua_State* l)
{
	auto pConf = reinterpret_cast<CConfIconSetting*>(CConfManager::getInstance()->getConf(CONF_ICON_SETTING));
	if (!pConf)
	{
		lua_pushnil(l);
		return 1;
	}
	auto item = pConf->getData();

	lua_newtable(l);

	lua_newtable(l);
	for (unsigned int i = 0; i < item.EqIcon.size(); ++i)
	{
		lua_pushstring(l, item.EqIcon[i].c_str());
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "EqIcon");

	lua_newtable(l);
	for (unsigned int i = 0; i < item.RaceIcon.size(); ++i)
	{
		lua_pushstring(l, item.RaceIcon[i].c_str());
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "RaceIcon");

	lua_newtable(l);
	for (unsigned int i = 0; i < item.JobIcon.size(); ++i)
	{
		lua_pushstring(l, item.JobIcon[i].c_str());
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "JobIcon");
	return 1;
}

int getSkillUpRateSettingConfItem(lua_State* l)
{
	const int lv = luaL_checkinteger(l, -1);
	auto pConf = reinterpret_cast<CConfSkillUpRateSetting*>(CConfManager::getInstance()->getConf(CONF_SKILL_UP_RATE_SETTING));
	auto item = reinterpret_cast<SkillUpRateItem*>(pConf->getData(lv));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->SkillLv, "SkillLv");
	LuaTools::pushMapIntIntToTableField(item->Rate, l, "Rate");

	return 1;
}

int getSoldierLevelSettingConfItem(lua_State* l)
{
	const int lv = luaL_checkinteger(l, -1);
	auto pConf = reinterpret_cast<CConfSoldierLevelSetting*>(
		CConfManager::getInstance()->getConf(CONF_SOLDIER_LEVEL_SETTING));
	auto item = reinterpret_cast<SoldierLevelSettingItem*>(pConf->getData(lv));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->SoldierLv, "SoldierLv");
	LuaTools::pushBaseKeyValue(l, item->LvUpCost, "LvUpCost");
	LuaTools::pushBaseKeyValue(l, item->Exp, "Exp");

	return 1;
}

int getSoldierStarSettingConfItem(lua_State* l)
{
	const int star = luaL_checkinteger(l, -1);
	auto item = queryConfSoldierStarSetting(star);
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->SoldierStar, "SoldierStar");
	LuaTools::pushBaseKeyValue(l, item->TopLevel, "TopLevel");
	LuaTools::pushBaseKeyValue(l, item->UpStarLevel, "UpStarLevel");
	LuaTools::pushBaseKeyValue(l, item->UpStarCost, "UpStarCost");
	LuaTools::pushBaseKeyValue(l, item->TurnCardCount, "TurnCardCount");
    LuaTools::pushBaseKeyValue(l, item->TurnFragCount, "TurnFragCount");
    LuaTools::pushBaseKeyValue(l, item->UpStarCount, "UpStarCount");
	return 1;
}

int getSoldierRareSettingConfItem(lua_State* l)
{
	const int star = luaL_checkinteger(l, -1);
	auto item = queryConfSoldierRareSetting(star);
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->UiRes, "UiRes");
	LuaTools::pushBaseKeyValue(l, item->HeadboxRes, "HeadboxRes");
	LuaTools::pushBaseKeyValue(l, item->UnderboxRes, "UnderboxRes");
	LuaTools::pushBaseKeyValue(l, item->BorderboxRes, "BorderboxRes");
	LuaTools::pushBaseKeyValue(l, item->CircleboxRes, "CircleboxRes");
	LuaTools::pushBaseKeyValue(l, item->BigHeadboxRes, "BigHeadboxRes");
	LuaTools::pushBaseKeyValue(l, item->HeadboxBgRes, "HeadboxBgRes");
	LuaTools::pushBaseKeyValue(l, item->JobBg, "JobBg");
	LuaTools::pushVecStringToTableField(item->JobsIcon, l, "JobsIcon");
	
	return 1;
}

int getTaskAcheveSettingConfItem(lua_State* l)
{
	auto pConf = reinterpret_cast<CConfTaskAchieveSetting*>(
		CConfManager::getInstance()->getConf(CONF_TASK_ACHIEVE_SETTING));
	if (!pConf)
	{
		lua_pushnil(l);
		return 1;
	}
	auto item = pConf->getData();

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item.TaskFinishSound, "TaskFinishSound");
	LuaTools::pushBaseKeyValue(l, item.AchieveFinishSound, "AchieveFinishSound");
	LuaTools::pushBaseKeyValue(l, item.MainTaskIcon, "MainTaskIcon");
	LuaTools::pushBaseKeyValue(l, item.DailyTaskIcon, "DailyTaskIcon");
	return 1;
}

int getUserLevelSettingConfItem(lua_State* l)
{
	const int lv = luaL_checkinteger(l, -1);
	auto outUnion = reinterpret_cast<CConfUserLevelSetting*>(
		CConfManager::getInstance()->getConf(CONF_USER_LEVEL_SETTING));
	auto item = reinterpret_cast<UserLevelSettingItem*>(outUnion->getData(lv));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);

	LuaTools::pushBaseKeyValue(l, item->Level, "Level");
	LuaTools::pushBaseKeyValue(l, item->Exp, "Exp");
    LuaTools::pushBaseKeyValue(l, item->SummonerHP, "SummonerHP");
	LuaTools::pushVecIntToTableField(item->BuyCoin, l, "BuyCoin");

	return 1;
}

int getOutterBonusSettingConfItem(lua_State* l)
{
    const int effectID = luaL_checkinteger(l, -1);
    auto setting = reinterpret_cast<CConfOutterBonusSetting*>(
        CConfManager::getInstance()->getConf(CONF_OUTTER_BONUS_SETTING));
    auto item = reinterpret_cast<OutterBonusSetting*>(setting->getData(effectID));
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);

    LuaTools::pushBaseKeyValue(l, item->ID, "ID");
    LuaTools::pushBaseKeyValue(l, item->AttributeID, "AttributeID");
    LuaTools::pushBaseKeyValue(l, item->Method, "Method");

    return 1;
}

int getNewPlayerSettingConf(lua_State* l)
{
	const NewPlayerItem* settingItem = queryConfNewPlayerItem(1);
	if (NULL == settingItem)
	{
		return 0;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, settingItem->MaxBagCapacity, "MaxBagCapacity");
	LuaTools::pushBaseKeyValue(l, settingItem->MaxHeroCapacity, "MaxHeroCapacity");
	return 1;
}

int getGoldTestConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto conf = reinterpret_cast<CConfGoldTest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST));
	auto item = reinterpret_cast<GoldTestConfItem*>(conf->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->WeekNum, "WeekNum");
	LuaTools::pushBaseKeyValue(l, item->Stage, "Stage");
	LuaTools::pushBaseKeyValue(l, item->StageDesc, "StageDesc");
	LuaTools::pushBaseKeyValue(l, item->Frequency, "Frequency");
	LuaTools::pushBaseKeyValue(l, item->StageLevel, "StageLevel");

	return 1;
}

int getGoldTestChestConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto conf = reinterpret_cast<CConfGoldTestChest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST_CHEST));
	auto item = reinterpret_cast<GoldTestChestConfItem*>(conf->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->Level , "Level");
	LuaTools::pushBaseKeyValue(l, item->Gold, "Gold");
	LuaTools::pushBaseKeyValue(l, item->Damage, "Damage");

	return 1;
}

int getHeroTestConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto conf = reinterpret_cast<CConfHeroTest*>(CConfManager::getInstance()->getConf(CONF_HERO_TEST));
	auto item = reinterpret_cast<HeroTestItem*>(conf->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "ID");
	LuaTools::pushVecIntToTableField(item->Time, l, "Time");
	LuaTools::pushBaseKeyValue(l, item->Occupation, "Occupation");
	LuaTools::pushBaseKeyValue(l, item->Times, "Times");
	LuaTools::pushBaseKeyValue(l, item->Desc, "Desc");
	LuaTools::pushBaseKeyValue(l, item->UpDesc, "UpDesc");
	LuaTools::pushBaseKeyValue(l, item->Pic, "Pic");
	LuaTools::pushBaseKeyValue(l, item->Title, "Title");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->Diff.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->Diff[i].DiffID, "DiffID");
		LuaTools::pushBaseKeyValue(l, item->Diff[i].MaxLevel, "MaxLevel");
		LuaTools::pushBaseKeyValue(l, item->Diff[i].BasicLevel, "BasicLevel");
		LuaTools::pushBaseKeyValue(l, item->Diff[i].ExLevel, "ExLevel");
		LuaTools::pushBaseKeyValue(l, item->Diff[i].UnlockLevel, "UnlockLevel");
		LuaTools::pushVecIntToTableField(item->Diff[i].Pic, l, "Pick");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "Diff");

	return 1;
}

int getTowerFloorConfItem(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfTowerFloor*>(CConfManager::getInstance()->getConf(CONF_TOWER_FLOOR));
    auto item = reinterpret_cast<TowerFloorItem*>(conf->getData(id));
    if (!item)
    {
        lua_pushnil(l);
        return 1;
    }

    lua_newtable(l);
    LuaTools::pushBaseKeyValue(l, item->ID, "ID");
    LuaTools::pushBaseKeyValue(l, item->MaxLevel, "MaxLevel");
    LuaTools::pushBaseKeyValue(l, item->BasicLevel, "BasicLevel");
    LuaTools::pushBaseKeyValue(l, item->EXLevel, "EXLevel");
    LuaTools::pushVecIntToTableField(item->StageID, l, "StageID");
    LuaTools::pushBaseKeyValue(l, item->Place, "Place");
    LuaTools::pushBaseKeyValue(l, item->Drop, "Drop");

    return 1;
}

int getTowerBuffConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto conf = reinterpret_cast<CConfTowerBuff*>(CConfManager::getInstance()->getConf(CONF_TOWER_BUFF));
	auto item = reinterpret_cast<TowerBuffItem*>(conf->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "Num");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->Buff.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->Buff[i].BuffID, "BuffID");
		LuaTools::pushBaseKeyValue(l, item->Buff[i].Cost, "Cost");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "Buff");

	LuaTools::pushBaseKeyValue(l, item->Max, "Max");
	LuaTools::pushBaseKeyValue(l, item->Min, "Min");

	return 1;
}

int getTowerRankConfItem(lua_State* l)
{
	const int id = luaL_checkinteger(l, -1);
	auto conf = reinterpret_cast<CConfTowerRank*>(CConfManager::getInstance()->getConf(CONF_TOWER_RANK));
	auto item = reinterpret_cast<TowerRankItem*>(conf->getData(id));
	if (!item)
	{
		lua_pushnil(l);
		return 1;
	}

	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, item->ID, "Num");
	LuaTools::pushVecIntToTableField(item->Rank, l, "Rank");

	lua_newtable(l);
	for (int i = 0; i < static_cast<int>(item->Item.size()); ++i)
	{
		lua_newtable(l);
		LuaTools::pushBaseKeyValue(l, item->Item[i].ID, "ID");
		LuaTools::pushBaseKeyValue(l, item->Item[i].Num, "Num");
		lua_rawseti(l, -2, i + 1);
	}
	lua_setfield(l, -2, "Item");

	return 1;
}

int getShopConfData(lua_State* l)
{
    auto conf = reinterpret_cast<CShopData*>(CConfManager::getInstance()->getConf(CONF_SHOP));
    if (NULL != conf)
    {
        auto datas = conf->getDatas();

        lua_newtable(l);
        int n = 1;
        for (auto iter = datas.begin(); iter != datas.end(); ++iter)
        {
            lua_newtable(l);

            auto data = reinterpret_cast<ShopConfigData *>(iter->second);
            LuaTools::pushBaseKeyValue(l, iter->first, "nShopType");
            LuaTools::pushBaseKeyValue(l, data->nShopName, "nName");
            LuaTools::pushBaseKeyValue(l, data->strShopIcon, "strShopIcon");
            LuaTools::pushBaseKeyValue(l, data->nLevLimit, "nOpenLevel");
            LuaTools::pushBaseKeyValue(l, data->nTimeInterval, "nFreshTime");

            LuaTools::pushVecIntToTableField(data->VectType, l, "tCoinType");

            lua_rawseti(l, -2, n++);
        }
        return 1;
    }
    return 0;
}

int getShopTypeData(lua_State* l)
{
    auto conf = reinterpret_cast<CShopData*>(CConfManager::getInstance()->getConf(CONF_SHOP));
    if (NULL != conf)
    {
        int shopType = luaL_checkinteger(l, -1);
        auto datas = conf->getDatas();

        auto iter = datas.find(shopType);
        if (iter != datas.end())
        {
            lua_newtable(l);

            auto data = reinterpret_cast<ShopConfigData *>(iter->second);
            LuaTools::pushBaseKeyValue(l, iter->first, "nShopType");
            LuaTools::pushBaseKeyValue(l, data->nShopName, "nName");
            LuaTools::pushBaseKeyValue(l, data->strShopIcon, "strShopIcon");
            LuaTools::pushBaseKeyValue(l, data->nLevLimit, "nOpenLevel");
            LuaTools::pushBaseKeyValue(l, data->nTimeInterval, "nFreshTime");

            LuaTools::pushVecIntToTableField(data->VectType, l, "tCoinType");

            return 1;
        }
    }

    return 0;
}

int getDiamondShopConfData(lua_State* l)
{
    auto conf = reinterpret_cast<CConfDiamondShop*>(CConfManager::getInstance()->getConf(CONF_SHOP_DIAMOND));
    if (NULL != conf)
    {
        auto datas = conf->getDatas();
        lua_newtable(l);
        int n = 1;
        for (auto iter = datas.begin(); iter != datas.end(); ++iter)
        {
            lua_newtable(l);
            auto data = reinterpret_cast<DiamondShopConfigData*>(iter->second);
            LuaTools::pushBaseKeyValue(l, data->nGoodsID, "nGoodsID");
            LuaTools::pushBaseKeyValue(l, data->strPicName, "strPicName");
            LuaTools::pushBaseKeyValue(l, data->nNameLanID, "nNameLanID");
            LuaTools::pushBaseKeyValue(l, data->nDescLanID, "nDescLanID");
            LuaTools::pushBaseKeyValue(l, data->nPrice, "nPrice");
            LuaTools::pushBaseKeyValue(l, data->nDiamond, "nDiamond");

            lua_rawseti(l, -2, n++);
        }
        return 1;
    }

    return 0;
}

int getOperateActiveTitleName(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveTime *>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TIME));
    if (conf)
    {
        auto data = reinterpret_cast<SConfActiveTime *>(conf->getData(id));
        if (data)
        {
            const char* str = getLanguageString(CONF_UI_LAN, data->nTitleLanguageID);
            if (NULL != str)
            {
                lua_pushstring(l, str);
                return 1;
            }
        }
    }
    return 0;
}

int getOperateActiveMenuIcon(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveTime *>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TIME));
    if (conf)
    {
        auto data = reinterpret_cast<SConfActiveTime *>(conf->getData(id));
        if (data)
        {
            lua_pushstring(l, data->szIcon.c_str());
            return 1;
        }
    }
    return 0;
}

int getOperateActiveMenuName(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveTime *>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TIME));
    if (conf)
    {
        auto data = reinterpret_cast<SConfActiveTime *>(conf->getData(id));
        if (data)
        {
            const char* str = getLanguageString(CONF_UI_LAN, data->nButonLanguageID);
            if (NULL != str)
            {
                lua_pushstring(l, str);
                return 1;
            }
        }
    }

    return 0;
}

int GetOperateActiveTaskIcon(lua_State* l)
{
    const int nActiveID = luaL_checkinteger(l, -2);
    const int nActiveTaskID = luaL_checkinteger(l, -1);

    auto conf = reinterpret_cast<CConfActiveTask*>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TASK));
    if (conf)
    {
        auto data = conf->GetTaskActiveTaskData(nActiveID, nActiveTaskID);
        if (data)
        {
            lua_pushstring(l, data->ActiveIcon.c_str());
            return 1;
        }
    }
    return 0;
}

int GetOperateActiveTaskName(lua_State* l)
{
    const int nActiveID = luaL_checkinteger(l, -2);
    const int nActiveTaskID = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveTask*>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TASK));
    if (conf)
    {
        auto data = conf->GetTaskActiveTaskData(nActiveID, nActiveTaskID);
        if (data)
        {
            const char* str = getLanguageString(CONF_UI_LAN, data->nActiveLanguangeID);
            if (NULL != str)
            {
                lua_pushstring(l, str);
                return 1;
            }
        }
    }
    return 0;
}

int GetOperateActiveTaskPic(lua_State* l)
{
    const int nActiveID = luaL_checkinteger(l, -2);
    const int nActiveTaskID = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveTask*>(CConfManager::getInstance()->getConf(CONF_ACTIVE_TASK));
    if (conf)
    {
        auto data = conf->GetTaskActiveTaskData(nActiveID, nActiveTaskID);
        if (data)
        {
            lua_pushstring(l, data->ActivePic.c_str());
            return 1;
        }
    }
    return 0;
}

int getOperateActiveDropDesc(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveExtraAdd *>(CConfManager::getInstance()->getConf(CONF_ACTIVE_DROP));
    if (conf)
    {
        auto data = reinterpret_cast<SConfActiveExtraAdd *>(conf->getData(id));
        if (data)
        {
            const char* str = getLanguageString(CONF_UI_LAN, data->nLanguageID);
            if (NULL != str)
            {
                lua_pushstring(l, str);
                return 1;
            }
        }
    }
    return 0;
}

int getOperateActiveDropPic(lua_State* l)
{
    const int id = luaL_checkinteger(l, -1);
    auto conf = reinterpret_cast<CConfActiveExtraAdd *>(CConfManager::getInstance()->getConf(CONF_ACTIVE_DROP));
    if (conf)
    {
        auto data = reinterpret_cast<SConfActiveExtraAdd *>(conf->getData(id));
        if (data)
        {
            lua_pushstring(l, data->ActivePic.c_str());
            return 1;
        }
    }
    return 0;
}


int getMonthSignConf(lua_State* l)
{
    const int nMonth = luaL_checkinteger(l, -1);
    auto cfg = reinterpret_cast<CConfDaySign *>(CConfManager::getInstance()->getConf(CONF_DAYSIGN));
    if (cfg)
    {
        lua_newtable(l);
        for (int i = 1; i <= 26; i++)
        {
            auto data = reinterpret_cast<SCheckInDayConfig *>(cfg->GetMonthSignDay(nMonth, i));
            if (data)
            {
                lua_newtable(l);
                LuaTools::pushBaseKeyValue(l, data->nGoodsID, "nGoodsID");
                LuaTools::pushBaseKeyValue(l, data->nGoodsNum, "nGoodsNum");
                LuaTools::pushBaseKeyValue(l, data->nShowNum, "nShowNum");

                lua_rawseti(l, -2, i);
            }
        }
        return 1;
    }

    return 0;
}

int getConDaySignConf(lua_State* l)
{
    const int nSignID = luaL_checkinteger(l, -1);
    auto cfg = reinterpret_cast<CConfConDaySign *>(CConfManager::getInstance()->getConf(CONF_CONDAYSIGN));
    if (cfg)
    {
        const SConCheckInConfig* const item = reinterpret_cast<SConCheckInConfig *>(cfg->getData(nSignID));
        if (item)
        {
            lua_newtable(l);
            LuaTools::pushBaseKeyValue(l, item->DayNeeds, "DayNeeds");
            for (int i = 0; i < 3; i++)
            {
                lua_newtable(l);
                LuaTools::pushBaseKeyValue(l, item->nGoodsID[i], "nGoodsID");
                LuaTools::pushBaseKeyValue(l, item->nGoodsNum[i], "nGoodsNum");
                LuaTools::pushBaseKeyValue(l, item->nShowNum[i], "nShowNum");

                lua_rawseti(l, -2, i+1);
            }
            return 1;
        }
    }
    return 0;
}

int getSysAutoNameConf(lua_State* l)
{
    auto cfg = reinterpret_cast<CConfSysAutoName *>(CConfManager::getInstance()->getConf(CONF_SYSAUTONAME));
    if (cfg)
    {
        lua_newtable(l);
        std::map<int, std::vector<std::string>> names = cfg->getAutoNames();
        int i = 1;
        for (auto item : names)
        {
            lua_newtable(l);
            int j = 1;
            for (auto &iter : item.second)
            {
                lua_pushstring(l, iter.c_str());
                lua_rawseti(l, -2, j++);
            }
            lua_rawseti(l, -2, i++);
        }
        return 1;
    }
    return 0;
}

int GetFirstPayData(lua_State* l)
{
    auto cfg = reinterpret_cast<CConfFirstPay*>(CConfManager::getInstance()->getConf(CONF_FIRSTPAY_SETING));
    if (cfg)
    {
        lua_newtable(l);
        SFirstPayData * data = cfg->GetFirstPayData();
        if (data)
        {
            LuaTools::pushVecIntToTableField(data->vectGoodsID, l, "GoodsID");
            LuaTools::pushVecIntToTableField(data->vectGoodsNum, l, "GoodsNum");
            LuaTools::pushBaseKeyValue(l, data->nGrowGiftPrice, "GrowGiftPrice");
            LuaTools::pushBaseKeyValue(l, data->nGiftDiamonds, "GiftDiamonds");
            LuaTools::pushBaseKeyValue(l, data->nGetTimes, "GetTimes");

            return 1;
        }
    }

    lua_pushnil(l);

    return 0;
}

int initConfig(lua_State* l)
{
    // 初始化配表
    if (!CConfManager::getInstance()->init())
    {
        LOG("init conf faile");
        return 0;
    }
    lua_pushboolean(l, true);
    return 1;
}

bool regiestConfigFuncs()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

	/////////////////////////////////获取配表方法/////////////////////////////////////////
	lua_register(luaState, "getPropLanConfItem", getPropLanConfItem);		//获取 道具语言表
	lua_register(luaState, "getStageLanConfItem", getStageLanConfItem);		//获取 关卡语言表
	lua_register(luaState, "getUILanConfItem", getUILanConfItem);			//获取 UI语言表
	lua_register(luaState, "getBMCLanConfItem", getBMCLanConfItem);			//获取 boss monster语言表
	lua_register(luaState, "getBMCSkillLanConfItem", getBMCSkillLanConfItem);//获取 boss monster 技能语言表
	lua_register(luaState, "getHSLanConfItem", getHSLanConfItem);			//获取 hero solider语言表
	lua_register(luaState, "getHSSkillLanConfItem", getHSSkillLanConfItem);	//获取 hero solider 技能语言表
	lua_register(luaState, "getStoryLanConfItem", getStoryLanConfItem);		//获取剧情文本
	lua_register(luaState, "getTaskLanConfItem", getTaskLanConfItem);		//获取任务文本
	lua_register(luaState, "getAchieveLanConfItem", getAchieveLanConfItem);	//获取成就文本
    lua_register(luaState, "getRoleAttributeLanConfItem", getRoleAttributeLanConfItem);	//获取角色属性文本
    lua_register(luaState, "getErrorCodeConfItem", getErrorCodeConfItem); // errorCode文字
    lua_register(luaState, "getLoadingTipsConfItem", getLoadingTipsConfItem);   // Loading提示文字
    lua_register(luaState, "getLoadingTipsCount", getLoadingTipsCount);         // Loading提示个数

    lua_register(luaState, "getCameraConfItem", getCameraConfItem);			//获取 镜头表
	lua_register(luaState, "getCameraItemList", getCameraItemList);			//获取 镜头表主键
	lua_register(luaState, "getSkillConfItem", getSkillConfItem);			//获取 技能表
	lua_register(luaState, "getHeroConfItem", getHeroConfItem);				//获取 英雄表
	lua_register(luaState, "getHeroItemList", getHeroItemList);				//获取 英雄表主键
	lua_register(luaState, "getSoldierConfItem", getSoldierConfItem);		//获取 士兵表
	lua_register(luaState, "getSoldierItemList", getSoldierItemList);		//获取 士兵表主键
	lua_register(luaState, "getBossConfItem", getBossConfItem);				//获取 boss表
	lua_register(luaState, "getBossItemList", getBossItemList);				//获取 boss表主键
	lua_register(luaState, "getMonsterConfItem", getMonsterConfItem);		//获取 怪物表
	lua_register(luaState, "getMonsterItemList", getMonsterItemList);		//获取 怪物表主键
	lua_register(luaState, "getCallConfItem", getCallConfItem);				//获取 召唤物表
	lua_register(luaState, "getCallItemList", getCallItemList);				//获取 召唤物表主键
	lua_register(luaState, "getEffectConfItem", getEffectConfItem);			//获取 特效表
	lua_register(luaState, "getStageInfoInChapter", getStageInfoInChapter);	//获取 获得章节中指定关卡数据
	lua_register(luaState, "getMapConfItem", getMapConfItem);				//获取 章节配置表
	lua_register(luaState, "getMapItemList", getMapItemList);				//获取 章节配置表主键
	lua_register(luaState, "getStageConfItem", getStageConfItem);			//获取 关卡表
	lua_register(luaState, "getStageItemList", getStageItemList);			//获取 关卡表主键
	lua_register(luaState, "getDropPropItem", getDropPropItem);				//获取 关卡掉落
    lua_register(luaState, "getStageSceneConfItem", getStageSceneConfItem);	//获取 关卡掉落

	lua_register(luaState, "getEquipmentConfItem", getEquipmentConfItem);	//获取 装备表
	lua_register(luaState, "getEquipmentItemList", getEquipmentItemList);	//获取 装备表主键
	lua_register(luaState, "getSuitConfItem", getSuitConfItem);				//获取 套装表
	lua_register(luaState, "getSuitItemList", getSuitItemList);				//获取 套装表主键
	lua_register(luaState, "getPropConfItem", getPropConfItem);				//获取 道具表
	lua_register(luaState, "getPropItemList", getPropItemList);				//获取 道具表主键
	lua_register(luaState, "getTaskConfItem", getTaskConfItem);				//获取 任务表
	lua_register(luaState, "getTaskItemList", getTaskItemList);				//获取 任务表 主键
	lua_register(luaState, "getAchieveConfItem", getAchieveConfItem);		//获取 成就表
	lua_register(luaState, "getAchieveItemList", getAchieveItemList);			//获取 成就表 主键
	lua_register(luaState, "getActivityInstanceItem", getActivityInstanceItem);	//获取 活动副本表
	lua_register(luaState, "getActivityInstanceList", getActivityInstanceList);	//获取 活动副本主键
	lua_register(luaState, "getMailConfItem", getMailConfItem);					//获取 邮件配表
	lua_register(luaState, "getGuideConfItem", getGuideConfItem);					//获取 引导表
	lua_register(luaState, "getGuideItemList", getGuideItemList);					//获取 引导表 主键
	lua_register(luaState, "getGuideStepConfItem", getGuideStepConfItem);			//获取 引导表
	lua_register(luaState, "getGuideStepItemList", getGuideStepItemList);			//获取 引导表 主键

	lua_register(luaState, "getUINodeConfItem", getUINodeConfItem);					//获取 UI节点
	lua_register(luaState, "getUINodeItemList", getUINodeItemList);					//获取 UI节点 主键
	lua_register(luaState, "getUIStatusConfItem", getUIStatusConfItem);				//获取 UI状态
	lua_register(luaState, "getUIStatusItemList", getUIStatusItemList);				//获取 UI状态 主键
    lua_register(luaState, "getGuideBattleConfItem", getGuideBattleConfItem);       //获取 引导战斗配置


	lua_register(luaState, "getGoldTestConfItem", getGoldTestConfItem);				//获取 金币试炼表
	lua_register(luaState, "getGoldTestItemList", getGoldTestItemList);				//获取 金币试炼表 主键
	lua_register(luaState, "getGoldTestChestConfItem", getGoldTestChestConfItem);	//获取 金币试炼表
	lua_register(luaState, "getGoldTestChestItemList", getGoldTestChestItemList);	//获取 金币试炼表 主键
	lua_register(luaState, "getHeroTestConfItem", getHeroTestConfItem);				//获取 英雄试炼表
	lua_register(luaState, "getHeroTestItemList", getHeroTestItemList);				//获取 英雄试炼表 主键

	lua_register(luaState, "getTowerFloorConfItem", getTowerFloorConfItem);			//获取 爬塔试炼表
	lua_register(luaState, "getTowerFloorItemList", getTowerFloorItemList);			//获取 爬塔试炼表 主键
	lua_register(luaState, "getTowerBuffConfItem", getTowerBuffConfItem);			//获取 爬塔试炼表
	lua_register(luaState, "getTowerBuffItemList", getTowerBuffItemList);			//获取 爬塔试炼表 主键
	lua_register(luaState, "getTowerRankConfItem", getTowerRankConfItem);			//获取 爬塔试炼表
	lua_register(luaState, "getTowerRankItemList", getTowerRankItemList);			//获取 爬塔试炼表 主键

	lua_register(luaState, "getResPathInfoByID", getResPathInfoByID);				//获取 资源信息
	lua_register(luaState, "getResIDsByIDStar", getResIDsByIDStar);					//获取 资源id

	lua_register(luaState, "getSaleSummonerConfItem", getSaleSummonerConfItem);		//获取 购买召唤师表
	lua_register(luaState, "getSaleSummonerItemList", getSaleSummonerItemList);		//获取 购买召唤师表主键
	lua_register(luaState, "getIncreasePayConfItem", getIncreasePayConfItem);		//获取 购买消耗表
	lua_register(luaState, "getIncreasePayItemList", getIncreasePayItemList);		//获取 购买消耗表主键
	
    lua_register(luaState, "getShopConfData", getShopConfData);                     //获取 商店类型表
    lua_register(luaState, "getShopTypeData", getShopTypeData);                     //获取 获取某个类型商店数据
    lua_register(luaState, "getDiamondShopConfData", getDiamondShopConfData);       //获取 充值商店配置表

    lua_register(luaState, "getOperateActiveTitleName", getOperateActiveTitleName); //获取 运营活动标题的语言包ID
    lua_register(luaState, "getOperateActiveMenuIcon", getOperateActiveMenuIcon);   //获取 运营活动标签的图片资源
    lua_register(luaState, "getOperateActiveMenuName", getOperateActiveMenuName);   //获取 运营活动标签的语言包ID
    lua_register(luaState, "GetOperateActiveTaskIcon", GetOperateActiveTaskIcon);   //获取 运营活动任务的图片资源
    lua_register(luaState, "GetOperateActiveTaskName", GetOperateActiveTaskName);   //获取 运营活动任务的语言包ID
    lua_register(luaState, "GetOperateActiveTaskPic", GetOperateActiveTaskPic);     //获取 运营活动任务的宣传图
    lua_register(luaState, "getOperateActiveDropDesc", getOperateActiveDropDesc);   //获取 运营活动掉落描述语言包ID
    lua_register(luaState, "getOperateActiveDropPic", getOperateActiveDropPic);     //获取 运营活动掉落的宣传图

    lua_register(luaState, "GetFirstPayData", GetFirstPayData);                     //获取 首次充值活动的配置

    lua_register(luaState, "getMonthSignConf", getMonthSignConf);                   //获取 每日签到的配置
    lua_register(luaState, "getConDaySignConf", getConDaySignConf);                 //获取 累计签到的配置

    lua_register(luaState, "getSysAutoNameConf", getSysAutoNameConf);               //获取 随机名字库配置
	////////////////////////////////////Role//////////////////////////////////////
    lua_register(luaState, "getRoleZoom", getRoleZoom);								 //获取 角色缩放配置

	////////////////////////////////////Hall//////////////////////////////////////
    lua_register(luaState, "getConfOutterBonusItem", getConfOutterBonusItem);		// 战斗外属性加成
    lua_register(luaState, "getConfArenaComputerItem", getConfArenaComputerItem);   // 竞技场电脑
	lua_register(luaState, "getConfAnimationPlayOrderItem", getConfAnimationPlayOrderItem);	// 点击播放动画
    lua_register(luaState, "getConfHallStandingItem", getConfHallStandingItem);	// 大厅站位顺序
    lua_register(luaState, "getEquipBaseAttriteCount", getEquipBaseAttriteCount);	// 获取装备基础属性个数
    lua_register(luaState, "getEquipPropCreateConfItem", getEquipPropCreateConfItem);	// 获取装备生成器配表
    lua_register(luaState, "getEquipPropMaxCount", getEquipPropMaxCount);	        // 获取装备最大属性个数
    lua_register(luaState, "getTalentConf", getTalentConf);	                        // 获取装备最大属性个数

    ////////////////////////////////////Union//////////////////////////////////////
    lua_register(luaState, "getUnionLevelConfItem", getUnionLevelConfItem);			// 公会任务
    lua_register(luaState, "getUnionConfItem", getUnionConfItem);			// 公会任务
    lua_register(luaState, "getUnionBadgeConfItem", getUnionBadgeConfItem);			// 公会会徽

	///////////////////////////////////GameSetting///////////////////////////////////////
	lua_register(luaState, "getCardGambleSettingConfItem", getCardGambleSettingConfItem);	// 抽卡相关
	lua_register(luaState, "getIconSettingConfItem", getIconSettingConfItem);				// 头像相关
	lua_register(luaState, "getSkillUpRateSettingConfItem", getSkillUpRateSettingConfItem);	// 技能升级相关
	lua_register(luaState, "getSoldierLevelSettingConfItem", getSoldierLevelSettingConfItem);// 士兵等级相关
	lua_register(luaState, "getSoldierStarSettingConfItem", getSoldierStarSettingConfItem);	// 士兵星级相关
	lua_register(luaState, "getSoldierRareSettingConfItem", getSoldierRareSettingConfItem);	// 士兵稀有度相关
	lua_register(luaState, "getTaskAcheveSettingConfItem", getTaskAcheveSettingConfItem);	// 任务成就相关
	lua_register(luaState, "getUserLevelSettingConfItem", getUserLevelSettingConfItem);		// 玩家等级相关
    lua_register(luaState, "getOutterBonusSettingConfItem", getOutterBonusSettingConfItem); // 战斗外属性作用方法
	lua_register(luaState, "getNewPlayerSettingConf", getNewPlayerSettingConf);				// 新玩家 最大背包, 最大卡包数据
	
    lua_register(luaState, "getTowerSetting", getTowerSetting);						//获取 活动副本购买次数费用
    lua_register(luaState, "getChapterSetting", getChapterSetting);		            //获取 章节配置
    lua_register(luaState, "getChatSetting", getChatSetting);		                //获取 聊天配置
    lua_register(luaState, "getSystemHeadIconItem", getSystemHeadIconItem);         //获取 系统头像配置
    lua_register(luaState, "getItemLevelSettingItem", getItemLevelSettingItem);     //获取 道具外框配置
	lua_register(luaState, "getTimeRecoverSetting", getTimeRecoverSetting);			//获取 时间恢复设置
	
	lua_register(luaState, "getArenaRankItem", getArenaRankItem);                   //获取 竞技场段位配置
    lua_register(luaState, "getArenaRankTask", getArenaRankTask);                   //获取 竞技场任务配置
    lua_register(luaState, "getArenaTypeRankReward", getArenaTypeRankReward);       //获取 竞技场配置(根据排行和类型)
    lua_register(luaState, "getArenaRankReward", getArenaRankReward);               //获取 竞技场奖励配置
    lua_register(luaState, "getArenaTrainings", getArenaTrainings);                 //获取 竞技场训练场配置
    lua_register(luaState, "getArenaLevel", getArenaLevel);                         //获取 竞技场解锁配置
    lua_register(luaState, "getArenaSetting", getArenaSetting);                     //获取 竞技场配置

    /////////////////////////////////// Music ///////////////////////////////////
    lua_register(luaState, "getUIBgMusic", getUIBgMusic);
    lua_register(luaState, "getBgMusic", getBgMusic);
    lua_register(luaState, "getButtonEffectPath", getButtonEffectPath);
    lua_register(luaState, "getUISoundEffectPath", getUISoundEffectPath);

    /////////////////////////////////// Support ///////////////////////////////////
    lua_register(luaState, "getUserMaxLevel", getUserMaxLevel);			            //获取 玩家最高等级
	lua_register(luaState, "getPreAchieveID", getPreAchieveID);			            //获取 激活这个成就的成就成就

	// 时间处理
	lua_register(luaState, "getNextTimeStamp", getNextTimeStampToLua);
	lua_register(luaState, "getWNextTimeStamp", getWNextTimeStampToLua);

    // 配表初始化
    lua_register(luaState, "initConfig", initConfig);

    return true;
}
