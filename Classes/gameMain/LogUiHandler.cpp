#include "LogUiHandler.h"
#include "LuaTools.h"
#include "cocostudio/CocoStudio.h"
#include "UILogLayer.h"
#include "LuaBasicConversions.h"

USING_NS_CC;
#define MAX_GAP	100

CLogUiHandler::CLogUiHandler()
{
	this->m_MaxCount = 200;
	this->logLayer = nullptr;
	this->m_isRun = true;
	this->m_isFirst = true;
	this->m_isSecond = false;
	this->m_isThird = false;
	this->m_isFour = false;
	this->m_isSuccessful = false;
	this->m_twoFirst = false;  // 第二套方案用的数据
	auto EventList = EventListenerTouchOneByOne::create();

	EventList->onTouchBegan = [=](Touch* _touch, Event* _event)->bool
	{
		auto po = _touch->getLocation();
		this->prePo = po;
		//复杂手势
		//第一个点
		if (this->m_isFirst && !this->m_isSecond && !this->m_isThird && !this->m_isFour)
		{
			//第一个点
			//CCLOG("11111111111111111111111111111");
			this->m_Point.push_back(po);
		}
		//第二次
		if (this->m_isSecond && !this->m_isFirst && !this->m_isThird && !this->m_isFour)
		{
			//第三个点
			//CCLOG("3333333333333333333333333333333");
			this->m_Point.push_back(po);
		}
		//第三次
		if (this->m_isThird && !this->m_isFirst && !this->m_isSecond && !this->m_isFour)
		{
			//第五个点
			//CCLOG("555555555555555555555555555555555555555555");
			this->m_Point.push_back(po);
		}

		if (this->m_isFour && !this->m_isFirst && !this->m_isSecond && !this->m_isThird)
		{
			//第七个点
			//CCLOG("777777777777777777777777777777777777777");
			this->m_Point.push_back(po);
		}

		return true;
	};
	EventList->onTouchMoved = [=](Touch* _touch, Event* _event){};

	EventList->onTouchEnded = [=](Touch* _touch, Event* _event)
	{
		auto po = _touch->getLocation();
		this->nowPo = po;
		auto distance = this->prePo.getDistance(this->nowPo);
		auto maxVi = Director::getInstance()->getVisibleSize();

		//第四次操作, 左下到右下
		if (prePo.x < MAX_GAP && prePo.y < MAX_GAP && nowPo.x > maxVi.width - MAX_GAP && nowPo.y < MAX_GAP
			&& this->m_isFour && !this->m_isFirst && !this->m_isSecond && !this->m_isThird)
		{
			//CCLOG("888888888888888888888888888");
			//是这个操作 记录第4个点
			this->m_Point.push_back(po);
			this->m_isSuccessful = true;

			this->m_isSecond = false;
			this->m_isFirst = false;
			this->m_isThird = false;
			this->m_isFour = true;
		}
		//操作不对删除了
		else if (this->m_isFour && !this->m_isFirst && !this->m_isSecond && !this->m_isThird)
		{
			reSet();
		}

		//第三次操作, 左上到右上
		if (prePo.x<MAX_GAP && prePo.y > maxVi.height - MAX_GAP && nowPo.x > maxVi.width - MAX_GAP && nowPo.y > maxVi.height - MAX_GAP 
			&& this->m_isThird && !this->m_isSecond && !this->m_isFirst && !this->m_isFour)
		{
			//CCLOG("66666666666666666666666");
			//是这个操作 记录第4个点
			this->m_Point.push_back(po);
			this->m_isSuccessful = false;

			this->m_isSecond = false;
			this->m_isFirst = false;
			this->m_isThird = false;
			this->m_isFour = true;
		}
		//操作不对删除了
		else if (this->m_isThird && !this->m_isFirst && !this->m_isSecond && !this->m_isFour)
		{
			reSet();
		}

		//第二次操作, 左上到右下
		if (prePo.x < MAX_GAP && prePo.y > maxVi.height-MAX_GAP && nowPo.x > maxVi.width - MAX_GAP && nowPo.y < MAX_GAP 
			&& this->m_isSecond && !this->m_isFirst && !this->m_isThird && !this->m_isFour)
		{
			//是这个操作 记录第4个点
			//CCLOG("44444444444444444444444444444444");
			this->m_Point.push_back(po);
			this->m_isSuccessful = false;
			this->m_isSecond = false;
			this->m_isFirst = false;
			this->m_isFour = false;
			this->m_isThird = true;
		}
		//操作不对删除了
		else if (this->m_isSecond && !this->m_isFirst && !this->m_isThird && !this->m_isFour)
		{
			reSet();
		}

		//第一次操作, 右上到左下
		if (prePo.x > maxVi.width - MAX_GAP && prePo.y > maxVi.height-MAX_GAP && nowPo.x < MAX_GAP && nowPo.y < MAX_GAP 
			&& this->m_isFirst && !this->m_isSecond  && !this->m_isThird && !this->m_isFour)
		{
			//CCLOG("2222222222222222222222222222222222222");
			//是这个操作 记录第二个点
			this->m_Point.push_back(po);
			this->m_isSuccessful = false;
			this->m_isFirst = false;
			this->m_isThird = false;
			this->m_isFour = false;
			this->m_isSecond = true;
		}
		//操作不对删除了
		else if (this->m_isFirst && !this->m_isSecond && !this->m_isThird && !this->m_isFour)
		{
			reSet();
		}

		if (this->m_isSuccessful && this->m_Point.size() == 8)
		{
			if (!Director::getInstance()->getRunningScene()->getChildByTag(100865566))
			{
				this->logLayer = static_cast<UILogLayer*>(UILogLayer::create());
				Director::getInstance()->getRunningScene()->addChild(this->logLayer, 9999999, 100865566);
			}
			reSet();
		}
	};
	EventList->setSwallowTouches(false);
	auto eventLister = Director::getInstance()->getEventDispatcher();
	eventLister->addEventListenerWithFixedPriority(EventList, -129);

	auto EventList1 = EventListenerTouchOneByOne::create();
	EventList1->onTouchBegan = [=](Touch* _touch, Event* _event)->bool
	{
		auto po = _touch->getLocation();
		this->m_Point2.push_back(po);
		return true;
	};
	EventList1->onTouchMoved = [=](Touch* _touch, Event* _event)
	{
		//不为10,只要划动了都清了,第十下要划动
		if (this->m_Point2.size() == 10)
		{
			this->m_Point2.clear();
			//第一步条件满足
			this->m_twoFirst = true;
		}
		else 
		{
			this->m_Point2.clear();
		}
	};
	EventList1->onTouchEnded = [=](Touch* _touch, Event* _event)
	{
		auto po = _touch->getLocation();
		auto maxVi = Director::getInstance()->getVisibleSize();

		if (this->m_twoFirst)
		{
			this->m_twoFirst = false;
			//划向左上角
			if (po.x < MAX_GAP && po.y >= maxVi.height - MAX_GAP)
			{
				if (!Director::getInstance()->getRunningScene()->getChildByTag(100865566))
				{
					this->logLayer = static_cast<UILogLayer*>(UILogLayer::create());
					Director::getInstance()->getRunningScene()->addChild(this->logLayer, 9999999, 100865566);
				}
			}
		}
	};
	EventList1->setSwallowTouches(false);
	eventLister->addEventListenerWithFixedPriority(EventList1, -130);
}

CLogUiHandler::~CLogUiHandler()
{

}

bool CLogUiHandler::onLog(int level, const std::string& log)
{
	size_t messCount = m_VuiLogMess.size();
	if (messCount > m_MaxCount)
	{
		m_VuiLogMess.erase(m_VuiLogMess.begin());
	}

	m_VuiLogMess.push_back(log);
	if (Director::getInstance()->getRunningScene() 
		&& Director::getInstance()->getRunningScene()->getChildByTag(100865566))
	{
		if (m_isRun && this->logLayer)
		{
			static_cast<UILogLayer*>(this->logLayer)->testMsg(this);
		}
	}
	return true;
}

std::vector<std::string>& CLogUiHandler::getVectorMess()
{
	return m_VuiLogMess;
}

void CLogUiHandler::reSet()
{
	//还原初始状态
	this->m_isFirst = true;
	this->m_isSecond = false;
	this->m_isThird = false;
	this->m_isFour = false;
	this->m_isSuccessful = false;
	this->m_Point.clear();
}


