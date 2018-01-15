/*
* 子弹显示组件
*
* 2014-12-23 by 宝爷
*/
#ifndef __BULLET_DISPLAY_COMPONENT_H__
#define __BULLET_DISPLAY_COMPONENT_H__

#include "DisplayComponent.h"

class CGameObject;
class CBullet;
class BulletConfItem;
class CArmatureComponent;
class CBulletComponent;
class CBulletDisplayComponent : public CDisplayComponent
{
public:
    CBulletDisplayComponent();
    virtual ~CBulletDisplayComponent();

public:
    //初始化
    bool init(CBullet *bullet, CBulletComponent *logicCom);
    //
    void update(float dt);
    //是否显示结束
    bool isDisplayOver();
    //播放自身, 飞行及飞行结束
    void displayAnimation(int state);

private:
    bool                    m_bIsOver;
    bool                    m_bIsFirstRotate;
    int                     m_nState;
    Vec2                    m_Direction;
    Vec2                    m_Offset;
    Vec2                    m_CurTargetPos;
    CBullet*                m_pOwner;
    CBulletComponent*       m_pBulletComponent;
    const BulletConfItem*   m_pBulletConf;
};

#endif
