/*
*  继承自IBaseModule 作为所有游戏模块相关的模版父类, 主要统一所有分包使用包头长短
*
*/

#ifndef __CBASEMODULE_H__
#define __CBASEMODULE_H__

#include "KxServer.h"

class CBaseModule :
    public KxServer::IKxModule
{
public:
    CBaseModule(void);
    virtual ~CBaseModule(void);

    // 返回需要处理的数据长度, tcp分包接口
    virtual int processLength(char* buffer, unsigned int len);
};

#endif
