/*
*   回放战斗界面主UI
*   1. 初始化战斗界面的所有模块（技能、水晶、卡片、动作提示栏）
*   2. 实现战斗倒计时功能
*   3. 实现战斗暂停、退出UI
*   4. 实现TIPS提示功能
*
*   2017-2-21 by wsy copy 宝爷
*/
#ifndef __UI_REPLAYBATTLE_MAIN_H__
#define __UI_REPLAYBATTLE_MAIN_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "GameComm.h"
#include "UIActionTipsBar.h"

class CUIReplayBattleMain : public cocos2d::Layer
{
public:
    CUIReplayBattleMain();
    virtual ~CUIReplayBattleMain();

    virtual bool init();
    virtual void update(float delta);
    virtual void onEnter();
    virtual void onExit();

    void onShowTip(void* data);
    void onFightStart(void* data);

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

    // 设置召唤师英雄卡片UI信息
    void setSummonerHeroInfo(bool isLeft);

    void test();
    void hero(Ref* ref);
    void skill(Ref* ref);
    void crystal(Ref* ref);

private:
    bool m_bUnDoDeathCamera;
    int m_nDownTime;
    int m_nHurt;
	float m_nSpeed;
    float m_fMoodParam;

    CUIActionTipsBar* m_ActionTipsBar;
    cocostudio::timeline::ActionTimeline* m_TimeAct;
    cocostudio::timeline::ActionTimeline* m_BattleAct;
    cocostudio::timeline::ActionTimeline* m_SpeedBtnAct;
	cocos2d::Node* m_BattleUI;
	cocos2d::Node* m_SkillTip;
	cocos2d::Node* m_Tips;
	cocos2d::Node* m_DownTimeNode;
	cocos2d::Node* m_HurtNode;
    cocos2d::ui::Text* m_TimeText;
    cocos2d::ui::TextAtlas* m_DownTimeText;
    cocos2d::ui::TextAtlas* m_HurtText;
    CBattleHelper* m_Helper;

	cocos2d::ui::Button* m_ScaleAddButton;
	cocos2d::ui::Button* m_ScaleMinusButton;
	cocos2d::ui::Button* m_SpeedButton;
};

#endif