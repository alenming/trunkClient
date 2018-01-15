#ifndef __MUSIC_LOADER_H__
#define __MUSIC_LOADER_H__

#include "IResLoader.h"

struct MusicResInfo
{
	bool isLoaded;
	ResLoadedCallback callback;
};

class CMusicLoader : public IResLoader
{
public:
	CMusicLoader();
	~CMusicLoader();

public:
	// 加载的都是Effect, background不需要预加载
	bool addPreloadRes(const std::string& resName, const ResLoadedCallback& callback);
	// 开始加载
	bool startLoadResAsyn();
	// 是否已加载
    bool isMusicLoad(const std::string &resName);
    // 是否已加载指定的资源
    virtual bool hasRes(const std::string& resName) { return isMusicLoad(resName); }
	// 移除资源
	void removeRes(const std::string& resName);
	// 文件不清理
	void cacheRes(const std::string& resName);
	// 清楚资源
	void clearRes();
	// 获得已加载个数
	int getLoadedCount();
	// 获得预加载个数
	int getPreloadCount();

private:

	void loadingMusic(float dt);

private:

	bool								m_bThreadWork;
	int									m_nPreloadCount;
	std::thread* 						m_pThread;
	std::map<std::string, MusicResInfo>	m_loadingEffect;
	std::set<std::string>   m_cacheRes;
	std::set<std::string>	m_loadedEffect;
};

#endif //__MUSIC_LOADER_H__
