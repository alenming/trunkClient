#ifndef __LISTENER_MODULE_H__
#define __LISTENER_MODULE_H__

#include "KXServer.h"

namespace kxdebuger {

class ListenerModule : public KxServer::IKxModule
{
public:
    ListenerModule();
    virtual ~ListenerModule();

    virtual void processLogic(char* buffer, unsigned int len, KxServer::IKxComm *target);
    virtual void processError(KxServer::IKxComm *target);
};

}

#endif
