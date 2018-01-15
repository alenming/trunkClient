#include "CsbLoader_.h"
#include "cocostudio/ActionTimeline/CSLoader.h"
#include "CsbTool.h"

#include "base/ObjectFactory.h"

#include "../../cocos/ui/CocosGUI.h"
#include "cocostudio/CocoStudio.h"
#include "cocostudio/CSParseBinary_generated.h"

#include "cocostudio/WidgetReader/NodeReaderProtocol.h"
#include "cocostudio/WidgetReader/NodeReaderDefine.h"

#include "cocostudio/WidgetReader/NodeReader/NodeReader.h"
#include "cocostudio/WidgetReader/SingleNodeReader/SingleNodeReader.h"
#include "cocostudio/WidgetReader/SpriteReader/SpriteReader.h"
#include "cocostudio/WidgetReader/ParticleReader/ParticleReader.h"
#include "cocostudio/WidgetReader/GameMapReader/GameMapReader.h"
#include "cocostudio/WidgetReader/ProjectNodeReader/ProjectNodeReader.h"
#include "cocostudio/WidgetReader/ComAudioReader/ComAudioReader.h"

USING_NS_CC;
using namespace std;
using namespace flatbuffers;
using namespace cocostudio;
using namespace ui;

CDataObject::CDataObject()
{
}

CDataObject::~CDataObject()
{
}

void CDataObject::setData(cocos2d::Data data)
{
    m_Data = data;
}

Data& CDataObject::getData()
{
    return m_Data;
}

CsbObject::~CsbObject()
{
    for (auto iter : DataObjects)
    {
        iter->release();
    }
    DataObjects.clear();
    for (auto iter : Textures)
    {
        iter->release();
    }
    Textures.clear();
}

CNewCsbLoader::CNewCsbLoader()
: m_CurrentLoadedCount(0)
, m_TotalLoadingCount(0)
, m_bNeedQuit(false)
, m_LoadingThread(nullptr)
{
}

CNewCsbLoader::~CNewCsbLoader()
{
    waitForQuit();
    releaseAndClearMap(m_DataObjectPool);
    deleteAndClearMap(m_CsbObjectPool);
}

bool CNewCsbLoader::addPreloadRes(const std::string& csbFile, const ResLoadedCallback& callBack)
{
	//CCLOG("add csb res %s", csbFile.c_str());
    if (!checkLoadRes(csbFile, "", callBack))
    {
        return false;
    }

    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    LoadingCsbObject *pLoadingCsb = new LoadingCsbObject(fullPath, callBack);
    m_RequestMutex.lock();
    m_RequestQueue.push_back(pLoadingCsb);
    m_RequestMutex.unlock();
    ++m_TotalLoadingCount;
    LOGDEBUG("performance: CNewCsbLoader Load %s", csbFile.c_str());
    return true;
}

bool CNewCsbLoader::startLoadResAsyn()
{
    if (m_TotalLoadingCount <= 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    // 初始化CSLoader
    CSLoader::getInstance();

    m_bIsLoading = true;
    m_bNeedQuit = false;
    m_CurrentLoadedCount = 0;

    // 开启线程
    if (nullptr == m_LoadingThread)
    {
        m_LoadingThread = new std::thread(&CNewCsbLoader::loadCsb, this);
    }

    // 当CSB检查完毕后在主线程中加载图片
    Director::getInstance()->getScheduler()->schedule(
        CC_SCHEDULE_SELECTOR(CNewCsbLoader::addImageAsyncCallBack), this, 0, false);

    return true;
}

bool CNewCsbLoader::hasRes(const std::string& resName)
{
    return m_CsbObjectPool.find(resName) != m_CsbObjectPool.end();
}

void CNewCsbLoader::removeRes(const std::string& csbFile)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    auto iter = m_CsbObjectPool.find(fullPath);
    if (iter == m_CsbObjectPool.end())
    {
        return;
    }

    LOGDEBUG("performance: CNewCsbLoader unload %s", fullPath.c_str());

    // 释放CsbObject
    delete iter->second;
    m_CsbObjectPool.erase(iter);

    // 锁住对m_DataObjectPool的操作
    m_DataObjectMutex.lock();
    auto itDataPool = m_DataObjectPool.find(fullPath);
    if (itDataPool != m_DataObjectPool.end())
    {
        if (itDataPool->second->getReferenceCount() <= 1)
        {
            itDataPool->second->release();
            m_DataObjectPool.erase(itDataPool);
        }
    }
    m_DataObjectMutex.unlock();
}

