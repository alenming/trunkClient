#include "TipBloodNode.h"
#include "cocostudio/CocoStudio.h"
#include "ui/CocosGUI.h"
#include "CsbEffect.h"

USING_NS_CC;
using namespace ui;
using namespace cocostudio;
using namespace timeline;

#define TIP_BLOOD_MAX_COUNT 20

TipBloodNode* TipBloodNode::m_Instance = NULL;

TipBloodNode::TipBloodNode()
:tipBloodMaxCount(0)
{
	
}

TipBloodNode::~TipBloodNode()
{

}

TipBloodNode* TipBloodNode::getInstance()
{
	if (NULL == m_Instance)
	{
		m_Instance = new TipBloodNode();
	}
	return m_Instance;
}

void TipBloodNode::destory()
{
	if (NULL != m_Instance)
	{
		delete m_Instance;
		m_Instance = NULL;
	}
}

Node* TipBloodNode::getCsb(const std::string& text, const std::string& animationName)
{
	//CCLOG("now! tipBloodNode count is %d", tipBloodMaxCount);
	if (tipBloodMaxCount > TIP_BLOOD_MAX_COUNT)
	{
		return nullptr;
	}
    do 
    {
        CCsbEffect* bloodEffect = new CCsbEffect();
        if (bloodEffect->init("ui_new/f_fight/bloodbar/TipBloodNum.csb", false))
        {
            Node* panel = bloodEffect->getEffectNode()->getChildByName(animationName);
            if (nullptr == panel) break;
            TextBMFont* label = dynamic_cast<TextBMFont*>(panel->getChildByName("BloodNum"));
            if (nullptr == label) break;
            label->setString(text);
            bloodEffect->playAnimateAutoRemove(animationName);
            bloodEffect->setOnExitCallback([this](){
                --tipBloodMaxCount;
            });
            ++tipBloodMaxCount;
            return bloodEffect;
        }
    } while (false);
    return nullptr;
}

