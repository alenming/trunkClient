#include "IService.h"
#include "KxDebugerProtocol.h"

using namespace kxdebuger;

IService::IService()
{
}


IService::~IService()
{
}

void IService::sendData(int serviceId, int actionId, const void *data, int len, KxServer::IKxComm *target)
{
    int nBufSize = sizeof(Head) + len;
    char *buf = static_cast<char*>(KxServer::KxMemManager::getInstance()->memAlocate(nBufSize));
    Head *pHead = reinterpret_cast<Head *>(buf);
    pHead->length = nBufSize;
    pHead->actionId = actionId;
    pHead->serviceId = serviceId;

    pHead += 1;

    memcpy(pHead, data, len);
    target->sendData(buf, nBufSize);
    KxServer::KxMemManager::getInstance()->memRecycle(buf, nBufSize);
}
