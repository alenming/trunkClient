/*
*   轮询节点，支持select轮询以及全局schedule
*
*   2015-11-19 by 宝爷
*/
#ifndef __KX_POLL_NODE_H__
#define __KX_POLL_NODE_H__

#include "KxDebuger.h"

namespace kxdebuger {

class KxPollNode : public cocos2d::Node
{
public:
    KxPollNode();
    virtual ~KxPollNode();

    virtual bool init();

    virtual void visit(cocos2d::Renderer *renderer, const cocos2d::Mat4& parentTransform, uint32_t parentFlags);

    bool addCommObject(KxServer::IKxComm* obj, int type);

private:
    KxServer::IKxCommPoller* m_Poller;
};

}

#endif
