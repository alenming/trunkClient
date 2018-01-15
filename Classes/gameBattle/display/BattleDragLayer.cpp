#include "BattleDragLayer.h"
#include "Game.h"
#include "Events.h"
#include "Protocol.h"
#include "BattleProtocol.h"
#include "Hero.h"
#include "UIEffect.h"
#include "DisplayCommon.h"
#include "ConfGuide.h"
#include "ConfLanguage.h"
#include "ResManager.h"

USING_NS_CC;

CStageSetLayer::CStageSetLayer()
: m_fBattleScreen(0.0f)
, m_fStageScreen(0.0f)
{
}

CStageSetLayer::~CStageSetLayer()
{
}

bool CStageSetLayer::initWithFile(const std::string &csbFile, float battleScreen, float stageScreen)
{
    //std::string szFullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    //auto bg = cocos2d::CSLoader::createNode(szFullPath);
    auto bg = CResManager::getInstance()->getCsbNode(csbFile);
    if (NULL == bg)
    {
        return false;
    }

    bg->setAnchorPoint(Vec2(0, 0));
    addChild(bg);
    bg->setPosition(Vec2(0, 0));

    m_fBattleScreen = battleScreen;
    m_fStageScreen = stageScreen;
    return true;
}

void CStageSetLayer::dragMove(float x)
{
    float moveX = m_fStageScreen / m_fBattleScreen * x;
    setPositionX(getPositionX() + moveX);
}

CBattleDragLayer::CBattleDragLayer() 
: m_bMoveDisable(false)
, m_bIsMove(false)
, m_bIsScaling(false)
, m_nSkillIndex(0)
, m_nNextCarmeraId(0)
, m_fCarmeraTime(0.0f)
, m_fMoveTime(0.0f)
, m_fScaleTime(0.0f)
, m_fScalePerSceond(0.0f)
, m_fMovePerSceond(0.0f)
, m_fCurCameraPosX(0.0f)
, m_fBattleScreen(0.0f)
, m_fMinPosX(0.0f)
, m_fRealScreenWidth(0.0f)
, m_fMaxScreenHeight(0.0f)
, m_fOffsetY(0.0f)
, m_pBattleLayer(NULL)
, m_pProspectLayer(NULL)
, m_pBackgroundLayer(NULL)
, m_pBattleBgLayer(NULL)
, m_pForegroundLayer(NULL)
, m_StandViewSize()
, m_CameraFinishCallback(nullptr)
, m_SkillRange(NULL)
, m_SkillScreen(NULL)
, m_fTouchPosX(0.0f)
{
}

CBattleDragLayer::~CBattleDragLayer()
{
}

