#ifndef __QQ_HALL_MANAGER_H_
#define __QQ_HALL_MANAGER_H_

#include "ClientProcMsgObject_i.h"
#include "Define.h"
#include "cocos2d.h"
#include <string>

std::wstring StringUtf8ToWideChar(const std::string& strUtf8);

class CQQHallManager
    : public IClientProcMsgEventHandler
{
private:
    CQQHallManager();
    ~CQQHallManager();

public:
    static CQQHallManager* GetInstance();
    static void Destory();
    bool Init(wchar_t* cmdLine);

    bool ConncetPipe();

    virtual void OnConnectSucc(IClientProcMsgObject* pClientProcMsgObj);
    virtual void OnConnectFailed(IClientProcMsgObject* pClientProcMsgObj
        , unsigned long dwErrorCode);
    virtual void OnConnectionDestroyed(IClientProcMsgObject* pClientProcMsgObj);
    virtual void OnReceiveMsg(IClientProcMsgObject* pClientProcMsgObj
        , long lRecvLen, const char* pRecvBuf);

    bool isQQHall(){ return m_bIsQQHall; }
    std::string getCmdLineID(){ return m_strOpenId; }
    std::string getCmdLineKey(){ return m_strOpenKey; }
    std::string getCmdLinePROCPARA(){ return m_strProcPara; }

	void waitForQQPay();

private:
    void clearArgs();
    bool LoadQQLibrary();
    IClientProcMsgObject* CreateObj();
    void ReleaseObj(IClientProcMsgObject* pObj);

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
    void SendMsgToGame(IClientProcMsgObject* pProcMsgObj, PROCMSG_DATA* pProcMsgData);
#endif

private:
    static CQQHallManager *m_pInstance;

    bool m_bIsQQHall;
    std::string m_strOpenId;
    std::string m_strOpenKey;
    std::string m_strProcPara;
    IClientProcMsgObject* m_pProcMsgObj;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
    HINSTANCE m_hModule;
#endif
};

#endif // __QQ_HALL_MANAGER_H_
