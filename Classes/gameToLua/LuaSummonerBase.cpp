#include "LuaSummonerBase.h"
#include "GameNetworkNode.h"
#include "LuaTools.h"
#include "Game.h"
#include "GameModel.h"

#include "LoadingScene.h"

// 单机进入关卡所需的Proxy
#include "SingleStageProxy.h"
#include "ProxyManager.h"
#include "Protocol.h"
#include "PvpProtocol.h"
#include "GameComm.h"

#include "CsbTool.h"
#include "LuaBasicConversions.h"
#include "TimeCalcTool.h"
#include "Hero.h"
#include "BattleDragLayer.h"
#include "BattleScene.h"
#include "BattleModels.h"
#include "CommonProxy.h"
#include "StageProtocol.h"
#include "GoldTestProtocol.h"
#include "HeroTestProtocol.h"
#include "TowerTestProtocol.h"
#include "UnionExpiditionProtocol.h"
#include "../cocos/network/HttpClient.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#   include "../extern/md5/MD5.h"
#	include "extern/qqHall/QQHallManager.h"
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
#   include "../extern/md5/MD5.h"
#	include "QQHallManager.h"
#	include "platform/android/jni/JniHelper.h"
#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS
#   include "MD5.h"
#	include "QQHallManager.h"
#endif

USING_NS_CC;
using namespace std;
using namespace network;

int initUserId(lua_State* l)
{
    int uid = luaL_checkinteger(l, 1);
    CGame::getInstance()->UserId = uid;
    return 0;
}

int connectToServer(lua_State* l)
{
    const char* ip = luaL_checkstring(l, 1);
	int port = luaL_checkint(l, 2);
    EServerConnType connType = (EServerConnType)luaL_checkint(l, 3);
	KxServer::KXSOCK_VERSION ipv = (KxServer::KXSOCK_VERSION)luaL_checkint(l, 4);
	// 设置为合法值
	ipv = ipv == KxServer::KXV_IPV4 ? KxServer::KXV_IPV4 : KxServer::KXV_IPV6;

	CCLOG("connect to server ip = %s, port = %d sockversion = %s", ip, port, ipv==KxServer::KXV_IPV4 ? "ipv4" : "ipv6");
    // 传入ip
    CGameNetworkNode *pNetwork = CGameNetworkNode::getInstance();
    std::function<void(bool)> Callback = nullptr;
    if (SERVER_CONN_SESSION == connType)
    {
        Callback = [&](bool success)->void
        {
            if (!success)
            {
                onLuaEvent(-101);
            }
            else
            {
                CCommonProxy *pCommProxy = new CCommonProxy;
                pCommProxy->init(CGame::getInstance()->EventMgr);
                CProxyManager::getInstance()->setCommProxy(pCommProxy);
                onLuaEvent(-100);
            }
        };
    }
    else
    {
        Callback = [&](bool success)->void
        {
            onLuaEventWithParamInt(31, success ? 1 : 0);
        };
    }
	
    pNetwork->connectToServer(ip, port, connType, ipv, Callback);
    return 0;
}

int reconnectToServer(lua_State *l)
{
    EServerConnType connType = (EServerConnType)luaL_checkint(l, 1);
	CGameNetworkNode *pNetwork = CGameNetworkNode::getInstance();
	std::function<void(bool)> ConnectCallback = nullptr;
	if (connType == SERVER_CONN_CHAT)
	{
		ConnectCallback = [](bool success)->void
		{
            //重连结果
            onLuaEventWithParamInt(31, success ? 1 : 0);
		};
	}
	else
	{
		ConnectCallback = [](bool success)->void
		{
            //重连结果
            if (success)
            {
                CCommonProxy *pCommProxy = dynamic_cast<CCommonProxy *>(CProxyManager::getInstance()->getCommProxy());
                if (nullptr == pCommProxy)
                {
                    CCommonProxy *pCommProxy = new CCommonProxy;
                    pCommProxy->init(CGame::getInstance()->EventMgr);
                    CProxyManager::getInstance()->setCommProxy(pCommProxy);
                }
            }
            onLuaEventWithParamInt(-103, success ? 1 : 0);
		};
	}
	
    pNetwork->reconnectToServer(connType, ConnectCallback);
	return 0;
}

void encryptBuffer(int mainCmd, int subCmd, char* buff, int len)
{
    int start = 0;
    while (start < len / 2)
    {
        char *num1 = buff + start;
        char *num2 = buff + (len - start - 1);

        int t = *num1 ^ MakeCommand(mainCmd, subCmd);
        *num1 = *num2 ^ MakeCommand(mainCmd, subCmd);
        *num2 = t;

        start += 1;
    }
}

int initModelData(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, 1, "Summoner.BufferData");
    if (NULL == buffer)
    {
        return 0;
    }
    CGameModel::getInstance()->init(buffer->getBuffer());
    return 0;
}

