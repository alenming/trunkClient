#include "RoleDisplayComponent.h"
#include "EffectFactory.h"
#include "KxLog.h"
#include "UIEffect.h"
#include "ConfOther.h"
#include "ConfLanguage.h"
#include "DisplayCommon.h"
#include "FMODAudioEngine.h"
#include "BlinkAction.h"
#include "GameComm.h"
#include "Game.h"
#include "ResPool.h"
#include "ResManager.h"
#include "TipBloodNode.h"

using namespace cocostudio;
using namespace timeline;

using namespace ui;
using namespace std;

static bool isvisible = false;
static int changetick = 0;

CRoleDisplayComponent::CRoleDisplayComponent()
: m_pHpBar(NULL)
{
    _name = "CRoleDisplayComponent";
}

CRoleDisplayComponent::~CRoleDisplayComponent()
{
	removePreEffects();
    stopPreMusics();
}

bool CRoleDisplayComponent::init(CRole* role, CAnimateComponent* animate, CRoleComponent* state)
{
	m_pArmatureCom = animate;
    m_pRoleCom = state;
	m_pRole = role;
    m_fDuration = 0.0f;
    m_fDelta = 0.0f;
	
	CHECK_RETURN(NULL != m_pRole);
	CHECK_RETURN(NULL != m_pArmatureCom);
	m_pArmatureCom->setFlipX(role->getDirection() != 1);

	CHECK_RETURN(NULL != m_pRoleCom);
    m_nAnimateId = m_pRole->getIntAttribute(EAttributeAnimationId);

    m_nState = State_None;//m_pRoleCom->getStateId();
    m_PlaySpeed = role->getFloatAttribute(EAttributeAttackSpeedVar);
    m_pRole->setCascadeColorEnabled(true);

    initHpBar();
    initDebug();
    //changeAnimate();
	return true;
}

