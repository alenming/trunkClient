#ifdef WIN32

#include <string>
#include "CsvCheck.h"
#include "ConfFight.h"
#include "ConfOther.h"
#include "ConfRole.h"
#include "ConfStage.h"
#include "ConfLanguage.h"
#include "ConfHall.h"
#include "cocos2d.h"  

#ifndef RunningInServer
#include "Game.h"
#endif

using namespace cocos2d;


CsvCheck *CsvCheck::m_pInstance = nullptr;

CsvCheck::CsvCheck()
{
}

CsvCheck::~CsvCheck()
{
}

CsvCheck * CsvCheck::getInstance()
{
	if (nullptr == m_pInstance)
	{
		m_pInstance = new CsvCheck;
	}

	return m_pInstance;
}

void CsvCheck::destory()
{
	if (nullptr != m_pInstance)
	{
		delete m_pInstance;
		m_pInstance = nullptr;
	}
}

bool CsvCheck::checkCsvHead()
{
	return true;
}

#define XXXXXXXXXXX 	CConfEffect* AnimationCsv = (CConfEffect*)CConfManager::getInstance()->getConf(CONF_EFFECT); \
	auto& AnimationCsvData = AnimationCsv->getDatas(); \
	CConfSkill* SkillCsv = (CConfSkill*)CConfManager::getInstance()->getConf(CONF_SKILL); \
    auto& SkillCsvData = SkillCsv->getDatas(); \
	CConfCall* CallCsv = (CConfCall*)CConfManager::getInstance()->getConf(CONF_CALL); \
	auto& CallCsvData = CallCsv->getDatas(); \
	CConfLanguage* HeroSoldierSkillCsv = (CConfLanguage*)CConfManager::getInstance()->getConf(CONF_HS_SKILL_LAN); \
	auto& HeroSoldierSkillCsvData = HeroSoldierSkillCsv->getWords(); \
	CConfAI* AICsv = (CConfAI*)CConfManager::getInstance()->getConf(CONF_AIDATA); \
	auto& AICsvData = AICsv->getAIMap(); \
	CConfStatus* StatusCsv = (CConfStatus*)CConfManager::getInstance()->getConf(CONF_STATUS); \
	auto& StatusCsvData = StatusCsv->getStatusFileMap(); \
	CConfBoss* BossCsv = (CConfBoss*)CConfManager::getInstance()->getConf(CONF_BOSS); \
	auto& BossCsvData = BossCsv->getDatas(); \
	CConfLanguage* BossMonsterCallCsv = (CConfLanguage*)CConfManager::getInstance()->getConf(CONF_BMC_LAN); \
	auto& BossMonsterCallCsvData = BossMonsterCallCsv->getWords(); \
	CConfMonster* MonsterCsv = (CConfMonster*)CConfManager::getInstance()->getConf(CONF_MONSTER); \
	auto& MonsterCsvData = MonsterCsv->getDatas(); \
	CConfHero* HeroCsv = (CConfHero*)CConfManager::getInstance()->getConf(CONF_HERO); \
	auto& HeroCsvData = HeroCsv->getDatas(); \
	CConfLanguage* HeroSoldierCsv = (CConfLanguage*)CConfManager::getInstance()->getConf(CONF_HS_LAN); \
	auto& HeroSoldierCsvData = HeroSoldierCsv->getWords(); \
	CConfSoldier* SoldierCsv = (CConfSoldier*)CConfManager::getInstance()->getConf(CONF_SOLDIER); \
	auto& SoldierCsvData = SoldierCsv->getSoldiersConfig(); \
	CConfAnimationRes* ResCsv = (CConfAnimationRes*)CConfManager::getInstance()->getConf(CONF_RESPATH); \
	auto& ResCsvData = ResCsv->getDatas(); \
	CConfBullet* BulletCsv = (CConfBullet*)CConfManager::getInstance()->getConf(CONF_BULLET); \
	auto& BulletCsvData = BulletCsv->getDatas(); \
	CConfSearch* SearchCsv = (CConfSearch*)CConfManager::getInstance()->getConf(CONF_SEARCH); \
	auto& SearchCsvData = SearchCsv->getDatas(); \
	CConfBuff* BuffCsv = (CConfBuff*)CConfManager::getInstance()->getConf(CONF_BUFF); \
	auto& BuffCsvData = BuffCsv->getBuffData(); \
	CConfCount* CountCsv = (CConfCount*)CConfManager::getInstance()->getConf(CONF_COUNT); \
	auto& CountCsvData = CountCsv->getDatas(); \
	CConfUIEffect* UIEffectCsv = (CConfUIEffect*)CConfManager::getInstance()->getConf(CONF_UI_EFFECT); \
	auto& UIEeffectCsvData = UIEffectCsv->getDatas(); \
	CConfCardCount* CardCountCsv = (CConfCardCount*)CConfManager::getInstance()->getConf(CONF_CARD_COUNT); \
	auto& CardCountCsvData = CardCountCsv->getDatas(); \
	CConfStage* StageCsv = (CConfStage*)CConfManager::getInstance()->getConf(CONF_STAGE); \
	auto& StageCsvData = StageCsv->getDatas(); \
	CConfStageScene* StageSceneCsv = (CConfStageScene*)CConfManager::getInstance()->getConf(CONF_STAGE_SCENE); \
	auto& StageSceneData = StageSceneCsv->getDatas(); \
	CConfDropProp* ItemDropCsv = (CConfDropProp*)CConfManager::getInstance()->getConf(CONF_ITEMDROP); \
	auto& ItemDropData = ItemDropCsv->getDatas(); \
	CConfRoleResPreload* RoleResPreload = (CConfRoleResPreload*)CConfManager::getInstance()->getConf(CONF_ROLERES); \
	auto& ResRolePreloadData = RoleResPreload->getData();



void getFilePathAtVec()
{

}

bool CsvCheck::checkCsv()
{
	m_checkResult.clear();
	//m_rongYu.clear();
	m_XXXX.clear();
	m_checkResult["Animation_csv"].clear();
	m_checkResult["Buff_csv"].clear();
	m_checkResult["Bullet_csv"].clear();
	m_checkResult["Count_csv"].clear();
	m_checkResult["Search_csv"].clear();
	m_checkResult["Skill_csv"].clear();
	m_checkResult["StageScene_csv"].clear();
	m_checkResult["AIAndStatus_csv"].clear();
	m_checkResult["Boss_csv"].clear();
	m_checkResult["Call_csv"].clear();
	m_checkResult["Monster_csv"].clear();
	m_checkResult["Res_csv"].clear();
	getFilePathAtVec();
	checkAnimationCsv();
	checkBuffCsv();
	checkBulletCsv();
	checkCountCsv();
	checkSearchCsv();
	checkSkillCsv();
	checkAIAndStatusCsv();
	checkBossCsv();
	checkCallCsv();
	checkMonsterCsv();
	checkHeroCsv();
	checkSoldierCsv();
	checkStageCsv();
	checkResCsv();
	checkResPreload();
	checkStatusPath();

	comput();
	printResult();
	return true;
}

