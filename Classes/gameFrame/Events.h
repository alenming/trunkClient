/*
* 公共事件消息头文件
* 定义所有EventManager转发的消息ID
* 网络相关的消息根据协议消息ID定义
*
* 2015-2-7 By 宝爷
*/
#ifndef __EVENTS_H__
#define __EVENTS_H__

enum EventsType
{
    LoginEvents = 0,                // 登录流程中的事件

    MainEvents = 100,               // 主界面中的事件

    BattleEvents = 200,             // 战斗界面中的事件
    BattleEventTouchReleaseSkill,   // 点击将释放技能
    BattleEventTouchCancelSkill,    // 取消释放技能
	BattleEventTouchPlaySkill,      // 成功释放技能
    BattleEventShowTips,            // 相关提示信息
	BattleEventEnemyActionTips,		// 对方派兵,释放技能提示
    BattleEventTouchReleaseTips,    // 释放技能提示
    BattleEventTouchCancelTips,     // 取消技能提示
    BattleEventFightStartTips,      // 战斗开始提示
    BattleEventCrystalUpgrade,      // 水晶升级事件

    BattleEventTalkCommand,         // pvp 调戏

    BattleEventDispatchHero,        // 派遣英雄

};

#endif