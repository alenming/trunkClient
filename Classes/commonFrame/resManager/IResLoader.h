/*
*   资源加载器的基类
*   抽象了各种类型资源加载器的通用接口
*   定义了通用的资源加载回调
*
*   2015-10-27 By 宝爷
*/
#ifndef __IRES_LOADER_H__
#define __IRES_LOADER_H__

#include <cocos2d.h>
#include <stdio.h>
#include <string>

// 单个资源加载完成的回调
// 传入加载的资源名以及加载结果
typedef std::function<void(const std::string&, bool)> ResLoadedCallback;
// 所有资源加载完成后的回调
// 依次传入总资源、成功资源的数量
typedef std::function<void(int, int)> ResFinishCallback;

// 预加载结构体
struct PreLoadResInfo
{
    std::string ResName;
    std::string AssName;
    ResLoadedCallback Callback;
};

class IResLoader : public cocos2d::Ref
{
public:
    IResLoader();
    virtual ~IResLoader();

    // 预加载资源，并没有开始加载
    virtual bool addPreloadRes(const std::string& resName, const ResLoadedCallback& callback);
    // 预加载资源，并没有开始加载，需传入副资源（Spine：json + atlas）
    virtual bool addPreloadRes(const std::string& resName, const std::string& assName, const ResLoadedCallback& callback);

    // 开始异步加载资源
    virtual bool startLoadResAsyn();
    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName) = 0;
    // 移除一个资源
    virtual void removeRes(const std::string& resName) = 0;
	// 文件不清理
	virtual void cacheRes(const std::string& resName) = 0;
    // 清除所有资源
    virtual void clearRes();
    // 已加载完成的资源数量
    virtual int getLoadedCount() = 0;
    // 获取预加载的资源总量
    virtual int getPreloadCount() = 0;

    // 可选实现接口，直接异步加载某资源，非预加载
    // 需自己保证线程安全，预加载时不建议调用
    virtual void loadResAsyn(const std::string& resName, const ResLoadedCallback& callback);

    // 设置所有资源加载完成的回调
    virtual void setFinishCallback(const ResFinishCallback& callback)
    {
        m_finishCallback = callback;
    }
    // 是否正在加载
    virtual bool isLoading() { return m_bIsLoading; }

protected:
    // 检查是否可以加载指定的资源
    virtual bool checkLoadRes(const std::string& resName, const std::string& assName, const ResLoadedCallback& callback);
    // 自动加载 —— 在【加载中】要加载的资源会被添加到自动加载列表中
    // 如果自动加载列表中的资源已经被加载，则会调用回调函数，并【从自动加载列表中移除】
    // 如果资源未被加载，则加载该资源，并【从自动加载列表中移除】
    // 如果资源已经准备加载，则【保留在自动加载列表中】
    virtual void autoLoadRes();

protected:
    bool m_bIsLoading;
    ResFinishCallback m_finishCallback;
    std::vector<PreLoadResInfo> m_AutoLoadResCache;     // 自动加载列表
};

namespace TextureTools
{
    std::string getTexturePathFromPlist(std::string plistPath);
}

#endif