// 用于计算
class RoleCalc : public CSoldierModel
{
public:
    // 传入英雄的唯一ID，自动计算英雄的所有属性
    virtual bool init(int& heroId, int& heroLv, int& heroStar, std::vector<SoldierEquip>& effects)
    {        
        // 获取英雄配置并初始化
        const SoldierConfItem* conf = queryConfSoldier(heroId, heroStar);
        CHECK_RETURN(NULL != conf && CRoleModel::init(RT_SOLDIER, heroLv, &conf->Common, EBATTLE_NONE));

        // 保存基础属性
        BaseIntMap = getClassIntMap();
        BaseFloatMap = getClassFloatMap();

        // 计算装备加成
        CHECK_RETURN(calcEquipAddition(effects));
        applyEffect();

        std::map<EAttributeTypes, int> ClassIntMap = getClassIntMap();
        std::map<EAttributeTypes, float> ClassFloatMap = getClassFloatMap();
        
        // 统计加成效果到AddIntMap中
        for (auto& intEff : BaseIntMap)
        {
            if (intEff.second != ClassIntMap[intEff.first])
            {
                AddIntMap[intEff.first] = ClassIntMap[intEff.first] - intEff.second;
            }
        }
        // 统计加成效果到AddFloatMap中
        for (auto& floatEff : BaseFloatMap)
        {
            if (floatEff.second != ClassFloatMap[floatEff.first])
            {
                AddFloatMap[floatEff.first] = ClassFloatMap[floatEff.first] - floatEff.second;
            }
        }
        return true;
    }

    std::map<EAttributeTypes, int> BaseIntMap;
    std::map<EAttributeTypes, float> BaseFloatMap;
    std::map<EAttributeTypes, int> AddIntMap;
    std::map<EAttributeTypes, float> AddFloatMap;
};

int queryHeroAttribute(lua_State* l)
{
    int heroId = luaL_checkint(l, -4);
    int heroLv = luaL_checkint(l, -3);
    int heroStar = luaL_checkint(l, -2);
    int effectCount = luaL_getn(l, -1);
    std::vector<SoldierEquip> effects(effectCount);
    for (int i = 0; i < effectCount; ++i)
    {
        // 装备不超过6个
        if (i >= 6)
        {
            LOG("EquipCount error %d", effectCount);
            break;
        }

        lua_rawgeti(l, -1, i+1);
        LuaTools::getStructIntValueByKey(l, "confId", effects[i].confId);
        
        lua_getfield(l, -1, "EffectID");
        int effectIDCount = luaL_getn(l, -1);
        for (int j = 0; j < effectIDCount; ++j)
        {
            if (j < sizeof(effects[i].cEffectID) / sizeof(effects[i].cEffectID[0]))
            {
                lua_rawgeti(l, -1, j+1);
                effects[i].cEffectID[j] = lua_tointeger(l, -1);
                lua_pop(l, 1);
            }
        }
        lua_pop(l, 1);

        lua_getfield(l, -1, "EffectValue");
        int effectValueCount = luaL_getn(l, -1);
        for (int k = 0; k < effectValueCount; ++k)
        {
            if (k < sizeof(effects[i].sEffectValue) / sizeof(effects[i].sEffectValue[0]))
            {
                lua_rawgeti(l, -1, k+1);
                effects[i].sEffectValue[k] = lua_tointeger(l, -1);
                lua_pop(l, 1);
            }
        }
        lua_pop(l, 1);

        lua_pop(l, 1);
    }
    

    RoleCalc heroCalc;
    if (heroCalc.init(heroId, heroLv, heroStar, effects))
    {
        // 写入基础属性Map
        lua_newtable(l);
        for (auto& item : heroCalc.BaseIntMap)
        {
            lua_pushinteger(l, item.second);
            lua_rawseti(l, -2, item.first);
        }

        for (auto& item : heroCalc.BaseFloatMap)
        {
            lua_pushnumber(l, item.second);
            lua_rawseti(l, -2, item.first);
        }
        // 写入基础属性加成Map
        lua_newtable(l);
        for (auto& item : heroCalc.AddIntMap)
        {
            lua_pushinteger(l, item.second);
            lua_rawseti(l, -2, item.first);
        }

        for (auto& item : heroCalc.AddFloatMap)
        {
            lua_pushnumber(l, item.second);
            lua_rawseti(l, -2, item.first);
        }
        return 2;
    }
    return 0;
}

void setGlobalZOrederRecursion(Node* node, float globalZOrder)
{
    if (node != nullptr)
    {
        node->setGlobalZOrder(globalZOrder);
        Widget* widget = dynamic_cast<Widget*>(node);
        if (widget != nullptr)
        {
            widget->getVirtualRenderer()->setGlobalZOrder(globalZOrder);
        }
        for (auto& child : node->getChildren())
        {
            setGlobalZOrederRecursion(child, globalZOrder);
        }
    }
}

int setCsbGlobalZOrder(lua_State* l)
{
    Node* node = reinterpret_cast<Node*>(tolua_tousertype(l, -2, nullptr));
    float zorder = luaL_checknumber(l, -1);
    if (node != nullptr)
    {
        setGlobalZOrederRecursion(node, zorder);
    }
    return 0;
}

