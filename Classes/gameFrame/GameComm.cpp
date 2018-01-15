#include "GameComm.h"

static const GLchar* pszFragSource1 =
	"#ifdef GL_ES \n \
	precision mediump float; \n \
	#endif \n \
	//uniform sampler2D u_texture; \n \
	varying vec2 v_texCoord; \n \
	varying vec4 v_fragmentColor; \n \
	void main(void) \n \
	{ \n \
	// Convert to greyscale using NTSC weightings \n \
	//vec4 col = texture2D(u_texture, v_texCoord); \n \
	vec4 col = texture2D(CC_Texture0, v_texCoord); \n \
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114)); \n \
	gl_FragColor = vec4(grey, grey, grey, col.a); \n \
	}";

static const GLchar* pszFragSource2 =
	"#ifdef GL_ES \n \
	precision mediump float; \n \
	#endif \n \
	//uniform sampler2D u_texture; \n \
	varying vec4 v_fragmentColor; \n \
	varying vec2 v_texCoord; \n \
	void main(void) \n \
	{ \n \
	// Convert to greyscale using NTSC weightings \n \
	//vec4 col = texture2D(u_texture, v_texCoord); \n \
	vec4 col = texture2D(CC_Texture0, v_texCoord); \n \
	gl_FragColor = vec4(col.r, col.g, col.b, col.a); \n \
	}";


void setGray(Node* node, bool b)
{
	CHECK_RETURN_VOID(node);

	auto layout = dynamic_cast<Layout*>(node);
	if(layout)
	{
		for(auto item : layout->getChildren())
		{
			CHECK_CONTINUE(item);
			setGray(item, b);
		}
		return;
	}

	Node* render = node;
	auto widget = dynamic_cast<Widget*>(node);
	if(widget)
	{
		Node* renderNode = widget->getVirtualRenderer();
		CHECK_RETURN_VOID(renderNode);
	    auto sp = dynamic_cast<Scale9Sprite*>(renderNode);
		if(sp)
		{
			render = sp->getSprite();
			CHECK_RETURN_VOID(render);
		}
		auto lb = dynamic_cast<Label*>(renderNode);
		if(lb)
		{
			//TODO:颜色设置不能恢复
			lb->setColor(b ? Color3B::GRAY : Color3B::WHITE);
			return;
		}
	}

	//auto fragmentFullPath = cocos2d::FileUtils::getInstance()->fullPathForFilename("example_greyScale.fsh");
	//auto fragSource =  cocos2d::FileUtils::getInstance()->getStringFromFile(fragmentFullPath);
	cocos2d::GLProgram* p = cocos2d::ShaderCache::getInstance()->getGLProgram(b ? "Gray" : "Normal");
	if(!p)
	{
		p = cocos2d::GLProgram::createWithByteArrays(cocos2d::ccPositionTextureColor_noMVP_vert, b ? pszFragSource1 : pszFragSource2);  
		cocos2d::ShaderCache::getInstance()->addGLProgram(p, b ? "Gray" : "Normal");
		p->bindAttribLocation(cocos2d::GLProgram::ATTRIBUTE_NAME_POSITION, cocos2d::GLProgram::VERTEX_ATTRIB_POSITION);  
		p->bindAttribLocation(cocos2d::GLProgram::ATTRIBUTE_NAME_COLOR, cocos2d::GLProgram::VERTEX_ATTRIB_COLOR);  
		p->bindAttribLocation(cocos2d::GLProgram::ATTRIBUTE_NAME_TEX_COORD, cocos2d::GLProgram::VERTEX_ATTRIB_TEX_COORDS);  
		p->link(); 
		p->updateUniforms();
	}
	render->setGLProgram(p); 
}

Node* getChildByPath(Node* root, std::string path)
{
	CHECK_RETURN_NULL(root);
	std::vector<std::string> vec;
	CConfAnalytic::StringSplit(path, vec, "/");
	Node* ret = root;
	for(auto v : vec)
	{
		Node* node = ret->getChildByName(v);
		CHECK_RETURN_NULL(node);
		ret = node;
	}
	return ret;
}

Layout* loadJson(const std::string& file)
{
	return dynamic_cast<Layout*>(cocostudio::GUIReader::getInstance()->widgetFromJsonFile(file.c_str()));
}

Widget* getWidget(Node* root, const std::string& path)
{
	return dynamic_cast<Widget*>(getChildByPath(root, path));
}

Text* getText(Node* root, const std::string& path)
{
	return dynamic_cast<Text*>(getWidget(root, path));
}

Layout*	getLayout(Node* root, const std::string& path)
{
	return dynamic_cast<Layout*>(getWidget(root, path));
}

Button* getButton(Node* root, const std::string& path)
{
	return dynamic_cast<Button*>(getWidget(root, path));
}

ImageView* getImageView(Node* root, const std::string& path)
{
	return dynamic_cast<ImageView*>(getWidget(root, path));
}

LoadingBar* getLoadingBar(Node* root, const std::string& path)
{
	return dynamic_cast<LoadingBar*>(getWidget(root, path));
}

ListView* getListView(Node* root, const std::string& path)
{
	return dynamic_cast<ListView*>(getWidget(root, path));
}

PageView* getPageView(Node* root, const std::string& path)
{
	return dynamic_cast<PageView*>(getWidget(root, path));
}

ScrollView* getScrollView(Node* root, const std::string& path)
{
	return dynamic_cast<ScrollView*>(getWidget(root, path));
}
