#include "UISummoner.h"
#include "Game.h"
#include "Protocol.h"
#include "BattleProtocol.h"
#include "DisplayCommon.h"
#include "Hero.h"
#include "Events.h"
#include "KxCSComm.h"
#include "ConfLanguage.h"

USING_NS_CC;
USING_NS_TIMELINE;
using namespace ui;
using namespace std;

const static int TalkCount = 6;

CUISummonerComponent::CUISummonerComponent()
    : m_pRole(NULL)
    , m_pMaskLayer(NULL)
    , m_pHPBar(NULL)
    , m_pHPBarD(NULL)
    , m_pHeadImg(NULL)
    , m_pTalkText(NULL)
    , m_nNextTalkTime(0)
{

}

CUISummonerComponent::~CUISummonerComponent()
{
    
}

bool CUISummonerComponent::init(cocos2d::Node* summonerPanelNode, CRole* role, bool isSelf)
{
    bool ret = Component::init();
    setName("UISummonerComponent");
    m_nLanIDs[0] = 1504;
    m_nLanIDs[1] = 1505;
    m_nLanIDs[2] = 1506;
    m_nLanIDs[3] = 1507;
    m_nLanIDs[4] = 1508;
    m_nLanIDs[5] = 1509;

    summonerPanelNode->scheduleUpdate();

    // 初始化数据
    m_pRole = role;
    m_bIsSelf = isSelf;

    // 初始化动画
    initAnimation(summonerPanelNode);
    // 初始化血条相关
    initHpBarInfo(summonerPanelNode);

    // 注册相关事件监听
    CGame::getInstance()->EventMgr->addEventHandle(BattleEventTalkCommand,
        this, CALLBACK_FUNCV(CUISummonerComponent::onShowTalk));

    return ret;
}

void CUISummonerComponent::onExit()
{
    CGame::getInstance()->EventMgr->removeEventHandle(this);
}

void CUISummonerComponent::update(float dt)
{
    updateHp(dt);
    updateState(dt);

    // pvp机器人说话
    if (m_pRole->getBattleHelper()->getBattleType() == EBATTLE_PVPROBOT)
    {
        robotTalk();
    }
}

void CUISummonerComponent::updateState(float dt)
{
    m_HPState = CountHPState(m_fHPFinalPercent);

    if (m_HPState != m_preHPState)
    {
        switch (m_HPState)
        {
        case CUISummonerComponent::kNormal:
            m_pHeadImg->setVisible(true);
            m_pHeadAction->play("Normal", false);
            m_pHpBarAction->play("Normal", false);
            break;
        case CUISummonerComponent::kTips:
            m_pHeadImg->setVisible(true);
            m_pHeadAction->play("Blink", true);
            m_pHpBarAction->play("Blink", true);
            break;
        case CUISummonerComponent::kZero:
            m_pHeadImg->setVisible(false);
            m_pHeadAction->play("Normal", false);
            m_pHpBarAction->play("Normal", false);
            break;
        default:
            break;
        }
        m_preHPState = m_HPState;
    }
}

void CUISummonerComponent::updateHp(float dt)
{
    if (m_pRole->getIntAttribute(EAttributeHP) != m_fHPValue)
    {
        m_fHPValue = m_pRole->getIntAttribute(EAttributeHP);
        m_fHPFinalPercent = m_fHPValue / m_fHPMaxValue * 100;

        if (m_fHPFinalPercent >= m_fHPPercent)
        {
            m_fHPSpeed = (m_fHPFinalPercent - m_fHPPercent) / m_fInterval;
            m_fHPDSpeed = (m_fHPFinalPercent - m_fHPDPercent) / m_fInterval;
        }
        else
        {
            m_pHPBar->setPercent(m_fHPFinalPercent);
            m_fHPPercent = m_fHPFinalPercent;
            m_fHPSpeed = 0;
            m_fHPDSpeed = (m_fHPFinalPercent - m_fHPDPercent) / m_fInterval;
        }
    }

    if (0 != m_fHPSpeed)
    {
        setBarPercent(m_pHPBar, m_fHPFinalPercent, m_fHPPercent, m_fHPSpeed, dt);
    }
    if (0 != m_fHPDSpeed)
    {
        setBarPercent(m_pHPBarD, m_fHPFinalPercent, m_fHPDPercent, m_fHPDSpeed, dt);
    }
}

void CUISummonerComponent::initAnimation(cocos2d::Node* summonerPanelNode)
{
    // 血条闪红动画
    m_pHpBarAction = getCsbAnimation(findChild<Node>(summonerPanelNode, "BloodBar"));
    // 头像闪红, 点击 动画
    m_pHeadAction = getCsbAnimation(findChild<Node>(summonerPanelNode, "HeadBar"));
    m_pHeadAction->setLastFrameCallFunc([this]{
       if (m_HPState == HPState::kTips)
       {
           m_pHeadAction->play("Blink", false);
       }
    });

    // 说话文字动画
    m_pTalkAction = getCsbAnimation(findChild<Node>(summonerPanelNode, "TalkText"));
    // 文字面板
    m_pTalkPanelAction = getCsbAnimation(findChild<Node>(summonerPanelNode, "TalkPanel"));

    m_pHpBarAction->play("Normal", false);
    m_pHeadAction->play("Normal", false);
    m_pTalkAction->play("Normal", false);

    if (m_pTalkPanelAction)
        m_pTalkPanelAction->play("Hide", false);
}