int cloneCsb(lua_State* l)
{
    int argc = lua_gettop(l);
    if (argc == 1)
    {
        Node* src = reinterpret_cast<Node*>(tolua_tousertype(l, -1, nullptr));
        Node* ret = CsbTool::cloneCsbNode(src);
        object_to_luaval<Node>(l, "cc.Node", (Node*)ret);
        return 1;
    }
    return 0;
}

int cloneBufferData(lua_State* l)
{
    // 要发送给服务端的数据
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer)
    {
        CBufferData* newBuffer = new CBufferData();
        newBuffer->init(buffer->getDataLength());
        newBuffer->writeData(buffer->getBuffer(), buffer->getDataLength());
        newBuffer->updateOffset(buffer->getOffset());

        // 传入BufferData作为参数
        LuaTools::pushClass(l, newBuffer, "Summoner.BufferData");
        return 1;
    }
    return 0;
}

int cloneBufferDataWithoutRead(lua_State* l)
{
    // 要发送给服务端的数据
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer)
    {
        CBufferData* newBuffer = new CBufferData();
        int buffLen = buffer->getDataLength() - buffer->getOffset();
        newBuffer->init(buffLen);
        newBuffer->writeData(buffer->getBuffer() + buffer->getOffset(), buffLen);

        // 传入BufferData作为参数
        LuaTools::pushClass(l, newBuffer, "Summoner.BufferData");
        return 1;
    }
    return 0;
}

int releaseBufferData(lua_State* l)
{
    // 要发送给服务端的数据
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer)
    {
        delete buffer;
    }
    return 0;
}

int request(lua_State* l)
{
    EServerConnType connType = SERVER_CONN_SESSION;
    // 要发送给服务端的数据
    CBufferData* buffer = nullptr;
    int argc = lua_gettop(l);
    if (argc == 1)
    {
        buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    }
    else if (argc == 2)
    {
        connType = (EServerConnType)luaL_checkint(l, -1);
        buffer = LuaTools::checkClass<CBufferData>(l, -2, "Summoner.BufferData");
    }
    
    if (NULL != buffer && buffer->getDataLength() >= sizeof(Head))
    {
        Head* head = reinterpret_cast<Head*>(buffer->getBuffer());
        // lua中不再计算包头的长度字段
        head->length = buffer->getDataLength();

        int mainCmd = head->MainCommand();
        int subCmd = head->SubCommand();
        // 根据命令加密
        if ((CMD_STAGE == mainCmd && CMD_STAGE_FINISH_CS == subCmd)
            || (CMD_GOLDTEST == mainCmd && CMD_GOLDTEST_FINISH_CS == subCmd)
            || (CMD_HEROTEST == mainCmd && CMD_HEROTEST_FINISH_CS == subCmd)
            || (CMD_TOWERTEST == mainCmd && CMD_TOWER_FINISH_CS == subCmd)
            || (CMD_UNIONEXPIDITION == mainCmd && CMD_UNIONEXPIDITION_STAGEFINISH_CS == subCmd))
        {
            CBufferData encryptBufferData;
            encryptBufferData.init(buffer);

            // 在新的buffer上加密数据
            encryptBuffer(mainCmd, 
                subCmd, 
                encryptBufferData.getBuffer() + sizeof(Head), 
                encryptBufferData.getDataLength() - sizeof(Head));

            CGameNetworkNode::getInstance()->sendData(encryptBufferData.getBuffer(), encryptBufferData.getDataLength(), connType);
        }
        else
        {
            CGameNetworkNode::getInstance()->sendData(buffer->getBuffer(), head->length, connType);
        }
    }
    return 0;
}

int raiseEvent(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer && buffer->getDataLength() >= sizeof(Head))
    {
        Head* head = reinterpret_cast<Head*>(buffer->getBuffer());
        // lua中不再计算包头的长度字段
        head->length = buffer->getDataLength();
        CGame::getInstance()->EventMgr->raiseEvent(head->cmd, buffer->getBuffer());
    }
    return 0;
}

int getSubCmd(lua_State* l)
{
    int cmd = luaL_checkint(l, 1);
    lua_pushinteger(l, cmd & 0x0000ffff);
    return 1;
}

int getMainCmd(lua_State* l)
{
    int cmd = luaL_checkint(l, 1);
    lua_pushinteger(l, cmd >> 16);
    return 1;
}

int makeCmd(lua_State* l)
{
    int mainCmd = luaL_checkint(l, -2);
    int subCmd = luaL_checkint(l, -1);
	lua_pushinteger(l, MakeCommand(mainCmd, subCmd));
    return 1;
}

// 进入Loading场景
int enterLoadingScene(lua_State* l)
{
    /*CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer && buffer->getDataLength() - buffer->getOffset() >= sizeof(RoomData))
    {
        RoomData* data = reinterpret_cast<RoomData*>(buffer->getBuffer() + buffer->getOffset());
        // 打开房间
        CRoomModel* room = CGameModel::getInstance()->openRoom();
        if (room->initByRoomData(data))
        {
            //设置玩家信息
            auto scene = CLoadingScene::create(room);
            Director::getInstance()->replaceScene(scene);
            lua_pushboolean(l, 1);
            return 1;
        }
    }
    lua_pushboolean(l, 0);*/
    return 1;
}

