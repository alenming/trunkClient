/*
*   战斗界面主UI
*   1. 初始化战斗界面的所有模块（技能、水晶、卡片、动作提示栏）
*   2. 实现战斗倒计时功能
*   3. 实现战斗暂停、退出UI
*   4. 实现TIPS提示功能
*
*   2015-12-23 by 宝爷
*/
#ifndef __UI_BATTLE_MAIN_H__
#define __UI_BATTLE_MAIN_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "GameComm.h"
#include "UIActionTipsBar.h"

class CUIBattleMain : public cocos2d::Layer
{
public:
    CUIBattleMain();
    virtual ~CUIBattleMain();

    virtual bool init();
    virtual void update(float delta);
    virtual void onEnter();
    virtual void onExit();

    void setAllTouchEnabled(bool enabled);

    void onShowTip(void* data);
    void onShowSkillMark(void* data);
    void onHideSkillMark(void* data);
    void onShowReleaseSkill(void* data);
    void onShowCancelSkill(void* data);
    void onFightStart(void* data);
    void onCrystalUpgrade(void* data);
private:
    void showTips(const char* tips, float delay = 2.0f);
    void updateTime();
    void updateHurt();
    void updateDeath();
    void playDownTimeEffect(int time);
    // 切换背景氛围
    void changeBackgroudMood();
    bool checkMoodCondition(const VecVecInt& conditionList);
    bool timeCondition(float time);
    bool soilderCondition(int count);
    bool crystalCondition(int level);

	void onBtnAdd(Ref* object);
	void onBtnMinus(Ref* object);
	void onBtnSpeed(Ref* object);
private:
    bool m_bUnDoDeathCamera;
    int m_nDownTime;
    int m_nHurt;
    int m_nSkillIndex;
	float m_nSpeed;
    float m_fMoodParam;

    CUIActionTipsBar* m_ActionTipsBar;
    cocostudio::timeline::ActionTimeline* m_TimeAct;
	cocos2d::Node* m_BattleUI;
	cocos2d::Node* m_SkillTip;
	cocos2d::Node* m_Tips;
	cocos2d::Node* m_DownTimeNode;
	cocos2d::Node* m_HurtNode;
    cocos2d::ui::Text* m_TimeText;
    cocos2d::ui::TextAtlas* m_DownTimeText;
    cocos2d::ui::TextAtlas* m_HurtText;
    CBattleHelper* m_Helper;

    cocos2d::Node* m_NodeBazier;
    cocostudio::timeline::ActionTimeline* m_ActionBazier;
    cocos2d::Vec2 m_OldPosition;
    std::map<int, cocos2d::Vec2> m_mapPosition;  // 水晶升级的粒子移动目标

	cocos2d::ui::Button* m_ScaleAddButton;
	cocos2d::ui::Button* m_ScaleMinusButton;
	cocos2d::ui::Button* m_SpeedButton;

///////////////////////////////序列化,反序列化测试///////////////////////////////////////////
private:
	//模拟测试英雄和角色的序列化,反序列化
	void showSerializeInfo();
	void serializeMenuCallback(Ref* ref);
	void unSerializeMenuCallback(Ref* ref);
private:
	CBufferData* m_SerializeBuffData;
	CBufferData* m_unSerializeBuffData;
///////////////////////////////序列化,反序列化测试///////////////////////////////////////////
};

#endif