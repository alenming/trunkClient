#include "ModelData.h"
#include "LoginProtocol.h"
#include "ConfManager.h"
#include "ConfLanguage.h"
#include "GameModel.h"

using namespace std;

CUserModel::CUserModel() :m_nUserID(0)
, m_nHeadID(0)
, m_nGold(0)
, m_nLevel(0)
, m_nUserExp(0)
, m_nDiamond(0)
, m_nTowerCoin(0)
, m_nPvpCoin(0)
, m_nUnionContrib(0)
, m_nMaxEnergy(0)
, m_nVipLv(0)
, m_nPayment(0)
, m_nVipScore(0)
, m_nChangeNameFree(0)
, m_nBuyGoldTimes(0)
{
	memset(m_cUserName, 0, sizeof(m_cUserName));
}

bool CUserModel::init(void *data)
{
	LoginUserModelInfo *info = reinterpret_cast<LoginUserModelInfo *>(data);
	memset(m_cUserName, 0, sizeof(m_cUserName));
	memcpy(m_cUserName, info->name, strlen(info->name));
	m_nUserID = info->userId;
	m_nDiamond = info->diamond;
	m_nGold = info->gold;
	m_nHeadID = info->headId;
	m_nLevel = info->cuserLv;
	m_nFlashcard = info->flashcard;
	m_nMaxEnergy = 10;
	m_nUserExp = info->userExp;
    m_nPayment = info->payment;
	m_nTowerCoin = info->towerCoin;
	m_nPvpCoin = info->pvpCoin;
	m_nUnionContrib = info->unionContrib;

    m_nTotalSignDay = info->nTotalSignDay;          //累计签到天数
    m_nMonthSignDay = info->nMonthSignDay;          //当月累计签到天数
    m_nTotalSignFlag = info->nTotalSignFlag;	    //累计签到次数

    m_nMonthCardStamp = info->monthCardStamp;
	m_nChangeNameFree = info->changeNameFree;
	m_nBuyGoldTimes = info->sbuyGoldTimes;
    m_nFreeHeroTimes = info->cfreeHeroTimes;
	return true;
}

void CUserModel::setUserName(const char* name)
{
    if (strlen(name) < sizeof(m_cUserName))
    {
        memset(m_cUserName, 0, sizeof(m_cUserName));
        memcpy(m_cUserName, name, strlen(name));
    }
}

void CUserModel::resetUserData()
{
    m_nBuyGoldTimes = 0;
}

CBagModel::CBagModel()
: m_nCurCapacity(0)
{
}

bool CBagModel::init(void *data)
{
	LoginBagModelInfo *info = reinterpret_cast<LoginBagModelInfo *>(data);
	BagItemInfo *item = reinterpret_cast<BagItemInfo*>(info + 1);
	for (int i = 0; i < info->count; ++i)
	{
		m_mapBagItems[item->id] = item->val;
		++item;
	}

	return true;
}

bool CBagModel::extra(int add)
{
	if (add < 0)
	{
		return false;
	}
    m_nCurCapacity += add;
	return true;
}

bool CBagModel::addItem(int id, int param)
{
	auto iter = m_mapBagItems.find(id);
	if (iter == m_mapBagItems.end())
	{
		m_mapBagItems[id] = param;
	}
	else
	{		
		m_mapBagItems[id] += param;
	}
	return true;
}

bool CBagModel::removeItem(int id)
{
	auto iter = m_mapBagItems.find(id);
	if (iter == m_mapBagItems.end())
	{
		return false;
	}
	else
	{
		if (iter->first > 1000000)
		{
			m_mapBagItems.erase(iter);
		}
		else
		{
			if (iter->second - 1 == 0)
			{
				m_mapBagItems.erase(iter);
			}
			else
			{
				iter->second -= 1;
			}
		}
	}

	return true;
}

bool CBagModel::removeItems(int id, int count)
{
    bool b = false;
    auto iter = m_mapBagItems.find(id);
    if (iter != m_mapBagItems.end())
    {
        if (iter->first > 1000000)
        {
            m_mapBagItems.erase(iter);
            b = true;
        }
        else
        {
            if (iter->second == count)
            {
                m_mapBagItems.erase(iter);
                b = true;
            }
            else if (iter->second - count > 0)
            {
                iter->second -= count;
                b = true;
            }
        }
    }

    return b;
}

bool CBagModel::hasItem(int id)
{
	auto iter = m_mapBagItems.find(id);
	return iter != m_mapBagItems.end();
}

bool CEquipModel::init(void *data)
{
	LoginEquipModelInfo *info = reinterpret_cast<LoginEquipModelInfo *>(data);
	EquipItemInfo *item = reinterpret_cast<EquipItemInfo *>(info + 1);
	for (int i = 0; i < info->count; ++i)
	{
		m_mapEquips[item->equipId] = *item;
		++item;
	}
	return true;
}

bool CEquipModel::haveEquip(int equipId)
{
	if (m_mapEquips.find(equipId) != m_mapEquips.end())
	{
		return true;
	}
	return false;
}

bool CEquipModel::addEquip(EquipItemInfo &EquipData)
{
	if (m_mapEquips.find(EquipData.equipId) != m_mapEquips.end())
	{
		return false;
	}
	m_mapEquips[EquipData.equipId] = EquipData;
	return true;
}

void CEquipModel::removeEquip(int equipId)
{
	auto iter = m_mapEquips.find(equipId);
	if (iter != m_mapEquips.end())
	{
		m_mapEquips.erase(iter);
	}
}

int CEquipModel::getEquipConfId(int equipId)
{
	if (m_mapEquips.find(equipId) != m_mapEquips.end())
	{
		return m_mapEquips[equipId].confId;
	}
	return 0;
}

bool CEquipModel::getEquipInfo(int equipId, EquipItemInfo &info)
{
    auto equip = m_mapEquips.find(equipId);
    if (equip != m_mapEquips.end())
    {
        memcpy(&info, &equip->second, sizeof(EquipItemInfo));
        return true;
    }

    return false;
}

bool CSummonersModel::init(void *data)
{
	LoginSummonModelInfo *info = reinterpret_cast<LoginSummonModelInfo*>(data);
	// 召唤师id
	int *item = reinterpret_cast<int*>(info + 1);
	for (int i = 0; i < info->count; ++i)
	{
		m_vecSummoners.push_back(*item);
		++item;
	}
	return true;
}

bool CSummonersModel::addSummoner(int id)
{
	if (hasSummoner(id))
	{
		return false;
	}
	//m_vecSummoners.push_back(id);
	m_vecSummoners.insert(m_vecSummoners.begin(), id);
	return true;
}

bool CSummonersModel::hasSummoner(int id)
{
	auto iter = m_vecSummoners.begin();
	for (; iter != m_vecSummoners.end(); ++iter)
	{
		if (*iter == id)
		{
			return true;
		}
	}
	return false;
}

int CSummonersModel::getSummonerCount()
{
	return m_vecSummoners.size();
}

CHeroCardModel::CHeroCardModel()
    : m_nID(0)
    , m_nFrag(0)
    , m_nLv(0)
    , m_nStar(0)
    , m_nExp(0)
{
    for (int i = 0; i < 6; ++i)
    {
        m_equips[i] = 0;
    }
}

