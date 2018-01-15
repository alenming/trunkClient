#include "HPBar.h"
#include "GameComm.h"
#include "ResManager.h"
#include "Game.h"
#include "ResPool.h"

using namespace cocos2d;
using namespace cocostudio;
using namespace timeline;

CHPBar::CHPBar(eBarSizeType sizeType, CampType camp, float maxHP, float shield /*= 0*/, float magic /*= 0*/, float rage /*= 0*/)
: m_eSizeType(sizeType)
, m_eCamp(camp)
, m_pCsbHP(nullptr)
, m_pCsbMagic(nullptr)
, m_pCsbRage(nullptr)
, m_pTextName(nullptr)
, m_pBarHP(nullptr)
, m_pBarHPD(nullptr)
, m_pBarShield(nullptr)
, m_pBarMagic(nullptr)
, m_pBarMagicD(nullptr)
, m_pBarRage(nullptr)
, m_pBarRageD(nullptr)
, m_pCsbHPAct(nullptr)

, m_fHP(maxHP)
, m_fMaxHP(maxHP)
, m_fShield(shield)
, m_fMagic(magic)
, m_fRage(rage)

, m_fFinalHPPercent(100)
, m_fFinalShieldPercent(100)
, m_fFinalMagicPercent(magic)
, m_fFinalRagePercent(rage)

, m_fCurHPPercent(100)
, m_fCurHPDPercent(100)
, m_fCurShieldPercent(100)
, m_fCurMagicPercent(magic)
, m_fCurMagicDPercent(magic)
, m_fCurRagePercent(rage)
, m_fCurRageDPercent(rage)

, m_fHPSpeed(0)
, m_fHPDSpeed(0)
, m_fShieldSpeed(0)
, m_fMagicSpeed(0)
, m_fMagicDSpeed(0)
, m_fRageSpeed(0)
, m_fRageDSpeed(0)

, m_fReduceTime(0.2f)
{

}

CHPBar::~CHPBar()
{    
}

CHPBar* CHPBar::create(eBarSizeType sizeType, CampType camp, float maxHP, float shield /*= 0*/, float magic /*= 0*/, float rage /*= 0*/)
{
	CHPBar *bar = new CHPBar(sizeType, camp, maxHP, shield, magic, rage);
	if (bar && bar->init())
	{
		bar->autorelease();
	}
	else
	{
		CC_SAFE_DELETE(bar);
	}
	return bar;
}

bool CHPBar::init()
{
	if (!Node::init())
	{
		return false;
	}
	createCsb();
	initShow();
	scheduleUpdate();
	return true;
}

void CHPBar::onExit()
{
    Node::onExit();
    if (NULL != m_pCsbHP)
    {
        CResPool::getInstance()->freeCsbNode(m_HPPath, m_pCsbHP);
        this->removeChild(m_pCsbHP);
        m_pCsbHP = NULL;
    }
}

