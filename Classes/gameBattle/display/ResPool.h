/*
	节点管理池
 */
#ifndef __NODE_POOL_H__
#define __NODE_POOL_H__

#include "KxCSComm.h"
#include <spine/spine-cocos2dx.h>

class CResPool
{
private:
    CResPool();
    virtual ~CResPool();

public:
    static CResPool* getInstance();
    static void destory();

    cocos2d::Node* getCsbNode(const std::string& resName);
    void freeCsbNode(const std::string& resName, cocos2d::Node* node);

	spine::SkeletonAnimation* createSpine(const std::string& resName);
	void freeSpineAnimation(const std::string& resName, spine::SkeletonAnimation* node);
    
private:
    static CResPool* m_Instance;
    int m_NodeCacheSize;
    int m_SpineCacheSize;
	int m_MaxCacheSize;
    std::map<std::string, std::list<cocos2d::Node*> > m_NodeCache;
    std::map<std::string, std::list<spine::SkeletonAnimation*> > m_SpineCache;
};

#endif