void CRoleDisplayComponent::update(float delta)
{
    m_pArmatureCom->setFlipX(m_pRole->getDirection() != 1);

    // 当"变羊"的时候，Role的EAttributeAnimationID会改变
    if (m_nAnimateId != m_pRole->getIntAttribute(EAttributeAnimationId))
    {
        // 如果切换了其它形象，要重新创建骨骼动画
        m_nAnimateId = m_pRole->getIntAttribute(EAttributeAnimationId);

        // 先转换出完整路径
		const SResPathItem* pResInfo = queryConfSResInfo(m_nAnimateId);
        if (pResInfo != NULL)
        {
            m_pArmatureCom->initAnimate(pResInfo->Path);
            m_nState = State_None;
        }
        else
        {
#if (CC_PLATFORM_WIN32 == CC_TARGET_PLATFORM)
            if (CGame::getInstance()->isDebug())
            {
                cocos2d::MessageBox("Fuck大策划！你忘记在ResPath里面配Csb资源了，资源名看LOG", "Fuck");
                //CCLOG("AnimateId %d", m_nAnimateId);
            }
#endif
        }
    }

    if (m_nState != m_pRoleCom->getStateId())
    {
        // 如果状态切换了，需要播放新的动画
        m_nState = m_pRoleCom->getStateId();
        changeAnimate();
    }

    // 当位置不一样时获取新的目标位置，并计算偏移
    if (m_TargetPos != m_pRole->getRealPosition())
    {
        m_TargetPos = m_pRole->getRealPosition();
        m_Offset = m_TargetPos - m_pRole->getPosition();
    }

    if (m_Offset != Vec2::ZERO)
    {
        // 如果卡顿，delta会变大，有可能超过
		delta = delta / dynamic_cast<CBattleLayer*>(m_pRole->getParent())->getTickDelta();
        Vec2 newPos = m_pRole->getPosition() + m_Offset * delta;
        if ((m_Offset.x > 0 && newPos.x > m_TargetPos.x)
            || (m_Offset.x < 0 && newPos.x < m_TargetPos.x))
        {
            newPos.x = m_TargetPos.x;
        }
        if ((m_Offset.y > 0 && newPos.y > m_TargetPos.y)
            || (m_Offset.y < 0 && newPos.y < m_TargetPos.y))
        {
            newPos.y = m_TargetPos.y;
        }
        m_pRole->setPosition(newPos);
    }

    float newSpeed = getCurPlaySpeed();
    if (newSpeed != m_PlaySpeed)
    {
        m_PlaySpeed = newSpeed;
        m_pArmatureCom->setAnimateSpeed(m_PlaySpeed);
        // 调整特效播放速度
        for (std::vector<CEffect*>::iterator iter = m_vEffectNode.begin();
            iter != m_vEffectNode.end(); ++iter)
        {
            auto effConf = (*iter)->getConf();
            if (NULL != effConf)
            {
                const StatusConfItem* conf = m_pRoleCom->getStateConf();
                if (NULL != conf && conf->SpeedAffect == effConf->SpeedAffect)
                {
                    (*iter)->setAnimateSpeed(m_PlaySpeed);
                }
            }
        }
    }

    // 关于血条的位置更新
    bool isChange = false;
    CampType camp = (CampType)m_pRole->getIntAttribute(EAttributeCamp);
    if (m_pRole->getIntAttribute(EAttributeHPPosX) != (int) m_HpBarOffset.x
        || m_pRole->getIntAttribute(EAttributeHPPosY) != (int) m_HpBarOffset.y)
    {
        isChange = true;
    }

    if (camp != m_pHpBar->getCamp())
    {
        // 阵营变更,血条显示更改
        m_pHpBar->ChangeCamp(camp);
        isChange = true;
    }

    if (isChange)
    {
        m_HpBarOffset = Vec2(m_pRole->getIntAttribute(EAttributeHPPosX), m_pRole->getIntAttribute(EAttributeHPPosY));
        Vec2 classPostion = Vec2(m_pRole->getIntAttribute(EClassHPPosX), m_pRole->getIntAttribute(EClassHPPosY));
        m_pHpBar->setPosition(classPostion + m_HpBarOffset);
        m_pHpBar->setPositionX(m_pHpBar->getPositionX() * m_pRole->getDirection());
    }
}

void CRoleDisplayComponent::changeAnimate()
{
    const StatusConfItem* conf = m_pRoleCom->getStateConf();
    if (NULL != conf)
    {
        //LOG("Play Animate %s", conf->AnimationTag.c_str());
        m_pArmatureCom->playAnimate(conf->AnimationTag, conf->AnimationLoop);
        m_pArmatureCom->setAlpha(conf->AnimationTransparency * 255);
        //m_pArmatureCom->setColor(conf->AnimationRGB);
        m_pArmatureCom->setHue(conf->hue);

        if (conf->AnimationFadeOut > 0)
        {
            // 角色身上所有的内容都需要淡出（等待——淡出）
            m_pRole->setCascadeOpacityEnabled(true);
            // 所有子节点
            for (auto &node : m_pRole->getChildren())
            {
                node->setCascadeOpacityEnabled(true);
            }
            Sequence* act = Sequence::createWithTwoActions(
                DelayTime::create(conf->AnimationFadeOut), FadeOut::create(2.0f));
            act->setTag(DEATH_ACT_TAG);
            m_pRole->runAction(act);
        }

        Node* root = m_pRole->getDisplayNode();
        Vec2 pos = Vec2::ZERO;
        int zorder = 0;
        if (!conf->IsFollow)
        {
            pos = m_pRole->getPosition();
            root = m_pRole->getBattleHelper()->getBattleScene();
            zorder = m_pRole->getLocalZOrder();
        }
		removePreEffects();
        stopPreMusics();

        // 批量播放特效
        switch (conf->EffectPlayType)
        {
            // 不播放特效
        case StatusEff_None:
            break;

            // 头部播放特效
        case StatusEff_Head:
            createEffects(root, conf->EffectIds, zorder, 0.0f, m_pRole->getBaseHeadOffset() + pos);
            break;

            // 受击点播放特效
        case StatusEff_Body:
            createEffects(root, conf->EffectIds, zorder, 0.0f, m_pRole->getBaseHitOffset() + pos);
            break;

            // 移动中性点播放特效
        case StatusEff_Leg:
            createEffects(root, conf->EffectIds, zorder, 0.0f, pos);
            break;

        default:
            break;
        }

        // 音效和播放速度相关
        if (conf->MusicInfos.size() > 0)
        {
            for (unsigned int i = 0; i < conf->MusicInfos.size(); ++i)
            {
                const MusicInfo& info = conf->MusicInfos[i];
                float delay = info.MusicDelay * getCurPlaySpeed() / m_PlaySpeed;
                int musicId = playMusic(info.MusicId, delay, info.Volume, info.Track, m_pRole);
                if (musicId > 0 && info.IsClose)
                {
                    m_vMusics.push_back(musicId);
                }
            }
        }

        // 播放UI特效
		CUIEffectManager::getInstance()->execute(conf->UIEffectID, m_pRole->getPosition());
    }
}