// 创建房间
int openAndinitRoom(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer && buffer->getDataLength() - buffer->getOffset() >= sizeof(RoomData))
    {
        RoomData* data = reinterpret_cast<RoomData*>(buffer->getBuffer() + buffer->getOffset());
        // 打开房间
        CRoomModel* room = CGameModel::getInstance()->openRoom();
        if (room->initByRoomData(data))
        {
            lua_pushboolean(l, 1);
            return 1;
        }
    }
    lua_pushboolean(l, 0);
    return 1;
}

int enterBattleScene(lua_State* l)
{
    CRoomModel* room = CGameModel::getInstance()->getRoom();
    if (NULL != room)
    {
        auto scene = CBattleLayer::createNewScene(room);
        if (NULL != scene)
        {
            Director::getInstance()->replaceScene(scene);
            lua_pushboolean(l, 1);
            return 1;
        }
    }

    lua_pushboolean(l, 0);
    return 1;
}

// 创建重播/回放房间
int openAndInitReplayRoom(lua_State* l)
{
    CBufferData* buffer = LuaTools::checkClass<CBufferData>(l, -1, "Summoner.BufferData");
    if (NULL != buffer && buffer->getDataLength() - buffer->getOffset() >= sizeof(RoomData))
    {
        RoomData* data = reinterpret_cast<RoomData*>(buffer->getBuffer() + buffer->getOffset());
        // 打开房间
        CReplayRoomModel* room = dynamic_cast<CReplayRoomModel*>(CGameModel::getInstance()->openReplayRoom());
        if (room->initByRoomData(data))
        {
            lua_pushboolean(l, 1);
            return 1;
        }
    }
    lua_pushboolean(l, 0);
    return 1;
}

// 进入重播/回放战斗场景
int enterReplayBattleScene(lua_State* l)
{
    CRoomModel* room = dynamic_cast<CRoomModel*>(CGameModel::getInstance()->getRoom());
    if (NULL != room)
    {
        auto scene = CBattleLayer::createReplayScene(room);
        if (NULL != scene)
        {
            Director::getInstance()->replaceScene(scene);
            lua_pushboolean(l, 1);
            return 1;
        }
    }

    lua_pushboolean(l, 0);
    return 1;
}

int replayAgain(lua_State* l)
{
    CBattleLayer *pBattleLayer = dynamic_cast<CBattleLayer *>(
        Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_BATTLE));
    if (nullptr != pBattleLayer)
    {
        pBattleLayer->replayAgain();
        lua_pushboolean(l, 1);
        return 1;
    }

    lua_pushboolean(l, 0);
    return 1;
}

int createBattleScene(lua_State* l)
{
    CRoomModel* room = CGameModel::getInstance()->getRoom();
    if (NULL != room)
    {
        auto scene = CBattleLayer::createNewScene(room);
        if (NULL != scene)
        {
            object_to_luaval<cocos2d::Scene>(l, "cc.Scene", scene);
            return 1;
        }
    }
    return 0;
}

int finishBattle(lua_State* l)
{
    // 清理BattleHelper
    Director::getInstance()->getRunningScene()->removeAllChildren();
    // 关闭房间
    CGameModel::getInstance()->closeRoom();
    return 1;
}

int initTestStage(lua_State* l)
{
    // 设置进入关卡的Proxy（目的是绕过服务器）
    // 后期服务器实现了关卡功能后，应该走服务器
    if (CProxyManager::getInstance()->getProxy(CMD_STAGE) == nullptr)
    {
        CSingleStageProxy *pCommProxy = new CSingleStageProxy();
        pCommProxy->init(CGame::getInstance()->EventMgr);
        CProxyManager::getInstance()->addProxy(CMD_STAGE, pCommProxy);
    }
    return 0;
}

////////////////////////////// 相关时间接口 //////////////////////////////////////
int getWNextTimeStamp(lua_State* l)
{
    time_t prev = luaL_checkint(l, -4);
    int nextMin = luaL_checkint(l, -3);
    int nextHour = luaL_checkint(l, -2);
    int wDay = luaL_checkint(l, -1);

    int nStamp = CTimeCalcTool::getWNextTimeStamp(prev, nextMin, nextHour, wDay);
    lua_pushinteger(l, nStamp);
    return 1;
}

int getNextTimeStamp(lua_State* l)
{
    time_t prev = luaL_checkint(l, -3);
    int nextMin = luaL_checkint(l, -2);
    int nextHour = luaL_checkint(l, -1);

    int nStamp = CTimeCalcTool::getNextTimeStamp(prev, nextMin, nextHour);
    lua_pushinteger(l, nStamp);
    return 1;
}

//////////////////////////////// 战斗相关接口 ////////////////////////////////////

// 是否可升级水晶
int isCrystalUpgradeable(lua_State* l)
{
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CHero* hero = dynamic_cast<CHero*>(CGame::getInstance(
            )->BattleHelper->getMainRole(CampType::ECamp_Blue));
        if (NULL != hero)
        {
            bool isReady = hero->canUpgradeCrystal();
            lua_pushboolean(l, isReady);
            return 1;
        }
    }
    return 0;
}

