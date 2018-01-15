/*
*   节点服务
*   1.提供了节点树查询功能
*   2.提供了节点信息查询、修改功能
*   3.提供了节点激活、删除功能
*
*   2015-11-19 by 宝爷
*/
#ifndef __NODE_SERVICE_H__
#define __NODE_SERVICE_H__

#include "KxDebuger.h"

namespace kxdebuger {

class NodeService : public IService
{
public:
    NodeService();
    virtual ~NodeService();

    virtual void process(int actionId, void* data, int len, KxServer::IKxComm *target);
};

}

#endif
