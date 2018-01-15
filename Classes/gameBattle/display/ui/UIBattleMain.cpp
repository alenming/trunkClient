#include "UIBattleMain.h"
#include "UISkill.h"
#include "UICrystal.h"
#include "UISummoner.h"
#include "UIHeroCard.h"
#include "UIActionTipsBar.h"
#include "ResManager.h"
#include "DisplayCommon.h"
#include "GameComm.h"
#include "Game.h"
#include "Hero.h"
#include "Events.h"
#include "ConfLanguage.h"
#include "UIPause.h"
#include "BattleDragLayer.h"
#include "LuaSummonerBase.h"
#include "UIEffect.h"
#include "FMODAudioEngine.h"
#include "UISkillPoint.h"
#include "ResPool.h"
USING_NS_CC;
using namespace std;
using namespace ui;

CUIBattleMain::CUIBattleMain()
    :m_bUnDoDeathCamera(true)
    , m_nDownTime(0)
    , m_fMoodParam(0.0f)
	, m_nSpeed(1.0f)
{
}


CUIBattleMain::~CUIBattleMain()
{
    Director::getInstance()->getScheduler()->setTimeScale(1.f);
}

bool CUIBattleMain::init()
{
    bool ret = Layer::init();
	m_BattleUI = CResManager::getInstance()->getCsbNode("ui_new/f_fight/Fight.csb");
    m_BattleUI->setContentSize(Director::getInstance()->getWinSize());
    addChild(m_BattleUI);

    auto action = CSLoader::createTimeline("ui_new/f_fight/Fight.csb");
    m_BattleUI->runAction(action);
    action->play("Hide", false);

    m_Helper = CGame::getInstance()->BattleHelper;
    m_nHurt = 0;
    m_nSkillIndex = 0;
    m_bUnDoDeathCamera = true;

    auto pauseBtn = findChild<Button>(m_BattleUI, "MainPanel/PlayAndPause_Button");
	auto pauseBtnSon = findChild<Node>(m_BattleUI, "MainPanel/PlayAndPause_Button/PlayAndPause_Button");
    if (m_Helper->getBattleType() == EBATTLE_PVP
        || m_Helper->getBattleType() == EBATTLE_GUIDE
        || m_Helper->getBattleType() == EBATTLE_PVPROBOT)
    {
        pauseBtn->setVisible(false);
		//不清楚为啥父节点调用setVisible没效果,只能让子节点隐藏了
		pauseBtnSon->setVisible(false);
    }
    else
    {
        pauseBtn->addClickEventListener([](Ref* sender){
            // 暂停回调
            CUIPause* pause = CUIPause::create();
            pause->setLocalZOrder(LZ_UI + 10);
            Director::getInstance()->getRunningScene()->addChild(pause);
        });
    }

    // 获取本地节点
    m_SkillTip = findChild<Node>(m_BattleUI, "MainPanel/Tips_1");
    m_Tips = findChild<Node>(m_BattleUI, "MainPanel/Tips_2");
    m_TimeText = findChild<Text>(m_BattleUI, "MainPanel/TimeItem/TimePanel/TimeTex");
    m_TimeAct = getCsbAnimation(findChild<Node>(m_BattleUI, "MainPanel/TimeItem"));
	// 提示文字开始时隐藏, 需要调用时再显示
	m_Tips->setVisible(false);
    // 伤害节点——只有金币试炼会用到
    m_HurtNode = findChild<Node>(m_BattleUI, "MainPanel/HurtsItem");
	if (m_Helper->getBattleType() != EBATTLE_GOLDTEST && m_Helper->getBattleType() != EBATTLE_UNIONEXPEDITION)
    {
        m_HurtNode->removeFromParent();
    }
    else
    {
        m_HurtText = findChild<TextAtlas>(m_HurtNode, "HurtsItem/HurtsNumAtlasLabel");
        m_HurtText->setString(toolToStr(m_nHurt));
        Text* hurtTips = findChild<Text>(m_HurtNode, "HurtsItem/HurtsTips");
        getLanguageString(CONF_UI_LAN, 1016);
        playCsbAnimation(m_HurtNode, "Normal");
    }

    // 倒计时节点——默认隐藏
    m_DownTimeNode = findChild<Node>(m_BattleUI, "MainPanel/CountdownTime");
    m_DownTimeText = findChild<TextAtlas>(m_DownTimeNode, "TimeAtlasLabel");
    m_DownTimeNode->setVisible(false);

    // 获取召唤师对象
    auto hero = dynamic_cast<CHero*>(m_Helper->getMainRole(
        m_Helper->getCampWithUid(m_Helper->getUserId())));

    // 初始化己方召唤师和敌方召唤师面板面板
    auto summonerPanelL = findChild<Node>(m_BattleUI, "MainPanel/ScreenPanel_3/SummonerPanel_L");
    auto summonerPanelR = findChild<Node>(m_BattleUI, "MainPanel/ScreenPanel_3/SummonerPanel_R");

    auto enemyRole = dynamic_cast<CRole*>(m_Helper->getMainRole(
        m_Helper->getEnmeyCampWithUid(m_Helper->getUserId())));	

    auto summonerCom = new CUISummonerComponent();
    auto summonerEnemyCom = new CUISummonerComponent();
    
    summonerCom->init(summonerPanelL, hero, true);
    summonerEnemyCom->init(summonerPanelR, enemyRole, false);
    summonerPanelL->addComponent(summonerCom);
    summonerPanelR->addComponent(summonerEnemyCom);

    summonerCom->release();
    summonerEnemyCom->release();

    // 初始化7个士兵卡片 —— 下标为0123456
    for (int i = 0; i < 7; ++i)
    {
        auto heroCard = findChild<Node>(m_BattleUI, string("MainPanel/DownPanel/HeroButton_" + toolToStr(i + 1) + "/HeroItem").c_str());
        if (hero->getSoldierCard(i) != nullptr)
        {
            auto heroCom = new CUIHeroCardComponent();
            heroCom->init(heroCard, hero, i);
            heroCard->addComponent(heroCom);
            heroCom->release();
        }
        else
        {
            // 初始化空图标
            auto rootNode = CSLoader::createNode("ui_new/f_fight/Fight_HeroItem_Null.csb");
            rootNode->setPosition(heroCard->getPosition());
            rootNode->setLocalZOrder(heroCard->getLocalZOrder());
            heroCard->getParent()->addChild(rootNode);
            heroCard->removeFromParentAndCleanup(true);
        }
    }

    // 初始化英雄技能 —— 下标为123
    for (int i = 1; i < 4; ++i)
    {
        auto skillBtn = findChild<Button>(m_BattleUI, string("MainPanel/SkillButton_" + toolToStr(i)).c_str());
        auto skillNode = findChild<Node>(skillBtn, string("SkillItem").c_str());
        CUISkillComponent* skillCom = new CUISkillComponent();
        skillCom->init(skillNode, hero, i);
        skillNode->addComponent(skillCom);
        skillCom->release();

        m_mapPosition[i * 2 - 1] = skillBtn->getPosition();
    }

    // 初始化英雄技能升级提示节点 —— 下标 12
    for (int i = 1; i < 3; ++i)
    {
        auto skillPoint = findChild<Node>(m_BattleUI, string("MainPanel/Fight_UpSkill_Point_" + toolToStr(i)).c_str());
        CUISkillPointComponent* pointCom = new CUISkillPointComponent();
        pointCom->init(skillPoint, hero, i);
        skillPoint->addComponent(pointCom);
        pointCom->release();

        m_mapPosition[i * 2] = skillPoint->getPosition();
    }

    // 初始化水晶
    auto crytalBtn = findChild<Node>(m_BattleUI, "MainPanel/DownPanel/GemButton/GemItem");
    CUICrystalComponent* crytalCom = new CUICrystalComponent();
    crytalCom->init(crytalBtn, hero);
    crytalBtn->addComponent(crytalCom);
    crytalCom->release();

    // 获取水晶升级提示粒子节点
    m_NodeBazier = findChild<Node>(m_BattleUI, string("MainPanel/UpSkill_Bazier").c_str());
    m_ActionBazier = getCsbAnimation(m_NodeBazier);
    m_OldPosition = m_NodeBazier->getPosition();

	//放大 缩小
	m_ScaleAddButton = findChild<Button>(m_BattleUI, "MainPanel/ScaleAddButton");
	m_ScaleMinusButton = findChild<Button>(m_BattleUI, "MainPanel/ScaleMinusButton");
#ifdef WIN32
	m_ScaleAddButton->addClickEventListener(CC_CALLBACK_1(CUIBattleMain::onBtnAdd, this));
	m_ScaleMinusButton->addClickEventListener(CC_CALLBACK_1(CUIBattleMain::onBtnMinus, this));
#else
	m_ScaleAddButton->setVisible(false);
	m_ScaleMinusButton->setVisible(false);
#endif

	m_SpeedButton = findChild<Button>(m_BattleUI, "MainPanel/SpeedButton");

	if (m_Helper->getBattleType() != EBATTLE_PVP
        && m_Helper->getBattleType() != EBATTLE_PVPROBOT)
	{
		//加速减速
		m_SpeedButton->addClickEventListener(CC_CALLBACK_1(CUIBattleMain::onBtnSpeed, this));
		m_nSpeed = 1.0f;
	}
	else
	{
		m_SpeedButton->setVisible(false);
	}



    // 注册相关事件监听
    m_Helper->pEventManager->addEventHandle(BattleEventTouchReleaseSkill,
        this, CALLBACK_FUNCV(CUIBattleMain::onShowSkillMark));
    m_Helper->pEventManager->addEventHandle(BattleEventTouchCancelSkill,
        this, CALLBACK_FUNCV(CUIBattleMain::onHideSkillMark));
    m_Helper->pEventManager->addEventHandle(BattleEventTouchPlaySkill,
        this, CALLBACK_FUNCV(CUIBattleMain::onHideSkillMark));
    m_Helper->pEventManager->addEventHandle(BattleEventShowTips,
        this, CALLBACK_FUNCV(CUIBattleMain::onShowTip));

    m_Helper->pEventManager->addEventHandle(BattleEventTouchReleaseTips,
        this, CALLBACK_FUNCV(CUIBattleMain::onShowReleaseSkill));
    m_Helper->pEventManager->addEventHandle(BattleEventTouchCancelTips,
        this, CALLBACK_FUNCV(CUIBattleMain::onShowCancelSkill));

    m_Helper->pEventManager->addEventHandle(BattleEventFightStartTips,
        this, CALLBACK_FUNCV(CUIBattleMain::onFightStart));

    m_Helper->pEventManager->addEventHandle(BattleEventCrystalUpgrade,
        this, CALLBACK_FUNCV(CUIBattleMain::onCrystalUpgrade));

    // CUIActionTipsBar
    m_ActionTipsBar = new CUIActionTipsBar();
    m_ActionTipsBar->init(false);
    addChild(m_ActionTipsBar);
    m_ActionTipsBar->release();

    scheduleUpdate();

	// 序列化 反序列化按钮显示
	// showSerializeInfo();

    return ret;
}


