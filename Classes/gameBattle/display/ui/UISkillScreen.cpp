#include "ResManager.h"
#include "DisplayCommon.h"
#include "GameComm.h"

#include "UISkillScreen.h"

USING_NS_CC;
using namespace std;
using namespace ui;

CUISkillScreen::CUISkillScreen()
{
}

CUISkillScreen::~CUISkillScreen()
{
}

bool CUISkillScreen::init()
{
    if (!Layer::init())
    {
        return false;
    }

	m_SkillScreen = CResManager::getInstance()->getCsbNode("ui_new/p_public/effect/SkillRange_Screen.csb");
    m_SkillScreen->setContentSize(Director::getInstance()->getWinSize());
    setName("SkillScreen");
    addChild(m_SkillScreen);

    auto action = CSLoader::createTimeline("ui_new/p_public/effect/SkillRange_Screen.csb");
    m_SkillScreen->runAction(action);
    playCsbAnimation(m_SkillScreen, "Stand", true);

    return true;
}

void CUISkillScreen::onEnter()
{
    Layer::onEnter();
    ui::Helper::doLayout(this);
}
void CUISkillScreen::onExit()
{
    Layer::onExit();
}