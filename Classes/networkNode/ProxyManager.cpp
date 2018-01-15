#include "ProxyManager.h"
#include "BaseProxy.h"

CProxyManager::CProxyManager(void)
:m_pCommProxy(NULL)
{
}

CProxyManager::~CProxyManager(void)
{
    for (auto proxyIter : m_mapProxy)
    {
        if (proxyIter.second != NULL)
        {
            proxyIter.second->clear();
            proxyIter.second->release();
        }
    }
    m_mapProxy.clear();

    if (NULL != m_pCommProxy)
    {
        m_pCommProxy->clear();
        SAFE_RELEASE(m_pCommProxy);
    }
}

CProxyManager *CProxyManager::m_pInstance = NULL;
CProxyManager *CProxyManager::getInstance()
{
    if (NULL == m_pInstance)
    {
        m_pInstance = new CProxyManager;
    }

    return m_pInstance;
}

void CProxyManager::destroy()
{
    if (NULL != m_pInstance)
    {
        delete m_pInstance;
        m_pInstance = NULL;
    }
}

void CProxyManager::addProxy(int cmdMain, CBaseProxy *pProxy)
{
    auto old = m_mapProxy.find(cmdMain);
    if (old != m_mapProxy.end() && old->second != NULL)
    {
        old->second->clear();
        old->second->release();
    }
    m_mapProxy[cmdMain] = pProxy;
}

CBaseProxy *CProxyManager::getProxy(int cmdMain)
{
    return m_mapProxy[cmdMain];
}

void CProxyManager::setCommProxy(CBaseProxy* proxy)
{
    if (NULL != m_pCommProxy)
    {
        m_pCommProxy->clear();
        m_pCommProxy->release();
    }
    m_pCommProxy = proxy;
}

CBaseProxy *CProxyManager::getCommProxy()
{
    return m_pCommProxy;
}
