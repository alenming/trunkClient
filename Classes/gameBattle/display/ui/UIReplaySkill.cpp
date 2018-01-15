#include "UIReplaySkill.h"
#include "Game.h"
#include "Hero.h"
#include "Skill.h"
#include "DisplayCommon.h"
#include "Events.h"
#include "ConfOther.h"
#include "ConfLanguage.h"
#include "LuaSummonerBase.h"
#include "UIEffect.h"

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;


CUIReplaySkillComponent::CUIReplaySkillComponent()
: m_CurState(SkillState::SkillInvalid)
{
}

CUIReplaySkillComponent::~CUIReplaySkillComponent()
{
}

void CUIReplaySkillComponent::onExit()
{
    CGame::getInstance()->EventMgr->removeEventHandle(this);
}

bool CUIReplaySkillComponent::init(cocos2d::Node* skillNode, CHero* hero, int index)
{
    bool ret = Component::init();
    setName("UISkillComponent");
    skillNode->scheduleUpdate();

    m_Index = index;
    m_Hero = hero;
    m_bEffectPlaying = false;
    m_Skill = m_Hero->getSkillWithIndex(m_Index);

    m_SkillAnimation = getCsbAnimation(skillNode);
    m_SkillAnimation->setLastFrameCallFunc([this]{
        m_bEffectPlaying = false;       // 标记特效播放完毕
    });

    // 初始化技能图标
    auto iconName = m_Skill->getSkillConf()->BattleSkillIcon;
    m_SkillIcon = findChild<Button>(skillNode, "FightSkillItem/SkillImage");
    m_SkillIcon->loadTextureNormal(iconName, TextureResType::PLIST);

    // 遮罩
    cocos2d::SpriteFrameCache::getInstance()->addSpriteFramesWithFile("ui_new/p_public/p_public.plist");
    m_SkillMask = ProgressTimer::create(Sprite::createWithSpriteFrameName("circle_68X68.png"));
    m_SkillMask->setType(ProgressTimer::Type::RADIAL);
    m_SkillMask->setReverseProgress(false);
    m_SkillMask->setMidpoint(Vec2(0.5f, 0.5f));
    m_SkillMask->setPosition(Vec2(35.0f, 35.0f));
    m_SkillMask->setPercentage(0);
    m_SkillMask->setVisible(false);
    m_SkillIcon->getParent()->addChild(m_SkillMask, CUIReplaySkillComponent::LZ_SKILLMASK);

    return ret;
}

void CUIReplaySkillComponent::update(float dt)
{
    SkillState state = checkSkillState();
    switch (state)
    {
    case SkillState::SkillLock:
        if (m_CurState != state)
        {
            m_bEffectPlaying = false;
            m_SkillAnimation->play("Lock", false);

            m_SkillIcon->setBright(false);
            m_SkillMask->setVisible(false);

            m_CurState = state;
        }
        break;
    case SkillState::SkillCD:
        if (m_CurState != state)
        {
            m_bEffectPlaying = false;
            m_SkillAnimation->play("Stop", false);

            m_SkillIcon->setBright(true);
            m_SkillMask->setPercentage(0.0f);
            m_SkillMask->setVisible(true);
            m_SkillMask->setReverseDirection(true);

            m_CurState = state;
        }
        m_SkillMask->setPercentage((1.0f - m_Skill->getCDPercent()) * 100.0f);
        break;
    case SkillState::SkillNormal:
        // 从锁状态跳转到正常状态: 播放解锁动画
        if (m_CurState == SkillState::SkillLock)
        {
            auto delay = cocos2d::DelayTime::create(0.75f);
            auto callback = cocos2d::CallFunc::create([this]()
            {
                m_SkillIcon->setBright(true);
                if (m_Hero->getBattleHelper()->getBattleType() != EBATTLE_GUIDE)
                {
                    playEffect("Unlock");
                    playSoundEffect(46);
                }
            });
            auto sequence = cocos2d::Sequence::create(delay, callback, nullptr);
            this->getOwner()->runAction(sequence);

            m_SkillMask->setVisible(false);
            m_CurState = state;
            m_bEffectPlaying = true;
        }
        else if(!m_bEffectPlaying)
        {
            if (m_CurState != state)
            {
                m_SkillIcon->setBright(true);
                m_SkillMask->setVisible(false);

                m_CurState = state;
            }
            playEffect("Normal", true);
        }

        break;
    case SkillState::SkillLack:
        if (m_CurState != state)
        {
            // 从CD状态跳转到水晶不足状态: 播放加载完成动画
            if (m_CurState == SkillState::SkillCD)
            {
                playEffect("LoadOver");
            }

            m_SkillIcon->setBright(true);
            m_SkillMask->setVisible(false);
            
            m_CurState = state;
        }
        break;
    case SkillState::SkillExecuting:
        if (m_CurState != state)
        {
            m_bEffectPlaying = false;
            m_SkillAnimation->play("Stop", false);

            m_SkillIcon->setBright(true);
            m_SkillMask->setPercentage(0.0f);
            m_SkillMask->setVisible(true);
            m_SkillMask->setReverseDirection(false);
            
            m_CurState = state;
        }
        m_SkillMask->setPercentage(m_Hero->getCommonCDPercent() * 100.0f);
        break;
    default:
        break;
    }
}

void CUIReplaySkillComponent::playEffect(const char* effName, bool loop /*=false*/)
{
    m_bEffectPlaying = true;
    m_SkillAnimation->play(effName, loop);
}

CUIReplaySkillComponent::SkillState CUIReplaySkillComponent::checkSkillState()
{
    if (m_Skill->isLock())
    {
        return SkillState::SkillLock;
    }
    else if (!m_Skill->isFinish() || (!m_Skill->isLock() && m_Hero->isCommonCD()))
    {
        // 技能正在释放
        return SkillState::SkillExecuting;
    }
    else if (m_Skill->getCDPercent() < 1.0f)
    {
        // 技能正在CD
        return SkillState::SkillCD;
    }
    else if (!m_Hero->canUseCrystal(m_Skill->getSkillConf()->CostTypeParam))
    {
        // 技能消耗不足
        return SkillState::SkillLack;
    }
    else
    {
        // 正常状态
        return SkillState::SkillNormal;
    }
}
