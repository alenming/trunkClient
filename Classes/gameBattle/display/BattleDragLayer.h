#ifndef __DRAGLAYER_H__
#define __DRAGLAYER_H__

#include "cocos2d.h"
#include "GameComm.h"
#include "UISkillRange.h"
#include "UISkillScreen.h"

typedef std::function<void()> CameraCallback;

//场景拖动层
class CStageSetLayer : public cocos2d::Layer
{
public:
    CStageSetLayer();
    ~CStageSetLayer();

public:
    //初始化场景, battleSize为战斗场景的屏幕倍数, stageSize为拖动层屏幕倍数.
	bool initWithFile(const std::string &csbFile, float battleScreen, float stageScreen);
    //拖动移动
    void dragMove(float x);

private:

    float              m_fBattleScreen;           //战斗场景宽度
    float              m_fStageScreen;            //场景宽度
};

//拖拽层, 通过点击事件控制拖拽
class CBattleDragLayer : public cocos2d::Layer
{
public:
    CBattleDragLayer();
    ~CBattleDragLayer();

public:
    virtual bool init(int stageId, cocos2d::Node *parent, cocos2d::Node *battle);
    virtual void update(float delta);
	virtual void onEnter();
    virtual void onExit();

    // 开始播放一个摄像头效果
    void startCamera(int carmeraId);
    // 执行摄像头效果，startCamera和摄像头结束后自动执行下一个摄像头会调用该方法
    void doCamera(int carmeraId);
    // 停止摄像头效果
    void stopCarmera();
    // 移动场景
    void dragMove(float x);
    // 设置摄像头结束回调
    void setCameraFinishCallback(const CameraCallback& callback) { m_CameraFinishCallback = callback; }
    // 场景回原
    void resetLayer();

	void onTouchesBegan(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event);
	void onTouchesMoved(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event);
	void onTouchesEnded(const std::vector<cocos2d::Touch*>& touches, cocos2d::Event* event);
	void onTouchesCancelled(const std::vector<cocos2d::Touch*>&touches, cocos2d::Event *event);

    // 技能触发
    void onSkillReleaseEvent(void *data);
    // 技能取消
    void onSkillCancelEvent(void* data);

    // 创建技能范围框
    void createSkillRange(float posX);

    // 移除技能范围框
    void removeSkillRange();

    // 淡出删除技能
    void FadeRemoveSkillRange();

    // 创建技能闪屏
    void createSkillScreen();

    // 移除技能闪屏
    void removeSkillScreen();

	// 放大
	void testScaleZoomIn(cocos2d::Ref *pSender);

	// 缩小
	void testScaleZoomOut(cocos2d::Ref *pSender);

private:
    // 释放技能
    void releaseSkill(int skillIndex, int pox);
	//void doScreenScale(float prevD, float curD, Vec2 centerPos);
	// 测试缩放按钮
	void initTestZoomBtn();

    // 缩放场景
    void scaleScene(float scale);

private:
	bool                    m_bMoveDisable;	            // 不允许拖动
    bool                    m_bIsMove;                  // 是否拖拽
    bool                    m_bIsScaling;               // 是否缩放
    int                     m_nSkillIndex;              // 将要释放的技能下标
    int                     m_nNextCarmeraId;           // 下一个执行的镜头ID
    float                   m_fCarmeraTime;             // 相机结束剩余时间
    float                   m_fMoveTime;                // 镜头移动剩余时间
    float                   m_fScaleTime;               // 镜头缩放剩余时间
    float                   m_fScalePerSceond;          // 镜头每秒移动距离
    float                   m_fMovePerSceond;           // 镜头每秒缩放值
    float                   m_fCurCameraPosX;           // 当前镜头应该移动到的位置
    float                   m_fBattleScreen;            // 战斗场景的屏数(1屏宽度为Stand的width), 作为标准
    float                   m_fMinPosX;                 // 战斗层最小的位置
	float				    m_fRealScreenWidth;			// 屏幕最大宽度
	float				    m_fMaxScreenHeight;			// 屏幕最大高度
    float                   m_fMinScale;				// 最小缩放值>= 0.5
	float				    m_fOffsetY;					// 视觉居中时的位移
	Node*                   m_pParent;                  // 父节点
	Node*                   m_pBattleLayer;             // 战斗逻辑层
    CStageSetLayer*         m_pProspectLayer;           // 远景层
    CStageSetLayer*         m_pBackgroundLayer;         // 背景层
    CStageSetLayer*         m_pBattleBgLayer;           // 战斗层, 与战斗逻辑层同步
    CStageSetLayer*         m_pForegroundLayer;         // 前景层
    Vec2                    m_ScreenCenter;             // 屏幕的正中心
    Vec2                    m_ParentOriginPos;          // 原先的位置
	Size                    m_StandViewSize;            // 标准屏幕大小(960*640)
	cocos2d::Vec2		    m_CenterPos;				// 触碰中心点
    CameraCallback          m_CameraFinishCallback;     // 镜头播放结束后调用的回调

private:
    CUISkillScreen*  m_SkillScreen;
    CUISkillRange*  m_SkillRange;
    float           m_fTouchPosX;
};

#endif
