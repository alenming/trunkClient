#include "Game.h"
#include "KxMemPool.h"
#include "Protocol.h"
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "QQHallManager.h"
#else
#include "extern/qqHall/QQHallManager.h"
#endif

using namespace KxServer;

CGame::CGame() :BattleHelper(NULL)
, User(NULL)
, EventMgr(NULL)
, UserId(0)
{
	CCLOG("CGame()");

    if (CQQHallManager::GetInstance()->getCmdLineID() != "")
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
        m_bDebug = false;
        m_nPfType = EQQHall;
#else
        m_bDebug = false;
        m_nPfType = EQQHall;
#endif
    }
    else
    {
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
        m_bDebug = true;
        m_nPfType = EDebug;
#else
        m_bDebug = false;
        m_nPfType = EAnySDK;
#endif
    }
}

CGame::~CGame()
{
	CCLOG("~CGame()");
	SAFE_DELETE(User);
	SAFE_DELETE(EventMgr);
}

CGame* CGame::m_Instance = NULL;
CGame* CGame::getInstance()
{
	if (NULL == m_Instance)
	{
		m_Instance = new CGame();
	}
	return m_Instance;
}

void CGame::destory()
{
	if (NULL != m_Instance)
	{
		delete m_Instance;
		m_Instance = NULL;
	}
}

bool CGame::init()
{
	User = new CPlayerModel();
	EventMgr = new CEventManager<int>();
	return true;
}

void CGame::sendRequest(int maincmd, int subcmd, void *data, int len)
{
	int sendlen = sizeof(Head);
    char* eventData = reinterpret_cast<char *>(kxMemMgrAlocate(sendlen + len));
    int dataLen = sendlen;

    Head *head = reinterpret_cast<Head *>(eventData);
	head->id = UserId;
	head->cmd = MakeCommand(maincmd, subcmd);
	head->length = sendlen;
	
	if (len > 0 && NULL != data)
	{
		memcpy(head + 1, data, len);
        dataLen += len;
        head->length = dataLen;
	}

	CCLOG("send request maincmd=%d, subcmd=%d, len=%d", maincmd, subcmd, len);
    EventMgr->raiseEvent(head->cmd, eventData);

    if (NULL != eventData)
    {
        kxMemMgrRecycle(eventData, dataLen);
    }
}