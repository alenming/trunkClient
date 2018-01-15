#include "SuperRichText.h"
#include "CommTools.h"
#include "ResManager.h"
#include "ui/UIButton.h"
#include "LuaSummonerBase.h"

using namespace ui;

SuperRichText::SuperRichText(float width) :_dirty(false)
, _isClick(false)
, _width(width)
{
    initialize();
}

SuperRichText::~SuperRichText()
{
    this->removeAllChildren();
}

SuperRichText* SuperRichText::create(float width/* = 0.0f*/)
{
    SuperRichText* text = new (std::nothrow) SuperRichText(width);
    if (text && text->init())
    {
        text->autorelease();
        return text;
    }
    CC_SAFE_DELETE(text);
    return nullptr;
}

SuperRichText* SuperRichText::create(const char *htmlCode, float width/* = 0.0f*/)
{
    SuperRichText *text = new SuperRichText(width);
    if (text && text->init()) 
    {
        text->renderHtml(htmlCode);
        text->autorelease();
        return text;
    } 

    CC_SAFE_DELETE(text);
    return nullptr;
}

void SuperRichText::renderHtml(const char *html)
{
    if (_dirty)
    {
        _contentSize = Size(0.0f, 0.0f);
        removeAllChildren();
        _richElements.clear();
    }
    else
    {
        _dirty = true;
    }

    if (_width > 0.0f)
    {
        ignoreContentAdaptWithSize(false);
        setContentSize(Size(_width, _contentSize.height));
    }
    else
    {
        ignoreContentAdaptWithSize(true);
    }

    tinyxml2::XMLDocument xml;
    xml.Parse(html);

    tinyxml2::XMLNode *node = xml.FirstChild();
    if (node)
    {
        renderNode(node);
    }
    else
    {
        std::string utf8Text = trimText(html);
        auto font = _fontList[_fontList.size() - 1];
        auto textElement = ui::RichElementText::create(0, font.color, font.opacity, utf8Text, font.fontName, font.fontSize);

        pushBackElement(textElement);
    }

    formatRichText();
}

void SuperRichText::renderNode(tinyxml2::XMLNode *node)
{
    while (node != nullptr) 
    {
        if (node->ToText()) 
        {
            auto n = node->ToText();
            std::string utf8Text = trimText(n->Value());

            auto font = _fontList[_fontList.size()-1];
            if (font.isClick)
            {
                auto fileExist = FileUtils::getInstance()->isFileExist(font.fontName);
                Label* textRenderer = nullptr;
                if (fileExist)
                {
                    textRenderer = Label::createWithTTF(utf8Text, font.fontName, font.fontSize);
                }
                else
                {
                    textRenderer = Label::createWithSystemFont(utf8Text, font.fontName, font.fontSize);
                }

                if (font.flag & ui::RichElementText::UNDERLINE_FLAG)
                    textRenderer->enableUnderline();
                if (font.flag & RichElementText::OUTLINE_FLAG)
                    textRenderer->enableOutline(Color4B(font.outlineColor), font.outlineSize);

                textRenderer->setColor(font.color);
                textRenderer->setOpacity(font.opacity);

                _clickNode[textRenderer] = font.extend;

                auto textElement = ui::RichElementCustomNode::create(0, font.color, font.opacity, textRenderer);
                pushBackElement(textElement);
            }
            else
            {
                auto textElement = ui::RichElementText::create(0, font.color, font.opacity, 
                    utf8Text, font.fontName, font.fontSize, font.flag, "", font.outlineColor, font.outlineSize);
                pushBackElement(textElement);
            }
        }
        else if(node->ToElement())
        {
            auto n = node->ToElement();
            std::string name = n->Name();

            std::transform(name.begin(), name.end(), name.begin(), ::toupper);

            if (name == "FONT")
            {
                analysisFont(n);
            }
            else if (name == "IMG")
            {
                analysisImg(n);
            }
            else if (name == "BR")
            {
                auto line = ui::RichElementNewLine::create(0, Color3B(255, 255, 255), 255);
                pushBackElement(line);
            }
            else if (name == "CSB")
            {
                analysisCsb(n);
            }
        }
        
        node=node->NextSibling();
    }
}

void SuperRichText::initialize()
{
    FontInfo defaultFont;
    defaultFont.color = Color3B(255, 255, 255);
    defaultFont.fontSize = 20.0f;
    defaultFont.opacity = 255;
    defaultFont.fontName = "";

    _fontList.push_back(defaultFont);
    // 修改为单字节(默认为单词),否则一连串的英文不会换行
    _defaults[KEY_WRAP_MODE] = static_cast<int>(WrapMode::WRAP_PER_CHAR);
    _name = "SuperRichText";
}

