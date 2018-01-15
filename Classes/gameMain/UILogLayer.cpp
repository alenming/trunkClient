#include "UILogLayer.h"
#include "KxLog.h"
#include "CommTools.h"

using namespace cocos2d;
using namespace ui;


UILogLayer::UILogLayer()
    :m_nCrashCount(0)
{
	this->isRun = true;
}

UILogLayer::~UILogLayer()
{

}

UILogLayer* UILogLayer::create()
{
	UILogLayer *pRet = new UILogLayer();
	if (pRet && pRet->init())
	{
		pRet->autorelease();
		return pRet;
	}
	else
	{
		delete pRet;
		pRet = NULL;
		return NULL;
	}
}

bool UILogLayer::init()
{
    if ( !Layer::init() )
    {
        return false;
    }

	this->initWithColor(Color4B(150, 200, 255, 255));
	initUI();
	
    return true;
}

void UILogLayer::initUI()
{
	auto kx = (CLogUiHandler*)KxLogger::getInstance()->getHandler(3);

	auto viSize = Director::getInstance()->getVisibleSize();
	Button* m_Button = Button::create("CloseNormal.png","CloseNormal.png","CloseNormal.png",ui::Widget::TextureResType::LOCAL);
	m_Button->setPosition(Size(viSize.width-40, viSize.height-40));
	std::string buttonName = "OUT";
	auto text = Text::create();
	text->setString(buttonName);
	text->setColor(Color3B::BLACK);
	text->setPosition(Vec2(20, 20));
	m_Button->addChild(text);
	m_Button->setScale(1.5);
	m_Button->addTouchEventListener([=](Ref* spender, Widget::TouchEventType type)
	{
		if (type == ui:: Widget::TouchEventType::ENDED)
		{
			this->removeFromParent();
		}
	});
	this->addChild(m_Button,98);

	 m_ListView = ListView::create();
	m_ListView->setContentSize(Size(viSize.width - 50, viSize.height));

	m_ListView->removeAllItems();
	
	auto m_VecMess = kx->getVectorMess();
	size_t m_Size = kx->getVectorMess().size();
	for (size_t i = 0; i < m_Size; ++i)
	{
		Text* m_TextItem = Text::create();
		m_TextItem->setString(m_VecMess.at(i));
		m_TextItem->setContentSize(Size(viSize.width, 25));
		m_TextItem->setFontSize(16);
		m_TextItem->setColor(Color3B::BLACK);
		m_ListView->pushBackCustomItem(m_TextItem);
	}
	
	this->addChild(m_ListView, 99);
	m_ListView->jumpToBottom();

	Button* m_Button1 = Button::create("CloseNormal.png", "CloseNormal.png", "CloseNormal.png", ui::Widget::TextureResType::LOCAL);
	m_Button1->setPosition(Size(viSize.width - 40, viSize.height - 100));
	buttonName.clear();
	buttonName = "Run";
	auto text1 = Text::create();
	text1->setString(buttonName);
	text1->setColor(Color3B::BLACK);
	text1->setPosition(Vec2(20, 20));
	m_Button1->addChild(text1,99,"Text");
	m_Button1->setScale(1.5);
	m_Button1->addTouchEventListener([=](Ref* spender, Widget::TouchEventType type)
	{
		if (type == ui::Widget::TouchEventType::ENDED)
		{
			auto Tex =(Text*) m_Button1->getChildByName("Text");
			if (this->isRun)
			{
				this->isRun = false;

				if (Tex)
				{
					Tex->setString("Stop");
				}
				kx->setIsRun(false);
			}
			else
			{
				this->isRun = true;
				if (Tex)
				{
					Tex->setString("Run");
				}
				m_ListView->removeAllItems();

				auto m_VecMess = kx->getVectorMess();
				size_t m_Size = kx->getVectorMess().size();
				for (size_t i = 0; i < m_Size; ++i)
				{
					Text* m_TextItem = Text::create();
					m_TextItem->setString(m_VecMess.at(i));
					m_TextItem->setContentSize(Size(viSize.width, 25));
					m_TextItem->setFontSize(16);
					m_TextItem->setColor(Color3B::BLACK);
					m_ListView->pushBackCustomItem(m_TextItem);
				}
				m_ListView->jumpToBottom();
				kx->setIsRun(true);
			}
		}
	});
	this->addChild(m_Button1, 98);

	Button* m_Button2 = Button::create("CloseNormal.png", "CloseNormal.png", "CloseNormal.png", ui::Widget::TextureResType::LOCAL);
	m_Button2->setPosition(Size(viSize.width - 40, viSize.height - 160));
	buttonName.clear();
	buttonName = "+";
	auto text2 = Text::create();
	text2->setScale(1.5);
	text2->setString(buttonName);
	text2->setColor(Color3B::BLACK);
	text2->setPosition(Vec2(20, 20));
	m_Button2->addChild(text2, 99, "Text");
	m_Button2->setScale(1.5);
	m_Button2->addTouchEventListener([=](Ref* spender, Widget::TouchEventType type)
	{
		if (type == ui::Widget::TouchEventType::ENDED)
		{
			if (kx->getMaxCount() >= 100)
			{
				kx->setMaxCount(kx->getMaxCount() + 100);
				auto textCount = static_cast<Text*>(this->getChildByName("TextCount"));
				if (textCount)
				{
					textCount->setString(toolToStr(kx->getMaxCount()));
				}
			}
		}
	});
	this->addChild(m_Button2, 98);

	Button* m_Button3 = Button::create("CloseNormal.png", "CloseNormal.png", "CloseNormal.png", ui::Widget::TextureResType::LOCAL);
	m_Button3->setPosition(Size(viSize.width - 40, viSize.height - 220));
	buttonName.clear();
	buttonName = "-";
	auto text3 = Text::create();
	text3->setScale(1.5);
	text3->setString(buttonName);
	text3->setColor(Color3B::BLACK);
	text3->setPosition(Vec2(20, 20));
	m_Button3->addChild(text3, 99, "Text");
	m_Button3->setScale(1.5);
	m_Button3->addTouchEventListener([=](Ref* spender, Widget::TouchEventType type)
	{
		if (type == ui::Widget::TouchEventType::ENDED)
		{
			if (kx->getMaxCount() >= 200)
			{
				kx->setMaxCount(kx->getMaxCount() - 100);
				auto textCount = static_cast<Text*>(this->getChildByName("TextCount"));
				if (textCount)
				{
					textCount->setString(toolToStr(kx->getMaxCount()));
				}
			}
		}
	});
	this->addChild(m_Button3, 98);

    //手动产生crash, 测试c++ bug上传及代码定位
    Button* m_Button4 = Button::create("CloseNormal.png", "CloseNormal.png", "CloseNormal.png", ui::Widget::TextureResType::LOCAL);
    m_Button4->setPosition(Size(viSize.width - 40, 40));
    buttonName = "Bugly";
    auto text4 = Text::create();
    text4->setScale(1.5);
    text4->setString(buttonName);
    text4->setColor(Color3B::BLACK);
    text4->setPosition(Vec2(20, 20));
    m_Button4->addChild(text4, 99, "Text");
    m_Button4->setScale(1.5);
    m_Button4->addClickEventListener([=](Ref* spender)
    {
        if (++m_nCrashCount == 30)
        {
            char* p = NULL;
            p[0] = p[99];
        }
    });
    this->addChild(m_Button4, 98);

	auto text5 = Text::create();
	text5->setScale(1.5);
	
	text5->setString(toolToStr(kx->getMaxCount()));
	text5->setColor(Color3B::BLACK);
	text5->setPosition(Size(viSize.width - 40, viSize.height - 280));
	this->addChild(text5, 99, "TextCount");

}


void UILogLayer::testMsg(Ref* pSender)
{
	if (m_ListView)
	{
		auto viSize = Director::getInstance()->getVisibleSize();
		auto kx = (CLogUiHandler*)KxLogger::getInstance()->getHandler(3);

		size_t lvSize = m_ListView->getItems().size();
		if (lvSize >= kx->getMaxCount())
		{
			auto son = m_ListView->getItem(0);
			m_ListView->removeChild(son, true);
		}

		auto m_VecMess = kx->getVectorMess();
		size_t m_Size = kx->getVectorMess().size();


		Text* m_TextItem = Text::create();
		m_TextItem->setString(m_VecMess.at(m_Size-1));
		m_TextItem->setContentSize(Size(viSize.width, 25));
		m_TextItem->setFontSize(16);
		m_TextItem->setColor(Color3B::BLACK);
		m_ListView->pushBackCustomItem(m_TextItem);
		m_ListView->jumpToBottom();
	}
}

