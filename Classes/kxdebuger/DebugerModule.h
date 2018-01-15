/*
*
*   2015-11-19 by 宝爷
*/
#ifndef __DEBUGER_MODULE_H__
#define __DEBUGER_MODULE_H__

#include "KXServer.h"
#include "KxDebuger.h"

namespace kxdebuger {

class DebugerModule :
    public KxServer::IKxModule
{
public:
    DebugerModule();
    virtual ~DebugerModule();

    virtual void processLogic(char* buffer, unsigned int len, KxServer::IKxComm *target);
    virtual void processError(KxServer::IKxComm *target);

    // 返回需要处理的数据长度, tcp分包接口
    virtual int processLength(char* buffer, unsigned int len);

    // 注册一个Service，用于处理服务
    virtual bool addService(int serviceId, IService* service);
    // 注销一个Service
    virtual void removeService(int serviceId);
    // 清除所有Service
    virtual void clearService();

private:
    std::map<int, IService*> m_Services;
};

}

#endif