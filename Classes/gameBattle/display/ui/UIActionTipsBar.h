/*
*   动作提示栏
*   1. 当对方玩家执行了某些动作后自动添加动作提示按钮到提示栏
*   2. 提示栏中最多有3个动作提示按钮，最先的按钮会被移除
*   3. 动作提示按钮停留一段时间后会自动moveby并隐藏
*   4. 点击动作提示按钮会弹出Tip详细提示，同时只会出现一个提示，提示停留一段时间后淡出。
*   5. 点击其他任何地方，提示消失
*
*   2015-12-26 by 宝爷
*/
#ifndef __UI_ACTION_TIPS_BAR_H__
#define __UI_ACTION_TIPS_BAR_H__

#include <cocos2d.h>
#include <queue>
#include <vector>

class CUIActionTipsBar;

// 动作提示按钮
class CUIActionIcon : public cocos2d::Node
{
public:
    CUIActionIcon();
    virtual ~CUIActionIcon();

    bool init(CUIActionTipsBar* parent, const char* icon, const char* name, const char* desc);
    // 被添加到场景中回调——开始执行Action
    void onEnter();
    // 被移除时回调，m_Parent->popActionIcon
    void onFinish();
    // 点击回调——调用m_Parent->showTip
    void onClick(cocos2d::Ref* object);

private:
    cocos2d::Node* m_CsbNode;
    CUIActionTipsBar* m_Parent;
    const char* m_Icon;
    const char* m_Name;
    const char* m_Desc;
};

template <typename T>
class CEventManager;

class CUIActionTipsBar : public cocos2d::Node
{
public:
    CUIActionTipsBar();
    virtual ~CUIActionTipsBar();

    bool init(bool isleft);
    void onExit();

    // 敌人发出动作后回调
    void onEnemyAction(void* data);

    // 提示——直接重置
    void showTip(const char* icon, const char* name, const char* desc, const cocos2d::Vec2& pos);
    void hideTip();
    void popActionIcon();

private:
    void addActionIcon(const char* icon, const char* name, const char* desc);

private:
    bool m_bLeftSide;
    cocos2d::Node* m_TipNode;
    std::list<CUIActionIcon*> m_Queue;
    std::vector<CUIActionIcon*> m_Caches;
	CEventManager<int>*	m_pEventManager;
};

#endif
