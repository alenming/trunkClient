/*
 * 显示组件
 * 1.所有显示组件的基类
 *
 * 2014-12-19 by 宝爷
 */
#ifndef __DISPLAY_COMPONENT_H__
#define __DISPLAY_COMPONENT_H__

#include "KxCSComm.h"

class CDisplayComponent : public Component
{
public:
    CDisplayComponent();
    virtual ~CDisplayComponent();

    // 设置为主显示对象，将显示节点的TAG设置为MAIN_DISPLAY
    virtual void setMainDisplay(bool isMain)
    {
    }
};

#endif
