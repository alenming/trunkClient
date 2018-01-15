/************************************************************************
FMOD音乐播放引擎                                                         
注意：1、fmod的库带L的为debug模式使用，否则是release
     2、fmod的库分32位和64位
     3、需要在主循环中调用update方法

2016-7-29                                                        
************************************************************************/

#ifndef __FMOD_AUDIO_ENGINE_H__
#define __FMOD_AUDIO_ENGINE_H__

#include "fmod/include/fmod_studio.hpp"
#include "cocos2d.h"

class CFMODAudioEngine
{
private:
    CFMODAudioEngine();
    ~CFMODAudioEngine();

public:
    static CFMODAudioEngine *getInstance();
    static void destory();

    static const int INVALID_AUDIO_ID;

    /** 加载bank文件
    * @param bank文件
    * @return true为加载成功,false为失败
    */
    bool loadBankFile(const char *bankFile);
    
    /** 卸载bank文件
    * @param bank文件
    * @return true为卸载成功,false为失败
    */
    bool unloadBankFile(const char *bankFile);

    /** 每一帧调用
    */
    void update();

    /** 播放背景音乐
    * @param 背景音乐路径,如event:/Music/city,FMOD Studio中查看
    */
    void playBackgroundMusic(const char *musicPath);

    /** 停止背景音乐
    */
    void stopBackgroundMusic();
    
    /** 设置背景音乐参数
    * @param 属性名称,如level,fmod studio中查看
    * @param 值
    */
    void setBackgroundMusicParam(const char *param, float value);

    /** 播放音效
    * @param 音效路径,如event:/UI/Click0,FMOD Studio中查看
    * @param 音量值
    */
    int playEffect(const char *eventPath, float volume = 1.0);

    /** 根据参数设置播放音效
    * @param 音效路径,如event:/UI/Click0,FMOD Studio中查看
    * @param 属性名称
    * @param 值
    */
    int playEffectWithParam(const char *eventPath, const char *param, float value);

    /** 获取音量
    * @return 音量大小0-1
    */
    float getMusicVolume();

    /** 设置音量
    * @param 值0-1
    */
    void setMusicVolume(float volume);

    /** 设置背景音乐是否暂停
    * @param 布尔值,true为暂停，false恢复
    */
    void setPaused(bool isPause);

    /* 背景音乐是否在播放
    * @return 播放中true，否则false
    */
    bool isBackgroundMusicPlaying();

    /** 恢复音效
    * @param 调用playEffect返回的音效ID
    */
    void resumeEffect(unsigned int soundId);

    /** 暂停音效
    * @param 调用playEffect返回的音效ID
    */
    void pauseEffect(unsigned int soundId);

    /** 停止音效
    * @param 调用playEffect返回的音效ID
    */
    void stopEffect(unsigned int soundId);

    /** 清除所有音效
    */
    void clearAllEffects();

    /* 设置是否关闭音效
    */
    void setOpenEffect(bool isOpen);

    /* 暂停线程
    */
    void mixerSuspend();

    /* 恢复线程
    */
    void mixerResume();

protected:

    /** 获取音乐事件对象
    * @param 音乐路径,如event:/Music/city,fmod studio中查看
    * @return EventInstance对象
    */
    FMOD::Studio::EventInstance *getEventInstance(const char *eventPath);

    /** 获取系统
    * @return System对象 唯一
    */
    FMOD::Studio::System *getStudioSystem();

    /** 释放系统
    */
    void endStudioSystem();

    /* 获取音效名字,去掉路径
    * @return 音效名字
    */
    std::string getFileName(std::string path);

protected:
    static CFMODAudioEngine *m_pInstance;

    bool m_bIsOpenEffect;                                     // 是否开启音效
    int m_nCurrentAudioID;                                    // 当前音效ID,递增
    std::map<int, FMOD::Studio::EventInstance*> m_mapEffects; // 音效列表<soundId, 对象>
    std::map<std::string, int> m_mapEffectNames;              // 音效资源列表<音效名, soundId>
};

#endif //__FMOD_AUDIO_ENGINE_H__
