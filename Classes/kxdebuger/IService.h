/*
*   Service的公共接口
*
*   2015-11-19 by 宝爷
*/
#ifndef __ISERVICE_H__
#define __ISERVICE_H__

#include "cocos2d.h"
#include "KXServer.h"

class IService : public cocos2d::Ref
{
public:
    IService();
    virtual ~IService();

    virtual void process(int actionId, void* data, int len, KxServer::IKxComm *target) = 0;

protected:
    //发送信息
    void sendData(int serviceId, int actionId, const void *data, int len, KxServer::IKxComm *target);
};

#endif