bool CBattleDragLayer::init(int stageId, Node *parent, Node *battle)
{
    if (NULL == parent || NULL == battle)
    {
        return false;
    }

	m_pParent = parent;
    m_pBattleLayer = battle;
    m_ScreenCenter = Director::getInstance()->getWinSize() * 0.5f;
    m_ParentOriginPos = m_pParent->getPosition();
    // 注册技能释放事件
    CGame::getInstance()->EventMgr->addEventHandle(BattleEventTouchReleaseSkill,
        this, CALLBACK_FUNCV(CBattleDragLayer::onSkillReleaseEvent));
    CGame::getInstance()->EventMgr->addEventHandle(BattleEventTouchCancelSkill,
        this, CALLBACK_FUNCV(CBattleDragLayer::onSkillCancelEvent));

	auto listener1 = EventListenerTouchAllAtOnce::create();
	listener1->onTouchesBegan = CC_CALLBACK_2(CBattleDragLayer::onTouchesBegan, this);
	listener1->onTouchesMoved = CC_CALLBACK_2(CBattleDragLayer::onTouchesMoved, this);
	listener1->onTouchesEnded = CC_CALLBACK_2(CBattleDragLayer::onTouchesEnded, this);
	listener1->onTouchesCancelled = CC_CALLBACK_2(CBattleDragLayer::onTouchesEnded, this);
	_eventDispatcher->addEventListenerWithSceneGraphPriority(listener1, this);

    const StageConfItem *pStageConf = queryConfStage(stageId);
    const StageSceneConfItem *pStageSceneConf = queryConfStageScene(pStageConf->StageSenceID);
	m_StandViewSize = Size(960, 640);
	Size battleSize = Size(pStageSceneConf->FightScene_Size * m_StandViewSize.width, m_StandViewSize.height);
	//真实的屏幕宽度, 已根据960*640的比例与真实的比例进行计算后的结果
	m_fRealScreenWidth = Director::getInstance()->getWinSize().width;
	//最大的高度为标准高度的2倍则1280
	m_fMaxScreenHeight = 1280.0f;	
	m_fOffsetY = -1 * (m_fMaxScreenHeight - m_StandViewSize.height) / 2;
    
    // 战斗层与战斗背景相同速度
    m_fBattleScreen = pStageSceneConf->FightScene_Size;
	m_bMoveDisable = false;
	m_fMinPosX = m_StandViewSize.width - battleSize.width;
    //添加远景层
    m_pProspectLayer = new CStageSetLayer();
    m_pProspectLayer->initWithFile(pStageSceneConf->FarScene_ccs, m_fBattleScreen, pStageSceneConf->FarScene_Size);
    m_pProspectLayer->setName("ProspectLayer ");
    //updateGrobleZOrder(m_pProspectLayer, LZ_PROSPECT);
	parent->addChild(m_pProspectLayer, SLZ_PROSPECT, BLT_PROSPECT);
    m_pProspectLayer->release();

    //添加背景层
    m_pBackgroundLayer = new CStageSetLayer();
    m_pBackgroundLayer->initWithFile(pStageSceneConf->BgScene_ccs, m_fBattleScreen, pStageSceneConf->BgScene_Size);
    m_pBackgroundLayer->setName("BackgroundLayer ");
    //updateGrobleZOrder(m_pBackgroundLayer, LZ_BACKGROUND);
	parent->addChild(m_pBackgroundLayer, SLZ_BACKGROUND, BLT_BACKGROUND);
    m_pBackgroundLayer->release();

    //添加战斗背景层
    m_pBattleBgLayer = new CStageSetLayer();
    m_pBattleBgLayer->initWithFile(pStageSceneConf->FightScene_ccs, m_fBattleScreen, pStageSceneConf->FightScene_Size);
    m_pBattleBgLayer->setName("BattleBgLayer ");
    //updateGrobleZOrder(m_pBattleBgLayer, LZ_BATTLEBG);
    parent->addChild(m_pBattleBgLayer, SLZ_BATTLEBG, BLT_BATTLEBG);
    m_pBattleBgLayer->release();

	//添加前景层
    m_pForegroundLayer = new CStageSetLayer();
    m_pForegroundLayer->initWithFile(pStageSceneConf->FrontScene_ccs, m_fBattleScreen, pStageSceneConf->FrontScene_Size);
    m_pForegroundLayer->setName("ForegroundLayer ");
    //updateGrobleZOrder(m_pForegroundLayer, LZ_FOREGRUND);
	parent->addChild(m_pForegroundLayer, SLZ_FOREGRUND, BLT_FOREGRUND);
    m_pForegroundLayer->release();

    // 窗口对准正中位置
	m_pBattleBgLayer->setPosition(Vec2(0, m_fOffsetY));
	m_pProspectLayer->setPosition(Vec2(0, m_fOffsetY));
	m_pBackgroundLayer->setPosition(Vec2(0, m_fOffsetY));
	m_pForegroundLayer->setPosition(Vec2(0, m_fOffsetY));
	m_pBattleLayer->setAnchorPoint(Vec2(0, 0));
    // 计算最小缩放值
	m_fMinScale = m_fRealScreenWidth / battleSize.width;
    if (m_fMinScale < 0.5f) {
        m_fMinScale = 0.5f;
    }
    // 处理反转
    CBattleHelper *helper = CGame::getInstance()->BattleHelper;
    if (helper->getUserId() != helper->getMasterId())
    {
		// 如果玩家在右边, 视角拖到最右边
        //dragMove(m_fMinPosX);
		m_pBattleLayer->setScaleX(-1);
		m_pBattleLayer->setPosition(Vec2(pStageSceneConf->RedHeroPos + pStageSceneConf->BlueHeroPos, m_fOffsetY));
    }
	else
	{
		m_pBattleLayer->setPosition(Vec2(0, m_fOffsetY));
	}

    if (CGame::getInstance()->isDebug())
    {
        EventListenerKeyboard* kbListener = EventListenerKeyboard::create();
        kbListener->onKeyPressed = [this](EventKeyboard::KeyCode code, Event* event){
            static int uiid = 1;
            float timescale = Director::getInstance()->getScheduler()->getTimeScale();
            if (timescale < 0.2f)
            {
                timescale = 0.2f;
            }
            switch (code)
            {
            case cocos2d::EventKeyboard::KeyCode::KEY_F1:
                Director::getInstance()->getScheduler()->setTimeScale(1.0f);
                break;
            case cocos2d::EventKeyboard::KeyCode::KEY_F2:
                Director::getInstance()->getScheduler()->setTimeScale(timescale + 0.2f);
                break;
            case cocos2d::EventKeyboard::KeyCode::KEY_F3:
                Director::getInstance()->getScheduler()->setTimeScale(timescale - 0.2f);
                break;
            case cocos2d::EventKeyboard::KeyCode::KEY_F4:
                Director::getInstance()->getScheduler()->setTimeScale(4.0f);
                break;

            case cocos2d::EventKeyboard::KeyCode::KEY_F5:
                ++uiid;
                CUIEffectManager::getInstance()->execute((uiid % 4) + 1);
                break;

                /*case cocos2d::EventKeyboard::KeyCode::KEY_F6:
                if (true)
                {
                CConfCarmera* confCarmera = dynamic_cast<CConfCarmera*>(
                CConfManager::getInstance()->getConf(CONF_CAMERA));
                CarmeraConfItem* conf = new CarmeraConfItem();
                conf->ID = 1;
                conf->Dtime = 3.0f;
                conf->STime = 0.0f;
                conf->Time = 3.0f;
                conf->NextCamera = 0;
                conf->Dspeed = 0.5f;
                conf->Sdistance = 0.0f;
                confCarmera->getDatas()[1] = conf;
                doCarmera(1);
                }
                break;*/
            default:
                break;
            }
        };
        getEventDispatcher()->addEventListenerWithSceneGraphPriority(kbListener, this);
    }    

    return true;
}

