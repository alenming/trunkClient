#include "BattleScene.h"
#include "cocostudio/CocoStudio.h"

#include "Game.h"
#include "ConfOther.h"
#include "Protocol.h"
#include "BattleProtocol.h"
#include "StageProtocol.h"
#include "PvpProtocol.h"
#include "NetBattleProxy.h"
#include "SingleBattleProxy.h"
#include "ProxyManager.h"
#include "GameNetworkNode.h"

#include "UIBattleMain.h"
#include "UIReplayBattleMain.h"

#include "BattleDragLayer.h"
#include "BattleHelper.h"
#include "Hero.h"
#include "Bullet.h"
#include "CallSoldier.h"
#include "UIEffect.h"
#include "Events.h"
#include "DisplayCommon.h"
#include "UIEffect.h"
#include "GameModel.h"
#include "PVPSerialize.h"

#include "LuaSummonerBase.h"
#include "RoleDisplayComponent.h"
#include "ResManager.h"
#include "ConfLanguage.h"
#include "FMODAudioEngine.h"

#include "ResPool.h"
#include "TipBloodNode.h"

using namespace std;
using namespace cocostudio;
USING_NS_CC;

float alldt = 0.0f;
struct timeval lastupdate;
bool bFightStart = false;

void initProxy(CBaseProxy* proxy)
{
    CProxyManager::getInstance()->addProxy(CMD_BATTLE, proxy);
}

Scene* CBattleLayer::createNewScene(CRoomModel* room)
{
    CHECK_RETURN_NULL(NULL != room);

    // 初始化网络代理
    CBaseProxy* proxy = NULL;
    switch (room->getBattleType())
    {
    case EBATTLE_PVP:
        proxy = new CNetBattleProxy();
        (dynamic_cast<CNetBattleProxy*>(proxy))->init(CGame::getInstance()->EventMgr);
        break;
	//case EBATTLE_CHAPTER:
    default:
        proxy = new CSingleBattleProxy();
        (dynamic_cast<CSingleBattleProxy*>(proxy))->init(CGame::getInstance()->EventMgr);
        break;
    }
    initProxy(proxy);

    // 服务器需要预处理
    Scene *scene = Scene::create();
	// 缩放层
	Layer *scaleLayer = Layer::create();
	
    CBattleLayer* battleLayer = new CBattleLayer();
    CBattleDragLayer* dragLayer = new CBattleDragLayer;
    CUIBattleMain* uiLayer = new CUIBattleMain();
    do
    {
        CHECK_BREAK(battleLayer->init(room));
		CHECK_BREAK(dragLayer->init(room->getStageId(), scaleLayer, battleLayer));
        CHECK_BREAK(uiLayer->init());

        battleLayer->setName("BattleLayer");
		scaleLayer->addChild(battleLayer, SLZ_BATTLE1, BLT_BATTLE);

        dragLayer->setName("BattleDragLayer");
        dragLayer->setTag(BLT_DRAG);
		scaleLayer->addChild(dragLayer);
		scaleLayer->setAnchorPoint(Vec2(0, 0));
		scaleLayer->setName("ScaleLayer");
		scene->addChild(scaleLayer, LZ_SCALE);

        uiLayer->setName("BattleUILayer");
        scene->addChild(uiLayer, LZ_UI, BLT_UI);

        CUIEffectManager::getInstance()->init(scene);
    } while (false);

    SAFE_RELEASE(battleLayer);
    SAFE_RELEASE(dragLayer);
    SAFE_RELEASE(uiLayer);

    return scene;
}

