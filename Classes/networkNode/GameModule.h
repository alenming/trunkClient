#ifndef __GAMEMODULE_H__
#define __GAMEMODULE_H__

#include "BaseModule.h"

class CGameModule : 
    public CBaseModule
{
public:
    CGameModule(void);
    ~CGameModule(void);

    // 处理收到的数据
    virtual void processLogic(char* buffer, unsigned int len, KxServer::IKxComm *target);
    // 处理出现的错误
    virtual void processError(KxServer::IKxComm *target);
    // 处理事件
    virtual void processEvent(int eventId, KxServer::IKxComm* target);
};

#endif 