void CBattleDragLayer::update(float delta)
{
    if (m_fCarmeraTime <= 0)
    {
        stopCarmera();
        return;
    }

    if (m_fScaleTime > 0.0f)
    {
        m_fScaleTime -= delta;
        scaleScene(m_pParent->getScale() + m_fScalePerSceond * delta);
    }

    if (m_fMoveTime > 0.0f)
    {
        m_fMoveTime -= delta;
        m_fCurCameraPosX += m_fMovePerSceond * delta * m_pParent->getScale();
    }

	float offset = m_fCurCameraPosX - m_pParent->getPositionX();
    if (offset > 0.0000001f || offset < 0.0000001f)
    {
        dragMove(offset);
    }

    m_fCarmeraTime -= delta;
}

void CBattleDragLayer::onEnter()
{
    Layer::onEnter();
#ifdef WIN32
	//initTestZoomBtn();

#endif

	float scale = 0.8f;
	scale = scale < m_fMinScale ? m_fMinScale : scale;
	scaleScene(scale);
}

void CBattleDragLayer::onExit()
{
    Layer::onExit();
    CGame::getInstance()->EventMgr->removeEventHandle(this);
}

void CBattleDragLayer::startCamera(int carmeraId)
{
    m_CameraFinishCallback = nullptr;
    doCamera(carmeraId);
}

void CBattleDragLayer::doCamera(int carmeraId)
{
    LOG("doCamera carmeraId %d", carmeraId);
    CConfCamera* confCarmera = dynamic_cast<CConfCamera*>(
        CConfManager::getInstance()->getConf(CONF_CAMERA));
    CameraConfItem* conf = reinterpret_cast<CameraConfItem*>(confCarmera->getData(carmeraId));
    if (NULL == conf)
    {
        return;
    }

    m_bMoveDisable = true;
    m_fCarmeraTime = conf->Time * 1.0f / 1000;
    m_fMoveTime = conf->MoveTime * 1.0f / 1000;
    m_fScaleTime = conf->ScaleTime * 1.0f / 1000;
    m_nNextCarmeraId = conf->NextCamera;
    // 配置表填0-100，实际范围为0.5-1.0
    float scale = conf->Scale * 0.5f / 100 + 0.5f;

    CBattleHelper* helper = CGame::getInstance()->BattleHelper;
    float targetX = conf->MoveX;
    if (conf->MoveType != CameraMovePosition)
    {
        if (conf->MoveType == CameraMoveMySummoner)
        {
            targetX = helper->getMainRole(ECamp_Blue)->getPositionX();
        }
        else if (conf->MoveType == CameraMoveEnemySummoner)
        {
            targetX = helper->getMainRole(ECamp_Red)->getPositionX();
        }
    }
    if (helper->getMasterId() != helper->getUserId())
    {
        //targetX = m_StandViewSize.width * m_fBattleScreen - targetX;
    }

    // 需要把目标位置转换成场景中心移动位置
    targetX = (-targetX - m_pParent->getPositionX() + m_fRealScreenWidth * 0.5f);
    m_fCurCameraPosX = m_pParent->getPositionX();
    LOG("doCamera move %f m_fCurCameraPosX %f", targetX, m_fCurCameraPosX);
    if (m_fMoveTime > 0.0f)
    {
        m_fMovePerSceond = targetX / m_fMoveTime;
    }
    else
    {
        // 直接移动
        dragMove(targetX);
        m_fCurCameraPosX += targetX * m_pParent->getScale();
        m_fMovePerSceond = 0.0f;
    }

    if (m_fScaleTime > 0.0f)
    {
		m_fScalePerSceond = (scale - m_pParent->getScale()) / m_fScaleTime;
    }
    else
    {
        scaleScene(scale);
        m_fScalePerSceond = 0.0f;
    }
    scheduleUpdate();
}

