/*
 * 动画显示组件基类
 * 1.提供动画播放相关的标准接口
 * 2.提供动画回调
 * 3.设置动画播放速度
 * 4.动画互斥
 *
 * 2014-12-23 by 宝爷
 */
#ifndef __ANIMATE_COMPONENT_H__
#define __ANIMATE_COMPONENT_H__

#include "DisplayComponent.h"

class CAnimateComponent : public CDisplayComponent
{
public:
    CAnimateComponent();
    ~CAnimateComponent();

    // 传入动画文件名，创建动画节点，在onEnter中addChild动画节点
	virtual bool initAnimate(const std::string& fileName, Node* displayNode = NULL) { return false; }

    // 传入动画ID，播放动画
    virtual bool playAnimate(int actionId, int loop = -1) { return false; }

    // 传入动画动画名，播放动画
    virtual bool playAnimate(const std::string& actionName, int loop = -1) { return false; }
    
    virtual void setCascadeColorAndOpacityEnabled(cocos2d::Node* node);

    // 设置动画播放速度
    virtual void setAnimateSpeed(float speed) {}

    virtual void pause() {}

	virtual void resume() {}

    virtual void setAlpha(int alpha) {}
    virtual void setColor(cocos2d::Color3B color) {}

    virtual void setHSV(const VecFloat &hsv){}

    virtual void setHue(const float &hue){}

	virtual void setFlipX(bool isFlipX) {}

    inline bool isMutex() { return m_bIsMutex; }

    virtual void setMutex(bool ismutex) 
    {
        m_bIsMutex = ismutex; 
        if (m_bIsMutex)
        {
            _name = "MainAnimate";
        }
        else
        {
            _name = "SubAnimate";
        }
    }

	inline void setDisplayNode(Node* displayNode)
	{
		if (NULL != displayNode)
		{
			m_DisplayNode = displayNode;
		}
	}

	inline Node* getDisplayNode()
	{
		if (NULL != m_DisplayNode)
		{
			return m_DisplayNode;
		}
		else
		{
			return _owner;
		}
	}

    inline Node* getMainAnimate()
    {
        return m_MainAnimate;
    }
protected:
    bool m_bIsMutex;        // 该动画是否互斥
    bool m_bIsFlipX;

	Node* m_DisplayNode;    // 加载在role上的需要再加一个节点, 避免放大缩小影响其他对象
    Node* m_MainAnimate;    // 主骨骼

    cocos2d::GLProgramState *m_pDefaultProgram;      // 默认shader
    cocos2d::GLProgramState *m_pStatusProgram;       // 状态shader(中毒、冰冻等效果)
};

#endif