// 是否可出兵
int isHeroCardReady(lua_State* l)
{
    int cardIndex = luaL_checkint(l, -1);
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CHero* hero = dynamic_cast<CHero*>(CGame::getInstance(
            )->BattleHelper->getMainRole(CampType::ECamp_Blue));
        if (NULL != hero)
        {
            bool isReady = hero->canUseSoldierCard(cardIndex);
            lua_pushboolean(l, isReady);
            return 1;
        }
    }
    return 0;
}

int isSkillReady(lua_State* l)
{
    int skillIndex = luaL_checkint(l, -1);
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CHero* hero = dynamic_cast<CHero*>(CGame::getInstance(
            )->BattleHelper->getMainRole(CampType::ECamp_Blue));
        if (NULL != hero)
        {
            bool isReady = hero->canExecuteSkillIndex(skillIndex);
            lua_pushboolean(l, isReady);
            return 1;
        }
    }
    return 0;
}

int pauseBattle(lua_State* l)
{
    int isPauseAction = luaL_checkint(l, -1);
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CBattleLayer* battleLayer = CGame::getInstance()->BattleHelper->getBattleScene();
        if (battleLayer != NULL)
        {
            // 1 不暂停 2 暂停
            battleLayer->pauseBattle(isPauseAction == 2);
        }
    }
    return 0;
}

int resumeBattle(lua_State* l)
{
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CBattleLayer* battleLayer = CGame::getInstance()->BattleHelper->getBattleScene();
        if (battleLayer != NULL)
        {
            battleLayer->resumeBattle();
        }
    }
    return 0;
}

int doCamera(lua_State* l)
{
    int carmeraId = luaL_checkint(l, -1);
    if (CGame::getInstance()->BattleHelper != NULL)
    {
        CBattleDragLayer* dragLayer = dynamic_cast<CBattleDragLayer*>(
			Director::getInstance()->getRunningScene()->getChildByName("ScaleLayer")->getChildByTag(BLT_DRAG));
        if (dragLayer != NULL)
        {
            dragLayer->startCamera(carmeraId);
        }
    }
    return 0;
}

int cryptoMd5(lua_State* l)
{
    string s = luaL_checkstring(l, -1);
    CMD5 md5;
    md5.GenerateMD5((unsigned char*)s.c_str(), (int)s.length());
    
    lua_pushstring(l, md5.ToString().c_str());
    return 1;
}

int logout(lua_State* l)
{
    CGameNetworkNode::getInstance()->closeConnect();
    return 0;
}

int requestHttp(lua_State* l)
{
    const char* url = luaL_checkstring(l, -2);
    const char* post = luaL_checkstring(l, -1);
    HttpRequest* request = new (std::nothrow) HttpRequest();
    request->setUrl(url);
    request->setRequestType(HttpRequest::Type::POST);
    request->setRequestData(post, strlen(post));
    HttpClient::getInstance()->sendImmediate(request);
    request->release();
    return 0;
}

int requestHttpWithCallback(lua_State* l)
{
    const char* url = luaL_checkstring(l, -3);
    const char* post = luaL_checkstring(l, -2);
    const char* fun = luaL_checkstring(l, -1);
    ccHttpRequestCallback callback = [fun](HttpClient* client, HttpResponse* respone)
        {
            LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
            stack->clean();
            lua_getglobal(stack->getLuaState(), fun);
            if (lua_isnoneornil(stack->getLuaState(), -1))
            {
                lua_pop(stack->getLuaState(), 1);
                return;
            }
            stack->pushInt(respone->getResponseCode());
            stack->pushString(respone->getResponseData()->data());
            LuaEngine::getInstance()->getLuaStack()->executeFunction(2);
            stack->clean();
        };

    HttpRequest* request = new (std::nothrow) HttpRequest();
    request->setUrl(url);
    request->setRequestType(HttpRequest::Type::GET);
    request->setRequestData(post, strlen(post));
    request->setResponseCallback(callback);
    HttpClient::getInstance()->sendImmediate(request);
    request->release();
    return 0;
}

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
typedef struct EnumHWndsArg
{
    DWORD dwProcessId;
}EnumHWndsArg, *LPEnumHWndsArg;

BOOL isExist = FALSE;
BOOL CALLBACK lpEnumFunc(HWND hwnd, LPARAM lParam)
{
    EnumHWndsArg *pArg = (LPEnumHWndsArg)lParam;
    DWORD  processId;
    GetWindowThreadProcessId(hwnd, &processId);
    if (processId == pArg->dwProcessId)
    {
        isExist = TRUE;
        return FALSE;
    }
    return TRUE;
}

BOOL isExistPid(DWORD pid)
{
    isExist = FALSE;
    EnumHWndsArg wi;
    wi.dwProcessId = pid;
    EnumWindows(lpEnumFunc, (LPARAM)&wi);
    return isExist;
}
#endif

