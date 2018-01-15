#ifndef _SUM_NUMBER_SCROLL_LABEL_
#define _SUM_NUMBER_SCROLL_LABEL_

#include "cocos2d.h"

class CNumberScrollLabel : public cocos2d::Node
{
public:
	static CNumberScrollLabel* create(int power = 1, int size = 20, float speed = 0.5f);
	virtual void visit(cocos2d::Renderer *renderer, const cocos2d::Mat4& parentTransform, uint32_t parentFlags);
	bool init(int power, int size, float speed);
	void setNumber(int var);

protected:
	void onAfterVisitScissor();
	void onBeforeVisitScissor();
	cocos2d::CustomCommand _beforeVisitCmdScissor;
	cocos2d::CustomCommand _afterVisitCmdScissor;    

private:
	int m_nPower;
	int m_nSize;
	float m_fSpeed;
};

class CNumberScrollLabelEx : public cocos2d::Node
{

};

#endif