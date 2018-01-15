#include "UITouchInfo.h"
#include "DisplayCommon.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "ResManager.h"
#include "ConfLanguage.h"
#include "ConfManager.h"
#include "ConfFight.h"
#else
#include "commonFrame/resManager/ResManager.h"
#include "gameConfig/ConfLanguage.h"
#include "gameConfig/ConfManager.h"
#include "gameConfig/ConfFight.h"
#endif

USING_NS_CC;

using namespace ui;
using namespace std;

UITouchInfo::UITouchInfo():
m_bIsOpen(false)
{
}

UITouchInfo::~UITouchInfo()
{
}

UITouchInfo* UITouchInfo::create()
{
	UITouchInfo *pRet = new UITouchInfo();
	if (pRet && pRet->init())
	{
		pRet->autorelease();
		return pRet;
	}
	else
	{
		delete pRet;
		pRet = nullptr;
		return nullptr;
	}
}

bool UITouchInfo::init()
{
	if (!cocos2d::Node::init())
	{
		return false;
	}

	initUI();
  
    return true;
}
   
bool UITouchInfo::initUI()
{
	m_UI.m_pHeroCardRoot  = CResManager::getInstance()->getCsbNode("ui_new/f_fight/effect/Hero_TouchTips.csb");
	m_UI.m_pHeroCardRoot->setVisible(false);
	this->addChild(m_UI.m_pHeroCardRoot);

	m_UI.m_pHeroCardTipsPanel = findChild<Layout>(m_UI.m_pHeroCardRoot, "TipsPanel");
	m_UI.m_pName = findChild<Layout>(m_UI.m_pHeroCardRoot, "TipsPanel/Name");
	m_UI.m_pHeroName = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Name/HeroName");
	m_UI.m_pAttackNum = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Name/AttackNum");
	m_UI.m_pBloodNum = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Name/BloodNum");

	m_UI.m_pSkill[0].m_pRoot = findChild<Layout>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1");
	m_UI.m_pSkill[0].m_tSkillName = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1/SkillName");
	m_UI.m_pSkill[0].m_tSkillLevel = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1/SkillLevel");
	m_UI.m_pSkill[0].m_tConsumePoint = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1/ConsumePoint");
	m_UI.m_pSkill[0].m_tCoolingTime= findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1/CoolingTime");
	m_UI.m_pSkill[0].m_tIntroText = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill1/IntroText");

	m_UI.m_pSkill[1].m_pRoot = findChild<Layout>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2");
	m_UI.m_pSkill[1].m_tSkillName = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2/SkillName");
	m_UI.m_pSkill[1].m_tSkillLevel = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2/SkillLevel");
	m_UI.m_pSkill[1].m_tConsumePoint = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2/ConsumePoint");
	m_UI.m_pSkill[1].m_tCoolingTime = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2/CoolingTime");
	m_UI.m_pSkill[1].m_tIntroText = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill2/IntroText");

	m_UI.m_pSkill[2].m_pRoot = findChild<Layout>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3");
	m_UI.m_pSkill[2].m_tSkillName = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3/SkillName");
	m_UI.m_pSkill[2].m_tSkillLevel = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3/SkillLevel");
	m_UI.m_pSkill[2].m_tConsumePoint = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3/ConsumePoint");
	m_UI.m_pSkill[2].m_tCoolingTime = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3/CoolingTime");
	m_UI.m_pSkill[2].m_tIntroText = findChild<Text>(m_UI.m_pHeroCardRoot, "TipsPanel/Skill3/IntroText");


	m_UI.m_pSkillRoot = CResManager::getInstance()->getCsbNode("ui_new/f_fight/effect/Skill_TouchTips.csb");
	m_UI.m_pSkillRoot->setVisible(false);
	this->addChild(m_UI.m_pSkillRoot);

	m_UI.m_tSkillName = findChild<Text>(m_UI.m_pSkillRoot, "TipsPanel/SkillName");
	m_UI.m_tSkillLevel = findChild<Text>(m_UI.m_pSkillRoot, "TipsPanel/SkillLevel");
	m_UI.m_tCoolingTime = findChild<Text>(m_UI.m_pSkillRoot, "TipsPanel/CoolingTime");
	m_UI.m_tConsumePoint = findChild<Text>(m_UI.m_pSkillRoot, "TipsPanel/ConsumePoint");
	m_UI.m_tIntroText = findChild<Text>(m_UI.m_pSkillRoot, "TipsPanel/IntroText");

	return true;
}


