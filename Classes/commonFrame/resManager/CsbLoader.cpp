#include "CsbLoader.h"
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

CCsbLoader::CCsbLoader()
: m_CurrentLoadedCount(0)
, m_bIsAutoSerachSubCsb(true)
{
}


CCsbLoader::~CCsbLoader()
{
    m_finishCallback = nullptr;
    onLoadFinish();

    for (auto& item : m_CsbNodes)
    {
        item.second->cleanup();
        item.second->release();
    }
    m_CsbNodes.clear();
}

bool CCsbLoader::addPreloadRes(const std::string& csbFile, const ResLoadedCallback& callBack)
{
	//CCLOG("add csb res %s", csbFile.c_str());
    if (!checkLoadRes(csbFile, "", callBack))
    {
        return false;
    }

    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    m_LoadingQueue.push_back(CsbLoadingInfo());
    CsbLoadingInfo& item = m_LoadingQueue[m_LoadingQueue.size() - 1];
    item.CsbFilePath = fullPath;
    item.Callback = callBack;
    item.LoadedCount = 0;

    // 就算所有的图片资源都已被加载，这里也需要将Csb节点加载
    // 如果这个Csb已经被检查过，则不用再检查了
    if (m_CheckedCsb.find(fullPath) == m_CheckedCsb.end())
    {
        m_CheckedCsb.insert(fullPath);
        Data data = FileUtils::getInstance()->getDataFromFile(fullPath);
        if (!data.isNull())
        {
            m_CsbFileCache[fullPath] = data;
            // 先搜索该Csb所需的图片资源
            searchTexturesByCsbFile(data, item.PreloadTextures);
            if (m_bIsAutoSerachSubCsb)
            {
                auto csparsebinary = GetCSParseBinary(data.getBytes());
                // 再对该Csb下所有的子节点进行递归，查找嵌套的Csb，并搜索嵌套Csb的资源
                searchTexturesByCsbNodeTree(csparsebinary->nodeTree(), item.PreloadTextures);
            }
        }
        else
        {
            CCLOG("no such file %s", fullPath.c_str());
        }
    }
    //CCLOG("SUCCESS 1");
    return true;
}

bool CCsbLoader::startLoadResAsyn()
{
    // 正在加载，请等加载完成
    // 没有东西可加载
    if (m_LoadingQueue.size() == 0 || !IResLoader::startLoadResAsyn())
    {
        return false;
    }

    IResLoader::startLoadResAsyn();
    CSLoader::getInstance();

    m_bIsLoading = true;
    m_CurrentLoadedCount = 0;

    // 对所有的纹理进行异步加载
    for (auto& item : m_LoadingQueue)
    {
        for (auto& texFile : item.PreloadTextures)
        {
            // 由于前面已经将所有的文件都执行了fullpathforfilename
            // 所以这里和createCsbNodeByLoadedTexture中的fullpathforfilename操作都是线程安全的
            Director::getInstance()->getTextureCache()->addImageAsync(texFile, [&item](Texture2D* tex)->void
            {
                // 这里不使用将PreloadTextures移除的原因是，该回调有可能被立即调用
                // 所以使用一个int来进行计数
                ++item.LoadedCount;
            });
        }
    }

    // 注册Schedule，用于检测纹理异步加载情况
    // 这里不使用addImageAsync的回调，因为addImageAsync可能被立即调用，而m_LoadingQueue有前向依赖性
    Director::getInstance()->getScheduler()->schedule(
        CC_SCHEDULE_SELECTOR(CCsbLoader::createCsbNodeByLoadedTexture), this, 0, false);
    return true;
}

void CCsbLoader::removeRes(const std::string& csbFile)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    if (m_bIsLoading)
    {
        CCLOG("thread is loading");
        return;
    }

    auto iter = m_CsbNodes.find(fullPath);
    if (iter == m_CsbNodes.end())
    {
        //CCLOG("can no find such csb node at cache %s", fullPath.c_str());
        return;
    }
    iter->second->cleanup();
    iter->second->release();
    m_CsbNodes.erase(iter);
}

void CCsbLoader::cacheRes(const std::string& resName)
{
	string fullPath = FileUtils::getInstance()->fullPathForFilename(resName);
    if (m_CacheRes.find(fullPath) == m_CacheRes.end() /*&&
        m_CsbNodes.find(fullPath) != m_CsbNodes.end()*/)
	{
		m_CacheRes.insert(fullPath);
	}
}

