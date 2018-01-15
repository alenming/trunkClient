#include "UIReplayHeroCard.h"
#include "Game.h"
#include "Hero.h"
#include "DisplayCommon.h"
#include "Events.h"
#include "ConfOther.h"
#include "ConfLanguage.h"
#include "ConfGameSetting.h"
#include "ResPool.h"

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;

CUIReplayHeroCardComponent::CUIReplayHeroCardComponent()
: m_Index(0)
, m_DefaultCD(0.0f)
, m_DefautlCost(0.0f)
, m_bLock(false)
, m_bEffectPlaying(false)
, m_Hero(nullptr)
, m_Model(nullptr)
, m_HeroItem(nullptr)
, m_HeroBg(nullptr)
, m_HeroIcon(nullptr)
, m_HeroCost(nullptr)
, m_HeroOnly(nullptr)
, m_LoadingMask(nullptr)
, m_CardAnimation(nullptr)
, m_LightAnimation(nullptr)
, m_LockAnimation(nullptr)
, m_BuffAnimation(nullptr)
, m_CurState(HeroCardState::HeroCardInvalid)
{
}

CUIReplayHeroCardComponent::~CUIReplayHeroCardComponent()
{
}

bool CUIReplayHeroCardComponent::init(cocos2d::Node* cardNode, CHero* hero, int index)
{
    bool ret = Component::init();
    setName("UIHeroCardComponent");
    cardNode->scheduleUpdate();

    // 初始化数据
    m_Index = index;
    m_Hero = hero;
    m_Model = hero->getSoldierCard(index);
    m_bLock = m_Model->IsLock;
    m_DefaultCD = m_Model->MaxCD;
    m_DefautlCost = m_Model->CurCost;

    // 卡牌动画列表：LoadOver(CD结束)、On(正常状态点击)、OnCD(CD状态点击)、OnNoGem(水晶不足点击)、OnOnly(唯一卡牌已派发点击)
    m_CardAnimation = getCsbAnimation(cardNode);
    m_CardAnimation->setLastFrameCallFunc([this]{
        m_bEffectPlaying = false;   // 标记特效播放完毕
    });
    //
    string icon = m_Model->getConf()->Common.HeadIcon;
    int jobs = m_Model->getConf()->Common.Vocation;
    int race = m_Model->getConf()->Common.Race;
	int rare = m_Model->getConf()->Rare;

	std::string str[] = { "NULL", "White", "Green", "Blue", "Voilet", "Yellow" };
	m_LightAnimation = getCsbAnimation(findChild<Node>(cardNode, "HeroItem/RayLight"));
	m_LightAnimation->play(str[rare], true);

	// 卡牌节点
	auto pSoldierItem = queryConfSoldierStarSetting(m_Model->getStar());
	auto pRareItem = queryConfSoldierRareSetting(rare);
	auto pIconItem = queryConfIconSetting();
    //
    m_HeroItem = findChild<Layout>(cardNode, "HeroItem");
    m_HeroBg = findChild<Button>(cardNode, "HeroItem/HeroBg");
    m_HeroIcon = findChild<Button>(cardNode, "HeroItem/HeroIcon");
    Sprite* heroFrame = findChild<Sprite>(cardNode, "HeroItem/LvImage");
    Sprite* heroJobs = findChild<Sprite>(cardNode, "HeroItem/Profesion");
	Sprite* heroJobsBar = findChild<Sprite>(cardNode, "HeroItem/ProfesionBar");
    Sprite* heroRace = findChild<Sprite>(cardNode, "HeroItem/Race");
    m_HeroCost = findChild<Text>(cardNode, "HeroItem/GemNum");
    m_LoadingMask = findChild<Sprite>(cardNode, "HeroItem/LoadingMask");
    //
	m_HeroBg->loadTextureNormal(pRareItem->HeadboxBgRes, TextureResType::PLIST);
    m_HeroIcon->loadTextureNormal(icon, TextureResType::PLIST);
	heroFrame->setSpriteFrame(pRareItem->BigHeadboxRes);
	heroJobs->setSpriteFrame(pRareItem->JobsIcon[jobs - 1]);
	heroJobsBar->setSpriteFrame(pRareItem->JobBg);

    heroRace->setSpriteFrame(pIconItem.RaceIcon[race - 1]);
    m_HeroCost->setString(toolToStr(m_Model->CurCost));

    // 唯一标识(英雄属性)
    if (m_Model->IsSingo)
    {
        auto rootNode = CSLoader::createNode("ui_new/f_fight/effect/Fight_HeroItem_Only.csb");
        rootNode->setPosition(Vec2(85.0f, 112.0f));
        rootNode->setLocalZOrder(LZ_SINGLE);
        m_HeroBg->getParent()->addChild(rootNode);
        ImageView* onlyImage = findChild<ImageView>(rootNode, "OnlyPanel/LevelImage");
		onlyImage->loadTexture(pRareItem->CircleboxRes, TextureResType::PLIST);
        m_HeroOnly = findChild<Text>(rootNode, "OnlyPanel/NumColor/Num");
        m_HeroOnly->setString("1");
    }

    //佣兵标识
    TextBMFont* mercenaryLogo = findChild<TextBMFont>(cardNode, "HeroItem/MercenaryLogo");
    mercenaryLogo->setVisible(false);
    if (m_Model->IsMercenary)
    {
        mercenaryLogo->setVisible(true);
        mercenaryLogo->setString(getLanguageString(CONF_UI_LAN, 2041));
    }

    // 注册派兵监听事件
    auto helper = CGame::getInstance()->BattleHelper;
    helper->pEventManager->addEventHandle(BattleEventDispatchHero,
        this, CALLBACK_FUNCV(CUIReplayHeroCardComponent::onDispatchHero));

    return ret;
}