Scene* CBattleLayer::createReplayScene(CRoomModel* room)
{
    CHECK_RETURN_NULL(NULL != room);

    // 初始化网络代理
    CBaseProxy* proxy = new CSingleBattleProxy();
    (dynamic_cast<CSingleBattleProxy*>(proxy))->init(CGame::getInstance()->EventMgr);

    initProxy(proxy);

    Scene *scene = Scene::create();
    // 缩放层
    Layer *scaleLayer = Layer::create();

    CBattleLayer* battleLayer = new CBattleLayer();
    CBattleDragLayer* dragLayer = new CBattleDragLayer;
    CUIReplayBattleMain* uiLayer = new CUIReplayBattleMain();
    do
    {
        CHECK_BREAK(battleLayer->init(room));
        CHECK_BREAK(dragLayer->init(room->getStageId(), scaleLayer, battleLayer));
        CHECK_BREAK(uiLayer->init());

        battleLayer->setName("BattleLayer");
        scaleLayer->addChild(battleLayer, SLZ_BATTLE1, BLT_BATTLE);

        dragLayer->setName("BattleDragLayer");
        dragLayer->setTag(BLT_DRAG);
        scaleLayer->addChild(dragLayer);
        scaleLayer->setAnchorPoint(Vec2(0, 0));
        scaleLayer->setName("ScaleLayer");
        scene->addChild(scaleLayer, LZ_SCALE);

        uiLayer->setName("BattleUILayer");
        scene->addChild(uiLayer, LZ_UI, BLT_UI);

        CUIEffectManager::getInstance()->init(scene);
    } while (false);

    SAFE_RELEASE(battleLayer);
    SAFE_RELEASE(dragLayer);
    SAFE_RELEASE(uiLayer);

    return scene;
}

CBattleLayer::CBattleLayer()
: m_bIsPauseAction(false)
, m_bIsPause(false)
, m_fDelta(0.0f)
, m_pBattle(NULL)
, m_pRoomModel(NULL)
, m_pPVPSerialize(NULL)
{
    setTickSpeed(10);
}

CBattleLayer::~CBattleLayer()
{
    initProxy(NULL);
    SAFE_DELETE(m_pBattle);
	SAFE_DELETE(m_pPVPSerialize);
    CGame::getInstance()->BattleHelper = NULL;
    //SAFE_DELETE(m_pRoom);
}

bool CBattleLayer::init(CRoomModel* roomModel)
{
    bFightStart = false;

    CHECK_RETURN(NULL != roomModel);
	CHECK_RETURN(Layer::init());
	// 房间模型
	m_pRoomModel = roomModel;
    // 注册响应事件
    for (int i = CMD_BAT_SCBEGIN + 1; i < CMD_BAT_SCEND; i++)
    {
        CGame::getInstance()->EventMgr->addEventHandle(MakeCommand(CMD_BATTLE, i),
            this, CALLBACK_FUNCV(CBattleLayer::onResponse));
    }
	// 监听开始游戏响应, 用于播放"预备开始"
	CGame::getInstance()->EventMgr->addEventHandle(MakeCommand(CMD_PVP, CMD_PVP_START_SC),
		this, CALLBACK_FUNCV(CBattleLayer::onResponse));
	CGame::getInstance()->EventMgr->addEventHandle(MakeCommand(CMD_PVP, CMD_PVP_OPPRECONNECT_SC),
		this, CALLBACK_FUNCV(CBattleLayer::onResponse));
	CGame::getInstance()->EventMgr->addEventHandle(MakeCommand(CMD_PVP, CMD_PVP_OPPDISCONNECT_SC),
		this, CALLBACK_FUNCV(CBattleLayer::onResponse));

    CBattlePlayerModel* myModel = NULL;
    CBattlePlayerModel* otherModel = NULL;
    map<int, CBattlePlayerModel*>& players = roomModel->getPlayers();
    for (auto model : players)
    {
        if (model.first == CGame::getInstance()->UserId
            || model.first == EDefaultPlayer)
        {
            myModel = model.second;
        }
        else
        {
            otherModel = model.second;
        }
    }

    // 播放背景音乐
    const StageConfItem* pStageConfItem = queryConfStage(roomModel->getStageId());
    CHECK_RETURN(NULL != pStageConfItem);
    const StageSceneConfItem *stageSceneConf = queryConfStageScene(pStageConfItem->StageSenceID);
    CHECK_RETURN(NULL != stageSceneConf);
    onLuaPlayBgMusic(stageSceneConf->BgMusicId);

	// 初始化BattleHelper
	m_pBattle = new CBattleHelper();
	CGame::getInstance()->BattleHelper = m_pBattle;
	if (!m_pBattle->init(roomModel, myModel, otherModel, CGame::getInstance()->EventMgr, this))
	{
		return false;
	}

    alldt = 0.0f;

    if (m_pRoomModel->getBattleType() == EBATTLE_PVP)
    {
        m_pPVPSerialize = new CPVPSerialize(m_pBattle);

        // 监听小重连
        CGame::getInstance()->EventMgr->addEventHandle(MakeCommand(CMD_LOGIN, CMD_LOGIN_RECONECT_CS),
            this, CALLBACK_FUNCV(CBattleLayer::onResponse));
    }
    else if (m_pRoomModel->getBattleType() == EBATTLE_PVPREPLAY)
    {
        m_pPVPSerialize = new CPVPSerialize(m_pBattle);
    }

    // 执行场景召唤物逻辑
    if (m_pBattle->getBattleType() != EBATTLE_PVP)
    {
        for (std::vector<SSceneCall>::const_iterator iter = pStageConfItem->SceneCall.begin(); 
            iter != pStageConfItem->SceneCall.end(); ++iter)
        {
            if (!m_pBattle->createCallSoldier(EDefaultScene, iter->callID, 1, iter->callPosX, iter->callPosY))
            {
                return false;
            }
        }
    }

    // 帧数显示
    //openDebugInfo();
    return true;
}