int webDialog(lua_State* l)
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
    const char* url = luaL_checkstring(l, -2);
    bool isBuyVip = lua_toboolean(l, -1) == 0 ? false : true;
    std::string browserPath = cocos2d::FileUtils::getInstance()->fullPathForFilename("SummonerBrowser.exe");
    browserPath += " ";
    browserPath += url;

    std::wstring wPath = StringUtf8ToWideChar(browserPath);
    wchar_t *wcht = new wchar_t[wPath.size() + 1];
    wcht[wPath.size()] = 0;
    std::copy(wPath.begin(), wPath.end(), wcht);

    STARTUPINFO si;
    memset(&si, 0, sizeof(si));
    PROCESS_INFORMATION pi;
    memset(&pi, 0, sizeof(pi));
    
    if (!CreateProcess(
     	NULL,   //  指向一个NULL结尾的、用来指定可执行模块的宽字节字符串   
        wcht, // 命令行字符串   
     	NULL, //    指向一个SECURITY_ATTRIBUTES结构体，这个结构体决定是否返回的句柄可以被子进程继承。   
     	NULL, //    如果lpProcessAttributes参数为空（NULL），那么句柄不能被继承。<同上>   
     	false,//    指示新进程是否从调用进程处继承了句柄。    
     	0,  //  指定附加的、用来控制优先类和进程的创建的标   
     	//  CREATE_NEW_CONSOLE  新控制台打开子进程   
     	//  CREATE_SUSPENDED    子进程创建后挂起，直到调用ResumeThread函数   
     	NULL, //    指向一个新进程的环境块。如果此参数为空，新进程使用调用进程的环境   
     	NULL, //    指定子进程的工作路径   
     	&si, // 决定新进程的主窗体如何显示的STARTUPINFO结构体   
     	&pi  // 接收新进程的识别信息的PROCESS_INFORMATION结构体   
     	))
    {
        delete []wcht;
     	return 0;
    }
    delete []wcht;

    if (isBuyVip)
    {
        return 0;
    }
    Director::getInstance()->getScheduler()->schedule(
        [=](float dt)
        {
            if (!isExistPid(pi.dwProcessId))
            {
                Director::getInstance()->getScheduler()->unschedule("PIDCHECK", Director::getInstance()->getRunningScene());
                onLuaEvent(41);
            }
        }, Director::getInstance()->getRunningScene(), 1, false, "PIDCHECK");
#endif
    return 0;
}

int getCmdLine(lua_State* l)
{
    /*lua_newtable(l);
    CCmdLine* pCmdLine = CCmdLine::getInstance();
    LuaTools::pushBaseKeyValue(l, pCmdLine->getCmdLineID(), "ID");
    LuaTools::pushBaseKeyValue(l, pCmdLine->getCmdLineKey(), "Key");
    LuaTools::pushBaseKeyValue(l, pCmdLine->getCmdLinePROCPARA(), "PROCPARA");*/

    lua_newtable(l);
    CQQHallManager* pQQHall = CQQHallManager::GetInstance();
    LuaTools::pushBaseKeyValue(l, pQQHall->getCmdLineID(), "ID");
    LuaTools::pushBaseKeyValue(l, pQQHall->getCmdLineKey(), "Key");
    LuaTools::pushBaseKeyValue(l, pQQHall->getCmdLinePROCPARA(), "PROCPARA");

    return 1;
}

void checkPush()
{
	auto luaStack = LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();
	
	luaStack->clean();

	lua_getglobal(luaState, "gCheckPush");
	if (lua_isnoneornil(luaState, -1))
	{
		CCLOG("get gCheckPush from lua failed");
		lua_pop(luaState, 1);
		return;
	}

	LuaEngine::getInstance()->getLuaStack()->executeFunction(0);
	LuaEngine::getInstance()->getLuaStack()->clean();
}

void clearPush()
{
	auto luaStack = LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaStack->clean();

	lua_getglobal(luaState, "gClearPush");
	if (lua_isnoneornil(luaState, -1))
	{
		CCLOG("get gClearPush from lua failed");
		lua_pop(luaState, 1);
		return;
	}

	LuaEngine::getInstance()->getLuaStack()->executeFunction(0);
	LuaEngine::getInstance()->getLuaStack()->clean();
}

void setLuaBackgroundValue(bool isBackground)
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    lua_pushboolean(l, isBackground);
    lua_setglobal(l, "gIsBackground");

    LuaEngine::getInstance()->getLuaStack()->clean();
}

int openURL(lua_State *l)
{
	auto url = luaL_checkstring(l, -1);

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32 
	auto result = ShellExecuteA(NULL, "open", url, NULL, NULL, SW_SHOWNORMAL);
	if ((int)result <= 32) { // 打开默认浏览器失败，尝试打开IE浏览器
		ShellExecuteA(NULL, "open", "iexplore.exe", url, NULL, SW_SHOWNORMAL);
	}
#elif CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
	auto packageName = JniHelper::callStaticStringMethod("org/cocos2dx/lib/Cocos2dxHelper", "getCocos2dxPackageName");
	JniHelper::callStaticVoidMethod(packageName + "/AppActivity", "openURL", url);
#endif

	return 0;
}

