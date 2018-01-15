#ifndef __PROXYMANAGER_H__
#define __PROXYMANAGER_H__

#include "BaseProxy.h"
#include <map>

class CProxyManager
{
private:
    CProxyManager(void);
    ~CProxyManager(void);

public:

    static CProxyManager *getInstance();
    static void destroy();

    // ÒÔÖ÷ÃüÁîÎªKey
    void addProxy(int cmdMain, CBaseProxy *pProxy);
    CBaseProxy *getProxy(int cmdMain);

    void setCommProxy(CBaseProxy* proxy);
    CBaseProxy *getCommProxy();

private:

    static CProxyManager*       m_pInstance;
    std::map<int, CBaseProxy*>  m_mapProxy;
    CBaseProxy*                 m_pCommProxy;
};

#endif 