void SuperRichText::formatRichText()
{
    adaptRenderers();

    float minX = 0.0f;
    float minY = 0.0f;
    float maxX = 0.0f;
    float maxY = 0.0f;
    for (auto &node : _protectedChildren)
    {
        Vec2 pos = node->getPosition();
        Vec2 ancPos = node->getAnchorPoint();
        Size size = node->getContentSize();

        minX = MIN(minX, pos.x - size.width * ancPos.x);
        minY = MIN(minY, pos.y - size.height * ancPos.y);
        maxX = MAX(maxX, pos.x + size.width * (1.0f - ancPos.x));
        maxY = MAX(maxY, pos.y + size.height * (1.0f - ancPos.y));
    }

    Size contentSize = Size(maxX - minX, maxY - minY);

    setContentSize(contentSize);
    setAnchorPoint(Vec2::ZERO);
}

void SuperRichText::analysisFont(tinyxml2::XMLElement* n)
{
    auto attr = n->FirstAttribute();
    FontInfo newFont = _fontList[_fontList.size() - 1];

    while (attr != nullptr)
    {
        //遍历所有属性
        std::string attrName = attr->Name();
        std::transform(attrName.begin(), attrName.end(), attrName.begin(), ::toupper);
        if (attrName == "FACE")
        {
            //设置字体
            newFont.fontName = attr->Value();
        }
        else if (attrName == "COLOR")
        {
            //设置颜色
            newFont.color = charToColor3B(attr->Value());
        }
        else if (attrName == "SIZE")
        {
            //设置大小
            newFont.fontSize = attr->IntValue();
        }
        else if (attrName == "OPACITY")
        {
            //设置不透明度
            newFont.opacity = attr->IntValue();
        }
        else if (attrName == "UNDERLINE")
        {
            //设置下划线
            newFont.flag = attr->BoolValue()
                ? (newFont.flag | ui::RichElementText::UNDERLINE_FLAG)
                : (newFont.flag & (~ui::RichElementText::UNDERLINE_FLAG));
        }
        else if (attrName == "OUTLINE")
        {
            //设置描边
            newFont.flag |= ui::RichElementText::OUTLINE_FLAG;
            charToOutline(attr->Value(), newFont.outlineColor, newFont.outlineSize);
        }
        else if (attrName == "CLICK")
        {
            newFont.isClick = true;
            newFont.extend = attr->Value();
            if (!_isClick)
            {
                _isClick = true;
                setTouchEnabled(true);
                this->_touchEventCallback = CC_CALLBACK_2(SuperRichText::touchEvent, this);
            }
        }
         
        attr = attr->Next();
    }

    _fontList.push_back(newFont);//添加新字体
    renderNode(n->FirstChild());//继续渲染子集
    _fontList.pop_back();//移除新字体
}

void SuperRichText::analysisImg(tinyxml2::XMLElement* n)
{
    auto attr = n->FirstAttribute();

    const char* src;
    Color3B col(255, 255, 255);
    GLubyte opacity = 255;
    while (attr != nullptr) {
        //遍历所有属性
        std::string attrName = attr->Name();
        std::transform(attrName.begin(), attrName.end(), attrName.begin(), ::toupper);

        if (attrName == "SRC") {
            //设置图片路径
            src = attr->Value();
        }
        else if (attrName == "COLOR")
        {
            //设置颜色
            col = charToColor3B(attr->Value());
        }
        else if (attrName == "OPACITY")
        {
            //设置不透明度
            opacity = attr->IntValue();
        }

        attr = attr->Next();
    }

    auto img = ui::RichElementImage::create(0, col, opacity, src);
    pushBackElement(img);
}

