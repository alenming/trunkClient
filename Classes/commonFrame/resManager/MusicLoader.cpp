#include "MusicLoader.h"

#ifndef MUSIC_AUDIO
#define MUSIC_AUDIO 1
#endif

#if 1 == MUSIC_AUDIO
#include "FMODAudioEngine.h"
#else
#include "SimpleAudioEngine.h"
#endif

CMusicLoader::CMusicLoader()
: m_bThreadWork(true)
, m_pThread(nullptr)
{
	m_bIsLoading = false;
}

CMusicLoader::~CMusicLoader()
{
	m_bThreadWork = false;
}

bool CMusicLoader::addPreloadRes(const std::string& resName, const ResLoadedCallback& callback)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	if (m_bIsLoading || fullPath ==""
		|| m_loadingEffect.find(fullPath) != m_loadingEffect.end()
		|| m_loadedEffect.find(fullPath) != m_loadedEffect.end())
	{
		return false;
	}

	CCLOG("add Music %s", fullPath.c_str());
	m_loadingEffect[fullPath] = MusicResInfo();
	m_loadingEffect[fullPath].isLoaded = false;
	m_loadingEffect[fullPath].callback = nullptr;
	if (callback)
	{
		m_loadingEffect[fullPath].callback = callback;
	}
	return true;
}

void CMusicLoader::loadingMusic(float dt)
{
	// load one music per frame
	if (m_loadingEffect.size() > 0)
	{
		const auto& iter = m_loadingEffect.begin();
 		CFMODAudioEngine::getInstance()->loadBankFile(iter->first.c_str());

		if (iter->second.callback)
		{
			iter->second.callback(iter->first, true);
			iter->second.callback = nullptr;
		}
		m_loadingEffect.erase(iter);
	}
	else
	{
		m_loadingEffect.clear();
		m_bIsLoading = false;
		if (m_finishCallback)
		{
			m_finishCallback(m_nPreloadCount, m_loadedEffect.size());
		}
		cocos2d::Director::getInstance()->getScheduler()->unschedule(
			CC_SCHEDULE_SELECTOR(CMusicLoader::loadingMusic), this);		
	}
}

bool CMusicLoader::startLoadResAsyn()
{
    if (m_loadingEffect.size() == 0
        || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

	//不用常备线程, 线程用完就退出
	m_bIsLoading = true;
	m_nPreloadCount = m_loadingEffect.size();
	cocos2d::Director::getInstance()->getScheduler()->schedule(
		CC_SCHEDULE_SELECTOR(CMusicLoader::loadingMusic), this, 0, false);
	return true;
}

bool CMusicLoader::isMusicLoad(const std::string &resName)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	return m_loadedEffect.find(fullPath) != m_loadedEffect.end();
}

void CMusicLoader::removeRes(const std::string& resName)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	auto iter = m_loadedEffect.find(fullPath);
	if (iter != m_loadedEffect.end())
	{
#if 1 == MUSIC_AUDIO
        CFMODAudioEngine::getInstance()->unloadBankFile(fullPath.c_str());
#else
        CocosDenshion::SimpleAudioEngine::getInstance()->unloadEffect(fullPath.c_str());
#endif
		
		m_loadedEffect.erase(iter);
	}
}

void CMusicLoader::cacheRes(const std::string& resName)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	if (m_cacheRes.find(fullPath) == m_cacheRes.end())
	{
		m_cacheRes.insert(fullPath);
	}
}

void CMusicLoader::clearRes()
{
    IResLoader::clearRes();
    if (m_bIsLoading)
    {
        m_bIsLoading = false;
        m_loadingEffect.clear();
        m_nPreloadCount = 0;
        m_finishCallback = nullptr;
        cocos2d::Director::getInstance()->getScheduler()->unschedule(
            CC_SCHEDULE_SELECTOR(CMusicLoader::loadingMusic), this);
    }

	for (std::set<std::string>::iterator iter = m_loadedEffect.begin(); 
		iter != m_loadedEffect.end(); )
	{
		auto cacheIter = m_cacheRes.find(*iter);
		// 不需要缓存的进行卸载
		if (cacheIter == m_cacheRes.end())
		{
#if 1 == MUSIC_AUDIO
            CFMODAudioEngine::getInstance()->unloadBankFile((*iter).c_str());
#else
            CocosDenshion::SimpleAudioEngine::getInstance()->unloadEffect((*iter).c_str());
#endif
			
			iter = m_loadedEffect.erase(iter);
		}
		else
		{
			++iter;
		}
	}
	//清除列表
    m_cacheRes.clear();
}

int CMusicLoader::getLoadedCount()
{
	return  m_loadedEffect.size();
}

int CMusicLoader::getPreloadCount()
{
	return m_loadingEffect.size();
}