bool CHeroCardModel::init(void *data)
{
    LoginHeroInfo *heroInfo = reinterpret_cast<LoginHeroInfo *>(data);
    m_nID = heroInfo->heroId;
    m_nFrag = heroInfo->heroFrag;
    m_nLv = heroInfo->heroLv;
    m_nStar = heroInfo->heroStar;
    m_nExp = heroInfo->heroExp;
    memcpy(m_talent, heroInfo->heroTalent, sizeof(heroInfo->heroTalent));
    for (int i = 0; i < 6; ++i)
    {
        m_equips[i] = heroInfo->equip[i];
    }
	return true;
}

bool CHeroCardBagModel::init(void *data)
{
    LoginHeroModelInfo *info = reinterpret_cast<LoginHeroModelInfo*>(data);
    LoginHeroInfo* heroInfo = reinterpret_cast<LoginHeroInfo *>(info + 1);
    for (int i = 0; i < info->count; ++i)
    {
        CHeroCardModel* model = new CHeroCardModel;
        if (!model->init(heroInfo))
        {
            delete model;
            continue;
        }

        if (m_mapHeroCards.find(heroInfo->heroId) != m_mapHeroCards.end())
        {
            delete m_mapHeroCards[heroInfo->heroId];
        }
        m_mapHeroCards[heroInfo->heroId] = model;

        ++heroInfo;        
    }
    return true;
}

bool CHeroCardBagModel::addHeroCard(int id)
{
	auto iter = m_mapHeroCards.find(id);
	if (iter != m_mapHeroCards.end())
	{
		return false;
	}
	m_mapHeroCards[id] = new CHeroCardModel;
    m_mapHeroCards[id]->setID(id);
	return true;
}

bool CHeroCardBagModel::hasHeroCard(int id)
{
    if (m_mapHeroCards.find(id) == m_mapHeroCards.end())
    {
        return false;
    }
    return true;
}

CHeroCardModel* CHeroCardBagModel::getHeroCard(int id)
{
	auto iter = m_mapHeroCards.find(id);
	if (iter == m_mapHeroCards.end())
	{
		return nullptr;
	}
	return iter->second;
}

int CHeroCardBagModel::getHeroCardCount()
{
    int count = 0;
    for (const auto &heroCard:m_mapHeroCards)
    {
        if (heroCard.second->getStar() != 0 &&
            heroCard.second->getLevel() != 0)
        {
            ++count;
        }
    }
    return count;
}

bool CStageModel::init(void *data)
{
	LoginStageModelInfo *info = reinterpret_cast<LoginStageModelInfo*>(data);
	m_nCurrentComonStageID		= info->curStage;
	m_nCurrentEliteStageID		= info->curElite;
	int nComonChapterCount		= info->chapterCount;
	int nEliteChapterCount		= info->eliteChapterCount;
	int nComonStageCount		= info->stageCount;
	int nEliteStageCount		= info->eliteCount;
	int nEliteRecordCount		= info->eliteRecordCount;
	
	ChapterStatusInfo *chapterInfo = reinterpret_cast<ChapterStatusInfo*>(info + 1);
	for (int i = 0; i < nComonChapterCount; ++i)
	{
		m_mapChapterStates[chapterInfo->chapterID] = chapterInfo->chapterStatus;
		chapterInfo += 1;
	}

	EliteChapterStatusInfo* eliteChapterInfo = reinterpret_cast<EliteChapterStatusInfo*>(chapterInfo);
	for (int i = 0; i < nEliteChapterCount; ++i)
	{
		m_mapChapterStates[eliteChapterInfo->chapterID] = eliteChapterInfo->chapterStatus;
		eliteChapterInfo += 1;
	}

	StageStatusInfo *stageInfo = reinterpret_cast<StageStatusInfo*>(eliteChapterInfo);
	for (int i = 0; i < nComonStageCount; ++i)
	{
		m_mapComonStageStates[stageInfo->stageId] = stageInfo->stageStatus;
		stageInfo += 1;
	}

	EliteStatusInfo* eliteStageInfo = reinterpret_cast<EliteStatusInfo*>(stageInfo);
	for (int i = 0; i < nEliteStageCount; ++i)
	{
		m_mapEliteStageStates[eliteStageInfo->stageId] = eliteStageInfo->stageStatus;
		eliteStageInfo += 1;
	}

	EliteRecordInfo* eliteRecordInfo = reinterpret_cast<EliteRecordInfo*>(eliteStageInfo);
	for (int i = 0; i < nEliteRecordCount; ++i)
	{
		int id = eliteRecordInfo->stageId;
		m_mapEliteStageChallengeCount[id] = eliteRecordInfo->canUseTimes;
		m_mapEliteStageBuyCount[id] = eliteRecordInfo->buyTimes;
		m_mapEliteStageChallengeTimestamp[id] = eliteRecordInfo->useStamp;
		m_mapEliteStageBuyTimestamp[id] = eliteRecordInfo->buyStamp;
		eliteRecordInfo += 1;
	}

	return true;
}

int CStageModel::getCurrentComonStageID()
{
	return m_nCurrentComonStageID;
}

int CStageModel::getCurrentEliteStageID()
{
	return m_nCurrentEliteStageID;
}

int CStageModel::getChapterState(int ch)
{
	auto iter = m_mapChapterStates.find(ch);
	return iter != m_mapChapterStates.end() ? iter->second : ECS_LOCK;
}

int CStageModel::getComonStageState(int lv)
{
	if (lv > m_nCurrentComonStageID + 1)
	{
		return ESS_HIDE;
	}
	else if (lv > m_nCurrentComonStageID)
	{
		return ESS_LOCK;
	}
	else if (lv == m_nCurrentComonStageID)
	{
		int chapterID = getChapterIDByStageID(lv);
		int state = getChapterState(chapterID);
		if (ECS_FINISH == state || ECS_REWARD == state)
		{
			auto iter = m_mapComonStageStates.find(lv);
			return iter != m_mapComonStageStates.end() ? iter->second : ESS_TRI;
		}
		return ESS_UNLOCK;
	}
	else
	{
		auto iter = m_mapComonStageStates.find(lv);
		return iter != m_mapComonStageStates.end() ? iter->second : ESS_TRI;
	}
}

int CStageModel::getEliteStageState(int lv)
{
	if (lv > m_nCurrentEliteStageID + 1)
	{
		return ESS_HIDE;
	}
	else if (lv > m_nCurrentEliteStageID)
	{
		return ESS_LOCK;
	}
	else if (lv == m_nCurrentEliteStageID)
	{
		int chapterID = getChapterIDByStageID(lv);
		int state = getChapterState(chapterID);
		if (ECS_FINISH == state || ECS_REWARD == state)
		{
			auto iter = m_mapComonStageStates.find(lv);
			return iter != m_mapComonStageStates.end() ? iter->second : ESS_TRI;
		}
		return ESS_UNLOCK;
	}
	else
	{
		auto iter = m_mapEliteStageStates.find(lv);
		return iter != m_mapEliteStageStates.end() ? iter->second : ESS_TRI;
	}
}

int CStageModel::getEliteChallengeCount(int lv)
{
	auto iter = m_mapEliteStageChallengeCount.find(lv);
	if (iter != m_mapEliteStageChallengeCount.end())
	{
		return iter->second;
	}
	return 0;
}