void CNewCsbLoader::cacheRes(const std::string& resName)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    if (m_CacheRes.find(fullPath) == m_CacheRes.end())
    {
        m_CacheRes.insert(fullPath);
    }
}

void CNewCsbLoader::clearRes()
{
    IResLoader::clearRes();
    // 先停止加载
    if (m_bIsLoading)
    {
        // 因为是强制中断，所以需要清空回调
        m_finishCallback = nullptr;
        onLoadFinish();
    }

    // 如果存在异步加载纹理中的CSB对象，那就让它加载吧...
    // 但需要清除其回调函数，否则可能调用到
    for (auto iter : m_LoadingTextureCsb)
    {
        iter->Callback = nullptr;
    }

    for (auto iter = m_CsbObjectPool.begin();iter != m_CsbObjectPool.end();)
    {
        auto cacheIter = m_CacheRes.find(iter->first);
        if (cacheIter == m_CacheRes.end())
        {
            LOGDEBUG("performance: CNewCsbLoader unload %s", iter->first.c_str());
            // 锁住对m_DataObjectPool的操作
            m_DataObjectMutex.lock();
            auto itDataPool = m_DataObjectPool.find(iter->first);
            if (itDataPool != m_DataObjectPool.end())
            {
                if (itDataPool->second->getReferenceCount() <= 1)
                {
                    itDataPool->second->release();
                    m_DataObjectPool.erase(itDataPool);
                }
            }
            m_DataObjectMutex.unlock();

            delete iter->second;
            m_CsbObjectPool.erase(iter++);
        }
        else
        {
            ++iter;
        }
    }

    m_DataObjectMutex.lock();
    for (auto itDataPool = m_DataObjectPool.begin();
        itDataPool != m_DataObjectPool.end(); )
    {
        if (itDataPool->second->getReferenceCount() <= 1)
        {
            itDataPool->second->release();
            m_DataObjectPool.erase(itDataPool++);
        }
        else
        {
            ++itDataPool;
        }
    }
    m_DataObjectMutex.unlock();

    timeline::ActionTimelineCache::getInstance()->purge();
    m_CacheRes.clear();
}

void CNewCsbLoader::waitForQuit()
{
    m_bNeedQuit = true;
    if (m_LoadingThread)
    {
        m_LoadingThread->join();
        delete m_LoadingThread;
        m_LoadingThread = nullptr;
    }
    // 前面已经把线程干掉了...所以这里不用担心线程安全
    deleteAndClearDeque(m_RequestQueue);
    for (auto request : m_ResponseQueue)
    {
        if (request->MainCsbObject)
        {
            delete (request->MainCsbObject);
        }
        request->release();
    }
    m_ResponseQueue.clear();

}