void CsvCheck::comput()
{
	XXXXXXXXXXX
	//取出所有表的主键
	std::set<int> temp;
	temp.clear();
	//Animation.csv
	for (auto oneDatas = AnimationCsvData.begin(); oneDatas != AnimationCsvData.end(); oneDatas++)
	{
		EffectConfItem* oneData = (EffectConfItem*)(oneDatas->second);
		temp.insert(oneData->EffectId);
	}

	std::vector<int> animation(AnimationCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Animation_csv"].begin(), m_XXXX["Animation_csv"].end(), animation.begin());
	animation.erase(remove(animation.begin(), animation.end(), 0), animation.end());
	endResult["Animation_csv"] = animation;
	temp.clear();
	animation.clear();
	//Buff.csv
	for (auto oneDatass = BuffCsvData.begin(); oneDatass != BuffCsvData.end(); oneDatass++)
	{
		auto twoDatas = oneDatass->second;
		for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		{
			BuffConfItem* oneData = (BuffConfItem*)(oneDatas->second);
			temp.insert(oneData->ID);
		}
	}

	std::vector<int> buff(BuffCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Buff_csv"].begin(), m_XXXX["Buff_csv"].end(), buff.begin());
	buff.erase(remove(buff.begin(), buff.end(), 0), buff.end());
	endResult["Buff_csv"] = buff;
	temp.clear();
	buff.clear();
	//Bullet
	for (auto oneDatas = BulletCsvData.begin(); oneDatas != BulletCsvData.end(); oneDatas++)
	{

		BulletConfItem* oneData = (BulletConfItem*)(oneDatas->second);
		temp.insert(oneData->ID);
	}

	std::vector<int> bullet(BulletCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Bullet_csv"].begin(), m_XXXX["Bullet_csv"].end(), bullet.begin());
	bullet.erase(remove(bullet.begin(), bullet.end(), 0), bullet.end());
	endResult["Bullet_csv"] = bullet;
	temp.clear();
	bullet.clear();
	//Count
	for (auto oneDatas = CountCsvData.begin(); oneDatas != CountCsvData.end(); oneDatas++)
	{

		CountConfItem* oneData = (CountConfItem*)(oneDatas->second);
		temp.insert(oneData->ID);
	}

	std::vector<int> count(CountCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Count_csv"].begin(), m_XXXX["Count_csv"].end(), count.begin());
	count.erase(remove(count.begin(), count.end(), 0), count.end());
	endResult["Count_csv"] = count;
	temp.clear();
	count.clear();
	//Search
	for (auto oneDatas = SearchCsvData.begin(); oneDatas != SearchCsvData.end(); oneDatas++)
	{

		SearchConfItem* oneData = (SearchConfItem*)(oneDatas->second);
		temp.insert(oneData->ID);
	}

	std::vector<int> search(SearchCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Search_csv"].begin(), m_XXXX["Search_csv"].end(), search.begin());
	search.erase(remove(search.begin(), search.end(), 0), search.end());
	endResult["Search_csv"] = search;
	temp.clear();
	search.clear();
	//Skill
	for (auto oneDatass = SkillCsvData.begin(); oneDatass != SkillCsvData.end(); oneDatass++)
	{
		//auto twoDatas = oneDatass->second;
		//for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		//{
		//	SkillConfItem* oneData = (SkillConfItem*)(oneDatas->second);
		//	temp.insert(oneData->ID);
		//}
	}

	std::vector<int> skill(SkillCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Skill_csv"].begin(), m_XXXX["Skill_csv"].end(), skill.begin());
	skill.erase(remove(skill.begin(), skill.end(), 0), skill.end());
	endResult["Skill_csv"] = skill;
	temp.clear();
	skill.clear();
	//StageScene
	for (auto oneDatas = StageSceneData.begin(); oneDatas != StageSceneData.end(); oneDatas++)
	{
		StageSceneConfItem* oneData = (StageSceneConfItem*)(oneDatas->second);
		temp.insert(oneData->Id);
	}

	std::vector<int> stagescene(StageSceneData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["StageScene_csv"].begin(), m_XXXX["StageScene_csv"].end(), stagescene.begin());
	stagescene.erase(remove(stagescene.begin(), stagescene.end(), 0), stagescene.end());
	endResult["StageScene_csv"] = stagescene;
	temp.clear();
	stagescene.clear();
	//AIAndStatus
	for (auto oneDatas = AICsvData.begin(); oneDatas != AICsvData.end(); oneDatas++)
	{
		temp.insert(oneDatas->first);
	}

	std::vector<int> aiandstatus(AICsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["AIAndStatus_csv"].begin(), m_XXXX["AIAndStatus_csv"].end(), aiandstatus.begin());
	aiandstatus.erase(remove(aiandstatus.begin(), aiandstatus.end(), 0), aiandstatus.end());
	endResult["AIAndStatus_csv"] = aiandstatus;
	temp.clear();
	aiandstatus.clear();
	//Boss
	for (auto oneDatas = BossCsvData.begin(); oneDatas != BossCsvData.end(); oneDatas++)
	{
		BossConfItem* oneData = (BossConfItem*)(oneDatas->second);
		temp.insert(oneData->Common.ClassID);
	}

	std::vector<int> boss(BossCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Boss_csv"].begin(), m_XXXX["Boss_csv"].end(), boss.begin());
	boss.erase(remove(boss.begin(), boss.end(), 0), boss.end());
	endResult["Boss_csv"] = boss;
	temp.clear();
	boss.clear();
	//Call
	for (auto oneDatas = CallCsvData.begin(); oneDatas != CallCsvData.end(); oneDatas++)
	{
		CallConfItem* oneData = (CallConfItem*)(oneDatas->second);
		temp.insert(oneData->Common.ClassID);
	}

	std::vector<int> call(CallCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Call_csv"].begin(), m_XXXX["Call_csv"].end(), call.begin());
	call.erase(remove(call.begin(), call.end(), 0), call.end());
	endResult["Call_csv"] = call;
	temp.clear();
	call.clear();
	//Monster
	for (auto oneDatas = MonsterCsvData.begin(); oneDatas != MonsterCsvData.end(); oneDatas++)
	{
		MonsterConfItem* oneData = (MonsterConfItem*)(oneDatas->second);
		temp.insert(oneData->Common.ClassID);
	}

	std::vector<int> monster(MonsterCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Monster_csv"].begin(), m_XXXX["Monster_csv"].end(), monster.begin());
	monster.erase(remove(monster.begin(), monster.end(), 0), monster.end());
	endResult["Monster_csv"] = monster;
	temp.clear();
	monster.clear();
	//Res
	for (auto oneDatas = ResCsvData.begin(); oneDatas != ResCsvData.end(); oneDatas++)
	{
		SResPathItem* oneData = (SResPathItem*)(oneDatas->second);
		temp.insert(oneData->AnimationID);
	}

	std::vector<int> res(ResCsvData.size());
	set_difference(temp.begin(), temp.end(), m_XXXX["Res_csv"].begin(), m_XXXX["Res_csv"].end(), res.begin());
	res.erase(remove(res.begin(), res.end(), 0), res.end());
	endResult["Res_csv"] = res;
	temp.clear();
	res.clear();


}

void CsvCheck::printResult()
{
	std::string resultPath = "../bin/checkResult.log";
	std::string rongyuPath = "../bin/rongYu.log";
	FILE* result = fopen(resultPath.c_str(), "w+");
	FILE* rongYu = fopen(rongyuPath.c_str(), "w+");
	if (!result)
	{
		return;
	}
	for (auto oneDatass = m_checkResult.begin(); oneDatass != m_checkResult.end(); oneDatass++)
	{
		auto twoDatas = oneDatass->second;
		std::string name = "next=======================" + oneDatass->first;
		name += "============================================= \n";
		int ret = (int)fwrite(name.c_str(), sizeof(char), name.length(), result);
		if (twoDatas.size() == 0)
		{
			name.clear();
			name = "策划你太厉害了,这张表居然配得一点错都没有!给你个棒棒糖!";
			ret = (int)fwrite(name.c_str(), sizeof(char), name.length(), result);
		}
		for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		{
			int temp = oneDatas->second;
			std::string log = oneDatass->first + "		" + oneDatas->first + "		" + std::to_string(temp) + "\n";
			int ret = (int)fwrite(log.c_str(), sizeof(char), log.length(), result);
		}
	}

	fclose(result);
	result = NULL;

	if (!rongYu)
	{
		return;
	}
	for (auto oneDatass = endResult.begin(); oneDatass != endResult.end(); oneDatass++)
	{
		auto twoDatas = oneDatass->second;
		std::string name = "next=======================" + oneDatass->first;
		name += "============================================= \n";
		int ret = (int)fwrite(name.c_str(), sizeof(char), name.length(), rongYu);
		for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		{
			std::string log = oneDatass->first + "		" + std::to_string((int)(*oneDatas)) + " \n";
			int ret = (int)fwrite(log.c_str(), sizeof(char), log.length(), rongYu);
		}
	}

	fclose(rongYu);
	rongYu = NULL;

}

bool CConfStatusPath::LoadCSV(const std::string& str)
{
	CCsvLoader csvLoader;
	if (!csvLoader.LoadCSV(str.c_str()))
	{
		return false;
	}
	m_mapAnimation.clear();
	//如果有数据 
	csvLoader.NextLine();
	csvLoader.NextLine();
	csvLoader.NextLine();
	while (csvLoader.NextLine())
	{
		int key = csvLoader.NextInt();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		csvLoader.NextStr();
		CConfAnalytic::ToJsonInt(csvLoader.NextStr(), m_mapAnimation[key]);
	}
	return true;
}

bool CsvCheck::checkStatusPath()
{
	XXXXXXXXXXX

	m_status = new CConfStatusPath();

	for(auto oneDatas = StatusCsvData.begin(); oneDatas != StatusCsvData.end(); oneDatas++)
	{
		std::string Name = (std::string)(oneDatas->second);
		std::string fileName = "../res/config/Role/Status/" + Name;
		bool isHave = FileUtils::getInstance()->isFileExist(fileName);
		if (isHave)
		{
			if (NULL == m_status || !m_status->LoadCSV(fileName))
			{
#ifndef RunningInServer
                if (CGame::getInstance()->isDebug())
                {
                    cocos2d::MessageBox(("Load " + fileName + " Error!!").c_str(), "Load CSV Error");
                }
#endif 
				return false;
			}
			auto data = m_status->geMapData();
			for (auto j = data.begin(); j != data.end(); j++)
			{
				auto aniData =(std::vector<int>) j->second;
				for (size_t k = 0; k < aniData.size(); k++)
				{
					if (AnimationCsvData.find(aniData.at(k)) == AnimationCsvData.end())
					{
						//没找到一只
						m_checkResult[Name]["Status_CanBreakParam:" + std::to_string(j->first) + "			Q列			" + std::to_string(k)] = aniData.at(k);
					}//找到了说明有用过
					else
					{

						m_XXXX["Animation_csv"].insert(aniData.at(k));
					}
				}

			}
		}
	}

	return true;
}

bool CsvCheck::checkSoldierCsv()
{

	XXXXXXXXXXX
	for (auto oneDatass = SoldierCsvData.begin(); oneDatass != SoldierCsvData.end(); oneDatass++)
	{
		auto twoDatas = oneDatass->second;
		for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		{
			SoldierConfItem* oneData = (SoldierConfItem*)(oneDatas->second);
			//C	
			if (oneData->Common.AnimationID != 0)
			{
				if (ResCsvData.find(oneData->Common.AnimationID) == ResCsvData.end())
				{
					//没找到一只
					m_checkResult["Soldier_csv"]["SoldierId:" + std::to_string(oneData->Common.ClassID) + "		C列	"] = oneData->Common.AnimationID;
				}//找到了说明有用过
				else
				{
					//m_rongYu["Res_csv"][oneData->Common.AnimationID] = 0;
					m_XXXX["Res_csv"].insert(oneData->Common.AnimationID);
				}
			}
			//M
			if (oneData->Common.StatusID != 0)
			{
				if (ResCsvData.find(oneData->Common.StatusID) == ResCsvData.end())
				{
					//没找到一只
					m_checkResult["Soldier_csv"]["SoldierId:" + std::to_string(oneData->Common.ClassID) + "		M列	"] = oneData->Common.StatusID;
				}//找到了说明有用过
				else
				{
					//m_rongYu["AIAndStatus_csv"][oneData->Common.StatusID] = 0;
					m_XXXX["AIAndStatus_csv"].insert(oneData->Common.StatusID);
				}
			}
			//0-Z,为技能,数据读取时,为0是在后边内存中没有存,遍历skill容器就好
			for (size_t i = 0; i < oneData->Common.Skill.size(); i++)
			{
				if (oneData->Common.Skill.at(i) != 0)
				{
					if (SkillCsvData.find(oneData->Common.Skill.at(i)) == SkillCsvData.end())
					{
						//没找到一只
						m_checkResult["Soldier_csv"]["SoldierId:" + std::to_string(oneData->Common.ClassID) + "		O-Z列	" + std::to_string(i)] = oneData->Common.Skill.at(i);
					}//找到了说明有用过
					else
					{
						//m_rongYu["Skill_csv"][oneData->Common.Skill.at(i)] = 0;
						m_XXXX["Skill_csv"].insert(oneData->Common.Skill.at(i));
					}
				}
			}
			// AA
			if (oneData->Common.Name != 0)
			{
				if (HeroSoldierCsvData.find(oneData->Common.Name) == HeroSoldierCsvData.end())
				{
					//没找到一只
					m_checkResult["Soldier_csv"]["SoldierId:" + std::to_string(oneData->Common.ClassID) + "		AA列		"] = oneData->Common.Name;
				}//找到了说明有用过
				else
				{
					//m_rongYu["HeroSoldier_csv"][oneData->Common.Name] = 0;
					m_XXXX["HeroSoldier_csv"].insert(oneData->Common.Name);
				}
			}
			//AB
			if (oneData->Common.Desc != 0)
			{
				if (HeroSoldierCsvData.find(oneData->Common.Desc) == HeroSoldierCsvData.end())
				{
					//没找到一只
					m_checkResult["Soldier_csv"]["SoldierId:" + std::to_string(oneData->Common.ClassID) + "		AB列		"] = oneData->Common.Desc;
				}//找到了说明有用过
				else
				{
					//m_rongYu["HeroSoldier_csv"][oneData->Common.Desc] = 0;
					m_XXXX["HeroSoldier_csv"].insert(oneData->Common.Desc);
				}
			}
		}
	}
	return true;
}

bool CsvCheck::checkHeroCsv()
{
	XXXXXXXXXXX
	for (auto oneDatas = HeroCsvData.begin(); oneDatas != HeroCsvData.end(); oneDatas++)
	{
		HeroConfItem* oneData = (HeroConfItem*)(oneDatas->second);
		//A列不判断

		//C	
		if (oneData->Common.AnimationID != 0)
		{
			if (ResCsvData.find(oneData->Common.AnimationID) == ResCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			C列			"] = oneData->Common.AnimationID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Res_csv"][oneData->Common.AnimationID] = 0;
				m_XXXX["Res_csv"].insert(oneData->Common.AnimationID);
			}
		}
		//K
		if (oneData->Common.StatusID != 0)
		{
			if (StatusCsvData.find(oneData->Common.StatusID) == StatusCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			K列			"] = oneData->Common.StatusID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["AIAndStatus_csv"][oneData->Common.StatusID] = 0;
				m_XXXX["AIAndStatus_csv"].insert(oneData->Common.StatusID);
			}
		}
		//M到X列,为技能,数据读取时,为0是在后边内存中没有存,遍历skill容器就好
		for (size_t i = 0; i < oneData->Common.Skill.size(); i++)
		{
			if (oneData->Common.Skill.at(i) != 0)
			{
				if (SkillCsvData.find(oneData->Common.Skill.at(i)) == SkillCsvData.end())
				{
					//没找到一只
					m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			M-X列			" + std::to_string(i)] = oneData->Common.Skill.at(i);
				}//找到了说明有用过
				else
				{
					//m_rongYu["Skill_csv"][oneData->Common.Skill.at(i)] = 0;
					m_XXXX["Skill_csv"].insert(oneData->Common.Skill.at(1));
				}
			}
		}
		//Y
		if (oneData->Common.Name != 0)
		{
			if (HeroSoldierCsvData.find(oneData->Common.Name) == HeroSoldierCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			Y列			"] = oneData->Common.Name;
			}//找到了说明有用过
			else
			{
				//m_rongYu["HeroSoldier_csv"][oneData->Common.Name] = 0;
				m_XXXX["HeroSoldier_csv"].insert(oneData->Common.Name);
			}
		}
		//Z
		if (oneData->Common.Desc != 0)
		{
			if (HeroSoldierCsvData.find(oneData->Common.Desc) == HeroSoldierCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			Z列			"] = oneData->Common.Desc;
			}//找到了说明有用过
			else
			{
				//m_rongYu["HeroSoldier_csv"][oneData->Common.Desc] = 0;
				m_XXXX["HeroSoldier_csv"].insert(oneData->Common.Desc);
			}
		}
		//AH
		if (oneData->PlayerSkill.at(0) != 0)
		{
			if (SkillCsvData.find(oneData->PlayerSkill.at(0)) == SkillCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			AH列			"] = oneData->PlayerSkill.at(0);
			}//找到了说明有用过
			else
			{
				//m_rongYu["HeroSoldier_csv"][oneData->Common.Desc] = 0;
				m_XXXX["Skill_csv"].insert(oneData->PlayerSkill.at(0));
			}
		}
		//AI
		if (oneData->PlayerSkill.at(1) != 0)
		{
			if (SkillCsvData.find(oneData->PlayerSkill.at(1)) == SkillCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			AI列			"] = oneData->PlayerSkill.at(1);
			}//找到了说明有用过
			else
			{
				//m_rongYu["HeroSoldier_csv"][oneData->Common.Desc] = 0;
				m_XXXX["Skill_csv"].insert(oneData->PlayerSkill.at(1));
			}
		}
		//AJ
		if (oneData->PlayerSkill.at(2) != 0)
		{
			if (SkillCsvData.find(oneData->PlayerSkill.at(2)) == SkillCsvData.end())
			{
				//没找到一只
				m_checkResult["Hero_csv"]["HeroId:" + std::to_string(oneData->Common.ClassID) + "			AJ列			"] = oneData->PlayerSkill.at(2);
			}//找到了说明有用过
			else
			{
				//m_rongYu["HeroSoldier_csv"][oneData->Common.Desc] = 0;
				m_XXXX["Skill_csv"].insert(oneData->PlayerSkill.at(2));
			}
		}
	}

	return true;
}

bool CsvCheck::checkMonsterCsv()
{
	XXXXXXXXXXX
	for (auto oneDatas = MonsterCsvData.begin(); oneDatas != MonsterCsvData.end(); oneDatas++)
	{
		MonsterConfItem* oneData = (MonsterConfItem*)(oneDatas->second);
		//A列不判断

		//C	
		if (oneData->Common.AnimationID != 0)
		{
			if (ResCsvData.find(oneData->Common.AnimationID) == ResCsvData.end())
			{
				//没找到一只
				m_checkResult["Monster_csv"]["MonsterId:" + std::to_string(oneData->Common.ClassID) + "			C列			"] = oneData->Common.AnimationID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Res_csv"][oneData->Common.AnimationID] = 0;
				m_XXXX["Res_csv"].insert(oneData->Common.AnimationID);
			}
		}
		//K
		if (oneData->Common.StatusID != 0)
		{
			if (AICsvData.find(oneData->Common.StatusID) == AICsvData.end())
			{
				//没找到一只
				m_checkResult["Monster_csv"]["MonsterId:" + std::to_string(oneData->Common.ClassID) + "			K列			"] = oneData->Common.StatusID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["AIAndStatus_csv"][oneData->Common.StatusID] = 0;
				m_XXXX["AIAndStatus_csv"].insert(oneData->Common.StatusID);
			}
		}
		//M到X列,为技能,数据读取时,为0是在后边内存中没有存,遍历skill容器就好
		for (size_t i = 0; i < oneData->Common.Skill.size(); i++)
		{
			if (oneData->Common.Skill.at(i) != 0)
			{
				if (SkillCsvData.find(oneData->Common.Skill.at(i)) == SkillCsvData.end())
				{
					//没找到一只
					m_checkResult["Monster_csv"]["MonsterId:" + std::to_string(oneData->Common.ClassID) + "			M-X列			" + std::to_string(i)] = oneData->Common.Skill.at(i);
				}//找到了说明有用过
				else
				{
					//m_rongYu["Skill_csv"][oneData->Common.Skill.at(i)] = 0;
					m_XXXX["Skill_csv"].insert(oneData->Common.Skill.at(i));
				}
			}
		}
		//Y
		if (oneData->Common.Name != 0)
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Name) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Monster_csv"]["MonsterId:" + std::to_string(oneData->Common.ClassID) + "			Y列			"] = oneData->Common.Name;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Name] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Name);
			}
		}
		//Z
		if (oneData->Common.Desc != 0)
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Desc) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Monster_csv"]["MonsterId:" + std::to_string(oneData->Common.ClassID) + "			Z列			"] = oneData->Common.Desc;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Desc] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Desc);
			}
		}
	}
	return true;
}

bool CsvCheck::checkCallCsv()
{
	XXXXXXXXXXX
	for (auto oneDatas = CallCsvData.begin(); oneDatas != CallCsvData.end(); oneDatas++)
	{
		CallConfItem* oneData = (CallConfItem*)(oneDatas->second);
		//A列不做检查

		//C	
		if (oneData->Common.AnimationID != 0)
		{
			if (ResCsvData.find(oneData->Common.AnimationID) == ResCsvData.end())
			{
				//没找到一只
				m_checkResult["Call_csv"]["CallId:" + std::to_string(oneData->Common.ClassID) + "		C列		"] = oneData->Common.AnimationID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Res_csv"][oneData->Common.AnimationID] = 0;
				m_XXXX["Res_csv"].insert(oneData->Common.AnimationID);
			}
		}
		//K
		if (oneData->Common.StatusID != 0)
		{
			if (AICsvData.find(oneData->Common.StatusID) == AICsvData.end())
			{
				//没找到一只
				m_checkResult["Call_csv"]["CallId:" + std::to_string(oneData->Common.ClassID) + "	K列		"] = oneData->Common.StatusID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["AIAndStatus_csv"][oneData->Common.StatusID] = 0;
				m_XXXX["AIAndStatus_csv"].insert(oneData->Common.StatusID);
			}
		}
		//M到X列,为技能,数据读取时,为0是在后边内存中没有存,遍历skill容器就好
		for (size_t i = 0; i < oneData->Common.Skill.size(); i++)
		{
			if (oneData->Common.Skill.at(i) != 0)
			{
				if (SkillCsvData.find(oneData->Common.Skill.at(i)) == SkillCsvData.end())
				{
					//没找到一只
					m_checkResult["Call_csv"]["CallId:" + std::to_string(oneData->Common.ClassID) + "	M-X列	" + std::to_string(i)] = oneData->Common.Skill.at(i);
				}//找到了说明有用过
				else
				{
					//m_rongYu["Skill_csv"][oneData->Common.Skill.at(i)] = 0;
					m_XXXX["Skill_csv"].insert(oneData->Common.Skill.at(i));
				}
			}
		}
		//Y
		if (oneData->Common.Name != 0)
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Name) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Call_csv"]["CallId:" + std::to_string(oneData->Common.ClassID) +	"	Y列		"] = oneData->Common.Name;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Name] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Name);
			}
		}
		//Z
		if (oneData->Common.Desc != 0)
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Desc) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Call_csv"]["CallId:" + std::to_string(oneData->Common.ClassID) + "	Z列		"] = oneData->Common.Desc;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Desc] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Desc);
			}
		}
	}

	return true;
}