void CBattleLayer::onEnter()
{
    Layer::onEnter();
    Director::getInstance()->getRunningScene()->setonEnterTransitionDidFinishCallback([this](){
        if (m_pBattle->getBattleType() == EBATTLE_PVP)
        {
            onLuaBattleStart(0);
        }
        else
        {
            onLuaBattleStart(m_pRoomModel->getStageId());
        }
    });

    Director::getInstance()->getEventDispatcher()->setMultiTouchEnable(true);
//#ifdef COCOS2D_DEBUG
    // 第一帧的时间
    m_fDelta = 0.0f;
    gettimeofday(&lastupdate, nullptr);
//#endif

    // 暂停, 但是动作继续
    pauseBattle(false);

    // pvp
    if (m_pBattle->getBattleType() == EBATTLE_PVP)
    {
        CPvpModel *pPvpModel = CGameModel::getInstance()->getPvpModel();
        // 是否重连
        if (pPvpModel->isReconnect())
        {
            // 请求序列化
            CGame::getInstance()->sendRequest(CMD_BATTLE, CMD_BAT_PVPUPDATECS, NULL, 0);
            // 不执行以下的镜头
            return;
        }
    }
    else if (m_pBattle->getBattleType() == EBATTLE_PVPREPLAY)
    {
        // 序列化一次,以便回放使用
        m_pPVPSerialize->serializeCommandBuffData();
    }

    doReady();
}

void CBattleLayer::onExit()
{
    Layer::onExit();
    CResPool::destory();
    TipBloodNode::destory();
    CGame::getInstance()->EventMgr->removeEventHandle(this);
    CUIEffectManager::getInstance()->uninit();
    CUIEffectManager::destroy();
    Director::getInstance()->getEventDispatcher()->setMultiTouchEnable(false);
	//重置重连状态
	CPvpModel *pPvpModel = CGameModel::getInstance()->getPvpModel();
	if (pPvpModel->isReconnect())
	{
		pPvpModel->setBattleId(0);
		pPvpModel->setReconnect(false);
	}
}