void CUIBattleMain::setAllTouchEnabled(bool enabled)
{
    auto pauseBtn = findChild<Button>(m_BattleUI, "MainPanel/PlayAndPause_Button");
    pauseBtn->setTouchEnabled(enabled);

    // 召唤师点击
    findChild<ImageView>(m_BattleUI, "MainPanel/ScreenPanel_3/SummonerPanel_L/HeadBar/HeadImage")
        ->setTouchEnabled(enabled);
    findChild<ImageView>(m_BattleUI, "MainPanel/ScreenPanel_3/SummonerPanel_R/HeadBar/HeadImage")
        ->setTouchEnabled(enabled);

    // 初始化7个士兵卡片 —— 下标为0123456
    for (int i = 0; i < 7; ++i)
    {
        auto heroBtn = findChild<Button>(m_BattleUI, string("MainPanel/DownPanel/HeroButton_" + toolToStr(i + 1)).c_str());
        heroBtn->setTouchEnabled(enabled);
    }

    // 初始化英雄技能 —— 下标为123
    for (int i = 1; i < 4; ++i)
    {
        if (i != m_nSkillIndex)
        {
            auto skillBtn = findChild<Button>(m_BattleUI, string("MainPanel/SkillButton_" + toolToStr(i)).c_str());
            skillBtn->setTouchEnabled(enabled);
        }
    }

    // 初始化水晶
    auto crytalBtn = findChild<Button>(m_BattleUI, "MainPanel/DownPanel/GemButton");
    crytalBtn->setTouchEnabled(enabled);
}

