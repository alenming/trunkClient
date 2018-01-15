#include "AnimateComponent.h"

USING_NS_CC;

CAnimateComponent::CAnimateComponent()
    : m_bIsFlipX(false)
    , m_DisplayNode(nullptr)
    , m_MainAnimate(nullptr)
    , m_pDefaultProgram(NULL)
    , m_pStatusProgram(NULL)
{
    setMutex(true);
}

CAnimateComponent::~CAnimateComponent()
{
}

void CAnimateComponent::setCascadeColorAndOpacityEnabled(Node* node)
{
    if (node)
    {
        node->setCascadeColorEnabled(true);
        node->setCascadeOpacityEnabled(true);

        for (auto& child : node->getChildren())
        {
            setCascadeColorAndOpacityEnabled(child);
        }
    }
}
