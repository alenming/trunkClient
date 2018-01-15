#include "DisplayCommon.h"
#include "FMODAudioEngine.h"
#include "ConfFight.h"
#include "ConfGameSetting.h"
#include "ConfMusic.h"
#include "CsbLoader.h"

USING_NS_CC;

void getSoundEffect(cocos2d::Node* node, float &pan, float &volume)
{
    if (nullptr != node)
    {
        Node *pParent = node->getParent();
        if (nullptr != pParent)
        {
            float mid = pParent->getPositionX() +
                Director::getInstance()->getWinSize().width;
            float x = node->getPositionX();
            const SoundEffectItem& effectItem = queryConfEffectSetting();
            float dv = 0.0f;
            // 左右声道判断
            if (mid > x)
            {
                dv = mid - x;
                if (dv > effectItem.MissChannel)
                    pan = 1.0f;
            }
            else
            {
                dv = x - mid;
                if (dv > effectItem.MissChannel)
                    pan = -1.0f;
            }
            // 衰减音量计算
            float f = dv / effectItem.VolumeDecayRate / 100.0f;
            volume -= f;
            volume = volume > 1.0f ? 1.0f 
                : volume < 0.0f ? 0.0f : volume;
        }
    }
}

int playMusic(int musicId, float delay, float volume, float track, cocos2d::Node* node)
{
    const AudioItem* pAudioItem = queryConfAudio(musicId);
    if (nullptr == pAudioItem) {
        log("play music error, can't find musicid:%d", musicId);
        return -1;
    }

    std::string path = pAudioItem->AudioPath;
    float pan = track;
    float v = volume;
    if (pAudioItem->isRuleAffect)
    {
        getSoundEffect(node, pan, v);
    }

    if (delay > 0.0f && node != nullptr)
    {
        musicId = CFMODAudioEngine::getInstance()->playEffect(path.c_str(), volume);
        if (musicId > 0)
        {
            CFMODAudioEngine::getInstance()->pauseEffect(musicId);
            auto seq = Sequence::create(DelayTime::create(delay), CallFunc::create([musicId]
            {
                CFMODAudioEngine::getInstance()->resumeEffect(musicId);
            }), nullptr);
        
            node->runAction(seq);
        }
    }
    else
    {
//#if CC_TARGET_PLATFORM != CC_PLATFORM_WIN32
//        musicId = SimpleAudioEngine::getInstance()->playEffect(path.c_str(), isLoop, 1.0, pan, v);
//#else
//        musicId = experimental::AudioEngine::play2d(path, isLoop, volume);
//#endif
        musicId = CFMODAudioEngine::getInstance()->playEffect(path.c_str(), volume);
    }
    return musicId;
}

void playSoundEffect(int effectId)
{
    auto item = reinterpret_cast<CConfUISoundEffect*>(CConfManager::getInstance()->getConf(CONF_SOUND_EFFECT));
    if (NULL != item)
    {
        std::string path = "";
        if (item->getEffectPath(effectId, path))
        {
            //SimpleAudioEngine::getInstance()->playEffect(path.c_str());
            CFMODAudioEngine::getInstance()->playEffect(path.c_str());
        }
    }
}

void playUISoundEffect(cocos2d::Node* node)
{
    if (NULL == node)
    {
        return;
    }

    auto buttonItem = reinterpret_cast<CConfUIButtonEffect*>(CConfManager::getInstance()->getConf(CONF_BUTTON_EFFECT));
    if (NULL == buttonItem)
    {
        return;
    }

    playSoundEffect(buttonItem->getButtonEffectId(node->getName()));
}

bool playCsbAnimation(cocos2d::Node* node, const std::string& animation, bool loop)
{
    auto action = getCsbAnimation(node);
    if (action && action->IsAnimationInfoExists(animation))
    {
        action->play(animation, loop);
        return true;
    }
    return false;
}

cocostudio::timeline::ActionTimeline* getCsbAnimation(cocos2d::Node* root)
{
    if (root)
    {
        return dynamic_cast<cocostudio::timeline::ActionTimeline*>(
            root->getActionByTag(root->getTag()));
    }
    return nullptr;
}

// 跳转到CSB动画指定的百分比
void gotoCsbAnimationPercent(cocostudio::timeline::ActionTimeline* ani, const char* name, float percent)
{
    if (ani && ani->IsAnimationInfoExists(name))
    {
        auto info = ani->getAnimationInfo(name);
        int frame = static_cast<int>((info.endIndex - info.startIndex) * percent);
        frame += info.startIndex;
        ani->gotoFrameAndPause(frame);
    }
}

void updateGrobleZOrder(Node* node, float zorder)
{
    node->setGlobalZOrder(zorder);
    for (auto& n : node->getChildren())
    {
        updateGrobleZOrder(n, zorder);
    }
}
