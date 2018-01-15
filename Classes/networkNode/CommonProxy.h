#ifndef __COMMONPROXY_H__
#define __COMMONPROXY_H__

#include "EventProxy.h"
#include "BufferData.h"

class CCommonProxy : public CEventProxy
{
public:
    CCommonProxy();
    virtual ~CCommonProxy();

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