int CStageModel::getEliteChallengeTimestamp(int lv)
{
	auto iter = m_mapEliteStageChallengeTimestamp.find(lv);
	return iter != m_mapEliteStageChallengeTimestamp.end() ? iter->second : 0;
}

int CStageModel::getEliteBuyCount(int lv)
{
	auto iter = m_mapEliteStageBuyCount.find(lv);
    return iter != m_mapEliteStageBuyCount.end() ? iter->second : 0;
}

int CStageModel::getEliteBuyTimestamp(int lv)
{
	auto iter = m_mapEliteStageBuyTimestamp.find(lv);
	return iter != m_mapEliteStageBuyTimestamp.end() ? iter->second : 0;
}

void CStageModel::setCurrentComonStageID(int lv)
{
	m_nCurrentComonStageID = lv;
}

void CStageModel::setCurrentEliteStageID(int lv)
{
	m_nCurrentEliteStageID = lv;
}

void CStageModel::setChapterState(int ch, int state)
{
	auto iter = m_mapChapterStates.find(ch);
	if (iter != m_mapChapterStates.end())
	{
        if (state > iter->second)
        {
            iter->second = state;
        }
	}
    else
    {
        m_mapChapterStates[ch] = state;
    }
}

void CStageModel::setComonStageState(int lv, int state)
{
	if (ESS_TRI == state)
	{
		auto iter = m_mapComonStageStates.find(lv);
		if (iter != m_mapComonStageStates.end())
		{
			m_mapComonStageStates.erase(iter);
		}
	}
	else if (ESS_ONE == state || ESS_TWO == state)
	{
		if (lv == m_nCurrentComonStageID)
		{
            if (state > m_mapComonStageStates[lv])
            {
                m_mapComonStageStates[lv] = state;
            }
		}
		else if (lv < m_nCurrentComonStageID)
		{
			auto iter = m_mapComonStageStates.find(lv);
			if (iter != m_mapComonStageStates.end())
			{
				if (state > iter->second)
				{
					iter->second = state;
				}
			}
		}
	}
}

void CStageModel::setEliteStageState(int lv, int state)
{
	if (ESS_TRI == state)
	{
		auto iter = m_mapEliteStageStates.find(lv);
		if (iter != m_mapEliteStageStates.end())
		{
			m_mapEliteStageStates.erase(iter);
		}
	}
	else if (ESS_ONE == state || ESS_TWO == state)
	{
		if (lv == m_nCurrentEliteStageID)
		{
            if (state > m_mapEliteStageStates[lv])
            {
                m_mapEliteStageStates[lv] = state;
            }
		}
		else if (lv < m_nCurrentEliteStageID)
		{
			auto iter = m_mapEliteStageStates.find(lv);
			if (iter != m_mapEliteStageStates.end())
			{
				if (state > iter->second)
				{
					iter->second = state;
				}
			}
		}
	}
}

void CStageModel::setEliteChallengeCount(int lv, int count)
{
	auto iter = m_mapEliteStageChallengeCount.find(lv);
	if (iter != m_mapEliteStageChallengeCount.end())
	{
		iter->second = count;
	}
    else
    {
        m_mapEliteStageChallengeCount[lv] = count;
    }
}

void CStageModel::setEliteBuyCount(int lv, int count)
{
	auto iter = m_mapEliteStageBuyCount.find(lv);
	if (iter != m_mapEliteStageBuyCount.end())
	{
		iter->second = count;
	}
    else
    {
        m_mapEliteStageBuyCount[lv] = count;
    }
}

void CStageModel::setEliteChallengeTimestamp(int lv, int time)
{
	auto iter = m_mapEliteStageChallengeTimestamp.find(lv);
	if (iter != m_mapEliteStageChallengeTimestamp.end())
	{
		iter->second = time;
	}
    else
    {
        m_mapEliteStageChallengeTimestamp[lv] = time;
    }
}

void CStageModel::setEliteBuyTimestamp(int lv, int time)
{
	auto iter = m_mapEliteStageBuyTimestamp.find(lv);
	if (iter != m_mapEliteStageBuyTimestamp.end())
	{
		iter->second = time;
	}
    else
    {
        m_mapEliteStageBuyTimestamp[lv] = time;
    }
}

void CStageModel::resetEliteChallengeCount(int lv)
{
	auto iter = m_mapEliteStageChallengeCount.find(lv);
	if (iter != m_mapEliteStageChallengeCount.end())
	{
		iter->second = 0;
	}
}

void CStageModel::resetEliteBuyCount(int lv)
{
	auto iter = m_mapEliteStageBuyCount.find(lv);
	if (iter != m_mapEliteStageBuyCount.end())
	{
		iter->second = 0;
	}
}

int CStageModel::deltaDay(const TimeInfo& info)
{
	time_t cur = CGameModel::getInstance()->getNow();
	struct tm *ptm = gmtime(&cur);
	int curHour = ptm->tm_hour;
	int curMin = ptm->tm_min;
	int curSec = ptm->tm_sec;
	int h = info.Hour;
	int m = info.Min;
	int delta = 0;
	if (curHour < h)
	{
		delta = (h - curHour) * 3600 + (m - curMin) * 60 - curSec;
	}
	else if (curHour > h)
	{
		delta = 24 * 3600 + (h - curHour) * 3600 - (m - curMin) * 60 - curSec;
	}
	else
	{
		if (curMin < m)
		{
			delta = (m - curMin) * 60 - curSec;
		}
		else if (curMin > m)
		{
			delta = 24 * 3600 + (m - curMin) * 60 - curSec;
		}
		else
		{
			delta = 24 * 3600 - curSec;
		}
	}
	return delta;
}

int CStageModel::deltaWeek(const TimeInfo& info)
{
	time_t cur = CGameModel::getInstance()->getNow();
	struct tm *ptm = gmtime(&cur);
	int curWeek = ptm->tm_wday;
	int curHour = ptm->tm_hour;
	int curMin = ptm->tm_min;
	int curSec = ptm->tm_sec;
	int w = info.Week;
	int h = info.Hour;
	int m = info.Min;
	int delta = 0;
	if (curWeek == 0)
	{
		curWeek = 7;
	}
	if (curWeek < w)
	{
		delta = (w - curWeek) * 24 * 3600 + deltaDay(info);
	}
	else if (curWeek > w)
	{
		delta = (7 + w - curWeek) * 24 * 3600 + deltaDay(info);
	}
	else
	{
		delta = deltaDay(info);
	}
	return delta;
}

int CStageModel::getChapterIDByStageID(int id)
{
	int ret = 0;
	CConfChapter* conf = dynamic_cast<CConfChapter*>(CConfManager::getInstance()->getConf(CONF_CHAPTER));
	for (auto ch : conf->getDatas())
	{
		int c = ch.first;
		ChapterConfItem* item = static_cast<ChapterConfItem*>(ch.second);
		for (auto s : item->Stages)
		{
			if (id == s.first)
			{
				ret = c;
				break;
			}
		}
	}
	return ret;
}