Node* CRoleDisplayComponent::getMainAnimate()
{
    if (m_pArmatureCom)
    {
        return m_pArmatureCom->getDisplayNode();
    }
    return nullptr;
}

void CRoleDisplayComponent::playCountEffect(eHurtType hurtType, int hurtValue)
{
    // 死亡状态不再更新血条
    if (m_pRole->getRoleComponent() == NULL
        || m_pRole->getRoleComponent()->getStateId() == State_Death)
    {
        return;
    }

    // 更新当前血量标签（按空格键出现的标签）
    auto hpLabel = dynamic_cast<cocos2d::Label*>(m_pRole->getChildByTag(6));
    if (hpLabel)
    {
        hpLabel->setString(std::string("hp:") + toolToStr(m_pRole->getIntAttribute(EAttributeHP)));
    }

    // 准备变量
    auto mainAni = m_pArmatureCom->getMainAnimate();
    std::string animationName = "";
    std::string text = "";

    // 根据伤害类型判断闪红闪白以及要播放的血量数字动画
    switch (hurtType)
    {
    case kUnCrit:
        animationName = "MinusHP";
        text = "-" + toolToStr(hurtValue);
        if (mainAni && mainAni->getActionByTag(6666666) == nullptr)
        {
            BlinkAction* blink = BlinkAction::create(mainAni, Color3B::WHITE);
            blink->setTag(6666666);
            mainAni->runAction(blink);
        }
        break;
    case kCrit:
        animationName = "Crit";
        text = getLanguageString(CONF_UI_LAN, 548) + string(" -") + toolToStr(hurtValue);
        if (mainAni && mainAni->getActionByTag(6666666) == nullptr)
        {
            auto blink = BlinkAction::create(mainAni, Color3B::RED);
            blink->setTag(6666666);
            mainAni->runAction(blink);
        }
        break;
    case kAddBlood:
        animationName = "AddHP";
        text = getLanguageString(CONF_UI_LAN, 535) + string(" +") + toolToStr(hurtValue);
        break;
    case kMiss:
        animationName = "Miss";
        text = getLanguageString(CONF_UI_LAN, 547);
        break;
    default:
        break;
    }

    // 播放血量数字动画
    while (!animationName.empty())
    {
		Node* csb = TipBloodNode::getInstance()->getCsb(text, animationName);
		CHECK_BREAK(csb);
        //csb->setPosition(m_pRole->getHitOffset());
        // 判断是否翻转
        if (m_pRole->getBattleHelper()->getMasterId() != m_pRole->getBattleHelper()->getUserId())
        {
            csb->setScaleX(-1);
        }
		m_pRole->addChild(csb);
        break;
    }

    if (hurtValue != 0)
    {
        // 刷新血条
        updateHpBar();
    }
}

