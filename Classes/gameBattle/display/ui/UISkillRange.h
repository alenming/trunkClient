/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-05-19 17:03
** 版  本:	1.0
** 描  述:  技能的释放范围, 跟CBattleLayer一起缩放，跟CBattleDragLayer一起移动
** 应  用:
********************************************************************/
#ifndef __UI_SKILL_RANGE_H__
#define __UI_SKILL_RANGE_H__

#include "cocos2d.h"

class CUISkillRange : public cocos2d::Node
{
public:
    CUISkillRange();
    virtual ~CUISkillRange();

    virtual bool init();
    virtual void onEnter();
    virtual void onExit();

    void playAni(std::string aniName, bool loop, std::function<void()> func);
    float getSkillRidius();

    CREATE_FUNC(CUISkillRange);
private:
    cocos2d::Node* m_SkillRange;
    cocostudio::timeline::ActionTimeline* m_SkillRangeAct;
};

#endif // !__UI_SKILL_RANGE_H__