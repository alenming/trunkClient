#include "LuaTools.h"
#include "ModelData.h"

int getShopCount(lua_State* L)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(L, -1, "Summoner.ShopModel");
    if (model)
    {
        int shopCount = model->getShopCount();
        lua_pushinteger(L, shopCount);
        return 1;
    }
    return 0;
}

int getShopModelData(lua_State* L)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(L, -2, "Summoner.ShopModel");
    if (model)
    {
        int shopType = luaL_checkint(L, -1);
        auto data = reinterpret_cast<ShopData *>(model->getShopModelData(shopType));
        if (NULL != data)
        {
            lua_newtable(L);
            LuaTools::pushBaseKeyValue(L, data->nShopType, "nShopType");
            LuaTools::pushBaseKeyValue(L, data->nCount, "nCount");
            LuaTools::pushBaseKeyValue(L, data->nCurCount, "nCurCount");
            LuaTools::pushBaseKeyValue(L, data->nFreshedCount, "nFreshedCount");
            LuaTools::pushBaseKeyValue(L, data->nNextFreshTime, "nNextFreshTime");

            lua_newtable(L);
            const std::vector<ShopGoodsData> goodsData = data->m_vecGoodsData;
            for (auto& data : goodsData)
            {
                lua_newtable(L);
                LuaTools::pushBaseKeyValue(L, data.nIndex, "nIndex");
                LuaTools::pushBaseKeyValue(L, data.nGoodsShopID, "nGoodsShopID");
                LuaTools::pushBaseKeyValue(L, data.nGoodsID, "nGoodsID");
                LuaTools::pushBaseKeyValue(L, data.nGoodsNum, "nGoodsNum");
                LuaTools::pushBaseKeyValue(L, data.nCoinType, "nCoinType");
                LuaTools::pushBaseKeyValue(L, data.nCoinNum, "nCoinNum");
                LuaTools::pushBaseKeyValue(L, data.nSale, "nSale");

                lua_rawseti(L, -2, data.nIndex);
            }
            lua_setfield(L, -2, "GoodsData");

            return 1;
        }
        return 0;
    }
    return 0;
}

int setShopModelData(lua_State* L)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(L, -2, "Summoner.ShopModel");
    if (model)
    {
        ShopData shopData;

        lua_getfield(L, -1, "nShopType");
        shopData.nShopType = lua_tointeger(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "nCount");
        shopData.nCount = lua_tointeger(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "nCurCount");
        shopData.nCurCount = lua_tointeger(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "nFreshedCount");
        shopData.nFreshedCount = lua_tointeger(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "nNextFreshTime");
        shopData.nNextFreshTime = lua_tointeger(L, -1);
        lua_pop(L, 1);

        lua_getfield(L, -1, "GoodsData");
        for (int i = 1; i <= shopData.nCurCount; ++i)
        {
            ShopGoodsData shopGoodsData;

            lua_rawgeti(L, -1, i);
            lua_getfield(L, -1, "nIndex");
            shopGoodsData.nIndex = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nGoodsShopID");
            shopGoodsData.nGoodsShopID = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nGoodsID");
            shopGoodsData.nGoodsID = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nGoodsNum");
            shopGoodsData.nGoodsNum = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nCoinType");
            shopGoodsData.nCoinType = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nCoinNum");
            shopGoodsData.nCoinNum = lua_tointeger(L, -1);
            lua_pop(L, 1);

            lua_getfield(L, -1, "nSale");
            shopGoodsData.nSale = lua_tointeger(L, -1);
            lua_pop(L, 1);

            shopData.m_vecGoodsData.push_back(shopGoodsData);
            lua_pop(L, 1);
        }
        model->setShopModelData(shopData);

        return 1;
    }
    return 0;
}

int isFirstCharge(lua_State* L)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(L, -2, "Summoner.ShopModel");
    if (model)
    {
        int pID = luaL_checkint(L, -1);
        bool ret = model->isFirstCharge(pID);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}

int setFirstChargeState(lua_State* L)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(L, -2, "Summoner.ShopModel");
    if (model)
    {
        int pID = luaL_checkint(L, -1);
        model->setFirstChargeState(pID);
        return 1;
    }
    return 0;
}

int newShopModel(lua_State* L)
{
    CShopModel* model = new CShopModel();
    LuaTools::pushClass(L, model, "Summoner.UserModel");
    return 1;
}

int deleteShopModel(lua_State* l)
{
    CShopModel* model = LuaTools::checkClass<CShopModel>(l, -2, "Summoner.ShopModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}


static const struct luaL_reg funShop[] =
{
    { "getShopCount", getShopCount },
    { "getShopModelData", getShopModelData },
    { "setShopModelData", setShopModelData },
    { "isFirstCharge", isFirstCharge },
    { "setFirstChargeState", setFirstChargeState },
    { NULL, NULL }
};

bool registeShopModel()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.ShopModel");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funShop, 0);

    lua_register(luaState, "newShopModel", newShopModel);
    lua_register(luaState, "deleteShopModel", deleteShopModel);

    return true;
}