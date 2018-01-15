#include "LuaTools.h"
#include "ModelData.h"
/*
int getActiveCount(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -1, "Summoner.OperateActiveModel");
    if (model)
    {
        int activeCount = model->getActiveCount();
        lua_pushinteger(L, activeCount);
        return 1;
    }
    return 0;
}

int delActiveCount(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -1, "Summoner.OperateActiveModel");
    if (model)
    {
        model->delActiveCount();
        return 1;
    }
    return 0;
}

int getActiveData(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -1, "Summoner.OperateActiveModel");
    if (model)
    {
        auto activeData = model->getActiveData();
        lua_newtable(L);
        int index = 1;
        for (const auto& data : activeData)
        {
            lua_newtable(L);
            LuaTools::pushBaseKeyValue(L, data.second.nActiveID, "activeID");
            LuaTools::pushBaseKeyValue(L, data.second.nActiveType, "activeType");
            LuaTools::pushBaseKeyValue(L, data.second.nLevLimit, "levLimit");
            LuaTools::pushBaseKeyValue(L, data.second.nStartTime, "startTime");
            LuaTools::pushBaseKeyValue(L, data.second.nEndTime, "endTime");
            lua_rawseti(L, -2, index++);
        }
        return 1;
    }
    return 0;
}


int  getActiveShopData(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -2, "Summoner.OperateActiveModel");
    if (model)
    {
        int activeID = luaL_checkint(L, -1);
        auto data = reinterpret_cast<SOperateActiveShop *>(model->getActiveShopData(activeID));
        if (data)
        {
            lua_newtable(L);
            const std::vector<SLoginActiveShopData> activeShopData = data->m_vecActiveShopData;
            int index = 1;
            for (auto& data : activeShopData)
            {
                lua_newtable(L);
                LuaTools::pushBaseKeyValue(L, data.nGiftID, "giftID");

                lua_newtable(L);
                int i = 1;
                for (auto& id : data.nGoodsID)
                {
                    lua_pushnumber(L, id);
                    lua_rawseti(L, -2, i++);
                }
                lua_setfield(L, -2, "goodsID");

                lua_newtable(L);
                int j = 1;
                for (auto& num : data.nGoodsNum)
                {
                    lua_pushnumber(L, num);
                    lua_rawseti(L, -2, j++);
                }
                lua_setfield(L, -2, "goodsNum");

                LuaTools::pushBaseKeyValue(L, data.nGoldType, "goldType");
                LuaTools::pushBaseKeyValue(L, data.nPrice, "price");
                LuaTools::pushBaseKeyValue(L, data.nSaleRate, "saleRate");
                LuaTools::pushBaseKeyValue(L, data.nMaxBuyTimes, "maxBuyTimes");
                LuaTools::pushBaseKeyValue(L, data.nBuyTimes, "buyTimes");

                lua_rawseti(L, -2, index++);
                //lua_rawseti(L, -2, data.nGiftID);
            }
        }
        return 1;
    }
    return 0;
}

int setActiveShopBuyTimes(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -4, "Summoner.OperateActiveModel");
    int activeID = luaL_checkint(L, -3);
    int giftID = luaL_checkint(L, -2);
    int buyTimes = luaL_checkint(L, -1);
    if (model)
    {
        model->setActiveShopBuyTimes(activeID, giftID, buyTimes);
        return 1;
    }
    return 0;
}

int getActiveTaskData(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -2, "Summoner.OperateActiveModel");
    if (model)
    {
        int activeID = luaL_checkint(L, -1);
        auto data = reinterpret_cast<SOperateActiveTask *>(model->getActiveTaskData(activeID));
        if (data)
        {
            lua_newtable(L);
            const std::vector<SLoginActiveTaskData> activeTaskData = data->m_vecActiveTaskData;
            int index = 1;
            for (auto& data : activeTaskData)
            {
                lua_newtable(L);
                LuaTools::pushBaseKeyValue(L, data.nFinishCondition, "finishCondition");
                LuaTools::pushBaseKeyValue(L, data.nTaskID, "taskID");

                lua_newtable(L);
                int i = 1;
                for (auto& condition : data.nConditionParam)
                {
                    lua_pushnumber(L, condition);
                    lua_rawseti(L, -2, i++);
                }
                lua_setfield(L, -2, "conditionParam");

                LuaTools::pushBaseKeyValue(L, data.nRewardDimand, "rewardDimand");
                LuaTools::pushBaseKeyValue(L, data.nRewardGold, "rewardGold");
                LuaTools::pushBaseKeyValue(L, data.nRewardEnergy, "rewardEnergy");

                lua_newtable(L);
                int j = 1;
                for (auto & id : data.nRewardGoodsID)
                {
                    lua_pushnumber(L, id);
                    lua_rawseti(L, -2, j++);
                }
                lua_setfield(L, -2, "rewardGoodsID");

                lua_newtable(L);
                int k = 1;
                for (auto & num : data.nRewardGoodsNum)
                {
                    lua_pushnumber(L, num);
                    lua_rawseti(L, -2, k++);
                }
                lua_setfield(L, -2, "rewardGoodsNum");

                LuaTools::pushBaseKeyValue(L, data.nValue, "value");
                LuaTools::pushBaseKeyValue(L, data.nFinishFlag, "finishFlag");

                lua_rawseti(L, -2, index++);
            }
            return 1;
        }
    }

    return 0;
}

int setActiveTaskProgress(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -4, "Summoner.OperateActiveModel");
    int activeID = luaL_checkint(L, -3);
    int taskID = luaL_checkint(L, -2);
    int value = luaL_checkint(L, -1);
    if (model)
    {
        model->setActiveTaskProgress(activeID, taskID, value);
        return 1;
    }
    return 0;
}

int setActiveTaskFinishFlag(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -4, "Summoner.OperateActiveModel");
    int activeID = luaL_checkint(L, -3);
    int taskID = luaL_checkint(L, -2);
    int flag = luaL_checkint(L, -1);
    if (model)
    {
        model->setActiveTaskFinishFlag(activeID, taskID, flag);
        return 1;
    }
    return 0;
}

int removeActiveData(lua_State* L)
{
    COperateActiveModel* model = LuaTools::checkClass<COperateActiveModel>(L, -3, "Summoner.OperateActiveModel");
    int activeID = luaL_checkint(L, -2);
    int activeType = luaL_checkint(L, -1);
    if (model)
    {
        model->removeActiveData(activeID, activeType);
        return 1;
    }
    return 0;
}

int newOperateActiveModel(lua_State* L)
{
    CShopModel* model = new CShopModel();
    LuaTools::pushClass(L, model, "Summoner.UserModel");
    return 1;
}

int deleteOperateActiveModel(lua_State* l)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(l, -2, "Summoner.ShopModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}


static const struct luaL_reg funOperateActive[] =
{
    { "getActiveCount", getActiveCount },
    { "delActiveCount", delActiveCount },
    { "getActiveData", getActiveData },
    { "getActiveShopData", getActiveShopData },
    { "setActiveShopBuyTimes", setActiveShopBuyTimes },
    { "getActiveTaskData", getActiveTaskData },
    { "setActiveTaskProgress", setActiveTaskProgress },
    { "setActiveTaskFinishFlag", setActiveTaskFinishFlag },
    { "removeActiveData", removeActiveData },
    { NULL, NULL }
};*/

bool registeOperateActiveModel()
{
    //auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    //auto luaState = luaStack->getLuaState();

    //luaL_newmetatable(luaState, "Summoner.OperateActiveModel");
    //lua_pushstring(luaState, "__index");
    //lua_pushvalue(luaState, -2);
    //lua_settable(luaState, -3);
    //luaL_openlib(luaState, NULL, funOperateActive, 0);

    //lua_register(luaState, "newOperateActiveModel", newOperateActiveModel);
    //lua_register(luaState, "deleteOperateActiveModel", deleteOperateActiveModel);

    return true;
}