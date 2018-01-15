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

#include "flatbuffers/flatbuffers.h"
#include "flatbuffers/util.h"
#include "cocostudio/FlatBuffersSerialize.h"
#include "cocostudio/CSParseBinary_generated.h"

/*struct CsbLoadInfo
{
    std::string CsbFilePath;
    std::map<std::string, Data> CsbFileData;
    std::map<std::string, cocos2d::Image*> PngFiles; 
};*/

#define TAG_CSB_ACTION  1000000

struct CsbLoadingInfo
{
    int LoadedCount;
    std::string CsbFilePath;
    std::set<std::string> PreloadTextures;
    ResLoadedCallback Callback;
};

class CCsbLoader : public IResLoader
{
public:
    CCsbLoader();
    virtual ~CCsbLoader();

    // 添加一个要异步加载的Csb文件，并传入回调，这些信息会被放入一个预加载队列中
    // 如果是一个嵌套了子Csb的文件，并且没有在这之前去加载这些子Csb，autoSearchCsbChild允许自动遍历并预加载它们的纹理资源
    // 添加成功返回true，已经开始异步加载或已经在预加载列表中返回false
    bool addPreloadRes(const std::string& csbFile, const ResLoadedCallback& callBack);
    // 异步加载预加载队列中的资源
    bool startLoadResAsyn();
    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName) { return getCsbNode(resName) != nullptr; }
    // 清理指定的Csb资源
	void removeRes(const std::string& csbFile);
	// 缓存的资源
	void cacheRes(const std::string& resName);
    // 清理所有的Csb资源
    void clearRes();

    // 获取Cache的Csb节点
    cocos2d::Node* getCsbNode(const std::string& csbFile);
    // update方法，在主线程中根据已加载的纹理创建Csb
    void createCsbNodeByLoadedTexture(float dt);

    inline int getLoadedCount() { return m_CurrentLoadedCount; }
    inline int getPreloadCount() { return m_LoadingQueue.size(); }

private:
    // 创建一个Csb节点
    void createCsbNode(const CsbLoadingInfo& csbInfo);
    cocos2d::Node* nodeWithFlatBuffers(const flatbuffers::NodeTree *nodetree);
    // 深度搜索Csb纹理
    void searchTexturesByCsbFile(cocos2d::Data& data, std::set<std::string>& texSet);
    // 搜索Csb节点树
    void searchTexturesByCsbNodeTree(const flatbuffers::NodeTree* tree, std::set<std::string>& texSet);
    // 所有Csb节点都加载完毕后执行
    void onLoadFinish();
    // 线程异步加载方法
    // void loadCsbNodeThreadSafe(const std::string& csbFile, CsbLoadInfo& info);

private:
    bool m_bIsAutoSerachSubCsb;
    int m_CurrentLoadedCount;

    // 线程异步加载
    //std::thread* m_LoadingThread;
    //std::set<std::string> m_TextureCacheMirror;       // PNG镜像，使线程加载中不操作TextureCache即可判断是否已经加载过该PNG
    //std::set<std::string> m_CsbNodeMirror;            // CSB文件镜像，使线程加载中不操作m_CsbNodes即可判断是否已经加载过该CSB
    //std::vector<CsbLoadInfo> m_LoadingCsbInfo;

    std::vector<CsbLoadingInfo> m_LoadingQueue;         // 异步加载队列
    std::set<std::string> m_LoadingTextures;            // 即将加载的纹理，防止重复加载
    std::set<std::string> m_LoadingPlists;              // 即将加载的图集，防止重复加载
    std::set<std::string> m_CheckedCsb;                 // 已经搜索过的Csb，防止重复搜索
	std::set<std::string> m_CacheRes;					// 缓存资源列表
    std::map<std::string, cocos2d::Data> m_CsbFileCache;// CSB文件缓存
    std::map<std::string, cocos2d::Node*> m_CsbNodes;   // 加载完成的Csb节点容器
};

#endif
