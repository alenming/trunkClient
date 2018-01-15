#include "ListenerModule.h"
#include "KxDebuger.h"
#include "KxPollNode.h"

namespace kxdebuger {

ListenerModule::ListenerModule()
{
}


ListenerModule::~ListenerModule()
{
}

void ListenerModule::processLogic(char* buffer, unsigned int len, KxServer::IKxComm *target)
{
    // 将客户端添加到Poller中
    if (target)
    {
        KxDebuger::getInstance()->getPoller()->addCommObject(
            target, target->getPollType());
    }
}

void ListenerModule::processError(KxServer::IKxComm *target)
{

}

}