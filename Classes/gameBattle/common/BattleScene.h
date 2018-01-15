/*
 * 战斗场景
 * 
 * 1.获取外部的数据，用户信息，房间信息等等
 * 2.在客户端加载战斗场景显示内容，并初始化
 * 3.创建BattleHelper，EventManager等一系列对象，并初始化
 * 4.战斗指令的驱动
 *
 * 2014-12-18 By 宝爷
 */
#ifndef __BATTLE_SCENE_H__
#define __BATTLE_SCENE_H__

#include "KxCSComm.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameObject.h"

class CBattleHelper;
class CPVPSerialize;

class CBattleLayer : public Layer
{
public:
    CBattleLayer();
    virtual ~CBattleLayer();

public:
    // 创建场景
    static Scene* createNewScene(CRoomModel* room);
    // 创建回放/重播场景
    static Scene* createReplayScene(CRoomModel* room);

    // 初始化
    virtual bool init(CRoomModel* room);
    // 场景开始
    virtual void onEnter();
    // 场景退出
    virtual void onExit();
    // 逻辑迭代
    virtual void update(float delta);

    // 战斗事件响应
    void onResponse(void* data);
	// 关卡挑战网络事件回调
	void onStageResponse(void *data);

    // 设置每秒多少逻辑帧
    inline void setTickSpeed(int tick) { m_fTickDelta = 1.0 / tick; }
    // 当前每帧延迟
    inline float getTickDelta() { return m_fTickDelta; }
    CRoomModel* getRoomModel() { return m_pRoomModel; }

    void pauseBattle(bool isPauseAction = true);
    void resumeBattle();
    void quitBattle();

    void doReady();
    bool replayAgain();
private:
    // 游戏逻辑迭代
    bool logicUpdate(float delta);
    // 帧数信息
    void openDebugInfo();
    void showDebugInfo();

private:
	bool			m_bIsPauseAction;     // 是否暂停动画
    bool            m_bIsPause;           // 是否暂停战斗
    float           m_fDelta;             // 上次执行逻辑到现在所逝去的时间
    float           m_fTickDelta;         // 每逻辑帧所需延迟
    CBattleHelper*  m_pBattle;            // battlehelper
	CRoomModel*     m_pRoomModel;         // 房间模型
	CPVPSerialize*  m_pPVPSerialize;	  // pvp命令处理
};

#endif
