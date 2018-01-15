#include "Effect.h"
#include "SimpleShader.h"

CEffect::CEffect()
: m_nDirection(0)
, m_pConf(NULL)
{
}


CEffect::~CEffect()
{
}

bool CEffect::init()
{
    return Node::init();
}

bool CEffect::init(int dir, const EffectConfItem* conf)
{
    if (NULL == conf)
    {
        return false;
    }

    if (!Node::init())
    {
        return false;
    }
    m_nDirection = dir;
    m_pConf = conf;
    setScale(m_pConf->Scale.x * m_nDirection, m_pConf->Scale.y);
    setCascadeColorEnabled(true);

    return true;
}

void CEffect::onEnter()
{
    Node::onEnter();

    if (NULL != m_pConf)
    {
        setCascadeOpacityEnabled(true);
        // 如果有淡入，则执行淡入逻辑
        if (0.0f < m_pConf->FadeInTime)
        {
            setOpacity(0);
            runAction(FadeIn::create(m_pConf->FadeInTime));
        }
        // 添加位置偏移
        Vec2 newPos = m_pConf->Offset;
        newPos.x *= m_nDirection;
        newPos += getPosition();
        setPosition(newPos);
    }
}

void CEffect::onExit()
{
    Node::onExit();
    //removeAllChildrenWithCleanup(true);
}