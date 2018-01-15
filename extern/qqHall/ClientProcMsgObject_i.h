#pragma once

class IClientProcMsgObject;
class IClientProcMsgEventHandler;

class IClientProcMsgObject
{
public:
    virtual bool Initialize() = 0;

    //--------------------------------------------------------------------------
    // Method:    BuildConnection
    // Returns:   BOOL，建立连接是否成功
    // Parameter: lpszConnectionName 连接的标识串
    // Brief:     与子进程建立链接，进程通信方式内部lpszConnectionName来判断
    //--------------------------------------------------------------------------
    virtual bool Connect(const char* lpszConnectionName) = 0;

    //--------------------------------------------------------------------------
    // Method:    Disconnect
    // Returns:   void
    // Parameter: void
    // Brief:     断开连接
    //--------------------------------------------------------------------------
    virtual void Disconnect() = 0;

    //--------------------------------------------------------------------------
    // Method:    IsConnected
    // Returns:   BOOL，判断链接还有效
    // Parameter: void
    // Brief:     判断链接还有效
    //--------------------------------------------------------------------------
    virtual bool IsConnected() = 0;

    //--------------------------------------------------------------------------
    // Method:    SendMessage
    // Returns:   0, 发送数据成功, 非0，发送失败
    // Parameter: @pbySendBuf  发送的数据
    // Brief:     发送数据
    //--------------------------------------------------------------------------
    virtual unsigned long SendMsg(long lLen, const char* pbySendBuf) = 0;

    //--------------------------------------------------------------------------
    // Method:    AddEventHandler
    // Returns:   void
    // Parameter: pEventHandler：处理进程通信事件接口
    // Brief:     添加进程通信监听
    //--------------------------------------------------------------------------
    virtual void AddEventHandler(IClientProcMsgEventHandler* pEventHandler) = 0;

    //--------------------------------------------------------------------------
    // Method:    RemoveEventHandler
    // Returns:   void
    // Parameter: pEventHandler：处理进程通信事件接口
    // Brief:     取消进程通信监听
    //--------------------------------------------------------------------------
    virtual void RemoveEventHandler(IClientProcMsgEventHandler* pEventHandler) = 0;
};

class IClientProcMsgEventHandler
{
public:
    //--------------------------------------------------------------------------
    // Method:    OnBuildConnectionSucc
    // Returns:   void
    // Parameter: void
    // Brief:     建立连接成功
    //--------------------------------------------------------------------------
    virtual void OnConnectSucc(IClientProcMsgObject* pClientProcMsgObj) = 0;

    //--------------------------------------------------------------------------
    // Method:    OnBuildConnectionFailed
    // Returns:   void
    // Parameter: dwErrorCode：失败的错误码
    // Brief:     建立连接失败
    //--------------------------------------------------------------------------
    virtual void OnConnectFailed(IClientProcMsgObject* pClientProcMsgObj
        , unsigned long dwErrorCode) = 0;

    //--------------------------------------------------------------------------
    // Method:    OnConnectionDestroy
    // Returns:   void
    // Parameter: void
    // Brief:     连接被破坏，断开
    //--------------------------------------------------------------------------
    virtual void OnConnectionDestroyed(IClientProcMsgObject* pClientProcMsgObj) = 0;

    //--------------------------------------------------------------------------
    // Method:    OnReceiveMsg
    // Returns:   void
    // Parameter: pProcMsgData 收到的数据
    // Brief:     收到另一进程发来的数据
    //--------------------------------------------------------------------------
    virtual void OnReceiveMsg(IClientProcMsgObject* pClientProcMsgObj
        , long lRecvLen, const char* pRecvBuf) = 0;
};