void CUISummonerComponent::initHpBarInfo(cocos2d::Node* summonerPanelNode)
{
    m_nMyUserID = m_pRole->getOwnerId();
    m_fHPMaxValue = m_pRole->getIntAttribute(EAttributeMaxHP);
    m_fHPValue = m_pRole->getIntAttribute(EAttributeHP);
    m_fHPPercent = m_fHPValue/m_fHPMaxValue*100;
    m_fHPDPercent = m_fHPPercent;
    m_fHPFinalPercent = m_fHPPercent;
    m_HPState = CountHPState(m_fHPFinalPercent);
    m_preHPState = HPState::kNormal;
    m_fInterval = 0.2f;
    m_fHPSpeed = 0;
    m_fHPDSpeed = 0;

    if (m_bIsSelf)
    {
        m_pMaskLayer = dynamic_cast<Layout*>(summonerPanelNode->getParent());
        m_pMaskLayer->addClickEventListener(CC_CALLBACK_1(CUISummonerComponent::onMaskClick, this));
        m_pMaskLayer->setTouchEnabled(false);
    }

    // 玩家名称
    Text* name = findChild<Text>(summonerPanelNode, "NameText");
    // 玩家头像
    Button* pHeadGreyImg = findChild<Button>(summonerPanelNode, "HeadBar/HeadImage_Grey");
    m_pHeadImg = findChild<ImageView>(summonerPanelNode, "HeadBar/HeadImage");
    m_pHeadImg->setTouchEnabled(true);
    CBattlePlayerModel* playModel = NULL;
    if (m_bIsSelf || m_pRole->getBattleHelper()->getBattleType() == EBATTLE_PVP)
    {
        playModel = m_pRole->getBattleHelper()->getUserModel(m_nMyUserID);
    }
    else
    {
        playModel = m_pRole->getBattleHelper()->getComputerModel();
    }

    CHECK_RETURN_VOID(NULL != playModel);
    name->setString(playModel->getUserName());
    if (SpriteFrameCache::getInstance()->getSpriteFrameByName(playModel->getRoleModel()->getRoleComm()->HeadIcon))
    {
        m_pHeadImg->loadTexture(playModel->getRoleModel()->getRoleComm()->HeadIcon, Widget::TextureResType::PLIST);
        pHeadGreyImg->loadTextureNormal(playModel->getRoleModel()->getRoleComm()->HeadIcon, Widget::TextureResType::PLIST);
    }

    // 玩家蓝钻
    Node *pTencentNode = findChild<Node>(summonerPanelNode, "TencentLogo");
    if (playModel->getIdentity() > 0 && CGame::getInstance()->getPfType() == EQQHall)
    {
        Sprite *pBlueLvSprite = findChild<Sprite>(pTencentNode, "Logo1");
        Sprite *pBlueYearSprite = findChild<Sprite>(pTencentNode, "Logo2");
        int nBlueLv = playModel->getIdentity()/10;
        int nBlueType = playModel->getIdentity()%10;

        SpriteFrame *pBlueLvFrame = CCSpriteFrameCache::getInstance()->getSpriteFrameByName(
            String::createWithFormat("bluediamond_%d.png", nBlueLv)->getCString());
        if (pBlueLvFrame)
        {
            pBlueLvSprite->setSpriteFrame(pBlueLvFrame);
        }
        if (3 != nBlueType && 7 != nBlueType)
        {
            pBlueYearSprite->setVisible(false);
        }
    }
    else
    {
        pTencentNode->setVisible(false);
    }

    // 玩家血条
    m_pHPBar = findChild<LoadingBar>(summonerPanelNode, "BloodBar/BloodLoadingBar");
    m_pHPBarD = findChild<LoadingBar>(summonerPanelNode, "BloodBar/BloodLoadingBar_red");
    m_pHPBar->setPercent(m_fHPValue / m_fHPMaxValue * 100);
    m_pHPBarD->setPercent(m_fHPValue / m_fHPMaxValue * 100);

  
    // 说话按钮
    Button* talkBtn = findChild<Button>(summonerPanelNode, "TalkButton");
    CHECK_RETURN_VOID(NULL != talkBtn);

    talkBtn->addClickEventListener(CC_CALLBACK_1(CUISummonerComponent::onHeroClick, this));
    
    if (m_pRole->getBattleHelper()->getBattleType() != EBATTLE_PVP &&
        m_pRole->getBattleHelper()->getBattleType() != EBATTLE_PVPROBOT)
    {
        talkBtn->setVisible(false);
    }else if (!m_bIsSelf)
    {
        talkBtn->setVisible(false);
    }        

    // 说的话
    m_pTalkText = findChild<Text>(summonerPanelNode, "TalkText/TextBar/Text");

    // 所有话
    std::string path = "TalkPanel/TalkPanel/TalkBar_%d";
    const char* btnPath = NULL;
    for (int i = 0; i < TalkCount; ++i)
    {
        btnPath = String::createWithFormat(path.c_str(), i+1)->getCString();
        auto btn = findChild<Button>(summonerPanelNode, btnPath);
        btn->setTag(i+1);
        btn->addClickEventListener(CC_CALLBACK_1(CUISummonerComponent::onTalkClick, this));

        // 文字
        findChild<Text>(btn, String::createWithFormat("%s", "TalkText")->getCString())
            ->setString(getLanguageString(CONF_UI_LAN, m_nLanIDs[i]));
    }
}

