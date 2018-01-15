#include "SpineComponent.h"
//#include "SpineCache.h"
#include "ResManager.h"
#include "KxCSComm.h"
#include "ConfOther.h"
#include "SimpleShader.h"
#include "ResPool.h"
using namespace spine;

CSpineComponent::CSpineComponent() :m_pSkeletonAnimation(NULL)
{
}

CSpineComponent::~CSpineComponent()
{

}

bool CSpineComponent::initAnimate(const std::string& fileName, Node* displayNode /*= NULL*/)
{
	setDisplayNode(displayNode);
    if (m_pSkeletonAnimation)
    {
        m_pSkeletonAnimation->removeFromParent();
        CC_SAFE_RELEASE_NULL(m_pSkeletonAnimation);
    }
	//m_pSkeletonAnimation = CResManager::getInstance()->createSpine(fileName);
    m_pSkeletonAnimation = CResPool::getInstance()->createSpine(fileName);
	if (NULL != m_pSkeletonAnimation)
	{
        m_MainAnimate = m_pSkeletonAnimation;
		m_pSkeletonAnimation->retain();
        getDisplayNode()->addChild(m_pSkeletonAnimation);
        m_FileName = fileName;
    }
    
	return NULL != m_pSkeletonAnimation;
}

bool CSpineComponent::playAnimate(const std::string& actionName, int loop /*= -1*/)
{
	if (NULL == m_pSkeletonAnimation)
	{
		return false;
	}

	if (actionName.empty())
	{
		return false;
	}

	//spTrackEntry *pTrackEntry = m_pSkeletonAnimation->getCurrent();
	//if (NULL != pTrackEntry)
	//{
	//	std::string curActionName = pTrackEntry->animation->name;
	//	if (curActionName != actionName)
	//	{
	//		m_pSkeletonAnimation->setMix(curActionName, actionName, 0.2f);
	//	}
	//}

    m_pSkeletonAnimation->setToSetupPose();
	m_pSkeletonAnimation->setAnimation(0, actionName, loop == 0 ? false : true);

	return true;
}

void CSpineComponent::setAnimateSpeed(float speed)
{
	if (NULL != m_pSkeletonAnimation)
	{
		m_pSkeletonAnimation->setTimeScale(speed);
	}
}

void CSpineComponent::pause()
{
	if (NULL != m_pSkeletonAnimation)
	{
		m_pSkeletonAnimation->pause();
	}
}

void CSpineComponent::resume()
{
	if (NULL != m_pSkeletonAnimation)
	{
		m_pSkeletonAnimation->resume();
	}
}

void CSpineComponent::setFlipX(bool isFlipX)
{
	if (NULL != m_pSkeletonAnimation && m_bIsFlipX != isFlipX)
	{
		m_pSkeletonAnimation->setScaleX((isFlipX ? -1 : 1) * std::abs(m_pSkeletonAnimation->getScaleX()));
	}
}

void CSpineComponent::onEnter()
{
}

void CSpineComponent::onExit()
{
    if (m_pSkeletonAnimation)
    {
        m_pSkeletonAnimation->removeFromParent();
        CResPool::getInstance()->freeSpineAnimation(m_FileName, m_pSkeletonAnimation);
        m_pSkeletonAnimation->release();
    }

    if (m_pDefaultProgram)
        m_pDefaultProgram->release();

    if (m_pStatusProgram)
        m_pStatusProgram->release();
}

void CSpineComponent::setHSV(const VecFloat &hsv)
{
    if (3 == hsv.size())
    {
        m_pDefaultProgram = CSimpleShader::applyHSVShader(m_pSkeletonAnimation, Vec3(hsv[0], hsv[1], hsv[2]))->clone();
        m_pSkeletonAnimation->setGLProgramState(m_pDefaultProgram);
        m_pDefaultProgram->retain();
    }
}

void CSpineComponent::setHue(const float &hue)
{
    if (hue > 0.0f)
    {
        if (m_pStatusProgram)
        {
            m_pStatusProgram->setUniformFloat("u_hue", hue);
        }
        else
        {
            m_pStatusProgram = CSimpleShader::applyHueShader(m_pSkeletonAnimation, hue)->clone();
            m_pSkeletonAnimation->setGLProgramState(m_pStatusProgram);
            m_pStatusProgram->retain();
        }
    }
    else
    {
        // 如果有默认的并且不是当前的state, 设置回去
        auto preState = m_pSkeletonAnimation->getGLProgramState();
        if (m_pDefaultProgram && preState != m_pDefaultProgram)
        {
            m_pSkeletonAnimation->setGLProgramState(m_pDefaultProgram);
        }
    }
}
