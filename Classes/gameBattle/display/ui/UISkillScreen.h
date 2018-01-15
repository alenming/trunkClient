/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-05-20 11:03
** 版  本:	1.0
** 描  述:  提示选点释放技能的闪屏
** 应  用:
********************************************************************/
#ifndef __UI_SKILL_SCREEN_H__
#define __UI_SKILL_SCREEN_H__

#include "cocos2d.h"

class CUISkillScreen : public cocos2d::Layer
{
public:
    CUISkillScreen();
    virtual ~CUISkillScreen();

    virtual bool init();
    virtual void onEnter();
    virtual void onExit();

    CREATE_FUNC(CUISkillScreen);

private:
    cocos2d::Node* m_SkillScreen;
};

#endif // !__UI_SKILL_SCREEN_H__