void CBattleDragLayer::stopCarmera()
{
    CConfCamera* confCarmera = dynamic_cast<CConfCamera*>(
        CConfManager::getInstance()->getConf(CONF_CAMERA));
    CameraConfItem* conf = reinterpret_cast<CameraConfItem*>(confCarmera->getData(m_nNextCarmeraId));
    if (NULL == conf)
    {
        m_bMoveDisable = false;
        // 结束镜头
        unscheduleUpdate();
        if (m_CameraFinishCallback)
        {
            m_CameraFinishCallback();
            m_CameraFinishCallback = nullptr;
        }
        return;
    }
    else
    {
        doCamera(m_nNextCarmeraId);
    }
}

void CBattleDragLayer::dragMove(float dx)
{
// 	float curMinPosX = -1 * ((m_StandViewSize.width * m_fBattleScreen * m_pParent->getScale()) - m_fRealScreenWidth);
// 	float curMaxPosX = 0;
// 	float tposX = m_pBattleBgLayer->getPositionX();
// 	// m_pParent为空节点, 缩放只会处理这个节点, 其它节点作为子节点添加在这节点之下, 缩放时除了m_pParent, 其它节点scale没有变化,
// 	// 所以移动时, 算出了最小位置, 是相对全局位置, 而子节点需要先转为"全局位置"相对于"自己的位置", 才是真正需要移动的距离.
// 	Vec2 v = Vec2(curMinPosX, 0);
// 	Vec2 v1 = m_pParent->convertToNodeSpace(v);
// 	curMinPosX = v1.x;
// 
// 	if ((dx + tposX) > curMaxPosX)
// 	{
// 		dx = curMaxPosX - tposX;
// 	}
// 	else if ((dx + tposX) < curMinPosX)
// 	{
// 		dx = curMinPosX - tposX;
// 	}
// 
// 	if (dx > 0.001f || dx < -0.001f)
// 	{
// 		//先处理战斗场景的位置
// 		m_pBattleLayer->setPositionX(m_pBattleLayer->getPositionX() + dx);
// 		if (NULL != m_pProspectLayer)
// 		{
// 			m_pProspectLayer->dragMove(dx);
// 		}
// 		if (NULL != m_pBackgroundLayer)
// 		{
// 			m_pBackgroundLayer->dragMove(dx);
// 		}
// 		if (NULL != m_pBattleBgLayer)
// 		{
// 			m_pBattleBgLayer->dragMove(dx);
// 		}
// 		if (NULL != m_pForegroundLayer)
// 		{
// 			m_pForegroundLayer->dragMove(dx);
// 		}
// 	}
	float curMinPosX = -1 * ((m_StandViewSize.width * m_fBattleScreen * m_pParent->getScale()) - m_fRealScreenWidth);
	float curMaxPosX = 0;
	float tposX = m_pParent->getPositionX();

	if ((dx + tposX) > curMaxPosX)
	{
		dx = curMaxPosX - tposX;
	}
	else if ((dx + tposX) < curMinPosX)
	{
		dx = curMinPosX - tposX;
	}

	if (dx > 0.001f || dx < -0.001f)
	{
		//先处理战斗场景的位置
		m_pParent->setPositionX(m_pParent->getPositionX() + dx);
	}
}

void CBattleDragLayer::resetLayer()
{
    m_ScreenCenter = Director::getInstance()->getWinSize() * 0.5f;
    m_bIsScaling = false;
    m_bIsMove = false;
    m_pParent->setPosition(m_ParentOriginPos);
}

