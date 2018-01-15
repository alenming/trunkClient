#include "LoadingScene.h"
#include "BattleScene.h"
#include "ConfOther.h"
#include "GameComm.h"
#include "ResManager.h"

#include <set>
using namespace std;

Scene* CLoadingScene::create(CRoomModel* room)
{
	auto ret = Scene::create();
	auto layer = CLoadingLayer::create();
	layer->RoomModel = room;
	ret->addChild(layer);
	return ret;
}

bool CLoadingScene::init()
{
	CHECK_RETURN(Scene::init());

	auto loadingLayer = CLoadingLayer::create();
	this->addChild(loadingLayer);

	return true;
}

bool CLoadingLayer::init()
{
	CHECK_RETURN(Layer::init());

	m_nResCount = 0;
	m_nFinish = 0;

	lb = cocos2d::Label::createWithTTF("", "fonts/arial.ttf", 40);
	lb->setPosition(Director::getInstance()->getVisibleSize() / 2);
	this->addChild(lb);
	
	return true;
}

void getNeedRes(CRoomModel* room, std::set<int>& ress, std::set<std::string>& csbRes)
{
    if (room->getBattleType() == EBATTLE_CHAPTER)
    {
        auto stage = queryConfStage(room->getStageId());
        for (auto& monster : stage->Monsters)
        {
            const SRoleResItem* monsters = queryConfSRoleResInfo(monster, 0);
            for (auto &monsterRes : monsters->ResIDs)
            {
                ress.insert(monsterRes);
            }
        }

        const SRoleResItem* boss = queryConfSRoleResInfo(stage->Boss, 0);
        for (auto &bossRes : boss->ResIDs)
        {
            ress.insert(bossRes);
        }

        const StageSceneConfItem* sceneConfItem = queryConfStageScene(stage->StageSenceID);
        csbRes.insert(sceneConfItem->FrontScene_ccs);
        csbRes.insert(sceneConfItem->FightScene_ccs);
        csbRes.insert(sceneConfItem->BgScene_ccs);
        csbRes.insert(sceneConfItem->FarScene_ccs);
    }

    for (auto& player : room->getPlayers())
    {
        CPlayerModel *pPlayer = dynamic_cast<CPlayerModel*>(player.second);
        if (NULL == pPlayer)
        {
            continue;
        }

        for (auto& heroModel : pPlayer->getSoldierCards())
        {
            const SRoleResItem* heros = queryConfSRoleResInfo(heroModel->getSoldId(), heroModel->getStar());
            for (auto &heroRes : heros->ResIDs)
            {
                ress.insert(heroRes);
            }
        }
        
        const SRoleResItem* summoner = queryConfSRoleResInfo(pPlayer->getMainRoleId(), 0);
        for (auto &summonerRes : summoner->ResIDs)
        {
            ress.insert(summonerRes);
        }
    }

    // 公共资源
    const SRoleResItem* commRes = queryConfSRoleResInfo(0, 0);
    for (auto &comm : commRes->ResIDs)
    {
        ress.insert(comm);
    }
}

void CLoadingLayer::onEnter()
{
	Layer::onEnter();

    Director::getInstance()->purgeCachedData();
    set<int> ress;
    set<std::string> csbRess;
    ress.insert(0);
    getNeedRes(RoomModel, ress, csbRess);

	CConfAnimationRes* confRes = dynamic_cast<CConfAnimationRes*>(CConfManager::getInstance()->getConf(CONF_RESPATH));
	if (NULL == confRes)
	{
		assert(!"ConfResPath is null");
	}

	//计算总个数
	bool bNeedLoad = false;
    std::map<int, void*> mapResInfo = confRes->getDatas();
	for (auto iter : mapResInfo)
	{
        SResPathItem* item = static_cast<SResPathItem*>(iter.second);
        if (ress.find(iter.first) == ress.end()
            && csbRess.find(item->Path) == csbRess.end())
        {
            continue;
        }

        if (item->ResType == RT_ARMATURE)
        {
            bNeedLoad = CResManager::getInstance()->addPreloadArmature(item->Path, [&](const std::string&, bool){
                ++m_nFinish;
                std::string str = toolToStr(m_nFinish) + "/" + toolToStr(m_nResCount);
                lb->setString(str);
            });
            m_nResCount += bNeedLoad ? 1 : 0;
        }
        else if (item->ResType == RT_CSB2)
        {
            bNeedLoad = CResManager::getInstance()->addPreloadRes(item->Path, [&](const std::string&, bool){
                ++m_nFinish;
                std::string str = toolToStr(m_nFinish) + "/" + toolToStr(m_nResCount);
                lb->setString(str);
            });
            m_nResCount += bNeedLoad ? 1 : 0;
        }
        else
        {
            bNeedLoad = CResManager::getInstance()->addPreloadRes(item->Path, item->AtlasPath, [&](const std::string&, bool){
                ++m_nFinish;
                std::string str = toolToStr(m_nFinish) + "/" + toolToStr(m_nResCount);
                lb->setString(str);
            });
            m_nResCount += bNeedLoad ? 1 : 0;
        }
	}

	CResManager::getInstance()->setFinishCallback([&](int, int){
		auto scene = CBattleLayer::createNewScene(RoomModel);
		Director::getInstance()->replaceScene(scene);
	});

	CResManager::getInstance()->startResAsyn();
}

void CLoadingLayer::ChangeFrameOriginalAndRect(const char* fileName)
{
	auto spriteFrame = SpriteFrameCache::getInstance()->getSpriteFrameByName(fileName);
	if (nullptr == spriteFrame)
	{
		log("HPBar texture: %s is null", fileName);
		return;
	}

	Rect rect = spriteFrame->getRect();
	auto orignSize = spriteFrame->getOriginalSize();
	rect.size.width = 1;
	orignSize.width = 1;
	if (spriteFrame->isRotated())
	{
		rect.origin.y += 1;
	}
	else
	{
		rect.origin.x += 1;
	}
	spriteFrame->setRect(rect);
	spriteFrame->setOriginalSize(orignSize);
}

