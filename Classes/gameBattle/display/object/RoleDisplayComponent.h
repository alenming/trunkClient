/*
* 角色显示组件
* 根据Owner的位置来平滑显示位置
* 根据状态来播放指定动画
*
* 2014-12-23 by 宝爷
*/
#ifndef __ROLE_DISPLAY_COMPONENT_H__
#define __ROLE_DISPLAY_COMPONENT_H__

#include "DisplayComponent.h"
#include "ArmatureComponent.h"
#include "RoleComponent.h"
#include "Role.h"
#include "HPBar.h"
#include "Count.h"
#include "Effect.h"

#define DEATH_ACT_TAG 100001

class CRoleDisplayComponent : public CDisplayComponent
{
public:
    CRoleDisplayComponent();
    virtual ~CRoleDisplayComponent();

    virtual bool init(CRole* role, CAnimateComponent* animate, CRoleComponent* state);

    virtual void update(float delta);

    // 切换动画播放
    void changeAnimate();
    // 获取骨骼动画对象
    Node* getMainAnimate();
    // 刷新血条，并弹出伤害文本，执行闪红闪白逻辑
    void playCountEffect(eHurtType hurtType, int hurtValue);
	CHPBar* getHPBar(){ return m_pHpBar; }
    // 刷新血条
    void updateHpBar();
    // 初始化debug测试相关
    void initDebug();

private:
    // 初始化血条
    void initHpBar();
    // 创建特效
    // 本地创建并保存方便管理
    bool createEffects(Node* root, const VecInt& effIds, int zorder = 0, float delay = 0.0f, cocos2d::Vec2 pos = Vec2::ZERO);
    // 移除上一次的特效
    void removePreEffects();
    // 移除上一次的音效（循环）
    void stopPreMusics();
    // 获取当前播放速度
    float getCurPlaySpeed();

private:
    Vec2 m_Offset;
    Vec2 m_TargetPos;
    Vec2 m_HpBarOffset;
    int m_nState;
    int m_nAnimateId;
    float m_fDuration;
    float m_fDelta;
    float m_PlaySpeed;
	CHPBar* m_pHpBar;
    CRoleComponent* m_pRoleCom;
	CAnimateComponent* m_pArmatureCom;
    CRole* m_pRole;
	std::vector<CEffect*> m_vEffectNode;
    std::vector<int> m_vMusics;
};

#endif
