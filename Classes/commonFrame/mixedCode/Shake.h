#ifndef _SUM_SHAKE_H_
#define _SUM_SHAKE_H_

#include "KxCSComm.h"

class CShake : public cocos2d::ActionInterval 
{
public:
	CShake();
	static CShake* create( float d, float strength , bool FromStrongToWeak = true, bool TheSameAmplitude = false );
	static CShake* createWithStrength( float d, float strength_x, float strength_y , bool FromStrongToWeak = false, bool TheSameAmplitude = false );

protected:
	bool initWithDuration( float d, float strength_x, float strength_y , bool FromStrongToWeak = false, bool TheSameAmplitude = false );
	void startWithTarget( Node* pTarget );
	void update( float time );
	void stop( void );
		
private:
	Point m_StartPosition;
	float m_strength_x;
	float m_strength_y;
	bool m_FromStrongToWeak;
	bool m_TheSameAmplitude;
};

#endif 
