#include "UIActionTipsBar.h"
#include "Game.h"
#include "Protocol.h"
#include "BattleProtocol.h"
#include "Hero.h"
#include "DisplayCommon.h"
#include "ResManager.h"
#include "GameComm.h"
#include "BattleHelper.h"
#include "ConfOther.h"
#include "ConfLanguage.h"
#include "EventManager.h"
#include "Events.h"
#include "ResPool.h"

#define TIPBAR_X_OFFSET     23.5
#define TIPBAR_Y_OFFSET     47
#define TIP_WIDTH_OFFSET    48

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;

CUIActionIcon::CUIActionIcon()
: m_CsbNode(nullptr)
, m_Parent(nullptr)
, m_Icon(nullptr)
, m_Name(nullptr)
, m_Desc(nullptr)
{
}

CUIActionIcon::~CUIActionIcon()
{
}

bool CUIActionIcon::init(CUIActionTipsBar* parent, const char* icon, const char* name, const char* desc)
{
    m_Parent = parent;
    m_Icon = icon;
    m_Name = name;
    m_Desc = desc;

    if (m_CsbNode == nullptr)
    {
		m_CsbNode = CResManager::getInstance()->getCsbNode("ui_new/f_fight/Fight_MatchSkill.csb");
        findChild<Layout>(m_CsbNode, "MatchSkillItem")->addClickEventListener(
            CC_CALLBACK_1(CUIActionIcon::onClick, this));
        addChild(m_CsbNode);
    }
    findChild<ImageView>(m_CsbNode, "MatchSkillItem/SkillImage")->loadTexture(icon, TextureResType::PLIST);
    return Node::init();
}

void CUIActionIcon::onEnter()
{
    Node::onEnter();
    runAction(Sequence::create(
        DelayTime::create(4.0f),
        MoveBy::create(2.0f, Vec2(0.0f, 100.0f)),
        CallFunc::create(CC_CALLBACK_0(CUIActionIcon::onFinish, this)),
        nullptr));
}

void CUIActionIcon::onFinish()
{
    // 如果被强制移除（顶出去），则不会再执行到该回调
    m_Parent->popActionIcon();
    removeFromParent();
}

void CUIActionIcon::onClick(cocos2d::Ref* object)
{
    m_Parent->showTip(m_Icon, m_Name, m_Desc, getPosition());
}

CUIActionTipsBar::CUIActionTipsBar()
{
}

CUIActionTipsBar::~CUIActionTipsBar()
{
    for (auto& item : m_Caches)
    {
        item->release();
    }
}

bool CUIActionTipsBar::init(bool isleft)
{
    m_bLeftSide = isleft;
    auto size = Director::getInstance()->getWinSize();
    if (m_bLeftSide)
    {
        setPosition(TIPBAR_X_OFFSET, size.height * 0.67);
    }
    else
    {
        setPosition(size.width - TIPBAR_X_OFFSET, size.height * 0.67);
    }

    // 初始化提示框
	m_TipNode = CResManager::getInstance()->getCsbNode("ui_new/f_fight/effect/Fight_MatchSkill_Tips.csb");
    m_TipNode->setVisible(false);
    addChild(m_TipNode);

    // 监听出兵事件
	m_pEventManager = CGame::getInstance()->BattleHelper->pEventManager;
	m_pEventManager->addEventHandle(BattleEventEnemyActionTips, this, CALLBACK_FUNCV(CUIActionTipsBar::onEnemyAction));
    
    // 监听触摸事件-取消
    auto listener = EventListenerTouchOneByOne::create();
    listener->setSwallowTouches(false);
    listener->onTouchBegan = [this](Touch* touch, Event* ev)->bool {
        hideTip();
        return false;
    };
    getEventDispatcher()->addEventListenerWithSceneGraphPriority(listener, this);

    return Node::init();
}

void CUIActionTipsBar::onExit()
{
    Node::onExit();
	m_pEventManager->removeEventHandle(this);
}

