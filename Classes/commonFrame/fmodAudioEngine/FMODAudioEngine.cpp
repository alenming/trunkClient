#include "FMODAudioEngine.h"
#include <assert.h>
#include "KxCSComm.h"

using namespace FMOD::Studio;

#define CHECK_RESULT(result) assert(result == FMOD_OK)
#define CHECK_RESULT_LOG(result) { \
    if (FMOD_OK != result) {            \
        LOG("Execute False On File %s Line %d : %s", __FILE__, __LINE__, #result); \
    }									\
}

static System *gSystem = nullptr;
static EventInstance *gMusicEvent = nullptr;

const int CFMODAudioEngine::INVALID_AUDIO_ID = -1;

CFMODAudioEngine *CFMODAudioEngine::m_pInstance = nullptr;
CFMODAudioEngine::CFMODAudioEngine() :m_nCurrentAudioID(0)
, m_bIsOpenEffect(false)
{

}

CFMODAudioEngine::~CFMODAudioEngine()
{

}

System *CFMODAudioEngine::getStudioSystem()
{
    if (gSystem == nullptr)
    {
        FMOD_RESULT result = System::create(&gSystem);
        CHECK_RESULT(result);

        FMOD::System *lowLevelSystem;
        result = gSystem->getLowLevelSystem(&lowLevelSystem);
        CHECK_RESULT(result);

        // 注：如果出现声音抖动可以将第一个参数调大，512、1024、2048、4096。
        result = lowLevelSystem->setDSPBufferSize(1024, 4);
        CHECK_RESULT(result);

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
        result = gSystem->initialize(32, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, 0);
#else
        result = gSystem->initialize(32, FMOD_STUDIO_INIT_NORMAL, FMOD_INIT_NORMAL, 0);
#endif
        CHECK_RESULT(result);
    }

    return gSystem;
}

void CFMODAudioEngine::endStudioSystem()
{
    if (gSystem)
    {
        FMOD_RESULT result = gSystem->release();
        CHECK_RESULT(result);

        gSystem = nullptr;
    }
}

void CFMODAudioEngine::playBackgroundMusic(const char *musicPath)
{
    stopBackgroundMusic();

    gMusicEvent = getEventInstance(musicPath);
    if (gMusicEvent)
    {
        FMOD_RESULT result = gMusicEvent->start();
        CHECK_RESULT_LOG(result);
    }
}

void CFMODAudioEngine::stopBackgroundMusic()
{
    if (gMusicEvent)
    {
        FMOD_RESULT result = gMusicEvent->stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
        CHECK_RESULT_LOG(result);

        result = gMusicEvent->release();
        CHECK_RESULT_LOG(result);

        gMusicEvent = nullptr;
    }
}

void CFMODAudioEngine::setBackgroundMusicParam(const char *param, float value)
{
    if (gMusicEvent)
    {
        FMOD_RESULT result = gMusicEvent->setParameterValue(param, value);
        if (FMOD_OK != result)
        {
            LOG("setBackgroundMusicParam fail, param:%s, result:%d", param, result);
        }
    }
}

EventInstance *CFMODAudioEngine::getEventInstance(const char *eventPath)
{
    EventDescription *desc;
    FMOD_RESULT result = getStudioSystem()->getEvent(eventPath, &desc);
    if (FMOD_OK != result)
    {
        LOGINFO("getEvent %s fail!", eventPath);
        return nullptr;
    }

    EventInstance *inst = nullptr;
    result = desc->createInstance(&inst);
    CHECK_RESULT_LOG(result);

    return inst;
}

int CFMODAudioEngine::playEffect(const char *eventPath, float volume/* = 1.0*/)
{
    if (!m_bIsOpenEffect)
    {
        return 0;
    }

    EventInstance *eventInstance = getEventInstance(eventPath);
    if (nullptr == eventInstance)
    {
        return -1;
    }

    eventInstance->setVolume(volume);
    FMOD_RESULT result = eventInstance->start();
    CHECK_RESULT_LOG(result);

    ++m_nCurrentAudioID;
    m_mapEffectNames[eventPath] = m_nCurrentAudioID;
    m_mapEffects[m_nCurrentAudioID] = eventInstance;

    return m_nCurrentAudioID;
}

int CFMODAudioEngine::playEffectWithParam(const char *eventPath, const char *param, float value)
{
    if (!m_bIsOpenEffect)
    {
        return 0;
    }

    EventInstance *eventInstance = getEventInstance(eventPath);
    if (nullptr == eventInstance)
    {
        return -1;
    }

    FMOD_RESULT result = eventInstance->setParameterValue(param, value);
    CHECK_RESULT_LOG(result);

    result = eventInstance->start();
    CHECK_RESULT_LOG(result);

    ++m_nCurrentAudioID;
    m_mapEffectNames[eventPath] = m_nCurrentAudioID;
    m_mapEffects[m_nCurrentAudioID] = eventInstance;

    return m_nCurrentAudioID;
}