void CBattleLayer::onResponse(void* data)
{
    // 处理游戏结束请求和战斗请求
    Head* head = reinterpret_cast<Head*>(data);
    if (NULL == head)
    {
        return;
    }

	if (head->MainCommand() == CMD_PVP)
	{
		if (head->SubCommand() == CMD_PVP_START_SC)
		{
            m_fDelta = 0.0f;
			resumeBattle();
//#if COCOS2D_DEBUG
			gettimeofday(&lastupdate, nullptr);
//#endif
            auto *pUILayer = Director::getInstance()->getRunningScene()->getChildByName("BattleUILayer");
			if (NULL != pUILayer)
            {
				auto readyGo = pUILayer->getChildByName("ReadyGo");
                if (NULL != readyGo)
                {
                    readyGo->setVisible(true);
                    auto action = getCsbAnimation(readyGo);
                    action->setLastFrameCallFunc([readyGo, action](){
                        // 触发战斗开始提示
                        if (!bFightStart)
                        {
                            bFightStart = true;
                            CGame::getInstance()->EventMgr->raiseEvent(BattleEventFightStartTips, NULL);
                        }
                        readyGo->removeFromParent();
                        action->clearLastFrameCallFunc();
                    });
                    playCsbAnimation(readyGo, "Go");
                }
            }
		}
		else if (head->SubCommand() == CMD_PVP_OPPRECONNECT_SC)
		{
			//显示玩家已重连
			CGame::getInstance()->EventMgr->raiseEvent(BattleEventShowTips,
				(void*)(getLanguageString(CONF_UI_LAN, 842)));
		}
		else if (head->SubCommand() == CMD_PVP_OPPDISCONNECT_SC)
		{
			//显示玩家退出游戏
			CGame::getInstance()->EventMgr->raiseEvent(BattleEventShowTips,
				(void*)(getLanguageString(CONF_UI_LAN, 840)));
		}
	}
	else if (head->MainCommand() == CMD_BATTLE)
	{
		switch (head->SubCommand())
		{
		case CMD_BAT_PVPCOMMANDSC:
			{
                // 如果
				BattleCommandInfo* info = reinterpret_cast<BattleCommandInfo*>(head->data());
				if (NULL != m_pBattle)
				{
					// 判断是否需要反序列化
					if (m_pRoomModel->getBattleType() == EBATTLE_PVP
                        && m_pPVPSerialize->processSerializeByCommand(*info))
					{
                        //m_fDelta += (m_pBattle->CurTick - m_pBattle->GameTick) * m_fTickDelta;
                        // 重新计算需要追回的时间，追回到alldt
                        m_fDelta = alldt - m_fDelta - m_pBattle->GameTick * m_fTickDelta;
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
                        if (CGame::getInstance()->isDebug())
                        {
                            // 网络延迟提示
                            Label* lb = Label::create();
                            lb->setSystemFontSize(28);
                            auto winsize = Director::getInstance()->getWinSize();
                            string msg = " Current Tick " + toolToStr(m_pBattle->GameTick)
                                + " Command Tick " + toolToStr(info->Tick);
                            lb->setPosition(winsize * 0.5f);
                            lb->setString(msg);
                            getParent()->addChild(lb);
                            lb->runAction(Sequence::create(FadeIn::create(1.5f),
                                FadeOut::create(1.5f), RemoveSelf::create(), NULL));
                        }
#endif
					}

					// 服务器需要另外处理插入命令（无论是否执行了反序列化，这里都需要插入）
                    m_pBattle->insertBattleCommand(*info);
				}
			}
			break;
			// 服务器下发纠正数据
		case CMD_BAT_PVPUPDATESC:
			{
				CBufferData buffdata;
				// 注意去掉头部Head的大小
				buffdata.init((char*)head->data(), head->length - sizeof(Head));
				m_pBattle->unserialize(buffdata);
				
                // 游戏dt
                float gameDt = m_pBattle->GameTick / 10.0f;
                // 大重连和小重连都会执行数据刷新，但大重连时，alldt变量会失效
                // 如果alldt小于gameDt，则说明是大重连
                // 因为gameDt是服务器的当前实际时间（发送包时），alldt是客户端的当前实际时间
                // 当客户端跑得比服务端慢时，则说明是大重连（大重连进来时 alldt从0开始，而服务器的时间则一直在跑）
                if (alldt < gameDt)
                {
                    alldt = gameDt;
                }
                m_pPVPSerialize->SaveReconnectData(&buffdata);
				resumeBattle();
			}
			break;
			// PVP战斗结束响应
		case CMD_BAT_PVPENDSC:
			{
				// 停止战斗
				// m_pBattle->onBattleOver();
				// 执行BattleHelper.onBattleOver
				unscheduleUpdate();
				onLuaBattleOver();
			}
			break;
		}
	}
	else if (head->MainCommand() == CMD_LOGIN)
	{
		switch (head->SubCommand())
		{
			case CMD_LOGIN_RECONECT_CS:
			{
                KXLOGDEBUG("SEND PVP UpdateCS");
                // 如果有未执行的网络指令
                /*const vector<BattleCommandInfo>& cmdQueue = m_pBattle->getBattleCommandQueue();
                int curCmdIndex = m_pBattle->getCurExecutCommandCount();
                BattlePvpUpdateCS updateCS;
                if (cmdQueue.size() > 0)
                {
                    int lastUserCmd = 0;
                    for (int i = cmdQueue.size() - 1; i >= curCmdIndex; --i)
                    {
                        if (cmdQueue[i].CommandId != CommandCallSolider)
                        {
                            if (lastUserCmd == 0)
                            {
                                lastUserCmd = i;
                            }
                            if (cmdQueue[i].Tick > m_pBattle->GameTick)
                            {
                                // 不需要反序列化
                                return;
                            }
                            else
                            {
                                // 必须反序列化
                                break;
                            }
                        }
                    }
                    updateCS.lastCmdGameTick = cmdQueue[lastUserCmd].Tick;
                    updateCS.lastCmdIndex = lastUserCmd;
                }
                else
                {
                    // 请求刷新
                    updateCS.lastCmdGameTick = 0;
                    updateCS.lastCmdIndex = 0;
                }
                // 请求序列化
                CGame::getInstance()->sendRequest(CMD_BATTLE, CMD_BAT_PVPUPDATECS, &updateCS, sizeof(updateCS));*/
                Head head;
                head.length = sizeof(head);
                head.MakeCommand(CMD_BATTLE, CMD_BAT_PVPUPDATECS);
                CGameNetworkNode::getInstance()->sendData(reinterpret_cast<char*>(&head), sizeof(head));
			}
			break;
		}
	}
}

