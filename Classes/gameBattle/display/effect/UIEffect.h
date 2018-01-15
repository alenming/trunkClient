#ifndef _SUM_UI_EFFECT_
#define _SUM_UI_EFFECT_

#include "KxCSComm.h"
#include "ConfFight.h"

class CUIEffectManager
{
public:
	static CUIEffectManager* getInstance();
    static void destroy();
    CUIEffectManager();

	void init(cocos2d::Node* battleScene);
    void uninit();
	//id为UI特效ID，pos为目标对象位置，位置为世界坐标位置
	void execute(int id, const Vec2& pos = Vec2::ZERO);
    //停止特效
    void stopUIEffect();

private:
    void executeDark(UIEffectConfItem* conf);
    void executeShake(int shakeLevel, float shakeDelayTime, float shakeTime);
    void shakeNode(int tag, int shakeLevel, float shakeDelayTime, float shakeTime);
    cocos2d::Node* executeEffect(int zorder, int resId, const std::string& effAni);
    void executeDoodad(UIEffectConfItem* conf, const Vec2& pos);
    void findDoodads(cocos2d::Node* node);

private:
    Node* m_DarkNode;                       // 黑暗层
    Node* m_BackGround;                     // 背景层
    Node* m_Blink;                          // 闪屏层
    Node* m_Scene;                          // 战斗场景
    std::list<Node*> m_Doodads;             // 装饰物列表
    static CUIEffectManager* m_Instance;    // 单例对象
};

#endif	