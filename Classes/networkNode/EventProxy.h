#ifndef __EVENT_PROXY_H__
#define __EVENT_PROXY_H__

#include "EventManager.h"
#include "BaseProxy.h"

class CEventProxy : public CBaseProxy
{
public:
    CEventProxy();
    virtual ~CEventProxy();
    virtual bool init(CEventManager<int>* eventMgr);
    virtual void clear();
protected:
    CEventManager<int>* m_pEventManager;
};

#endif