bool CTeamModel::init(void *data)
{
	LoginTeamModelInfo *pLoginTeamModelInfo = static_cast<LoginTeamModelInfo*>(data);
	int nTeamCount = pLoginTeamModelInfo->teamCount;

	pLoginTeamModelInfo += 1;

	TeamInfo *pTeamInfo = reinterpret_cast<TeamInfo*>(pLoginTeamModelInfo);
	for (int i = 0; i < nTeamCount; i++)
	{
		// 召唤师
		m_mapTeamSummoner[pTeamInfo->teamType] = pTeamInfo->summonerID;
		// 英雄
		for (int i = 0; i < 7; ++i)
		{
			if (pTeamInfo->heroID[i] > 0)
			{
				m_mapTeamHero[pTeamInfo->teamType].push_back(pTeamInfo->heroID[i]);
			}
		}
		pTeamInfo += 1;
	}

	return true;
}

bool CTeamModel::getTeamInfo(int teamType, int &summonerID, std::vector<int>& vecHero)
{
	std::map<int, std::vector<int>>::iterator iterHero = m_mapTeamHero.find(teamType);
	std::map<int, int>::iterator iterSummoner = m_mapTeamSummoner.find(teamType);
	if (iterSummoner != m_mapTeamSummoner.end())
	{
		summonerID = iterSummoner->second;
	}

	if (iterHero != m_mapTeamHero.end())
	{
		vecHero = iterHero->second;
	}

	return true;
}

void CTeamModel::setTeamInfo(int teamType, int summonerID, const std::vector<int>& vecHero)
{
	if (teamType > ETT_SPORTE
		&& teamType < ETT_PASE)
	{
		return;
	}

	m_mapTeamSummoner[teamType] = summonerID;
	m_mapTeamHero[teamType] = vecHero;
}

void CTeamModel::removeHeroFromAllTeam(int heroID)
{
	std::map<int, std::vector<int>>::iterator iterTeam = m_mapTeamHero.begin();
	for (; iterTeam != m_mapTeamHero.end(); iterTeam++)
	{
		std::vector<int>::iterator iterFind = std::find(iterTeam->second.begin(), iterTeam->second.end(), heroID);
		if (iterFind != iterTeam->second.end())
		{
			iterTeam->second.erase(iterFind);
		}
	}
}

bool CTeamModel::hasHeroAllTeam(int heroID)
{
	std::map<int, std::vector<int>>::iterator iterTeam = m_mapTeamHero.begin();
	for (; iterTeam != m_mapTeamHero.end(); iterTeam++)
	{
		std::vector<int>::iterator iterFind = std::find(iterTeam->second.begin(), iterTeam->second.end(), heroID);
		if (iterFind != iterTeam->second.end())
		{
			return true;
		}
	}

	return false;
}

bool CTaskModel::init(void* data)
{
	LoginTaskModelInfo * info = static_cast<LoginTaskModelInfo*>(data);
	int count = info->taskCount;
	info += 1;

	TaskInfo* pTaskInfo = reinterpret_cast<TaskInfo*>(info);
	for (int i = 0; i < count; ++i)
	{
		const TaskItem* taskConf = queryConfTask(pTaskInfo->taskID);
		if (taskConf != NULL && pTaskInfo->taskStatus == ETASK_ACTIVE && pTaskInfo->taskVal >= taskConf->CompleteTimes)
		{
			pTaskInfo->taskStatus = ETASK_FINISH;
		}
		addTask(*pTaskInfo);

		pTaskInfo += 1;
	}
	return true;
}

bool CTaskModel::addTask(const TaskInfo& taskInfo)
{
	std::map<int, TaskInfo>::iterator iter = m_mapTasksInfo.find(taskInfo.taskID);
	if (iter != m_mapTasksInfo.end())
	{
		return false;
	}
	m_mapTasksInfo[taskInfo.taskID] = taskInfo;
	return true;
}


bool CTaskModel::delTask(const int& taskId)
{
	std::map<int, TaskInfo>::iterator iter = m_mapTasksInfo.find(taskId);
	if (iter == m_mapTasksInfo.end())
	{
		return false;
	}
	m_mapTasksInfo.erase(iter);
	return true;
}

bool CTaskModel::setTask(const TaskInfo& taskInfo)
{
	std::map<int, TaskInfo>::iterator iter = m_mapTasksInfo.find(taskInfo.taskID);
	if (iter == m_mapTasksInfo.end())
	{
		return false;
	}
	m_mapTasksInfo[taskInfo.taskID] = taskInfo;
	return true;
}

bool CAchieveModel::init(void* data)
{
	LoginAchieveModelInfo * info = static_cast<LoginAchieveModelInfo*>(data);
	int count = info->achieveCount;
	info += 1;

	AchieveInfo* pAchieveInfo = reinterpret_cast<AchieveInfo*>(info);
	for (int i = 0; i < count; ++i)
	{
		const AchieveItem* achieveConf = queryConfAchieve(pAchieveInfo->achieveID);
		if (achieveConf != NULL && pAchieveInfo->achieveStatus == EACHIEVE_STATUS_ACTIVE && pAchieveInfo->achieveVal >= achieveConf->CompleteTimes)
		{
			pAchieveInfo->achieveStatus = EACHIEVE_STATUS_FINISH;
		}
		addAchieve(*pAchieveInfo);
		
		pAchieveInfo += 1;
	}
	return true;
}

bool CAchieveModel::addAchieve(const AchieveInfo& achieveInfo)
{
	std::map<int, AchieveInfo>::iterator iter = m_mapAchievesInfo.find(achieveInfo.achieveID);
	if (iter != m_mapAchievesInfo.end())
	{
		return false;
	}
	m_mapAchievesInfo[achieveInfo.achieveID] = achieveInfo;
	return true;
}

bool CAchieveModel::delAchieve(const int& achieveID)
{
	std::map<int, AchieveInfo>::iterator iter = m_mapAchievesInfo.find(achieveID);
	if (iter == m_mapAchievesInfo.end())
	{
		return false;
	}
	m_mapAchievesInfo.erase(iter);
	return true;
}

bool CAchieveModel::setAchieve(const AchieveInfo& achieveInfo)
{
	std::map<int, AchieveInfo>::iterator iter = m_mapAchievesInfo.find(achieveInfo.achieveID);
	if (iter == m_mapAchievesInfo.end())
	{
		return false;
	}
	m_mapAchievesInfo[achieveInfo.achieveID] = achieveInfo;
	return true;
}

#include "ConfGameSetting.h"
bool CGuideModel::init(void* data)
{
#if 0
    const NewPlayerItem* settingItem = queryConfNewPlayerItem(1);
    if (NULL == settingItem)
    {
        return false;
    }
    for (auto guideId : settingItem->Guides)
    {
        add(guideId);
    }
#else
	LoginGuideInfo* info = reinterpret_cast<LoginGuideInfo*>(data);

	int *pGuideID = reinterpret_cast<int*>(info+1);
	for (int i = 0; i < info->nNum; i++)
	{
		add(*pGuideID);
        pGuideID++;
    }
#endif
	return true;
}

void CGuideModel::del(int id)
{
	auto iter = m_setActives.find(id);
	if (iter != m_setActives.end())
	{
		m_setActives.erase(iter);
	}
}

void CGuideModel::add(int id)
{
	auto iter = m_setActives.find(id);
	if (iter == m_setActives.end())
	{
		m_setActives.insert(id);
	}
}

