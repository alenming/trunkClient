#include "ArmatureComponent.h"
#include "CommTools.h"

USING_NS_CC;
using namespace cocostudio;

CArmatureComponent::CArmatureComponent()
	:m_Armature(NULL)
{
}


CArmatureComponent::~CArmatureComponent()
{
}

bool CArmatureComponent::initAnimate(const std::string& fileName, Node* displayNode /*= NULL*/)
{
	setDisplayNode(displayNode);
    if (NULL == m_Armature)
    {
        m_Armature = Armature::create(fileName);
        m_MainAnimate = m_Armature;
        return (NULL != m_Armature);
    }
    else
    {
        return m_Armature->init(fileName);
    }
}

bool CArmatureComponent::playAnimate(const std::string& actionName, int loop)
{
    if (NULL == m_Armature)
    {
        return false;
    }

    if (actionName.empty())
    {
        return false;
    }

    m_Armature->getAnimation()->play(actionName, -1, loop);
    return true;
}

void CArmatureComponent::setAnimateSpeed(float speed)
{
    if (NULL != m_Armature)
    {
        m_Armature->getAnimation()->setSpeedScale(speed);
    }
}

void CArmatureComponent::onEnter()
{
	getDisplayNode()->addChild(m_Armature);
}

void CArmatureComponent::onExit()
{
	m_Armature->removeFromParent();
}

void CArmatureComponent::pause()
{
    m_Armature->getAnimation()->pause();
}

void CArmatureComponent::resume()
{
    m_Armature->getAnimation()->resume();
}
