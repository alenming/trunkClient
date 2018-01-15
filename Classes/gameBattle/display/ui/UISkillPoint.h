
#ifndef __UI_SKILL_POINT_H__
#define __UI_SKILL_POINT_H__

#include "cocos2d.h"
#include "Hero.h"
#include "GameComm.h"

class CUISkillPointComponent : public cocos2d::Component
{
public:
    CUISkillPointComponent();
    virtual ~CUISkillPointComponent();

    virtual void onExit();
    bool init(cocos2d::Node* pointNode, CHero* hero, int index);
    void update(float dt);

private:
    int m_Index;
    bool m_Highlight;
    CHero* m_Hero;

    cocostudio::timeline::ActionTimeline* m_PointAnimation;
};

#endif
