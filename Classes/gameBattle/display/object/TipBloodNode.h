/*
* 角色显示组件
* 根据Owner的位置来平滑显示位置
* 根据状态来播放指定动画
*
* 2014-12-23 by 宝爷
*/
#ifndef __TIP_BLOOD_NODE__
#define __TIP_BLOOD_NODE__

#include "cocos2d.h"

class TipBloodNode
{
private:
	TipBloodNode();
	virtual ~TipBloodNode();

public:
	static TipBloodNode* getInstance();
	static void destory();
	cocos2d::Node* getCsb(const std::string& text, const std::string& animationName);
	//CC_SYNTHESIZE_READONLY(Node*, m_csb, Csb);
private:
	static TipBloodNode* m_Instance;
	size_t tipBloodMaxCount;
};

#endif //__TIP_BLOOD_NODE__