Node* CNewCsbLoader::createCsbNode(const std::string& csbFile)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    CDataObject* dataObj = getDataForCsbFile(fullPath);
    if (dataObj != nullptr)
    {
        auto csparsebinary = GetCSParseBinary(dataObj->getData().getBytes());
        auto textures = csparsebinary->textures();
        int textureSize = csparsebinary->textures()->size();
        for (int i = 0; i < textureSize; ++i)
        {
            SpriteFrameCache::getInstance()->addSpriteFramesWithFile(textures->Get(i)->c_str());
        }

        //CCLOG("CSB %s CREATE START ==================================", csbFile.c_str());
        auto nodetree = csparsebinary->nodeTree();
        auto csbNode = nodeWithFlatBuffers(nodetree);
        //CCLOG("CSB %s CREATE END ==================================", csbFile.c_str());
        if (csbNode)
        {
            size_t pos1 = csbFile.find_last_of("/") + 1;
            size_t pos2 = csbFile.find_last_of(".");
            csbNode->setName(csbFile.substr(pos1, pos2 - pos1));

            // 执行Action
            auto act = cocostudio::timeline::ActionTimelineCache::getInstance(
                )->createActionWithDataBuffer(dataObj->getData(), csbFile);
            if (act)
            {
                csbNode->runAction(act);
                act->gotoFrameAndPause(0);
            }
        }
        else
        {
            CCLOG("create Csb Node %s Faile", csbFile.c_str());
        }
        return csbNode;
    }

    CCLOG("getDataForCsbFile %s Faile", fullPath.c_str());
    return nullptr;
}

void CNewCsbLoader::loadCsb()
{
    LoadingCsbObject* pLoadingCsb = nullptr;
    //std::mutex signalMutex;
    //std::unique_lock<std::mutex> signal(signalMutex);

    while (!m_bNeedQuit)
    {
        // 获取需要加载的csb信息
        m_RequestMutex.lock();
        if (m_RequestQueue.empty())
        {
            pLoadingCsb = nullptr;
        }
        else
        {
            pLoadingCsb = m_RequestQueue.front();
            m_RequestQueue.pop_front();
        }
        m_RequestMutex.unlock();
        // 如果获取不到，就等等
        if (nullptr == pLoadingCsb)
        {
            break;
        }

        CDataObject* mainData = getDataForCsbFile(pLoadingCsb->CsbFilePath);
        if (mainData != nullptr)
        {
            // 添加引用
            pLoadingCsb->MainCsbObject = new CsbObject();
            if (pLoadingCsb->MainCsbObject->DataObjects.find(mainData)
                == pLoadingCsb->MainCsbObject->DataObjects.end())
            {
                mainData->retain();
                pLoadingCsb->MainCsbObject->DataObjects.insert(mainData);
            }

            // 自动加载csb以及嵌套的子csb，并搜索其所需的所有纹理
            // 先搜索该Csb所需的图片资源
            searchTexturesByCsbFile(mainData->getData(), pLoadingCsb->TextureFiles);
            auto csparsebinary = GetCSParseBinary(mainData->getData().getBytes());
            // 再对该Csb下所有的子节点进行递归，查找嵌套的Csb，并搜索嵌套Csb的资源
            searchTexturesByCsbNodeTree(csparsebinary->nodeTree(),
                pLoadingCsb->TextureFiles, pLoadingCsb->MainCsbObject->DataObjects);
        }

        m_ResponseMutex.lock();
        m_ResponseQueue.push_back(pLoadingCsb);
        m_ResponseMutex.unlock();
    }
}

// 查找单个Csb所引用的所有PNG
void CNewCsbLoader::searchTexturesByCsbFile(const Data& data, set<string>& texSet)
{
    auto csparsebinary = GetCSParseBinary(data.getBytes());
    auto textures = csparsebinary->textures();
    int textureSize = csparsebinary->textures()->size();
    for (int i = 0; i < textureSize; ++i)
    {
        string plistFile = FileUtils::getInstance()->fullPathForFilename(textures->Get(i)->c_str());
        string texFile = getTextFromPlist(plistFile);
        if (!texFile.empty())
        {
            texSet.insert(texFile);
        }
    }
}