bool CsvCheck::checkBossCsv()
{
	XXXXXXXXXXX
	for (auto oneDatas = BossCsvData.begin(); oneDatas != BossCsvData.end(); oneDatas++)
	{
		BossConfItem* oneData = (BossConfItem*)(oneDatas->second);
		//A列不做检查

		//C	
		if (oneData->Common.AnimationID != 0)
		{
			if (ResCsvData.find(oneData->Common.AnimationID) == ResCsvData.end())
			{
				//没找到一只
				m_checkResult["Boss_csv"]["BossId:" + std::to_string(oneData->Common.ClassID) +	"			C列			"] = oneData->Common.AnimationID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Res_csv"][oneData->Common.AnimationID] = 0;
				m_XXXX["Res_csv"].insert(oneData->Common.AnimationID);
			}
		}
		//k	
		if (oneData->Common.StatusID != 0 )
		{
			if (AICsvData.find(oneData->Common.StatusID) == AICsvData.end())
			{
				//没找到一只
				m_checkResult["Boss_csv"]["BossId:" + std::to_string(oneData->Common.ClassID) + "			K列			"] = oneData->Common.StatusID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["AIAndStatus_csv"][oneData->Common.StatusID] = 0;
				m_XXXX["AIAndStatus_csv"].insert(oneData->Common.StatusID);
			}
		}
		//M到X列,为技能,数据读取时,为0是在后边内存中没有存,遍历skill容器就好
		for (size_t i = 0; i < oneData->Common.Skill.size(); i++)
		{
			if (oneData->Common.Skill.at(i) != 0)
			{
				if (SkillCsvData.find(oneData->Common.Skill.at(i)) == SkillCsvData.end())
				{
					//没找到一只
					m_checkResult["Boss_csv"]["BossId:" + std::to_string(oneData->Common.ClassID) + "			M-X列			" + std::to_string(i)] = oneData->Common.Skill.at(i);
				}//找到了说明有用过
				else
				{
					//m_rongYu["Skill_csv"][oneData->Common.Skill.at(i)] = 0;
					m_XXXX["Skill_csv"].insert(oneData->Common.Skill.at(i));
				}
			}
		}
		//Y列
		if (oneData->Common.Name != 0 )
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Name) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Boss_csv"]["BossId:" + std::to_string(oneData->Common.ClassID) + "			Y列			"] = oneData->Common.Name;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Name] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Name);
			}
		}
		//Z
		if (oneData->Common.Desc != 0 )
		{
			if (BossMonsterCallCsvData.find(oneData->Common.Desc) == BossMonsterCallCsvData.end())
			{
				//没找到一只
				m_checkResult["Boss_csv"]["BossId:" + std::to_string(oneData->Common.ClassID) + "			Y列			"] = oneData->Common.Desc;
			}//找到了说明有用过
			else
			{
				//m_rongYu["BossMonsterCall_csv"][oneData->Common.Desc] = 0;
				m_XXXX["BossMonsterCall_csv"].insert(oneData->Common.Desc);
			}
		}
	}
	return true;
}