void CUIBattleMain::update(float delta)
{
    updateTime();
    updateHurt();
    updateDeath();
}

void CUIBattleMain::onEnter()
{
    Layer::onEnter();
    ui::Helper::doLayout(this);
}

void CUIBattleMain::onExit()
{
    Layer::onExit();
    m_Helper->pEventManager->removeEventHandle(this);
}

void CUIBattleMain::onShowTip(void* data)
{
    const char* tips = reinterpret_cast<const char*>(data);
    showTips(tips);
}

void CUIBattleMain::onShowSkillMark(void* data)
{
    //playCsbAnimation(m_BattleUI, "On", true);
    m_nSkillIndex = *(reinterpret_cast<int*>(data));
    setAllTouchEnabled(false);

    m_SkillTip->setVisible(true);
    auto tipsLable = findChild<Text>(m_SkillTip, "TipsLabel");
    const char* tipsText = getLanguageString(CONF_UI_LAN, 298);
    tipsLable->setString(tipsText);
    tipsLable->setColor(Color3B::YELLOW);
}

void CUIBattleMain::onShowReleaseSkill(void* data)
{
    auto tipsLable = findChild<Text>(m_SkillTip, "TipsLabel");
    const char* tipsText = reinterpret_cast<const char*>(data);
    tipsLable->setString(tipsText);
    tipsLable->setColor(Color3B::GREEN);
}

