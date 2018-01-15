/*
*   特效基类
*   抽象特效的通用接口
*
*   2015-12-17 By 宝爷
*/
#ifndef __EFFECT_H__
#define __EFFECT_H__

#include "cocos2d.h"
#include "ConfFight.h"

typedef std::function<void()> EffectFinishCallback;

class CEffect : public cocos2d::Node
{
public:
    CEffect();
    virtual ~CEffect();

    virtual bool init();
    virtual bool init(int dir, const EffectConfItem* conf);
    virtual void onEnter();
    virtual void onExit();

    // 播放指定动画
    virtual bool playAnimate(const std::string& animate) { return false; };
    // 播放指定动画，并在动画播放完后自动移除
    virtual bool playAnimateAutoRemove(const std::string& animate) { return false; };
    // 设置播放速度
    virtual void setAnimateSpeed(float speed) { }

    inline const EffectConfItem* getConf()
    {
        return m_pConf;
    }

    // 获取特效节点
    virtual cocos2d::Node* getEffectNode() { return NULL; }

protected:
    int m_nDirection;
    const EffectConfItem* m_pConf;
};

#endif