void CCsbLoader::clearRes()
{
	for (std::map<std::string, cocos2d::Node*>::iterator iter = m_CsbNodes.begin();
		iter != m_CsbNodes.end();)
	{
		auto cacheIter = m_CacheRes.find(iter->first);
		if (cacheIter == m_CacheRes.end())
		{
            Node* node = iter->second;
            if (node->getReferenceCount() > 1)
            {
                CCLOG("csb leak %s", iter->first.c_str());
            }
            node->cleanup();
            node->release();
            m_CsbNodes.erase(iter++);
		}
		else
		{
			++iter;
		}
	}
    timeline::ActionTimelineCache::getInstance()->purge();
    m_CacheRes.clear();
    m_AutoLoadResCache.clear();
    IResLoader::clearRes();
}

Node* CCsbLoader::getCsbNode(const std::string& csbFile)
{
    string fullPath = FileUtils::getInstance()->fullPathForFilename(csbFile);
    auto iter = m_CsbNodes.find(fullPath);
    if (iter == m_CsbNodes.end())
    {
        //CCLOG("can no find such csb node at cache %s", fullPath.c_str());
        return nullptr;
    }

    return iter->second;
}

void CCsbLoader::createCsbNodeByLoadedTexture(float dt)
{
    int count = 0;
    for (unsigned int i = m_CurrentLoadedCount; i < m_LoadingQueue.size(); ++i)
    {
        auto& item = m_LoadingQueue[i];
        if (static_cast<unsigned int>(item.LoadedCount) >= item.PreloadTextures.size()
            && count++ < 3)
        {
            // 如果该Csb所有资源准备就绪，则进行创建
            createCsbNode(item);
            ++m_CurrentLoadedCount;
        }
        else
        {
            break;
        }
    }

    // 结束加载
    if (static_cast<unsigned int>(m_CurrentLoadedCount) >= m_LoadingQueue.size())
    {
        onLoadFinish();
    }
}

void CCsbLoader::createCsbNode(const CsbLoadingInfo& csbInfo)
{
    // 1.Json可以走CSLoader，而Csb走自己的Loader，提高效率（暂不考虑json）
    // 2.纹理资源已经加载，这里允许存在一些阻塞
    // 3.在启动线程前，文件名都已经Cache，所以绕过了FileUtils的线程不安全部分
    //auto csbNode = CSLoader::getInstance()->createNode(csbInfo.CsbFilePath, nullptr);
    
    // 自定义的加载Csb节点
    auto iter = m_CsbFileCache.find(csbInfo.CsbFilePath);
    if (iter == m_CsbFileCache.end())
    {
        CCLOG("Csb %s Not Load", csbInfo.CsbFilePath.c_str());
        return;
    }

    Data buf = iter->second;
    string str = iter->first;
    m_CsbFileCache.erase(iter);
    auto csparsebinary = GetCSParseBinary(buf.getBytes());
    auto textures = csparsebinary->textures();
    int textureSize = csparsebinary->textures()->size();
    for (int i = 0; i < textureSize; ++i)
    {
        SpriteFrameCache::getInstance()->addSpriteFramesWithFile(textures->Get(i)->c_str());
    }

    //CCLOG("CSB %s CREATE START ==================================", str.c_str());
    auto nodetree = csparsebinary->nodeTree();
    auto csbNode = nodeWithFlatBuffers(nodetree);
    //CCLOG("CSB %s CREATE END ==================================", str.c_str());
    if (csbNode)
    {
        size_t pos1 = str.find_last_of("/") + 1;
        size_t pos2 = str.find_last_of(".");
        csbNode->setName(str.substr(pos1, pos2 - pos1));
        csbNode->retain();
        m_CsbNodes[csbInfo.CsbFilePath] = csbNode;
    }
    else
    {
        CCLOG("create Csb Node %s Faile", csbInfo.CsbFilePath.c_str());
    }
	//CCLOG("CCsbLoader::createCsbNode %s", csbInfo.CsbFilePath.c_str());
    if (csbInfo.Callback)
    {
        csbInfo.Callback(csbInfo.CsbFilePath, csbNode != nullptr);
    }
}


