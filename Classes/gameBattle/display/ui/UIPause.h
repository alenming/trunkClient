#ifndef __BATTLE_PAUSE_H__
#define __BATTLE_PAUSE_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "GameComm.h"

class CUIPause : public cocos2d::Layer
{
public:
    CUIPause();
    virtual ~CUIPause();

    virtual bool init();
    virtual void onEnter();
    virtual void onExit();
    void onQuit(cocos2d::Ref* sender);

    CREATE_FUNC(CUIPause);
};

#endif
