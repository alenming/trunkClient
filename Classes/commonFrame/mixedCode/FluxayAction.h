/*
*   流光效果，通过shader实现颜色流动的效果
*
*   2016-5-16 By 宝爷
*/
#ifndef __FLUXAYACTION_H__
#define __FLUXAYACTION_H__

#include "cocos2d.h"

class CFluxayAction : public cocos2d::ActionInterval
{
public:
    CFluxayAction();
    virtual ~CFluxayAction();

    static CFluxayAction* create();

    virtual void startWithTarget(cocos2d::Node *target) override;

    virtual void step(float dt) override;

    virtual void fourceStop();

    virtual bool isDone() const { return false; }
    
    inline cocos2d::GLProgramState* getProgramState()
    {
        return m_OldProgramState;
    }

private:
    float m_fModTime;
    cocos2d::GLProgramState* m_FluxayProgramState;
    cocos2d::GLProgramState* m_OldProgramState;
    cocos2d::Node* m_Target;
};

#endif