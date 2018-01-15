#include "HelloWorldScene.h"
#include "GameModel.h"
#include "Game.h"
#include "BufferData.h"

USING_NS_CC;

Scene* HelloWorld::createScene()
{
    // 'scene' is an autorelease object
    auto scene = Scene::create();
    
    // 'layer' is an autorelease object
    auto layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    // return the scene
    return scene;
}

// on "init" you need to initialize your instance
bool HelloWorld::init()
{
    //////////////////////////////
    // 1. super init first
    if ( !Layer::init() )
    {
        return false;
    }


	Size visibleSize = Director::getInstance()->getVisibleSize();

	MenuItemImage *itemLogin = MenuItemImage::create("CloseNormal.png", "CloseNormal.png", [&](Ref* pSender){
		LOG("Login button pressed");

//		U8SDKInterface::getInstance()->login();
	});

	MenuItemImage *itemPay = MenuItemImage::create("CloseNormal.png", "CloseNormal.png", [&](Ref* pSender){
// 		LOG("Pay button pressed");
// 		U8PayParams param;
// 		memset(&param, 0, sizeof(param));
// 		param.buyNum = 999;
// 		param.price = 10;
// 		U8SDKInterface::getInstance()->pay(&param);
	});

	Menu *menu = Menu::create(itemLogin, itemPay, NULL);
	menu->alignItemsHorizontally();
	addChild(menu);
    return true;
}


void HelloWorld::menuCloseCallback(Ref* pSender)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WP8) || (CC_TARGET_PLATFORM == CC_PLATFORM_WINRT)
	MessageBox("You pressed the close button. Windows Store Apps do not implement a close button.","Alert");
    return;
#endif

    Director::getInstance()->end();

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    exit(0);
#endif
}

void HelloWorld::previewBattle()
{
    int stageId = 1;
    int stageLv = 1;
    CBufferData* bufferData = new CBufferData();
    bufferData->init(256);
    bufferData->writeData(stageId);
    bufferData->writeData(stageLv);
    bufferData->writeData(1);
    bufferData->writeData(0);              
    bufferData->writeData(0);              
    bufferData->writeData(1);              
    
    int userId = -1;
    int userLv = 1;
    int cardCount = 7;
    std::string userName = "Player";
    bufferData->writeData(userId);        
    bufferData->writeData(userLv);        
    bufferData->writeData(1);
    bufferData->writeData(0);
    bufferData->writeData(cardCount);
    bufferData->writeData(userName);

    int heroId = UserDefault::getInstance()->getIntegerForKey("myhero", 1000);
    bufferData->writeData(heroId);

    for (int i = 1; i < cardCount; i++)
    {
        std::string cardIdStr = "mysolider" +i;
        std::string cardStarStr = "star" +i;
        std::string cardTalentStr = "talent" +i;
        std::string cardLevelStr = "level" +i;

        int cardId = UserDefault::getInstance()->getIntegerForKey(cardIdStr.c_str(), 10200);
        int cardStar = UserDefault::getInstance()->getIntegerForKey(cardStarStr.c_str(), 2);
        int cardTalent = UserDefault::getInstance()->getIntegerForKey(cardTalentStr.c_str(), 2);
        int cardLevel = UserDefault::getInstance()->getIntegerForKey(cardLevelStr.c_str(), 1);
        bufferData->writeData(cardId);
        bufferData->writeData(cardLevel);
        bufferData->writeData(cardStar);
        bufferData->writeData(0);
        bufferData->writeData(cardTalent);
        bufferData->writeData(1);
        bufferData->writeData(1);
        bufferData->writeData(0);
    } 

    bufferData->resetOffset();
    RoomData* data = reinterpret_cast<RoomData*>(bufferData->getBuffer() + bufferData->getOffset());
    CRoomModel* room = CGameModel::getInstance()->openRoom();
    room->initByRoomData(data);

    delete bufferData;

    CGame::getInstance()->UserId = userId;

}
