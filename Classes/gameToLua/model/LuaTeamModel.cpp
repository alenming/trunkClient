#include "LuaTeamModel.h"
#include "LuaTools.h"
#include "ModelData.h"

// 用法：local SummonerID, HeroTable = teamModel:getTeamInfo(TeamType)
int getTeamInfo(lua_State *L)
{
    CTeamModel* model = LuaTools::checkClass<CTeamModel>(L, -2, "Summoner.TeamModel");
    int teamType = luaL_checkint(L, -1);
    if (model)
    {
        int summonerID = 0;
        std::vector<int> vecHero;
        bool ret = model->getTeamInfo(teamType, summonerID, vecHero);
        if (ret)
        {
            lua_pushnumber(L, summonerID);
            // vector to table
            lua_newtable(L);
            for (unsigned int i = 0; i < vecHero.size(); ++i)
            {
                lua_pushinteger(L, vecHero[i]);
                lua_rawseti(L, -2, i + 1);
            }

            return 2;
        }
    }

    return 0;
}

// 用法：teamModel:setTeamInfo(TeamType, SummonerID, HeroTable)
int setTeamInfo(lua_State *L)
{
    CTeamModel* model = LuaTools::checkClass<CTeamModel>(L, -4, "Summoner.TeamModel");
    int teamType = luaL_checkint(L, -3);
    int summonerID = luaL_checkint(L, -2);
    int count = luaL_getn(L, -1);

    std::vector<int> vecHero;
    for (int i = 1; i <= count; i++)
    {
        // 获取栈顶的table,依次取出各个KEY的值,最后pop保持栈顶是table
        lua_rawgeti(L, -1, i); 
        int heroID = lua_tointeger(L, -1);
        vecHero.push_back(heroID);

        lua_pop(L, 1);
    }

    if (model)
    {
        model->setTeamInfo(teamType, summonerID, vecHero);
    }

    return 0;
}

int removeHeroFromAllTeam(lua_State *L)
{
    CTeamModel* model = LuaTools::checkClass<CTeamModel>(L, -2, "Summoner.TeamModel");
    int heroID = luaL_checkint(L, -1);
    if (model)
    {
        model->removeHeroFromAllTeam(heroID);
    }

    return 0;
}

int hasHeroAllTeam(lua_State *L)
{
    CTeamModel* model = LuaTools::checkClass<CTeamModel>(L, -2, "Summoner.TeamModel");
    int heroID = luaL_checkint(L, -1);
    if (model)
    {
        bool exist = model->hasHeroAllTeam(heroID);
        lua_pushboolean(L, exist ? 1 : 0);
        return 1;
    }

    return 0;
}

static const struct luaL_reg funTeam[] =
{
    { "getTeamInfo", getTeamInfo },
    { "setTeamInfo", setTeamInfo },
    { "removeHeroFromAllTeam", removeHeroFromAllTeam },
    { "hasHeroAllTeam", hasHeroAllTeam },
    { NULL, NULL }
};

int newTeamModel(lua_State *L)
{
    CTeamModel *model = new CTeamModel();
    LuaTools::pushClass(L, model, "Summoner.TeamModel");
    return 1;
}

int deleteTeamModel(lua_State *L)
{
    CTeamModel* model = LuaTools::checkClass<CTeamModel>(L, -2, "Summoner.TeamModel");
    if (NULL != model)
    {
        delete model;
    }
    return 0;
}

bool registeTeamModel()
{
    auto luaStack = cocos2d::LuaEngine::getInstance()->getLuaStack();
    auto luaState = luaStack->getLuaState();

    luaL_newmetatable(luaState, "Summoner.TeamModel");
    lua_pushstring(luaState, "__index");
    lua_pushvalue(luaState, -2);
    lua_settable(luaState, -3);
    luaL_openlib(luaState, NULL, funTeam, 0);

    lua_register(luaState, "newTeamModel", newTeamModel);
    lua_register(luaState, "deleteTeamModel", deleteTeamModel);

    return true;
}

