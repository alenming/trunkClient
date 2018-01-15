#include "LuaMailModel.h"
#include "LuaTools.h"
#include "ModelData.h"

int addMail(lua_State* L)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(L, -2, "Summoner.MailModel");

	MailInfo info;
    DropItemInfo itemInfo;

    LuaTools::getStructBoolValueByKey(L, "isGetContent", info.isGetContent);
    LuaTools::getStructIntValueByKey(L, "mailID", info.mailID);
    LuaTools::getStructIntValueByKey(L, "mailType", info.mailType);
    LuaTools::getStructIntValueByKey(L, "mailConfID", info.mailConfID);
    LuaTools::getStructIntValueByKey(L, "sendTimeStamp", info.sendTimeStamp);
    LuaTools::getStructStringValueByKey(L, "title", info.title);
    LuaTools::getStructStringValueByKey(L, "sender", info.sender);
    LuaTools::getStructStringValueByKey(L, "content", info.content);

    lua_getfield(L, -1, "vecItem");
	int count = luaL_getn(L, -1);
	for (int i = 1; i <= count; ++i)
	{
        lua_rawgeti(L, -1, i);
        LuaTools::getStructIntValueByKey(L, "id", itemInfo.id);
        LuaTools::getStructIntValueByKey(L, "num", itemInfo.num);
        LuaTools::getStructIntValueByKey(L, "crit", itemInfo.crit);
        info.items.push_back(itemInfo);
        lua_pop(L, 1);
	}
    lua_pop(L, 1);

	if (model)
	{
		bool ret = model->addMail(info);
		lua_pushboolean(L, ret);
		return 1;
	}
	return 0;
}

int setMail(lua_State* L)
{
    CMailModel* model = LuaTools::checkClass<CMailModel>(L, -2, "Summoner.MailModel");

    MailInfo info;
    DropItemInfo itemInfo;

    LuaTools::getStructBoolValueByKey(L, "isGetContent", info.isGetContent);
    LuaTools::getStructIntValueByKey(L, "mailID", info.mailID);
    LuaTools::getStructIntValueByKey(L, "mailType", info.mailType);
    LuaTools::getStructIntValueByKey(L, "mailConfID", info.mailConfID);
    LuaTools::getStructIntValueByKey(L, "sendTimeStamp", info.sendTimeStamp);
    LuaTools::getStructStringValueByKey(L, "title", info.title);
    LuaTools::getStructStringValueByKey(L, "sender", info.sender);
    LuaTools::getStructStringValueByKey(L, "content", info.content);

    lua_getfield(L, -1, "vecItem");
    int count = luaL_getn(L, -1);
    for (int i = 1; i <= count; ++i)
    {
        lua_rawgeti(L, -1, i);
        LuaTools::getStructIntValueByKey(L, "id", itemInfo.id);
        LuaTools::getStructIntValueByKey(L, "num", itemInfo.num);
        LuaTools::getStructIntValueByKey(L, "crit", itemInfo.crit);
        info.items.push_back(itemInfo);
        lua_pop(L, 1);
    }
    lua_pop(L, 1);

    if (model)
    {
        bool ret = model->setMail(info);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}

int removeMail(lua_State* L)
{
    CMailModel* model = LuaTools::checkClass<CMailModel>(L, -2, "Summoner.MailModel");
    int mailKey = luaL_checkint(L, -1);
    if (model)
    {
        bool ret = model->removeMail(mailKey);
        lua_pushboolean(L, ret);
        return 1;
    }
    return 0;
}


int getMail(lua_State* L)
{
    CMailModel* model = LuaTools::checkClass<CMailModel>(L, -2, "Summoner.MailModel");
    int mailKey = luaL_checkint(L, -1);
    if (model)
    {
        auto mailInfo = model->getMail(mailKey);
        if (mailInfo)
        {
            lua_newtable(L);
            LuaTools::pushBaseKeyValue(L, mailInfo->isGetContent, "isGetContent");
            LuaTools::pushBaseKeyValue(L, mailInfo->mailID, "mailID");
            LuaTools::pushBaseKeyValue(L, mailInfo->mailType, "mailType");
            LuaTools::pushBaseKeyValue(L, mailInfo->mailConfID, "mailConfID");
            LuaTools::pushBaseKeyValue(L, mailInfo->sendTimeStamp, "sendTimeStamp");
            LuaTools::pushBaseKeyValue(L, mailInfo->title, "title");
            LuaTools::pushBaseKeyValue(L, mailInfo->sender, "sender");
            LuaTools::pushBaseKeyValue(L, mailInfo->content, "content");
            lua_newtable(L);
            for (unsigned int i = 0; i < mailInfo->items.size(); ++i)
            {
                lua_newtable(L);
                LuaTools::pushBaseKeyValue(L, mailInfo->items[i].id, "id");
                LuaTools::pushBaseKeyValue(L, mailInfo->items[i].num, "num");
                LuaTools::pushBaseKeyValue(L, mailInfo->items[i].crit, "cirt");
                lua_rawseti(L, -2, i + 1);
            }
            lua_setfield(L, -2, "vecItem");
            return 1;
        }
    }
    return 0;
}

int getMails(lua_State* L)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(L, -1, "Summoner.MailModel");
	if (model)
	{
		lua_newtable(L);
		auto mailsInfo = model->getMails();
		for (auto iter = mailsInfo.begin(); iter != mailsInfo.end(); ++iter)
		{
			lua_newtable(L);

			auto mailInfo = iter->second;
            LuaTools::pushBaseKeyValue(L, mailInfo.isGetContent, "isGetContent");
			LuaTools::pushBaseKeyValue(L, mailInfo.mailID, "mailID");
            LuaTools::pushBaseKeyValue(L, mailInfo.mailType, "mailType");
            LuaTools::pushBaseKeyValue(L, mailInfo.mailConfID, "mailConfID");
            LuaTools::pushBaseKeyValue(L, mailInfo.sendTimeStamp, "sendTimeStamp");
			LuaTools::pushBaseKeyValue(L, mailInfo.title, "title");
			LuaTools::pushBaseKeyValue(L, mailInfo.sender, "sender");
			LuaTools::pushBaseKeyValue(L, mailInfo.content, "content");
			lua_newtable(L);
			for (size_t i = 0; i < mailInfo.items.size(); ++i)
			{
				lua_newtable(L);
				LuaTools::pushBaseKeyValue(L, mailInfo.items[i].id, "id");
				LuaTools::pushBaseKeyValue(L, mailInfo.items[i].num, "num");
				LuaTools::pushBaseKeyValue(L, mailInfo.items[i].crit, "crit");
				lua_rawseti(L, -2, i + 1);
			}
			lua_setfield(L, -2, "vecItem");

			lua_rawseti(L, -2, iter->first);
		}
		return 1;
	}
	return 0;
}