void CBattleLayer::update(float delta)
{
    if (m_pRoomModel->getBattleType() == EBATTLE_PVP)
	{
        // 战斗未开始或战斗未结束，不进行PVP自动序列化
        if (!m_pBattle->IsBattleOver)
        {
            m_pPVPSerialize->update(delta);
        }

//#if COCOS2D_DEBUG
        // DEBUG模式下才需要对时间进行校正，因为Director::calculateDeltaTime中
        // 在DEBUG模式下会将大于0.2f的delta置为1 / 60.0
        struct timeval now;
		gettimeofday(&now, nullptr);
        // PVP需要加速追回
        delta = (now.tv_sec - lastupdate.tv_sec) + (now.tv_usec - lastupdate.tv_usec) / 1000000.0f;
        lastupdate = now;
//#endif
    }

    alldt += delta;
    m_pBattle->CurTick = static_cast<int>(alldt * 10);
    // 每一帧都累加delta
    m_fDelta += delta;

    if (alldt >= 0.1f)
    {
        // 触发战斗开始提示
        if (!bFightStart)
        {
            bFightStart = true;
            CGame::getInstance()->EventMgr->raiseEvent(BattleEventFightStartTips, NULL);
        }
    }

    // 当卡顿时delta会变大，这时逻辑帧的频率也会跟着变快
    // 单逻辑帧执行的逻辑时间不变
    int execCount = 0;
    while (m_fDelta >= m_fTickDelta)
    {
        m_fDelta -= m_fTickDelta;
        if (!logicUpdate(m_fTickDelta))
        {
            // 游戏结束需要强制退出该循环
            break;
        }
        if (++execCount >= 3)
        {
            break;
        }
    }

    // PVP调试帧数显示
    // showDebugInfo();
}

