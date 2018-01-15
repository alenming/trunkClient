#include "NumberScrollLabel.h"
#include "CommTools.h"

#define CHECK_RETURN_VOID(success) if(!(success)) return;

CNumberScrollLabel* CNumberScrollLabel::create(int power, int size, float speed)
{ 
	CNumberScrollLabel *pRet = new CNumberScrollLabel();
	if (pRet && pRet->init(power, size, speed)) 
	{
		pRet->autorelease(); 
		return pRet; 
	} 
	else 
	{ 
		delete pRet; 
		pRet = nullptr; 
		return nullptr; 
	} 
}

bool CNumberScrollLabel::init(int power, int size, float speed)
{
	m_nPower = power;
	m_nSize = size;
	m_fSpeed = speed;

	for (int i = 0; i < m_nPower; i++)
	{
		auto row = Node::create();
		row->setAnchorPoint(Vec2::ZERO);
		row->setPosition(Vec2(m_nSize * (m_nPower - i - 1), 0));
		row->setTag(i);
		this->addChild(row);
		for (int j = 0; j < 10; j++)
		{
			auto col = cocos2d::Label::createWithTTF(toolToStr(j), "fonts/arial.ttf", m_nSize);
			col->setAnchorPoint(Vec2::ZERO);
			col->setPosition(Vec2(0, m_nSize * j));
			row->addChild(col);
		}
	}

	return true;
}

void CNumberScrollLabel::visit(cocos2d::Renderer *renderer, const cocos2d::Mat4& parentTransform, uint32_t parentFlags)
{
	_beforeVisitCmdScissor.init(_globalZOrder);
	_beforeVisitCmdScissor.func = CC_CALLBACK_0(CNumberScrollLabel::onBeforeVisitScissor, this);
	renderer->addCommand(&_beforeVisitCmdScissor);

	Node::visit(renderer, parentTransform, parentFlags);

	_afterVisitCmdScissor.init(_globalZOrder);
	_afterVisitCmdScissor.func = CC_CALLBACK_0(CNumberScrollLabel::onAfterVisitScissor, this);
	renderer->addCommand(&_afterVisitCmdScissor);
}

void CNumberScrollLabel::onBeforeVisitScissor()
{
	glEnable(GL_SCISSOR_TEST);
	Vec2 v = this->convertToWorldSpace(Vec2::ZERO);
	Director::getInstance()->getOpenGLView()->setScissorInPoints(v.x, v.y, m_nPower * m_nSize, m_nSize);
}

void CNumberScrollLabel::onAfterVisitScissor()
{
	glDisable(GL_SCISSOR_TEST);
}

void CNumberScrollLabel::setNumber(int var)
{
	CHECK_RETURN_VOID(var < pow(10, m_nPower));

	for (int i = 0;; i++)
	{
		if (0 == var) break;
		int c = var % 10;
		var /= 10;
		auto row = this->getChildByTag(i);
		row->runAction(cocos2d::MoveTo::create(m_fSpeed, Vec2(row->getPosition().x, -m_nSize * c)));
	}
}