bool CsvCheck::checkAIAndStatusCsv()
{
	XXXXXXXXXXX
	for (auto oneDatas = AICsvData.begin(); oneDatas != AICsvData.end(); oneDatas++)
	{
		std::string fileName = (std::string)(oneDatas->second);
		auto pathName = "../res/config/Role/AI/"+fileName;
		bool isHave = FileUtils::getInstance()->isFileExist(pathName);
		//B
		if (!isHave)
		{
			//没查到
			m_checkResult["AIAndStatus_csv"]["AI:" + oneDatas->second] = oneDatas->first;
		}
		else
		{
			//查到了
			m_XXXX["AIAndStatus_csv"].insert(oneDatas->first);
		}

	}
	for (auto oneDatas = StatusCsvData.begin(); oneDatas != StatusCsvData.end(); oneDatas++)
	{
		std::string fileName = (std::string)(oneDatas->second);
		auto pathName = "../res/config/Role/Status/" + fileName;
		//C
		bool isHave = FileUtils::getInstance()->isFileExist(pathName);
		if (!isHave)
		{
			//没查到
			m_checkResult["AIAndStatus_csv"]["Status:" + oneDatas->second] = oneDatas->first;
		}
		else
		{
			//查到了
			m_XXXX["AIAndStatus_csv"].insert(oneDatas->first);
		}
	}
	return true;
}

