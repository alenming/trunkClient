#include "SpineLoader.h"
#include "CommTools.h"
using namespace spine;
using namespace std;
USING_NS_CC;

CSpineLoader::CSpineLoader()
: m_bThreadWorking(false)
, m_nFinishIndex(-1)
, m_SkeletonThread(nullptr)
{
}

CSpineLoader::~CSpineLoader()
{
    clearRes();
}

bool CSpineLoader::addPreloadRes(const std::string& resName, const std::string& atlasName, const ResLoadedCallback& callback)
{
    if (!checkLoadRes(resName, atlasName, callback)
        || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    string fullJsonPath = FileUtils::getInstance()->fullPathForFilename(resName);
    m_LoadingSpine.insert(fullJsonPath);
    m_LoadingInfos.push_back(SpineLoadingInfo());
    SpineLoadingInfo& spineInfo = m_LoadingInfos[m_LoadingInfos.size() - 1];
    spineInfo.JsonFile = fullJsonPath;
    int pos = atlasName.find_last_of('.');
    if (pos != std::string::npos)
    {
        spineInfo.TextureFile = atlasName.substr(0, pos + 1) + "png";
        spineInfo.TextureFile = FileUtils::getInstance()->fullPathForFilename(spineInfo.TextureFile);
    }
    spineInfo.AtlasFile = FileUtils::getInstance()->fullPathForFilename(atlasName);
    spineInfo.Callback = callback;
    spineInfo.Atlas = nullptr;
    spineInfo.SkeletonData = nullptr;
    spineInfo.AtlasImage = nullptr;
    LOGDEBUG("performance: CSpineLoader load %s", resName.c_str());
    return true;
}


// 旧的异步加载
bool CSpineLoader::startLoadResAsyn()
{
    if (m_LoadingInfos.size() == 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    m_bIsLoading = true;
    m_nTextureLoadingIndex = 0;
    m_nSkeletonLoadingIndex = 0;
    m_nFinishIndex = 0;

    for (auto& spineInfo : m_LoadingInfos)
    {
        function<void(Texture2D* tex)> fun = [this, &spineInfo](Texture2D* tex)->void
        {
            spineInfo.Atlas = spAtlas_createFromFile(spineInfo.AtlasFile.c_str(), 0);
            if (spineInfo.Atlas == nullptr)
            {
                CCLOG("spAtlas_createFromFile %s failed", spineInfo.AtlasFile.c_str());
            }
            else
            {
                std::function<void(void*)> mainThread = [&spineInfo, this](void* param)
                {
                    if (spineInfo.SkeletonData != nullptr)
                    {
                        SpineCacheInfo cacheInfo;
                        cacheInfo.Atlas = spineInfo.Atlas;
                        cacheInfo.SkeletonData = spineInfo.SkeletonData;
                        m_SpineCache[spineInfo.JsonFile] = cacheInfo;
                    }
                    CCLOG("CSpineLoader onSkeletonLoaded finish %s", spineInfo.JsonFile.c_str());
                    if (spineInfo.Callback != nullptr)
                    {
                        spineInfo.Callback(spineInfo.JsonFile, spineInfo.SkeletonData != nullptr);
                    }
                    ++m_nFinishIndex;
                    if (m_nFinishIndex >= static_cast<int>(m_LoadingInfos.size()))
                    {
                        onFinish();
                    }
                };

                AsyncTaskPool::getInstance()->enqueue(AsyncTaskPool::TaskType::TASK_IO, mainThread, (void*)NULL, [&spineInfo]()
                {
                    if (spineInfo.Atlas != nullptr)
                    {
                        spSkeletonJson* json = spSkeletonJson_create(spineInfo.Atlas);
                        if (json == nullptr)
                        {
                            CCLOG("spSkeletonJson_create %s failed", spineInfo.JsonFile.c_str());
                        }
                        spineInfo.SkeletonData = spSkeletonJson_readSkeletonDataFile(
                            json, spineInfo.JsonFile.c_str());
                        if (spineInfo.SkeletonData == nullptr)
                        {
                            CCLOG("spSkeletonJson_readSkeletonDataFile %s failed", spineInfo.JsonFile.c_str());
                        }
                        spSkeletonJson_dispose(json);
                    }
                });
            }
        };
        Director::getInstance()->getTextureCache()->addImageAsync(spineInfo.TextureFile, fun);
    } 

    return true;
}

/*// 新的异步加载，更加高效
bool CSpineLoader::startLoadResAsyn()
{
    if (m_LoadingInfos.size() == 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }
    m_bIsLoading = true;
    m_nTextureLoadingIndex = 0;
    m_nSkeletonLoadingIndex = 0;
    m_nFinishIndex = 0;

    for (auto& spineInfo : m_LoadingInfos)
    {
        function<void(void* args)> textureLoadOver = [this, &spineInfo](void* args)->void
        {
            std::function<void(void*)> mainThread = [&spineInfo, this](void* param)
            {
                if (spineInfo.SkeletonData != nullptr)
                {
                    SpineCacheInfo cacheInfo;
                    cacheInfo.Atlas = spineInfo.Atlas;
                    cacheInfo.SkeletonData = spineInfo.SkeletonData;
                    m_SpineCache[spineInfo.JsonFile] = cacheInfo;
                }
                CCLOG("CSpineLoader onSkeletonLoaded finish %s", spineInfo.JsonFile.c_str());
                if (spineInfo.Callback != nullptr)
                {
                    spineInfo.Callback(spineInfo.JsonFile, spineInfo.SkeletonData != nullptr);
                }
                ++m_nFinishIndex;
                if (m_nFinishIndex >= static_cast<int>(m_LoadingInfos.size()))
                {
                    onFinish();
                }
            };

            if (spineInfo.AtlasImage != nullptr)
            {
                Director::getInstance()->getTextureCache()->addImage(spineInfo.AtlasImage, spineInfo.TextureFile);
                CC_SAFE_RELEASE_NULL(spineInfo.AtlasImage);
            }

            // 在主线程中
            spineInfo.Atlas = spAtlas_createFromFile(spineInfo.AtlasFile.c_str(), 0);
            if (spineInfo.Atlas == nullptr)
            {
                CCLOG("spAtlas_createFromFile %s failed", spineInfo.AtlasFile.c_str());
                mainThread(nullptr);
            }
            else
            {
                AsyncTaskPool::getInstance()->enqueue(AsyncTaskPool::TaskType::TASK_OTHER, mainThread, (void*)NULL, [&spineInfo]()
                {
                    if (spineInfo.Atlas != nullptr)
                    {
                        spSkeletonJson* json = spSkeletonJson_create(spineInfo.Atlas);
                        if (json == nullptr)
                        {
                            CCLOG("spSkeletonJson_create %s failed", spineInfo.JsonFile.c_str());
                        }
                        spineInfo.SkeletonData = spSkeletonJson_readSkeletonDataFile(
                            json, spineInfo.JsonFile.c_str());
                        if (spineInfo.SkeletonData == nullptr)
                        {
                            CCLOG("spSkeletonJson_readSkeletonDataFile %s failed", spineInfo.JsonFile.c_str());
                        }
                        spSkeletonJson_dispose(json);
                    }
                });
            }
        };

        // 先异步加载纹理（这里不去TextureCache中加载，是因为Spine的纹理是一一对应的，其他资源不会用到）
        auto spineTex = Director::getInstance()->getTextureCache()->getTextureForKey(spineInfo.TextureFile);
        if (spineTex)
        {
            textureLoadOver(nullptr);
        }
        else
        {
            AsyncTaskPool::getInstance()->enqueue(AsyncTaskPool::TaskType::TASK_IO, textureLoadOver, (void*)NULL, [&spineInfo]()
            {
                spineInfo.AtlasImage = new Image();
                if (!spineInfo.AtlasImage->initWithImageFile(spineInfo.TextureFile))
                {
                    CC_SAFE_DELETE(spineInfo.AtlasImage);
                }
            });
        }
    }

    return true;
}*/

void CSpineLoader::onSkeletonLoaded(float dt)
{
    int count = 0;
    while (m_nFinishIndex < m_nSkeletonLoadingIndex
        && count++ < 3)
    {
        SpineLoadingInfo& info = m_LoadingInfos[m_nFinishIndex];
        if (info.SkeletonData != nullptr)
        {
            SpineCacheInfo cacheInfo;
            cacheInfo.Atlas = info.Atlas;
            cacheInfo.SkeletonData = info.SkeletonData;
            m_SpineCache[info.JsonFile] = cacheInfo;
        }

        CCLOG("CSpineLoader onSkeletonLoaded %s", info.JsonFile.c_str());
        if (info.Callback != nullptr)
        {
            info.Callback(info.JsonFile, info.SkeletonData != nullptr);
        }

        ++m_nFinishIndex;
        if (m_nFinishIndex >= static_cast<int>(m_LoadingInfos.size()))
        {
            onFinish();
        }
    }
}

spSkeletonData* CSpineLoader::getSkeletonData(const std::string& resName)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    auto iter = m_SpineCache.find(fullPath);
    if (iter != m_SpineCache.end())
    {
        return iter->second.SkeletonData;
    }
    return nullptr;
}

void CSpineLoader::removeRes(const std::string& resName)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    auto iter = m_SpineCache.find(fullPath);
    if (iter != m_SpineCache.end())
    {
        LOGDEBUG("performance: CSpineLoader unload %s", resName.c_str());
        spAtlas_dispose(iter->second.Atlas);
        spSkeletonData_dispose(iter->second.SkeletonData);
        m_SpineCache.erase(iter);
    }
}

