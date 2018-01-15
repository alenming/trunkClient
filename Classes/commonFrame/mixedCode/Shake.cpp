#include "Shake.h"

CShake::CShake() : m_strength_x ( 0 ), m_strength_y ( 0 ) , m_FromStrongToWeak ( false ), m_TheSameAmplitude ( false ) 
{

}

CShake* CShake::create ( float d, float strength  , bool FromStrongToWeak , bool TheSameAmplitude ) 
{
	return createWithStrength ( d, strength, strength ,FromStrongToWeak,TheSameAmplitude);
}

CShake* CShake::createWithStrength ( float duration, float strength_x, float strength_y , bool FromStrongToWeak , bool TheSameAmplitude  ) 
{
	CShake* pRet = new CShake();
	if ( pRet && pRet->initWithDuration ( duration, strength_x, strength_y ,FromStrongToWeak,TheSameAmplitude) ) 
	{
		pRet->autorelease();
	}
	else 
	{
		CC_SAFE_DELETE ( pRet );
	}
	return pRet;
}

bool CShake::initWithDuration ( float duration, float strength_x, float strength_y , bool FromStrongToWeak , bool TheSameAmplitude ) 
{
	if ( ActionInterval::initWithDuration ( duration ) ) 
	{
		m_strength_x = strength_x;
		m_strength_y = strength_y;
		m_FromStrongToWeak = FromStrongToWeak;
		m_TheSameAmplitude = TheSameAmplitude;
		return true;
	}
	
	return false;
}

static float fgRangeRand ( float min, float max , bool TheSameAmplitude = false ) 
{
	if ( !TheSameAmplitude ) 
	{
		float rnd = ( ( float ) rand() / ( float ) RAND_MAX );
		return rnd * ( max - min ) + min;
	}
	
	else 
	{
		return rand() % 2 == 0 ? max : min;
	}
}

void CShake::update(float dt)
{
	if (fabs(dt) < 1e-6)
	{
		_target->setPosition(m_StartPosition);
		return;
	}
	float fromStrongToWeak;
	fromStrongToWeak = m_FromStrongToWeak ? ( 1 - dt ) : dt;
	float randx = fgRangeRand ( -m_strength_x, m_strength_x , m_TheSameAmplitude ) * fromStrongToWeak;
	float randy = fgRangeRand ( -m_strength_y, m_strength_y , m_TheSameAmplitude ) * fromStrongToWeak;
	_target->setPosition(m_StartPosition + Vec2(randx, randy));
}

void CShake::startWithTarget ( Node* pTarget ) 
{
	ActionInterval::startWithTarget ( pTarget );
	m_StartPosition = pTarget->getPosition();
}

void CShake::stop ( void ) 
{
	this->getTarget()->setPosition ( m_StartPosition );
	ActionInterval::stop();
}