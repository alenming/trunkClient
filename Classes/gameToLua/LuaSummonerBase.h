#ifndef _SUM_SUMMONER_BASE_
#define _SUM_SUMMONER_BASE_

#include "LuaTools.h"
#include "BufferData.h"

bool regiestSummonerBase();

void onLuaRespone(CBufferData* buffer);

void onLuaLoginSDKSuccess(int pfType, std::string openId, std::string token);

void onLuaPayQQSuccess(int type, std::string openId, std::string openKey, std::string pf, std::string pfKey);

void onLuaBattleStart(int stageId);

void onLuaBattleOver();

void debugLuaStack();

void onLuaEvent(int eventId);
void onLuaEventWithParamInt(int eventId, int param);
void onLuaEventWithParamStr(int eventId, std::string param);

void onLuaQuitBattle();

void onLuaPlayBgMusic(int musicId);

/* 推送相关 */
void checkPush();
void clearPush();

// 游戏后台时不能draw, 如果在热更新, 后台也会继续执行, 中间可能会触发添加节点事件
void setLuaBackgroundValue(bool isBackground);

#endif