int LogPrint(lua_State * luastate)
{
	int nargs = lua_gettop(luastate);

	std::string t;
	for (int i = 1; i <= nargs; i++)
	{
		if (lua_istable(luastate, i))
			t += "table";
		else if (lua_isnone(luastate, i))
			t += "none";
		else if (lua_isnil(luastate, i))
			t += "nil";
		else if (lua_isboolean(luastate, i))
		{
			if (lua_toboolean(luastate, i) != 0)
				t += "true";
			else
				t += "false";
		}
		else if (lua_isfunction(luastate, i))
			t += "function";
		else if (lua_islightuserdata(luastate, i))
			t += "lightuserdata";
		else if (lua_isthread(luastate, i))
			t += "thread";
		else
		{
			const char * str = lua_tostring(luastate, i);
			if (str)
				t += lua_tostring(luastate, i);
			else
				t += lua_typename(luastate, lua_type(luastate, i));
		}
		if (i != nargs)
			t += "\t";
	}

	LOGDEBUG("[LUA-print] %s", t.c_str());
	return 0;
}

int closeGame(lua_State * luastate)
{
    Director::getInstance()->end();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    exit(0);
#endif
    return 0;
}

int hasSDK(lua_State *luastate)
{
	int type = luaL_checkint(luastate, 1);

	if (1 == type) {			// AnySDK
#if (ANYSDK)
		lua_pushboolean(luastate, true);
#else
		lua_pushboolean(luastate, false);
#endif
	}
	else if (2 == type) {		// 微信
#if (WEIXIN)
		lua_pushboolean(luastate, true);
#else
		lua_pushboolean(luastate, false);
#endif
	}
	else if (3 == type) {		// qq游戏大厅
#if (QQHALL)
		lua_pushboolean(luastate, true);
#else
		lua_pushboolean(luastate, false);
#endif
	}
	else {
		lua_pushboolean(luastate, false);
	}

	return 1;
}

bool regiestSummonerBase()
{
    auto luaState = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    
    lua_register(luaState, "initUserId", initUserId);
    lua_register(luaState, "connectToServer", connectToServer);
	lua_register(luaState, "reconnectToServer", reconnectToServer);
    lua_register(luaState, "initModelData", initModelData);
    lua_register(luaState, "queryHeroAttribute", queryHeroAttribute);
    lua_register(luaState, "setCsbGlobalZOrder", setCsbGlobalZOrder);
    lua_register(luaState, "cloneBufferData", cloneBufferData);
    lua_register(luaState, "cloneBufferDataWithoutRead", cloneBufferDataWithoutRead);
    lua_register(luaState, "releaseBufferData", releaseBufferData);
    lua_register(luaState, "request", request);
    lua_register(luaState, "requestHttpWithCallback", requestHttpWithCallback);
    lua_register(luaState, "raiseEvent", raiseEvent);
    lua_register(luaState, "makeCommand", makeCmd);
    lua_register(luaState, "getMainCmd", getMainCmd);
    lua_register(luaState, "getSubCmd", getSubCmd); 
    lua_register(luaState, "enterLoadingScene", enterLoadingScene);
    lua_register(luaState, "openAndinitRoom", openAndinitRoom);
    lua_register(luaState, "openAndInitReplayRoom", openAndInitReplayRoom);
    lua_register(luaState, "enterBattleScene", enterBattleScene);
    lua_register(luaState, "enterReplayBattleScene", enterReplayBattleScene);
    lua_register(luaState, "createBattleScene", createBattleScene);
    lua_register(luaState, "finishBattle", finishBattle);
    lua_register(luaState, "initTestStage", initTestStage);
    lua_register(luaState, "cloneCsb", cloneCsb);
    lua_register(luaState, "cryptoMd5", cryptoMd5);
    lua_register(luaState, "logout", logout);
    lua_register(luaState, "requestHttp", requestHttp);
    lua_register(luaState, "webDialog", webDialog);
    lua_register(luaState, "getCmdLine", getCmdLine);

    // 时间相关接口
    lua_register(luaState, "getWNextTimeStamp", getWNextTimeStamp);
    lua_register(luaState, "getNextTimeStamp", getNextTimeStamp);
    
    // 战斗相关接口
    lua_register(luaState, "isCrystalUpgradeable", isCrystalUpgradeable);
    lua_register(luaState, "isHeroCardReady", isHeroCardReady);
    lua_register(luaState, "isSkillReady", isSkillReady);
    lua_register(luaState, "pauseBattle", pauseBattle);
    lua_register(luaState, "resumeBattle", resumeBattle);
    lua_register(luaState, "doCamera", doCamera);
    lua_register(luaState, "replayAgain", replayAgain);

    //打印相关
    lua_register(luaState, "print", LogPrint);

	lua_register(luaState, "openURL", openURL);

    lua_register(luaState, "closeGame", closeGame);
	
	lua_register(luaState, "hasSDK", hasSDK);

    return true;
}