bool CFMODAudioEngine::loadBankFile(const char *bankFile)
{
    Bank *bank;
    FMOD_RESULT result;
    auto data = cocos2d::FileUtils::getInstance()->getDataFromFile(bankFile);
    result = getStudioSystem()->loadBankMemory(reinterpret_cast<char*>(data.getBytes()), data.getSize(),
        FMOD_STUDIO_LOAD_MEMORY, FMOD_STUDIO_LOAD_BANK_NORMAL, &bank);
    //CCLOG("load bank %s result %d", bankFile, result);

    return FMOD_OK == result;
}

bool CFMODAudioEngine::unloadBankFile(const char *bankFile)
{
    Bank *bank;
    std::string file = getFileName(bankFile);
    if (FMOD_OK == gSystem->getBank(file.c_str(), &bank))
    {
        return FMOD_OK == bank->unload();
    }
    
    return false;
}

void CFMODAudioEngine::update()
{
    FMOD_RESULT result = getStudioSystem()->update();
    //CCLOG("CFMODAudioEngine::update result %d", result);
    CHECK_RESULT(result);
}

float CFMODAudioEngine::getMusicVolume()
{
    float volume = 0.0f;

    if (gMusicEvent)
    {
        FMOD_RESULT result = gMusicEvent->getVolume(&volume);
        CHECK_RESULT_LOG(result);
    }

    return volume;
}

void CFMODAudioEngine::setMusicVolume(float volume)
{
    if (gMusicEvent)
    {
        if (volume < 0.0f) 
            volume = 0.0f;
        else if (volume > 1.0f)
            volume = 1.0f;

        FMOD_RESULT result = gMusicEvent->setVolume(volume);
        CHECK_RESULT_LOG(result);
    }
}

CFMODAudioEngine * CFMODAudioEngine::getInstance()
{
    if (nullptr == m_pInstance)
    {
        m_pInstance = new CFMODAudioEngine;
    }
    
    return m_pInstance;
}

void CFMODAudioEngine::destory()
{
    if (nullptr != m_pInstance)
    {
        m_pInstance->endStudioSystem();

        delete m_pInstance;
        m_pInstance = nullptr;
    }
}

void CFMODAudioEngine::setPaused(bool isPause)
{
    if (gMusicEvent)
    {
        bool pause = false;
        FMOD_RESULT result = gMusicEvent->getPaused(&pause);
        CHECK_RESULT_LOG(result);
        if (pause == isPause)
        {
            return;
        }
        
        result = gMusicEvent->setPaused(isPause);
        CHECK_RESULT_LOG(result);
    }
}

bool CFMODAudioEngine::isBackgroundMusicPlaying()
{
    FMOD_STUDIO_PLAYBACK_STATE state = FMOD_STUDIO_PLAYBACK_FORCEINT;
    if (gMusicEvent)
    {
        FMOD_RESULT result = gMusicEvent->getPlaybackState(&state);
        CHECK_RESULT_LOG(result);
    }
    
    return FMOD_STUDIO_PLAYBACK_PLAYING == state;
}

void CFMODAudioEngine::resumeEffect(unsigned int soundId)
{
    auto iter = m_mapEffects.find(soundId);
    if (iter != m_mapEffects.end())
    {
        iter->second->setPaused(false);
    }
}

void CFMODAudioEngine::pauseEffect(unsigned int soundId)
{
    auto iter = m_mapEffects.find(soundId);
    if (iter != m_mapEffects.end())
    {
        iter->second->setPaused(true);
    }
}

void CFMODAudioEngine::stopEffect(unsigned int soundId)
{
    auto iter = m_mapEffects.find(soundId);
    if (iter != m_mapEffects.end())
    {
        iter->second->stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
    }
}

void CFMODAudioEngine::clearAllEffects()
{
    for (auto &effect : m_mapEffects)
    {
        auto &inst = effect.second;
        if (inst)
        {
            inst->stop(FMOD_STUDIO_STOP_ALLOWFADEOUT);
            inst->release();
        }
    }
    
    m_mapEffects.clear();
    m_mapEffectNames.clear();
}

std::string CFMODAudioEngine::getFileName(std::string path)
{
    int pos = path.find_last_of('/');
    if (std::string::npos != pos)
    {
        return path.substr(pos + 1, path.length() - pos);
    }
    
    return path;
}

void CFMODAudioEngine::setOpenEffect(bool isOpen)
{
    m_bIsOpenEffect = isOpen;
}

void CFMODAudioEngine::mixerSuspend()
{
    FMOD::System *pLowSystem;
    FMOD_RESULT result = getStudioSystem()->getLowLevelSystem(&pLowSystem);
    CHECK_RESULT(result);

    result = pLowSystem->mixerSuspend();
    CHECK_RESULT_LOG(result);
}

void CFMODAudioEngine::mixerResume()
{
    FMOD::System *pLowSystem;
    FMOD_RESULT result = getStudioSystem()->getLowLevelSystem(&pLowSystem);
    CHECK_RESULT(result);

    result = pLowSystem->mixerResume();
    CHECK_RESULT_LOG(result);
}
