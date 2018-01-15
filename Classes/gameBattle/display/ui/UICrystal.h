/*
*   水晶UI
*   1. 绑定UI以及对应的模型，并初始化（等级、状态、消耗）
*   2. 常态、水晶不足、满级等状态的切换
*   3. 增益减益效果
*
*   2015-12-25 by 宝爷
*/
#ifndef __UI_CRYSTAL_H__
#define __UI_CRYSTAL_H__

#include "cocos2d.h"
#include "BattleHelper.h"
#include "BattleModels.h"
#include "GameComm.h"

class CUICrystalComponent : public cocos2d::Component
{
public:
    CUICrystalComponent();
    ~CUICrystalComponent();

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
     * @brief  设置当前升级价格
     */
    void setPrice();


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
     * @brief  设置爬塔试炼水晶数量文本
     */
    void setClimbTowerText();

    /*
     * @brief  设置当前升级价格文本
     */
    void setPriceText();

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

private:

    enum LayerZorder
    {
        LZ_CRYSTALSTATE = 11,			// 执行遮罩层
    };

    void playEffect(const char* effName);
    void onClick(cocos2d::Ref* object);

    /*
    @brief  获取加载的进度
    */
    float getLoadPercent();

private:
    int m_CurLevel;
    int m_Price;
    float m_CurCrystal;
    int m_MaxCrystal;
    float m_DefaultSpeed;
    bool m_bEffectPlaying;
    bool m_bLevelUpTips;
    bool m_bFingerTips;
    CHero* m_Hero;
    cocos2d::ui::Text* m_LevelText;             // 当前水晶等级
    cocos2d::ui::Text* m_CurCrystalText;        // 当前水晶数量
    cocos2d::ui::Text* m_MaxCrystalText;        // 最大水晶数量
    cocos2d::ui::Text* m_ClimbTowerText;        // 爬塔试炼水晶数量
    cocos2d::ui::Text* m_AddGemText;            // 掠夺水晶数量
    cocos2d::ui::Text* m_PriceText;             // 当前升级价格
    cocos2d::ui::LoadingBar* m_LoadingBar;      // 水晶加载进度
    cocostudio::timeline::ActionTimeline* m_CrystalAnimation;       // 水晶整体动画
    cocostudio::timeline::ActionTimeline* m_TextAnimation;          // 底部文字动画
    cocostudio::timeline::ActionTimeline* m_AddGemAnimation;        // 掠夺水晶动画
    cocostudio::Armature* m_BuffAnimation;
    cocos2d::Node* m_TipsFinger;                // 升级水晶提示手指
    cocostudio::timeline::ActionTimeline* m_TipsFingerAnimation;        // 掠夺水晶动画
};

#endif