CUnionModel::CUnionModel()
: m_bHasAudit(false)
, m_nUnionID(0)
, m_cPos(0)
{
    memset(m_cUnionName, 0, sizeof(m_cUnionName));
    memset(m_cUnionNotice, 0, sizeof(m_cUnionNotice));
}

bool CUnionModel::init(void* data)
{
    LoginUnionModelInfo* info = reinterpret_cast<LoginUnionModelInfo*>(data);
    if (info->hasUnion == 0)
    {
        m_bHasUnion = false;
        m_bHasAudit = false;
        m_nUnionID = 0;
        m_nTodayLiveness = 0;
        m_nTotalContribution = 0;
        m_cPos = 0;
        memset(m_cUnionName, 0, sizeof(m_cUnionName));
        memset(m_cUnionNotice, 0, sizeof(m_cUnionNotice));
        m_vecApplyInfo.clear();
        NoUnionInfo* noInfo = reinterpret_cast<NoUnionInfo*>(info + 1);
        m_nApplyCount = noInfo->applyCount;
        m_nApplyStamp = noInfo->applyStamp;
        ApplyInfo* appInfo = reinterpret_cast<ApplyInfo*>(noInfo + 1);
        ApplyInfo temp;
        for (int i = 0; i < noInfo->applyCount; ++i)
        {
            temp.applyTime = appInfo->applyTime;
            temp.unionID = appInfo->unionID;
            m_vecApplyInfo.push_back(temp);
            ++appInfo;
        }
    }
    else
    {
        m_bHasUnion = true;
        m_nApplyCount = 0;
        m_nApplyStamp = 0;
        m_vecApplyInfo.clear();
        OwnUnionInfo* ownInfo = reinterpret_cast<OwnUnionInfo*>(info + 1);
        m_nUnionID = ownInfo->unionID;
        m_nTodayLiveness = ownInfo->todayStageLiveness;
        m_nTotalContribution = ownInfo->totalContribution;
        m_cPos = ownInfo->pos;
        m_bHasAudit = ownInfo->hasAudit == 0 ? false : true;
        memset(m_cUnionName, 0, sizeof(m_cUnionName));
        memcpy(m_cUnionName, ownInfo->unionName, strlen(ownInfo->unionName));
        memset(m_cUnionNotice, 0, sizeof(m_cUnionNotice));
        memcpy(m_cUnionNotice, ownInfo->notice, strlen(ownInfo->notice));
    }

	return true;
}

bool CUnionModel::delApplyInfo(int unionID)
{
    for (std::vector<ApplyInfo>::iterator iter = m_vecApplyInfo.begin(); 
        iter != m_vecApplyInfo.end(); ++iter)
    {
        if (iter->unionID == unionID)
        {
            m_vecApplyInfo.erase(iter);
            return true;
        }
    }
    return false;
}

bool CActivityInstanceModel::init(void *data)
{
	LoginInstanceModelInfo* info = reinterpret_cast<LoginInstanceModelInfo*>(data);
	InstanceInfo* ins = reinterpret_cast<InstanceInfo*>(info + 1);
	InstanceInfo instance;
	for (int i = 0; i < info->instanceCount; i++)
	{
		instance.activityId = ins->activityId;
		instance.useTimes = ins->useTimes;
		instance.useStamp = ins->useStamp;
		instance.buyTimes = ins->buyTimes;
		instance.buyStamp = ins->buyStamp;
		instance.easy = ins->easy;
		instance.normal = ins->normal;
		instance.difficult = ins->difficult;
		instance.hell = ins->hell;
		instance.legend = ins->legend;
		m_mapInstance[ins->activityId] = instance;
		++ins;
	}
	return true;
}

CMailModel::CMailModel()
{
    m_mapMailInfo.clear();
    memset(&m_unionMailTip, 0, sizeof(MailTips));
}

CMailModel::~CMailModel()
{

}

bool CMailModel::init(void *data)
{
	LoginMailModelInfo* pMailInfo = reinterpret_cast<LoginMailModelInfo*>(data);
	int normalMailCount = pMailInfo->normalMailCount;
	int webMailCount = pMailInfo->webMailCount;

 	NoramlMailInfo* pNormalInfo = reinterpret_cast<NoramlMailInfo*>(pMailInfo + 1);
	for (int i = 0; i < normalMailCount; ++i)
	{
        int key = getMailKey(pNormalInfo->nMailID, MAIL_TYPE_NORMAL);
        m_mapMailInfo[key] = MailInfo();
        m_mapMailInfo[key].isGetContent = false;
        m_mapMailInfo[key].mailID = pNormalInfo->nMailID;
		m_mapMailInfo[key].mailType = MAIL_TYPE_NORMAL;
        m_mapMailInfo[key].mailConfID = pNormalInfo->mailConfID;
        m_mapMailInfo[key].sendTimeStamp = pNormalInfo->sendTimeStamp;
        m_mapMailInfo[key].title = pNormalInfo->szTitle;
        m_mapMailInfo[key].sender = getLanguageString(CONF_UI_LAN, 409);

		const MailItem* pMailConf = queryConfMailItem(pNormalInfo->mailConfID);
        if (pMailConf != NULL && pNormalInfo->mailConfID != 0)
		{
			// 配置的标题
			m_mapMailInfo[key].title = getLanguageString(CONF_UI_LAN, pMailConf->Topic);
			// 拼接内容
			std::string hello = getLanguageString(CONF_UI_LAN, 408);
			std::string content = getLanguageString(CONF_UI_LAN, pMailConf->Content);
			// 所有的发送者都是系统
			m_mapMailInfo[key].sender = getLanguageString(CONF_UI_LAN, pMailConf->Sender);
			m_mapMailInfo[key].content = hello + "\n\t" + content;
		}
        ++pNormalInfo;
	}

	for (int i = 0; i < webMailCount; ++i)
	{
        int key = getMailKey(pNormalInfo->nMailID, MAIL_TYPE_WEB);
        m_mapMailInfo[key] = MailInfo();
        m_mapMailInfo[key].isGetContent = false;
        m_mapMailInfo[key].mailID = pNormalInfo->nMailID;
		m_mapMailInfo[key].mailType = MAIL_TYPE_WEB;
        m_mapMailInfo[key].mailConfID = pNormalInfo->mailConfID;
        m_mapMailInfo[key].sendTimeStamp = pNormalInfo->sendTimeStamp;
        m_mapMailInfo[key].title = pNormalInfo->szTitle;
        m_mapMailInfo[key].sender = getLanguageString(CONF_UI_LAN, 409);
		
        const MailItem* pMailConf = queryConfMailItem(pNormalInfo->mailConfID);
        if (NULL != pMailConf && pNormalInfo->mailConfID != 0)
		{
            // 配置的标题
            m_mapMailInfo[key].title = getLanguageString(CONF_UI_LAN, pMailConf->Topic);
            // 拼接内容
            std::string hello = getLanguageString(CONF_UI_LAN, 408);
            std::string content = getLanguageString(CONF_UI_LAN, pMailConf->Content);
            // 所有的发送者都是系统
            m_mapMailInfo[key].sender = getLanguageString(CONF_UI_LAN, pMailConf->Sender);
            m_mapMailInfo[key].content = hello + "\n\t" + content;
		}
        ++pNormalInfo;
	}	
	return true;
}

