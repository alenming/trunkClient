/*
*   英雄卡片UI
*   1. 绑定UI以及对应的模型，并初始化（框、头像、天赋、消耗）
*   2. 实现CD、常态、水晶不足等状态的切换
*   3. 实现锁和解锁、锁点击逻辑
*   4. 实现唯一限制UI表现更新
*   5. 实现增益减益效果呈现
*
*   点击逻辑优先级：锁点击 > 常态点击 > 水晶不足点击 > 唯一点击 > CD点击
*
*   2015-12-23 by 宝爷
*/
#ifndef __UI_TOUCH_INFO_H__
#define __UI_TOUCH_INFO_H__

#include "cocos2d.h"
#include "GameComm.h"
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#include "SuperRichText.h"
#include "Skill.h"
#else
#include "commonFrame/mixedCode/SuperRichText.h"
#include "gameBattle/logic/Skill.h"
#endif

enum TOUCH_UI_TYPE
{
	TOUCH_UI_TYPE_HERO,
	TOUCH_UI_TYPE_SKILL
};

struct UITouchInfo_UI_SKILL
{
	cocos2d::Node* m_pRoot;
	cocos2d::ui::Text* m_tSkillName;		//技能名字
	cocos2d::ui::Text* m_tSkillLevel;		//技能等级
	cocos2d::ui::Text* m_tCoolingTime;		//冷却
	cocos2d::ui::Text* m_tConsumePoint;		//耗能
	cocos2d::ui::Text* m_tIntroText;		//详细介绍
};

struct UITouchInfo_UIRoot
{
	cocos2d::Node*	m_pSkillRoot;
	cocos2d::ui::Layout* m_pName;
	cocos2d::ui::Text* m_tSkillName;
	cocos2d::ui::Text* m_tSkillLevel;
	cocos2d::ui::Text* m_tCoolingTime;
	cocos2d::ui::Text* m_tConsumePoint;
	cocos2d::ui::Text* m_tIntroText;

	cocos2d::Node*	m_pHeroCardRoot;
	cocos2d::ui::Layout* m_pHeroCardTipsPanel;
	cocos2d::ui::Text*	m_pHeroName;
	cocos2d::ui::Text*	m_pAttackNum;
	cocos2d::ui::Text*	m_pBloodNum;
	UITouchInfo_UI_SKILL	m_pSkill[3];
};

class UITouchInfo : public cocos2d::Node
{
public:
	UITouchInfo();
	virtual ~UITouchInfo();
	static UITouchInfo* create();
    bool init();
	bool initUI();

	void updateUI(TOUCH_UI_TYPE uiType, CSoldierModel* heroId);
	void updateUI(TOUCH_UI_TYPE uiType, CSkill* skill);

	CC_SYNTHESIZE(bool, m_bIsOpen, isOpen);
	Size calculateFontSize(const char *str);
private:
	UITouchInfo_UIRoot m_UI;
};

#endif // __UI_TOUCH_INFO_H__
