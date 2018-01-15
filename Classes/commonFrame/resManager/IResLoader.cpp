#include "IResLoader.h"

using namespace std;
USING_NS_CC;

IResLoader::IResLoader()
: m_bIsLoading(false)
, m_finishCallback(nullptr)
{
}


IResLoader::~IResLoader()
{
}

bool IResLoader::startLoadResAsyn()
{
    return !m_bIsLoading;
}

void IResLoader::clearRes()
{
    m_AutoLoadResCache.clear();
}

void IResLoader::loadResAsyn(const std::string& resName, const ResLoadedCallback& callback)
{
}

bool IResLoader::addPreloadRes(const std::string& resName, const ResLoadedCallback& callback)
{
    return false;
}

bool IResLoader::addPreloadRes(const std::string& resName, const std::string& assName, const ResLoadedCallback& callback)
{
    return false;
}

bool IResLoader::checkLoadRes(const std::string& resName, const std::string& assName, const ResLoadedCallback& callback)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    // 1.检查路径是否正确
    if (fullPath.empty())
    {
        CCLOG("IResLoader::addPreloadRes can't find file %s ", resName.c_str());
        return false;
    }

    // 2.检查是否已经加载了
    if (hasRes(fullPath))
    {
        if (callback != nullptr)
        {
            callback(fullPath, true);
        }
        return false;
    }

    // 3.检查是否正在加载中
    if (m_bIsLoading)
    {
        PreLoadResInfo info;
        info.ResName = resName;
        info.AssName = assName;
        info.Callback = callback;
        m_AutoLoadResCache.push_back(info);
        return false;
    }

    // 可以加载该资源
    return true;
}

void IResLoader::autoLoadRes()
{
    // 没有资源需要自动加载
    if (m_AutoLoadResCache.size() == 0)
    {
        return;
    }

    // 先复制一份，因为存在遍历中添加删除
    vector<PreLoadResInfo> AutoLoadResCache = m_AutoLoadResCache;
    m_AutoLoadResCache.clear();

    for (auto& resInfo : AutoLoadResCache)
    {
        // 是否已加载
        if (hasRes(resInfo.ResName))
        {
            resInfo.Callback(resInfo.ResName, true);
            continue;
        }

        if (resInfo.AssName.empty())
        {
            addPreloadRes(resInfo.ResName, resInfo.Callback);
        }
        else
        {
            addPreloadRes(resInfo.ResName, resInfo.AssName, resInfo.Callback);
        }
    }

    // 如果有要加载的，自动开始加载
    startLoadResAsyn();
}

std::string TextureTools::getTexturePathFromPlist(std::string plistPath)
{
    string texturePath("");

    std::string fullPath = FileUtils::getInstance()->fullPathForFilename(plistPath);
    if (fullPath.size() == 0)
    {
        return texturePath;
    }

    ValueMap dict = FileUtils::getInstance()->getValueMapFromFile(fullPath);

    if (dict.find("metadata") != dict.end())
    {
        ValueMap& metadataDict = dict["metadata"].asValueMap();
        // try to read  texture file name from meta data
        texturePath = metadataDict["textureFileName"].asString();
    }

    if (!texturePath.empty())
    {
        // build texture path relative to plist file
        texturePath = FileUtils::getInstance()->fullPathFromRelativeFile(texturePath, plistPath);
    }
    else
    {
        // build texture path by replacing file extension
        texturePath = plistPath;

        // remove .xxx
        size_t startPos = texturePath.find_last_of(".");
        texturePath = texturePath.erase(startPos);

        // append .png
        texturePath = texturePath.append(".png");
    }
    return texturePath;
}
