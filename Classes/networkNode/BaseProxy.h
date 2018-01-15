#ifndef __BASEPROXY_H__
#define __BASEPROXY_H__

#include "KxCSComm.h"

class CBaseProxy : public Ref
{
public:
    CBaseProxy(void);
    virtual ~CBaseProxy(void);

public:
    //业务逻辑处理接收到消息
    virtual int onRecv(char *buffer, int len) = 0;
    //逻辑处理完发送消息
    virtual int send(char *buffer, int len) = 0;
    //异常, error为错误类型, 后面参数为信息
    virtual int onError(int error, int tag = 0 , char *data = 0) = 0;
    //清理
    virtual void clear() { };
};

#endif 
