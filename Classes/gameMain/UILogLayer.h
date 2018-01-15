/***********************************************************     
* 文件名称: UILogLayer         
* 作 成 者：Mr.Alen     
* 作成日期：2016/09/18         
/***********************************************************/
#ifndef __UILOG_LAYER_H__
#define __UILOG_LAYER_H__

#include "cocos2d.h"
#include "ui/CocosGUI.h"
#include "LogUiHandler.h"
#include "LuaTools.h"
#include "LuaBasicConversions.h"



class UILogLayer : public cocos2d::LayerColor
{
public:
	UILogLayer();
	~UILogLayer();
	static UILogLayer* create();

    virtual bool init();

	void initUI();
	void testMsg(Ref* pSender);

private:
	bool isRun = false;
	ui::ListView* m_ListView = nullptr;
    // 点击30次, 触发c++崩溃bug, 次数记录 (测试bugly C++代码定位)
    int m_nCrashCount;
};


#endif // __UILOG_LAYER_H__