void UITouchInfo::updateUI(TOUCH_UI_TYPE uiType, CSoldierModel* hero)
{
	if (uiType == TOUCH_UI_TYPE_HERO)
	{
		auto action = CSLoader::createTimeline("ui_new/f_fight/effect/Hero_TouchTips.csb");
		m_UI.m_pHeroCardRoot->runAction(action);
		action->play("Appear", false);
		m_UI.m_pHeroCardRoot->setVisible(true);
		m_UI.m_pSkillRoot->setVisible(false);
		const SoldierConfItem* heroInfo = hero->getConf();

		std::string name = getLanguageString(CONF_HS_LAN, heroInfo->Common.Name);
		m_UI.m_pHeroName->setString(name);
		std::string hp = getLanguageString(CONF_UI_LAN, 417);

		m_UI.m_pBloodNum->setString(hp + StringUtils::toString(hero->getClassInt(EClassHP)));
		int Pattack = hero->getClassInt(EClassPAttack);
		int Mattackt = hero->getClassInt(EClassMAttack);
		if (Pattack > Mattackt)
		{
			std::string attack = getLanguageString(CONF_UI_LAN, 416);
			m_UI.m_pAttackNum->setString(attack + StringUtils::toString(Pattack));
		}
		else
		{
			std::string attack = getLanguageString(CONF_UI_LAN, 424);
			m_UI.m_pAttackNum->setString(attack + StringUtils::toString(Mattackt));
		}
		std::vector<int> skillIds = hero->getSkillIds();
		auto skillConf = reinterpret_cast<CConfSkill*>(CConfManager::getInstance()->getConf(CONF_SKILL));

		std::string ji = getLanguageString(CONF_UI_LAN, 528);
		Size allSizeHight(m_UI.m_pHeroCardTipsPanel->getContentSize().width, 15);
		
		for (int i = 2; i >= 0; --i)
		{
			const SkillConfItem* const item = reinterpret_cast<SkillConfItem*>(skillConf->getData(skillIds.at(i)));
			if (item && skillIds.at(i) != 0)
			{
				m_UI.m_pSkill[i].m_pRoot->setVisible(true);
				m_UI.m_pSkill[i].m_pRoot->setAnchorPoint(Vec2::ANCHOR_MIDDLE_BOTTOM);
				
				m_UI.m_pSkill[i].m_tSkillName->setString(getLanguageString(CONF_HS_SKILL_LAN, item->Name));
				m_UI.m_pSkill[i].m_tSkillLevel->setVisible(false);
				m_UI.m_pSkill[i].m_tConsumePoint->setString(item->CostDesc1 != 0 ? getLanguageString(CONF_HS_SKILL_LAN, item->CostDesc1) : "");
				m_UI.m_pSkill[i].m_tCoolingTime->setString(item->CostDesc2 != 0 ? getLanguageString(CONF_HS_SKILL_LAN, item->CostDesc2) : "");
				m_UI.m_pSkill[i].m_tIntroText->setString(getLanguageString(CONF_HS_SKILL_LAN, item->Desc));

				Label* newDescLab = Label::createWithTTF(getLanguageString(CONF_HS_SKILL_LAN, item->Desc), 
				m_UI.m_pSkill[i].m_tIntroText->getFontName(), m_UI.m_pSkill[i].m_tIntroText->getFontSize());

				newDescLab->setTextColor(m_UI.m_pSkill[i].m_tIntroText->getTextColor());
				newDescLab->setClipMarginEnabled(false);
				newDescLab->setAnchorPoint(Vec2::ANCHOR_TOP_LEFT);
				newDescLab->setMaxLineWidth(310);
				newDescLab->setVerticalAlignment(TextVAlignment::CENTER);

				Size newSize(m_UI.m_pHeroCardTipsPanel->getContentSize().width, 40);
				newSize.height += newDescLab->getContentSize().height;
				m_UI.m_pSkill[i].m_pRoot->setContentSize(newSize);

				m_UI.m_pSkill[i].m_pRoot->setPosition(Vec2(allSizeHight.width/2, allSizeHight.height));
				allSizeHight.height += newSize.height==40?0:newSize.height;
			}
			else
			{
				m_UI.m_pSkill[i].m_pRoot->setVisible(false);
			}
		}
		allSizeHight.height += m_UI.m_pName->getContentSize().height;
		m_UI.m_pName->setPosition(Vec2(0, allSizeHight.height - m_UI.m_pName->getContentSize().height));
		m_UI.m_pHeroCardTipsPanel->setContentSize(allSizeHight);
	}
}

void UITouchInfo::updateUI(TOUCH_UI_TYPE uiType, CSkill* skill)
{
	if (uiType == TOUCH_UI_TYPE_SKILL)
	{
		m_UI.m_pHeroCardRoot->setVisible(false);
		m_UI.m_pSkillRoot->setVisible(true);

		auto skillConf = reinterpret_cast<CConfSkill*>(CConfManager::getInstance()->getConf(CONF_SKILL));
		const SkillConfItem* const item = reinterpret_cast<SkillConfItem*>(skillConf->getData(skill->skillId()));
		auto action = CSLoader::createTimeline("ui_new/f_fight/effect/Skill_TouchTips.csb");
		m_UI.m_pSkillRoot->runAction(action);
		action->play("Appear", false);
		m_UI.m_tSkillName->setString(getLanguageString(CONF_HS_SKILL_LAN, item->Name));
		m_UI.m_tSkillLevel->setVisible(false);
		m_UI.m_tCoolingTime->setString(item->CostDesc1 != 0 ? getLanguageString(CONF_HS_SKILL_LAN, item->CostDesc1) : "");
		m_UI.m_tConsumePoint->setString(item->CostDesc2 != 0 ? getLanguageString(CONF_HS_SKILL_LAN, item->CostDesc2) : "");
		m_UI.m_tIntroText->setString(getLanguageString(CONF_HS_SKILL_LAN, item->Desc));
	}
}

