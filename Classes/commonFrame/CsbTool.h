#ifndef __CSB_TOOL_H__
#define __CSB_TOOL_H__

#include <cocos2d.h>

class CsbTool
{
public:
    // 根据Node进行克隆
    static cocos2d::Node* cloneCsbNode(cocos2d::Node* node);
};

#endif
