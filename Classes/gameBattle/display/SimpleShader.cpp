#include "SimpleShader.h"
#include "ui/UIImageView.h"
#include "ui/UIScale9Sprite.h"
#include "ui/UITextBMFont.h"

USING_NS_CC;
using namespace ui;

static const char* HSV = "HSV";
static const char* HUE = "HUE";
static const char* HSVNoMVP = "HSVNoMVP";
static const char* SummonerGray = "SUMMONER_GRAY";

GLProgramState* CSimpleShader::applyHSVShader(cocos2d::Node* node, const cocos2d::Vec3& hsv)
{
    auto glProgram = ShaderCache::getInstance()->getGLProgram(HSV);
    if (glProgram == nullptr)
    {
        auto fileUtiles = FileUtils::getInstance();
        auto fragmentFilePath = fileUtiles->fullPathForFilename("shaders/HSV.frag");
        auto fragSource = fileUtiles->getStringFromFile(fragmentFilePath);
        glProgram = GLProgram::createWithByteArrays(ccPositionTextureColor_vert, fragSource.c_str());
        ShaderCache::getInstance()->addGLProgram(glProgram, HSV);
    }

    node->setGLProgram(glProgram);

    auto programState = node->getGLProgramState();
    programState->setUniformVec3("u_hsv", hsv);

    return programState;
}

void CSimpleShader::applyHSVShaderNoMVP(cocos2d::Node* node, const cocos2d::Vec3& hsv)
{
    auto glProgram = ShaderCache::getInstance()->getGLProgram(HSVNoMVP);
    if (glProgram == nullptr)
    {
        auto fileUtiles = FileUtils::getInstance();
        auto fragmentFilePath = fileUtiles->fullPathForFilename("shaders/HSV.frag");
        auto fragSource = fileUtiles->getStringFromFile(fragmentFilePath);
        glProgram = GLProgram::createWithByteArrays(ccPositionTextureColor_noMVP_vert, fragSource.c_str());
        ShaderCache::getInstance()->addGLProgram(glProgram, HSVNoMVP);
    }

    node->setGLProgram(glProgram);
    auto programState = node->getGLProgramState();
    programState->setUniformVec3("u_hsv", hsv);
}

GLProgramState* CSimpleShader::applyHueShader(cocos2d::Node* node, const float hue)
{
    auto glProgram = ShaderCache::getInstance()->getGLProgram(HUE);
    if (glProgram == nullptr)
    {
        auto fileUtiles = FileUtils::getInstance();
        auto fragmentFilePath = fileUtiles->fullPathForFilename("shaders/Hue.frag");
        auto fragSource = fileUtiles->getStringFromFile(fragmentFilePath);
        glProgram = GLProgram::createWithByteArrays(ccPositionTextureColor_vert, fragSource.c_str());
        ShaderCache::getInstance()->addGLProgram(glProgram, HUE);
    }

    node->setGLProgram(glProgram);
    auto programState = node->getGLProgramState();
    programState->setUniformFloat("u_hue", hue);

    return programState;
}

void CSimpleShader::applyGray(cocos2d::Node* node)
{
    for (auto &child : node->getChildren())
    {
        applyGray(child);
    }

    Node *pGrayNode = nullptr;
    Sprite *pSprite = dynamic_cast<Sprite*>(node);
    if (nullptr == pSprite)
    {
        ImageView *pImageView = dynamic_cast<ImageView*>(node);
        if (pImageView)
        {
            auto imageViewNode = dynamic_cast<Scale9Sprite*>(pImageView->getVirtualRenderer());
            if (imageViewNode)
            {
                imageViewNode->setState(Scale9Sprite::State::GRAY);
                return;
            }
        }

        TextBMFont *pLabel = dynamic_cast<TextBMFont*>(node);
        if (pLabel)
        {
            pGrayNode = pLabel->getVirtualRenderer();
        }
    }
    else
    {
        pGrayNode = pSprite;
    }

    if (nullptr == pGrayNode)
    {
        return;
    }

    auto glProgram = ShaderCache::getInstance()->getGLProgram(SummonerGray);
    if (glProgram == nullptr)
    {
        auto fileUtiles = FileUtils::getInstance();
        auto vshFilePath = fileUtiles->fullPathForFilename("shaders/Gray.vsh");
        auto fshFilePath = fileUtiles->fullPathForFilename("shaders/Gray.fsh");
        glProgram = GLProgram::createWithFilenames(vshFilePath, fshFilePath);
        ShaderCache::getInstance()->addGLProgram(glProgram, SummonerGray);
    }

    pGrayNode->setGLProgram(glProgram);
}

void CSimpleShader::removeGray(cocos2d::Node* node)
{
    for (auto &child : node->getChildren())
    {
        removeGray(child);
    }

    Node *pGrayNode = nullptr;
    Sprite *pSprite = dynamic_cast<Sprite*>(node);
    if (nullptr == pSprite)
    {
        ImageView *pImageView = dynamic_cast<ImageView*>(node);
        if (pImageView)
        {
            auto imageViewNode = dynamic_cast<Scale9Sprite*>(pImageView->getVirtualRenderer());
            if (imageViewNode)
            {
                imageViewNode->setState(Scale9Sprite::State::NORMAL);
                return;
            }
        }

        TextBMFont *pLabel = dynamic_cast<TextBMFont*>(node);
        if (pLabel)
        {
            pGrayNode = pLabel->getVirtualRenderer();
        }
    }
    else
    {
        pGrayNode = pSprite;
    }

    if (pGrayNode != nullptr)
    {
        std::string str = GLProgram::SHADER_NAME_POSITION_TEXTURE_COLOR_NO_MVP;
        GLProgram * pProgram = ShaderCache::getInstance()->getGLProgram(str);
        pGrayNode->setGLProgram(pProgram);
    }
}