void CRoleDisplayComponent::initHpBar()
{
    //添加血条
    int magic = 0;
    int rage = 0;
    if (m_pRole->getIntAttribute(EAttributeMaxMP) != 0)
        magic = m_pRole->getIntAttribute(EAttributeMP) / m_pRole->getIntAttribute(EAttributeMaxMP) * 100;
    if (m_pRole->getIntAttribute(EAttributeMaxRage) != 0)
        rage = m_pRole->getIntAttribute(EAttributeRage) / m_pRole->getIntAttribute(EAttributeMaxRage) * 100;

    m_pHpBar = CHPBar::create(
        (eBarSizeType)m_pRole->getIntAttribute(EClassHPLine),
        (CampType)m_pRole->getIntAttribute(EAttributeCamp),
        m_pRole->getIntAttribute(EAttributeMaxHP),
        m_pRole->getIntAttribute(EAttributeExtraHP),
        magic,
        rage);
    m_pRole->addChild(m_pHpBar, 10, 100);
	m_pHpBar->setPosition(m_pRole->getIntAttribute(EClassHPPosX), m_pRole->getIntAttribute(EClassHPPosY));
    m_pHpBar->setPositionX(m_pHpBar->getPositionX() * m_pRole->getDirection());
    updateHpBar();
}

void CRoleDisplayComponent::updateHpBar()
{
    if (m_pHpBar)
    {
        m_pHpBar->setHP(m_pRole->getIntAttribute(EAttributeHP));
        m_pHpBar->setShield(m_pRole->getIntAttribute(EAttributeExtraHP));

        if (m_pRole->getIntAttribute(EAttributeMaxMP) != 0)
            m_pHpBar->setMagic((float)m_pRole->getIntAttribute(EAttributeMP)
                / m_pRole->getIntAttribute(EAttributeMaxMP) * 100);
        if (m_pRole->getIntAttribute(EAttributeMaxRage) != 0)
            m_pHpBar->setRage((float)m_pRole->getIntAttribute(EAttributeRage)
                / m_pRole->getIntAttribute(EAttributeMaxRage) * 100);
    }
}

void CRoleDisplayComponent::initDebug()
{
    if (!CGame::getInstance()->isDebug())
    {
        return;
    }
    auto p1 = Sprite::create("123.png");
    p1->setName("RED");
    p1->setColor(Color3B::RED);
    p1->setPosition(m_pRole->getFireOffset().x, m_pRole->getFireOffset().y);
    p1->setScale(0.12f);
    m_pRole->getDisplayNode()->addChild(p1, 1, 1);

    p1 = Sprite::create("123.png");
    p1->setName("GREEN");
    p1->setColor(Color3B::GREEN);
    p1->setPosition(m_pRole->getHeadOffset().x, m_pRole->getHeadOffset().y);
    p1->setScale(0.11f);
    m_pRole->getDisplayNode()->addChild(p1, 1, 2);

    p1 = Sprite::create("123.png");
    p1->setName("BLUE");
    p1->setColor(Color3B::BLUE);
    p1->setPosition(m_pRole->getHitOffset().x, m_pRole->getHitOffset().y);
    p1->setScale(0.1f);
    m_pRole->getDisplayNode()->addChild(p1, 1, 3);

    p1 = Sprite::create("123.png");
    p1->setName("BLACK");
    p1->setColor(Color3B::BLACK);
    p1->setPosition(Vec2::ZERO);
    p1->setScale(0.09f);
    m_pRole->getDisplayNode()->addChild(p1, 1, 4);

    auto id = Label::create();
    id->setName("IDLabel");
    id->setString(string("id:") + toolToStr(m_pRole->getObjectId()));
    id->setColor(Color3B::BLACK);
    id->setSystemFontSize(25);
    id->setPosition(m_pRole->getHeadOffset().x, m_pRole->getHeadOffset().y + 20);
    m_pRole->getDisplayNode()->addChild(id, 1, 5);

    auto hp = Label::create();
    hp->setName("HPLabel");
    hp->setString(string("hp:") + toolToStr(m_pRole->getIntAttribute(EAttributeHP)));
    hp->setColor(Color3B::RED);
    hp->setSystemFontSize(25);
    hp->setPosition(m_pRole->getHeadOffset().x, m_pRole->getHeadOffset().y + 40);
    m_pRole->getDisplayNode()->addChild(hp, 1, 6);

    for (int i = 1; i < 7; ++i)
    {
        m_pRole->getDisplayNode()->getChildByTag(i)->setVisible(isvisible);
    }

    EventListenerKeyboard* kbL = EventListenerKeyboard::create();
    kbL->onKeyReleased = [this](EventKeyboard::KeyCode code, Event* ev)->void
    {
        if (code == EventKeyboard::KeyCode::KEY_SPACE)
        {
            if (changetick != m_pRole->getBattleHelper()->GameTick)
            {
                changetick = m_pRole->getBattleHelper()->GameTick;
                isvisible = !isvisible;
            }

            for (int i = 1; i < 7; ++i)
            {
                m_pRole->getDisplayNode()->getChildByTag(i)->setVisible(isvisible);
            }
        }
    };
    m_pRole->getDisplayNode()->getEventDispatcher()->addEventListenerWithSceneGraphPriority(kbL, m_pRole->getDisplayNode());
}

