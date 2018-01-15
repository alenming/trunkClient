#include "UIReplayCrystal.h"
#include "Game.h"
#include "Hero.h"
#include "DisplayCommon.h"
#include "Events.h"
#include "ConfOther.h"
#include "ConfLanguage.h"
#include "LuaSummonerBase.h"

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;

CUIReplayCrystalComponent::CUIReplayCrystalComponent()
: m_CurLevel(0)
, m_DefaultSpeed(0.0f)
, m_CurCrystal(0.0f)
, m_MaxCrystal(0)
, m_bEffectPlaying(false)
, m_Hero(nullptr)
, m_LevelText(nullptr)
, m_CurCrystalText(nullptr)
, m_MaxCrystalText(nullptr)
, m_AddGemText(nullptr)
, m_LoadingBar(nullptr)
, m_CrystalAnimation(nullptr)
, m_AddGemAnimation(nullptr)
, m_BuffAnimation(nullptr)
{
	
}

CUIReplayCrystalComponent::~CUIReplayCrystalComponent()
{
}

bool CUIReplayCrystalComponent::init(cocos2d::Node* crystalNode, CHero* hero)
{
    bool ret = Component::init();
    setName("UICrystalComponent");

    m_Hero = hero;
    m_CurLevel = m_Hero->getIntAttribute(EHeroCrystalLevel);
    m_CurCrystal = m_Hero->getFloatAttribute(EHeroCrystal); 
    m_DefaultSpeed = m_Hero->getFloatAttribute(EHeroCrystalSpeedParam);

    m_CrystalAnimation = getCsbAnimation(crystalNode);
    m_CrystalAnimation->setLastFrameCallFunc([this]{
        m_bEffectPlaying = false;   // 标记特效播放完毕
    });

    // 水晶消耗增益减益动画列表：Add增益、Minus减益、Normal正常
    m_AddGemAnimation = getCsbAnimation(findChild<Node>(crystalNode, "LevelPanel/AddGem"));
    m_AddGemAnimation->play("Hide", false);

    m_LevelText = findChild<Text>(crystalNode, "LevelPanel/LvText");
    m_CurCrystalText = findChild<Text>(crystalNode, "LevelPanel/GemNum");
    m_MaxCrystalText = findChild<Text>(crystalNode, "LevelPanel/GemSum");
    m_AddGemText = findChild<Text>(crystalNode, "LevelPanel/AddGem/NumPanel/GemNum");
    m_LoadingBar = findChild<LoadingBar>(crystalNode, "LevelPanel/LoadingBar_1");

    cocostudio::ArmatureDataManager::getInstance()->addArmatureFileInfo("ui_new/f_fight/effect/GemState.ExportJson");
    m_BuffAnimation = Armature::create("GemState");
    m_BuffAnimation->setVisible(false);
    m_BuffAnimation->setPosition(Vec2(112.0f, 24.0f));
    m_BuffAnimation->setLocalZOrder(CUIReplayCrystalComponent::LZ_CRYSTALSTATE);
    m_LevelText->getParent()->addChild(m_BuffAnimation);

    m_MaxCrystal = queryConfCrystal(m_CurLevel)->Max;

    setCurLevelText();
    setCurCrystalText();
    setMaxCrystalText();

    // 注册升级监听事件
    auto helper = CGame::getInstance()->BattleHelper;
    helper->pEventManager->addEventHandle(BattleEventCrystalUpgrade,
        this, CALLBACK_FUNCV(CUIReplayCrystalComponent::onCrystalUpgrade));

    return ret;
}

void CUIReplayCrystalComponent::update(float dt)
{
    playCrystalEffect(dt);
    playBuffEffect();
}

/*
@brief  设置水晶等级
*/
void CUIReplayCrystalComponent::setCurLevel()
{
    m_CurLevel = m_Hero->getIntAttribute(EHeroCrystalLevel);
}

/*
@brief  设置当前水晶数量
*/
void CUIReplayCrystalComponent::setCurCrystal()
{
    m_CurCrystal = m_Hero->getFloatAttribute(EHeroCrystal);
}

