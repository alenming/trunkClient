/***********************************************************
* 文件名称: CLogUiHandler
* 作 成 者：Mr.Alen
* 作成日期：2016/09/18
/***********************************************************/
#ifndef _LOG_UI_HANDLER_H__
#define _LOG_UI_HANDLER_H__

#include "cocos2d.h"
#include "KxLog.h"
#include <vector>
#include "UILogLayer.h"


//#define  MAX_COUNT	200

class CLogUiHandler : public IKxLogHandler, public cocos2d::Ref
{
public:
	CLogUiHandler();
	~CLogUiHandler();


	std::vector<std::string>& getVectorMess();

	virtual bool onLog(int level, const std::string& log);
	CC_SYNTHESIZE(bool, m_isRun, IsRun);
	CC_SYNTHESIZE(int, m_MaxCount, MaxCount);

	void reSet();

private:
	std::vector<std::string> m_VuiLogMess;
	std::vector<cocos2d::Vec2> m_Point;
	bool m_isSuccessful;
	bool m_isFirst;
	bool m_isSecond;
	bool m_isThird;
	bool m_isFour;
	cocos2d::Vec2 prePo;
	cocos2d::Vec2 nowPo;
	cocos2d::LayerColor* logLayer;
	
	//第二套方案数据
	std::vector<cocos2d::Vec2> m_Point2;
	bool m_twoFirst;
};


#endif //_LOG_UI_HANDLER_H__
 