void CUIBattleMain::onShowCancelSkill(void* data)
{
    auto tipsLable = findChild<Text>(m_SkillTip, "TipsLabel");
    const char* tipsText = reinterpret_cast<const char*>(data);
    tipsLable->setString(tipsText);
    tipsLable->setColor(Color3B::RED);
}

void CUIBattleMain::onHideSkillMark(void* data)
{
    //playCsbAnimation(m_BattleUI, "Off", true);
    setAllTouchEnabled(true);
    m_SkillTip->setVisible(false);
}

void CUIBattleMain::onFightStart(void* data)
{
    auto action = CSLoader::createTimeline("ui_new/f_fight/Fight.csb");
    m_BattleUI->runAction(action);
    action->play("Appear", false);
    playSoundEffect(49);
}

void CUIBattleMain::onCrystalUpgrade(void* data)
{
    auto uid = m_Helper->getUserId();
    if (nullptr != data)
    {
        BattleCommandInfo* info = reinterpret_cast<BattleCommandInfo*>(data);
        CHECK_RETURN_VOID(info->ExecuterId == uid);
    }

    auto hero = dynamic_cast<CRole*>(m_Helper->getMainRole(m_Helper->getCampWithUid(uid)));
    int crystalLevel = hero->getIntAttribute(EHeroCrystalLevel);
    auto iter = m_mapPosition.find(crystalLevel - 1);
    if (iter != m_mapPosition.end())
    {
        m_NodeBazier->setVisible(true);
        m_ActionBazier->play("Move", true);
        
        Size winSize = Director::getInstance()->getVisibleSize();
        Vec2 pos = iter->second;
        float posX = pos.x * winSize.width / 1136.0f;
        float posY = pos.y * winSize.height / 640.0f;
        auto moveTo = cocos2d::MoveTo::create(0.75, Vec2(posX, posY));
        auto callback1 = cocos2d::CallFunc::create([this]()
        {
            m_ActionBazier->play("Stop", false);
        });
        auto delay = cocos2d::DelayTime::create(0.5f);
        auto callback2 = cocos2d::CallFunc::create([this]()
        {
            m_NodeBazier->setVisible(false);
            m_NodeBazier->setPosition(Vec2(m_OldPosition));
        });
        auto sequence = cocos2d::Sequence::create(moveTo, callback1, delay, callback2, nullptr);
        m_NodeBazier->runAction(sequence);
    }
}

