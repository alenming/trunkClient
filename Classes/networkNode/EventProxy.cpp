#include "EventProxy.h"


CEventProxy::CEventProxy()
    :m_pEventManager(NULL)
{
}

CEventProxy::~CEventProxy()
{
}

bool CEventProxy::init(CEventManager<int>* eventMgr)
{
    m_pEventManager = eventMgr;
    return NULL != m_pEventManager;
}

void CEventProxy::clear()
{
    if (NULL != m_pEventManager)
    {
        m_pEventManager->removeEventHandle(this);
    }
}