bool CMailModel::addMail(const MailInfo& info)
{
    int mailKey = getMailKey(info.mailID, info.mailType);
    auto iter = m_mapMailInfo.find(mailKey);
	if (iter == m_mapMailInfo.end())
	{
        m_mapMailInfo[mailKey] = info;
		return true;
	}
	return false;
}

bool CMailModel::setMail(const MailInfo& info)
{
    int mailKey = getMailKey(info.mailID, info.mailType);
    auto iter = m_mapMailInfo.find(mailKey);
    if (iter != m_mapMailInfo.end())
    {
        iter->second = info;
        return true;
    }
    return false;
}

bool CMailModel::removeMail(int mailKey)
{
    auto iter = m_mapMailInfo.find(mailKey);
    if (iter != m_mapMailInfo.end())
    {
        m_mapMailInfo.erase(iter);
        return true;
    }
    return false;
}

const MailInfo* CMailModel::getMail(int mailKey)
{
    auto iter = m_mapMailInfo.find(mailKey);
	if (iter != m_mapMailInfo.end())
	{
		return &iter->second;
	}
	return nullptr;
}

int CMailModel::getMailKey(int mailID, int mailType)
{
    if (mailType == MAIL_TYPE_WEB)
        return -100 - mailID;
	return mailID;
}

bool CGoldTestModel::init(void* data)
{
	GoldTestInfo* info = reinterpret_cast<GoldTestInfo*>(data);
	m_sInfo.count = info->count;
	m_sInfo.stamp = info->stamp;
	m_sInfo.damage = info->damage;
	m_sInfo.state = info->state;
	return true;
}

int CGoldTestModel::getState(int i)
{
	if (i < 0 || i > 31)
	{
		return -1;
	}

	CConfGoldTestChest* conf = dynamic_cast<CConfGoldTestChest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST_CHEST));
	GoldTestChestConfItem* item = static_cast<GoldTestChestConfItem*>(conf->getData(i));
	if (m_sInfo.damage < item->Damage)
	{
		return -1;   //未达到伤害，不可领取
	}

	return m_sInfo.state & (1 << (i - 1));    //1表示已领取，0表示未领取
}

void CGoldTestModel::setState(int i)
{
	if (i < 0 || i > 31)
	{
		return;
	}
	CConfGoldTestChest* conf = dynamic_cast<CConfGoldTestChest*>(CConfManager::getInstance()->getConf(CONF_GOLD_TEST_CHEST));
	GoldTestChestConfItem* item = static_cast<GoldTestChestConfItem*>(conf->getData(i));
	if (m_sInfo.damage < item->Damage)
	{
		return;   //未达到伤害，不可领取
	}
	m_sInfo.state |= (1 << (i - 1));
}

void CGoldTestModel::resetGoldTest(int stamp)
{
    m_sInfo.stamp = stamp;
    m_sInfo.count = 0;
    m_sInfo.damage = 0;
    m_sInfo.state = 0;
}

bool CHeroTestModel::init(void* data)
{
	HeroTestInfo* info = reinterpret_cast<HeroTestInfo*>(data);
	m_nStamp = info->stamp;
	int cn = info->count;
    HeroTestTimesInfo * pInfo = reinterpret_cast<HeroTestTimesInfo*>(info + 1);
	for (int i = 1; i <= cn; i++)
	{
        m_mapCount[pInfo->nInstanceId] = pInfo->nTimes;
        ++pInfo;
	}
	
	return true;
}

int CHeroTestModel::getCount(int i)
{
	auto iter = m_mapCount.find(i);
	if (iter != m_mapCount.end())
	{
		return iter->second;
	}
	return 0;
}

void CHeroTestModel::setCount(int i, int count)
{
	auto iter = m_mapCount.find(i);
	if (iter != m_mapCount.end())
	{
		iter->second = count;
	}
}

void CHeroTestModel::addCount(int i, int count)
{
    m_mapCount[i] += count;
}

void CHeroTestModel::resetHeroTest(int stamp)
{
    m_nStamp = stamp;
    std::map<int, int>::iterator iter =  m_mapCount.begin();
    for (; iter != m_mapCount.end(); ++iter)
    {
        iter->second = 0;
    }
}

bool CTowerTestModel::init(void* data)
{
	LoginTowerTestModelInfo* info = reinterpret_cast<LoginTowerTestModelInfo*>(data);
	m_nFloor = info->floor;

	return true;
}

void CTowerTestModel::addBuff(int id)
{
}

CPersonalTaskModel::CPersonalTaskModel()
	:m_nResetTime(0)
{

}

bool CPersonalTaskModel::addTask(PersonalTaskInfo info)
{
	auto iter = m_mapTaskInfo.find(info.id);
	if (iter == m_mapTaskInfo.end())
	{
		m_mapTaskInfo[info.id] = info;
		return true;
	}	
	return false;
}

bool CPersonalTaskModel::setTask(PersonalTaskInfo info)
{
	auto iter = m_mapTaskInfo.find(info.id);
	if (iter != m_mapTaskInfo.end())
	{
		iter->second = info;
		return true;
	}
	return false;
}

CTeamTaskModel::CTeamTaskModel()
{

}

void CTeamTaskModel::clearTask()
{
	m_nNextTaskID = 0;

	m_teamTaskInfo.curTaskID = 0;
	m_teamTaskInfo.endTime = 0;
	m_teamTaskInfo.stage = 0;
	m_teamTaskInfo.bossHp = 0;
	m_teamTaskInfo.rewardBox = 0x0000;
	m_teamTaskInfo.challengeCDTime = 0;
	m_teamTaskInfo.challengeTimes = 0;
	m_teamTaskInfo.nextTargetTime = 0;

	m_vecNextTask.clear();
	m_mapHurtsInfo.clear();
}

bool CTeamTaskModel::setHurtInfo(TeamHurtInfo info)
{
	auto iter = m_mapHurtsInfo.find(info.userID);
	if (iter != m_mapHurtsInfo.end())
	{
		m_mapHurtsInfo[info.userID] = info;
		return true;
	}
	return false;
}

bool CTeamTaskModel::addHurtInfo(TeamHurtInfo info)
{
	auto iter = m_mapHurtsInfo.find(info.userID);
	if (iter == m_mapHurtsInfo.end())
	{
		m_mapHurtsInfo[info.userID] = info;
		return true;
	}
	return false;
}

////////////////////////////// PVP模型 START //////////////////////////////////////////
CPvpModel::CPvpModel()
: m_bIsReconnect(false)
{
    memset(&m_PvpInfo, 0, sizeof(PvpInfo));
}

CPvpModel::~CPvpModel()
{
}

bool CPvpModel::init(void* data)
{
    LoginPvpModelInfo *pLoginPvpModelInfo = reinterpret_cast<LoginPvpModelInfo*>(data);
    m_PvpInfo = *pLoginPvpModelInfo;

    return true;
}

void CPvpModel::resetPvp()
{
    m_PvpInfo.DayBattleCount = 0;
    m_PvpInfo.DayContinusWin = 0;
    m_PvpInfo.DayWin = 0;
    m_PvpInfo.RewardFlag = 0;
    m_PvpInfo.DayMaxContinusWinTimes = 0;
    m_PvpInfo.DayBuyChestTimes = 0;
    m_PvpInfo.ResetStamp += 24 * 3600; // 直接用服务器的时间加一天
}

