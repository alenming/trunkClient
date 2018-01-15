/*
* 召唤师联盟单例类
*
* 管理整个游戏的全局变量
* 管理游戏中的数据模型
*
* 2015-1-16 by 宝爷
*/
#ifndef __GAME_H__
#define __GAME_H__

#include "KxCSComm.h"
#include "BattleModels.h"
#include "EventManager.h"
#include "BattleHelper.h"

enum EPfType
{
    EDebug,     // 调试
    EQQHall,    // QQ大厅
    EAnySDK,    // anysdk
};

class CGame
{
private:
    CGame();
    virtual ~CGame();

public:
	static CGame* getInstance();

	static void destory();

	bool init();
    // 注意, 不能在事件execute时, 调用该接口(raiseEvent)两次, 这样会破坏第一次调用的内存数据, 并导致崩溃
    void sendRequest(int maincmd, int subcmd, void *data, int len);
    // 是否是调试模式
    bool isDebug(){ return m_bDebug; }
    // 平台类型
    EPfType getPfType(){ return m_nPfType; }

public:
	CPlayerModel*       User;
    CEventManager<int>* EventMgr;
    CBattleHelper*      BattleHelper;    // 临时对象
    int                 UserId;

private:
	static CGame*       m_Instance;

    bool m_bDebug;      // 调试开关
    EPfType m_nPfType;  // 平台类型
};

#endif // Game_h__
