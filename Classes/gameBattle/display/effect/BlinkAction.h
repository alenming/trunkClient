/*
*   闪烁效果（传入颜色和时间，通过shader自动闪烁）
*
*   2015-12-9 By 宝爷
*/

#ifndef __BLINK_ACTION__
#define __BLINK_ACTION__

#include "cocos2d.h"

class BlinkAction : public cocos2d::ActionInterval
{
public:
    BlinkAction();
    virtual ~BlinkAction();

    static BlinkAction* create(cocos2d::Node* node, cocos2d::Color3B color, float time = 0.15f);

    virtual bool initWithDuration(cocos2d::Node* node, cocos2d::Color3B color, float d);

    virtual void startWithTarget(cocos2d::Node *target) override;

    virtual void update(float time) override;

    virtual void fourceStop();

    inline cocos2d::GLProgramState* getProgramState()
    {
        return m_OldProgramState;
    }

private:
    cocos2d::Color3B m_Color;
    cocos2d::Color3B m_OldColor;
    cocos2d::GLProgramState* m_OldProgramState;
    cocos2d::Node* m_Target;
};

#endif