bool CsvCheck::checkSkillCsv()
{
	XXXXXXXXXXX
	//std::map<int, std::map<int, SkillConfItem*> >
	for (auto oneDatass = SkillCsvData.begin(); oneDatass != SkillCsvData.end(); oneDatass++)
	{
		//auto twoDatas = oneDatass->second;
		//for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		//{
		//	SkillConfItem* oneData = (SkillConfItem*)(oneDatas->second);
		//	//R
		//	for (size_t j = 0; j < oneData->Buff.size(); j++)
		//	{
		//		if (oneData->Buff.at(j).ID != 0 )
		//		{
		//			if (BuffCsvData.find(oneData->Buff.at(j).ID) == BuffCsvData.end())
		//			{
		//				//没找到一只
		//				m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			R列			" + std::to_string(j)] = oneData->Buff.at(j).ID;
		//			}//
		//			else
		//			{
		//				//m_rongYu["Buff_csv"][oneData->Buff.at(j).ID] = 0;
		//				m_XXXX["Buff_csv"].insert(oneData->Buff.at(j).ID);
		//			}
		//		}
		//	}
		//	//O
		//	for (size_t j = 0; j < oneData->TargetBullet.size(); j++)
		//	{
		//		if (oneData->TargetBullet.at(j) != 0)
		//		{
		//			if (BulletCsvData.find(oneData->TargetBullet.at(j)) == BulletCsvData.end())
		//			{
		//				//没找到一只
		//				m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			O列			" + std::to_string(j)] = oneData->TargetBullet.at(j);
		//			}//
		//			else
		//			{
		//				//m_rongYu["Bullet_csv"][oneData->TargetBullet.at(j)] = 0;
		//				m_XXXX["Bullet_csv"].insert(oneData->TargetBullet.at(j));
		//			}
		//		}
		//	}
		//	//P
		//	//if (oneData->TargetBulletDelay != 0 )
		//	//{
		//	//	if (BulletCsvData.find(oneData->TargetBulletDelay*1000) == BulletCsvData.end())
		//	//	{
		//	//		//没找到一只
		//	//		m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "		P列		"] = oneData->TargetBulletDelay*1000;
		//	//	}//
		//	//	else
		//	//	{
		//	//		//m_rongYu["Bullet_csv"][oneData->TargetBulletDelay] = 0;
		//	//		m_XXXX["Bullet_csv"].insert(oneData->TargetBulletDelay*1000);
		//	//	}
		//	//}
		//	////Q
		//	//if (oneData->TargetBulletInterval != 0)
		//	//{
		//	//	if (BulletCsvData.find(oneData->TargetBulletInterval*1000) == BulletCsvData.end())
		//	//	{
		//	//		//没找到一只
		//	//		m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "		Q列		"] = oneData->TargetBulletInterval*1000;
		//	//	}//
		//	//	else
		//	//	{
		//	//		//m_rongYu["Bullet_csv"][oneData->TargetBulletInterval] = 0;
		//	//		m_XXXX["Bullet_csv"].insert(oneData->TargetBulletInterval*1000);
		//	//	}
		//	//}
		//	//R
		//	for (size_t j = 0; j < oneData->Buff.size(); j++)
		//	{
		//		if (oneData->Buff.at(j).ID != 0)
		//		{
		//			if (BuffCsvData.find(oneData->Buff.at(j).ID) == BuffCsvData.end())
		//			{
		//				//没找到一只
		//				m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			R列			" + std::to_string(j)] = oneData->Buff.at(j).ID;
		//			}//
		//			else
		//			{
		//				//m_rongYu["Bullet_csv"][oneData->Buff.at(j).ID] = 0;
		//				m_XXXX["Buff_csv"].insert(oneData->Buff.at(j).ID);
		//			}
		//		}
		//	}
		//	//S
		//	for (size_t j = 0; j < oneData->PointBullet.size(); j++)
		//	{
		//		if (oneData->PointBullet.at(j) != 0)
		//		{
		//			if (BulletCsvData.find(oneData->PointBullet.at(j)) == BulletCsvData.end())
		//			{
		//				//没找到一只
		//				m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			S列			" + std::to_string(j)] = oneData->PointBullet.at(j);
		//			}//
		//			else
		//			{
		//				//m_rongYu["Bullet_csv"][oneData->PointBullet.at(j)] = 0;
		//				m_XXXX["Bullet_csv"].insert(oneData->PointBullet.at(j));
		//			}
		//		}
		//	}
		//	//V
		//	for (size_t j = 0; j < oneData->Call.size(); j++)
		//	{
		//		if (oneData->Call.at(j))
		//		{
		//			if (CallCsvData.find(oneData->Call.at(j)) == CallCsvData.end())
		//			{
		//				//没找到一只
		//				m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			V列			" + std::to_string(j)] = oneData->Call.at(j);
		//			}//
		//			else
		//			{
		//				//m_rongYu["Call_csv"][oneData->Call.at(j)] = 0;
		//				m_XXXX["Call_csv"].insert(oneData->Call.at(j));
		//			}
		//		}
		//	}
		//	//X
		//	if (oneData->Name !=0)
		//	{
		//		if (HeroSoldierSkillCsvData.find(oneData->Name) == HeroSoldierSkillCsvData.end())
		//		{
		//			//没找到一只
		//			m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			X列			"] = oneData->Name;
		//		}//
		//		else
		//		{
		//			//m_rongYu["HeroSoldierSkill_csv"][oneData->Name] = 0;
		//			m_XXXX["HeroSoldierSkill_csv"].insert(oneData->Name);
		//		}
		//	}
		//	//Y
		//	if (oneData->CostDesc1 != 0)
		//	{
		//		if (HeroSoldierSkillCsvData.find(oneData->CostDesc1) == HeroSoldierSkillCsvData.end())
		//		{
		//			//没找到一只
		//			m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			Y列			"] = oneData->CostDesc1;
		//		}//
		//		else
		//		{
		//			//m_rongYu["HeroSoldierSkill_csv"][oneData->CostDesc1] = 0;
		//			m_XXXX["HeroSoldierSkill_csv"].insert(oneData->CostDesc1);
		//		}
		//	}
		//	//Z
		//	if (oneData->CostDesc2 != 0)
		//	{
		//		if (HeroSoldierSkillCsvData.find(oneData->CostDesc2) == HeroSoldierSkillCsvData.end())
		//		{
		//			//没找到一只
		//			m_checkResult["Skill_csv"]["SkillId:" + std::to_string(oneData->ID) + "			Z列			"] = oneData->CostDesc2;
		//		}//
		//		else
		//		{
		//			//m_rongYu["HeroSoldierSkill_csv"][oneData->CostDesc2] = 0;
		//			m_XXXX["HeroSoldierSkill_csv"].insert(oneData->CostDesc2);
		//		}
		//	}
		//}
	}
	return true;
}	  

