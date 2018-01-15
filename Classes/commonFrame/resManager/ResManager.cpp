#include "ResManager.h"
#include "CsbLoader.h"
#include "SpineLoader.h"
#include "ArmatureLoader.h"
#include "TextureLoader.h"
#include "MusicLoader.h"
#include "CsbTool.h"
/*
csb: .csb(2.0)
texture: .png .plist
music: .mp3 .wav
armature: .csb(1.6) .ExportJson
spine: .json+.atlas
*/

USING_NS_CC;

CResManager::CResManager()
: m_bIsLoading(false)
, m_nPreload(0)
, m_nLoaded(0)
, m_FinishCallback(nullptr)
{
}

CResManager::~CResManager()
{
    for (auto iter : m_Loaders)
    {
        delete iter.second;
    }
    m_Loaders.clear();
}

CResManager* CResManager::m_Instance = NULL;
CResManager* CResManager::getInstance()
{
    if (NULL == m_Instance)
    {
        m_Instance = new CResManager;
        m_Instance->init();
    }
    return m_Instance;
}

void CResManager::destroy()
{
    if (NULL != m_Instance)
    {
        delete m_Instance;
        m_Instance = NULL;
    }
}

bool CResManager::addPreloadRes(const std::string& resName, const ResLoadedCallback& callback)
{
    std::string suffix = getSuffix(resName);
    // 图集
    if (suffix == ".png" || suffix == ".plist")
    {
        return m_Loaders[LOADER_TEXTURE]->addPreloadRes(resName, callback);
    }
    // 默认是2.0csb, 1.6为骨骼由其它接口加载
    else if (suffix == ".csb")
    {
        return m_Loaders[LOADER_CSB]->addPreloadRes(resName, callback);
    }
    // 音乐
    else if (suffix == ".bank")
    {
        return m_Loaders[LOADER_MUSIC]->addPreloadRes(resName, callback);
    }
    else
    {
        //其它的资源不由该接口加载
        return false;
    }
    return true;
}

bool CResManager::addPreloadRes(const std::string& resName, const std::string& ass, const ResLoadedCallback& callback)
{
    std::string file1Suffix = getSuffix(resName);
    std::string flieS2uffix = getSuffix(ass);
    // spine
    if (file1Suffix == ".json" && flieS2uffix == ".atlas")
    {
        return m_Loaders[LOADER_SPINE]->addPreloadRes(resName, ass, callback);
    }
    else
    {
        //暂时只处理spine
        CCLOG("Please add spine file at this API!");
        return false;
    }
    return true;
}

bool CResManager::addPreloadArmature(const std::string& resName, const ResLoadedCallback &callback)
{
    std::string suffix = getSuffix(resName);
    // spine
    if (suffix == ".ExportJson" || suffix == ".csb")
    {
        return m_Loaders[LOADER_ARMATURE]->addPreloadRes(resName, callback);
    }
    else
    {
        //暂时只处理1.6骨骼动画
        CCLOG("Please add Armature file at this API!");
        return false;
    }
    return true;
}

double begin = 0.0;
double end = 0.0;

bool CResManager::startResAsyn()
{
    begin = utils::gettime();
    if (!m_bIsLoading)
    {
        m_bIsLoading = true;
        std::function<void(int, int)> finishFunc = [&](int preload, int loaded){
            m_nLoaded += loaded;
            m_nPreload += preload;
        };

        for (auto iter : m_Loaders)
        {
            iter.second->setFinishCallback(finishFunc);
        }

        Director::getInstance()->getScheduler()->schedule(
            CC_SCHEDULE_SELECTOR(CResManager::checkLoading), this, 0, false);
    }

    for (auto iter : m_Loaders)
    {
        if (!iter.second->isLoading())
        {
            iter.second->startLoadResAsyn();
        }
    }
    return true;
}

void CResManager::setFinishCallback(const ResFinishCallback& callback)
{
    KXLOGDEBUG("CResManager::setFinishCallback");
    m_FinishCallback = callback;
}

