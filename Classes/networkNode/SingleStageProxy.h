/*
*   用于本地单机进入关卡
*   1.接收玩家进入关卡的请求
*   2.模拟服务器的进入关卡响应，并通知到Lua层中
*
*/
#ifndef __SINGLE_STAGE_ROXY_H__
#define __SINGLE_STAGE_ROXY_H__

#include "EventProxy.h"
#include "BufferData.h"

class CSingleStageProxy : public CEventProxy
{
public:
	CSingleStageProxy();
	virtual ~CSingleStageProxy();

public:
	//初始化公共代理
	virtual bool init(CEventManager<int>* eventMgr);
	//代理接受数据处理
	virtual int onRecv(char *buffer, int len);
	//代理发送数据处理
	virtual int send(char *buffer, int len);
	//错误处理
	virtual int onError(int error, int tag = 0, char *data = 0);

	//事件回调接口
    virtual void onEventSend(void *data);

private:
    CBufferData* m_BufferData;
};

#endif 