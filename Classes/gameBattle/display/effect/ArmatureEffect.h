#ifndef __ARMATURE_EFFECT_H__
#define __ARMATURE_EFFECT_H__

#include "cocostudio/CocoStudio.h"
#include "Effect.h"

class CArmatureEffect : public CEffect
{
public:
	CArmatureEffect();
	~CArmatureEffect();

    virtual bool init(int dir, const EffectConfItem* conf);
    virtual bool init(const std::string& armature);
	virtual void onEnter();
    // 播放指定动画
    virtual bool playAnimate(const std::string& animate);
    // 播放指定动画，并在动画播放完后自动移除
    virtual bool playAnimateAutoRemove(const std::string& animate);    
    // 设置播放速度
    virtual void setAnimateSpeed(float speed)
    {
        if (NULL != m_pAnimation)
        {
            m_pAnimation->getAnimation()->setSpeedScale(speed);
        }
    }
    // 获取特效节点
    cocos2d::Node* getEffectNode() { return m_pAnimation; }

private:
    cocostudio::Armature* m_pAnimation;
};

#endif