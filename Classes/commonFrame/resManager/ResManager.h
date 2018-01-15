/*
*   资源管理器单例
*   1.支持各种资源的预加载以及缓存
*   2.支持部分资源对象的创建或克隆
*   3.支持资源的清理
*
*   2015-10-30 By 宝爷
*/
#ifndef __RES_MANAGER_H__
#define __RES_MANAGER_H__

#include "cocos2d.h"
#include "CsbLoader_.h"
#include "ArmatureLoader.h"
#include "SpineLoader.h"

enum LoaderType
{
    LOADER_NONE,
    LOADER_SPINE,
    LOADER_TEXTURE,
    LOADER_CSB,
    LOADER_ARMATURE,
    LOADER_MUSIC,
};

class CResManager : public cocos2d::Ref
{
private:
    CResManager();
    virtual ~CResManager();

public:
    static CResManager* getInstance();
    static void destroy();

    // 添加预加载的资源，内部根据后缀自动识别文件格式
    // 支持以下格式：csb（2.0）、png（所有的纹理文件）、plist（图集不指定纹理）
    bool addPreloadRes(const std::string& resName, const ResLoadedCallback& callback);
    // 添加预加载的资源，内部根据后缀自动识别文件格式
    // 支持以下格式配对：json + atlas、plist + png（所有的纹理文件）、
    bool addPreloadRes(const std::string& resName, const std::string& ass, const ResLoadedCallback& callback);
    // 加载cocostudio1.6骨骼动画
    bool addPreloadArmature(const std::string& resName, const ResLoadedCallback &callback);
    // 开始所有资源的异步加载
    bool startResAsyn();
    // 设置结束回调
    void setFinishCallback(const ResFinishCallback& callback);

    // 通过骨骼名字获得骨骼缓存数据
    spSkeletonData * getSpineSkeletonData(const std::string &resName);
    // 创建Spine骨骼动画对象
    spine::SkeletonAnimation* createSpine(const std::string& resName);
    // 获取Csb节点对象
    cocos2d::Node* getCsbNode(const std::string& resName);
    // 克隆Csb节点对象
    cocos2d::Node* cloneCsbNode(const std::string& resName);

    // 删除指定资源, armature与csb后缀重名, 独立接口
    bool removeRes(const std::string& resName);
    bool removeArmature(const std::string& resName);
    // 下一次的clear不清除指定的资源
    void cacheRes(const std::string& resName);
    void cacheRes(int loaderType);
    // 清理资源
    void clearRes();
    // 是否加载了资源
    bool hasRes(const std::string& resName);
    bool hasArmature(const std::string& resName);

    // 在加载资源过程中追加新的异步资源
    //bool appendLoadResAsyn() { return false; }
private:
    // 初始化
    bool init();
    // 获得文件后缀
    std::string getSuffix(const std::string &filename);
    // 检查加载
    void checkLoading(float dt);

private:
    static CResManager*			m_Instance;
    bool						m_bIsLoading;
    int							m_nPreload;
    int							m_nLoaded;

    ResFinishCallback			m_FinishCallback;
    std::set<int>				m_CacheLoader;
    std::map<int, IResLoader*>	m_Loaders;
};

#endif