void CNewCsbLoader::searchTexturesByCsbNodeTree(const flatbuffers::NodeTree* tree, set<string>& texSet, std::set<CDataObject*>& objects)
{
    // 对所有的子节点做相同的处理
    auto children = tree->children();
    int size = children->size();
    for (int i = 0; i < size; ++i)
    {
        auto subNodeTree = children->Get(i);
        // 对于CsbNode子节点，需要一并加载进来
        auto options = subNodeTree->options();
        std::string classname = subNodeTree->classname()->c_str();
        if (classname == "ProjectNode")
        {
            auto projectNodeOptions = (ProjectNodeOptions*)options->data();
            std::string filePath = FileUtils::getInstance()->fullPathForFilename(
                projectNodeOptions->fileName()->c_str());

            // 有此文件，且未加载过该文件
            // 如果已经搜索过，则没必要再搜索
            if (!filePath.empty())
            {
                auto dataObj = getDataForCsbFile(filePath);
                if (dataObj != nullptr)
                {
                    // 添加引用
                    if (objects.find(dataObj) == objects.end())
                    {
                        dataObj->retain();
                        objects.insert(dataObj);
                    }

                    // 找到这个Csb所引用的Png
                    searchTexturesByCsbFile(dataObj->getData(), texSet);
                    auto csparsebinary = GetCSParseBinary(dataObj->getData().getBytes());
                    // 对该Csb进行递归
                    searchTexturesByCsbNodeTree(csparsebinary->nodeTree(), texSet, objects);
                }
            }
        }
        else
        {
            searchTexturesByCsbNodeTree(subNodeTree, texSet, objects);
        }
    }
}

CDataObject* CNewCsbLoader::getDataForCsbFile(const std::string& csbFile)
{
    CDataObject* ret = nullptr;

    m_DataObjectMutex.lock();
    auto it = m_DataObjectPool.find(csbFile);
    if (it != m_DataObjectPool.end())
    {
        ret = it->second;
    }
    m_DataObjectMutex.unlock();

    if (ret == nullptr)
    {
        auto buf = FileUtils::getInstance()->getDataFromFile(csbFile);
        if (!buf.isNull())
        {
            ret = new CDataObject();
            ret->setData(buf);
            m_DataObjectMutex.lock();
            m_DataObjectPool[csbFile] = ret;
            m_DataObjectMutex.unlock();
        }
    }

    return ret;
}

const std::string& CNewCsbLoader::getTextFromPlist(const std::string& plist)
{
    auto iter = m_PlistTextMap.find(plist);
    if (iter != m_PlistTextMap.end())
    {
        return iter->second;
    }

    Data plistData = FileUtils::getInstance()->getDataFromFile(plist);
    if (plistData.isNull())
    {
        m_PlistTextMap[plist] = "";
    }
    else
    {
        string textureFile;
        ValueMap dict = FileUtils::getInstance()->getValueMapFromData(
            reinterpret_cast<const char*>(plistData.getBytes()), plistData.getSize());

        if (dict.find("metadata") != dict.end())
        {
            ValueMap& metadataDict = dict["metadata"].asValueMap();
            textureFile = metadataDict["textureFileName"].asString();
        }

        if (!textureFile.empty())
        {
            // 计算相对路径，将纹理的文件名对应到plist的路径下
            textureFile = FileUtils::getInstance()->fullPathFromRelativeFile(textureFile, plist);
        }
        else
        {
            // 如果plist文件中没有纹理路径名，则尝试读取plist对应的.png
            textureFile = plist;
            // 将xxxx.plist结尾的.plist移除，替换成.png
            textureFile = textureFile.erase(textureFile.find_last_of("."));
            textureFile = textureFile.append(".png");
        }
        m_PlistTextMap[plist] = textureFile;
    }
    return m_PlistTextMap[plist];
}

void CNewCsbLoader::onLoadFinish()
{
    waitForQuit();

    Director::getInstance()->getScheduler()->unschedule(
        CC_SCHEDULE_SELECTOR(CNewCsbLoader::addImageAsyncCallBack), this);

    LOGDEBUG("performance: CNewCsbLoader onLoadFinish %d", utils::getTimeInMilliseconds());
    if (m_finishCallback)
    {
        m_finishCallback(m_CurrentLoadedCount, m_TotalLoadingCount);
    }

    m_bIsLoading = false;
    m_CurrentLoadedCount = 0;
    m_TotalLoadingCount = 0;
    autoLoadRes();
}

