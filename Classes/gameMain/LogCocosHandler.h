#ifndef _LOG_COCOS_HANDLER_H__
#define _LOG_COCOS_HANDLER_H__

#include "KxLog.h"

class CLogCocosHandler : public IKxLogHandler
{
public:
	CLogCocosHandler();
	~CLogCocosHandler();

public:
	virtual bool onLog(int level, const std::string& log);
};


#endif //_LOG_COCOS_HANDLER_H__