bool CBattleLayer::logicUpdate(float delta)
{
    if (m_pBattle->IsBattleOver)
    {
        return false;
    }

    // 检查战斗结束 —— 如果游戏结束会将m_pBattle->IsBattleOver设置为true
    if (m_pBattle->checkBattleOver())
    {
        // 先将战斗数据写入结算模型
        m_pBattle->onBattleOver();
        CFMODAudioEngine::getInstance()->clearAllEffects();
        switch (m_pBattle->getBattleType())
        {
            // PVP由后端通知战斗结束
        case EBATTLE_PVP:
            break;
        default:
            unscheduleUpdate();
            onLuaBattleOver();
            return false;
        }
    }
    else
    {
        // 处理战斗逻辑
        m_pBattle->processBattle(delta);
	}
    return true;
}

void CBattleLayer::openDebugInfo()
{
    auto lb = Label::create();
    lb->setString("0");
    lb->setSystemFontSize(32);
    lb->setTag(7788);
    lb->setPosition(Vec2(480, 600));
    addChild(lb);

    lb = Label::create();
    lb->setString("0");
    lb->setSystemFontSize(32);
    lb->setTag(7799);
    lb->setPosition(Vec2(480, 560));
    addChild(lb);

    lb = Label::create();
    lb->setString("0");
    lb->setSystemFontSize(32);
    lb->setTag(7777);
    lb->setPosition(Vec2(480, 540));
    addChild(lb);
}

void CBattleLayer::showDebugInfo()
{
    Label* lb = (Label*)getChildByTag(7788);
    if (lb)
    {
        lb->setString(toolToStr(m_pBattle->GameTick));
    }

    lb = (Label*)getChildByTag(7799);
    if (lb)
    {
        lb->setString(toolToStr(alldt));
    }

    lb = (Label*)getChildByTag(7777);
    if (lb)
    {
        lb->setString(toolToStr(m_pBattle->CurTick));
    }
}

void pauseRole(CRole* role)
{
    role->pause();
    CAnimateComponent* displayCom = dynamic_cast<CAnimateComponent*>(
        role->getComponent("MainAnimate"));
    if (displayCom)
    {
        displayCom->pause();
    }
}

void pauseBullet(CBullet* bullet)
{
    bullet->pause();
    for (auto& child : bullet->getChildren())
    {
        child->pause();
    }
}

void resumeRole(CRole* role)
{
    role->resume();
    CAnimateComponent* displayCom = dynamic_cast<CAnimateComponent*>(
        role->getComponent("MainAnimate"));
    if (displayCom)
    {
        displayCom->resume();
    }
}

void resumeBullet(CBullet* bullet)
{
    bullet->resume();
    for (auto& child : bullet->getChildren())
    {
        child->resume();
    }
}

void CBattleLayer::pauseBattle(bool isPauseAction)
{
    if (!m_bIsPause)
    {
        m_bIsPause = true;
        unscheduleUpdate();
        if (m_bIsPauseAction != isPauseAction && isPauseAction)
        {
            m_bIsPauseAction = isPauseAction;
			pauseRole(m_pBattle->getMainRole(CampType::ECamp_Blue));
			pauseRole(m_pBattle->getMainRole(CampType::ECamp_Red));
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Blue))
			{
				pauseRole(role);
			}
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Red))
			{
				pauseRole(role);
			}
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Neutral))
			{
				pauseRole(role);
			}
			for (auto& bullet : m_pBattle->getBullets())
			{
				pauseBullet(bullet);
			}
		}
    }
}

