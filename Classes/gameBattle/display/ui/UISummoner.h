/*
*   召唤师面板(pvp显示)
*   1. 绑定UI以及对应的模型, 并初始化召唤师信息(头像, 名称, 血条)
*   2. 实现血条的增减效果, 血量低的警告
*   3. 实现点击文字的发送
*   4. 实现对方发送文字的显示
*   2016-5-31 by 小强
*/

#ifndef __UI_SUMMONER_H__
#define __UI_SUMMONER_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "GameComm.h"

struct TalkInfo
{
    int userID;
    int talkID;
};

class CUISummonerComponent : public cocos2d::Component
{
public:
    CUISummonerComponent();
    virtual ~CUISummonerComponent();

    bool init(cocos2d::Node* SummonerPanelNode, CRole* role, bool isSelf);
    void onExit();
    void update(float dt);
    void updateState(float dt);
    void updateHp(float dt);

private:
    enum HPState
    {
        kNormal,    // 正常
        kTips,      // 警告提示
        kZero,      // 血量为0
    };

    void initAnimation(cocos2d::Node* summonerPanelNode);
    void initHpBarInfo(cocos2d::Node* summonerPanelNode);

    void setBarPercent(cocos2d::ui::LoadingBar* bar, const float& finalPercent, float& curPercent, float& speed, const float dt);
    HPState CountHPState(const float& hpPercent);

    void onShowTalk(void* data);
    void onMaskClick(cocos2d::Ref* object);
    void onHeroClick(cocos2d::Ref* object);
    void onTalkClick(cocos2d::Ref* object);

    // 机器人随机说话
    void robotTalk();

private:
    bool            m_bIsSelf;
    HPState         m_HPState;
    HPState         m_preHPState;
    CRole*          m_pRole;

    cocos2d::ui::Layout*        m_pMaskLayer;   // 屏蔽层

    cocos2d::ui::LoadingBar*    m_pHPBar;       // 血条上
    cocos2d::ui::LoadingBar*    m_pHPBarD;      // 血条下

    cocos2d::ui::ImageView* m_pHeadImg;  // 头像
    
    cocos2d::ui::Text*      m_pTalkText; // 说出的话

    int m_nMyUserID;
    int m_nNextTalkTime;        // 机器人下次说话时间
    int m_nLanIDs[6];           // 文字ID

    float   m_fInterval;        // 血条改变完成时间(0.2s)
    float   m_fHPMaxValue;      // 最大血量值
    float   m_fHPValue;         // 当前血量值
    float   m_fHPPercent;       // 前血条显示的值
    float   m_fHPDPercent;      // 底部血条显示的值
    float   m_fHPFinalPercent;  // 上面血条的最终值
    float   m_fHPSpeed;         // 前血条的改变速度
    float   m_fHPDSpeed;        // 底部血条改变的速度

    cocostudio::timeline::ActionTimeline*   m_pHpBarAction;
    cocostudio::timeline::ActionTimeline*   m_pHeadAction;
    cocostudio::timeline::ActionTimeline*   m_pTalkAction;      // 说出的话
    cocostudio::timeline::ActionTimeline*   m_pTalkPanelAction; // 所有文字的面板
};

#endif // !__UI_SUMMONER_H__