void CUIBattleMain::showTips(const char* tips, float delay /* = 2.0f */)
{
	m_Tips->setVisible(true);
    // 强制更新Tips
	findChild<Text>(m_Tips, "TipsLabel")->setString(tips);
    m_Tips->stopAllActions();
    m_Tips->setOpacity(255);
    m_Tips->runAction(Sequence::create(
		FadeIn::create(0.2f),
        DelayTime::create(delay),
        FadeOut::create(1.0f),
        nullptr));
}

void CUIBattleMain::updateTime()
{
    // 更新时间值
    int leftSecond = (m_Helper->MaxTick - m_Helper->CurTick) / m_Helper->TickPerSecond;
    if (leftSecond < 0)
    {
        leftSecond = 0;
    }

    int min = leftSecond / 60;
    int second = leftSecond % 60;
    char buf[16];
    snprintf(buf, sizeof(buf), "%02d:%02d", min, second);
    m_TimeText->setString(buf);

    // 时间小于30秒开始警告，play一次，循环播放
    if (leftSecond == 30)
    {
        m_TimeAct->play("RedBlink", true);
    }
    // 时间小于10秒开始倒计时，play一次，循环
    else if (leftSecond == 10)
    {
        m_DownTimeNode->setVisible(true);
        playCsbAnimation(m_DownTimeNode, "Countdown", true);
        m_DownTimeText->setString(toolToStr(leftSecond));
    }
    else if (leftSecond < 10)
    {
        m_DownTimeText->setString(toolToStr(leftSecond));
    }

    playDownTimeEffect(leftSecond);
    changeBackgroudMood();
}

void CUIBattleMain::updateHurt()
{
    if (m_Helper->getSettleAccountModel())
    {
        if (m_Helper->getSettleAccountModel()->getHitBossHP() != m_nHurt)
        {
            m_nHurt = m_Helper->getSettleAccountModel()->getHitBossHP();
            playCsbAnimation(m_HurtNode, "HurtsAdd");
            m_HurtText->setString(toolToStr(m_nHurt));
        }
    }
}

