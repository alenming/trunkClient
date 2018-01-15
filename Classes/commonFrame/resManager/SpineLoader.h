/*
*   异步加载Spine骨骼
*   添加完预加载的资源后，执行异步加载，共使用了2条线程
*   1.使用TextureCache的线程异步加载纹理
*   2.加载结束后根据加载完成的纹理创建spAtlas对象
*   3.进入骨骼解析线程，使用spAtlas对象创建骨骼数据对象
*   4.在主线程中处理完成的骨骼到Cache中
*
*   2015-10-30 by 宝爷
*/
#ifndef __SPINE_LAODER_H__
#define __SPINE_LAODER_H__

#include <spine/spine-cocos2dx.h>
#include <atomic> 
#include "IResLoader.h"

struct SpineLoadingInfo
{
    std::string JsonFile;
    std::string AtlasFile;
    std::string TextureFile;
    cocos2d::Image* AtlasImage;
    spAtlas* Atlas;
    spSkeletonData* SkeletonData;
    ResLoadedCallback Callback;
};

struct SpineCacheInfo
{
    spAtlas* Atlas;
    spSkeletonData* SkeletonData;
};

class CSpineLoader : public IResLoader
{
public:
    CSpineLoader();
    virtual ~CSpineLoader();

    // 预加载资源，并没有开始加载
    virtual bool addPreloadRes(const std::string& resName, const std::string& atlasName, const ResLoadedCallback& callback);
    // 预加载资源，并没有开始加载，需传入副资源（Spine：json + atlas）
    virtual bool startLoadResAsyn();

    void onSkeletonLoaded(float dt);

    // 获取一个资源
    spSkeletonData* getSkeletonData(const std::string& resName);
    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName) { return getSkeletonData(resName) != nullptr; }
    // 移除一个资源
    virtual void removeRes(const std::string& resName);
	// 缓存资源
	virtual void cacheRes(const std::string& resName);
    // 清除所有资源
    virtual void clearRes();
    // 已加载完成的资源数量
    virtual int getLoadedCount(){ return m_nFinishIndex; }
    // 获取预加载的资源总量
    virtual int getPreloadCount(){ return m_LoadingInfos.size(); }

private:
    // 加载结束时调用
    void onFinish();
    // 骨骼加载线程
    //void skeletonThread();
    // 加载下一个骨骼
    //void loadNextSkeletonThreadSafe();
    // 加载下一个纹理
    //void loadNextTextureThreadSafe();

private:
    bool m_bThreadWorking;
    int m_nTextureLoadingIndex;
    int m_nSkeletonLoadingIndex;                       // 当前可加载
    int m_nFinishIndex;
    std::thread* m_SkeletonThread;
    std::vector<SpineLoadingInfo> m_LoadingInfos;
    std::set<std::string> m_LoadingSpine;
	std::set<std::string> m_CacheRes;
    std::map<std::string, SpineCacheInfo> m_SpineCache;
};

#endif
