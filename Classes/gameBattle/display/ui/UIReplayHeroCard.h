/*
*   英雄卡片UI
*   1. 绑定UI以及对应的模型，并初始化（框、头像、天赋、消耗）
*   2. 实现CD、常态、水晶不足等状态的切换
*   3. 实现锁和解锁、锁点击逻辑
*   4. 实现唯一限制UI表现更新
*   5. 实现增益减益效果呈现
*
*   点击逻辑优先级：锁点击 > 常态点击 > 水晶不足点击 > 唯一点击 > CD点击
*
*   2015-12-23 by 宝爷
*/
#ifndef __UI_REPLAYHERO_CARD_H__
#define __UI_REPLAYHERO_CARD_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameComm.h"
#include "UITouchInfo.h"
#include "UIBattleMain.h"

class CUIReplayHeroCardComponent : public cocos2d::Component
{
public:
    CUIReplayHeroCardComponent();
    virtual ~CUIReplayHeroCardComponent();

    bool init(cocos2d::Node* cardNode, CHero* hero, int index);
    void update(float dt);

private:
    enum HeroCardState {
        HeroCardInvalid,
        HeroCardNormal,
        HeroCardCD,
        HeroCardLack,
    };

    // 层级Zorder
    enum LayerZorder
    {
        LZ_SINGLE   = 13,			// 唯一节点层
        LZ_LOCK     = 14,			// 锁节点层
        LZ_BUFF     = 15,           // buff节点层
    };

    void playEffect(const char* effName);

    HeroCardState checkModelState();
    // 派遣监听
    void onDispatchHero(void *data);

private:
    int m_Index;
    float m_DefaultCD;
    float m_DefautlCost;
    bool m_bLock;
    bool m_bEffectPlaying;

    CHero* m_Hero;
    CSoldierModel* m_Model;
    HeroCardState m_CurState;

	cocos2d::ui::Layout*    m_HeroItem;
    cocos2d::ui::Button*    m_HeroBg;               // 英雄背景
    cocos2d::ui::Button*    m_HeroIcon;             // 英雄头像
    cocos2d::ui::Text*      m_HeroCost;             // 英雄水晶
	cocos2d::ui::Text*      m_HeroOnly;
    cocos2d::Sprite*        m_LoadingMask;          // 遮罩层

    cocostudio::timeline::ActionTimeline* m_CardAnimation;      // 卡牌整体动画
    cocostudio::timeline::ActionTimeline* m_LightAnimation;     // 光动画
    cocostudio::timeline::ActionTimeline* m_LockAnimation;      // 锁动画
    cocostudio::timeline::ActionTimeline* m_BuffAnimation;      // Buff动画(CD增加、减少)
};

#endif
