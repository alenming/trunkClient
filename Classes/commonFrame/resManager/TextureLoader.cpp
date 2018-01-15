#include "TextureLoader.h"
#include "cocostudio/CCSpriteFrameCacheHelper.h"
#include "CommTools.h"

using namespace cocos2d;

CTextureLoader::CTextureLoader()
: m_nPreloadCount(0)
, m_nLoadedCount(0)
{
}

CTextureLoader::~CTextureLoader()
{
    clearRes();
}

bool CTextureLoader::addPreloadRes(const std::string& resName, const ResLoadedCallback& callback)
{
    if (!checkLoadRes(resName, "", callback))
    {
        return false;
    }

	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	m_preloadList[fullPath] = TextureLoadInfo();
	m_preloadList[fullPath].isLoaded = false;
    m_preloadList[fullPath].callback = callback;
    LOGDEBUG("performance: CTextureLoader load %s", resName.c_str());
	return true;
}

bool CTextureLoader::startLoadResAsyn()
{
    if (m_preloadList.size() == 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    m_bIsLoading = true;
	m_nPreloadCount = m_preloadList.size();
    auto preLoadList = m_preloadList;
    m_nLoadedCount = 0;
    for (auto &iter : preLoadList)
	{
        std::string suffix = getSuffix(iter.first);
        std::string textureFile = iter.first;
        if (suffix == ".plist")
        {
            textureFile = TextureTools::getTexturePathFromPlist(textureFile);
        }		

        Director::getInstance()->getTextureCache()->addImageAsync(textureFile, [this, iter, suffix, textureFile](Texture2D* tex)->void
        {
            ++m_nLoadedCount;
            if (m_TextureCache.find(iter.first) == m_TextureCache.end()
                && tex != nullptr)
            {
                m_TextureCache[iter.first] = tex;
                tex->retain();
                if (suffix == ".plist")
                {
                    cocostudio::SpriteFrameCacheHelper::getInstance()->addSpriteFrameFromFile(iter.first, textureFile);
                }
            }

            if (iter.second.callback)
            {
                iter.second.callback(iter.first, tex != nullptr);
            }

            if (m_nLoadedCount == m_nPreloadCount)
            {
                LOGDEBUG("performance: CTextureLoader onFinish %d", utils::getTimeInMilliseconds());
                m_bIsLoading = false;
                if (m_finishCallback)
                {
                    m_finishCallback(m_nPreloadCount, m_nPreloadCount);
                }
                m_preloadList.clear();
                autoLoadRes();
            }
        });
	}
	return true;
}

void CTextureLoader::removeRes(const std::string& resName)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
    auto iter = m_TextureCache.find(fullPath);
    if (iter != m_TextureCache.end())
    {
        LOGDEBUG("performance: CTextureLoader unload %s", resName.c_str());
		std::string suffix = getSuffix(fullPath);
		if (suffix == ".plist")
		{
            cocostudio::SpriteFrameCacheHelper::getInstance()->removeSpriteFrameFromFile(fullPath);
		}
        iter->second->release();
        m_TextureCache.erase(iter);
	}
}

void CTextureLoader::cacheRes(const std::string& resName)
{
	std::string fullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename(resName);
	if (m_cacheRes.find(fullPath) == m_cacheRes.end())
	{
		m_cacheRes.insert(fullPath);
	}
}

void CTextureLoader::clearRes()
{
    if (m_bIsLoading)
    {
        m_bIsLoading = false;
        IResLoader::clearRes();
        Director::getInstance()->getTextureCache()->unbindAllImageAsync();
        m_finishCallback = nullptr;
        m_nLoadedCount = 0;
        m_nPreloadCount = 0;
        m_preloadList.clear();
    }

    for (std::map<std::string, cocos2d::Texture2D*>::iterator iter = m_TextureCache.begin();
        iter != m_TextureCache.end();)
	{
		auto cacheIter = m_cacheRes.find(iter->first);
		// 清理不需要缓存的对象
		if (cacheIter == m_cacheRes.end())
        {
            LOGDEBUG("performance: CTextureLoader unload %s", iter->first.c_str());
            std::string suffix = getSuffix(iter->first);
			if (suffix == ".plist")
            {
                cocostudio::SpriteFrameCacheHelper::getInstance()->removeSpriteFrameFromFile(iter->first);
			}
            iter->second->release();
			//移除不需要缓存的资源
            iter = m_TextureCache.erase(iter);
		}
		else
		{
			++iter;
		}
	}
	// 缓存的对象
	m_cacheRes.clear();
}

int CTextureLoader::getLoadedCount()
{
    return m_TextureCache.size();
}

int CTextureLoader::getPreloadCount()
{
	return m_preloadList.size();
}

std::string CTextureLoader::getSuffix(const std::string &filename)
{
	std::size_t pos = filename.find_last_of(".");
	if (pos != std::string::npos)
	{
		std::string suffix = filename.substr(pos, filename.size());
		return suffix;
	}
	return "";
}
