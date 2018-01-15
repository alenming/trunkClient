/************************************************
* HPBar_ 创建血条
*
* 该类的其他注意事项:
	pow: 满值为100
*
* 作者：
* 日期：2015年12月25日
************************************************/

#ifndef __HPBAR_H__
#define __HPBAR_H__

#include "cocos2d.h"
#include "ui/CocosGUI.h"
#include "cocostudio/CocoStudio.h"
#include "RoleComm.h"
using cocos2d::ui::Text;
using cocos2d::ui::LoadingBar;

//血条类型
enum eBarSizeType
{
	kHP_s = 0,			        // 小血条
	kHP_m,				        // 中血条
	kHP_l,				        // 大血条
	kHPSummoner,		        // 召唤师

	KHPMagic_s = 10,	        // 小血条+魔法
	KHPMagic_m,			        // 中血条+魔法
	KHPMagic_l,			        // 大血条+魔法
	kHPMagicSummoner,	        // 召唤师+魔法

	kHPRage_s = 20,		        // 小血条+怒气
	kHPRage_m,			        // 中血条+怒气
	kHPRage_l,			        // 大血条+怒气
	kHPRageSummoner,	        // 召唤师+怒气

    kHPMagicRage_s = 30,        // 小血法怒条
    kHPMagicRage_m = 31,        // 中血法怒条
    kHPMagicRage_l = 32,        // 大血法怒条
    kHPMagicRageSummoner = 33,  // 召唤师血法怒条
};

class CHPBar : public cocos2d::Node
{
public:
	CHPBar(eBarSizeType sizeType, CampType camp, float maxHP, float shield = 0, float magic = 0, float rage = 0);
    ~CHPBar();
    static CHPBar* create(eBarSizeType sizeType, CampType camp, float maxHP, float shield, float magic = 0, float rage = 0);
	bool init();

    virtual void onExit();

	void setHP(float hp);
	//void setMaxHP(float maxHP);
	void setShield(float shield);
    void setMagic(float magic);
    void setRage(float rage);
	void setName(std::string name);
	eBarSizeType getSizeType(){ return m_eSizeType; }
	CampType getCamp(){ return m_eCamp; }
	void ChangeCamp(CampType camp);
	void setReduceTime(float dt);	// 显示血量变化的时间
	
private:
	// 根据类型创建测csb血条
	void createCsb();
	// 初始化血条的显示
	void initShow();

	// 设置进度条的百分比
	void setBarPercent(LoadingBar* bar, const float& percent, float& curPercent);
	void setHPPercent(float percent);
	void setHPDPercent(float percent);
	void setShieldPercent(float percent);
    void setMagicPercent(float percent);
    void setMagicDPercent(float percent);
    void setRagePercent(float percent);
    void setRageDPercent(float percent);
	
	// 限制数值上下限
	void boundValue(float& value, float minValue = 0, float maxValue = 0);
	// 根据当前的值计算出血和护盾最终的长度
	void countHPShieldFinal();
	// 根据速度设置进度条的百分比
    inline void setPercentBySpeed(LoadingBar* bar, float& targetPercent, float& curPercent, float& speed, float dt)
    {
        if (speed == 0)
        {
            return;
        }
        curPercent += speed * dt;
        if ((speed > 0 && curPercent >= targetPercent)
            || (speed < 0 && curPercent <= targetPercent))
        {
            curPercent = targetPercent;
            speed = 0;
        }
        setBarPercent(bar, curPercent, curPercent);
    }

	void update(float dt);
private:
	eBarSizeType		m_eSizeType;
	CampType			m_eCamp;

	cocos2d::Node*			m_pCsbHP;			// 血条csb
    cocos2d::Node*          m_pCsbMagic;        // 用来显示魔法的能量条
    cocos2d::Node*          m_pCsbRage;         // 用来显示怒气的能量条
	Text*					m_pTextName;		// 召唤师名称
	LoadingBar*				m_pBarHP;			// 血条
	LoadingBar*				m_pBarHPD;			// 血条下
	LoadingBar*				m_pBarShield;		// 护盾
    LoadingBar*             m_pBarMagic;        // 魔法
    LoadingBar*             m_pBarMagicD;       // 魔法下
    LoadingBar*             m_pBarRage;         // 怒气
    LoadingBar*             m_pBarRageD;        // 怒气下
	cocostudio::timeline::ActionTimeline* m_pCsbHPAct;	//切换阵营

	// 血条当前值
	float	m_fHP;
	float	m_fMaxHP;
	float	m_fShield;
	//float	m_fPow;
    float   m_fMagic;
    float   m_fRage;

	// 最终显示值
	float	m_fFinalHPPercent;
	float	m_fFinalShieldPercent;
	//float	m_fFinalPowPercent;
    float   m_fFinalMagicPercent;
    float   m_fFinalRagePercent;

	// 当前显示的值
	float	m_fCurHPPercent;
	float	m_fCurHPDPercent;
	float	m_fCurShieldPercent;
    float   m_fCurMagicPercent;
    float   m_fCurMagicDPercent;
    float   m_fCurRagePercent;
    float   m_fCurRageDPercent;

	// 变化速度
	float	m_fHPSpeed;
	float	m_fHPDSpeed;
	float	m_fShieldSpeed;
    float   m_fMagicSpeed;
    float   m_fMagicDSpeed;
    float   m_fRageSpeed;
    float   m_fRageDSpeed;

	// 增加或减少 需要的时间
	float	m_fReduceTime;

    std::string m_HPPath;   // hp csb路径
};

#endif