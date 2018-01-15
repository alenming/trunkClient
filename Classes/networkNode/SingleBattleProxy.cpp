#include "SingleBattleProxy.h"
#include "BattleProtocol.h"
#include "Protocol.h"

CSingleBattleProxy::CSingleBattleProxy()
{
}

CSingleBattleProxy::~CSingleBattleProxy()
{
}

bool CSingleBattleProxy::init(CEventManager<int>* eventMgr)
{
    if (NULL == eventMgr)
    {
        return false;
    }

    CEventProxy::init(eventMgr);
    //注册事件id
    //battle
    m_pEventManager->addEventHandle(MakeCommand(CMD_BATTLE, CMD_BAT_PVPCOMMANDCS),
        this, CALLBACK_FUNCV(CSingleBattleProxy::onEventSend));
    return true;
}

int CSingleBattleProxy::onRecv(char *buffer, int len)
{
    if (NULL != m_pEventManager)
    {
        Head *head = reinterpret_cast<Head*>(buffer);
        m_pEventManager->raiseEvent(head->cmd, buffer);
    }
    
    return 0;
}

int CSingleBattleProxy::send(char *buffer, int len)
{
    //处理消息, 需要中间层进行消息缓存, 不能直接onRecv
    return 0;
}

int CSingleBattleProxy::onError(int error, int tag, char *data)
{
    //nothing to do
    return 0;
}

void CSingleBattleProxy::onEventSend(void *data)
{
    //解析出长度
    Head *head = reinterpret_cast<Head*>(data);
    int len = head->length;

    // 转成服务器相应的命令
    int offset = head->SubCommand() - CMD_BAT_CSBEGIN;
    head->MakeCommand(CMD_BATTLE, CMD_BAT_SCBEGIN + offset);

    onRecv(reinterpret_cast<char*>(data), len);
}
