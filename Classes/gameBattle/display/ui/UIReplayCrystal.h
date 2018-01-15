/*
*   回放水晶UI
*   1. 绑定UI以及对应的模型，并初始化（等级、状态、消耗）
*
*/
#ifndef __UI_REPLAYCRYSTAL_H__
#define __UI_REPLAYCRYSTAL_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameComm.h"

class CUIReplayCrystalComponent : public cocos2d::Component
{
public:
    CUIReplayCrystalComponent();
    ~CUIReplayCrystalComponent();

    bool init(cocos2d::Node* crystalNode, CHero* hero);
    void update(float dt);

    /*
     * @brief  设置水晶等级
     */
    void setCurLevel();

    /*
     * @brief  设置当前水晶数量
     */
    void setCurCrystal();

    /*
     * @brief  设置最大水晶数量
     */
    void setMaxCrystal();

    /*
     * @brief  设置水晶等级文本
     */
    void setCurLevelText();

    /*
     * @brief  设置当前水晶数量文本
     */
    void setCurCrystalText();

    /*
     * @brief  设置最大水晶数量文本
     */
    void setMaxCrystalText();
    
    /*
    * @brief   设置水晶加载进度条
    */
    void setLoadingBarPercent();

    /**
    * @brief  播放水晶的状态特效
    */
    void playCrystalEffect(float dt);

    /**
    * @brief  播放水晶的增益减益特效
    */
    void playBuffEffect();

    void onCrystalUpgrade(void* data);

private:

    void playEffect(const char* effName);

    enum LayerZorder
    {
        LZ_CRYSTALSTATE = 11,			// 执行遮罩层
    };

    /*
    @brief  获取加载的进度
    */
    float getLoadPercent();

private:
    int m_CurLevel;
    float m_DefaultSpeed;
    float m_CurCrystal;
    int m_MaxCrystal;
    bool m_bEffectPlaying;
    CHero* m_Hero;
    cocos2d::ui::Text* m_LevelText;             // 当前水晶等级
    cocos2d::ui::Text* m_CurCrystalText;        // 当前水晶数量
    cocos2d::ui::Text* m_MaxCrystalText;        // 最大水晶数量
    cocos2d::ui::Text* m_AddGemText;            // 掠夺水晶数量
    cocos2d::ui::LoadingBar* m_LoadingBar;      // 水晶加载进度
    cocostudio::timeline::ActionTimeline* m_CrystalAnimation;       // 水晶整体动画
    cocostudio::timeline::ActionTimeline* m_AddGemAnimation;        // 掠夺水晶动画
    cocostudio::Armature* m_BuffAnimation;
};

#endif