int addUnionMail(lua_State* L)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(L, -4, "Summoner.MailModel");
	MailTips tip;
	tip.tipsType = luaL_checkint(L, -3);
    tip.extend = luaL_checkint(L, -2);
	strcpy(tip.unionName, luaL_checkstring(L, -1));
	if (model)
	{		
		model->addUnionMail(tip);
	}
	return 0;
}

int delUnionMail(lua_State* L)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(L, -1, "Summoner.MailModel");
	if (model)
	{
		model->delUnionMail();
	}
	return 0;
}

int getUnionMail(lua_State* L)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(L, -1, "Summoner.MailModel");
	if (model)
	{
		auto mail = model->getUnionMail();
		lua_newtable(L);
		LuaTools::pushBaseKeyValue(L, mail.tipsType, "tipsType");
		LuaTools::pushBaseKeyValue(L, mail.unionName, "unionName");
        LuaTools::pushBaseKeyValue(L, mail.extend, "extend");

        return 1;
	}
	return 0;
}

int getMailCount(lua_State* L)
{
    CMailModel* model = LuaTools::checkClass<CMailModel>(L, -1, "Summoner.MailModel");
    if (model)
    {
        lua_pushinteger(L, model->getMailCount());
        return 1;
    }
    return 0;
}

int newMailModel(lua_State* L)
{
	CMailModel* model = new CMailModel();
	LuaTools::pushClass(L, model, "Summoner.MailModel");
	return 1;
}

int deleteMailModel(lua_State* l)
{
	CMailModel* model = LuaTools::checkClass<CMailModel>(l, -2, "Summoner.MailModel");
	if (NULL != model)
	{
		delete model;
	}
	return 0;
}


static const struct luaL_reg funMail[] =
{
	{ "addMail", addMail },
    { "setMail", setMail },
    { "removeMail", removeMail },
    { "getMail", getMail },
    { "getMails", getMails },
	{ "addUnionMail", addUnionMail },
	{ "delUnionMail", delUnionMail },
	{ "getUnionMail", getUnionMail },
    { "getMailCount", getMailCount },
	{ NULL, NULL }
};

bool registeMailModel()
{
	auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
	auto luaState = luaStack->getLuaState();

	luaL_newmetatable(luaState, "Summoner.MailModel");
	lua_pushstring(luaState, "__index");
	lua_pushvalue(luaState, -2);
	lua_settable(luaState, -3);
	luaL_openlib(luaState, NULL, funMail, 0);

	lua_register(luaState, "newMailModel", newMailModel);
	lua_register(luaState, "deleteMailModel", deleteMailModel);

	return true;
}