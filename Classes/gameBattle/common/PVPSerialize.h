/*
处理pvp游戏延迟后, 反序列化的处理
*/
#ifndef __PVPSERIALIZE_H__
#define __PVPSERIALIZE_H__

#include <map>
#include "CommStructs.h"
#include "BufferData.h"

class CBattleHelper;

class CPVPSerialize
{
public:
	CPVPSerialize(CBattleHelper* battleHelper);
	~CPVPSerialize();

	// 接受到命令, 判断是否需要序列化和反序列化
	bool processSerializeByCommand(const BattleCommandInfo& cmd);
	// 固定间隔序列化数据
	void serializeFixData();
	// 命令序列化数据
	void serializeCommandBuffData();
	// 反序列化数据
	void unSerializePVPData(CBufferData* data);
    // 重连后, 保存重连时刻的序列化数据, 清除时间序列化数据
    void SaveReconnectData(CBufferData* data);
    // 反序列化最新的数据
    void unSerializeLastPVPData();

	// 数据更新处理
	void update(float dt);

private:
	float m_nRecordCountDown;		// 开始序列化数据倒计时
	float m_nRecordInterval;		// 序列化数据单个记录最大间隔时间
	int m_nRecordCount;				// 备份反序列化数据最大个数
    //int m_nTest;

	CBattleHelper* m_pBattleHelper;

	// 最新的插入命令处的序列化数据
	CBufferData* m_pCommandBuffData;

	// 固定间隔的序列化数据<GameTick, 序列化数据>
	std::map<int, CBufferData*> m_mapBufferData;
    std::list<CBufferData*> m_DiscardBuffDataList;  // 废弃的buffdata
};

#endif