bool CsvCheck::checkSearchCsv()
{
	XXXXXXXXXXX
	auto StateNameToIDCsvData = CConfManager::getInstance()->getStateNameToIDConf()->getConvertData();
	for (auto oneDatass = SearchCsvData.begin(); oneDatass != SearchCsvData.end(); oneDatass++)
	{

		SearchConfItem* oneData = (SearchConfItem*)(oneDatass->second);
		//O
		for (size_t j = 0; j < oneData->Buff.size(); j++)
		{
			if (BuffCsvData.find(oneData->Buff.at(j)) == BuffCsvData.end())
			{
				//没找到一只
				m_checkResult["Search_csv"]["SearchId:" + std::to_string(oneData->ID) + "			O列			" + std::to_string(j)] = oneData->Buff.at(j);
			}
			else
			{
				//m_rongYu["Buff_csv"][oneData->Buff.at(j)] = 0;
				m_XXXX["Buff_csv"].insert(oneData->Buff.at(j));
			}
		}
		//p
		for (size_t j = 0; j < oneData->State.size(); j++)
		{
			if (oneData->State.at(j) == 0)
			{
				continue;
			}

			auto iter = StateNameToIDCsvData.begin();
			for (; iter != StateNameToIDCsvData.end(); ++iter)
			{
				int var = (int)(iter->second);
				if (var != 0 && var == oneData->State.at(j))
				{//找到了说明有用过
					//m_rongYu["StateNameToID_csv"][oneData->State.at(j)] = 0;
					m_XXXX["StateNameToID_csv"].insert(oneData->State.at(j));
					break;
				}
			}
			if (iter == StateNameToIDCsvData.end())
			{
				//没找到一只
				m_checkResult["Search_csv"]["SearchId:" + std::to_string(oneData->ID) + "			P列			"+std::to_string(j)] = oneData->State.at(j);
				//找到了
			}
		}
	}
	return true;
}

bool CsvCheck::checkCountCsv()
{
	XXXXXXXXXXX
	auto StateNameToIDCsvData = CConfManager::getInstance()->getStateNameToIDConf()->getConvertData();
	//std::map<std::string, int> 

	for (auto oneDatas = CountCsvData.begin(); oneDatas != CountCsvData.end(); oneDatas++)
	{
		CountConfItem* oneData = (CountConfItem*)(oneDatas->second);
		//P
		for (size_t i = 0; i < oneData->CardCountID.size(); i++)
		{
			if (oneData->CardCountID.at(i)!=0 && CardCountCsvData.find(oneData->CardCountID.at(i)) == CardCountCsvData.end())
			{
				//没找到一只
				m_checkResult["Count_csv"]["CountId:" + std::to_string(oneData->ID) + "			P列			" + std::to_string(i)] = oneData->CardCountID.at(i);
			}//找到了说明有用过
			else
			{
				//m_rongYu["CardCount_csv"][oneData->CardCountID.at(i)] = 0;
				m_XXXX["CardCount_csv"].insert(oneData->CardCountID.at(i));
			}
		}
		if ( oneData->Status != 0)
		{
			//N
			auto iter = StateNameToIDCsvData.begin();
			for (; iter != StateNameToIDCsvData.end(); ++iter)
			{
				int var = (int)(iter->second);
				if (var != 0 && var == oneData->Status)
				{//找到了说明有用过
					//m_rongYu["StateNameToID_csv"][oneData->Status] = 0;
					m_XXXX["StateNameToID_csv"].insert(oneData->Status);
					break;
				}
			}
			if (iter == StateNameToIDCsvData.end())
			{
				//没找到一只
				m_checkResult["Count_csv"]["CountId:" + std::to_string(oneData->ID) + "			N列			"] = oneData->Status;
			}
		} 

	}
	return true;
}