spSkeletonData * CResManager::getSpineSkeletonData(const std::string &resName)
{
    CSpineLoader *pLoader = dynamic_cast<CSpineLoader*>(m_Loaders[LOADER_SPINE]);
    return pLoader->getSkeletonData(resName);
}

spine::SkeletonAnimation* CResManager::createSpine(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    if (suffix == ".json")
    {
        spine::SkeletonAnimation* pAnimation = NULL;
        CSpineLoader *pSpineLoader = dynamic_cast<CSpineLoader*>(m_Loaders[LOADER_SPINE]);
        spSkeletonData *data = pSpineLoader->getSkeletonData(resName);
        if (NULL != data)
        {
            pAnimation = spine::SkeletonAnimation::createWithData(data);
            return pAnimation;
        }
    }
    return NULL;
}

cocos2d::Node* CResManager::getCsbNode(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    if (suffix == ".csb")
    {
        CNewCsbLoader *pCSBLoader = dynamic_cast<CNewCsbLoader*>(m_Loaders[LOADER_CSB]);
        cocos2d::Node* pNode = pCSBLoader->createCsbNode(resName);
        return pNode;
    }
    return NULL;
}

cocos2d::Node* CResManager::cloneCsbNode(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    if (suffix == ".csb")
    {
        CNewCsbLoader *pCSBLoader = dynamic_cast<CNewCsbLoader*>(m_Loaders[LOADER_CSB]);
        cocos2d::Node* pNode = pCSBLoader->createCsbNode(resName);
        return pNode;
        /*
        #if (CC_PLATFORM_WIN32 == CC_TARGET_PLATFORM)
        if (pNode == NULL)
        {
        CCLOG("%s", resName.c_str());
        cocos2d::MessageBox("Fuck大策划！你忘记在ResPath里面配Csb资源了，资源名看LOG", "Fuck");
        }
        #endif
        pNode = CsbTool::cloneCsbNode(pNode);
        //auto action = dynamic_cast<cocostudio::timeline::ActionTimeline*>(pNode->getActionByTag(pNode->getTag()));
        //if (action) action->gotoFrameAndPause(0);
        // 如果不播放动画，会出现一些错误，因为有些CSB依赖第一个动画来初始化一些显示状态
        auto action = cocostudio::timeline::ActionTimelineCache::getInstance(
        )->createActionWithFlatBuffersFile(resName);
        if (action)
        {
        pNode->runAction(action);
        //action->setTag(TAG_CSB_ACTION);
        action->gotoFrameAndPause(0);
        }
        return pNode;*/
    }
    return NULL;
}

bool CResManager::removeRes(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    // 图集
    if (suffix == ".png" || suffix == ".plist")
    {
        m_Loaders[LOADER_TEXTURE]->removeRes(resName);
    }
    // 默认是2.0csb, 1.6为骨骼由其它接口移除
    else if (suffix == ".csb")
    {
        m_Loaders[LOADER_CSB]->removeRes(resName);
    }
    // 音乐
    else if (suffix == ".bank")
    {
        m_Loaders[LOADER_MUSIC]->removeRes(resName);
    }
    // spine
    else if (suffix == ".json")
    {
        m_Loaders[LOADER_SPINE]->removeRes(resName);
    }
    else
    {
        //其它的资源不由该接口处理
        return false;
    }
    return true;
}

bool CResManager::removeArmature(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    if (suffix == ".ExportJson" || suffix == ".csb")
    {
        m_Loaders[LOADER_ARMATURE]->removeRes(resName);
        return true;
    }
    return false;
}

void CResManager::cacheRes(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    // 图集
    if (suffix == ".png" || suffix == ".plist")
    {
        m_Loaders[LOADER_TEXTURE]->cacheRes(resName);
    }
    // 默认是2.0csb, 1.6为骨骼由其它接口移除
    else if (suffix == ".csb" || suffix == ".ExportJson")
    {
        m_Loaders[LOADER_CSB]->cacheRes(resName);
        m_Loaders[LOADER_ARMATURE]->cacheRes(resName);
    }
    // 音乐
    else if (suffix == ".bank")
    {
        m_Loaders[LOADER_MUSIC]->cacheRes(resName);
    }
    // spine
    else if (suffix == ".json")
    {
        m_Loaders[LOADER_SPINE]->cacheRes(resName);
    }
}

