#include "UISkillPoint.h"
#include "Game.h"
#include "Hero.h"
#include "DisplayCommon.h"

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;


CUISkillPointComponent::CUISkillPointComponent()
    :m_Highlight(false)
{
}

CUISkillPointComponent::~CUISkillPointComponent()
{
}

void CUISkillPointComponent::onExit()
{
    CGame::getInstance()->EventMgr->removeEventHandle(this);
}

bool CUISkillPointComponent::init(cocos2d::Node* pointNode, CHero* hero, int index)
{
    bool ret = Component::init();
    setName("CUISkillPointComponent");
    pointNode->scheduleUpdate();
    m_PointAnimation = getCsbAnimation(pointNode);
    m_PointAnimation->play("Off", false);

    m_Index = index;
    m_Hero = hero;

    return ret;
}

void CUISkillPointComponent::update(float dt)
{
    int crystalLevel = m_Hero->getIntAttribute(EHeroCrystalLevel);
    if (crystalLevel >= m_Index * 2 + 1)
    {
        if (!m_Highlight)
        {
            m_Highlight = true;
            auto delay = cocos2d::DelayTime::create(0.75f);
            auto callback = cocos2d::CallFunc::create([this]()
            {
                m_PointAnimation->play("On", false);
                if (m_Hero->getBattleHelper()->getBattleType() != EBATTLE_GUIDE)
                {
                    playSoundEffect(32);
                }
            });
            auto sequence = cocos2d::Sequence::create(delay, callback, nullptr);
            this->getOwner()->runAction(sequence);
        }
    }
}