bool CsvCheck::checkBulletCsv()
{
	XXXXXXXXXXX
	//检查bulletcsv
	for (auto oneData = BulletCsvData.begin(); oneData != BulletCsvData.end(); oneData++)
	{
		//L列为2时M列的值 
		BulletConfItem* data = (BulletConfItem*)oneData->second;
		if (data->HitJudgeType==2 && SearchCsvData.find(data->HitJudgeParam) == SearchCsvData.end())
		{
			//没找到一只
			m_checkResult["Bullet_csv"]["BulletId:"+std::to_string(data->ID) + "			M列			"] = data->HitJudgeParam;
		}//找到了说明有用过
		else
		{
			//m_rongYu["Search_csv"][data->HitJudgeParam] = 0;
			m_XXXX["Search_csv"].insert(data->HitJudgeParam);
		}
		//R 列
		for (auto j = 0; j != data->CountId.size(); j++)
		{
			if (CountCsvData.find(data->CountId.at(j)) == CountCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			R列			" + std::to_string(j)] = data->CountId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Search_csv"][data->CountId.at(j)] = 0;
				m_XXXX["Search_csv"].insert(data->CountId.at(j));
			}
		}
		//S列
		for (auto j = 0; j != data->SummonerCountId.size(); j++)
		{
			if (CountCsvData.find(data->SummonerCountId.at(j)) == CountCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			S列			" + std::to_string(j)] = data->SummonerCountId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Search_csv"][data->SummonerCountId.at(j)] = 0;
				m_XXXX["Search_csv"].insert(data->SummonerCountId.at(j));
			}
		}

		//T列
		for (auto j = 0; j != data->BuffId.size(); j++)
		{
			if (BuffCsvData.find(data->BuffId.at(j).ID) == BuffCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			T列			" + std::to_string(j)] = data->BuffId.at(j).ID;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Search_csv"][data->BuffId.at(j).ID] = 0;
				m_XXXX["Search_csv"].insert(data->BuffId.at(j).ID);
			}
		}
		//U
		for (auto j = 0; j != data->AnimationId.size(); j++)
		{
			if (AnimationCsvData.find(data->AnimationId.at(j)) == AnimationCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			U列			" + std::to_string(j)] = data->AnimationId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Animation_csv"][data->AnimationId.at(j)] = 0;
				m_XXXX["Animation_csv"].insert(data->AnimationId.at(j));
			}
		}
		//V
		for (auto j = 0; j != data->EndAnimationId.size(); j++)
		{
			if (AnimationCsvData.find(data->EndAnimationId.at(j)) == AnimationCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			V列			" + std::to_string(j)] = data->EndAnimationId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Animation_csv"][data->EndAnimationId.at(j)] = 0;
				m_XXXX["Animation_csv"].insert(data->EndAnimationId.at(j));
			}
		}
		//W
		for (auto j = 0; j != data->HitAnimationId.size(); j++)
		{
			if (AnimationCsvData.find(data->HitAnimationId.at(j)) == AnimationCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			W列			" + std::to_string(j)] = data->HitAnimationId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Animation_csv"][data->HitAnimationId.at(j)] = 0;
				m_XXXX["Animation_csv"].insert(data->HitAnimationId.at(j));
			}
		}
		//X
		for (auto j = 0; j != data->HitAllAnimationId.size(); j++)
		{
			if (AnimationCsvData.find(data->HitAllAnimationId.at(j)) == AnimationCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			X列			" + std::to_string(j)] = data->HitAllAnimationId.at(j);
			}//找到了说明有用过
			else
			{
				//m_rongYu["Animation_csv"][data->HitAllAnimationId.at(j)] = 0;
				m_XXXX["Animation_csv"].insert(data->HitAllAnimationId.at(j));
			}
		}
		//Z
		if (data->UiEffectTime != 0)
		{
			if (UIEeffectCsvData.find(data->UiEffectTime) == UIEeffectCsvData.end())
			{
				//没找到一只
				m_checkResult["Bullet_csv"]["BulletId:" + std::to_string(data->ID) + "			Z列			"] = data->UiEffectTime;
			}//找到了说明有用过
			else
			{
				//m_rongYu["Search_csv"][data->UiEffectTime] = 0;
				m_XXXX["Search_csv"].insert(data->UiEffectTime);
			}
		}

	}
	
	return true;
}

bool CsvCheck::checkAnimationCsv()
{
	XXXXXXXXXXX
	//检查AnimationCsv C列 AnimationName字段
	for (auto oneDatas = AnimationCsvData.begin(); oneDatas != AnimationCsvData.end(); oneDatas++)
	{
		EffectConfItem* oneData = (EffectConfItem*)(oneDatas->second);
		//C
		if (ResCsvData.find(oneData->ResID) == ResCsvData.end())
		{
			//没找到一只
			m_checkResult["Animation_csv"]["EffectId:"+std::to_string(oneData->EffectId) + "			C列			"] = oneData->ResID;
		}//找到了说明有用过
		else
		{
			//m_rongYu["Res_csv"][oneData->ResID] = 0;
			m_XXXX["Res_csv"].insert(oneData->ResID);
		}
	}
	return true;
}

bool CsvCheck::checkBuffCsv()
{
	XXXXXXXXXXX
	for (auto oneDatass = BuffCsvData.begin(); oneDatass != BuffCsvData.end(); oneDatass++)
	{
		auto twoDatas = oneDatass->second;
		for (auto oneDatas = twoDatas.begin(); oneDatas != twoDatas.end(); oneDatas++)
		{
			BuffConfItem* oneData = (BuffConfItem*)(oneDatas->second);
			//H
			for (size_t j = 0; j < oneData->AnimationID.size(); j++)
			{
				if (oneData->AnimationID.at(j) != 0 )
				{
					if (AnimationCsvData.find(oneData->AnimationID.at(j)) == AnimationCsvData.end())
					{
						//没找到一只
						m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			H列			" + std::to_string(j)] = oneData->AnimationID.at(j);
					}//
					else
					{
						//m_rongYu["Animation_csv"][oneData->AnimationID.at(j)] = 0;
						m_XXXX["Animation_csv"].insert(oneData->AnimationID.at(j));
					}
				}
			}
			//U
			for (size_t j = 0; j < oneData->CountID.size(); j++)
			{
				if (oneData->CountID.at(j) != 0)
				{
					if (CountCsvData.find(oneData->CountID.at(j)) == CountCsvData.end())
					{
						//没找到一只
						m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			U列			" + std::to_string(j)] = oneData->CountID.at(j);
					}
					else
					{
						//m_rongYu["Count_csv"][oneData->CountID.at(j)] = 0;
						m_XXXX["Count_csv"].insert(oneData->CountID.at(j));
					}
				}
			}
			//V
			for (size_t j = 0; j < oneData->SummonerCountID.size(); j++)
			{
				if (oneData->SummonerCountID.at(j) != 0)
				{
					if (CountCsvData.find(oneData->SummonerCountID.at(j)) == CountCsvData.end())
					{
						//没找到一只
						m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			V列			" + std::to_string(j)] = oneData->SummonerCountID.at(j);
					}
					else
					{
						//m_rongYu["Count_csv"][oneData->SummonerCountID.at(j)] = 0;
						m_XXXX["Count_csv"].insert(oneData->SummonerCountID.at(j));
					}
				}
			}
			//W
			for (size_t j = 0; j < oneData->LapseCountID.size(); j++)
			{
				if (oneData->LapseCountID.at(j) != 0)
				{
					if (CountCsvData.find(oneData->LapseCountID.at(j)) == CountCsvData.end())
					{
						//没找到一只
						m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			W列			" + std::to_string(j)] = oneData->LapseCountID.at(j);
					}
					else
					{
						//m_rongYu["Count_csv"][oneData->LapseCountID.at(j)] = 0;
						m_XXXX["Count_csv"].insert(oneData->LapseCountID.at(j));
					}
				}

			}
			//X
			for (size_t j = 0; j < oneData->SummonerLapseCountID.size(); j++)
			{
				if (oneData->SummonerLapseCountID.at(j) != 0 )
				{
					if (CountCsvData.find(oneData->SummonerLapseCountID.at(j)) == CountCsvData.end())
					{
						//没找到一只
						m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			X列			" + std::to_string(j)] = oneData->SummonerLapseCountID.at(j);
					}
					else
					{
						//m_rongYu["Count_csv"][oneData->SummonerLapseCountID.at(j)] = 0;
						m_XXXX["Count_csv"].insert(oneData->SummonerLapseCountID.at(j));
					}
				}
			}
			//Y
			if (oneData->SkillID != 0)
			{
				if (SkillCsvData.find(oneData->SkillID) == SkillCsvData.end())
				{
					//没找到一只
					m_checkResult["Buff_csv"]["BuffId:" + std::to_string(oneData->ID) + "			Y列			"] = oneData->SkillID;
				}
				else
				{
					//m_rongYu["Count_csv"][oneData->SkillID] = 0;
					m_XXXX["Skill_csv"].insert(oneData->SkillID);
				}
			}

		}
	}
	return true;
}