void CUIReplayHeroCardComponent::update(float dt)
{
    // 检查状态变化
    HeroCardState state = checkModelState();
    if (state != m_CurState)
    {
        // CD结束后可能会切到（正常、水晶不足）两个状态
        switch (state)
        {
        case HeroCardState::HeroCardNormal:
        case HeroCardState::HeroCardLack:
            if (m_CurState == HeroCardState::HeroCardCD)
            {
                playEffect("LoadOver");
            }
            break;
        default:
            break;
        }
        m_CurState = state;
    }

    // CD中或者水晶不足时节点颜色为灰色
    if (m_Model->CurCD < m_Model->MaxCD || !m_Hero->canUseCrystal(m_Model->CurCost))
    {
        m_HeroItem->setColor(Color3B(144, 144, 144));
    }
    else
    {
        m_HeroItem->setColor(Color3B(255, 255, 255));
    }

    // CD
    if (m_Model->CurCD < m_Model->MaxCD)
    {
        m_LoadingMask->setScaleY(1 - m_Model->CurCD / m_Model->MaxCD);
        m_LoadingMask->setVisible(true);
    }
    else
    {
        m_LoadingMask->setVisible(false);
    }

    // 水晶
    if (m_Hero->canUseCrystal(m_Model->CurCost))
    {
        m_HeroBg->setBright(true);
        m_HeroIcon->setBright(true);
        if (m_DefautlCost > m_Model->CurCost)
        {
            m_HeroCost->setTextColor(Color4B::GREEN);
        }
        else if (m_DefautlCost < m_Model->CurCost)
        {
            m_HeroCost->setTextColor(Color4B::YELLOW);
        }
        else
        {
            m_HeroCost->setTextColor(Color4B::WHITE);
        }
    }
    else
    {
        m_HeroBg->setBright(false);
        m_HeroIcon->setBright(false);
        m_HeroCost->setTextColor(Color4B::RED);
    }
    m_HeroCost->setString(toolToStr(m_Model->CurCost));

    // 唯一
    if (m_Model->IsSingo)
    {
        if (m_Hero->isSoldierSingle(m_Index))
        {
            m_HeroOnly->setString("0");
            m_HeroOnly->setColor(Color3B::GRAY);
        }
        else
        {
            m_HeroOnly->setString("1");
            m_HeroOnly->setColor(Color3B::WHITE);
        }
    }

    // 锁(技能效果)
    if (m_bLock != m_Model->IsLock)
    {
        if (NULL == m_LockAnimation)
        {
            auto rootNode = CSLoader::createNode("ui_new/f_fight/effect/Fight_HeroItem_Lock.csb");
            rootNode->setPosition(Vec2(50.0f, 70.0f));
            rootNode->setLocalZOrder(CUIReplayHeroCardComponent::LZ_LOCK);
            rootNode->setScale(0.9f);
            m_HeroBg->getParent()->addChild(rootNode);
            m_LockAnimation = CSLoader::createTimeline("ui_new/f_fight/effect/Fight_HeroItem_Lock.csb");
            rootNode->runAction(m_LockAnimation);
        }
        if (m_bLock)
        {
            m_LockAnimation->play("Unlock", false);
        }
        else
        {
            m_LockAnimation->play("Lock", false);
        }
        m_bLock = m_Model->IsLock;
    }

    // buff
    if (m_DefaultCD == m_Model->MaxCD)
    {
        if (m_BuffAnimation)
        {
            m_BuffAnimation->play("Null", false);
        }
    }
    else
    {
        if (NULL == m_BuffAnimation)
        {
            auto rootNode = CSLoader::createNode("ui_new/f_fight/effect/Fight_HeroItem_U_State.csb");
            rootNode->setPosition(Vec2(50.0f, 76.0f));
            rootNode->setLocalZOrder(CUIReplayHeroCardComponent::LZ_BUFF);
            rootNode->setScale(0.84f);
            m_HeroBg->getParent()->addChild(rootNode);
            m_BuffAnimation = CSLoader::createTimeline("ui_new/f_fight/effect/Fight_HeroItem_U_State.csb");
            rootNode->runAction(m_BuffAnimation);
            m_BuffAnimation->play("Add", true);
        }
        if (m_DefaultCD > m_Model->MaxCD)
        {
            m_BuffAnimation->play("Add", true);
        }
        else if (m_DefaultCD < m_Model->MaxCD)
        {
            m_BuffAnimation->play("Minus", true);
        }
    }
}

void CUIReplayHeroCardComponent::playEffect(const char* effName)
{
    if (m_bEffectPlaying)
        return;

    m_bEffectPlaying = true;
    m_CardAnimation->play(effName, false);
}

CUIReplayHeroCardComponent::HeroCardState CUIReplayHeroCardComponent::checkModelState()
{
    if (m_Model->CurCD < m_Model->MaxCD)
    {
        return HeroCardState::HeroCardCD;
    }
    else if (!m_Hero->canUseCrystal(m_Model->CurCost))
    {
        return HeroCardState::HeroCardLack;
    }
    else
    {
        return HeroCardState::HeroCardNormal;
    }
}

void CUIReplayHeroCardComponent::onDispatchHero(void *data)
{
    auto uid = m_Hero->getBattleHelper()->getUserId();
    BattleCommandInfo* info = reinterpret_cast<BattleCommandInfo*>(data);
    CHECK_RETURN_VOID(info->ExecuterId == uid
        && info->Ext1 == m_Index);

    playEffect("ReplayChoose");
}