void CHPBar::createCsb()
{
	std::string pathSuffix = "S";       // csb文件名后缀
    bool isVisible = false;
    switch (m_eSizeType)
    {
    case kHPRage_m:
    case KHPMagic_m:
    case kHPMagicRage_m:
    case kHP_m:
        pathSuffix = "M";
        break;

    case kHPRage_l:
    case KHPMagic_l:
    case kHPMagicRage_l:
    case kHP_l:
        pathSuffix = "L";
        break;

    case kHPSummoner:
    case kHPMagicSummoner:
    case kHPRageSummoner:
    case kHPMagicRageSummoner:
        pathSuffix = "Summoner";
        isVisible = true;
        break;
    default:
        break;
    }

    // csb文件路径(用来创建csb, 播放动画)
    m_HPPath = String::createWithFormat("ui_new/f_fight/bloodbar/BloodBar_%s.csb", pathSuffix.c_str())->getCString();
    std::string csbPowFile = String::createWithFormat("ui_new/f_fight/bloodbar/MagicAngerBar_%s.csb", pathSuffix.c_str())->getCString();
    // 血条csb
    m_pCsbHP = CResPool::getInstance()->getCsbNode(m_HPPath);
    CHECK_RETURN_VOID(m_pCsbHP);
    this->setVisible(isVisible);
	this->addChild(m_pCsbHP);
    // 血条动画
    m_pCsbHPAct = dynamic_cast<ActionTimeline*>(m_pCsbHP->getActionByTag(m_pCsbHP->getTag()));
    if (NULL == m_pCsbHPAct)
    {
        m_pCsbHPAct = CSLoader::createTimeline(m_HPPath);
        m_pCsbHP->runAction(m_pCsbHPAct);
    }

    // 名字
    m_pTextName = static_cast<Text*>(getChildByPath(m_pCsbHP, "BarPanel/NamePanel/PlayerName"));
    // 血条, 护盾 进度条
    m_pBarHP = static_cast<LoadingBar*>(getChildByPath(m_pCsbHP, "BarPanel/BloodLoadingBar_u"));
    m_pBarHPD = static_cast<LoadingBar*>(getChildByPath(m_pCsbHP, "BarPanel/BloodLoadingBar_d"));
    m_pBarShield = static_cast<LoadingBar*>(getChildByPath(m_pCsbHP, "BarPanel/ShieldLoadingBar"));
	
    // 魔法条和怒气条
    switch (m_eSizeType)
    {
    case kHPRage_s:
    case kHPRage_m:
    case kHPRage_l:
    case kHPRageSummoner:
        m_pCsbMagic = getChildByPath(m_pCsbHP, String::createWithFormat("BarPanel/MagicAngerBar_%s2", pathSuffix.c_str())->getCString());
        m_pCsbRage = getChildByPath(m_pCsbHP, String::createWithFormat("BarPanel/MagicAngerBar_%s", pathSuffix.c_str())->getCString());
        break;

    default:
        m_pCsbMagic = getChildByPath(m_pCsbHP, String::createWithFormat("BarPanel/MagicAngerBar_%s", pathSuffix.c_str())->getCString());
        m_pCsbRage = getChildByPath(m_pCsbHP, String::createWithFormat("BarPanel/MagicAngerBar_%s2", pathSuffix.c_str())->getCString());
        break;
    }
    
    // 魔法, 怒气进度条
    m_pBarMagic = static_cast<LoadingBar*>(getChildByPath(m_pCsbMagic, "BarPanel/MagicLoadingBar_u"));
    m_pBarMagicD = static_cast<LoadingBar*>(getChildByPath(m_pCsbMagic, "BarPanel/MagicLoadingBar_d"));
    m_pBarRage = static_cast<LoadingBar*>(getChildByPath(m_pCsbRage, "BarPanel/AngerLoadingBar_u"));
    m_pBarRageD = static_cast<LoadingBar*>(getChildByPath(m_pCsbRage, "BarPanel/AngerLoadingBar_d"));

    // 魔法条和怒气条动画
    std::string magicActName = "No";    // 魔法条动画(切换显示 空, 魔法 , 怒气)
    std::string rageActName = "No";     // 怒气条动画(切换显示 空, 魔法 , 怒气)
    switch (m_eSizeType)
    {
    case KHPMagic_s:
    case KHPMagic_m:
    case KHPMagic_l:
    case kHPMagicSummoner:
        magicActName = "Magic";
        break;

    case kHPRage_s:
    case kHPRage_m:
    case kHPRage_l:
    case kHPRageSummoner:
        rageActName = "Anger";
        break;

    case kHPMagicRage_s:
    case kHPMagicRage_m:
    case kHPMagicRage_l:
    case kHPMagicRageSummoner:
        magicActName = "Magic";
        rageActName = "Anger";
        break;
    default:
        break;
    }

    ActionTimeline* csbMagicAct = static_cast<ActionTimeline*>(m_pCsbMagic->getActionByTag(m_pCsbMagic->getTag()));
    ActionTimeline* csbRageAct = static_cast<ActionTimeline*>(m_pCsbRage->getActionByTag(m_pCsbRage->getTag()));
    if (NULL == csbMagicAct)
    {
        csbMagicAct = CSLoader::createTimeline(csbPowFile);
        csbMagicAct->setTag(m_pCsbMagic->getTag());
        m_pCsbMagic->runAction(csbMagicAct);
    }
    if (NULL == csbRageAct)
    {
        csbRageAct = CSLoader::createTimeline(csbPowFile);
        csbRageAct->setTag(m_pCsbRage->getTag());
        m_pCsbRage->runAction(csbRageAct);
    }

    csbMagicAct->play(magicActName, false);
    csbRageAct->play(rageActName, false);

    // 播放动画
	ChangeCamp(m_eCamp);
    setName("");
}

void CHPBar::initShow()
{
	countHPShieldFinal();
	setHPPercent(m_fFinalHPPercent);
	setHPDPercent(m_fFinalHPPercent);
    setShieldPercent(m_fFinalShieldPercent);
    setMagicPercent(m_fFinalMagicPercent);
    setMagicDPercent(m_fFinalMagicPercent);
    setRagePercent(m_fFinalRagePercent);
    setRageDPercent(m_fFinalRagePercent);
}

