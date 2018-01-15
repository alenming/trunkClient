#include "KxTCPClienter.h"

namespace KxServer {

KxTCPClienter::KxTCPClienter()
{
}

KxTCPClienter::~KxTCPClienter()
{
}

bool KxTCPClienter::init(KXCOMMID fd)
{
    if (NULL == m_Socket)
    {
        m_Socket = new KxSock();
    }
    changePollType(KXPOLLTYPE_IN);
    if (m_Socket->init(fd))
    {
        m_Socket->setSockNonblock();
        m_Socket->setSockKeepAlive();
        return true;
    }
    return false;
}

}
