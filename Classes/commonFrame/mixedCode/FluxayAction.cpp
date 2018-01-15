#include "FluxayAction.h"

using namespace cocos2d;

CFluxayAction::CFluxayAction()
: m_fModTime(0.0f)
, m_FluxayProgramState(nullptr)
, m_OldProgramState(nullptr)
, m_Target(nullptr)
{
}


CFluxayAction::~CFluxayAction()
{
    fourceStop();
}

CFluxayAction* CFluxayAction::create()
{
    CFluxayAction *ret = new CFluxayAction();
    ret->autorelease();
    return ret;
}

void CFluxayAction::startWithTarget(cocos2d::Node *target)
{
    if (target)
    {
        ActionInterval::startWithTarget(target);
        m_Target = target;
        m_Target->retain();

        // ±£´æ¾É×´Ì¬
        CC_SAFE_RELEASE_NULL(m_OldProgramState);
        m_OldProgramState = target->getGLProgramState();
        CC_SAFE_RETAIN(m_OldProgramState);

        auto glProgram = ShaderCache::getInstance()->getGLProgram("Fluxay");
        if (glProgram == nullptr)
        {
            auto fileUtiles = FileUtils::getInstance();
            auto fragmentFilePath = fileUtiles->fullPathForFilename("shaders/Fluxay.frag");
            auto fragSource = fileUtiles->getStringFromFile(fragmentFilePath);
            auto vertexFilePath = fileUtiles->fullPathForFilename("shaders/Fluxay.vert");
            auto vertSource = fileUtiles->getStringFromFile(vertexFilePath);
            glProgram = GLProgram::createWithByteArrays(vertSource.c_str(), fragSource.c_str());
            ShaderCache::getInstance()->addGLProgram(glProgram, "Fluxay");
        }
        target->setGLProgram(glProgram);
        m_FluxayProgramState = target->getGLProgramState();
        CC_SAFE_RETAIN(m_FluxayProgramState);
    }

}

void CFluxayAction::step(float time)
{
    if (m_FluxayProgramState)
    {
        m_fModTime += Director::getInstance()->getAnimationInterval();
        //m_fModTime = fmod(m_fModTime, 3.0f);
        m_FluxayProgramState->setUniformFloat("u_modTime", m_fModTime);
    }
}

void CFluxayAction::fourceStop()
{
    if (m_OldProgramState && m_Target)
    {
        m_Target->setGLProgramState(m_OldProgramState);
        CC_SAFE_RELEASE_NULL(m_OldProgramState);
    }
    CC_SAFE_RELEASE_NULL(m_Target);
}