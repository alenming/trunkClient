#include "LuaTools.h"
#include "LuaSuperRichText.h"
#include "SuperRichText.h"
#include "LuaBasicConversions.h"

int setString(lua_State* tolua_S)
{
    if (nullptr == tolua_S)
        return 0;

    int argc = 0;
    SuperRichText* cobj = nullptr;
    bool ok = true;

#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
#endif

#if COCOS2D_DEBUG >= 1
    if (!tolua_isusertype(tolua_S, 1, "Summoner.SuperRichText", 0, &tolua_err)) goto tolua_lerror;
#endif

    cobj = (SuperRichText*)tolua_tousertype(tolua_S, 1, 0);

#if COCOS2D_DEBUG >= 1
    if (!cobj)
    {
        tolua_error(tolua_S, "invalid 'cobj' in function 'renderHtml'", nullptr);
        return 0;
    }
#endif

    argc = lua_gettop(tolua_S) - 1;
    if (argc == 1)
    {
        const char* arg;

        std::string arg_tmp;
        ok &= luaval_to_std_string(tolua_S, 2, &arg_tmp, "Summoner.SuperRichText:renderHtml");
        arg = arg_tmp.c_str();

        if (!ok)
            return 0;

        cobj->renderHtml(arg);
    }

    return 0;

#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'renderHtml'.", &tolua_err);
#endif
    return 0;
}

static int setTouchEnabled(lua_State* tolua_S)
{
#if COCOS2D_DEBUG >= 1
    tolua_Error tolua_err;
    if (
        !tolua_isusertype(tolua_S, 1, "Summoner.SuperRichText", 0, &tolua_err) ||
        !tolua_isboolean(tolua_S, 2, 0, &tolua_err) ||
        !tolua_isnoobj(tolua_S, 3, &tolua_err)
        )
        goto tolua_lerror;
    else
#endif
    {
        SuperRichText* node = static_cast<SuperRichText*>(tolua_tousertype(tolua_S, 1, 0));
        bool value = tolua_toboolean(tolua_S, 2, 0) != 0;
#if COCOS2D_DEBUG >= 1
        if (!node) tolua_error(tolua_S, "invalid 'self' in function 'setTouchEnabled'", nullptr);
#endif
        {
            node->setTouchEnabled(value);
        }
    }
    return 0;
#if COCOS2D_DEBUG >= 1
tolua_lerror:
    tolua_error(tolua_S, "#ferror in function 'setTouchEnabled'.", &tolua_err);
    return 0;
#endif
}

int createRichText(lua_State* l)
{
    int argc = lua_gettop(l);
    SuperRichText* text = nullptr;
    if (argc == 0)
    {
        text = SuperRichText::create();
    }
    else if (argc == 1)
    {
        float width = luaL_checknumber(l, -1);
        text = SuperRichText::create(width);
    }
    
    if (nullptr != text)
    {
        object_to_luaval<SuperRichText>(l, "Summoner.SuperRichText", (SuperRichText*)text);
        return 1;
    }
    return 0;
}

int createRichTextWithCode(lua_State* l)
{
    int argc = lua_gettop(l);
    SuperRichText* text = nullptr;
    if (argc == 1)
    {
        std::string htmlCode = luaL_checkstring(l, -1);
        text = SuperRichText::create(htmlCode.c_str());
    }
    else if (argc == 2)
    {
        std::string htmlCode = luaL_checkstring(l, -2);
        float width = luaL_checknumber(l, -1);
        text = SuperRichText::create(htmlCode.c_str(), width);
    }

    if (nullptr != text)
    {
        object_to_luaval<SuperRichText>(l, "Summoner.SuperRichText", (SuperRichText*)text);
        return 1;
    }
    return 0;
}

bool registeSuperRichText()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto tolua_S = luaStack->getLuaState();

    tolua_usertype(tolua_S, "Summoner.SuperRichText");
    tolua_cclass(tolua_S, "SuperRichText", "Summoner.SuperRichText", "cc.Node", nullptr);

    tolua_beginmodule(tolua_S, "SuperRichText");
        tolua_function(tolua_S, "setString", setString);
        tolua_function(tolua_S, "setTouchEnabled", setTouchEnabled);
    tolua_endmodule(tolua_S);

    std::string typeName = typeid(SuperRichText).name();
    g_luaType[typeName] = "Summoner.SuperRichText";
    g_typeCast["SuperRichText"] = "Summoner.SuperRichText";

    lua_register(tolua_S, "createRichText", createRichText);
    lua_register(tolua_S, "createRichTextWithCode", createRichTextWithCode);

	return true;
}