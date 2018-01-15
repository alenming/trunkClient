/*
*   英雄技能UI
*   1. 绑定UI以及对应的模型，并初始化（图标、状态、消耗）
*   2. 实现CD、常态、水晶不足、持续释放等状态的切换
*
*   2015-12-25 by 宝爷
*/
#ifndef __UI_REPLAYSKILL_H__
#define __UI_REPLAYSKILL_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameComm.h"
#include "Hero.h"
#include "Skill.h"

class CUIReplaySkillComponent : public cocos2d::Component
{
public:
    CUIReplaySkillComponent();
    virtual ~CUIReplaySkillComponent();

    virtual void onExit();
    bool init(cocos2d::Node* skillNode, CHero* hero, int index);
    void update(float dt);
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
    SkillState checkSkillState();

private:
    int  m_Index;
    bool m_bEffectPlaying;

    CHero* m_Hero;
    CSkill* m_Skill;
    SkillState m_CurState;

    cocos2d::ui::Button*    m_SkillIcon;
    cocos2d::ProgressTimer* m_SkillMask;
    cocostudio::timeline::ActionTimeline* m_SkillAnimation;
};

#endif
