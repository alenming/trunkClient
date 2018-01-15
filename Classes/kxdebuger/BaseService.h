/*
*   基础服务
*   1.提供游戏暂停和恢复功能
*   2.提供游戏单步前进功能
*
*   2015-11-19 By 宝爷
*/

#ifndef __BASE_SERVICE_H__
#define __BASE_SERVICE_H__

#include "KxDebuger.h"

namespace kxdebuger {

class BaseService : public IService
{
public:
    BaseService();
    virtual ~BaseService();

    virtual void process(int actionId, void* data, int len, KxServer::IKxComm *target);

private:
    void actionStepSelector(float dt);
};

}

#endif