std::string getGUIClassName(const std::string &name)
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

cocos2d::Node* CCsbLoader::nodeWithFlatBuffers(const flatbuffers::NodeTree *nodetree)
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

        auto dataIter = m_CsbFileCache.find(filePath);
        if (dataIter != m_CsbFileCache.end())
        {
            Data buf = dataIter->second;
            auto csparsebinary = GetCSParseBinary(buf.getBytes());
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
                )->createActionWithFlatBuffersFile(filePath);
        }
        else if (filePath != "" && FileUtils::getInstance()->isFileExist(filePath))
        {
            Data buf = FileUtils::getInstance()->getDataFromFile(filePath);
            auto csparsebinary = GetCSParseBinary(buf.getBytes());
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
                )->createActionWithFlatBuffersFile(filePath);
        }
        /*
        auto nodeIter = m_CsbNodes.find(filePath);
        auto dataIter = m_CsbFileCache.find(filePath);
        if (nodeIter != m_CsbNodes.end())
        {
            node = CsbTool::cloneCsbNode(nodeIter->second);
            action = cocostudio::timeline::ActionTimelineCache::getInstance(
                )->createActionWithFlatBuffersFile(filePath);
        }
        else if (dataIter != m_CsbFileCache.end())
        {
            Data buf = dataIter->second;
            m_CsbFileCache.erase(dataIter);
            auto csparsebinary = GetCSParseBinary(buf.getBytes());
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
                )->createActionWithFlatBuffersFile(filePath);
            node->retain();
            m_CsbNodes[filePath] = node;
            node = CsbTool::cloneCsbNode(node);
        }*/
        else
        {
            node = Node::create();
        }
        reader->setPropsWithFlatBuffers(node, options->data());
        if (action)
        {
            action->setTimeSpeed(projectNodeOptions->innerActionSpeed());
            node->runAction(action);
            //action->setTag(TAG_CSB_ACTION);
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

// 查找单个Csb所引用的所有PNG
void CCsbLoader::searchTexturesByCsbFile(Data& data, set<string>& texSet)
{
    auto csparsebinary = GetCSParseBinary(data.getBytes());
    auto textures = csparsebinary->textures();
    int textureSize = csparsebinary->textures()->size();
    for (int i = 0; i < textureSize; ++i)
    {
        string plistFile = FileUtils::getInstance()->fullPathForFilename(textures->Get(i)->c_str());
        if (m_LoadingPlists.find(plistFile) != m_LoadingPlists.end()
            || SpriteFrameCache::getInstance()->isSpriteFramesWithFileLoaded(plistFile))
        {
            continue;
        }
        m_LoadingPlists.insert(plistFile);
        Data plistData = FileUtils::getInstance()->getDataFromFile(plistFile);
        if (plistData.isNull())
        {
            continue;
        }

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
            textureFile = FileUtils::getInstance()->fullPathFromRelativeFile(textureFile, plistFile);
        }
        else
        {
            // 如果plist文件中没有纹理路径名，则尝试读取plist对应的.png
            textureFile = plistFile;
            // 将xxxx.plist结尾的.plist移除，替换成.png
            textureFile = textureFile.erase(textureFile.find_last_of("."));
            textureFile = textureFile.append(".png");
        }

        // 
        if (Director::getInstance()->getTextureCache()->getTextureForKey(textureFile) == nullptr
            && m_LoadingTextures.find(textureFile) == m_LoadingTextures.end())
        {
            m_LoadingTextures.insert(textureFile);
            texSet.insert(textureFile);
        }
    }
}

void CCsbLoader::searchTexturesByCsbNodeTree(const flatbuffers::NodeTree* tree, set<string>& texSet)
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
            if (!filePath.empty() 
                && m_CsbNodes.find(filePath) == m_CsbNodes.end()
                && m_CheckedCsb.find(filePath) == m_CheckedCsb.end())
            {
                m_CheckedCsb.insert(filePath);
                Data data = FileUtils::getInstance()->getDataFromFile(filePath);
                if (!data.isNull())
                {
                    m_CsbFileCache[filePath] = data;
                    // 找到这个Csb所引用的Png
                    searchTexturesByCsbFile(data, texSet);
                    auto csparsebinary = GetCSParseBinary(data.getBytes());
                    // 对该Csb进行递归
                    searchTexturesByCsbNodeTree(csparsebinary->nodeTree(), texSet);
                }
            }
        }
        else
        {
            searchTexturesByCsbNodeTree(subNodeTree, texSet);
        }
    }
}