bool CPvpModel::isReconnect()
{
	return m_bIsReconnect;
}

void CPvpModel::setReconnect(bool isReconn)
{
	m_bIsReconnect = isReconn;
}

void CPvpModel::setBattleId(int battleId)
{
	m_PvpInfo.BattleId = battleId;
}

void CPvpModel::setRank(int type, int rank)
{
    if (MATCH_FAIRPVP == type)
        m_PvpInfo.Rank = rank;
    else
        m_PvpInfo.CpnRank = rank;
}

void CPvpModel::setScore(int type, int score)
{
    if (MATCH_FAIRPVP == type)
        m_PvpInfo.Score = score;
    else
        m_PvpInfo.CpnIntegral = score;
}

int CPvpModel::getScore(int type)
{
    if (MATCH_FAIRPVP == type)
        return m_PvpInfo.Score;
    else
        return m_PvpInfo.CpnIntegral;
}

void CPvpModel::setHistoryRank(int type, int rank)
{
    if (MATCH_FAIRPVP == type)
        m_PvpInfo.HistoryRank = rank;
    else
        m_PvpInfo.CpnHistoryHigestRank = rank;
}

int CPvpModel::getHistoryRank(int type)
{
    if (MATCH_FAIRPVP == type)
        return m_PvpInfo.HistoryRank;
    else
        return m_PvpInfo.CpnHistoryHigestRank;
}

void CPvpModel::setHistoryScore(int type, int score)
{
    if (MATCH_FAIRPVP == type)
        m_PvpInfo.HistoryScore = score;
    else
        m_PvpInfo.CpnHistoryHigestIntegral = score;
}

int CPvpModel::getHistoryScore(int type)
{
    if (MATCH_FAIRPVP == type)
        return m_PvpInfo.HistoryScore;
    else
        return m_PvpInfo.CpnHistoryHigestIntegral;
}

int CPvpModel::getPvpTaskStatus(int type)
{
    if (type < 0 || type > 32)
    {
        return -1;
    }

    return m_PvpInfo.RewardFlag >> type & 0x1;
}

void CPvpModel::setPvpTaskStatus(int type)
{
    if (type < 0 || type > 32)
    {
        return;
    }

    int flag = 0x1 << type;
    m_PvpInfo.RewardFlag |= flag;
}

void CPvpModel::setDayTask(int result)
{
	if (1 == result)
	{
		m_PvpInfo.DayContinusWin += 1;
		m_PvpInfo.DayWin += 1;
		if (m_PvpInfo.DayContinusWin > m_PvpInfo.DayMaxContinusWinTimes)
		{
			m_PvpInfo.DayMaxContinusWinTimes = m_PvpInfo.DayContinusWin;
		}
	}
	else
	{
		m_PvpInfo.DayContinusWin = 0;
	}

	m_PvpInfo.DayBattleCount += 1;
}

void CPvpModel::resetPvpTaskWithType(int taskType)
{
	if (taskType == 0)
	{
		m_PvpInfo.DayBattleCount = 0;
	}
	else if (taskType == 1)
	{
		m_PvpInfo.DayWin = 0;
	}
	else if (taskType == 2)
	{
		m_PvpInfo.DayContinusWin = 0;
		m_PvpInfo.DayMaxContinusWinTimes = 0;
	}
}

void CPvpModel::setContinueWinTimes(bool win)
{
    if (win)
    {
        if (m_PvpInfo.ContinusWinTimes < 0)
            m_PvpInfo.ContinusWinTimes = 1;
        else
            m_PvpInfo.ContinusWinTimes += 1;

        if (m_PvpInfo.ContinusWinTimes > m_PvpInfo.HistoryContinusWinTimes)
            m_PvpInfo.HistoryContinusWinTimes = m_PvpInfo.ContinusWinTimes;
    }
    else
    {
        if (m_PvpInfo.ContinusWinTimes > 0)
            m_PvpInfo.ContinusWinTimes = -1;
        else
            m_PvpInfo.ContinusWinTimes -= 1;
    }
}

void CPvpModel::resetChampionArena()
{
    m_PvpInfo.CpnContinusWinTimes = 0;
    m_PvpInfo.CpnRank = 0;
    m_PvpInfo.CpnWeekResetStamp += 7 * 24 * 3600;
    m_PvpInfo.CpnGradingNum = 0;
    m_PvpInfo.CpnGradingDval = 0;
    m_PvpInfo.CpnIntegral = 0;
    m_PvpInfo.CpnContinusWinTimes = 0;
    m_PvpInfo.CpnHistoryContinusWinTimes = 0;
}

////////////////////////////// PVP模型 END //////////////////////////////////////////


///////////////////////////////// 商店模型 START /////////////////////////////////
CShopModel::CShopModel()
{
}
CShopModel::~CShopModel()
{
}

bool CShopModel::init(void* data)
{
    LoginShopModelInfo *pLoginShopModelInfo = reinterpret_cast<LoginShopModelInfo *>(data);
    m_nShopCount = pLoginShopModelInfo->cCount;

	//SLoginShopData *pLoginShopData = reinterpret_cast<SLoginShopData *>(pLoginShopModelInfo + 1);
 //   for (int i = 0; i < m_nShopCount; ++i)
 //   {
 //       ShopData shopData;
	//	shopData.nShopType = pLoginShopData->nShopID;
 //       shopData.nCount = pLoginShopData->nCount;
 //       shopData.nCurCount = pLoginShopData->nCurCount;
 //       shopData.nFreshedCount = pLoginShopData->nTimes;
 //       shopData.nNextFreshTime = pLoginShopData->nNextFreshTime;

	//	m_mapShopInfo[shopData.nShopType] = shopData;

 //       SLoginShopGoodsData *pLoginShopGoodsData = reinterpret_cast<SLoginShopGoodsData *>(pLoginShopData + 1);
 //       for (int i = 0; i < shopData.nCurCount; ++i)
 //       {
 //           ShopGoodsData * pShopGoodsData = reinterpret_cast<ShopGoodsData *>(pLoginShopGoodsData);
	//		m_mapShopInfo[shopData.nShopType].m_vecGoodsData.push_back(*pShopGoodsData);
 //           pLoginShopGoodsData++;
 //       }

	//	pLoginShopData = reinterpret_cast<SLoginShopData *>(pLoginShopGoodsData);
 //   }

 //   SLoginDiamondShopData *pLoginDiamondShopData = reinterpret_cast<SLoginDiamondShopData *>(pLoginShopData);
 //   int num = pLoginDiamondShopData->nNum;
 //   SLoginDiamondData *pLoginDiamondData = reinterpret_cast<SLoginDiamondData *>(pLoginDiamondShopData + 1);
 //   for (int i = 0; i < num; ++i)
 //   {
 //       m_mapDiamondShopData[pLoginDiamondData->nPid] = pLoginDiamondData->nTimeStamp;
 //       pLoginDiamondData++;
 //   }
    return true;
}

ShopData* CShopModel::getShopModelData(int shopType)
{
    auto iter = m_mapShopInfo.find(shopType);
    if (iter == m_mapShopInfo.end())
    {
        return NULL;
    }

    return &(iter->second);
}


