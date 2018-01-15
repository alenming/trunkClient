/*
*   负责实现PVP战斗的网络通信
*   1.接收玩家操作请求，转发到服务端
*   2.接收服务端发来的所有玩家的操作响应以及纠错指令，并触发消息通知战斗层
*   
*/
#ifndef __NETBATTLEPROXY_H__
#define __NETBATTLEPROXY_H__

#include "EventProxy.h"

class CNetBattleProxy : public CEventProxy
{
public:
    CNetBattleProxy();
    virtual ~CNetBattleProxy();

public:
    //初始化
    virtual bool init(CEventManager<int>* eventMgr);
    //代理接受数据处理
    virtual int onRecv(char *buffer, int len);
    //代理发送数据处理
    virtual int send(char *buffer, int len);
    //处理错误
    virtual int onError(int error, int tag = 0, char *data = 0);
    //事件回调接口
    void onEventSend(void *data);
};

#endif 
