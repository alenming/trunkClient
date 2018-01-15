#include "KxPollNode.h"

using namespace KxServer;

namespace kxdebuger {

KxPollNode::KxPollNode()
: m_Poller(nullptr)
{
}

KxPollNode::~KxPollNode()
{
    KXSAFE_RELEASE(m_Poller);
}

bool KxPollNode::init()
{
    if (nullptr == m_Poller)
    {
        m_Poller = new KxSelectPoller();
    }
    return true;
}

void KxPollNode::visit(cocos2d::Renderer *renderer, const cocos2d::Mat4& parentTransform, uint32_t parentFlags)
{
    if (m_Poller)
    {
        m_Poller->poll();
    }
}

bool KxPollNode::addCommObject(KxServer::IKxComm* obj, int type)
{
    if (m_Poller)
    {
        return (0 == m_Poller->addCommObject(obj, type));
    }
    return false;
}

}