void CBattleDragLayer::onTouchesBegan(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event)
{
    if (m_nSkillIndex != 0)
    {
        removeSkillRange();
        m_bIsMove = false;
    }
    else if (touches.size() == 1)
    {
        m_bIsMove = true;
    }
    else if (touches.size() >= 2)
    {
        m_bIsMove = false;
        m_bIsScaling = true;
        m_ScreenCenter = touches[0]->getLocation().getMidpoint(touches[1]->getLocation());
    }
}

void CBattleDragLayer::onTouchesMoved(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event)
{
    CHECK_RETURN_VOID(!m_bMoveDisable);
    
    // touchesbegan里面可能是1个， 所以在这里只要触摸点超过两个就算是缩放操作
    if (touches.size() >= 2)
    {
        m_bIsMove = false;
        m_bIsScaling = true;
        m_ScreenCenter = touches[0]->getLocation().getMidpoint(touches[1]->getLocation());
    }
    
    if (m_bIsMove)
    {
        float dx = touches[0]->getDelta().x;
        dragMove(dx);
    }
    else if (touches.size() >= 2 && !m_bIsMove)
    {
        // 开始屏幕缩放
        float fMoveFlag = 200.0f; //手指之间最大的位移
        float fD1 = touches[0]->getPreviousLocation().distance(touches[1]->getPreviousLocation());
        float fD2 = touches[0]->getLocation().distance(touches[1]->getLocation());
		float scale = m_pParent->getScale();
        scale += m_fMinScale * (fD2 - fD1) / fMoveFlag;
        scaleScene(scale);
    }
    else
    {
        int posY = static_cast<int>(touches[0]->getLocation().y);
        if (posY > 140 && posY < 520)
        {
            // 触发释放提示
            CGame::getInstance()->EventMgr->raiseEvent(BattleEventTouchReleaseTips,
                (void*)(getLanguageString(CONF_UI_LAN, 296)));
        }
        else
        {
            // 触发取消提示
            CGame::getInstance()->EventMgr->raiseEvent(BattleEventTouchCancelTips,
                (void*)(getLanguageString(CONF_UI_LAN, 297)));
        }
    }
}

void CBattleDragLayer::onTouchesEnded(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event)
{
    if (!m_bIsScaling && m_nSkillIndex > 0)
    {
        int posY = touches[0]->getLocation().y;
        if (posY > 140 && posY < 520)
        {
            int posX = static_cast<int>(m_pBattleLayer->convertTouchToNodeSpace(touches[0]).x);
            createSkillRange(posX);
            removeSkillScreen();
            FadeRemoveSkillRange();
            releaseSkill(m_nSkillIndex, posX);
            CGame::getInstance()->EventMgr->raiseEvent(BattleEventTouchPlaySkill, &m_nSkillIndex);
            m_nSkillIndex = 0;
        }
        else
        {
            CGame::getInstance()->EventMgr->raiseEvent(BattleEventTouchCancelSkill, &m_nSkillIndex);
        }
    }

    // 重置屏幕中心点
    m_ScreenCenter = Director::getInstance()->getWinSize() * 0.5f;
    m_bIsScaling = false;
    m_bIsMove = false;
}

void CBattleDragLayer::onTouchesCancelled(const std::vector<cocos2d::Touch*>&touches, cocos2d::Event *event)
{
    onTouchesEnded(touches, event);
}

void CBattleDragLayer::onSkillReleaseEvent(void *data)
{
    m_nSkillIndex = *(reinterpret_cast<int*>(data));
    createSkillScreen();
}

void CBattleDragLayer::onSkillCancelEvent(void* data)
{
    removeSkillScreen();
    m_nSkillIndex = 0;
}


// 创建技能范围框
void CBattleDragLayer::createSkillRange(float posX)
{
    m_SkillRange = CUISkillRange::create();
    m_pBattleBgLayer->addChild(m_SkillRange);
    m_SkillRange->setLocalZOrder(20);
    m_SkillRange->setGlobalZOrder(20);
    CBattleHelper *helper = CGame::getInstance()->BattleHelper;
    if (helper->getUserId() != helper->getMasterId())
    {
        m_SkillRange->setPosition(m_StandViewSize.width * m_fBattleScreen - posX, 480);
    }
    else
    {
        m_SkillRange->setPosition(posX, 480);
    }

    // 获取技能配置
    CBattleHelper* battleHelper = CGame::getInstance()->BattleHelper;
    CHero* hero = dynamic_cast<CHero*>(battleHelper->getMainRole(
        battleHelper->getCampWithUid(battleHelper->getUserId())));
    CSkill* skill = hero->getSkillWithIndex(m_nSkillIndex);

    // 设置缩放
    int range = skill->getSkillConf()->CastRange;
    float  diameter = m_SkillRange->getSkillRidius() * 2;
    float scale = range / diameter;
    m_SkillRange->setScale(scale);
}

