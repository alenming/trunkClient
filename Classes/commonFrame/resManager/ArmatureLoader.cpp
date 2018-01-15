#include "ArmatureLoader.h"

USING_NS_CC;
using namespace cocostudio;
using namespace std;

CArmatureLoader::CArmatureLoader()
: m_bIsThreadWorking(false)
, m_nLoadingIndex(0)
, m_nArmatureIndex(0)
, m_nFinishIndex(0)
, m_ArmatureThread(nullptr)
{
}

CArmatureLoader::~CArmatureLoader()
{
    if (m_ArmatureThread)
    {
        m_bIsThreadWorking = false;
        m_ArmatureThread->join();
        delete m_ArmatureThread;
        m_ArmatureThread = nullptr;
    }
}

bool CArmatureLoader::addPreloadRes(const std::string& resName, const ResLoadedCallback& callback)
{
    if (!checkLoadRes(resName, "", callback))
    {
        return false;
    }

    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    ArmatureLoadingInfo info;
    int pos = fullPath.find_last_of('.');
    do 
    {
        if (pos != string::npos)
        {
            string fmt = fullPath.substr(pos, fullPath.length() - pos);
            if (fmt == ".csb")
            {
                info.FileType = ArmatureCsbType;
                break;
            }
            else if (fmt == ".json" || fmt == ".ExportJson")
            {
                info.FileType = ArmatureJsonType;
                break;
            }
        }
        CCLOG("CArmatureLoader::addPreloadRes %s file format error", resName.c_str());
        return false;
    } while (false);

    info.PlistLoadedCount = 0;
    info.Error = false;
    info.fullPathFile = fullPath;
    info.ResFile = resName;
    info.Callback = callback;
    m_LoadingInfos.push_back(info);
    return true;
}