void CNewCsbLoader::addImageAsyncCallBack(float dt)
{
    while (true)
    {
        size_t sz = m_ResponseQueue.size();
        LoadingCsbObject* pLoadingCsb = nullptr;
        // 1. 获取解析好的Csb加载信息对象
        m_ResponseMutex.lock();
        if (m_ResponseQueue.empty())
        {
            pLoadingCsb = nullptr;
        }
        else
        {
            pLoadingCsb = m_ResponseQueue.front();
            m_ResponseQueue.pop_front();
        }
        m_ResponseMutex.unlock();
        if (nullptr == pLoadingCsb)
        {
            break;
        }

        // 2. 开始加载Csb所需的纹理对象
        // 加载失败
        bool success = false;
        if (pLoadingCsb->MainCsbObject != nullptr)
        {
            // 加载成功，如果没有纹理需要加载，则直接完成，否则开始加载纹理
            if (pLoadingCsb->TextureFiles.size() > 0)
            {
                pLoadingCsb->retain();
                m_LoadingTextureCsb.insert(pLoadingCsb);
                auto itPngFile = pLoadingCsb->TextureFiles.begin();
                for (; itPngFile != pLoadingCsb->TextureFiles.end(); ++itPngFile)
                {
                    string textureFile = *itPngFile;
                    KXLOGDEBUG("csblink %s -- %s", pLoadingCsb->CsbFilePath.c_str(), textureFile.c_str());
                    Director::getInstance()->getTextureCache()->addImageAsync(*itPngFile,
                        [this, textureFile, pLoadingCsb](Texture2D* tex)->void
                    {
                        if (tex == nullptr)
                        {
                            pLoadingCsb->FaileCount++;
                            CCLOG("CsbLoader Load Texture %s Faile", textureFile.c_str());
                        }
                        else
                        {
                            pLoadingCsb->SuccessCount++;
                            // 引用，保证不被释放
                            pLoadingCsb->MainCsbObject->Textures.insert(tex);
                            tex->retain();
                        }

                        // 所有的纹理都加载完成
                        if (pLoadingCsb->SuccessCount + pLoadingCsb->FaileCount >= 
                            static_cast<int>(pLoadingCsb->TextureFiles.size()))
                        {
                            onCsbLoadFinish(pLoadingCsb, pLoadingCsb->FaileCount == 0);
                            m_LoadingTextureCsb.erase(pLoadingCsb);
                        }
                    });
                }
                pLoadingCsb->release();
                // 还需要加载，就先跳过
                continue;
            }
            else
            {
                success = true;
            }
        }

        // 3. 在加载完所需纹理后执行回调，并添加到m_CsbObjectPool中
        onCsbLoadFinish(pLoadingCsb, success);
    }
}

void CNewCsbLoader::onCsbLoadFinish(LoadingCsbObject* loadingCsb, bool success)
{
    if (success)
    {
        m_CsbObjectPool[loadingCsb->CsbFilePath] = loadingCsb->MainCsbObject;
    }
    else if (loadingCsb->MainCsbObject != nullptr)
    {
        delete loadingCsb->MainCsbObject;
        loadingCsb->MainCsbObject = nullptr;
    }

    if (loadingCsb->Callback != nullptr)
    {
        loadingCsb->Callback(loadingCsb->CsbFilePath, success);
    }

    loadingCsb->release();
    ++m_CurrentLoadedCount;
    if (m_CurrentLoadedCount == m_TotalLoadingCount)
    {
        onLoadFinish();
    }
}

