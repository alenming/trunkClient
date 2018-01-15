#pragma once

#define CS_GAME_EXIT        0x00000001  // 关闭游戏客户端
#define CS_NAVIGATE_URL     0x00000003  // 游戏请求大厅带登陆态打开一个内嵌IE页

//--第三方客户端
#define CS_REQUEST_UIN		0x00000004
#define CS_Notify_APP_TOP   0x00000008   //APP发消息过来通知此个app置顶
#define CS_Notify_APP_CLOSE 0x00000009   //app发消息过来通知用户点击了关闭，但是后台进程仍在驻留，大厅收到此消息来处理在线时长的统计
#define CS_REQUSET_VERSION  0x0000000A   //app发消息请求大厅版本号
//--end第三方客户端游戏专用

#define CS_REQ_NEWCONNECTION 0x0000000B  //app发消息请求大厅新连接
#define CS_REQ_NEWACCOUNT  0x0000000C    //app发消息请求其它帐号登录

//大厅————>游戏
#define SC_PLAYERINFO       0x00000001  // 给游戏下发自己的信息
#define SC_NOTIFY_KEY       0x00000002  // 通知客户端st变化，也做request的回复
#define SC_BOSSKEY          0x00000003  // 通知游戏老板键，0：hide 1：show
#define SC_WND_BRINGTOP     0x00000004  // 通知游戏窗口最前显示
#define SC_OPEN_KEY         0x00000005  // 给游戏下发openID、openKey
#define SC_HALL_CMDPARA     0x00000006  // 给游戏发大厅的命令参数，游戏根据这个参数来执行对应的功能，该参数由游戏方定义
#define SC_RESPONSE_UIN		0x00000007  // 同CS_REQUEST_UIN对应
#define SC_RESPONSE_NEWCONN      0x0000000B  //大厅回复游戏新连接名称
#define SC_RESPONSE_NEWCONN_RUFUSE  0x0000000C  //大厅回复游戏请求新连接错误
//------------------------------------------------------------------------------

#define MAX_PROC_START_CMD_SIZE 128 // 启动进程参数长度
#define MAX_CONNECTION_NAME_SIZE 128
#define  MAX_PROCMSG_DATABUF_LEN 64*1024

#pragma pack(1)
typedef struct stProcMsgData
{
    int  nCommandID;    //协议ID
    int  nDataLen;      //协议数据长度
    char abyData[MAX_PROCMSG_DATABUF_LEN];
}PROCMSG_DATA;
#pragma pack()
