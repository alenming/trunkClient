#include "GameModel.h"
#include "cocos2d.h"
#include "cocostudio/ActionTimeline/CSLoader.h"
#include "../../cocos/ui/CocosGUI.h"
#include "Protocol.h"
#include "LoginProtocol.h"
#include "DisplayCommon.h"
#include "ConfLanguage.h"
#include "TimeCalcTool.h"
USING_NS_CC;
using namespace ui;

CGameModel* CGameModel::m_Instance = NULL;

CGameModel::CGameModel()
: m_LoginServerTime(0)
, m_LoginClientTime(0)
, m_Room(NULL)
, m_UserModel(NULL)
, m_BagModel(NULL)
, m_pEquipModel(NULL)
, m_HeroCardBagModel(NULL)
, m_SummonersModel(NULL)
, m_StageModel(NULL)
, m_pTeamModel(NULL)
, m_pTaskModel(NULL)
, m_pAchieveModel(NULL)
, m_pUnionModel(NULL)
, m_pActivityInstanceModel(NULL)
, m_pMailModel(NULL)
, m_pPersonalTaskModel(NULL)
, m_pTeamTaskModel(NULL)
, m_pPvpModel(NULL)
, m_pShopModel(NULL)
, m_pOperateActive(NULL)
, m_pHeadModel(NULL)
{
    m_UserModel = new CUserModel();
    m_BagModel = new CBagModel();
    m_pEquipModel = new CEquipModel;
    m_HeroCardBagModel = new CHeroCardBagModel();
    m_SummonersModel = new CSummonersModel();
    m_StageModel = new CStageModel();
    m_pTeamModel = new CTeamModel;
	m_pTaskModel = new CTaskModel;
	m_pAchieveModel = new CAchieveModel;
	m_pGuideModel = new CGuideModel;
	m_pUnionModel = new CUnionModel;
	m_pActivityInstanceModel = new CActivityInstanceModel;
	m_pMailModel = new CMailModel;
	m_pGoldTestModel = new CGoldTestModel;
	m_pHeroTestModel = new CHeroTestModel;
	m_pTowerTestModel = new CTowerTestModel;
	m_pPersonalTaskModel = new CPersonalTaskModel;
	m_pTeamTaskModel = new CTeamTaskModel;
    m_pPvpModel = new CPvpModel;
    m_pShopModel = new CShopModel;
    m_pOperateActive = new COperateActiveModel;
    m_pHeadModel = new CHeadModel;
}

CGameModel::~CGameModel()
{
    CC_SAFE_DELETE(m_Room);
    CC_SAFE_DELETE(m_UserModel);
    CC_SAFE_DELETE(m_BagModel);
    CC_SAFE_DELETE(m_pEquipModel);
    CC_SAFE_DELETE(m_HeroCardBagModel);
    CC_SAFE_DELETE(m_SummonersModel);
    CC_SAFE_DELETE(m_StageModel);
    CC_SAFE_DELETE(m_pTeamModel);
	CC_SAFE_DELETE(m_pTaskModel);
	CC_SAFE_DELETE(m_pAchieveModel);
	CC_SAFE_DELETE(m_pGuideModel);
	CC_SAFE_DELETE(m_pUnionModel);
	CC_SAFE_DELETE(m_pActivityInstanceModel);
	CC_SAFE_DELETE(m_pMailModel);
	CC_SAFE_DELETE(m_pGoldTestModel);
	CC_SAFE_DELETE(m_pHeroTestModel);
	CC_SAFE_DELETE(m_pTowerTestModel);
	CC_SAFE_DELETE(m_pPersonalTaskModel);
	CC_SAFE_DELETE(m_pTeamTaskModel);
    CC_SAFE_DELETE(m_pPvpModel);
    CC_SAFE_DELETE(m_pShopModel);
    CC_SAFE_DELETE(m_pOperateActive);
    CC_SAFE_DELETE(m_pHeadModel);
}

CGameModel* CGameModel::getInstance()
{
    if (NULL == m_Instance)
    {
        m_Instance = new CGameModel();
    }
    return m_Instance;
}