// 移除技能范围框
void CBattleDragLayer::removeSkillRange()
{
    if (m_SkillRange)
    {
        m_SkillRange->removeFromParentAndCleanup(true);
        m_SkillRange = NULL;
    }
}

void CBattleDragLayer::FadeRemoveSkillRange()
{
    if (m_SkillRange)
    {
        m_SkillRange->playAni("Stand", false, [this](){
            removeSkillRange();
        });
    }
}

// 创建技能闪屏
void CBattleDragLayer::createSkillScreen()
{
    auto rootNode = Director::getInstance()->getRunningScene();
    if (!rootNode)
    {
        return;
    }
    m_SkillScreen = CUISkillScreen::create();
    rootNode->addChild(m_SkillScreen, 100);
}

// 移除技能闪屏
void CBattleDragLayer::removeSkillScreen()
{
    if (m_SkillScreen)
    {
        m_SkillScreen->removeFromParentAndCleanup(true);
        m_SkillScreen = NULL;
    }
}

void CBattleDragLayer::releaseSkill(int skillIndex, int posX)
{
    auto game = CGame::getInstance();
    int uid = game->BattleHelper->getUserId();
    int camp = game->BattleHelper->getCampWithUid(uid);
    auto hero = game->BattleHelper->getMainRole(camp);

    // 二次验证技能释放条件
    if (hero->canExecuteSkillIndex(skillIndex))
    {
        // 不能执行则返回
        // return
    }

    BattleCommandInfo cmd;
    cmd.CommandId = CommandSkill;
    cmd.ExecuterId = uid;
    cmd.Tick = game->BattleHelper->GameTick + 6;
    cmd.Ext1 = skillIndex;
    cmd.Ext2 = posX;
    game->sendRequest(CMD_BATTLE, CMD_BAT_PVPCOMMANDCS, &cmd, sizeof(cmd));
}

void CBattleDragLayer::initTestZoomBtn()
{
	auto pUILayer = m_pBattleLayer->getScene()->getChildByTag(BLT_UI);
	if (NULL != pUILayer)
	{
		auto zoomInItem = MenuItemImage::create(
			"CloseNormal.png",
			"CloseSelected.png",
			CC_CALLBACK_1(CBattleDragLayer::testScaleZoomIn, this));

		auto zoomOutItem = MenuItemImage::create(
			"CloseNormal.png",
			"CloseSelected.png",
			CC_CALLBACK_1(CBattleDragLayer::testScaleZoomOut, this));

		auto menu = Menu::create(zoomInItem, zoomOutItem, NULL);
		zoomInItem->setPosition(100, m_StandViewSize.height - 50);
		zoomOutItem->setPosition(180, m_StandViewSize.height - 50);
		menu->setPosition(Vec2::ZERO);
		pUILayer->addChild(menu);
	}
}

void CBattleDragLayer::testScaleZoomIn(cocos2d::Ref *pSender)
{
    // 重置屏幕中心点
    m_ScreenCenter = Director::getInstance()->getWinSize() * 0.5f;
	scaleScene(m_pParent->getScale() - 0.1f);
}

void CBattleDragLayer::testScaleZoomOut(cocos2d::Ref *pSender)
{
    // 重置屏幕中心点
    m_ScreenCenter = Director::getInstance()->getWinSize() * 0.5f;
	scaleScene(m_pParent->getScale() + 0.1f);
}

void CBattleDragLayer::scaleScene(float scale)
{
	float oldScale = m_pParent->getScale();
    scale = MIN(1.0f, MAX(0.5f, scale));
    if (oldScale == scale)
    {
        return;
    }
	// scaleLayer的锚点为(0,0), 缩放时自动靠左下角, 将y轴往上移动即可.
	float newY = 320 - (640 * scale)/2;
	Vec2 oldCenter = m_pParent->convertToNodeSpace(m_ScreenCenter);
	m_pParent->setScale(scale);
	Vec2 newCenter = m_pParent->convertToWorldSpace(oldCenter);
	m_pParent->setPositionY(newY);
	//dragMove(0.1f);
	dragMove(m_ScreenCenter.x - newCenter.x);
}