void CUIBattleMain::updateDeath()
{
    if (m_bUnDoDeathCamera)
    {
        // 获取召唤师对象
        auto hero = dynamic_cast<CRole*>(m_Helper->getMainRole(
            m_Helper->getCampWithUid(m_Helper->getUserId())));
        // 获取对方召唤师/boss
        auto enemy = dynamic_cast<CRole*>(m_Helper->getMainRole(
            m_Helper->getEnmeyCampWithUid(m_Helper->getUserId())));

        // 判断血量
        //bool heroDie = (hero && hero->getIntAttribute(EAttributeHP) == 0);
        //bool bossDie = (enemy && enemy->getIntAttribute(EAttributeHP) == 0);
        // 判断是否真的死亡
        bool heroDie = hero->isRealDead();
        bool bossDie = enemy->isRealDead();
        if (heroDie || bossDie)
        {
            m_BattleUI->setVisible(false);
            setAllTouchEnabled(false);
            m_bUnDoDeathCamera = false;
            // 暂停动作
            CUIEffectManager::getInstance()->stopUIEffect();
            CBattleDragLayer *pDragLayer = dynamic_cast<CBattleDragLayer *>(
				Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));
            CBattleLayer *pBattleLayer = dynamic_cast<CBattleLayer *>(
				Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_BATTLE));

            // 策划说，第一个新手引导关卡不走镜头
            if (m_Helper->getStageId() == 100)
            {
                onLuaEventWithParamInt(8, m_Helper->getStageId());
            }
            else if (pDragLayer && pBattleLayer)
            {
                Size s = Director::getInstance()->getWinSize();
                // 不清楚需要几个屏幕的大小才能全部盖住, 先用4个屏幕
                // 创建黑色面板
                LayerColor* pMaskLayer = LayerColor::create(cocos2d::Color4B(0, 0, 0, 200), s.width * 4, s.height * 4);
                pBattleLayer->addChild(pMaskLayer, SLZ_BATTLE2+1);
                pMaskLayer->setPosition(-s.width, -s.height);
                hero->setLocalZOrder(SLZ_BATTLE2 + 2);
                enemy->setLocalZOrder(SLZ_BATTLE2 + 2);

                // 设置游戏速度
                Director::getInstance()->getScheduler()->setTimeScale(0.3f);
                pDragLayer->startCamera(heroDie ? 3 : 4);

                //设置回调
                pDragLayer->setCameraFinishCallback([this, pMaskLayer, bossDie](){
                    Director::getInstance()->getScheduler()->setTimeScale(1.f);
                    if (bossDie)
                    {
                        onLuaEventWithParamInt(8, m_Helper->getStageId());
                    }
                    pMaskLayer->removeFromParent();
                });
            }
        }
    }
}

void CUIBattleMain::playDownTimeEffect(int time)
{
    if (m_nDownTime == time)
    {
        return;
    }

    m_nDownTime = time;
    switch (time)
    {
    case 10:
    case 9:
    case 8:
    case 7:
    case 6:
    case 1:
        playSoundEffect(43);
        break;
    case 5:
    case 4:
    case 3:
    case 2:
        playSoundEffect(44);
        break;
    case 0:
        playSoundEffect(45);
        break;
    default:
        break;
    }
}

void CUIBattleMain::changeBackgroudMood()
{
    const StageConfItem* pStageConfItem = queryConfStage(m_Helper->getStageId());
    CHECK_RETURN_VOID(NULL != pStageConfItem);
    const StageSceneConfItem* item = queryConfStageScene(pStageConfItem->StageSenceID);
    CHECK_RETURN_VOID(NULL != item);

    if (1.0f > m_fMoodParam && checkMoodCondition(item->IMSControl1))
    {
        m_fMoodParam = 1.0f;
        CFMODAudioEngine::getInstance()->setBackgroundMusicParam("mood", m_fMoodParam);
    }

    if (2.0f > m_fMoodParam && checkMoodCondition(item->IMSControl2))
    {
        m_fMoodParam = 2.0f;
        CFMODAudioEngine::getInstance()->setBackgroundMusicParam("mood", m_fMoodParam);
    }
}

void CUIBattleMain::showSerializeInfo()
{
	m_SerializeBuffData = NULL;
	m_unSerializeBuffData = NULL;

	Size winSize = Director::getInstance()->getVisibleSize();

	MenuItemFont* xlh = MenuItemFont::create(
		"XuLieHua",
		CC_CALLBACK_1(CUIBattleMain::serializeMenuCallback, this)
		);
	xlh->setPosition(winSize.width - 100, winSize.height - 70);

	MenuItemFont* fxlh = MenuItemFont::create(
		"FanXuLieHua",
		CC_CALLBACK_1(CUIBattleMain::unSerializeMenuCallback, this)
		);
	fxlh->setPosition(winSize.width - 100, winSize.height - 110);

	auto menu = cocos2d::Menu::create(xlh, fxlh, nullptr);
	menu->setPosition(Vec2::ZERO);
	this->addChild(menu);
}