void CSpineLoader::cacheRes(const std::string& resName)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    if (m_CacheRes.find(fullPath) == m_CacheRes.end())
    {
        CCLOG("CSpineLoader::cacheRes %s", fullPath.c_str());
        m_CacheRes.insert(fullPath);
    }
}

void CSpineLoader::clearRes()
{
    IResLoader::clearRes();
    if (m_bIsLoading)
    {
        // 因为是强制中断，所以需要清空回调
        m_finishCallback = nullptr;
        onFinish();
    }

    for (std::map<std::string, SpineCacheInfo>::iterator iter = m_SpineCache.begin();
        iter != m_SpineCache.end();)
    {
        auto cacheIter = m_CacheRes.find(iter->first);
        if (cacheIter == m_CacheRes.end())
        {
            LOGDEBUG("performance: CSpineLoader unload %s", iter->first.c_str());
            spAtlas_dispose(iter->second.Atlas);
            spSkeletonData_dispose(iter->second.SkeletonData);
            m_SpineCache.erase(iter++);
        }
        else
        {
            ++iter;
        }
    }
    m_CacheRes.clear();
}

void CSpineLoader::onFinish()
{
    if (m_SkeletonThread)
    {
        m_bThreadWorking = false;
        m_SkeletonThread->join();
        delete m_SkeletonThread;
        m_SkeletonThread = nullptr;
    }

    Director::getInstance()->getScheduler()->unschedule(
        CC_SCHEDULE_SELECTOR(CSpineLoader::onSkeletonLoaded), this);

    LOGDEBUG("performance: CSpineLoader onFinish %d", utils::getTimeInMilliseconds());

    if (m_finishCallback)
    {
        m_finishCallback(m_nFinishIndex, m_LoadingInfos.size());
    }

    m_nTextureLoadingIndex = 0;
    m_nSkeletonLoadingIndex = 0;
    m_nFinishIndex = 0;

    m_bIsLoading = false;
    for (auto info : m_LoadingInfos)
    {
        if (info.AtlasImage != nullptr)
        {
            info.AtlasImage->release();
        }
    }
    m_LoadingInfos.clear();
    m_LoadingSpine.clear();
    autoLoadRes();
}
/*
void CSpineLoader::skeletonThread()
{
    while (m_bThreadWorking)
    {
        if (m_nTextureLoadingIndex > m_nSkeletonLoadingIndex)
        {
            SpineLoadingInfo& spineInfo = m_LoadingInfos[m_nSkeletonLoadingIndex];
            if (spineInfo.Atlas != nullptr)
            {
                spSkeletonJson* json = spSkeletonJson_create(spineInfo.Atlas);
                if (json == nullptr)
                {
                    CCLOG("spSkeletonJson_create %s failed", spineInfo.JsonFile.c_str());
                }
                spineInfo.SkeletonData = spSkeletonJson_readSkeletonDataFile(
                    json, spineInfo.JsonFile.c_str());
                if (spineInfo.SkeletonData == nullptr)
                {
                    CCLOG("spSkeletonJson_readSkeletonDataFile %s failed", spineInfo.JsonFile.c_str());
                }
                spSkeletonJson_dispose(json);
            }

            ++m_nSkeletonLoadingIndex;
            if (m_nSkeletonLoadingIndex >= static_cast<int>(m_LoadingInfos.size()))
            {
                break;
            }
            this_thread::sleep_for(chrono::milliseconds(1));
        }
    }
}

void CSpineLoader::loadNextSkeletonThreadSafe()
{
    SpineLoadingInfo& spineInfo = m_LoadingInfos[m_nSkeletonLoadingIndex];
    std::function<void(void*)> mainThread = [&spineInfo, this](void* param)
    {
        ++m_nSkeletonLoadingIndex;
        if (spineInfo.SkeletonData != nullptr)
        {
            SpineCacheInfo cacheInfo;
            cacheInfo.Atlas = spineInfo.Atlas;
            cacheInfo.SkeletonData = spineInfo.SkeletonData;
            m_SpineCache[spineInfo.JsonFile] = cacheInfo;
        }

        CCLOG("CSpineLoader onSkeletonLoaded %s", spineInfo.JsonFile.c_str());
        if (spineInfo.Callback != nullptr)
        {
            spineInfo.Callback(spineInfo.JsonFile, spineInfo.SkeletonData != nullptr);
        }

        ++m_nFinishIndex;
        if (m_nFinishIndex >= static_cast<int>(m_LoadingInfos.size()))
        {
            onFinish();
        }
    };

    AsyncTaskPool::getInstance()->enqueue(AsyncTaskPool::TaskType::TASK_IO, mainThread, (void*)NULL, [&spineInfo]()
    {
        if (spineInfo.Atlas != nullptr)
        {
            spSkeletonJson* json = spSkeletonJson_create(spineInfo.Atlas);
            if (json == nullptr)
            {
                CCLOG("spSkeletonJson_create %s failed", spineInfo.JsonFile.c_str());
            }
            spineInfo.SkeletonData = spSkeletonJson_readSkeletonDataFile(
                json, spineInfo.JsonFile.c_str());
            if (spineInfo.SkeletonData == nullptr)
            {
                CCLOG("spSkeletonJson_readSkeletonDataFile %s failed", spineInfo.JsonFile.c_str());
            }
            spSkeletonJson_dispose(json);
        }
    });
}

void CSpineLoader::loadNextTextureThreadSafe()
{
    if (m_nTextureLoadingIndex >= static_cast<int>(m_LoadingInfos.size()))
    {
        return;
    }

    SpineLoadingInfo& spineInfo = m_LoadingInfos[m_nTextureLoadingIndex];
    function<void(Texture2D* tex)> fun = [this, &spineInfo](Texture2D* tex)->void
    {
        spineInfo.Atlas = spAtlas_createFromFile(spineInfo.AtlasFile.c_str(), 0);
        if (spineInfo.Atlas == nullptr)
        {
            CCLOG("spAtlas_createFromFile %s failed", spineInfo.AtlasFile.c_str());
        }
        ++m_nTextureLoadingIndex;
        loadNextSkeletonThreadSafe();
        loadNextTextureThreadSafe();
    };

    if (spineInfo.TextureFile.empty())
    {
        fun(nullptr);
    }
    else
    {
        Director::getInstance()->getTextureCache()->addImageAsync(spineInfo.TextureFile, fun);
    }
}

*/