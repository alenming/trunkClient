/*
* 召唤师联盟客户端共用头文件
* 定义客户端专用的数据结构，枚举和宏
*
* 2015-2-5 by 宝爷
*/
#ifndef __GAME_COMM_H__
#define __GAME_COMM_H__

#include "KxCSComm.h"
#include "BattleModels.h"

#include "ui/UIWidget.h"
#include "ui/UIText.h"
#include "ui/UIButton.h"
#include "ui/UIImageView.h"
#include "ui/UILoadingBar.h"
#include "ui/UIScale9Sprite.h"
#include "ui/UIEditBox/UIEditBox.h"
#include "ui/UILayout.h"
#include "ui/UIListView.h"
#include "ui/UIPageView.h"
#include "ui/UIScrollView.h"
#include "ui/UIHelper.h"
#include "ui/CocosGUI.h"
#include "cocostudio/CocoStudio.h"

using cocos2d::Color4B;
using cocos2d::Label;
using cocos2d::Sprite;
using cocos2d::Sequence;
using cocos2d::ProgressTo;
using cocos2d::ProgressFromTo;
using cocos2d::ProgressTimer;
using cocos2d::RepeatForever;
using cocos2d::LayerColor;
using cocos2d::ui::Widget;
using cocos2d::ui::Text;
using cocos2d::ui::Button;
using cocos2d::ui::ImageView;
using cocos2d::ui::LoadingBar;
using cocos2d::ui::Scale9Sprite;
using cocos2d::ui::EditBox;
using cocos2d::ui::Layout;
using cocos2d::ui::ListView;
using cocos2d::ui::PageView;
using cocos2d::ui::ScrollView;
using cocos2d::ui::Helper;
using cocostudio::GUIReader;
using cocostudio::Armature;

// 战斗场景的层级Zorder
enum BattleLayerZorder
{
	LZ_SCALE = 0,					// 缩放层级
	LZ_UI = 1,						// UI层
	LZ_FLASH = 2,					// 闪屏层
};

enum ScaleLayerZorder
{
	SLZ_CHANGE = -5,					// 切换层
	SLZ_PROSPECT = -4,				// 远景层
	SLZ_BACKGROUND = -3,				// 背景层
	SLZ_BATTLEBG = -2,				// 战斗背景层
	SLZ_BATTLE0 = -1,				// 战斗层0
	SLZ_BATTLE1 = 0,				// 战斗层1
	SLZ_BATTLE2 = 1,				// 战斗层2
	SLZ_FOREGRUND = 2,				// 前景层
};


// 战斗场景的层级标签
enum BattleLayerTag
{
	BLT_CHANGE = 10,				// 切换层
	BLT_PROSPECT,					// 远景层
	BLT_BACKGROUND,					// 背景层
    BLT_BATTLEBG,                   // 战斗背景
	BLT_BATTLE,						// 战斗层
	BLT_FOREGRUND,					// 前景层
	BLT_UI,							// UI层
	BLT_FLASH,						// 闪屏层
	BLT_DRAG,						// 拖动层
};

void		setGray(Node* node, bool b);
Node*		getChildByPath(Node* root, std::string path);
Layout*		loadJson(const std::string& file);
Widget*     getWidget(Node* root, const std::string& path);
Text*		getText(Node* root, const std::string& path);
Layout*		getLayout(Node* root, const std::string& path);
Button*     getButton(Node* root, const std::string& path);
ImageView*	getImageView(Node* root, const std::string& path);
LoadingBar* getLoadingBar(Node* root, const std::string& path);
ListView*	getListView(Node* root, const std::string& path);
PageView*	getPageView(Node* root, const std::string& path);
ScrollView* getScrollView(Node* root, const std::string& path);

#endif