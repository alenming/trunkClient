#include "cocos2d.h"
#include "PVPSerialize.h"
#include "BattleHelper.h"
USING_NS_CC;

CPVPSerialize::CPVPSerialize(CBattleHelper* battleHelper)
	: m_nRecordCountDown(0)
	, m_nRecordInterval(3)
	, m_nRecordCount(3)
	, m_pCommandBuffData(NULL)
	, m_pBattleHelper(battleHelper)
	//, m_nTest(1)
{
	
}

CPVPSerialize::~CPVPSerialize()
{
	std::map<int, CBufferData*>::iterator iter = m_mapBufferData.begin();
	for (; iter != m_mapBufferData.end(); ++iter)
	{
		CC_SAFE_DELETE(iter->second);
	}
	m_mapBufferData.clear();

    std::list<CBufferData*>::iterator iterDiscard = m_DiscardBuffDataList.begin();
    for (; iterDiscard != m_DiscardBuffDataList.end(); ++iterDiscard)
    {
        CC_SAFE_DELETE(*iterDiscard);
    }
    m_DiscardBuffDataList.clear();

	CC_SAFE_DELETE(m_pCommandBuffData);
}

bool CPVPSerialize::processSerializeByCommand(const BattleCommandInfo& cmd)
{
	// pvp反序列化测试
    //if ((random(1, 5) == 3 || cmd.Tick <= m_pBattleHelper->GameTick) && cmd.CommandId != BattleCommandType::CommandTalk)

    // 延时了, 需要反序列化 (说话的不参与执行战斗逻辑, 可以忽略)
    if (cmd.Tick <= m_pBattleHelper->GameTick && cmd.CommandId != BattleCommandType::CommandTalk)
	{
        // 先清除无效的序列化数据（）
        std::map<int, CBufferData*>::iterator iter = m_mapBufferData.begin();
        for (; iter != m_mapBufferData.end();)
        {
            if (iter->first >= cmd.Tick)
            {
                m_DiscardBuffDataList.push_back(iter->second);
                m_mapBufferData.erase(iter++);
            }
            else
            {
                ++iter;
            }
        }

        // 反序列化
        std::map<int, CBufferData*>::reverse_iterator riter = m_mapBufferData.rbegin();
        if (riter != m_mapBufferData.rend())
        {
            KXLOGBATTLE("======star unserial to gameTick %d========", riter->first);
            unSerializePVPData(riter->second);
        }
        // 没找到符合位置的反序列化数据, 使用上次命令的反序列化数据
        else if (m_pCommandBuffData != NULL)
		{
            KXLOGBATTLE("======star unserial to preCommand ========");
            // 固定序列化数据为空, 才会进命令序列化, 所以不用清除固定间隔的反序列化数据, 直接反序列化命令序列化数据
			unSerializePVPData(m_pCommandBuffData);
		}
        return true;
	}
	else
	{
		// 没有延时, 序列化该数据, 清除其他记录的序列化数据
		serializeCommandBuffData();
		return false;
	}
}

void CPVPSerialize::serializeFixData()
{
    KXLOGBATTLE("======star serial fix data  gameTick %d========", m_pBattleHelper->GameTick);

	// 超过保存条数,则删除旧数据,增加新数据
	if (m_mapBufferData.size() > 0 && m_mapBufferData.size() >= m_nRecordCount)
	{
        m_DiscardBuffDataList.push_back(m_mapBufferData.begin()->second);
		m_mapBufferData.erase(m_mapBufferData.begin());
	}

    // 取出一个buffData
    CBufferData* data = NULL;
    if (m_DiscardBuffDataList.empty())
    {
        data = new CBufferData();
        data->init(65535);
        m_pBattleHelper->serialize(*data);
    }
    else
    {
        std::list<CBufferData*>::iterator iter = m_DiscardBuffDataList.begin();
        data = *iter;
        data->resetDataLength();
        data->setIsReadModel(false);
        m_DiscardBuffDataList.erase(iter);
        m_pBattleHelper->serialize(*data);
    }

	// 设置下次固定序列化时间
	m_nRecordCountDown = m_nRecordInterval;

    // 同一帧上是否有序列化数据, 如果有将其回收(可能不会出现)
    std::map<int, CBufferData*>::iterator iter = m_mapBufferData.find(m_pBattleHelper->GameTick);
    if (iter != m_mapBufferData.end())
    {
        m_DiscardBuffDataList.push_back(iter->second);
    }
	m_mapBufferData[m_pBattleHelper->GameTick] = data;
}

void CPVPSerialize::serializeCommandBuffData()
{
    KXLOGBATTLE("======star serial Command data  gameTick %d, curTick %d========",
        m_pBattleHelper->GameTick, m_pBattleHelper->CurTick);
    // lazy init
    if (NULL == m_pCommandBuffData)
    {
        CBufferData* data = new CBufferData();
        data->init(65535);
        m_pCommandBuffData = data;
    }
    else
    {
        m_pCommandBuffData->resetDataLength();
        m_pCommandBuffData->setIsReadModel(false);
    }
    
    m_pBattleHelper->serialize(*m_pCommandBuffData);

	// 设置下次固定序列化时间
	m_nRecordCountDown = m_nRecordInterval;

	// 清除其他所有序列化数据
	for (std::map<int, CBufferData*>::iterator iter = m_mapBufferData.begin();
		iter != m_mapBufferData.end(); ++iter)
	{
        m_DiscardBuffDataList.push_back(iter->second);
	}
	m_mapBufferData.clear();
}

void CPVPSerialize::unSerializePVPData(CBufferData* data)
{
    // 设置下次固定序列化时间
    m_nRecordCountDown = m_nRecordInterval;
    data->resetOffset();
    data->setIsReadModel(true);
    m_pBattleHelper->unserialize(*data);
	KXLOGBATTLE("======unSerialize over =========");
}

void CPVPSerialize::SaveReconnectData(CBufferData* buffdata)
{
    // 清除定时序列化数据
    std::map<int, CBufferData*>::iterator iter = m_mapBufferData.begin();
    for (; iter != m_mapBufferData.end(); ++iter)
    {
        m_DiscardBuffDataList.push_back(iter->second);
    }
    m_mapBufferData.clear();

    // 重置重连序列化数据
    CC_SAFE_DELETE(m_pCommandBuffData);

    CBufferData* data = new CBufferData();
    if (data->init(buffdata))
    {
        m_pCommandBuffData = data;
    }
    else
    {
        KXLOGBATTLE("CPVPSerialize SaveReconnectData init buffData error!!!!");
        delete data;
    }
}

void CPVPSerialize::unSerializeLastPVPData()
{
    unSerializePVPData(m_pCommandBuffData);
}

void CPVPSerialize::update(float dt)
{
	m_nRecordCountDown -= dt;
	if (m_nRecordCountDown <= 0)
	{
		//超过最大间隔时间, 开始序列化数据
		serializeFixData();
	}
}

