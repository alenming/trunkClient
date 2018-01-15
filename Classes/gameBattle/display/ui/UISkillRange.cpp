
#include "ResManager.h"
#include "DisplayCommon.h"
#include "GameComm.h"
#include "ResPool.h"
#include "UISkillRange.h"

USING_NS_CC;
using namespace std;
using namespace ui;

CUISkillRange::CUISkillRange()
: m_SkillRange(NULL)
{
}

CUISkillRange::~CUISkillRange()
{
}

bool CUISkillRange::init()
{
    if (!Node::init())
    {
        return false;
    }

	m_SkillRange = CResManager::getInstance()->getCsbNode("ui_new/p_public/effect/SkillRange.csb");
    m_SkillRange->setAnchorPoint(Vec2(0.5f, 0.5f));
    setName("SkillRange");
    addChild(m_SkillRange);
    ui::Helper::doLayout(m_SkillRange);

    m_SkillRangeAct = CSLoader::createTimeline("ui_new/p_public/effect/SkillRange.csb");
    m_SkillRange->runAction(m_SkillRangeAct);

    return true;
}



void CUISkillRange::onEnter()
{
    Node::onEnter();
    ui::Helper::doLayout(this);
}

void CUISkillRange::onExit()
{
    Node::onExit();
}

void CUISkillRange::playAni(std::string aniName, bool loop, std::function<void()> func)
{
    m_SkillRangeAct->play(aniName, loop);
    if (loop && func)
    {
        m_SkillRangeAct->setLastFrameCallFunc(func);
    }
}

float CUISkillRange::getSkillRidius()
{
    auto image = m_SkillRange->getChildByName("Image_1");
    float scale = image->getScale();
    float skillRidius = image->getContentSize().width * scale;
    return skillRidius;
}