void SuperRichText::analysisCsb(tinyxml2::XMLElement* n)
{
    auto attr = n->FirstAttribute();
    
    const char* path = nullptr;
    const char* animationName = nullptr;
    Color3B col(255, 255, 255);
    GLubyte opacity = 255;
    float scale = 1.0f;
    float width = 0.0f;
    float height = 0.0f;
    bool setWidth = false;
    bool setHeight = false;
    while (attr != nullptr) {
        //遍历所有属性
        std::string attrName = attr->Name();
        std::transform(attrName.begin(), attrName.end(), attrName.begin(), ::toupper);

        if (attrName == "PATH") {
            //CSB路径
            path = attr->Value();
        }
        else if (attrName == "SCALE")
        {
            //设置大小
            scale = attr->FloatValue();
        }
        else if (attrName == "ANIMATION")
        {
            //播放标签
            animationName = attr->Value();
        }
        else if (attrName == "WIDTH")
        {
            //宽度
            setWidth = true;
            width = attr->FloatValue();
        }
        else if (attrName == "HEIGHT")
        {
            //高度
            setHeight = true;
            height = attr->FloatValue();
        }

        attr = attr->Next();
    }

    cocos2d::Node *pCsbNode = CResManager::getInstance()->getCsbNode(path);
    if (pCsbNode)
    {
        pCsbNode->setScale(scale);
        // 宽度和高度可以通过遍历所有节点获取最大值
        if (setWidth)
            pCsbNode->setContentSize(Size(width * scale, pCsbNode->getContentSize().height));

        if (setHeight)
            pCsbNode->setContentSize(Size(pCsbNode->getContentSize().width, height * scale));

        if (nullptr != animationName)
        {
            auto action = CSLoader::createTimeline(path);
            pCsbNode->runAction(action);
            action->play(animationName, true);
        }

        auto csbRichElement = ui::RichElementCustomNode::create(0, Color3B(255, 255, 255), 255, pCsbNode);
        pushBackElement(csbRichElement);
    }
}

GLubyte SuperRichText::charToNumber(char c)
{
    GLubyte n = c - '0';//将“数字字符”转换为数字
    //如果大于9则表示当前是字母 需要将字母转换为10-15的值
    if (n > 9) 
    {
        n = c-(c >= 'a' ? 'a' : 'A') + 10;
    }
    
    return n;
}

Color3B SuperRichText::charToColor3B(const char* code)
{
    Color3B color(0,0,0);
    if (strlen(code)==6) 
    {
        color.r = charToNumber(code[0])*16+charToNumber(code[1]);
        color.g = charToNumber(code[2])*16+charToNumber(code[3]);
        color.b = charToNumber(code[4])*16+charToNumber(code[5]);
    }

    return color;
}

Color4B SuperRichText::charToColor4B(const char* code)
{
    Color4B color(0, 0, 0, 255);
    if (strlen(code) == 6)
    {
        color.r = charToNumber(code[0]) * 16 + charToNumber(code[1]);
        color.g = charToNumber(code[2]) * 16 + charToNumber(code[3]);
        color.b = charToNumber(code[4]) * 16 + charToNumber(code[5]);
    }
    else if (strlen(code) == 8)
    {
        color.r = charToNumber(code[0]) * 16 + charToNumber(code[1]);
        color.g = charToNumber(code[2]) * 16 + charToNumber(code[3]);
        color.b = charToNumber(code[4]) * 16 + charToNumber(code[5]);
        color.a = charToNumber(code[6]) * 16 + charToNumber(code[7]);
    }

    return color;
}

void SuperRichText::charToOutline(std::string code, Color3B &outlineColor, int &outlineSize)
{
    std::vector<std::string> ret;
    splitStringToVec(code, "&", ret);
    if (ret.size() == 2)
    {
        outlineColor = charToColor3B(ret[0].c_str());
        outlineSize = atoi(ret[1].c_str());
    }
}

std::string SuperRichText::trimText(std::string str)
{
    std::u16string text;

    StringUtils::UTF8ToUTF16(str, text);

    std::u16string::size_type pos = 0;
    pos = text.find('\n');
    while ((pos != std::u16string::npos))
    {
        text.erase(pos, 1);
        pos = text.find('\n', pos);
    }

    pos = 0;
    pos = text.find('\r');
    while ((pos != std::u16string::npos))
    {
        text.erase(pos, 1);
        pos = text.find('\r', pos);
    }

    std::string utf8Text;
    StringUtils::UTF16ToUTF8(text, utf8Text);

    return utf8Text;
}

void SuperRichText::touchEvent(Ref* ref, Widget::TouchEventType type)
{
    if (Widget::TouchEventType::ENDED != type)
        return;

    for (auto &nodeIter : _clickNode)
    {
        Node *node = nodeIter.first;
        auto pos = node->convertToWorldSpace(Vec2::ZERO);
        auto anchorPoint = node->getAnchorPoint();
        auto size = node->getContentSize();
        auto rect = Rect(pos.x - size.width * anchorPoint.x,
            pos.y - size.height * anchorPoint.y,
            size.width,
            size.height);

        if (rect.containsPoint(_touchEndPosition))
        {
            onLuaEventWithParamStr(33, nodeIter.second);
            break;
        }
    }
}
