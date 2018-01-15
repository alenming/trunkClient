#ifndef __TEXTURE_LOADER_H__
#define __TEXTURE_LOADER_H__

#include "IResLoader.h"
#include <map>

struct TextureLoadInfo
{
	bool				isLoaded;		//是否已加载完成
	ResLoadedCallback	callback;		//回调函数
};

class CTextureLoader : public IResLoader
{
public:
	CTextureLoader();
	~CTextureLoader();

public:
	// 预加载资源，并没有开始加载
	bool addPreloadRes(const std::string& resName, const ResLoadedCallback& callback);
	// 开始异步加载资源
    bool startLoadResAsyn();

    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName) { return m_TextureCache.find(resName) != m_TextureCache.end(); }
	// 移除一个资源
	void removeRes(const std::string& resName);
	// 缓存资源
	void cacheRes(const std::string& resName);
	// 清除所有资源
	void clearRes();
	// 已加载完成的资源数量
	int getLoadedCount();
	// 获取预加载的资源总量
	int getPreloadCount();

private:
	// 获得文件后缀
	std::string getSuffix(const std::string &filename);

private:

	int										    m_nPreloadCount;
    int                                         m_nLoadedCount;
    std::map<std::string, cocos2d::Texture2D*>  m_TextureCache;
    std::map<std::string, TextureLoadInfo>      m_preloadList;
	std::set<std::string>					    m_cacheRes;
};

#endif //__TEXTURE_LOADER_H__