bool CsvCheck::checkStageCsv()
{
	XXXXXXXXXXX
		std::string strStageCSvRootPath = "../res/config/Stage/Stages/";
	for (auto oneData = StageCsvData.begin(); oneData != StageCsvData.end(); ++oneData)
	{
		//检查A列，在目录下是否有该csv文件
		char temp[10] = {};
		sprintf(temp, "%d", oneData->first);
		std::string strStageCsv(temp);
		strStageCsv = strStageCSvRootPath + strStageCsv + "_Stage.csv";
		if (FileUtils::getInstance()->isFileExist(strStageCsv))
		{
			//硬盘上存在该csv文件
		}
		else
		{
			//硬盘上不存在该csv文件
			m_checkResult["Stage_csv"]["StageID:" + oneData->first] = oneData->first;
		}

		//检查C列，在StageScene表中是否有相应主键
		int StageSceneID = ((StageConfItem*)(oneData->second))->StageSenceID;
		if (StageSceneData.find(StageSceneID) != StageSceneData.end())
		{
			//m_rongYu["StageScene_csv"][StageSceneID] = StageSceneID;
			m_XXXX["StageScene_csv"].insert(StageSceneID);
		}
		else
		{
			m_checkResult["Stage_csv"]["StageSceneID:" + std::to_string(StageSceneID) + "			C列			"] = StageSceneID;
		}

		//检查D列，在BOSS表中是否有相应主键
		int BossID = ((StageConfItem*)(oneData->second))->Boss;
		if (BossCsvData.find(BossID) != BossCsvData.end())
		{
			//m_rongYu["Boss_csv"][BossID] = BossID;
			m_XXXX["Boss_csv"].insert(BossID);
		}
		else
		{
			m_checkResult["Stage_csv"]["BossID:" + std::to_string(BossID) + "			D列			"] = BossID;
		}

		//检查E-K列，在MONSTER表中是否有相应主键
		for (VecInt::iterator vecit = ((StageConfItem*)(oneData->second))->Monsters.begin(); vecit != ((StageConfItem*)(oneData->second))->Monsters.end(); ++vecit)
		{
			if (MonsterCsvData.find(*vecit) != MonsterCsvData.end())
			{
				//m_rongYu["Monster_csv"][*vecit] = *vecit;
				m_XXXX["Monster_csv"].insert(*vecit);
			}
			else
			{
				m_checkResult["Stage_csv"]["MonsterID:" + std::to_string(*vecit)+"			E-K列			"] = *vecit;
			}
		}

		//检查Y列，在Call表中是否有对应主键
		for (std::vector<SSceneCall>::iterator vecit = ((StageConfItem*)(oneData->second))->SceneCall.begin();
			vecit != ((StageConfItem*)(oneData->second))->SceneCall.end(); ++vecit)
		{
			if (CallCsvData.find((*vecit).callID) != CallCsvData.end())
			{
				//m_rongYu["Call_csv"][(*vecit).callID] = (*vecit).callID;
				m_XXXX["Call_csv"].insert((*vecit).callID);
			}
			else
			{
				m_checkResult["Stage_csv"]["CallID:" + std::to_string((*vecit).callID) + "			Y列			"] = (*vecit).callID;
			}
		}

		//检查U-X列，在itemDrop表中是否有相应的主键
		for (VecInt::iterator vecit = ((StageConfItem*)(oneData->second))->ItemDrop.begin(); vecit != ((StageConfItem*)(oneData->second))->ItemDrop.end(); ++vecit)
		{
			if (ItemDropData.find(*vecit) != ItemDropData.end())
			{
				//m_rongYu["ItemDrop_csv"][*vecit] = *vecit;
				m_XXXX["ItemDrop_csv"].insert((*vecit));
			}
			else
			{
				m_checkResult["Stage_csv"]["ItemDropID:" + std::to_string(*vecit) + "			UVW列			"] = *vecit;
			}
		}
		if (ItemDropData.find(((StageConfItem*)(oneData->second))->FirstItemDrop) != ItemDropData.end())
		{
			//m_rongYu["ItemDrop_csv"][((StageConfItem*)(oneData->second))->FirstItemDrop] = ((StageConfItem*)(oneData->second))->FirstItemDrop;
			m_XXXX["ItemDrop_csv"].insert(((StageConfItem*)(oneData->second))->FirstItemDrop);
		}
		else
		{
			m_checkResult["Stage_csv"]["ItempDropID:" + std::to_string(((StageConfItem*)(oneData->second))->FirstItemDrop)+ "			X列			"] = ((StageConfItem*)(oneData->second))->FirstItemDrop;
		}
	}
	return true;
}

bool CsvCheck::checkResCsv()
{
	XXXXXXXXXXX
	for (auto oneData = ResCsvData.begin(); oneData != ResCsvData.end(); ++oneData)
	{
		std::string ResPathRoot = "../res/";
		if (!((SResPathItem*)(oneData->second))->Path.empty())
		{
			std::string ResPath = ResPathRoot + ((SResPathItem*)(oneData->second))->Path;
			if (FileUtils::getInstance()->isFileExist(ResPath))
			{
				//硬盘上存在该csv文件
				m_XXXX["Res_csv"].insert(oneData->first);
			}
			else
			{
				//硬盘上不存在该文件
				m_checkResult["Res_csv"]["ResID" + std::to_string(oneData->first) + "json/csb	"] = oneData->first;
			}
		}

		if (!((SResPathItem*)(oneData->second))->AtlasPath.empty())
		{
			std::string ResAtlasPath = ResPathRoot + ((SResPathItem*)(oneData->second))->AtlasPath;
			if (FileUtils::getInstance()->isFileExist(ResAtlasPath))
			{
				//硬盘上存在该csv文件
				m_XXXX["Res_csv"].insert(oneData->first);
			}
			else
			{
				//硬盘上不存在该文件
				m_checkResult["Res_csv"]["ResID" + std::to_string(oneData->first) + "AtlasPath		"] = oneData->first;
			}
		}
	}
	return true;
}

bool CsvCheck::checkResPreload()
{
	XXXXXXXXXXX
	for (auto oneData = ResRolePreloadData.begin(); oneData != ResRolePreloadData.end(); ++oneData)
	{
		for (auto iter = oneData->second.begin(); iter != oneData->second.end(); ++iter)
		{
			for (auto vecit = iter->second->ResIDs.begin(); vecit != iter->second->ResIDs.end(); ++vecit)
			{
				if (ResCsvData.find(*vecit) != ResCsvData.end())
				{
					//m_rongYu["Res_csv"][*vecit] = *vecit;
					m_XXXX["Res_csv"].insert(*vecit);
				}
				else
				{
					m_checkResult["ResPreloadn_csv"]["ResID" + std::to_string(*vecit)] = *vecit;
				}
			}
		}
	}
	return true;
}

#endif //WIN32