void CUIActionTipsBar::onEnemyAction(void* data)
{
    BattleCommandInfo* info = reinterpret_cast<BattleCommandInfo*>(data);
	if (CGame::getInstance()->BattleHelper->getEnmeyUserId() == info->ExecuterId)
    {
        const char* icon = nullptr;
        const char* desc = nullptr;
        const char* name = nullptr;
        CBattleHelper* helper = CGame::getInstance()->BattleHelper;
        auto role = helper->getMainRole(helper->getCampWithUid(info->ExecuterId));
        CHero* hero = dynamic_cast<CHero*>(role);
        if (hero == nullptr)
        {
            return;
        }

        switch (info->CommandId)
        {
        case CommandSummoner:
            icon = hero->getSoldierCard(info->Ext1)->getConf()->Common.HeadIcon.c_str();
            name = getLanguageString(CONF_HS_LAN, hero->getSoldierCard(info->Ext1)->getConf()->Common.Name);
            desc = getLanguageString(CONF_HS_LAN, hero->getSoldierCard(info->Ext1)->getConf()->Common.Desc);
            addActionIcon(icon, name, desc);
            break;
        case CommandSkill:
            icon = hero->getSkillWithIndex(info->Ext1)->getSkillConf()->IconName.c_str();
            name = getLanguageString(CONF_HS_SKILL_LAN, hero->getSkillWithIndex(info->Ext1)->getSkillConf()->Name);
            desc = getLanguageString(CONF_HS_SKILL_LAN, hero->getSkillWithIndex(info->Ext1)->getSkillConf()->Desc);
            addActionIcon(icon, name, desc);
            break;
        default:
            break;
        }
    }
}

void CUIActionTipsBar::showTip(const char* icon, const char* name, const char* desc, const cocos2d::Vec2& pos)
{
    m_TipNode->stopAllActions();
    // 播放打开动画
    getCsbAnimation(m_TipNode)->play("Appear", false);
    m_TipNode->runAction(Sequence::create(
        DelayTime::create(3.0f),
        Hide::create(),
        nullptr));
    findChild<ImageView>(m_TipNode, "TipBar/SkillImage_1")->loadTexture(icon, TextureResType::PLIST);
    findChild<Text>(m_TipNode, "TipBar/SkillNameLabel")->setString(name); 
    findChild<Text>(m_TipNode, "TipBar/SkillInfoLabel")->setString(desc);
    m_TipNode->setVisible(true);
    if (m_bLeftSide)
    {
        m_TipNode->setPosition(pos.x + TIP_WIDTH_OFFSET, pos.y);
    }
    else
    {
        m_TipNode->setPosition(pos.x - TIP_WIDTH_OFFSET, pos.y);
    }
}

void CUIActionTipsBar::hideTip()
{
    m_TipNode->stopAllActions();
    m_TipNode->setVisible(false);
}

void CUIActionTipsBar::popActionIcon()
{
    // 回收队列中最先的提示按钮
    if (m_Queue.size() > 0)
    {
        auto btn = m_Queue.front();
        m_Caches.push_back(btn);
        btn->retain();
        m_Queue.pop_front();
    }
}

void CUIActionTipsBar::addActionIcon(const char* icon, const char* name, const char* desc)
{
    if (m_Queue.size() > 0)
    {
        if (m_Queue.size() >= 3)
        {
            // 超过3个则把最上面的移除
            auto btn = m_Queue.front();
            popActionIcon();
            btn->removeFromParent();
        }
        // 全部往上移动
		for (auto& item : m_Queue)
		{
			item->setPositionY(item->getPositionY() + TIPBAR_Y_OFFSET);
		}
    }

    // 从Cache中获取或创建一个新的
    CUIActionIcon* actionIcon = nullptr;
    if (m_Caches.size() > 0)
    {
		actionIcon = *m_Caches.rbegin();
		actionIcon->setPositionY(0);
        m_Caches.pop_back();
    }
    else
    {
        actionIcon = new CUIActionIcon();
    }
    // 初始化并添加到场景中
    if (actionIcon)
    {
		m_Queue.push_back(actionIcon);
        actionIcon->init(this, icon, name, desc);
        addChild(actionIcon);
        // release防止内存泄露
        actionIcon->release();
    }
}
