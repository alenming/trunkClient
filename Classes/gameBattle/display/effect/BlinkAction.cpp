#include "BlinkAction.h"

#define ACT_TAG 10025

using namespace cocos2d;

BlinkAction::BlinkAction()
: m_OldColor(Color3B::WHITE)
, m_OldProgramState(nullptr)
, m_Target(nullptr)
{
}


BlinkAction::~BlinkAction()
{
    fourceStop();
}

BlinkAction* BlinkAction::create(cocos2d::Node* node, cocos2d::Color3B color, float time)
{
    BlinkAction* blinkAction = new BlinkAction();
    blinkAction->initWithDuration(node, color, time);
    blinkAction->autorelease();
    return blinkAction;
}

bool BlinkAction::initWithDuration(cocos2d::Node* node, cocos2d::Color3B color, float d)
{
    if (ActionInterval::initWithDuration(d))
    {
        auto oldAction = dynamic_cast<BlinkAction*>(
            node->getActionByTag(ACT_TAG));
        if (oldAction)
        {
            // 如果已经在闪
            oldAction->fourceStop();
            node->stopAction(oldAction);
        }

        setTag(ACT_TAG);
        m_Color = color;
        return true;
    }
    return false;
}

void BlinkAction::startWithTarget(cocos2d::Node *target)
{
    if (target)
    {

        ActionInterval::startWithTarget(target);
        m_Target = target;
        m_Target->retain();

        // 保存旧状态
        m_OldColor = target->getColor();
        CC_SAFE_RELEASE_NULL(m_OldProgramState);
        m_OldProgramState = target->getGLProgramState();
        CC_SAFE_RETAIN(m_OldProgramState);

        target->setColor(m_Color);
        auto glProgram = ShaderCache::getInstance()->getGLProgram("SpinePositionTextureColor");
        if (glProgram == nullptr)
        {
            auto fileUtiles = FileUtils::getInstance();
            auto fragmentFilePath = fileUtiles->fullPathForFilename("shaders/SpinePositionTextureColor.frag");
            auto fragSource = fileUtiles->getStringFromFile(fragmentFilePath);
            auto vertexFilePath = fileUtiles->fullPathForFilename("shaders/SpinePositionTextureColor.vert");
            auto vertSource = fileUtiles->getStringFromFile(vertexFilePath);

            glProgram = GLProgram::createWithByteArrays(vertSource.c_str(), fragSource.c_str());
            ShaderCache::getInstance()->addGLProgram(glProgram, "SpinePositionTextureColor");
        }
        target->setGLProgram(glProgram);
    }
}

void BlinkAction::update(float time)
{
    if (time >= 1.0f)
    {
        fourceStop();
    }
}

void BlinkAction::fourceStop()
{
    if (m_OldProgramState && m_Target)
    {
        m_Target->setColor(m_OldColor);
        m_Target->setGLProgramState(m_OldProgramState);
        CC_SAFE_RELEASE_NULL(m_OldProgramState);
    }
    CC_SAFE_RELEASE_NULL(m_Target);
}
