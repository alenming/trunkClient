#include "KxSelectPoller.h"
#include "KxLog.h"

using namespace std;

namespace KxServer {

    KxSelectPoller::KxSelectPoller()
        : m_MaxCount(0)
        , m_IsBlock(false)
    {
		m_InSet = new fd_set;
		m_OutSet = new fd_set;
		FD_ZERO(m_InSet);
		FD_ZERO(m_OutSet);
        m_TimeOut.tv_sec = 0;
        m_TimeOut.tv_usec = 0;
    }

    KxSelectPoller::~KxSelectPoller()
    {
		if (NULL != m_InSet)
		{
			delete m_InSet;
			m_InSet = NULL;
		}
		if (NULL != m_OutSet)
		{
			delete m_OutSet;
			m_OutSet = NULL;
		}
        for (map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.begin();
            iter != m_PollMap.end(); ++iter)
        {
            iter->second->release();
        }
    }

    int KxSelectPoller::poll()
    {
        fd_set inset;
        fd_set outset;
		fd_set expset;
		memcpy(&inset, m_InSet, sizeof(inset));
		memcpy(&outset, m_OutSet, sizeof(outset));
		memcpy(&expset, m_OutSet, sizeof(expset));
		int ret = select(m_MaxCount, &inset, &outset, &expset,
            m_IsBlock ? NULL : reinterpret_cast<timeval*>(&m_TimeOut));
        if (ret > 0)
        {
            int eventCounts = ret;
            map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.begin();
            // 先遍历获取触发的事件
            while (eventCounts > 0 && iter != m_PollMap.end())
            {
                IKxComm* obj = iter->second;
                KXCOMMID fd = obj->getCommId();
                int events = 0;
                if (FD_ISSET(fd, &inset))
                {
                    events |= KXPOLLTYPE_IN;
                    --eventCounts;
                }
                if (FD_ISSET(fd, &outset)
					|| FD_ISSET(fd, &expset))
                {
                    events |= KXPOLLTYPE_OUT;
                    --eventCounts;
                }

                if (events != 0)
                {
                    KxCommExecuter etr;
                    etr.events = events;
                    etr.obj = obj;
                    obj->retain();
                    m_ExecuterList.push_back(etr);
                }
                ++iter;
            }

            // 再执行触发的事件
            std::vector<KxCommExecuter>::iterator eiter = m_ExecuterList.begin();
            for (; eiter != m_ExecuterList.end(); ++eiter)
            {
                IKxComm* obj = (*eiter).obj;
                int events = (*eiter).events;
                if ((events & KXPOLLTYPE_IN && 0 > obj->onRecv())
                    || (events & KXPOLLTYPE_OUT && 0 > obj->onSend()))
                {
                    obj->onError();
                    removeCommObject(obj);
                }

                obj->release();
            }
            m_ExecuterList.clear();

        }
        else if (0 > ret)
        {
#if(KX_TARGET_PLATFORM == KX_PLATFORM_WIN32)
            int errorNo = WSAGetLastError();
            if (errorNo != WSAEINVAL)
            {
                KXLOGDEBUG("select error %d", errorNo);
            }
#else
            KXLOGDEBUG("select errno is %d", errno);
#endif
        }
        return ret;
    }

    int KxSelectPoller::addCommObject(IKxComm* obj, int type)
    {
        if (NULL == obj)
        {
            return -1;
        }

        KXCOMMID fd = obj->getCommId();
        map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.find(fd);
        if (iter != m_PollMap.end())
        {
            // 重复添加，只需要按type重新设置即可
            // 如果有失效，先干掉失效的
            if (iter->second != obj)
            {
                iter->second->release();
                m_PollMap.erase(iter);
                goto insetPoller;
            }
        }
        else
        {
        insetPoller:
            obj->retain();
            m_PollMap[fd] = obj;
        }
        obj->setPollType(type);
        obj->setPoller(this);

#if(KX_TARGET_PLATFORM != KX_PLATFORM_WIN32)
        if (m_MaxCount <= fd)
        {
            m_MaxCount = fd + 1;
        }
#endif
        applyChange(fd, type);
        return 0;
    }

    int KxSelectPoller::modifyCommObject(IKxComm* obj, int type)
    {
        if (obj == NULL)
        {
            return -1;
        }
        KXCOMMID fd = obj->getCommId();
        if (obj->getPoller() != this)
        {
            KXLOGERROR("error: KxSelectPoller::removeCommObject %d poller is %x", fd, obj->getPoller());
            return -1;
        }
        map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.find(fd);
        if (iter == m_PollMap.end())
        {
            KXLOGERROR("error: KxSelectPoller::removeCommObject can't find %d in pollMap", fd);
            return -1;
        }
        obj->setPollType(type);
        applyChange(fd, type);
        return 0;
    }

    int KxSelectPoller::removeCommObject(IKxComm* obj)
    {
        if (obj == NULL)
        {
            return -1;
        }
        KXCOMMID fd = obj->getCommId();
        if (obj->getPoller() != this)
        {
            KXLOGERROR("error: KxSelectPoller::removeCommObject %d poller is %x", fd, obj->getPoller());
            return -1;
        }
        map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.find(fd);
        if (iter == m_PollMap.end())
        {
            KXLOGERROR("error: KxSelectPoller::removeCommObject can't find %d in pollMap", fd);
            return -1;
        }
        obj->setPoller(NULL);
        applyChange(fd, 0);
        iter->second->release();
        m_PollMap.erase(iter);
        return 0;
    }

    void KxSelectPoller::applyChange(KXCOMMID fd, int events)
    {
        if (events & KXPOLLTYPE_IN)
        {
            FD_SET(fd, m_InSet);
        }
        else
        {
            FD_CLR(fd, m_InSet);
        }

        if (events & KXPOLLTYPE_OUT)
        {
            FD_SET(fd, m_OutSet);
        }
        else
        {
            FD_CLR(fd, m_OutSet);
        }
    }

    IKxComm* KxSelectPoller::getComm(KXCOMMID cid)
    {
        map<KXCOMMID, IKxComm*>::iterator iter = m_PollMap.find(cid);
        if (iter == m_PollMap.end())
        {
            return NULL;
        }
        else
        {
            return iter->second;
        }
         return NULL;
    }

}
