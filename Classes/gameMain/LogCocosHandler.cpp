#include "LogCocosHandler.h"
#include "cocostudio/CocoStudio.h"

CLogCocosHandler::CLogCocosHandler()
{
}


CLogCocosHandler::~CLogCocosHandler()
{
}


bool CLogCocosHandler::onLog(int level, const std::string& log)
{
    cocos2d::log("%s", log.c_str());
	return true;
}