void CCsbLoader::onLoadFinish()
{
    // 取消schedule
    Director::getInstance()->getScheduler()->unschedule(
        CC_SCHEDULE_SELECTOR(CCsbLoader::createCsbNodeByLoadedTexture), this);

	//CCLOG("CCsbLoader::onFinish");
    m_bIsLoading = false;
    // m_CurrentLoadedCount = 0;
    if (m_finishCallback)
    {
        m_finishCallback(m_CurrentLoadedCount, m_LoadingQueue.size());
    }

    // 清理此次异步加载的临时容器
    m_LoadingQueue.clear();
    m_LoadingTextures.clear();
    m_CheckedCsb.clear();
    m_CsbFileCache.clear();
    autoLoadRes();
}

/*void CCsbLoader::loadCsbNodeThreadSafe(const std::string& csbFile, CsbLoadInfo& info)
{
    // 如果已经加载过这个Csb
    if (info.CsbFileData.find(csbFile) != info.CsbFileData.end()
        || m_CsbNodeMirror.find(csbFile) != m_CsbNodeMirror.end())
    {
        return;
    }

    // 获取CSB文件数据，Data用到了移动构造函数，所以可以用局部变量来保存堆中的指针
    Data data = FileUtils::getInstance()->getDataFromFile(csbFile);
    // 进行记录
    m_CsbNodeMirror.insert(csbFile);
    info.CsbFileData[csbFile] = data;

    // 解析到flatbuffer中
    auto csparsebinary = GetCSParseBinary(data.getBytes());

    // 需要加载的Plist
    auto textures = csparsebinary->textures();
    int textureSize = csparsebinary->textures()->size();
    for (int i = 0; i < textureSize; ++i)
    {
        // 解析出Plist对应的PNG图片
        string plistFile = FileUtils::getInstance()->fullPathForFilename(textures->Get(i)->c_str());
        Data plistData = FileUtils::getInstance()->getDataFromFile(plistFile);
        if (plistData.isNull())
        {
            continue;
        }

        string textureFile;
        ValueMap dict = FileUtils::getInstance()->getValueMapFromData(
            reinterpret_cast<const char*>(plistData.getBytes()), plistData.getSize());

        if (dict.find("metadata") != dict.end())
        {
            ValueMap& metadataDict = dict["metadata"].asValueMap();
            textureFile = metadataDict["textureFileName"].asString();
            if (!textureFile.empty())
            {
                // 计算相对路径，将纹理的文件名对应到plist的路径下
                textureFile = FileUtils::getInstance()->fullPathFromRelativeFile(textureFile, plistFile);
            }
        }
        else
        {
            // 如果plist文件中没有纹理路径名，则尝试读取plist对应的.png
            textureFile = plistFile;
            // 将xxxx.plist结尾的.plist移除
            textureFile = textureFile.erase(textureFile.find_last_of("."));
            textureFile = textureFile.append(".png");
        }

        // 判断该PNG是否已加载
        if (info.PngFiles.find(textureFile) != info.PngFiles.end()
            || m_TextureCacheMirror.find(textureFile) != m_TextureCacheMirror.end())
        {
            continue;
        }

        Image* image = new (std::nothrow) Image();
        Data pngData = FileUtils::getInstance()->getDataFromFile(textureFile.c_str());
        // 如果读取文件为空或初始化Image失败
        if (image && (pngData.isNull() || !image->initWithImageData(pngData.getBytes(), pngData.getSize())))
        {
            CC_SAFE_RELEASE(image);
            CCLOG("CCsbLoader:can not load %s", textureFile.c_str());
            continue;
        }

        // 添加到PngFiles中并追加到镜像中
        info.PngFiles[textureFile] = image;
        m_TextureCacheMirror.insert(textureFile);
    }

    // 对所有的子节点做相同的处理
    auto children = csparsebinary->nodeTree()->children();
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
            std::string filePath = projectNodeOptions->fileName()->c_str();
            if (!filePath.empty())
            {
                loadCsbNodeThreadSafe(filePath, info);
            }
        }
    }
}*/