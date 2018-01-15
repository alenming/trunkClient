#include "BulletDisplayComponent.h"
#include "BulletComponent.h"
#include "ArmatureComponent.h"
#include "ConfManager.h"
#include "Bullet.h"
#include "EffectFactory.h"
#include "UIEffect.h"
#include "ConfFight.h"

#define ROTATE_ACTION_TAG   88888

CBulletDisplayComponent::CBulletDisplayComponent()
: m_bIsOver(false)
, m_bIsFirstRotate(true)
, m_nState(BST_NONE)
, m_Offset(Vec2::ZERO)
, m_pOwner(NULL)
, m_pBulletComponent(NULL)
, m_pBulletConf(NULL)
{
    _name = "BulletDisplayComponent";
}

CBulletDisplayComponent::~CBulletDisplayComponent()
{
}

bool CBulletDisplayComponent::init(CBullet *bullet, CBulletComponent *logicCom)
{
    if (NULL == bullet || NULL == logicCom)
    {
        return false;
    }

    m_pOwner = bullet;
    m_pBulletComponent = logicCom;
    m_nState = BST_NONE;
    m_pBulletConf = bullet->getBulletConf();
    m_CurTargetPos = m_pOwner->getRealPosition();

    return true;
}

void CBulletDisplayComponent::update(float dt)
{
    if (m_pOwner->getState() != m_nState)
    {
        m_nState = m_pOwner->getState();
        displayAnimation(m_nState);
    }

    if (!m_pBulletConf->LockDirect)
    {
        //方向锁定与否逻辑处理
        Vec2 dir = m_pOwner->getRealPosition() - m_pOwner->getPrevPosition();
        if (m_Direction != dir && !dir.equals(Vec2::ZERO))
        {
            m_Direction = dir;
            // 移动方向归一化
            float unit = fastInvSqrt(dir.x * dir.x + dir.y * dir.y);
            dir.x *= unit;
            dir.y *= unit;
            // 求出该方向的角度
            float ro = asinf(dir.y) * RadianToDegree * m_pOwner->getDirection();

            if (m_bIsFirstRotate)
            {
                m_bIsFirstRotate = false;
                m_pOwner->setRotation(-ro);
            }
            else
            {
                m_pOwner->stopActionByTag(ROTATE_ACTION_TAG);
                auto act = RotateTo::create(0.1f, -ro);
                act->setTag(ROTATE_ACTION_TAG);
                m_pOwner->runAction(act);
            }
        }
    }

    if (m_pOwner->getState() == BST_FLYING)
    {
        // 逻辑位置发生变化，更新位置
        if (m_CurTargetPos != m_pOwner->getRealPosition())
        {
            m_CurTargetPos = m_pOwner->getRealPosition();
            m_Offset = m_CurTargetPos - m_pOwner->getPosition();
        }
        
        if (m_Offset != Vec2::ZERO)
        {
            dt = dt / dynamic_cast<CBattleLayer*>(m_pOwner->getParent())->getTickDelta();
            Vec2 newPos = m_pOwner->getPosition() + m_Offset * dt;
            if ((m_Offset.x > 0 && newPos.x > m_CurTargetPos.x)
                || (m_Offset.x < 0 && newPos.x < m_CurTargetPos.x))
            {
                newPos.x = m_CurTargetPos.x;
            }
            if ((m_Offset.y > 0 && newPos.y > m_CurTargetPos.y)
                || (m_Offset.y < 0 && newPos.y < m_CurTargetPos.y))
            {
                newPos.y = m_CurTargetPos.y;
            }
            m_pOwner->setPosition(newPos);
        }
    }
}

bool CBulletDisplayComponent::isDisplayOver()
{
    return true;
}

void CBulletDisplayComponent::displayAnimation(int state)
{
    m_pOwner->removeAllChildren();
    if (state == BST_FLYING)
    {
        CEffectFactory::createEffectsToNode(m_pBulletConf->AnimationId,
            m_pOwner, m_pOwner->getDirection());
    }
    else
    {
        // 结束动画交由场景控制
        CEffectFactory::createEffectsToNode(m_pOwner->getBulletConf()->EndAnimationId,
            m_pOwner->getBattleHelper()->getBattleScene(),
            m_pOwner->getDirection(), m_pOwner->getLocalZOrder(), 0.0f, m_pOwner->getRealPosition());
    }

	//添加UI特效
	CUIEffectManager::getInstance()->execute(m_pBulletConf->UiEffectId, m_pOwner->getPosition());
}
