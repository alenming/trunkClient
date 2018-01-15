#include "CommonProxy.h"
#include "KxCSComm.h"
#include "GameNetworkNode.h"
#include "LuaSummonerBase.h"

#include "Protocol.h"
#include "LoginProtocol.h"
#include "UserProtocol.h"
#include "BagProtocol.h"
#include "StageProtocol.h"
#include "PvpProtocol.h"
#include "SummonerProtocol.h"
#include "HeroProtocol.h"

CCommonProxy::CCommonProxy()
{
    m_BufferData = new CBufferData();
}

CCommonProxy::~CCommonProxy()
{
    delete m_BufferData;
}

bool CCommonProxy::init(CEventManager<int> *eventMgr)
{
    if (NULL == eventMgr)
    {
        return false;
    }

    CEventProxy::init(eventMgr);
    return true;
}

int CCommonProxy::onRecv(char *buffer, int len)
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

int CCommonProxy::send(char *buffer, int len)
{
    return CGameNetworkNode::getInstance()->sendData(buffer, len);
}

int CCommonProxy::onError(int error, int tag, char *data)
{
    return 0;
}

void CCommonProxy::onEventSend(void *data)
{
    //解析出长度
    Head *head = reinterpret_cast<Head*>(data);
    int len = head->length;
    send(reinterpret_cast<char*>(data), len);
}
