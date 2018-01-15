#include "LuaTools.h"
#include "ModelData.h"
/*
int setUserID(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setUserID(data);
    }
    return 0;
}

int setHeadID(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setHeadID(data);
    }
    return 0;
}

int setGold(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setGold(data);
    }
    return 0;
}

int addGold(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addGold(data);
    }
    return 0;
}

int setUserLevel(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setLevel(data);
    }
    return 0;
}

int setDiamond(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setDiamond(data);
    }
    return 0;
}

int setEnergy(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setEnergy(data);
    }
    return 0;
}

int setFlashcard(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setFlashcard(data);
	}
	return 0;
}

int getFlashcard(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
	if (NULL != model)
	{
		int data = model->getFlashcard();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int setFlashcard10(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
	int data = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setFlashcard10(data);
	}
	return 0;
}

int getFlashcard10(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
	if (NULL != model)
	{
		int data = model->getFlashcard10();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int setMaxEnergy(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setMaxEnergy(data);
    }
    return 0;
}

int setUserName(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    std::string str = luaL_checkstring(L, -1);
    if (NULL != model)
    {
        model->setUserName(str.c_str());
    }
    return 0;
}

int setUserExp(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setUserExp(data);
    }
    return 0;
}

int setVipLv(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setVipLv(data);
    }
    return 0;
}

int setVipPayment(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setVipPayment(data);
    }
    return 0;
}

int addVipPayment(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addVipPayment(data);
    }
    return 0;
}

int setVipScore(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setVipScore(data);
    }
    return 0;
}

int addVipScore(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->addVipScore(data);
    }
    return 0;
}

int setMonthCardStamp(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setMonthCardStamp(data);
    }
    return 0;
}

int setBuyGoldTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setBuyGoldTimes(data);
    }
    return 0;
}

int setBuyEnergyTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setBuyEnergyTimes(data);
    }
    return 0;
}

int set3StarRemainTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int data = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->set3StarRemainTimes(data);
    }
    return 0;
}

int setFreeHeroTimes(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
	int times = luaL_checkint(L, -1);
	if (NULL != model)
	{
		model->setFreeHeroTimes(times);
	}
	return 0;
}

int getFreeHeroTimes(lua_State* L)
{
	CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
	if (NULL != model)
	{
		int data = model->getFreeHeroTimes();
		lua_pushinteger(L, data);
		return 1;
	}
	return 0;
}

int setChangeNameFree(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        model->setChangeNameFree();
    }
    return 0;
}

int getUserID(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getUserID();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getHeadID(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getHeadID();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getGold(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getGold();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getUserLevel(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getLevel();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getDiamond(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getDiamond();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getEnergy(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getEnergy();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getMaxEnergy(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int data = model->getMaxEnergy();
        lua_pushinteger(L, data);
        return 1;
    }
    return 0;
}

int getUserName(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        std::string str = model->getUserName();
        lua_pushstring(L, str.c_str());
        return 1;
    }
    return 0;
}

int getUserExp(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int exp = model->getUserExp();
        lua_pushinteger(L, exp);
        return 1;
    }
    return 0;
}

int getVipLv(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int vipLv = model->getVipLv();
        lua_pushinteger(L, vipLv);
        return 1;
    }
    return 0;
}

int getVipPayment(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int payment = model->getVipPayment();
        lua_pushinteger(L, payment);
        return 1;
    }
    return 0;
}

int getVipScore(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int score = model->getVipScore();
        lua_pushinteger(L, score);
        return 1;
    }
    return 0;
}

int getMonthCardStamp(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int stamp = model->getMonthCardStamp();
        lua_pushinteger(L, stamp);
        return 1;
    }
    return 0;
}

int getBuyGoldTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int buyGoldTimes = model->getBuyGoldTimes();
        lua_pushinteger(L, buyGoldTimes);
        return 1;
    }
    return 0;
}

int getBuyEnergyTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int buyEnergyTimes = model->getBuyEnergyTimes();
        lua_pushinteger(L, buyEnergyTimes);
        return 1;
    }
    return 0;
}

int get3StarRemainTimes(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int remainTimes = model->get3StarRemainTimes();
        lua_pushinteger(L, remainTimes);
        return 1;
    }
    return 0;
}

int getChangeNameFree(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int free = model->getChangeNameFree();
        lua_pushinteger(L, free);
        return 1;
    }
    return 0;
}

int setTowerCoin(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int towerCoin = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setTowerCoin(towerCoin);
    }
    return 0;
}

int getTowerCoin(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int towerCoin = model->getTowerCoin();
        lua_pushinteger(L, towerCoin);
        return 1;
    }
    return 0;
}

int setPVPCoin(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int pvpCoin = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setPVPCoin(pvpCoin);
    }
    return 0;
}

int getPVPCoin(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int pvpCoin = model->getPVPCoin();
        lua_pushinteger(L, pvpCoin);
        return 1;
    }
    return 0;
}

int setUnionContrib(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int contrib = luaL_checkint(L, -1);
    if (NULL != model)
    {
        model->setUnionContrib(contrib);
    }
    return 0;
}

int getUnionContrib(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int unionContrib = model->getUnionContrib();
        lua_pushinteger(L, unionContrib);
        return 1;
    }

    return 0;
}


int getTotalSignDay(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int totalSignDay = model->getTotalSignDay();
        lua_pushinteger(L, totalSignDay);
        return 1;
    }

    return 0;
}

int setTotalSignDay(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int totalSignDay = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setTotalSignDay(totalSignDay);
        return 1;
    }

    return 0;
}

int getMonthSignDay(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int monthSignDay = model->getMonthSignDay();
        lua_pushinteger(L, monthSignDay);
        return 1;
    }

    return 0;
}

int setMonthSignDay(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int monthSignDay = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setMonthSignDay(monthSignDay);
        return 1;
    }

    return 0;
}

int getTotalSignFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int totalSignFlag = model->getTotalSignFlag();
        lua_pushinteger(L, totalSignFlag);
        return 1;
    }

    return 0;
}

int setTotalSignFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int totalSignFlag = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setTotalSignFlag(totalSignFlag);
        return 1;
    }

    return 0;
}

int getDaySignFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int daySignFlag = model->getDaySignFlag();
        lua_pushinteger(L, daySignFlag);
        return 1;
    }

    return 0;
}

int setDaySignFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int daySignFlag = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setDaySignFlag(daySignFlag);
        return 1;
    }

    return 0;
}

int getFirstPayFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int flag = model->getFirstPayFlag();
        lua_pushinteger(L, flag);
        return 1;
    }

    return 0;
}

int setFirstPayFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int flag = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setFirstPayFlag(flag);
        return 1;
    }

    return 0;
}

int getFundStartFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int flag = model->getFundStartFlag();
        lua_pushinteger(L, flag);
        return 1;
    }

    return 0;
}

int setFundStartFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int flag = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setFundStartFlag(flag);
        return 1;
    }

    return 0;
}

int getFundRewardFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -1, "Summoner.UserModel");
    if (NULL != model)
    {
        int flag = model->getFundRewardFlag();
        lua_pushinteger(L, flag);
        return 1;
    }

    return 0;
}

int setFundRewardFlag(lua_State* L)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(L, -2, "Summoner.UserModel");
    int flag = luaL_checkinteger(L, -1);
    if (NULL != model)
    {
        model->setFundRewardFlag(flag);
        return 1;
    }

    return 0;
}

int newUserModel(lua_State* L)
{
    CUserModel* model = new CUserModel();
    LuaTools::pushClass(L, model, "Summoner.UserModel");
    return 1;
}

int deleteUserModel(lua_State* l)
{
    CUserModel* model = LuaTools::checkClass<CUserModel>(l, -2, "Summoner.UserModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}

static const struct luaL_reg funUser[] =
{
    { "setUserID", setUserID },
    { "setHeadID", setHeadID },
    { "setGold", setGold },
    { "addGold", addGold },
    { "setUserLevel", setUserLevel },
    { "setDiamond", setDiamond },
    { "setTowerCoin", setTowerCoin },
    { "setPVPCoin", setPVPCoin },
    { "setUnionContrib", setUnionContrib },
    { "setEnergy", setEnergy },
	{ "setFlashcard", setFlashcard },
	{ "setFlashcard10", setFlashcard10 },
    { "setMaxEnergy", setMaxEnergy },
    { "setUserName", setUserName },
    { "setUserExp", setUserExp },
    { "setVipLv", setVipLv },
    { "setVipPayment", setVipPayment },
    { "addVipPayment", addVipPayment },
    { "setVipScore", setVipScore },
    { "addVipScore", addVipScore },
    { "setMonthCardStamp", setMonthCardStamp },
    { "setBuyGoldTimes", setBuyGoldTimes },
    { "setBuyEnergyTimes", setBuyEnergyTimes },
    { "set3StarRemainTimes", set3StarRemainTimes },
	{ "setFreeHeroTimes", setFreeHeroTimes },
    { "setChangeNameFree", setChangeNameFree },

    { "getUserID", getUserID },
    { "getHeadID", getHeadID },
    { "getGold", getGold },
    { "getUserLevel", getUserLevel },
    { "getDiamond", getDiamond },
    { "getTowerCoin", getTowerCoin },
    { "getPVPCoin", getPVPCoin },
    { "getUnionContrib", getUnionContrib },
    { "getEnergy", getEnergy },
	{ "getFlashcard", getFlashcard },
	{ "getFlashcard10", getFlashcard10 },
    { "getMaxEnergy", getMaxEnergy },
    { "getUserName", getUserName },
    { "getUserExp", getUserExp },
    { "getVipLv", getVipLv },
    { "getVipPayment", getVipPayment },
    { "getVipScore", getVipScore },
    { "getMonthCardStamp", getMonthCardStamp },
    { "getBuyGoldTimes", getBuyGoldTimes },
    { "getBuyEnergyTimes", getBuyEnergyTimes },
    { "get3StarRemainTimes", get3StarRemainTimes },
	{ "getFreeHeroTimes", getFreeHeroTimes },
    { "getChangeNameFree", getChangeNameFree },
    { "getTotalSignDay", getTotalSignDay },
    { "setTotalSignDay", setTotalSignDay },
    { "getMonthSignDay", getMonthSignDay },
    { "setMonthSignDay", setMonthSignDay },
    { "getTotalSignFlag", getTotalSignFlag },
    { "setTotalSignFlag", setTotalSignFlag },
    { "getDaySignFlag", getDaySignFlag },
    { "setDaySignFlag", setDaySignFlag },
    { "getFirstPayFlag", getFirstPayFlag },
    { "setFirstPayFlag", setFirstPayFlag },
    { "getFundStartFlag", getFundStartFlag },
    { "setFundStartFlag", setFundStartFlag },
    { "getFundRewardFlag", getFundRewardFlag },
    { "setFundRewardFlag", setFundRewardFlag },


    { NULL, NULL }
};*/

bool registeUserModel()
{
    //auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    //auto luaState = luaStack->getLuaState();

    //luaL_newmetatable(luaState, "Summoner.UserModel");
    //lua_pushstring(luaState, "__index");
    //lua_pushvalue(luaState, -2);
    //lua_settable(luaState, -3);
    //luaL_openlib(luaState, NULL, funUser, 0);

    //lua_register(luaState, "newUserModel", newUserModel);
    //lua_register(luaState, "deleteUserModel", deleteUserModel);

    return true;
}