bool CArmatureLoader::startLoadResAsyn()
{
    if (m_LoadingInfos.size() == 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    m_bIsLoading = true;
    m_bIsThreadWorking = true;
    m_nArmatureIndex = 0;
    m_nFinishIndex = 0;
    m_nLoadingIndex = 0;

    // 初始化每个文件的RelativeData
    for (auto& item : m_LoadingInfos)
    {
        SafeDataReaderHelper::saveFileInfo(item.ResFile);
        ArmatureDataManager::getInstance()->addArmatureFileInfo(item.ResFile);
    }

    if (m_ArmatureThread == nullptr)
    {
        m_ArmatureThread = new std::thread(&CArmatureLoader::armatureThread, this);
    }

    Director::getInstance()->getScheduler()->schedule(
        CC_SCHEDULE_SELECTOR(CArmatureLoader::onArmatureLoaded), this, 0, false);
    return true;
}

void CArmatureLoader::onArmatureLoaded(float dt)
{
    if (m_nArmatureIndex < m_nLoadingIndex)
    {
        ArmatureLoadingInfo& info = m_LoadingInfos[m_nArmatureIndex];
        // 将加载完成的骨骼对象添加到ArmatureDataManager中
        for (auto& item : info.ArmatureDatas)
        {
            ArmatureDataManager::getInstance()->addArmatureData(item->name, item, info.ResFile);
            CC_SAFE_RELEASE_NULL(item);
        }
        for (auto& item : info.AnimationDatas)
        {
            ArmatureDataManager::getInstance()->addAnimationData(item->name, item, info.ResFile);
            CC_SAFE_RELEASE_NULL(item);
        }
        for (auto& item : info.TextureDatas)
        {
            ArmatureDataManager::getInstance()->addTextureData(item->name, item, info.ResFile);
            CC_SAFE_RELEASE_NULL(item);
        }

        // 接下来应该addSpriteFrames，图片统统在Cocos2d-x的图片加载线程中处理
        for (auto& item : info.PlistPngMap)
        {
            string plist = item.first;
            string png = item.second;
            if (plist.empty() || png.empty())
            {
                ++info.PlistLoadedCount;
                continue;
            }
            // png必须是fullPath
            Director::getInstance()->getTextureCache()->addImageAsync(png,
                [this, &info, png, plist](Texture2D* tex)->void
            {
                if (nullptr != tex)
                {
                    ArmatureDataManager::getInstance()->addSpriteFrameFromFile(plist, png, info.ResFile);
                }
                ++info.PlistLoadedCount;
            });
        }
        ++m_nArmatureIndex;
    }

    if (m_nFinishIndex < static_cast<int>(m_LoadingInfos.size()))
    {
        ArmatureLoadingInfo& info = m_LoadingInfos[m_nFinishIndex];
        if (m_nFinishIndex < m_nArmatureIndex
            && info.PlistLoadedCount >= static_cast<int>(info.PlistPngMap.size()))
        {
			CCLOG("CArmatureLoader::onArmatureLoaded %s", info.ResFile.c_str());
            if (info.Callback != nullptr)
            {
                info.Callback(info.ResFile, !info.Error);
            }
            ++m_nFinishIndex;
            if (m_nFinishIndex >= static_cast<int>(m_LoadingInfos.size()))
            {
                onFinish();
            }
        }
    }
}

bool CArmatureLoader::hasRes(const std::string& resName)
{ 
    return SafeDataReaderHelper::isArmatureLoaded(resName); 
}

void CArmatureLoader::removeRes(const std::string& resName)
{
    CCLOG("CArmatureLoader remove %s", resName.c_str());
    ArmatureDataManager::getInstance()->removeArmatureFileInfo(resName);
}

void CArmatureLoader::cacheRes(const std::string& resName)
{
    // cache的是resFile，未经过fullpath的
    m_ArmatureCache.insert(resName);
}

void CArmatureLoader::clearRes()
{
    IResLoader::clearRes();
    if (m_bIsLoading)
    {
        // 因为是强制中断，所以需要清空回调
        m_finishCallback = nullptr;
        onFinish();
    }
    vector<string> armatureList = SafeDataReaderHelper::getArmatureList();
    for (auto& item : armatureList)
    {
        if (m_ArmatureCache.find(item) == m_ArmatureCache.end())
        {
            removeRes(item);
        }
    }
    m_ArmatureCache.clear();
}

void CArmatureLoader::armatureThread()
{
    while (m_bIsThreadWorking)
    {
        ArmatureLoadingInfo& info = m_LoadingInfos[m_nLoadingIndex];
        switch (info.FileType)
        {
        case ArmatureCsbType:
            SafeDataReaderHelper::loadCsbArmatureThreadSafe(info);
            break;
        case ArmatureJsonType:
            SafeDataReaderHelper::loadJsonArmatureThreadSafe(info);
            break;
        default:
            break;
        }
        ++m_nLoadingIndex;
        if (static_cast<unsigned int>(m_nLoadingIndex) >= m_LoadingInfos.size())
        {
            break;
        }
    }
}

void CArmatureLoader::onFinish()
{
    if (m_ArmatureThread)
    {
        m_bIsThreadWorking = false;
        m_ArmatureThread->join();
        delete m_ArmatureThread;
        m_ArmatureThread = nullptr;
    }

    Director::getInstance()->getScheduler()->unschedule(
        CC_SCHEDULE_SELECTOR(CArmatureLoader::onArmatureLoaded), this);

	CCLOG("CArmatureLoader::onFinish");

    if (m_finishCallback)
    {
        m_finishCallback(m_nFinishIndex, m_LoadingInfos.size());
    }

    m_nArmatureIndex = 0;
    m_nFinishIndex = 0;
    m_nLoadingIndex = 0;

    m_bIsLoading = false;
    m_LoadingInfos.clear();
    autoLoadRes();
}

//////////////////////////////////////////////////////////////////////////
/*
    SafeDataReaderHelper 的实现，基于Cocos2d-x的DataReaderHelper
*/
//////////////////////////////////////////////////////////////////////////

static const char *VERSION = "version";
static const float VERSION_2_0 = 2.0f;

static const char *ARMATURES = "armatures";
static const char *ARMATURE = "armature";
static const char *BONE = "b";
static const char *DISPLAY = "d";

static const char *ANIMATIONS = "animations";
static const char *ANIMATION = "animation";
static const char *MOVEMENT = "mov";
static const char *FRAME = "f";

static const char *TEXTURE_ATLAS = "TextureAtlas";
static const char *SUB_TEXTURE = "SubTexture";

static const char *A_NAME = "name";
static const char *A_DURATION = "dr";
static const char *A_FRAME_INDEX = "fi";
static const char *A_DURATION_TO = "to";
static const char *A_DURATION_TWEEN = "drTW";
static const char *A_LOOP = "lp";
static const char *A_MOVEMENT_SCALE = "sc";
static const char *A_MOVEMENT_DELAY = "dl";
static const char *A_DISPLAY_INDEX = "dI";

static const char *A_PLIST = "plist";

static const char *A_PARENT = "parent";
static const char *A_SKEW_X = "kX";
static const char *A_SKEW_Y = "kY";
static const char *A_SCALE_X = "cX";
static const char *A_SCALE_Y = "cY";
static const char *A_Z = "z";
static const char *A_EVENT = "evt";
static const char *A_SOUND = "sd";
static const char *A_SOUND_EFFECT = "sdE";
static const char *A_TWEEN_EASING = "twE";
static const char *A_EASING_PARAM = "twEP";
static const char *A_TWEEN_ROTATE = "twR";
static const char *A_IS_ARMATURE = "isArmature";
static const char *A_DISPLAY_TYPE = "displayType";
static const char *A_MOVEMENT = "mov";

static const char *A_X = "x";
static const char *A_Y = "y";

static const char *A_COCOS2DX_X = "cocos2d_x";
static const char *A_COCOS2DX_Y = "cocos2d_y";

static const char *A_WIDTH = "width";
static const char *A_HEIGHT = "height";
static const char *A_PIVOT_X = "pX";
static const char *A_PIVOT_Y = "pY";

static const char *A_COCOS2D_PIVOT_X = "cocos2d_pX";
static const char *A_COCOS2D_PIVOT_Y = "cocos2d_pY";

static const char *A_BLEND_TYPE = "bd";
static const char *A_BLEND_SRC = "bd_src";
static const char *A_BLEND_DST = "bd_dst";

static const char *A_ALPHA = "a";
static const char *A_RED = "r";
static const char *A_GREEN = "g";
static const char *A_BLUE = "b";
static const char *A_ALPHA_OFFSET = "aM";
static const char *A_RED_OFFSET = "rM";
static const char *A_GREEN_OFFSET = "gM";
static const char *A_BLUE_OFFSET = "bM";
static const char *A_COLOR_TRANSFORM = "colorTransform";
static const char *A_TWEEN_FRAME = "tweenFrame";

static const char *CONTOUR = "con";
static const char *CONTOUR_VERTEX = "con_vt";

static const char *FL_NAN = "NaN";

static const char *FRAME_DATA = "frame_data";
static const char *MOVEMENT_BONE_DATA = "mov_bone_data";
static const char *MOVEMENT_DATA = "mov_data";
static const char *ANIMATION_DATA = "animation_data";
static const char *DISPLAY_DATA = "display_data";
static const char *SKIN_DATA = "skin_data";
static const char *BONE_DATA = "bone_data";
static const char *ARMATURE_DATA = "armature_data";
static const char *CONTOUR_DATA = "contour_data";
static const char *TEXTURE_DATA = "texture_data";
static const char *VERTEX_POINT = "vertex";
static const char *COLOR_INFO = "color";

static const char *CONFIG_FILE_PATH = "config_file_path";
static const char *CONTENT_SCALE = "content_scale";

std::vector<std::string> SafeDataReaderHelper::getArmatureList()
{
    return _configFileList;
}

bool SafeDataReaderHelper::isArmatureLoaded(const std::string& configFile)
{
    for (auto& item : _configFileList)
    {
        if (item == configFile)
        {
            return true;
        }
    }
    return false;
}

void SafeDataReaderHelper::saveFileInfo(const std::string& configFile)
{
    _configFileList.push_back(configFile);
}

void SafeDataReaderHelper::loadCsbArmatureThreadSafe(ArmatureLoadingInfo& info)
{
    // 1.读文件、初始化DataInfo
    Data data = FileUtils::getInstance()->getDataFromFile(info.fullPathFile);
    DataInfo *dataInfo = new DataInfo();
    dataInfo->asyncStruct = nullptr;
    size_t pos = info.fullPathFile.find_last_of("/");
    if (pos != std::string::npos)
    {
        dataInfo->baseFilePath = info.fullPathFile.substr(0, pos + 1);
    }
    else
    {
        info.Error = true;
        delete dataInfo;
        return;
    }
    
    // 2.解析，创建骨骼结构，并添加到info中
    CocoLoader tCocoLoader;
    if (tCocoLoader.ReadCocoBinBuff(reinterpret_cast<char*>(data.getBytes())))
    {
        stExpCocoNode *tpRootCocoNode = tCocoLoader.GetRootCocoNode();
        rapidjson::Type tType = tpRootCocoNode->GetType(&tCocoLoader);
        if (rapidjson::kObjectType == tType)
        {
            stExpCocoNode *tpChildArray = tpRootCocoNode->GetChildArray(&tCocoLoader);
            int nCount = tpRootCocoNode->GetChildNum();

            dataInfo->contentScale = 1.0f;
            int length = 0;
            std::string key;
            stExpCocoNode* pDataArray;
            for (int i = 0; i < nCount; ++i)
            {
                key = tpChildArray[i].GetName(&tCocoLoader);
                if (key.compare(CONTENT_SCALE) == 0)
                {
                    std::string value = tpChildArray[i].GetValue(&tCocoLoader);
                    dataInfo->contentScale = utils::atof(value.c_str());
                }
                else if (0 == key.compare(ARMATURE_DATA))
                {
                    pDataArray = tpChildArray[i].GetChildArray(&tCocoLoader);
                    length = tpChildArray[i].GetChildNum();
                    for (int ii = 0; ii < length; ++ii)
                    {
                        info.ArmatureDatas.push_back(decodeArmature(&tCocoLoader, &pDataArray[ii], dataInfo));
                    }
                }
                else if (0 == key.compare(ANIMATION_DATA))
                {
                    pDataArray = tpChildArray[i].GetChildArray(&tCocoLoader);
                    length = tpChildArray[i].GetChildNum();
                    for (int ii = 0; ii < length; ++ii)
                    {
                        info.AnimationDatas.push_back(decodeAnimation(&tCocoLoader, &pDataArray[ii], dataInfo));
                    }
                }
                else if (key.compare(TEXTURE_DATA) == 0)
                {
                    pDataArray = tpChildArray[i].GetChildArray(&tCocoLoader);
                    length = tpChildArray[i].GetChildNum();
                    for (int ii = 0; ii < length; ++ii)
                    {
                        info.TextureDatas.push_back(decodeTexture(&tCocoLoader, &pDataArray[ii]));
                    }
                }
            }

            // 添加要加载的Plist列表
            for (int i = 0; i < nCount; ++i)
            {
                key = tpChildArray[i].GetName(&tCocoLoader);
                if (0 != key.compare(CONFIG_FILE_PATH))
                {
                    continue;
                }
                length = tpChildArray[i].GetChildNum();
                stExpCocoNode *pConfigFilePath = tpChildArray[i].GetChildArray(&tCocoLoader);
                for (int ii = 0; ii < length; ii++)
                {
                    const char *path = pConfigFilePath[ii].GetValue(&tCocoLoader);
                    if (path == nullptr)
                    {
                        CCLOG("load CONFIG_FILE_PATH error.");
                        delete dataInfo;
                        return;
                    }

                    std::string filePath = path;
                    filePath = filePath.erase(filePath.find_last_of("."));
                    std::string plistPath = dataInfo->baseFilePath + filePath + ".plist";
                    std::string pngPath = TextureTools::getTexturePathFromPlist(plistPath);
                    info.PlistPngMap[plistPath] = pngPath;
                }
            }
        }
    }
    delete dataInfo;
}



void SafeDataReaderHelper::loadJsonArmatureThreadSafe(ArmatureLoadingInfo& info)
{
    // 1.读文件、初始化DataInfo
    string fileContent = FileUtils::getInstance()->getStringFromFile(info.fullPathFile);
    DataInfo *dataInfo = new DataInfo();
    dataInfo->asyncStruct = nullptr;
    size_t pos = info.fullPathFile.find_last_of("/");
    if (pos != std::string::npos)
    {
        dataInfo->baseFilePath = info.fullPathFile.substr(0, pos + 1);
    }
    else
    {
        info.Error = true;
        delete dataInfo;
        //CCLOG("loadJsonArmatureThreadSafe Error: %s", info.fullPathFile);
        return;
    }

    rapidjson::Document json;
    rapidjson::StringStream stream(fileContent.c_str());

    if (fileContent.size() >= 3) {
        // Skip BOM if exists
        const unsigned char* c = (const unsigned char *)fileContent.c_str();
        unsigned bom = c[0] | (c[1] << 8) | (c[2] << 16);

        if (bom == 0xBFBBEF)  // UTF8 BOM
        {
            stream.Take();
            stream.Take();
            stream.Take();
        }
    }

    json.ParseStream<0>(stream);
    if (json.HasParseError()) {
        CCLOG("GetParseError %d\n", json.GetParseError());
    }

    dataInfo->contentScale = DICTOOL->getFloatValue_json(json, CONTENT_SCALE, 1.0f);

    // Decode armatures
    int length = DICTOOL->getArrayCount_json(json, ARMATURE_DATA);
    for (int i = 0; i < length; i++)
    {
        const rapidjson::Value &armatureDic = DICTOOL->getSubDictionary_json(json, ARMATURE_DATA, i);
        info.ArmatureDatas.push_back(decodeArmature(armatureDic, dataInfo));
    }

    // Decode animations
    length = DICTOOL->getArrayCount_json(json, ANIMATION_DATA);
    for (int i = 0; i < length; i++)
    {
        const rapidjson::Value &animationDic = DICTOOL->getSubDictionary_json(json, ANIMATION_DATA, i);
        info.AnimationDatas.push_back(decodeAnimation(animationDic, dataInfo));
    }

    // Decode textures
    length = DICTOOL->getArrayCount_json(json, TEXTURE_DATA);
    for (int i = 0; i < length; i++)
    {
        const rapidjson::Value &textureDic = DICTOOL->getSubDictionary_json(json, TEXTURE_DATA, i);
        info.TextureDatas.push_back(decodeTexture(textureDic));
    }

    length = DICTOOL->getArrayCount_json(json, CONFIG_FILE_PATH);
    for (int i = 0; i < length; i++)
    {
        const char *path = DICTOOL->getStringValueFromArray_json(json, CONFIG_FILE_PATH, i);
        if (path == nullptr)
        {
            CCLOG("load CONFIG_FILE_PATH error.");
            delete dataInfo;
            return;
        }

        std::string filePath = path;
        filePath = filePath.erase(filePath.find_last_of("."));
        std::string plistPath = dataInfo->baseFilePath + filePath + ".plist";
        std::string pngPath = TextureTools::getTexturePathFromPlist(plistPath);
        info.PlistPngMap[plistPath] = pngPath;
    }

    delete dataInfo;
}