void CHPBar::update(float dt)
{
	setPercentBySpeed(m_pBarHP, m_fFinalHPPercent, m_fCurHPPercent, m_fHPSpeed, dt);
	setPercentBySpeed(m_pBarHPD, m_fFinalHPPercent, m_fCurHPDPercent, m_fHPDSpeed, dt);
    setPercentBySpeed(m_pBarShield, m_fFinalShieldPercent, m_fCurShieldPercent, m_fShieldSpeed, dt);
    setPercentBySpeed(m_pBarMagic, m_fFinalMagicPercent, m_fCurMagicPercent, m_fMagicSpeed, dt);
    setPercentBySpeed(m_pBarMagicD, m_fFinalMagicPercent, m_fCurMagicDPercent, m_fMagicDSpeed, dt);
    setPercentBySpeed(m_pBarRage, m_fFinalRagePercent, m_fCurRagePercent, m_fRageSpeed, dt);
    setPercentBySpeed(m_pBarRageD, m_fFinalRagePercent, m_fCurRageDPercent, m_fRageDSpeed, dt);
}

void CHPBar::setHP(float hp)
{
	boundValue(hp, 0, m_fMaxHP);
	if (m_fHP == hp)
	{
		return;
	}
    this->setVisible(true);

	bool isAddHp = hp > m_fHP ? true : false;
	m_fHP = hp;
	countHPShieldFinal();
	if (isAddHp)
	{
		m_fHPSpeed = (m_fFinalHPPercent - m_fCurHPPercent) / m_fReduceTime;
		m_fHPDSpeed = (m_fFinalHPPercent - m_fCurHPDPercent) / m_fReduceTime;
		m_fShieldSpeed = (m_fFinalShieldPercent - m_fCurShieldPercent) / m_fReduceTime;
	}
	else
	{
		setHPPercent(m_fFinalHPPercent);
		setShieldPercent(m_fFinalShieldPercent);
		m_fHPSpeed = 0;
		m_fHPDSpeed = (m_fFinalHPPercent - m_fCurHPDPercent) / m_fReduceTime;
		m_fShieldSpeed = (m_fFinalShieldPercent - m_fCurShieldPercent) / m_fReduceTime;
	}
}

// void CHPBar_::setMaxHP(float maxHP)
// {
// 
// }

void CHPBar::setShield(float shield)
{
	boundValue(shield, 0);
	if (m_fShield == shield)
	{
		return;
	}
    this->setVisible(true);
	bool isAddShield = shield > m_fShield ? true : false;
	if (isAddShield)
	{
		m_fShield = shield;
		countHPShieldFinal();
		m_fHPSpeed = (m_fFinalHPPercent - m_fCurHPPercent) / m_fReduceTime;
		m_fHPDSpeed = (m_fFinalHPPercent - m_fCurHPDPercent) / m_fReduceTime;
		m_fShieldSpeed = (m_fFinalShieldPercent - m_fCurShieldPercent) / m_fReduceTime;
	}else
	{
		if (m_fShield == 0)
		{
			m_fShield = shield;
			countHPShieldFinal();
			setHPPercent(m_fFinalHPPercent);
			setShieldPercent(m_fFinalShieldPercent);
			m_fHPSpeed = 0;
			m_fHPDSpeed = (m_fFinalHPPercent - m_fCurHPDPercent) / m_fReduceTime;
			m_fShieldSpeed = 0;
		}else
		{
			setShieldPercent(m_fFinalHPPercent + (m_fFinalShieldPercent - m_fFinalHPPercent)*shield / m_fShield);
			m_fShield = shield;
			countHPShieldFinal();
			m_fHPSpeed = (m_fFinalHPPercent - m_fCurHPPercent) / m_fReduceTime;
			m_fHPDSpeed = (m_fFinalHPPercent - m_fCurHPDPercent) / m_fReduceTime;
			m_fShieldSpeed = (m_fFinalShieldPercent - m_fCurShieldPercent) / m_fReduceTime;
		}
	}
}

void CHPBar::setMagic(float magic)
{
    boundValue(magic, 0, 100);
    if (m_fMagic == magic)
    {
        return;
    }
    this->setVisible(true);
    bool isAddPow = magic > m_fMagic ? true : false;
    m_fMagic = magic;
    m_fFinalMagicPercent = m_fMagic;
    if (isAddPow)
    {
        m_fMagicSpeed = (m_fFinalMagicPercent - m_fCurMagicPercent) / m_fReduceTime;
        m_fMagicDSpeed = (m_fFinalMagicPercent - m_fCurMagicPercent) / m_fReduceTime;
    }
    else
    {
        setMagicPercent(m_fFinalMagicPercent);
        m_fMagicSpeed = 0;
        m_fMagicDSpeed = (m_fFinalMagicPercent - m_fCurMagicDPercent) / m_fReduceTime;
    }
}

