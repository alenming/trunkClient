#include "EffectFactory.h"
#include "ConfOther.h"
#include "ArmatureEffect.h"
#include "SpineEffect.h"
#include "ResManager.h"
#include "DisplayCommon.h"
#include "CsbEffect.h"
#include "SimpleShader.h"
#include "FMODAudioEngine.h"
#include "ResPool.h"
using namespace std;
USING_NS_CC;

CEffectFactory::CEffectFactory()
{
}


CEffectFactory::~CEffectFactory()
{
}

bool CEffectFactory::createEffectsToNode(const VecInt& effIds, Node* parent, int dir, int zorder, float delay, Vec2 pos)
{
    if (NULL == parent || effIds.size() == 0)
    {
        return false;
    }

    for (auto iter : effIds)
    {
        auto eff = CEffectFactory::create(iter, dir, zorder, delay);
        if (NULL == eff)
        {
            return false;
        }
        eff->setPosition(pos);
        parent->addChild(eff);
    }

    return true;
}

CEffect* CEffectFactory::create(int effId, int dir, int zorder, float delay)
{
	// 1.查询配置
	const EffectConfItem* pConf = queryConfEffect(effId);
	if (NULL == pConf)
	{
		LOG("Config can't find Eff %d", effId);
		return NULL;
	}

	//LOG("Create Eff %d", effId);
	const SResPathItem *pResInfo = queryConfSResInfo(pConf->ResID);
	if (NULL == pResInfo)
	{
        return nullptr;
	}

    CEffect *pNode = NULL;
	// 2.加载骨骼(aramature & spine)
	if (RT_ARMATURE == pResInfo->ResType)
	{
		CArmatureEffect* eff = new CArmatureEffect();
        if (!eff->init(dir, pConf))
		{
			eff->release();
			return NULL;
		}

		pNode = eff;
	}
	else if (RT_SPINE == pResInfo->ResType)
	{
		CSpineEffect* eff = new CSpineEffect();
        if (!eff->init(dir, pConf, pResInfo->Path))
		{
			eff->release();
			return NULL;
		}

		pNode = eff;
	}
    else if (RT_CSB2 == pResInfo->ResType)
    {
        CCsbEffect* eff = new CCsbEffect();
        if (!eff->init(dir, pConf, pResInfo->Path))
        {
            eff->release();
            return NULL;
        }
        pNode = eff;
    }
	else
	{
		return NULL;
	}

    // 色相
    if (3 == pConf->AddColor.size())
    {
        CSimpleShader::applyHSVShader(pNode->getEffectNode()
            , Vec3(pConf->AddColor[0], pConf->AddColor[1], pConf->AddColor[2]));
    }

    // 0本地 1全局 2继承
    // 全局ZOrder在具体的Effect对象中设置
    switch (pConf->ZOrderType)
    {
    case EffZOrderLocal:
        pNode->setLocalZOrder(pConf->ZOrder);
        break;
    case EffZOrderInherit:
        pNode->setLocalZOrder(zorder + pConf->ZOrder);
        break;
    default:
        break;
    }

    // 设置自动释放
	pNode->autorelease();
	if (delay > 0.0f)
	{
		auto act = Sequence::create(
			DelayTime::create(delay),
            RemoveSelf::create(true), NULL);
		pNode->runAction(act);
	}
    else if (pConf->LifeTime > 0.0f)
    {
        if (pConf->FadeOutTime > 0.0f)
        {
            auto act = Sequence::create(
                DelayTime::create(pConf->LifeTime), 
                FadeOut::create(pConf->FadeOutTime),
                RemoveSelf::create(true), NULL);
            pNode->runAction(act);
        }
        else
        {
            auto act = Sequence::create(
                DelayTime::create(pConf->LifeTime),
                RemoveSelf::create(true), NULL);
            pNode->runAction(act);
        }
    }

    // 播放音效
    if (pConf->MusicInfos.size() > 0)
    {
        vector<int> musicVec;
        for (unsigned int i = 0; i < pConf->MusicInfos.size(); ++ i)
        {
            const MusicInfo& info = pConf->MusicInfos[i];
            int musicId = playMusic(info.MusicId, info.MusicDelay, info.Volume, info.Track, pNode);
            if (info.IsClose && musicId > 0)
            {
                musicVec.push_back(musicId);
            }
        }
        if (musicVec.size() > 0)
        {
            pNode->setOnExitCallback([musicVec]
            {
                for (auto& musicId : musicVec)
                {
                    //#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
                    //    SimpleAudioEngine::getInstance()->stopEffect(musicId);
                    //#else
                    //    experimental::AudioEngine::stop(musicId);
                    //#endif
                    CFMODAudioEngine::getInstance()->stopEffect(musicId);
                }
            });
        }
    }

	return pNode;
}

CEffect* CEffectFactory::createEffect(int resID)
{
	const SResPathItem *pResInfo = queryConfSResInfo(resID);
	if (NULL == pResInfo)
	{
		return nullptr;
	}

	CEffect *pEffect = NULL;
	// 加载骨骼(aramature & spine)
	if (RT_ARMATURE == pResInfo->ResType)
	{
		CArmatureEffect* eff = new CArmatureEffect();
		if (!eff->init(pResInfo->ResName))
		{
			eff->release();
			return NULL;
		}
		pEffect = eff;
	}
	else if (RT_SPINE == pResInfo->ResType)
	{
		CSpineEffect* eff = new CSpineEffect();
        if (!eff->init(pResInfo->Path))
		{
			eff->release();
			return NULL;
		}
		pEffect = eff;
	}
	else if (RT_CSB2 == pResInfo->ResType)
	{
        CCsbEffect* eff = new CCsbEffect();
        if (!eff->init(pResInfo->Path))
		{
			eff->release();
			return NULL;
		}
		pEffect = eff;
	}
	else
	{
		return NULL;
	}

	pEffect->autorelease();
	return pEffect;
}