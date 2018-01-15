#include "ArmatureEffect.h"
#include "ConfOther.h"

USING_NS_CC;
using namespace cocostudio;

// 将Armature骨骼对象中的粒子调整为相对运动模式
void updateParticle(Armature* node)
{
	for (auto& boneItem : node->getBoneDic())
	{
		auto& bone = boneItem.second;
		if (bone->getDisplayRenderNodeType() == CS_DISPLAY_PARTICLE)
		{
			auto particle = dynamic_cast<ParticleSystem*>(bone->getDisplayRenderNode());
			if (nullptr != particle)
			{
				particle->setPositionType(ParticleSystem::PositionType::RELATIVE);
			}
		}
	}
}

// 调整Armature骨骼对象的全局ZOrder
void updateArmatureGrobleZOrder(Armature* node, float zorder)
{
    for (auto& n : node->getBoneDic())
    {
        // 遍历所有骨骼的DisplayManager
        Bone* bone = n.second;
        if (nullptr != bone && nullptr != bone->getDisplayManager())
        {
            // 遍历所有DisplayManager的DecorativeDisplayList
            auto& l = bone->getDisplayManager()->getDecorativeDisplayList();
            for (auto ln : l)
            {
                // 依次设置其GlobalZOrder
                ln->getDisplay()->setGlobalZOrder(zorder);
            }
        }
    }
}

CArmatureEffect::CArmatureEffect()
: m_pAnimation(NULL)
{
}

CArmatureEffect::~CArmatureEffect()
{
}

bool CArmatureEffect::init(const std::string& armature)
{
    CHECK_RETURN(CEffect::init());
	m_pAnimation = Armature::create(armature);
    CHECK_RETURN(m_pAnimation);
    addChild(m_pAnimation);
    return true;
}

bool CArmatureEffect::init(int dir, const EffectConfItem* conf)
{
    CHECK_RETURN(CEffect::init(dir, conf));

	auto confResPaht = queryConfSResInfo(m_pConf->ResID);
	CHECK_RETURN(confResPaht);
	m_pAnimation = Armature::create(confResPaht->ResName);
    CHECK_RETURN(m_pAnimation);
    addChild(m_pAnimation);

	// 检查动画
    auto animation = m_pAnimation->getAnimation()->getAnimationData()->getMovement(m_pConf->AnimationName);
	CHECK_RETURN(NULL != animation);

	// 如果动画不循环且有淡出，动画播放完成后淡出
	if (m_pConf->Loop == 0
		|| (!animation->loop && m_pConf->Loop < 0))
	{
        m_pAnimation->getAnimation()->setMovementEventCallFunc(
			[this](Armature* armature, MovementEventType movementType, const std::string movementId)->void
		{
			if (movementType == COMPLETE)
			{
				runAction(Sequence::create(FadeOut::create(m_pConf->FadeOutTime),
					RemoveSelf::create(true),
					NULL));
			}
		});
	}

    m_pAnimation->getAnimation()->setSpeedScale(m_pConf->AnimationSpeed);

	// 递归遍历粒子
    updateParticle(m_pAnimation);
	return true;
}

void CArmatureEffect::onEnter()
{
	CEffect::onEnter();
    if (m_pConf)
    {
        // 播放动画
        m_pAnimation->getAnimation()->play(m_pConf->AnimationName, -1, m_pConf->Loop);
    }
}

// 播放指定动画
bool CArmatureEffect::playAnimate(const std::string& animate)
{
    CHECK_RETURN(m_pAnimation);
    // 检查动画
    auto animation = m_pAnimation->getAnimation()->getAnimationData()->getMovement(animate);
    CHECK_RETURN(NULL != animation);
    m_pAnimation->getAnimation()->play(animate);
    return true;
}

// 播放指定动画，并在动画播放完后自动移除
bool CArmatureEffect::playAnimateAutoRemove(const std::string& animate)
{
    if (playAnimate(animate))
    {
        m_pAnimation->getAnimation()->setMovementEventCallFunc(
            [this](Armature* armature, MovementEventType movementType, const std::string movementId)->void
        {
            if (movementType == COMPLETE)
            {
                removeFromParent();
            }
        });
        return true;
    }
    return false;
}