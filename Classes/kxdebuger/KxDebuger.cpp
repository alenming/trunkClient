#include "KxDebuger.h"
#include "KxPollNode.h"
#include "ListenerModule.h"
#include "DebugerModule.h"
#include "BaseService.h"
#include "NodeService.h"

using namespace cocos2d;
using namespace KxServer;

namespace kxdebuger {

KxDebuger* KxDebuger::m_Instance = nullptr;

KxDebuger::KxDebuger()
: m_PollNode(nullptr)
, m_DebugerModule(nullptr)
{
}

KxDebuger::~KxDebuger()
{
    if (m_PollNode)
    {
        if (Director::getInstance()->getNotificationNode() == m_PollNode)
        {
            Director::getInstance()->setNotificationNode(nullptr);
        }
        else
        {
            m_PollNode->removeFromParent();
        }
        CC_SAFE_RELEASE_NULL(m_PollNode);
    }

    KXSAFE_RELEASE(m_DebugerModule);
}

KxDebuger* KxDebuger::getInstance()
{
    if (m_Instance == nullptr)
    {
        m_Instance = new KxDebuger();
    }
    return m_Instance;
}

void KxDebuger::destroy()
{
    CC_SAFE_RELEASE_NULL(m_Instance);
}

bool KxDebuger::init(int port)
{
    if (m_PollNode)
    {
        return false;
    }

    m_PollNode = new KxPollNode();
    m_PollNode->init();

    if (Director::getInstance()->getNotificationNode())
    {
        Director::getInstance()->getNotificationNode()->addChild(m_PollNode);
    }
    else
    {
        Director::getInstance()->setNotificationNode(m_PollNode);
    }

    // 开启监听
    KxTCPListener* listener = new KxTCPListener();
    if (!listener->init() || !listener->listen(port))
    {
        CCLOG("KxTCPListener init faile, listen %d", port);
        listener->release();
        return false;
    }

    // 监听模块，负责将连接上来的用户添加到轮询节点中
    ListenerModule* listenerModule = new ListenerModule();
    listener->setModule(listenerModule);
    listenerModule->release();

    // 调试模块，每个连接上来的用户都可以调试游戏
    m_DebugerModule = new DebugerModule();
    listener->setClientModule(m_DebugerModule);

    // 为调试模块注册默认的服务
    BaseService* baseService = new BaseService();
    addService(ServicesId::ServiceBase, baseService);
    baseService->release();
    NodeService* nodeService = new NodeService();
    addService(ServicesId::ServiceNode, nodeService);
    nodeService->release();

    // 添加到轮询
    m_PollNode->addCommObject(listener, listener->getPollType());
    listener->release();
    return true;
}

bool KxDebuger::addService(int serviceId, IService* service)
{
    if (m_DebugerModule)
    {
        return m_DebugerModule->addService(serviceId, service);
    }
    return false;
}

// 注销一个Service
void KxDebuger::removeService(int serviceId)
{
    if (m_DebugerModule)
    {
        m_DebugerModule->removeService(serviceId);
    }
}

// 清除所有Service
void KxDebuger::clearService()
{
    if (m_DebugerModule)
    {
        m_DebugerModule->clearService();
    }
}

}