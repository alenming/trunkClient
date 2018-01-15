#ifndef __SPINE_EFFECT_H__
#define __SPINE_EFFECT_H__

#include "spine/spine-cocos2dx.h"
#include "Effect.h"

class CSpineEffect : public CEffect
{
public:
	CSpineEffect();
	~CSpineEffect();
    bool init(const std::string& fileName);
    bool init(int dir, const EffectConfItem* conf, const std::string& fileName);
	virtual void onEnter();
    virtual void onExit();
    // 播放指定动画
    virtual bool playAnimate(const std::string& animate);
    // 播放指定动画，并在动画播放完后自动移除
    virtual bool playAnimateAutoRemove(const std::string& animate);
    // 设置播放速度
    virtual void setAnimateSpeed(float speed)
    {
        if (NULL != m_pAnimation)
        {
            m_pAnimation->setTimeScale(speed);
        }
    }
    // 获取特效节点
    cocos2d::Node* getEffectNode() { return m_pAnimation; }

private:
    std::string m_FileName;
    spine::SkeletonAnimation* m_pAnimation;
};

#endif