/*
@brief  设置最大水晶数量
*/
void CUIReplayCrystalComponent::setMaxCrystal()
{
    m_MaxCrystal = queryConfCrystal(m_CurLevel)->Max;
}

/*
@brief  设置水晶等级文本
*/
void CUIReplayCrystalComponent::setCurLevelText()
{
    if (m_Hero->isCrystalMaxLevel())
    {
        m_LevelText->setString(getLanguageString(CONF_UI_LAN, 578));
    }
    else
    {
        m_LevelText->setString(toolToStr(m_CurLevel));
    }
}

/*
@brief  设置当前水晶数量文本
*/
void CUIReplayCrystalComponent::setCurCrystalText()
{
    m_CurCrystalText->setString(toolToStr(static_cast<int>(m_CurCrystal)));
}

/*
@brief  设置最大水晶数量文本
*/
void CUIReplayCrystalComponent::setMaxCrystalText()
{
    m_MaxCrystalText->setString(std::string("/") + toolToStr(m_MaxCrystal));
}

/*
* @brief   设置水晶加载进度条
*/
void CUIReplayCrystalComponent::setLoadingBarPercent()
{
    m_LoadingBar->setPercent(getLoadPercent());
}

void CUIReplayCrystalComponent::playCrystalEffect(float dt)
{
    float curCrystal = m_Hero->getFloatAttribute(EHeroCrystal);
    if (m_CurCrystal != curCrystal)
    {
        setCurCrystal();
        setCurCrystalText();
    }

    int crystalLevel = m_Hero->getIntAttribute(EHeroCrystalLevel);
    if (m_CurLevel != crystalLevel)
    {
        setCurLevel();
        setCurLevelText();
        setMaxCrystal();
        setMaxCrystalText();
    }

    setLoadingBarPercent();

    int maxCrystal = queryConfCrystal(crystalLevel)->Max;
    // 水晶等级未达到最大、数量达到最大值
    if (!m_Hero->isCrystalMaxLevel() && static_cast<int>(curCrystal) == maxCrystal)
    {
        playEffect("LVGemFull");
    }
    // 水晶等级达到最大，数量未达到最大值
    else if (m_Hero->isCrystalMaxLevel() && static_cast<int>(curCrystal) < maxCrystal)
    {
        playEffect("MaxLevelUp");
    }
    // 水晶等级，数量都达到最大值
    else if (m_Hero->isCrystalMaxLevel() && static_cast<int>(curCrystal) == maxCrystal)
    {
        playEffect("GemFull");
    }
}

/**
@brief  播放水晶的增益减益特效
*/
void CUIReplayCrystalComponent::playBuffEffect()
{
    // 处理增益减益效果
    if (m_DefaultSpeed == 1 || m_Hero->getFloatAttribute(EHeroCrystal) == m_MaxCrystal)
    {
        // 正常状态
        m_BuffAnimation->setVisible(false);
    }
    else if (m_DefaultSpeed < 1 && m_Hero->getFloatAttribute(EHeroCrystal) < m_MaxCrystal)
    {
        // 水晶恢复减速
        if (!m_BuffAnimation->isVisible())
        {
            m_BuffAnimation->setVisible(true);
            m_BuffAnimation->getAnimation()->play("Minus", -1, 1);
        }
    }
    else if (m_DefaultSpeed > 1 && m_Hero->getFloatAttribute(EHeroCrystal) < m_MaxCrystal)
    {
        // 水晶恢复加速
        if (!m_BuffAnimation->isVisible())
        {
            m_BuffAnimation->setVisible(true);
            m_BuffAnimation->getAnimation()->play("Add", -1, 1);
        }
    }
}

void CUIReplayCrystalComponent::onCrystalUpgrade(void* data)
{
    playEffect("LevelUp");
}

void CUIReplayCrystalComponent::playEffect(const char* effName)
{
    if (m_bEffectPlaying)
        return;

    m_bEffectPlaying = true;
    m_CrystalAnimation->play(effName, false);
}

/*
@brief  获取加载的进度
*/
float CUIReplayCrystalComponent::getLoadPercent()
{
    if (m_MaxCrystal == 0)
    {
        return 0.0f;
    }
    else
    {
        return 100 * m_CurCrystal / m_MaxCrystal;
    }
}