void CResManager::cacheRes(int loaderType)
{
    if (m_CacheLoader.find(loaderType) != m_CacheLoader.end())
    {
        CCLOG("cache res type %d", loaderType);
        m_CacheLoader.insert(loaderType);
    }
}

void CResManager::clearRes()
{
    if (m_bIsLoading)
    {
        m_bIsLoading = false;
        m_FinishCallback = nullptr;
        Director::getInstance()->getScheduler()->unschedule(
            CC_SCHEDULE_SELECTOR(CResManager::checkLoading), this);
        m_nPreload = 0;
        m_nLoaded = 0;
    }

    for (auto& iter : m_Loaders)
    {
        //不清除某一类的loader
        //if (m_CacheLoader.find(iter.first) == m_CacheLoader.end())
        //{
            //CCLOG("clear res %d", iter.first);
            iter.second->clearRes();
        //}
    }
    m_CacheLoader.clear();
    
    if (Director::getInstance()->getOpenGLView())
    {
        SpriteFrameCache::getInstance()->removeUnusedSpriteFrames();
        Director::getInstance()->getTextureCache()->removeUnusedTextures();

        // Note: some tests such as ActionsTest are leaking refcounted textures
        // There should be no test textures left in the cache
        log("%s\n", Director::getInstance()->getTextureCache()->getCachedTextureInfo().c_str());
    }
    //FileUtils::getInstance()->purgeCachedEntries();
    //Director::getInstance()->purgeCachedData();
}

bool CResManager::hasRes(const std::string& resName)
{
    std::string suffix = getSuffix(resName);
    // 图集
    if (suffix == ".png" || suffix == ".plist")
    {
        return m_Loaders[LOADER_TEXTURE]->hasRes(resName);
    }
    // 默认是2.0csb, 1.6为骨骼由其它接口移除
    else if (suffix == ".csb" || suffix == ".ExportJson")
    {
        return m_Loaders[LOADER_CSB]->hasRes(resName)
            || m_Loaders[LOADER_ARMATURE]->hasRes(resName);
    }
    // 音乐
    else if (suffix == ".bank")
    {
        return m_Loaders[LOADER_MUSIC]->hasRes(resName);
    }
    // spine
    else if (suffix == ".json")
    {
        return m_Loaders[LOADER_SPINE]->hasRes(resName);
    }
    return false;
}

bool CResManager::hasArmature(const std::string& resName)
{
    return SafeDataReaderHelper::isArmatureLoaded(resName);
}

bool CResManager::init()
{
    m_Loaders[LOADER_CSB] = new CNewCsbLoader;
    m_Loaders[LOADER_SPINE] = new CSpineLoader;
    m_Loaders[LOADER_ARMATURE] = new CArmatureLoader;
    m_Loaders[LOADER_MUSIC] = new CMusicLoader;
    m_Loaders[LOADER_TEXTURE] = new CTextureLoader;
    return true;
}

std::string CResManager::getSuffix(const std::string &filename)
{
    std::size_t pos = filename.find_last_of(".");
    if (pos != std::string::npos)
    {
        std::string suffix = filename.substr(pos, filename.size());
        return suffix;
    }
    return "";
}

void CResManager::checkLoading(float dt)
{
    for (auto iter : m_Loaders)
    {
        if (iter.second->isLoading())
        {
            return;
        }
    }

    m_bIsLoading = false;
    Director::getInstance()->getScheduler()->unschedule(
        CC_SCHEDULE_SELECTOR(CResManager::checkLoading), this);

    end = utils::gettime();
    KXLOGDEBUG("CResManager::checkLoading start call m_FinishCallback");
    if (m_FinishCallback)
    {
        m_FinishCallback(m_nPreload, m_nLoaded);
        if (!m_bIsLoading)
        {
            m_FinishCallback = nullptr;
        }
    }
    KXLOGDEBUG("CResManager::checkLoading call m_FinishCallback over %f", end - begin);
}