void CUISummonerComponent::onShowTalk(void* data)
{
    BattleCommandInfo* info = reinterpret_cast<BattleCommandInfo*>(data);
    if (m_nMyUserID == info->ExecuterId && info->Ext1 > 0 && info->Ext1<=6)
    {
        m_pTalkText->setString(getLanguageString(CONF_UI_LAN, m_nLanIDs[info->Ext1-1]));
        m_pTalkAction->play("Appear", false);
    }    
}

void CUISummonerComponent::onMaskClick(cocos2d::Ref* object)
{
    if (m_bIsSelf)
    {
        m_pMaskLayer->setTouchEnabled(false);
        if (m_pTalkPanelAction)
            m_pTalkPanelAction->play("Hide", false);
    }
}

void CUISummonerComponent::onHeroClick(cocos2d::Ref* object)
{
    if (m_bIsSelf && 
        (m_pRole->getBattleHelper()->getBattleType() == EBATTLE_PVP ||
        m_pRole->getBattleHelper()->getBattleType() == EBATTLE_PVPROBOT))
    {
        m_pMaskLayer->setTouchEnabled(true);
        m_pHeadAction->play("On", false);
        if (m_pTalkPanelAction)
            m_pTalkPanelAction->play("Appear", false);
    }
}

void CUISummonerComponent::onTalkClick(cocos2d::Ref* object)
{
    auto btn = dynamic_cast<Button*>(object);
    if (btn && m_bIsSelf)
    {
        m_pMaskLayer->setTouchEnabled(false);
        int talkID = btn->getTag();
        BattleCommandInfo cmd;
        cmd.CommandId = CommandTalk;
        cmd.ExecuterId = m_nMyUserID;
        cmd.Tick = m_pRole->getBattleHelper()->GameTick + 6;
        cmd.Ext1 = talkID;
        if (m_pRole->getBattleHelper()->getBattleType() == EBATTLE_PVP)
        {
            CGame::getInstance()->sendRequest(CMD_BATTLE, CMD_BAT_PVPCOMMANDCS, &cmd, sizeof(cmd));
        }
        else
        {
            m_pRole->getBattleHelper()->insertBattleCommand(cmd);
        }
    }

    if (m_pTalkPanelAction)
        m_pTalkPanelAction->play("Hide", false);
}

void CUISummonerComponent::setBarPercent(cocos2d::ui::LoadingBar* bar, const float& finalPercent, float& curPercent, float& speed, const float dt)
{
   if (speed >= 0)
   {
       curPercent += speed * dt;
       if (curPercent > finalPercent)
       {
           curPercent = finalPercent;
           speed = 0;
       }
   }
   else
   {
       curPercent += speed*dt;
       if (curPercent <= finalPercent)
       {
           curPercent = finalPercent;
           speed = 0;
       }
   }
   bar->setPercent(curPercent);
}

CUISummonerComponent::HPState CUISummonerComponent::CountHPState(const float& hpPercent)
{
    if (hpPercent >= 25)
    {
        return CUISummonerComponent::kNormal;
    }
    else if (hpPercent <= 0)
    {
        return CUISummonerComponent::kZero;
    }
    else
    {
        return CUISummonerComponent::kTips;        
    }
}

void CUISummonerComponent::robotTalk()
{
    CBattleHelper* pBattleHelper = m_pRole->getBattleHelper();
    if (pBattleHelper->GameTick / pBattleHelper->TickPerSecond < m_nNextTalkTime)
        return;

    int nRandNum = rand();
    if (m_nNextTalkTime <= 0)
    {
        m_nNextTalkTime = nRandNum % 30 + 10;
        return;
    }
    else
        m_nNextTalkTime += nRandNum % 60;

    if (nRandNum % 3 == 0)
        return;

    BattleCommandInfo cmd;
    cmd.CommandId = CommandTalk;
    cmd.ExecuterId = pBattleHelper->getEnmeyUserId();
    cmd.Tick = pBattleHelper->GameTick + 6;
    cmd.Ext1 = m_nNextTalkTime % TalkCount;

    pBattleHelper->insertBattleCommand(cmd);
}
