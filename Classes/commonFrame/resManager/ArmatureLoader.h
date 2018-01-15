/*
*   CocoStudio1.6骨骼动画加载器
*   加载流程如下：
*   1.开启armature线程加载并解析骨骼
*   2.在主线程将加载完成的数据添加到Cache
*   3.根据加载完成的数据添加Plist图集，此时会使用TextureCache线程加载纹理
*
*   2015-10-30 By 宝爷
*/
#ifndef __ARMATURE_LOADER_H__
#define __ARMATURE_LOADER_H__

#include "IResLoader.h"
#include "cocostudio/CocoStudio.h"

enum ArmatureFileType
{
    ArmatureErrorType,
    ArmatureCsbType,
    ArmatureJsonType
};

struct ArmatureLoadingInfo
{
    bool Error;
    int PlistLoadedCount;
    ArmatureFileType FileType;
    std::string ResFile;
    std::string fullPathFile;
    std::list<cocostudio::ArmatureData*> ArmatureDatas;
    std::list<cocostudio::AnimationData*> AnimationDatas;
    std::list<cocostudio::TextureData*> TextureDatas;
    std::map<std::string, std::string> PlistPngMap;
    ResLoadedCallback Callback;
};

class CArmatureLoader : public IResLoader
{
public:
    CArmatureLoader();
    virtual ~CArmatureLoader();
    // 预加载一个骨骼资源【不支持DragonBone】
    bool addPreloadRes(const std::string& resName, const ResLoadedCallback& callback);
    // 开始异步加载
    bool startLoadResAsyn();
    // 骨骼加载完成
    void onArmatureLoaded(float dt);

    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName);
    // 移除指定的ArmatureData
    void removeRes(const std::string& resName);
	// 缓存不清理资源
	void cacheRes(const std::string& resName);
    // 清理所有的ArmatureData
    void clearRes();

    int getLoadedCount() { return m_nFinishIndex; }
    int getPreloadCount() { return m_LoadingInfos.size(); }
private:
    // 骨骼加载线程
    void armatureThread();
    // 全部加载完成
    void onFinish();
private:
    bool m_bIsThreadWorking;                            // 骨骼加载线程工作标识
    int m_nLoadingIndex;                                // 骨骼线程加载完成的索引（骨骼线程执行++）
    int m_nArmatureIndex;                               // 骨骼对象添加到ArmatureDataManager完成的索引（主线程++）
    int m_nFinishIndex;                                 // 一切处理完毕后（包括addSpriteFrames）的索引（先转PNG线程，回到主线程++）
    std::thread* m_ArmatureThread;                      // 骨骼加载线程
    std::vector<ArmatureLoadingInfo> m_LoadingInfos;    // 预加载骨骼队列
    std::set<std::string> m_ArmatureCache;              // 需要缓存的骨骼
};

class SafeDataReaderHelper : public cocostudio::DataReaderHelper
{
public:
    // 暂不支持，懒得去添加tinyxml库
    //static void loadXmlArmatureThreadSafe(ArmatureLoadingInfo& info);
    // 获取Armature列表--这里不能返回引用，因为会进行删除
    static std::vector<std::string> getArmatureList();
    static void loadCsbArmatureThreadSafe(ArmatureLoadingInfo& info);
    static void loadJsonArmatureThreadSafe(ArmatureLoadingInfo& info);
    static bool isArmatureLoaded(const std::string& configFile);
    static void saveFileInfo(const std::string& configFile);
};

#endif