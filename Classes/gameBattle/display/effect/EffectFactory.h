/*
* 游戏中的特效工厂类
*
* 1.根据特效ID创建特效对象
* 2.添加到场景中可自己管理自己
* 3.如果要设置位置，请在addChild调用之前设置
*
* 2015-1-28 by 宝爷
*/
#ifndef __EFFECT_FACTORY_H__
#define __EFFECT_FACTORY_H__

#include "cocos2d.h"
#include "KxCSComm.h"
#include "Effect.h"

class CEffectFactory
{
public:
    CEffectFactory();
    virtual ~CEffectFactory();

    // 批量添加特效到parent节点
    static bool createEffectsToNode(const VecInt& effIds,
        cocos2d::Node* parent, int dir = 1, int zorder = 0, float delay = 0.0f, cocos2d::Vec2 pos = Vec2::ZERO);
    // 创建一个特效
    static CEffect* create(int effId, int dir = 1, int zorder = 0, float delay = 0.0f);
	static CEffect* createEffect(int resID);
};

#endif
