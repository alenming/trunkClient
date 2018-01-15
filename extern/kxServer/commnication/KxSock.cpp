#include "KxSock.h"
#include "KxLog.h"

namespace KxServer {

bool KxSock::s_IsInit = false;

#if (KX_TARGET_PLATFORM == KX_PLATFORM_WIN32) && (defined(__MINGW32__) || (_MSC_VER < 1900))
// inet
const char* inet_ntop_(int af, const void* src, char* dst, int cnt)
{
    struct sockaddr_in srcaddr;

    memset(&srcaddr, 0, sizeof(struct sockaddr_in));
    memcpy(&(srcaddr.sin_addr), src, sizeof(srcaddr.sin_addr));

    srcaddr.sin_family = af;
    if (WSAAddressToStringA((struct sockaddr*) &srcaddr, sizeof(struct sockaddr_in), 0, dst, (LPDWORD)&cnt) != 0)
    {
        return nullptr;
    }
    return dst;
}
#endif

bool KxSock::initSock()
{
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    WORD wVersionRequested;
    WSADATA wsaData;
    int err;
    
    wVersionRequested = MAKEWORD(2, 2);
    
    err = WSAStartup(wVersionRequested, &wsaData);
    if (err != 0)
    {
        return false;
    }
    
    if (LOBYTE(wsaData.wVersion) != 2 ||
        HIBYTE(wsaData.wVersion) != 2)
    {
        WSACleanup();
        return false;
    }
#endif
    s_IsInit = true;
    return true;
}

void KxSock::uninitSock()
{
#ifdef WIN32
    WSACleanup();
#endif
    s_IsInit = false;
}

KxSock::KxSock()
: m_IsNonBlock(false)
, m_SockType(KXSOCK_UNKNOWN)
, m_Sock(KXINVALID_COMMID)
, m_SockVersion(KXV_IPV4)
{
	if (!s_IsInit)
	{
		initSock();
	}
}

KxSock::~KxSock()
{
	close();
}

bool KxSock::init(KXSOCK_TYPE type, KXSOCK_VERSION sv)
{
    if (KXINVALID_COMMID != m_Sock)
    {
        return false;
    }

    m_SockType = type;
	m_SockVersion = sv;
    switch (m_SockType)
    {
		case KXSOCK_TCP:
		{
			if (sv == KXV_IPV6)
			{
				return true; 
			}
			m_Sock = socket(AF_INET, SOCK_STREAM, 0);
		}			
            break;

        case KXSOCK_UDP:
			m_Sock = socket(sv == KXV_IPV4 ? AF_INET : AF_INET6, SOCK_DGRAM, 0);
            break;

        default:
            break;
    }
    if (m_Sock == KXINVALID_COMMID)
    {
        echoSockError("init");
        return false;
    }
	return true;
}

bool KxSock::init(KXCOMMID fd)
{
    if (KXINVALID_COMMID != m_Sock)
    {
        KXLOGERROR("error: KxSock::init sock %d init with %d faile", m_Sock, fd);
        return false;
    }
    
    m_Sock = fd;
    m_SockType = KXSOCK_TCP;
    return m_Sock != KXINVALID_COMMID;
}

int KxSock::listen(int maxListenQueue)
{
    int ret = ::listen(m_Sock, maxListenQueue);
    if (ret < 0)
    {
        echoSockError("listen");
    }
    return ret;
}

int KxSock::connect(const char* addr, int port)
{
    KXLOGDEBUG("debug: KxSock::connect %s : %d socket %d", addr, port, m_Sock);
	if (m_SockVersion == KXV_IPV4)
	{
		sockaddr_in name;
		sockInitAddr(name, port, addr);
		return ::connect(m_Sock, (sockaddr*)&name, sizeof(sockaddr));
	}
	else
	{
		addrinfo *allres;
		addrinfo *res;
		addrinfo hints;
		int ret = 0;
		char szPort[16] = {};
		snprintf(szPort, sizeof(szPort), "%d", port);
		memset(&hints, 0, sizeof(hints));
		hints.ai_family = AF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = IPPROTO_TCP;
		int airet = getaddrinfo(addr, szPort, &hints, &allres);

		for (res = allres; res != NULL; res = allres->ai_next)
		{
			m_Sock = ::socket(res->ai_family, res->ai_socktype, res->ai_protocol);
			if (m_IsNonBlock)
			{
				setSockNonblock();
			}
			setSockKeepAlive();
			ret = ::connect(m_Sock, res->ai_addr, res->ai_addrlen);
			// 如果非阻塞, 应该要连接到ret==0才返回
			break;
		}
		freeaddrinfo(allres);
		return ret;
	}
}

int KxSock::bind(const char* addr, int port)
{
	int ret = 0;
	if (m_SockVersion == KXV_IPV4)
	{
		sockaddr_in name;
		sockInitAddr(name, port, addr);
		ret = ::bind(m_Sock, (sockaddr*)&name, sizeof(sockaddr));
	}
	else
	{
		addrinfo *res;
		addrinfo addrInfo;
		memset(&addrInfo, 0, sizeof(addrInfo));
		addrInfo.ai_flags = AI_PASSIVE;
		addrInfo.ai_family = AF_INET6;
		addrInfo.ai_socktype = SOCK_STREAM;
		addrInfo.ai_protocol = 0;
		char szPort[16] = {};
		snprintf(szPort, sizeof(szPort), "%d", port);
		getaddrinfo(addr, szPort, &addrInfo, &res);
		ret = ::bind(m_Sock, res->ai_addr, res->ai_addrlen);
		freeaddrinfo(res);
	}
    if (ret < 0)
    {
        echoSockError("bind");
    }
    return ret;
}

KXCOMMID KxSock::accept()
{
	sockaddr_in6 name;
	socklen_t len = sizeof(sockaddr_in6);
    KXCOMMID ret = ::accept(m_Sock, (sockaddr*)&name, &len);
    if (ret != KXINVALID_COMMID)
    {
		int BUFLEN = 16384;
		char buf[16384] = {};
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
		inet_ntop_(name.sin6_family, name.sin6_addr.s6_addr, buf, BUFLEN);
#endif
		KXLOGDEBUG("debug: KxSock::accept ip %s prot %d socketId %d", buf, name.sin6_port, ret);
    }
    else
    {
        echoSockError("accept");
    }
    return ret;
}

int KxSock::send(const char* buffer, int size)
{
    switch (m_SockType)
    {
        case KXSOCK_TCP:
            return (int)::send(m_Sock, buffer, size, 0);
    
        case KXSOCK_UDP:
            return (int)::sendto(m_Sock, buffer, size, 0, (sockaddr*)&m_SockAddr, sizeof(m_SockAddr));
    
        default:
            return KXSOCK_ERRORTYPE;
    }
}

int KxSock::recv(char* buffer, int size)
{
    switch (m_SockType)
    {
        case KXSOCK_TCP:
            return (int)::recv(m_Sock, buffer, size, 0);

        case KXSOCK_UDP:
            {
                int len = sizeof(sockaddr);
                return (int)::recvfrom(m_Sock, buffer, size, 0, (sockaddr*)&m_SockAddr, (kxSockLen*)&len);
            }

        default:
            return KXSOCK_ERRORTYPE;
    }
}

void KxSock::close()
{
    KXLOGDEBUG("debug: KxSock::close %d close", m_Sock);
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    ::closesocket(m_Sock);
#else
	::close(m_Sock);
#endif
    m_Sock = KXINVALID_COMMID;
}

void KxSock::setSockAddr(kxSocketAddr &name)
{
	m_SockAddr = name;
}

void KxSock::setSockAddr(const char* ip, int port)
{
	sockInitAddr(m_SockAddr, port, ip);
}

void KxSock::setSockNonblock()
{
	m_IsNonBlock = true;
	if (m_Sock != KXINVALID_COMMID)
	{
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
		u_long nonblocking = 1;
		if (ioctlsocket(m_Sock, FIONBIO, &nonblocking) == SOCKET_ERROR)
		{
			echoSockError("setSockNonblock");
		}
#else
		int flags;
		if ((flags = fcntl(m_Sock, F_GETFL, NULL)) < 0) 
		{
			echoSockError("setSockNonblock fcntl F_GETFL");
			return;
		}
		if (fcntl(m_Sock, F_SETFL, flags | O_NONBLOCK) == -1) 
		{
			echoSockError("setSockNonblock fcntl F_SETFL");
			return;
		}
#endif
	}
}

void KxSock::setSockKeepAlive()
{
	if (m_Sock != KXINVALID_COMMID)
	{
		int on = 1;
		if (setsockopt(m_Sock, SOL_SOCKET, SO_KEEPALIVE, (char*)&on, sizeof(on)) < 0)
		{
			echoSockError("setSockKeepAlive setsockopt SO_KEEPALIVE");
		}
	}
}

void KxSock::setSockNondelay()
{
	if (m_Sock != KXINVALID_COMMID)
	{
		int on = 1;
		if (setsockopt(m_Sock, IPPROTO_TCP, TCP_NODELAY, (char*)&on, sizeof(on)) < 0)
		{
			echoSockError("setSockNondelay");
		}
	}
}

void KxSock::setSockAddrReuse()
{
	if (m_Sock != KXINVALID_COMMID)
	{
		int on = 1;
		if (setsockopt(m_Sock, SOL_SOCKET, SO_REUSEADDR, (char*)&on, sizeof(on)) < 0)
		{
			echoSockError("setSockAddrReuse");
		}
	}
}

void KxSock::sockInitAddr(kxSocketAddr &name, int port, const char* ip)
{
	name.sin_family		= AF_INET;
	name.sin_port		= htons(port);
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    name.sin_addr.S_un.S_addr = (NULL == ip) ? htonl(INADDR_ANY) : inet_addr(ip);
#else
    name.sin_addr.s_addr = (NULL == ip) ? htonl(INADDR_ANY) : inet_addr(ip);
#endif
}

bool KxSock::isSockBlockError()
{
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    int errorCode = WSAGetLastError();
    if (WSAEWOULDBLOCK == errorCode || WSAEINPROGRESS == errorCode
        || WSAEINTR == errorCode)
    {
        return true;
    }
    KXLOGERROR("error: sock %d isSockBlockError %d ", m_Sock, errorCode);
#else
    if (errno == EWOULDBLOCK || errno == EAGAIN 
        || errno == EINPROGRESS || errno == EINTR)
    {
        return true;
    }
    KXLOGERROR("error: sock %d isSockBlockError %d %s", m_Sock, errno, strerror(errno));
#endif
    return false;
}

int KxSock::getSockError()
{
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    return WSAGetLastError();
#else
    return errno;
#endif
}

void KxSock::echoSockError(const char* msg)
{
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
    int errorCode = WSAGetLastError();
    KXLOGERROR("error: KxSock::echoSockError sock %d msg %s SockError %d ", m_Sock, msg, errorCode);
#else
    KXLOGERROR("error: KxSock::echoSockError sock %d msg %s SockError %d %s", m_Sock, msg, errno, strerror(errno));
#endif
}

}