bool CGameModel::init(void* data)
{
    Head* head = reinterpret_cast<Head*>(data);
    switch (head->SubCommand())
    {
	case CMD_LOGIN_SC:
		{
			// 初始化GameModel
			LoginSC *loginSC = reinterpret_cast<LoginSC*>(head->data());
			m_LoginClientTime = time(NULL);
			m_LoginServerTime = loginSC->serverStamp;
			LOG("client timestamp = %d, server timestamp = %d", m_LoginClientTime, m_LoginServerTime);
		}
        break;
	case CMD_LOGIN_USERMODEL_SC:
		{
			m_UserModel->init(head->data());
		}
		break;
	case CMD_LOGIN_BAGMODEL_SC:
		{
			m_BagModel->init(head->data());
		}
        break;
    case CMD_LOGIN_EQUIPMODEL_SC:
        {
            m_pEquipModel->init(head->data());
        }
		break;
	case CMD_LOGIN_SUMMONMODEL_SC:
		{
			m_SummonersModel->init(head->data());
		}
		break;
	case CMD_LOGIN_HEROMODEL_SC:
		{
			m_HeroCardBagModel->init(head->data());
		}
		break;
	case CMD_LOGIN_STAGEMODEL_SC:
		{
			m_StageModel->init(head->data());
		}
		break;
    case CMD_LOGIN_TEAMMODEL_SC:
        {
            m_pTeamModel->init(head->data());
        }
        break;
 	case CMD_LOGIN_TASKMODEL_SC:
 		{
 			m_pTaskModel->init(head->data());
 		}
		break;
	case CMD_LOGIN_ACHIEVEMODEL_SC:
		{
			m_pAchieveModel->init(head->data());
		}
		break;
	case CMD_LOGIN_GUIDEMODEL_SC:
		{
			m_pGuideModel->init(head->data());
		}
        break;
	case CMD_LOGIN_UNIONMODEL_SC:
		{
			m_pUnionModel->init(head->data());
		}
		break;
	case CMD_LOGIN_INSTANCEMODEL_SC:
		{
			m_pActivityInstanceModel->init(head->data());
		}
		break;
	case CMD_LOGIN_GOLDTESTMODEL_SC:
		{
			m_pGoldTestModel->init(head->data());
		}
		break;
	case CMD_LOGIN_HEROTESTMODEL_SC:
		{
			m_pHeroTestModel->init(head->data());
		}
		break;
	case CMD_LOGIN_TOWERTESTMODEL_SC:
		{
			m_pTowerTestModel->init(head->data());
		}
		break;
	case CMD_LOGIN_MAILMODEL_SC:
		{
			m_pMailModel->init(head->data());
		}
		break;
    case CMD_LOGIN_PVPMODEL_SC:
        {
            m_pPvpModel->init(head->data());
        }
        break;
    case CMD_LOGIN_SHOPMODEL_SC:
        {
            m_pShopModel->init(head->data());
        }
        break;
    case CMD_LOGIN_ACTIVEMODEL_SC:
        {
            m_pOperateActive->init(head->data());
        }
        break;
    case CMD_LOGIN_BAN_SC:
        {
            int time = *reinterpret_cast<int*>(head->data());
            time_t timestamp = time;
            tm* tmInfo = localtime(&timestamp);

            std::string lanStr = getLanguageString(CONF_ERROR_CODE_LAN, 802);
            const char* msgStr = String::createWithFormat(lanStr.c_str(), 
                tmInfo->tm_year + 1900, tmInfo->tm_mon + 1, tmInfo->tm_mday, tmInfo->tm_hour, tmInfo->tm_min)->getCString();

            Node* csbNode = CSLoader::createNode("ui_new/g_gamehall/g_gpub/TipPanel.csb");
            Text* infoText = findChild<Text>(csbNode, "BuyEnergyPanel/TipLabel1");
            Button* confirmBtn = findChild<Button>(csbNode, "BuyEnergyPanel/ConfrimButton");
            infoText->setString(msgStr);
            confirmBtn->addClickEventListener([](Ref*){Director::getInstance()->end(); });

            Director::getInstance()->getRunningScene()->addChild(csbNode, 100);
        }
        break;
    case CMD_LOGIN_HEAD_SC:
        {
            m_pHeadModel->init(head->data());
        }
        break;
    default:
        break;
    }
    return true;
}

void CGameModel::destroy()
{
    if (NULL != m_Instance)
    {
        delete m_Instance;
        m_Instance = NULL;
    }
}

CRoomModel* CGameModel::openRoom()
{
    if (NULL == m_Room)
    {
        m_Room = new CRoomModel();
    }
    return m_Room;
}

CRoomModel* CGameModel::openReplayRoom()
{
    if (NULL == m_Room)
    {
        m_Room = new CReplayRoomModel();
    }
    return m_Room;
}

int CGameModel::getNow()
{
    // 计算客户端的相对时间
	int clientNow = time(NULL);
	int elapseTick = clientNow - m_LoginClientTime;
    // 累加到登录时，服务端的时间戳，并返回
    return m_LoginServerTime + elapseTick;
}

bool CGameModel::isFreePickCard()
{
	return m_UserModel->getFreeHeroTimes() > 0;
}