// 这里只能在主线程中调用，如果创建了一个未经过预加载的csb
// 则自动缓存其Data对象用于加速创建（但并不为其生成CsbObject对象）
cocos2d::Node* CNewCsbLoader::nodeWithFlatBuffers(const flatbuffers::NodeTree *nodetree)
{
    Node* node = nullptr;

    std::string classname = nodetree->classname()->c_str();
    auto options = nodetree->options();

    if (classname == "ProjectNode")
    {
        auto reader = ProjectNodeReader::getInstance();
        auto projectNodeOptions = (ProjectNodeOptions*)options->data();
        std::string filePath = FileUtils::getInstance()->fullPathForFilename(
            projectNodeOptions->fileName()->c_str());
        cocostudio::timeline::ActionTimeline* action = nullptr;

        if (filePath != "" && FileUtils::getInstance()->isFileExist(filePath))
        {
            // 从Cache中获取不到则自动创建并Cache
            CDataObject* dataObj = getDataForCsbFile(filePath);
            if (dataObj != nullptr)
            {
                auto csparsebinary = GetCSParseBinary(dataObj->getData().getBytes());
                auto textures = csparsebinary->textures();
                int textureSize = csparsebinary->textures()->size();
                for (int i = 0; i < textureSize; ++i)
                {
                    SpriteFrameCache::getInstance()->addSpriteFramesWithFile(textures->Get(i)->c_str());
                }
                auto nodetree = csparsebinary->nodeTree();
                node = nodeWithFlatBuffers(nodetree);
                if (node == nullptr)
                {
                    return nullptr;
                }
                action = cocostudio::timeline::ActionTimelineCache::getInstance(
                    )->createActionWithDataBuffer(dataObj->getData(), filePath);
            }
            else
            {
                node = Node::create();
            }
        }
        else
        {
            node = Node::create();
        }
        reader->setPropsWithFlatBuffers(node, options->data());
        if (action)
        {
            action->setTimeSpeed(projectNodeOptions->innerActionSpeed());
            node->runAction(action);
            action->gotoFrameAndPause(0);
        }
    }
    else if (classname == "SimpleAudio")
    {
        node = Node::create();
        auto reader = ComAudioReader::getInstance();
        Component* component = reader->createComAudioWithFlatBuffers(options->data());
        if (component)
        {
            node->addComponent(component);
            reader->setPropsWithFlatBuffers(node, options->data());
        }
    }
    else
    {
        std::string customClassName = nodetree->customClassName()->c_str();
        if (customClassName != "")
        {
            classname = customClassName;
        }
        std::string readername = getGUIClassName(classname);
        readername.append("Reader");
        NodeReaderProtocol* reader = dynamic_cast<NodeReaderProtocol*>(
            ObjectFactory::getInstance()->createObject(readername));
        if (reader)
        {
            node = reader->createNodeWithFlatBuffers(options->data());
        }
    }

    if (!node)
    {
        return nullptr;
    }

    auto children = nodetree->children();
    int size = children->size();
    for (int i = 0; i < size; ++i)
    {
        auto subNodeTree = children->Get(i);
        Node* child = nodeWithFlatBuffers(subNodeTree);
        if (child)
        {
            PageView* pageView = dynamic_cast<PageView*>(node);
            ListView* listView = dynamic_cast<ListView*>(node);
            if (pageView)
            {
                Layout* layout = dynamic_cast<Layout*>(child);
                if (layout)
                {
                    pageView->addPage(layout);
                }
            }
            else if (listView)
            {
                Widget* widget = dynamic_cast<Widget*>(child);
                if (widget)
                {
                    listView->pushBackCustomItem(widget);
                }
            }
            else
            {
                node->addChild(child, i);
            }
        }
    }
    return node;
}

string CNewCsbLoader::getGUIClassName(const std::string &name)
{
    std::string convertedClassName = name;
    if (name == "Panel")
    {
        convertedClassName = "Layout";
    }
    else if (name == "TextArea")
    {
        convertedClassName = "Text";
    }
    else if (name == "TextButton")
    {
        convertedClassName = "Button";
    }
    else if (name == "Label")
    {
        convertedClassName = "Text";
    }
    else if (name == "LabelAtlas")
    {
        convertedClassName = "TextAtlas";
    }
    else if (name == "LabelBMFont")
    {
        convertedClassName = "TextBMFont";
    }

    return convertedClassName;
}