void CHPBar::setRage(float rage)
{
    boundValue(rage, 0, 100);
    if (m_fRage == rage)
    {
        return;
    }
    this->setVisible(true);
    bool isAddPow = rage > m_fRage ? true : false;
    m_fRage = rage;
    m_fFinalRagePercent = m_fRage / 100 * 100;
    if (isAddPow)
    {
        m_fRageSpeed = (m_fFinalRagePercent - m_fCurRagePercent) / m_fReduceTime;
        m_fRageDSpeed = (m_fFinalRagePercent - m_fCurRagePercent) / m_fReduceTime;
    }
    else
    {
        setRagePercent(m_fFinalRagePercent);
        m_fRageSpeed = 0;
        m_fRageDSpeed = (m_fFinalRagePercent - m_fCurRageDPercent) / m_fReduceTime;
    }
}


void CHPBar::setName(std::string name)
{
	if (m_pTextName)
	{
        if ("" == name)
        {
            m_pTextName->setVisible(false);
        }
        else
        {
            m_pTextName->setString(name);
            m_pTextName->setVisible(false);
        }
	}
}

void CHPBar::ChangeCamp(CampType camp)
{
    // 判断是否反转
    CBattleHelper* pBattleHelper = CGame::getInstance()->BattleHelper;
    if (pBattleHelper)
    {
        if (pBattleHelper->getMasterId() != pBattleHelper->getUserId())
        {
            if (ECamp_Blue == camp)
            {
                camp = ECamp_Red;
            }
            else if (ECamp_Red == camp)
            {
                camp = ECamp_Blue;
            }
            setScaleX(-1);
        }
    }

	if (m_pCsbHPAct)
	{
        m_eCamp = camp;
		switch (m_eCamp)
		{
		case ECamp_Neutral:
			m_pCsbHPAct->play("Neutral", false);
			break;
		case ECamp_Blue:
			m_pCsbHPAct->play("Your", false);
			break;
		case ECamp_Red:
			m_pCsbHPAct->play("Enemy", false);
			break;
		default:
			break;
		}
	}
}

void CHPBar::setReduceTime(float dt)
{
	m_fReduceTime = dt;
}

void CHPBar::setBarPercent(LoadingBar* bar, const float& percent, float& curPercent)
{
	assert(bar && percent >= 0 && percent <= 100);
	if (bar)
	{
		if (percent >= 0 && percent <= 100)
		{
			bar->setPercent(percent);
			curPercent = percent;
		}
	}
}

void CHPBar::setHPPercent(float percent)
{
	setBarPercent(m_pBarHP, percent, m_fCurHPPercent);
}

void CHPBar::setHPDPercent(float percent)
{
	setBarPercent(m_pBarHPD, percent, m_fCurHPDPercent);
}

void CHPBar::setShieldPercent(float percent)
{
	setBarPercent(m_pBarShield, percent, m_fCurShieldPercent);
}

void CHPBar::setMagicPercent(float percent)
{
    setBarPercent(m_pBarMagic, percent, m_fCurMagicPercent);
}

void CHPBar::setMagicDPercent(float percent)
{
    setBarPercent(m_pBarMagicD, percent, m_fCurMagicDPercent);
}

void CHPBar::setRagePercent(float percent)
{
    setBarPercent(m_pBarRage, percent, m_fCurRagePercent);
}

void CHPBar::setRageDPercent(float percent)
{
    setBarPercent(m_pBarRageD, percent, m_fCurRageDPercent);
}


void CHPBar::boundValue(float& value, float minValue /*= 0*/, float maxValue /*= 0*/)
{
	if (value < minValue)
	{
		value = minValue;
	}else if (maxValue != 0 && value > maxValue)
	{
		value = maxValue;
	}
}

void CHPBar::countHPShieldFinal()
{
	if (m_fHP + m_fShield >= m_fMaxHP)
	{
		m_fFinalHPPercent = m_fHP / (m_fHP + m_fShield) * 100;
		m_fFinalShieldPercent = 100;
	}else
	{
		m_fFinalHPPercent = m_fHP / m_fMaxHP * 100;
		m_fFinalShieldPercent = m_fShield / m_fMaxHP * 100 + m_fFinalHPPercent;
	}
}