void CBattleLayer::resumeBattle()
{
    if (m_bIsPause)
    {
        m_bIsPause = false;
        scheduleUpdate();
		if (m_bIsPauseAction)
		{
            m_bIsPauseAction = false;
			resumeRole(m_pBattle->getMainRole(CampType::ECamp_Blue));
			resumeRole(m_pBattle->getMainRole(CampType::ECamp_Red));
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Blue))
			{
				resumeRole(role);
			}
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Red))
			{
				resumeRole(role);
			}
			for (auto& role : m_pBattle->getRoleWithCamp(CampType::ECamp_Neutral))
			{
				resumeRole(role);
			}
			for (auto& bullet : m_pBattle->getBullets())
			{
				resumeBullet(bullet);
			}
		}
    }
}

void CBattleLayer::quitBattle()
{
    m_pRoomModel->getSettleAccountModel()->setChallengeResult(CHALLENGE_CANCEL);
    m_pBattle->onBattleOver();
    unscheduleUpdate();
    onLuaQuitBattle();
}

void CBattleLayer::doReady()
{
    CBattleDragLayer *pDragLayer = dynamic_cast<CBattleDragLayer *>(
        Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));

    //播放预备动画
    auto *pUILayer = Director::getInstance()->getRunningScene()->getChildByName("BattleUILayer");
    auto readyGo = CResManager::getInstance()->getCsbNode("ui_new/f_fight/ReadyGo.csb");
    readyGo->setContentSize(Director::getInstance()->getWinSize());
    ui::Helper::doLayout(readyGo);
    if (NULL == readyGo->getParent())
    {
        auto action = CSLoader::createTimeline("ui_new/f_fight/ReadyGo.csb");
        readyGo->runAction(action);
        readyGo->setVisible(false);
        pUILayer->addChild(readyGo);
    }

    CHECK_RETURN_VOID(NULL != pDragLayer);
    //执行摄像头
    pDragLayer->doCamera(1);
    //设置回调
    pDragLayer->setCameraFinishCallback([this, readyGo](){
        if (m_pBattle->getBattleType() != EBATTLE_PVP)
        {
            // 准备音效
            playSoundEffect(54);
            readyGo->setVisible(true);
            auto readyAction = getCsbAnimation(readyGo);
            if (NULL != readyAction)
            {
                readyAction->setLastFrameCallFunc([readyGo, readyAction](){
                    Head head = { sizeof(Head), MakeCommand(CMD_PVP, CMD_PVP_START_SC), 0 };
                    CGame::getInstance()->EventMgr->raiseEvent(MakeCommand(CMD_PVP, CMD_PVP_START_SC), (void*)&head);
                });
            }
            else
            {
                Head head = { sizeof(Head), MakeCommand(CMD_PVP, CMD_PVP_START_SC), 0 };
                CGame::getInstance()->EventMgr->raiseEvent(MakeCommand(CMD_PVP, CMD_PVP_START_SC), (void*)&head);
            }
            playCsbAnimation(readyGo, "Ready");
        }
    });
}

bool CBattleLayer::replayAgain()
{
    bFightStart = false;
    m_bIsPauseAction = false;
    m_bIsPause = true;
    alldt = 0.0f;
    m_fDelta = 0.0f;
    gettimeofday(&lastupdate, nullptr);
    m_pBattle->getSettleAccountModel()->resetSettle();

    CBattleDragLayer *pDragLayer = dynamic_cast<CBattleDragLayer *>(
        Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));
    if (NULL != pDragLayer)
    {
        pDragLayer->resetLayer();
    }

    CHECK_RETURN(NULL != m_pPVPSerialize);
    m_pPVPSerialize->unSerializeLastPVPData();

    //执行摄像头+准备
    doReady();

    return true;
}