bool CRoleDisplayComponent::createEffects(Node* root, const VecInt& effIds, int zorder, float delay /*= 0.0f*/, cocos2d::Vec2 pos /*= Vec2::ZERO*/)
{
    if (NULL == root || NULL == m_pRole|| effIds.size() == 0)
	{
		return false;
	}

	for (auto iter : effIds)
	{
        auto eff = CEffectFactory::create(iter, m_pRole->getDirection(), zorder, delay);
        float effScale = m_pRole->getFloatAttribute(EAttributeTypes::EAttributeEffectScale);
		if (NULL == eff)
		{
			return false;
		}

        eff->setScaleX(effScale * eff->getScaleX());
        eff->setScaleY(effScale * eff->getScaleY());
		if (root == m_pRole->getDisplayNode())
        {
            SAFE_RETAIN(eff);
			m_vEffectNode.push_back(eff);
		}
		eff->setPosition(pos);
        root->addChild(eff);
	}

	return true;
}

void CRoleDisplayComponent::removePreEffects()
{
	for (std::vector<CEffect*>::iterator iter = m_vEffectNode.begin();
        iter != m_vEffectNode.end(); ++iter)
	{
        Node* node = *iter;
        if (node->isRunning())
        {
            (*iter)->removeFromParent();
        }
		SAFE_RELEASE((*iter));
	}
	m_vEffectNode.clear();
}

void CRoleDisplayComponent::stopPreMusics()
{
    for (auto& musicId : m_vMusics)
    {
//#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
//        SimpleAudioEngine::getInstance()->stopEffect(musicId);
//#else
//        experimental::AudioEngine::stop(musicId);
//#endif
        CFMODAudioEngine::getInstance()->stopEffect(musicId);
    }

    m_vMusics.clear();
}

float CRoleDisplayComponent::getCurPlaySpeed()
{
    float newSpeed = m_PlaySpeed;
    const StatusConfItem* conf = m_pRoleCom->getStateConf();
    if (NULL != conf)
    {
        newSpeed = 1.0f;
        switch (conf->SpeedAffect)
        {
        case StatusSpeed_Attack:
            newSpeed = m_pRole->getFloatAttribute(EAttributeAttackSpeedVar);
            break;
        case StatusSpeed_Move:
            newSpeed = (m_pRole->getIntAttribute(EAttributeSpeed) * 1.0f)
                / (m_pRole->getIntAttribute(EClassSpeed) * 1.0f);
            break;
        case StatusSpeed_MPRecover:
            newSpeed = (m_pRole->getIntAttribute(EAttributeMPRecover) * 1.0f)
                / m_pRole->getIntAttribute(EClassMPRecover);
            break;
        }
        newSpeed *= conf->AnimationSpeed;
    }

    return newSpeed;
}