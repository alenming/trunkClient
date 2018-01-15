/*
*  KxDebuger 核心引擎单例
*  提供了初始化、注册服务、管理全局更新等功能
*
*  2015-11-19 by 宝爷 
*/
#ifndef __KX_DEBUGER_H__
#define __KX_DEBUGER_H__

#include "cocos2d.h"
#include "KxServer.h"
#include "IService.h"
#include "DebugerModule.h"
#include "KxDebugerProtocol.h"

namespace kxdebuger {

class DebugerModule;
class KxPollNode;
typedef std::function<void(float)> scheduleCallback;

class KxDebuger : public cocos2d::Ref
{
private:
    KxDebuger();
    virtual ~KxDebuger();

public:
    static KxDebuger* getInstance();
    static void destroy();

    // 初始化TCP监听器以及相应的Module
    // 注册默认的Service
    // 创建PollNode，并添加到引擎的通知节点下
    // 调试器监听的端口
    virtual bool init(int port = 6666);
    // 注册一个Service，用于处理服务
    virtual bool addService(int serviceId, IService* service);
    // 注销一个Service
    virtual void removeService(int serviceId);
    // 清除所有Service
    virtual void clearService();

    inline KxPollNode* getPoller() { return m_PollNode; }

private:
    KxPollNode* m_PollNode;
    DebugerModule* m_DebugerModule;
    static KxDebuger* m_Instance;
};

}
#endif
