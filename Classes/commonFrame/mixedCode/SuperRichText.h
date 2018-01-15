#ifndef __SUPER_RICH_TEXT__
#define __SUPER_RICH_TEXT__

#include "cocos2d.h"
#include "ui/UIRichText.h"
#include "tinyxml2/tinyxml2.h"

USING_NS_CC;

/**
*@brief render html.support line feed, but can't support outlint.
*/
struct FontInfo{
    std::string fontName;
    std::string extend;
    float fontSize;
    Color3B color;
    GLubyte opacity;
    uint32_t flag;
    bool isClick;
    Color3B outlineColor;
    int outlineSize;

    FontInfo() :fontName("")
        , extend("")
        , fontSize(24)
        , opacity(255)
        , flag(0)
        , isClick(false)
        , outlineSize(-1)
    {}
};

class SuperRichText : public ui::RichText
{
public:
    SuperRichText(float width);
    virtual ~SuperRichText();
    
    static SuperRichText* create(float width = 0.0f);

    static SuperRichText* create(const char *htmlCode, float width = 0.0f);

    virtual void renderHtml(const char* html);

    virtual void renderNode(tinyxml2::XMLNode* node);
    
private:

    void initialize();
    
    void formatRichText();

    // 解析font标签
    void analysisFont(tinyxml2::XMLElement* n);
    // 解析img标签
    void analysisImg(tinyxml2::XMLElement* n);
    // 解析csb标签
    void analysisCsb(tinyxml2::XMLElement* n);

    inline GLubyte charToNumber(char c);
    
    inline Color3B charToColor3B(const char* code);
    inline Color4B charToColor4B(const char* code);

    inline void charToOutline(std::string code, Color3B &outlineColor, int &outlineSize);

    inline std::string trimText(std::string str);
    
    void touchEvent(Ref* ref, Widget::TouchEventType type);

protected:
    std::vector<FontInfo> _fontList;
    std::map<Node*, std::string> _clickNode;
    bool _dirty;
    bool _isClick;
    float _width;
};

#endif /* defined(__SUPER_RICH_TEXT__) */
