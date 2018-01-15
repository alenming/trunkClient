#include "BaseModule.h"
#include "Protocol.h"
#include "cocos2d.h"

CBaseModule::CBaseModule(void)
{
}

CBaseModule::~CBaseModule(void)
{
}

int CBaseModule::processLength(char* buffer, unsigned int len)
{
    // 返回一个包的长度, 由包头解析, 解析的长度包括包头
    if (len < sizeof(int))
    {
        return sizeof(int);
    }
    else
    {
        int ret = reinterpret_cast<Head*>(buffer)->length;
        CCLOG("processLength %d in len %d", ret, len);
        return ret;
    }
}
