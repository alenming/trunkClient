#include "GameModule.h"
#include "ProxyManager.h"
#include "BaseProxy.h"
#include "Protocol.h"
#include "GameNetworkNode.h"
#include "Game.h"
#include "LuaSummonerBase.h"
#include "LoginProtocol.h"

using namespace KxServer;

CGameModule::CGameModule(void)
{
}

CGameModule::~CGameModule(void)
{
}

void CGameModule::processLogic(char* buffer, unsigned int len, IKxComm *target)
{
    // 收到数据, 交由proxy处理
    Head *head = reinterpret_cast<Head*>(buffer);
    int maincmd = head->MainCommand();
    CBaseProxy *pMainProxy = CProxyManager::getInstance()->getProxy(maincmd);
    if (NULL != pMainProxy)
    {
        pMainProxy->onRecv(buffer, len);
    }
    else
    {
        CBaseProxy *pProxy = CProxyManager::getInstance()->getCommProxy();
        if (NULL != pProxy)
        {
            LOG("Process %d %d", head->MainCommand(), head->SubCommand());
            pProxy->onRecv(buffer, len);
        }
    }
}

void CGameModule::processError(IKxComm *target)
{
    CGameNetworkNode* net = CGameNetworkNode::getInstance();
    if (!net->isUserClose())
    {
        // 连接到服务器可能失败, 各种网络问题在此暴露
        CBaseProxy *pMainProxy = CProxyManager::getInstance()->getCommProxy();
        if (NULL != pMainProxy)
        {
            pMainProxy->onError(0);
            //断线事件
            onLuaEvent(-102);
        }
    }
}

void CGameModule::processEvent(int eventId, IKxComm* target)
{
    CGameNetworkNode* net = CGameNetworkNode::getInstance();
    ServerConn* pServerConn = net->getServerConn();
    if (nullptr == pServerConn)
    {
        return;
    }

	bool success = eventId != KXEVENT_CONNECT_FAILE;
	if (pServerConn->ConnectCallback != nullptr)
	{
		pServerConn->ConnectCallback(success);
		pServerConn->ConnectCallback = nullptr;
	}
}
