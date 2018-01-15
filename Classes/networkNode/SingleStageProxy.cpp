#include "SingleStageProxy.h"
#include "KxMemPool.h"
#include "GameModel.h"
#include "LuaSummonerBase.h"

#include "Protocol.h"
#include "StageProtocol.h"
#include "RoleComm.h"

CSingleStageProxy::CSingleStageProxy()
{
    m_BufferData = new CBufferData();
}

CSingleStageProxy::~CSingleStageProxy()
{
    delete m_BufferData;
}

bool CSingleStageProxy::init(CEventManager<int> *eventMgr)
{
	if (NULL == eventMgr)
	{
		return false;
	}

    CEventProxy::init(eventMgr);
	for (int i = CMD_STAGE_CSBEGIN + 1; i < CMD_STAGE_CSEND; i++)
	{
		int eventId = MakeCommand(CMD_STAGE, i);
		m_pEventManager->addEventHandle(eventId, this, CALLBACK_FUNCV(CSingleStageProxy::onEventSend));
	}

	return true;
}

int CSingleStageProxy::onRecv(char *buffer, int len)
{
    // 触发事件
    if (NULL != m_pEventManager)
    {
        Head *head = reinterpret_cast<Head*>(buffer);
        m_pEventManager->raiseEvent(head->cmd, buffer);
    }

    // 通知Lua
    m_BufferData->init(buffer, len);
    onLuaRespone(m_BufferData);
    m_BufferData->clean();
	return 0;
}

int CSingleStageProxy::send(char *buffer, int len)
{
	//处理消息, 需要中间层进行消息缓存, 不能直接onRecv
	return 0;
}

int CSingleStageProxy::onError(int error, int tag, char *data)
{
	// nothing to do
	return 0;
}

void CSingleStageProxy::onEventSend(void *data)
{
	Head* head = reinterpret_cast<Head*>(data);
	int len = head->length;

	switch (head->SubCommand())
	{
		case CMD_STAGE_CHALLENGE_CS:
		{
//             CGameModel* gameModel = CGameModel::getInstance();
// 
// 			// 先解析客户端发送包
// 			StageChallengeCS* stageCS = reinterpret_cast<StageChallengeCS*>(head + 1);
// 			int stageId = stageCS->stageId;
// 			int heroId = stageCS->heroId;
// 			int soldierCount = stageCS->soliderCount;
// 			int* offset = reinterpret_cast<int*>(stageCS + 1);
//             int size = sizeof(Head) + sizeof(RoomData) + sizeof(PlayerData) + sizeof(HeroCardData);
//             for (int i = 0; i < soldierCount; i++)
// 			{
//                 int id = *(offset + i);
//                 auto soldier = gameModel->getHeroCardBagModel()->getHeroCard(id);
//                 size += sizeof(SoldierCardData);
//                 size += sizeof(SoldierEquip) * soldier->getEquips().size();
//                 size += sizeof(SoldierSkill) * soldier->getSkills().size();
// 			}
// 
//             // 根据计算好的长度进行封包
// 			char* pData = reinterpret_cast<char*>(KxServer::kxMemMgrAlocate(size));
// 
// 			Head* dataHead = reinterpret_cast<Head*>(pData);
// 			dataHead->cmd = MakeCommand(CMD_STAGE, CMD_STAGE_CHALLENGE_SC);
// 			dataHead->length = size;
// 
// 			RoomData* dataRoom = reinterpret_cast<RoomData*>(dataHead + 1);
// 			dataRoom->StageId = stageId;
// 			dataRoom->StageLevel = 1;
// 			dataRoom->BattleType = EBATTLE_CHAPTER;
// 			dataRoom->Ext1 = 0;
// 			dataRoom->Ext2 = 0;
// 			dataRoom->PlayerCount = 1;
// 
//             // 用户数据使用GameModel单例中的UserModel
// 			PlayerData* dataPlayer = reinterpret_cast<PlayerData*>(dataRoom + 1);
//             dataPlayer->UserId = gameModel->getUserModel()->getUserID();
//             dataPlayer->UserLv = gameModel->getUserModel()->getLevel();
// 			dataPlayer->SoldierCount = soldierCount;
// 			dataPlayer->Camp = static_cast<int>(ECamp_Blue);
// 			strcpy(dataPlayer->UserName, gameModel->getUserModel()->getUserName());
// 
// 			HeroCardData* dataHero = reinterpret_cast<HeroCardData*>(dataPlayer + 1);
// 			dataHero->HeroId = heroId;
// 
//             // 封装士兵的数据
//             char* soldiersData = reinterpret_cast<char*>(dataHero + 1);
//             int soldierOffset = 0;
// 			for (int i = 0; i < soldierCount; i++)
// 			{
//                 int id = *(offset + i);
//                 auto soldier = gameModel->getHeroCardBagModel()->getHeroCard(id);
// 
//                 SoldierCardData* soldierData = reinterpret_cast<SoldierCardData*>(soldiersData + soldierOffset);
//                 soldierData->SoldierId = id;
//                 soldierData->SoldierConfId = soldier->getCardID();
//                 soldierData->SkillCnt = soldier->getSkills().size();
//                 soldierData->EquipCnt = soldier->getEquips().size();
//                 soldierData->SoldierTalent = soldier->getCurTalent();
//                 soldierData->SoldierStar = soldier->getStar();
//                 soldierData->SoldierLv = soldier->getLevel();
//                 soldierOffset += sizeof(SoldierCardData);
// 
//                 auto equips = soldier->getEquips();
//                 for (auto equipInfo : equips)
//                 {
//                     SoldierEquip* equip = reinterpret_cast<SoldierEquip*>(soldiersData + soldierOffset);
//                     equip->confId = gameModel->getEquipModel()->getEquipConfId(equipInfo);
//                     soldierOffset += sizeof(SoldierEquip);
//                 }
// 
//                 auto skills = soldier->getSkills();
//                 for (auto skillInfo : skills)
//                 {
//                     SoldierSkill* skill = reinterpret_cast<SoldierSkill*>(soldiersData + soldierOffset);
//                     skill->skillId = skillInfo.first;
//                     skill->skillLv = skillInfo.second;
//                     soldierOffset += sizeof(SoldierSkill);
//                 }
// 			}
// 
// 			onRecv(reinterpret_cast<char*>(pData), size);
// 			KxServer::kxMemMgrRecycle(pData, size);
		}
	default:
		break;
	}
}