void CShopModel::setShopModelData(const ShopData& data)
{
    m_mapShopInfo[data.nShopType] = data;
}

bool CShopModel::isFirstCharge(int pID)
{
    auto iter = m_mapDiamondShopData.find(pID);
    if (iter != m_mapDiamondShopData.end())
    {
        if (iter->second > 0)
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    else
    {
        return true;
    }
}

void CShopModel::setFirstChargeState(int pID)
{
    m_mapDiamondShopData[pID] = CGameModel::getInstance()->getNow();
}

///////////////////////////////// 商店模型 END ///////////////////////////////////



///////////////////////////////// 运营活动模型 START /////////////////////////////////
COperateActiveModel::COperateActiveModel()
{
}

COperateActiveModel::~COperateActiveModel()
{
}

bool COperateActiveModel::init(void* data)
{
    // 活动个数
    SLoginActiveSC* pLoginActiveSC = reinterpret_cast<SLoginActiveSC *>(data);
    m_nActiveCount = pLoginActiveSC->sCount;

    //SLoginActiveData* pLoginActiveData = reinterpret_cast<SLoginActiveData *>(pLoginActiveSC + 1);
    //for (int i = 0; i < m_nActiveCount; i++)
    //{
    //    // 活动基础信息
    //    m_mapActiveData[pLoginActiveData->nActiveID] = *pLoginActiveData;

    //    if (pLoginActiveData->nActiveType == TYPE_SHOP)         // 商店活动
    //    {
    //        // 礼包个数
    //        SLoginActiveShop* pLoginActiveShop = reinterpret_cast<SLoginActiveShop *>(pLoginActiveData + 1);
    //        m_mapActiveShop[pLoginActiveData->nActiveID].nShopNum = pLoginActiveShop->nShopNum;
    //        // 礼包信息
    //        SLoginActiveShopData* pLoginActiveShopData = reinterpret_cast<SLoginActiveShopData *>(pLoginActiveShop + 1);
    //        for (int i = 0; i < pLoginActiveShop->nShopNum; i++)
    //        {
    //            m_mapActiveShop[pLoginActiveData->nActiveID].m_vecActiveShopData.push_back(*pLoginActiveShopData);
    //            pLoginActiveShopData++;
    //        }

    //        pLoginActiveData = reinterpret_cast<SLoginActiveData *>(pLoginActiveShopData);
    //    }
    //    else if (pLoginActiveData->nActiveType == TYPE_TASK)    // 任务活动
    //    {
    //        // 活动任务数
    //        SLoginActiveTask* pLoginActiveTask = reinterpret_cast<SLoginActiveTask *>(pLoginActiveData + 1);
    //        m_mapActiveTask[pLoginActiveData->nActiveID].nActiveTaskNum = pLoginActiveTask->nActiveTaskNum;
    //        // 任务信息
    //        SLoginActiveTaskData* pLoginActiveTaskData = reinterpret_cast<SLoginActiveTaskData *>(pLoginActiveTask + 1);
    //        for (int i = 0; i < pLoginActiveTask->nActiveTaskNum; i++)
    //        {
    //            m_mapActiveTask[pLoginActiveData->nActiveID].m_vecActiveTaskData.push_back(*pLoginActiveTaskData);
    //            pLoginActiveTaskData++;
    //        }

    //        pLoginActiveData = reinterpret_cast<SLoginActiveData *>(pLoginActiveTaskData);
    //    }
    //    else if (pLoginActiveData->nActiveType == TYPE_DROP)
    //    {
    //        pLoginActiveData++;
    //    }
    //}

    return true;
}

SOperateActiveShop* COperateActiveModel::getActiveShopData(int activeID)
{
    auto iter = m_mapActiveShop.find(activeID);
    if (iter == m_mapActiveShop.end())
    {
        return NULL;
    }

    return &(iter->second);
}

void COperateActiveModel::setActiveShopBuyTimes(int activeID, int giftID, int buyTimes)
{
    //auto iter = m_mapActiveShop.find(activeID);
    //if (iter != m_mapActiveShop.end())
    //{
    //    for (auto& data : iter->second.m_vecActiveShopData)
    //    {
    //        if (data.nGiftID == giftID)
    //        {
    //            data.nBuyTimes = buyTimes;
    //        }
    //    }
    //}
}

SOperateActiveTask* COperateActiveModel::getActiveTaskData(int activeID)
{
    auto iter = m_mapActiveTask.find(activeID);
    if (iter == m_mapActiveTask.end())
    {
        return NULL;
    }

    return &(iter->second);
}

void COperateActiveModel::setActiveTaskProgress(int activeID, int taskID, int value)
{
    //auto iter = m_mapActiveTask.find(activeID);
    //if (iter != m_mapActiveTask.end())
    //{
    //    for (auto& data : iter->second.m_vecActiveTaskData)
    //    {
    //        if (data.nTaskID == taskID)
    //        {
    //            data.nValue = value;
    //        }
    //    }
    //}
}

void COperateActiveModel::setActiveTaskFinishFlag(int activeID, int taskID, int flag)
{
    //auto iter = m_mapActiveTask.find(activeID);
    //if (iter != m_mapActiveTask.end())
    //{
    //    for (auto& data : iter->second.m_vecActiveTaskData)
    //    {
    //        if (data.nTaskID == taskID)
    //        {
    //            data.nFinishFlag = flag;
    //        }
    //    }
    //}
}

void COperateActiveModel::removeActiveData(int activeID, int activeType)
{
    m_mapActiveData.erase(activeID);
    if (activeType == TYPE_SHOP)         // 商店活动
    {
        m_mapActiveShop.erase(activeID);
    }
    else if (activeType == TYPE_TASK)    // 任务活动
    {
        m_mapActiveTask.erase(activeID);
    }
}

////////////////////////////////// 运营活动模型 END //////////////////////////////////


////////////////////////////////// 头像模型 BEGIN //////////////////////////////////
CHeadModel::CHeadModel()
{

}

CHeadModel::~CHeadModel()
{

}

bool CHeadModel::init(void* data)
{
    // 头像个数
    LoginHeadInfo* pLoginHeadInfo = reinterpret_cast<LoginHeadInfo *>(data);
    m_nNum = pLoginHeadInfo->nNum;
    int* headID = reinterpret_cast<int*>(pLoginHeadInfo + 1);
    for (int i = 0; i < m_nNum; i++)
    {
        m_vecUnlockedHead.push_back(*headID);
        ++headID;
    }
    return true;
}

bool CHeadModel::isUnlocked(int headID)
{
    for (std::vector<int>::const_iterator iter = m_vecUnlockedHead.begin();
        iter != m_vecUnlockedHead.end(); ++iter)
    {
        if (headID == *iter)
        {
            return true;
        }
    }
    return false;
}

bool CHeadModel::addHead(int headID)
{
    for (std::vector<int>::const_iterator iter = m_vecUnlockedHead.begin();
        iter != m_vecUnlockedHead.end(); ++iter)
    {
        if (headID == *iter)
        {
            return false;
        }
    }
    m_vecUnlockedHead.push_back(headID);
    return true;
}
////////////////////////////////// 头像模型 END //////////////////////////////////