void CUIBattleMain::serializeMenuCallback(Ref* ref)
{
	CBattleHelper* battleHelper = CGame::getInstance()->BattleHelper;

	CC_SAFE_DELETE(m_SerializeBuffData);
	CC_SAFE_DELETE(m_unSerializeBuffData);

	m_SerializeBuffData = new CBufferData();
    m_SerializeBuffData->init(65535);

	battleHelper->serialize(*m_SerializeBuffData);
}

void CUIBattleMain::unSerializeMenuCallback(Ref* ref)
{
	CBattleHelper* battleHelper = CGame::getInstance()->BattleHelper;

	if (m_SerializeBuffData)
	{
		m_unSerializeBuffData = new CBufferData();
		m_unSerializeBuffData->init(m_SerializeBuffData->getBuffer(), m_SerializeBuffData->getDataLength());
		m_unSerializeBuffData->resetOffset();

		battleHelper->unserialize(*m_unSerializeBuffData);
		CC_SAFE_DELETE(m_unSerializeBuffData);
	}
}

bool CUIBattleMain::checkMoodCondition(const VecVecInt& conditionList)
{
    bool bRlt = false;
    for (auto &condition : conditionList)
    {
        if (2 != condition.size())
        {
            bRlt = false;
            break;
        }

        if (1 == condition[0])
            bRlt = timeCondition(condition[1]);
        else if (2 == condition[0])
            bRlt = soilderCondition(condition[1]);
        else
            bRlt = crystalCondition(condition[1]);

        if (!bRlt)
            break;
    }

    return bRlt;
}

bool CUIBattleMain::timeCondition(float time)
{
    float s = m_Helper->CurTick / m_Helper->TickPerSecond;
    
    return time <= s;
}

bool CUIBattleMain::soilderCondition(int count)
{
    int c = m_Helper->getRoleWithCamp(CampType::ECamp_Blue).size()
        + m_Helper->getEnmeyRoleWithCamp(CampType::ECamp_Blue).size();

    return count <= c;
}

bool CUIBattleMain::crystalCondition(int level)
{
    CRole *pPlayerHero = m_Helper->getMainRole(m_Helper->getCampWithUid(m_Helper->getUserId()));
    CHECK_RETURN(NULL != pPlayerHero);

    return pPlayerHero->getIntAttribute(EHeroCrystalLevel) >= level;
}

void CUIBattleMain::onBtnAdd(Ref* object)
{
	CBattleDragLayer *pDragLayer = dynamic_cast<CBattleDragLayer *>(Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));
	pDragLayer->testScaleZoomOut(pDragLayer);
}

void CUIBattleMain::onBtnMinus(Ref* object)
{
	CBattleDragLayer *pDragLayer = dynamic_cast<CBattleDragLayer *>(Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));
	pDragLayer->testScaleZoomIn(pDragLayer);
}

void CUIBattleMain::onBtnSpeed(Ref* object)
{
	auto speedButton = findChild<Node>(m_BattleUI, "MainPanel/SpeedButton/SpeedButton");
	auto action = CSLoader::createTimeline("ui_new/f_fight/effect/SpeedButton.csb");
	if (m_nSpeed == 1.0f)
	{
		m_nSpeed = 2.0f;
		Director::getInstance()->getScheduler()->setTimeScale(m_nSpeed);
		action->setLastFrameCallFunc([=](){action->play("X2", true); });
		speedButton->stopAllActions();
		speedButton->runAction(action);
		action->play("X1ToX2", false);
	}
	else if (m_nSpeed == 2.0f)
	{
		m_nSpeed = 1.0f;
		Director::getInstance()->getScheduler()->setTimeScale(m_nSpeed);
		action->setLastFrameCallFunc([=](){action->play("X1", true); });
		speedButton->stopAllActions();
		speedButton->runAction(action);
		action->play("X2ToX1", false);
	}
}
