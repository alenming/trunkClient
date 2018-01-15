/*
* 骨骼动画显示组件
*
* 2014-12-23 by 宝爷
*/
#ifndef __ARMATURE_COMPONENT_H__
#define __ARMATURE_COMPONENT_H__

#include "AnimateComponent.h"
#include "cocostudio/CocoStudio.h"

class CArmatureComponent : public CAnimateComponent
{
public:
    CArmatureComponent();
    virtual ~CArmatureComponent();

    // 传入动画文件名，创建动画节点，在onEnter中addChild动画节点
	virtual bool initAnimate(const std::string& fileName, Node* displayNode = NULL);

    // 传入动画ID，播放动画
    // loop 为-1表示使用动画文件内部数据播放，0表示播放一次，大于0表示循环N次
    virtual bool playAnimate(const std::string& actionName, int loop = -1);

    // 设置动画播放速度
    virtual void setAnimateSpeed(float speed);

    virtual void onEnter();

    virtual void onExit();

    virtual void pause();

    virtual void resume();

    virtual void setAlpha(int alpha)
    {
        if (NULL != m_Armature)
        {
            m_Armature->setOpacity(alpha);
        }
    }

    virtual void setColor(cocos2d::Color3B color)
    {
        if (NULL != m_Armature)
        {
            m_Armature->setColor(color);
        }
    }

    virtual void setMainDisplay(bool isMain)
    {
        if (isMain)
        {
            m_Armature->setTag(MAIN_DISPLAY);
        }
        else
        {
            m_Armature->setTag(-1);
        }
    }

	virtual void setFlipX(bool isFlipX)
	{
        if (m_bIsFlipX != isFlipX)
        {
            m_bIsFlipX = isFlipX;
            // 2dx 的奇葩写法
            m_Armature->setScaleX(isFlipX ? -1 : 1 * std::abs(m_Armature->getScaleX()));
        }
	}

    cocostudio::Armature* getArmature()
    {
        return m_Armature;
    }

private:
    cocostudio::Armature* m_Armature;
};

#endif
