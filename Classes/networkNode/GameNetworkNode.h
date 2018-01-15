/*
*   负责网络的初始化, 网络状态监视, 以及网络轮询
*
*/

#ifndef __GAMENETWORKNODE_H__
#define __GAMENETWORKNODE_H__

#include <functional>
#include "cocos2d.h"
#include "KxServer.h"
#include "KxCSComm.h"

enum EServerConnType
{
    SERVER_CONN_SESSION,      // session服务器连接
    SERVER_CONN_CHAT,         // chat服务器连接
};

struct ServerConn
{
    std::string                 ConnIP;         // 连接的ip地址
    int                         Port;               // 连接的端口
    int                         ConnectingTimes;    // 正在重连中的次数（大于10次强制关闭重启）
    KxServer::KXSOCK_VERSION	SockVersion;        // ipv4/ipv6
    KxServer::KxTCPConnector*   Connector;          // 连接
    std::function<void(bool)>   ConnectCallback;

    ServerConn() :Port(0)
        , ConnectingTimes(0)
        , SockVersion(KxServer::KXV_IPV6)
        , Connector(nullptr)
        , ConnectCallback(nullptr)
    {
    }
};

class CBaseModule;
class CGameNetworkNode : 
    public Node
{
private:
    CGameNetworkNode(void);
    ~CGameNetworkNode(void);

public:

    static CGameNetworkNode *getInstance();
    static void destroy();

    bool init();
    void onEnter();
    void onExit();
    void update(float dt);
    void visit(cocos2d::Renderer *renderer, const cocos2d::Mat4& parentTransform, uint32_t parentFlags);

    CREATE_FUNC(CGameNetworkNode);

    // 连接到指定ip, port
    bool connectToServer(const char *ip, int port, EServerConnType connType, KxServer::KXSOCK_VERSION version = KxServer::KXV_IPV6,
        std::function<void(bool)> callBack = nullptr);
    // 发送数据
    int sendData(char* buffer, unsigned int len, EServerConnType connType = SERVER_CONN_SESSION);
    // 提供重连接口, 按照之前选择的服务器ip地址
    bool reconnectToServer(EServerConnType connType, std::function<void(bool)> callBack = nullptr);
    // 是否启动心跳, 默认启动
    void setIsHeartbeat(bool bEnabled);
    // 设置心跳时间
    void setHeartbeatTime(float fHbTime);
    // 断开连接
    void closeConnect();
    // 获得连接
    KxServer::KxTCPConnector *getConnector(EServerConnType connType = SERVER_CONN_SESSION);
    // 获取连接信息
    ServerConn* getServerConn(EServerConnType connType = SERVER_CONN_SESSION);
	// 是否用户主动关闭
    bool isUserClose(){ return m_bUserClose; }

private:
    // 心跳, 检查网络状态
    void heartbeatScheduler(float dt);
    // 注册网络通信消息, 用于重置心跳包时间
    void registeNetworkCommunicate(void *data);

private:
    bool                                m_bUserClose;
    bool                                m_bEnabledHb;                   // 是否启动心跳
    float                               m_fMaxHbTime;                   // 多久没数据交互发送一次心跳包
    float                               m_fTickNet;                     // 计算与上次交互数据间隔时间
    static CGameNetworkNode*            m_pInstance;                    // 
    KxServer::IKxCommPoller*            m_pPoller;                      // 轮询器
    CBaseModule*                        m_pGameModule;                  // 处理逻辑模块实例
    CBaseModule*                        m_pChatModule;                  // 处理聊天模块实例

    std::map<int, ServerConn>           m_mapServerConns;               // 服务器连接
};

#endif 
