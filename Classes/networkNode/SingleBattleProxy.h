/*
*   负责模拟本地战斗的网络通信
*   1.接收玩家操作请求，直接在本地处理转发到战斗层
*
*/
#ifndef __SINGLEBATTLEPROXY_H__
#define __SINGLEBATTLEPROXY_H__

#include "EventProxy.h"

class CSingleBattleProxy : public CEventProxy
{
public:
    CSingleBattleProxy();
    virtual ~CSingleBattleProxy();

public:
    //初始化公共代理
    virtual bool init(CEventManager<int>* eventMgr);
    //代理接受数据处理
    virtual int onRecv(char *buffer, int len);
    //代理发送数据处理
    virtual int send(char *buffer, int len);
    //错误处理
    virtual int onError(int error, int tag = 0, char *data = 0);
    //内部直接处理转发
    void onEventSend(void *data);
};

#endif 
