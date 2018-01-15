#include "CsvLoader.h"
#include "CommTools.h"

#ifndef RunningInServer

#include "cocos2d.h"
#include "xxtea/xxtea.h"
USING_NS_CC;

#endif

using namespace std;

CCsvLoader::CCsvLoader()
{
    m_nDocOffset = 0;
    m_nDocStep = 0;
    m_nLineOffset = 0;
    m_nLineStep = 0;
}


CCsvLoader::~CCsvLoader()
{
}

void CCsvLoader::Release()
{
	m_nDocOffset = 0;
	m_nDocStep = 0;
	m_nLineOffset = 0;
	m_nLineStep = 0;
	m_CurLine = "";
	m_Document = "";
}

bool CCsvLoader::LoadCSV(const char* fileName)
{
    if (NULL == fileName)
    {
        return false;
    }

#ifndef RunningInServer

	auto fileUtils = FileUtils::getInstance();
	if (!fileUtils->isFileExist(fileName)) {
		string fname(fileName);
		size_t pos = fname.find_last_of('.');
		if (pos != string::npos) {
			fname.replace(pos, 4, ".csve");		// ".csv" -> ".csve"
		}
		else {
			fname += ".cvse";
		}
		auto encrypted = fileUtils->getDataFromFile(fname);
        if (!encrypted.isNull())
        {
            string key("fanhougame_zhs");
            xxtea_long len;
            auto decrypted = xxtea_decrypt((unsigned char *)encrypted.getBytes(), encrypted.getSize(), (unsigned char *)key.c_str(), key.length(), &len);
            m_Document = string((const char *)decrypted);
        }
	}
	else {
		m_Document = fileUtils->getStringFromFile(fileName);
	}

#else
    m_Document = getStringFromFile(fileName);
#endif

    m_nDocOffset = m_nDocStep = 0;
    
    //如果文件为空也会返回失败
    return NextLine();
}

// NextLine会跳转至下一行
// 返回false表示已经到了尾部，返回true表示读到了新的一行数据
bool CCsvLoader::NextLine()
{
skipline:
    // 换行这里需要考虑\r\n的问题
    m_nDocStep = m_Document.find_first_of('\n', m_nDocOffset);

    if (-1 == m_nDocStep)
    {
        // 这里还需要考虑最后一行找不到\n的情况
        if (m_nDocOffset < m_Document.size())
        {
            // 将最后剩余的一行内容取出
            m_CurLine = m_Document.substr(m_nDocOffset, m_Document.size() - m_nDocOffset);
            m_nDocOffset = m_Document.size();
            m_nLineOffset = 0;
            if (isCurrentLineNull())
            {
                return false;
            }
            return true;
        }
        return false;
    }

    if (m_Document.at(m_nDocStep - 1) == '\r')
    {
        m_CurLine = m_Document.substr(m_nDocOffset, m_nDocStep - m_nDocOffset - 1);
    }
    else
    {
        m_CurLine = m_Document.substr(m_nDocOffset, m_nDocStep - m_nDocOffset);
    }
	m_nLineOffset = 0;
	m_nDocOffset = m_nDocStep + 1;

	if (isCurrentLineNull())
	{
		goto skipline;
	}
	else
	{
		return true;
	}
}

std::string CCsvLoader::LeftStr()
{
    return m_CurLine.substr(m_nLineOffset, m_CurLine.size() - m_nLineOffset);;
}

// 将当前行下一个字段解析为string并返回
// 如果解析失败返回""
std::string CCsvLoader::NextStr()
{
	m_nLineStep = m_CurLine.find_first_of(',', m_nLineOffset);
	string seg = m_CurLine.substr(m_nLineOffset, m_nLineStep - m_nLineOffset);
	m_nLineOffset = m_nLineStep + 1;
	return Trim(seg);
}

// 将当前行下一个字段解析为int并返回
// 如果解析失败返回0
int CCsvLoader::NextInt()
{
	return atoi(NextStr().c_str());
}

// 将当前行下一个字段解析为float并返回
// 如果解析失败返回0.0f
float CCsvLoader::NextFloat()
{
    return static_cast<float>(toolToNum<float>(NextStr().c_str()));
}

std::string CCsvLoader::Trim(std::string str)
{
	if (str.empty())
	{
		return str;
	}
	size_t posL = str.find_first_not_of(' ');
    size_t posR = str.find_last_not_of(' ');
    if ((posL == string::npos && posR == string::npos)
        || (0 == posL && (str.size()-1) == posR))
	{
		return str;
	}
	string ret = str.substr(posL, posR - posL + 1);
	return ret;
}

bool CCsvLoader::isCurrentLineNull()
{
	for (size_t i = 0; i < m_CurLine.length(); ++i)
	{
		switch (m_CurLine.c_str()[i])
		{
		case ' ':
		case ',':
		case '\n':
		case '\r':
			break;
			
		default:
			return false;
			break;
		}
	}
	return true;
}

// 将一个字符串以分隔符 sep 分隔开，转换为字符串，填入vector容器中
bool CCsvLoader::SplitStrToVector(const std::string &str, char sep, std::vector<std::string>& out)
{
    int pos = 0;
    int step = 0;

    while (pos < static_cast<int>(str.length()) && step != -1)
    {
        step = str.find_first_of(sep, pos);
        string seg = str.substr(pos, step);
        out.push_back(seg);
        pos = step + 1;
    }

    return out.size() > 0;
}

// 将一个字符串以分隔符 sep 分隔开，转换为float，填入vector容器中
bool CCsvLoader::SplitFloatToVector(const std::string &str, char sep, std::vector<float>& out)
{
    int pos = 0;
    int step = 0;

    while (pos < static_cast<int>(str.length()) && step != -1)
    {
        step = str.find_first_of(sep, pos);
        string seg = str.substr(pos, step);
        float value = static_cast<float>(toolToNum<float>(seg.c_str()));
        out.push_back(value);
        pos = step + 1;
    }

    return out.size() > 0;
}

// 将一个字符串以分隔符 sep 分隔开，转换为int，填入vector容器中
bool CCsvLoader::SplitIntToVector(const std::string &str, char sep, std::vector<int>& out)
{
    int pos = 0;
    int step = 0;

    while (static_cast<unsigned int>(pos) < str.length() && step != -1)
    {
        step = str.find_first_of(sep, pos);
        string seg = str.substr(pos, step);
        int value = atoi(seg.c_str());
        out.push_back(value);
        pos = step + 1;
    }

    return out.size() > 0;
}

std::string CCsvLoader::getStringFromFile(const std::string &path)
{
    FILE *fp = fopen(path.c_str(), "rt");
    if (NULL == fp)
    {
        return "";
    }

    char* buffer = NULL;
    int size = 0;
    int readsize = 0;

    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    buffer = (char*)malloc(sizeof(char) * (size + 1));
    buffer[size] = '\0';

    readsize = fread(buffer, sizeof(unsigned char), size, fp);
    fclose(fp);

    std::string ret(buffer);
    return ret;
}