void onLuaRespone(CBufferData* buffer)
{
    if (NULL == buffer)
    {
        return;
    }

    // 回调Lua入口
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取NetHelper.onResponse方法
    lua_getglobal(l, "NetHelper");
	if (lua_isnoneornil(l, -1))
	{
		lua_pop(l, 1);
		return;
	}

    lua_getfield(l, 1, "onResponse");
    // 传入BufferData作为参数
    LuaTools::pushClass(l, buffer, "Summoner.BufferData");

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(1);
    // 调用Lua的NetHelper.onResponse方法
    //int ret = lua_pcall(l, 1, 0, 0);
	//if (ret)
	//{
	//		auto err = lua_tostring(l, -1);
	//		KXLOGDEBUG("----------------------------------------");
	//		KXLOGDEBUG("LUA ERROR: %s", err);
	//		KXLOGDEBUG("----------------------------------------");
	//}
    LuaEngine::getInstance()->getLuaStack()->clean();
}

// SDK登录成功
void onLuaLoginSDKSuccess(int pfType, std::string openId, std::string token)
{
    CCLOG("=================== onLuaLoginSDKSuccess ====================");
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取EventManager:raiseEvent方法
    lua_getglobal(l, "EventManager");
    if (lua_isnoneornil(l, -1))
    {
		CCLOG("======================== onLuaLoginSDKSuccess lua_isnoneornil return!!!");
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "raiseEvent");
    lua_getglobal(l, "EventManager");
    lua_pushinteger(l, 45);
    lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, pfType, "pfType");
    LuaTools::pushBaseKeyValue(l, openId, "openId");
    LuaTools::pushBaseKeyValue(l, token, "token");

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(3);
    //lua_pcall(l, 3, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

// qq付费成功
void onLuaPayQQSuccess(int type, std::string openId, std::string openKey, std::string pf, std::string pfKey)
{
	auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
	LuaEngine::getInstance()->getLuaStack()->clean();
	// 获取EventManager:raiseEvent方法
	lua_getglobal(l, "EventManager");
	if (lua_isnoneornil(l, -1))
	{
		lua_pop(l, 1);
		return;
	}

	lua_getfield(l, 1, "raiseEvent");
	lua_getglobal(l, "EventManager");

	lua_pushinteger(l, 41);
	lua_newtable(l);
	LuaTools::pushBaseKeyValue(l, type, "type");
	LuaTools::pushBaseKeyValue(l, openId, "openId");
	LuaTools::pushBaseKeyValue(l, openKey, "openKey");
	LuaTools::pushBaseKeyValue(l, pf, "pf");
	LuaTools::pushBaseKeyValue(l, pfKey, "pfKey");

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(3);
	//lua_pcall(l, 3, 0, 0);
	LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaBattleStart(int stageId)
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取BattleHelper.onBattleStart方法
    lua_getglobal(l, "BattleHelper");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "onBattleStart");
    lua_pushinteger(l, stageId);

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(1);
    //lua_pcall(l, 1, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaBattleOver()
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取BattleHelper.onBattleOver方法
    lua_getglobal(l, "BattleHelper");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "onBattleOver");

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(0);
    //lua_pcall(l, 0, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void debugLuaStack()
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    lua_getglobal(l, "printTrace");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(0);
    //lua_pcall(l, 0, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaEvent(int eventId)
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取EventManager:raiseEvent方法
    lua_getglobal(l, "EventManager");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "raiseEvent");
    lua_getglobal(l, "EventManager");
    lua_pushinteger(l, eventId);

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(2);
    //lua_pcall(l, 2, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaEventWithParamInt(int eventId, int param)
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取EventManager:raiseEvent方法
    lua_getglobal(l, "EventManager");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "raiseEvent");
    lua_getglobal(l, "EventManager");
    lua_pushinteger(l, eventId);
    lua_pushinteger(l, param);

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(3);
    //lua_pcall(l, 3, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaEventWithParamStr(int eventId, std::string param)
{
	auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
	LuaEngine::getInstance()->getLuaStack()->clean();
	// 获取EventManager:raiseEvent方法
	lua_getglobal(l, "EventManager");
	if (lua_isnoneornil(l, -1))
	{
		lua_pop(l, 1);
		return;
	}

	lua_getfield(l, 1, "raiseEvent");
	lua_getglobal(l, "EventManager");
	lua_pushinteger(l, eventId);
	lua_pushstring(l, param.c_str());

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(3);
	//lua_pcall(l, 3, 0, 0);
	LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaQuitBattle()
{
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取BattleHelper.onBattleOver方法
    lua_getglobal(l, "BattleHelper");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "quitBattle");

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(0);
    //lua_pcall(l, 0, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}

void onLuaPlayBgMusic(int musicId)
{
    // 回调Lua入口
    auto l = LuaEngine::getInstance()->getLuaStack()->getLuaState();
    LuaEngine::getInstance()->getLuaStack()->clean();
    // 获取MusicManager.playBgMusic方法
    lua_getglobal(l, "MusicManager");
    if (lua_isnoneornil(l, -1))
    {
        lua_pop(l, 1);
        return;
    }

    lua_getfield(l, 1, "playBgMusic");
    // 传入参数
    lua_pushinteger(l, musicId);
    lua_pushboolean(l, true);

	//参数为传入的参数个数
	LuaEngine::getInstance()->getLuaStack()->executeFunction(2);
    //lua_pcall(l, 2, 0, 0);
    LuaEngine::getInstance()->getLuaStack()->clean();
}