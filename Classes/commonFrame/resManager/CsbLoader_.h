/*
*  异步加载 Csb节点
*  1. 通过addPreloadResAsyn方法将要异步加载的节点全部添加进来（可以设置该Csb加载完成的回调）
*  2. 接下来调用startLoadingResAsyn开始异步加载（可先调用setFinishCallback设置加载完成的回调）
*  3. 加载完成之后可以使用getCsbNode方法获取里面的节点
*
*  2015-10-22 By 宝爷
*
*/
#ifndef __CSB_LOADER_H__
#define __CSB_LOADER_H__

#include <set>
#include <string>
#include <map>

#include "IResLoader.h"
#include "CommTools.h"

#include "flatbuffers/flatbuffers.h"
#include "flatbuffers/util.h"
#include "cocostudio/FlatBuffersSerialize.h"
#include "cocostudio/CSParseBinary_generated.h"

class CDataObject : public cocos2d::Ref
{
public:
    CDataObject();
    virtual ~CDataObject();

    void setData(cocos2d::Data data);
    cocos2d::Data &getData();

private:
    cocos2d::Data m_Data;
};

struct CsbObject
{
    virtual ~CsbObject();

    std::set<CDataObject*> DataObjects;
    std::set<cocos2d::Texture2D*> Textures;
};

// loading的csb信息
struct LoadingCsbObject : public cocos2d::Ref
{
    LoadingCsbObject(std::string csbFilePath, ResLoadedCallback callback) 
    : SuccessCount(0)
    , FaileCount(0)
    , CsbFilePath(csbFilePath)
    , MainCsbObject(nullptr)
    , Callback(callback)
    {
    }

    int SuccessCount;
    int FaileCount;
    std::string CsbFilePath;
    CsbObject* MainCsbObject;
    std::set<std::string> TextureFiles;
    ResLoadedCallback Callback;
};

class CNewCsbLoader : public IResLoader
{
public:
    CNewCsbLoader();
    virtual ~CNewCsbLoader();

    // 添加一个要异步加载的Csb文件，并传入回调，这些信息会被放入一个预加载队列中
    // 如果是一个嵌套了子Csb的文件，并且没有在这之前去加载这些子Csb，autoSearchCsbChild允许自动遍历并预加载它们的纹理资源
    // 添加成功返回true，已经开始异步加载或已经在预加载列表中返回false
    bool addPreloadRes(const std::string& csbFile, const ResLoadedCallback& callBack);
    // 异步加载预加载队列中的资源
    bool startLoadResAsyn();
    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName);
    // 清理指定的Csb资源
	void removeRes(const std::string& csbFile);
	// 缓存的资源
	void cacheRes(const std::string& resName);
    // 清理所有的Csb资源
    void clearRes();

    void waitForQuit();

    inline int getLoadedCount() { return m_CurrentLoadedCount; }
    inline int getPreloadCount() { return m_TotalLoadingCount; }
    // 创建一个Csb节点
    cocos2d::Node* createCsbNode(const std::string& csbFile);

private:
    // 线程中加载csb
    void loadCsb();
    // 深度搜索Csb纹理
    void searchTexturesByCsbFile(const cocos2d::Data& data, std::set<std::string>& texSet);
    // 搜索Csb节点树
    void searchTexturesByCsbNodeTree(const flatbuffers::NodeTree* tree, std::set<std::string>& texSet, std::set<CDataObject*>& objects);
    // 通关csb文件获取data，主线程子线程都会调用，需要加锁
    CDataObject* getDataForCsbFile(const std::string& csbFile);
    // 根据plist文件获取对应的纹理文件名，只有子线程会调用，主线程不能也不应该调用
    const std::string& getTextFromPlist(const std::string& plist);
    // 只有主线程会调用，执行结束的回调
    void onCsbLoadFinish(LoadingCsbObject* loadingCsb, bool success);

    // 所有Csb节点都加载完毕后执行
    void onLoadFinish();
    void addImageAsyncCallBack(float dt);
    cocos2d::Node* nodeWithFlatBuffers(const flatbuffers::NodeTree *nodetree);
    std::string getGUIClassName(const std::string &name);

private:
    bool m_bNeedQuit;
    int m_CurrentLoadedCount;
    int m_TotalLoadingCount;
    
    std::thread*                           m_LoadingThread;     // 线程异步加载
    std::mutex                             m_RequestMutex;      // 请求互斥锁
    std::mutex                             m_ResponseMutex;     // 响应互斥锁
    std::mutex                             m_DataObjectMutex;   // DataObjectPool互斥锁
    std::condition_variable                m_SleepCondition;    // 条件

    std::deque<LoadingCsbObject*>          m_RequestQueue;      // 请求加载资源的队列
    std::deque<LoadingCsbObject*>          m_ResponseQueue;     // 加载了资源的队列
    std::set<LoadingCsbObject*>            m_LoadingTextureCsb; // 正在加载纹理的CSBLoading对象
    
    std::map<std::string, CDataObject*>    m_DataObjectPool;    // CSB文件dataobject
    std::map<std::string, CsbObject*>      m_CsbObjectPool;     // 加载完成的Csb节点容器
    std::map<std::string, std::string>     m_PlistTextMap;      // 在
    std::set<std::string>                  m_CacheRes;          // 缓存资源列表
};

#endif
