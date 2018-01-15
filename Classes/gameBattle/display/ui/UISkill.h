/*
*   英雄技能UI
*   1. 绑定UI以及对应的模型，并初始化（图标、状态、消耗）
*   2. 实现CD、常态、水晶不足、持续释放等状态的切换
*
*   2015-12-25 by 宝爷
*/
#ifndef __UI_SKILL_H__
#define __UI_SKILL_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameComm.h"
#include "Hero.h"
#include "Skill.h"

class CUISkillComponent : public cocos2d::Component
{
public:
    CUISkillComponent();
    virtual ~CUISkillComponent();

    virtual void onExit();
    bool init(cocos2d::Node* skillNode, CHero* hero, int index);
    void update(float dt);
	void touchCallBack(Ref* psender, cocos2d::ui::Widget::TouchEventType type);
private:
    enum SkillState {
        SkillInvalid,
        SkillLock,
        SkillCD,
        SkillNormal,
        SkillLack,
        SkillExecuting,
    };

    enum LayerZorder
    {
        LZ_SKILLMASK   = 7,			// 执行遮罩层
    };

    void playEffect(const char* effName, bool loop = false);
    void onClick(cocos2d::Ref* object);
    SkillState checkSkillState();

    // 取消释放技能
    void onSkillCancel(void* data);
    // 成功释放技能
    void onSkillPlay(void* data);

private:
    int  m_Index;
	int  m_iTouchingTime;
    bool m_bEffectPlaying;
    bool m_bWaitForClick;
	bool m_bTouching;

    CHero* m_Hero;
    CSkill* m_Skill;
    SkillState m_CurState;

    cocos2d::ui::Button*    m_SkillIcon;
	cocos2d::ui::Button*	m_bButton;
    cocos2d::ProgressTimer* m_SkillMask;
    cocostudio::timeline::ActionTimeline* m_SkillAnimation;
};

#endif
