#ifndef __SIMPLE_SHADER_H__
#define __SIMPLE_SHADER_H__

#include "cocos2d.h"

class CSimpleShader
{
public:
    // h s v 为增加量和减少量
    static cocos2d::GLProgramState* applyHSVShader(cocos2d::Node* node, const cocos2d::Vec3& hsv);

    // h s v 为增加量和减少量
    static void applyHSVShaderNoMVP(cocos2d::Node* node, const cocos2d::Vec3& hsv);

    // 设置色相
    static cocos2d::GLProgramState* applyHueShader(cocos2d::Node* node, const float hue);

    // 应用灰化
    static void applyGray(cocos2d::Node* node);
    // 去除灰化
    static void removeGray(cocos2d::Node* node);
};

#endif
