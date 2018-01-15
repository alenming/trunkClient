#include "UIPause.h"
#include "Game.h"
#include "ConfLanguage.h"
#include "ResManager.h"
#include "DisplayCommon.h"
#include "GameComm.h"
#include "FMODAudioEngine.h"
#include "ResPool.h"

USING_NS_CC;
using namespace std;
using namespace ui;

CUIPause::CUIPause()
{

}

CUIPause::~CUIPause()
{

}

bool CUIPause::init()
{
    bool ret = Layer::init();
    auto pauseUI = CResManager::getInstance()->getCsbNode("ui_new/f_fight/PauseFightTips.csb");
    pauseUI->setContentSize(Director::getInstance()->getWinSize());
    addChild(pauseUI);

    CFMODAudioEngine::getInstance()->setPaused(true);
    // 语言包 + 按钮
    auto exitBtn = findChild<Button>(pauseUI, "MainPanel/ExitButton");
    exitBtn->addClickEventListener(CC_CALLBACK_1(CUIPause::onQuit, this));
    auto exitText = findChild<Text>(exitBtn, "ButtonText");
    exitText->setString(getLanguageString(CONF_UI_LAN, 972));

    auto resumeBtn = findChild<Button>(pauseUI, "MainPanel/ContinueButton");
    resumeBtn->addClickEventListener([this](Ref* sender){
        CBattleLayer* battleScene = CGame::getInstance()->BattleHelper->getBattleScene();
        battleScene->resumeBattle();
        CFMODAudioEngine::getInstance()->setPaused(false);
        removeFromParent();
    });
    auto resumeText = findChild<Text>(resumeBtn, "ButtonText_0");
    resumeText->setString(getLanguageString(CONF_UI_LAN, 973));

    return ret;
}

void CUIPause::onEnter()
{
    Layer::onEnter();
    ui::Helper::doLayout(this);
    CBattleLayer* battleScene = CGame::getInstance()->BattleHelper->getBattleScene();
    battleScene->pauseBattle();
}

void CUIPause::onExit()
{
    Layer::onExit();
}

void CUIPause::onQuit(cocos2d::Ref* sender)
{
    auto quitUI = CResManager::getInstance()->getCsbNode("ui_new/f_fight/ExitFigthTips.csb");
    quitUI->setContentSize(Director::getInstance()->getWinSize());
    addChild(quitUI);
    ui::Helper::doLayout(quitUI);

    // 语言包 + 按钮
    auto labelText = findChild<Text>(quitUI, "MainPanel/TipLabel1");
    labelText->setString(getLanguageString(CONF_UI_LAN, 974));
    
    auto exitBtn = findChild<Button>(quitUI, "MainPanel/ExitButton");
    exitBtn->addClickEventListener([](Ref* sender){
        CBattleLayer* battleScene = CGame::getInstance()->BattleHelper->getBattleScene();
        battleScene->quitBattle();
    });

    auto exitText = findChild<Text>(exitBtn, "Text");
    exitText->setString(getLanguageString(CONF_UI_LAN, 972));

    auto resumeBtn = findChild<Button>(quitUI, "MainPanel/ContinueButton");
    resumeBtn->addClickEventListener([quitUI](Ref* sender){
        quitUI->removeFromParent();
    });
    auto resumeText = findChild<Text>(resumeBtn, "Text");
    resumeText->setString(getLanguageString(CONF_UI_LAN, 973));
}
