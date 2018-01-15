#ifndef __SPINECOMPONENT_H__
#define __SPINECOMPONENT_H__

#include "AnimateComponent.h"
#include <spine/spine-cocos2dx.h>

class CSpineComponent :
	public CAnimateComponent
{
public:
	CSpineComponent();
	virtual ~CSpineComponent();

	// 传入动画文件名，创建动画节点，在onEnter中addChild动画节点
	virtual bool initAnimate(const std::string& fileName, Node* displayNode = NULL);

	// 传入动画动画名，播放动画
	virtual bool playAnimate(const std::string& actionName, int loop = -1);

	// 设置动画播放速度
	virtual void setAnimateSpeed(float speed);

	virtual void pause();

	virtual void resume();

    virtual void setAlpha(int alpha)
    {
        if (NULL != m_pSkeletonAnimation)
        {
            m_pSkeletonAnimation->setOpacity(alpha);
        }
    }

    virtual void setColor(cocos2d::Color3B color)
    {
        if (NULL != m_pSkeletonAnimation)
        {
            m_pSkeletonAnimation->setColor(color);
        }
    }

	virtual void onEnter();

	virtual void onExit();

	virtual void setFlipX(bool isFlipX);

	spine::SkeletonAnimation *getSkeletonAnimation()
	{
		return m_pSkeletonAnimation;
	}

    // 创建的时候默认
    virtual void setHSV(const VecFloat &hsv);

    // 状态切换时调用
    virtual void setHue(const float &hue);

private:
    std::string m_FileName;
	spine::SkeletonAnimation *m_pSkeletonAnimation;
};

#endif
