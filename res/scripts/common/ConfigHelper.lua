require "configlua.allcfg"

----------------- Union目录 begin -----------------

-- 公会远征
function getExpeditionConf()
    return Cfg_Expedition
end

function getExpeditionItem(areaId)
	return Cfg_Expedition[areaId]
end

-- 先驱者日志
function getExpeditionBookItem(id)
	local cfg = Cfg_ExpeditionBook[id]
	if cfg then
		local newRole = {}
		for _, v in ipairs(cfg.Role) do
			if v.RoleMapID ~= 0 then
				table.insert(newRole, v)
			end
		end
		cfg.Role = newRole

		return cfg
	end
end

cpp_getUnionLevelConfItem = getUnionLevelConfItem
function getUnionLevelConfItem(lv)
	return Cfg_UnionLevelSetting[lv]
end

cpp_getUnionConfItem = getUnionConfItem
function getUnionConfItem()
	return Cfg_UnionSetting[1]
end

-- 获取公会远征地图配表
cpp_getExpeditionMapConf = getExpeditionMapConf
function getExpeditionMapConf(id)
	local cfg = Cfg_ExpeditionMap[id]
	if cfg then
		local newStages = {}
		for _, v in ipairs(cfg.Stages) do
			if v.stage and v.stage[1] and v.stage[1] > 0 then	-- 关卡ID
				v.stageID = v.stage[1]
				v.stageLv = v.stage[2]
				v.stage = nil
			end

			if v.stageID then
				table.insert(newStages, v)
			end
		end
		cfg.Stages = newStages

		return cfg
	end
end

-- 公会会徽
cpp_getUnionBadgeConfItem = getUnionBadgeConfItem
function getUnionBadgeConfItem()
	local ret = {}
	for _, v in pairs(Cfg_UnionBadge) do
		ret[v.badge_id] = v.badge_res
	end
	return ret
end

----------------- Union目录 end -----------------

---------------- GameSetting目录 begin ---------------

function getEquipmentSetting()
	return Cfg_EquipmentSetting
end

function getEquipmentForCast()
	return Cfg_EquipmentForCast
end

function getMercenaryNumber()
	return Cfg_MercenaryNumber
end

-- 抽卡相关
cpp_getCardGambleSettingConfItem = getCardGambleSettingConfItem
function getCardGambleSettingConfItem()
	local cfg = Cfg_CardGambleSetting[1]
	for i = 1, #cfg.StarProb do
		local item = cfg.StarProb[i]
		if not item.Prob then
			item.Prob = {
				Probability = item[1],
				Ratio = item[2]
			}
			item[1], item[2] = nil, nil
		end
	end
	return cfg
end

-- 技能升级相关
cpp_getSkillUpRateSettingConfItem = getSkillUpRateSettingConfItem
function getSkillUpRateSettingConfItem(lv)
	return Cfg_SkillUpRateSetting[lv]
end

-- 士兵等级相关
cpp_getSoldierLevelSettingConfItem = getSoldierLevelSettingConfItem
function getSoldierLevelSettingConfItem(lv)
	return Cfg_SoldierLevelSetting[lv]
end

-- 任务成就相关
cpp_getTaskAcheveSettingConfItem = getTaskAcheveSettingConfItem
function getTaskAcheveSettingConfItem()
	return Cfg_TaskAndAchievementSetting[1]
end

-- 获取 玩家最高等级
cpp_getUserMaxLevel = getUserMaxLevel
function getUserMaxLevel()
	return #Cfg_UserLevelSetting
end

-- 玩家等级相关
cpp_getUserLevelSettingConfItem = getUserLevelSettingConfItem
function getUserLevelSettingConfItem(lv)
	return Cfg_UserLevelSetting[lv]
end

-- 获取 竞技场配置
cpp_getArenaSetting = getArenaSetting
function getArenaSetting()
	return Cfg_ArenaSettings[1]
end

-- 获取 时间恢复设置
cpp_getTimeRecoverSetting = getTimeRecoverSetting
function getTimeRecoverSetting()
	return Cfg_TimeRecover[1]
end

cpp_getTowerSetting = getTowerSetting
function getTowerSetting()
	return Cfg_TowerSetting[1]
end

-- 获取 购买消耗表主键
cpp_getIncreasePayItemList = getIncreasePayItemList
function getIncreasePayItemList()
	local list = CommonHelper.getKeys(Cfg_IncreasePaymentPriceSetting)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 购买消耗表
cpp_getIncreasePayConfItem = getIncreasePayConfItem
function getIncreasePayConfItem(buyTimes)
	return Cfg_IncreasePaymentPriceSetting[buyTimes]
end

-- 获取 系统头像配置
cpp_getSystemHeadIconItem = getSystemHeadIconItem
function getSystemHeadIconItem()
	return Cfg_SystemHeadIcon
end

-- 新玩家 最大背包, 最大卡包数据
cpp_getNewPlayerSettingConf = getNewPlayerSettingConf
function getNewPlayerSettingConf()
	return Cfg_NewPlayerSetting[1]
end

-- 获取 竞技场段位配置
cpp_getArenaRankItem = getArenaRankItem
function getArenaRankItem(rankScore)
	for _, v in pairs(Cfg_ArenaRank) do
		if rankScore >= v.GNRank[1] and rankScore < v.GNRank[2] then
			return v
		end
	end
end

-- 获取竞技场段位配置
function getArenaRankItemByLevel(level)
	return Cfg_ArenaRank[level]
end

-- 获取竞技场段位
function getArenaTLevel(score)
	for i, v in pairs(Cfg_ArenaRank) do
		if score >= v.GNRank[1] and score < v.GNRank[2] then
			return i
		end
	end
	return #Cfg_ArenaRank
end

-- 获取Cfg_ArenaRank的主键列表
function getArenaRankIndexList()
	local list = {}
	for k, _ in ipairs(Cfg_ArenaRank) do
		table.insert(list, k)
	end
	return list
end

-- 获取装备最大属性个数
cpp_getEquipPropMaxCount = getEquipPropMaxCount
function getEquipPropMaxCount(quality)
	local cfg = Cfg_EquipmentSetting[quality]
	if cfg then
		return cfg.Eq_AttributeMax
	end
end

-- 获取 聊天配置
cpp_getChatSetting = getChatSetting
function getChatSetting()
	return Cfg_ChatSetting[1]
end

-- 获取 道具外框配置
cpp_getItemLevelSettingItem = getItemLevelSettingItem
function getItemLevelSettingItem(quality)
	return Cfg_ItemLevelSetting[quality]
end

-- 获取 随机名字库配置
cpp_getSysAutoNameConf = getSysAutoNameConf
function getSysAutoNameConf()
	local ret = {}
	for _, cfg in ipairs(Cfg_SysAutoName) do
		if not ret[cfg.CharacterID] then
			ret[cfg.CharacterID] = {}
		end

		table.insert(ret[cfg.CharacterID], cfg.content)
	end
	return ret
end

function getAllPushIds()
	local list = CommonHelper.getKeys(Cfg_Push)
	table.sort(list, function (a, b)
		return a < b
	end)
	return list
end

function getPushItem(id)
	return Cfg_Push[id]
end

function getExpressionSetting()
	return Cfg_ExpressionSetting
end

---------------- GameSetting目录 end ---------------

----------------- Guide目录 begin -----------------

-- 获取 UI节点
cpp_getUINodeConfItem = getUINodeConfItem
function getUINodeConfItem(id)
	return Cfg_UINode[id]
end

-- 获取 UI节点 主键
cpp_getUINodeItemList = getUINodeItemList
function getUINodeItemList()
	local list = CommonHelper.getKeys(Cfg_UINode)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 UI状态
cpp_getUIStatusConfItem = getUIStatusConfItem
function getUIStatusConfItem(id, count)
	for _, cfg in pairs(Cfg_UIStatus) do
		if cfg.UIID == id and cfg.ButtonLockCount == count then
			return cfg
		end
	end
end

-- 获取 UI状态 主键
cpp_getUIStatusItemList = getUIStatusItemList
function getUIStatusItemList()
	local list = CommonHelper.getKeys(Cfg_UIStatus)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 引导表
cpp_getGuideConfItem = getGuideConfItem
function getGuideConfItem(id)
	local cfg = Cfg_GuideConfig[id] 
	if cfg then
		local newStartCondition = {}
		for _, v in pairs(cfg.StartCondition) do
			if #v.Param ~= 0 or v.Type ~= 0 then
				table.insert(newStartCondition, v)
			end
		end
		cfg.StartCondition = newStartCondition

		local newSkipCondition = {}
		for _, v in pairs(cfg.SkipCondition) do
			if #v.Param ~= 0 or v.Type ~= 0 then
				table.insert(newSkipCondition, v)
			end
		end
		cfg.SkipCondition = newSkipCondition
	end
	return cfg
end

-- 获取 引导表 主键
cpp_getGuideItemList = getGuideItemList
function getGuideItemList()
	local list = CommonHelper.getKeys(Cfg_GuideConfig)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 引导表
cpp_getGuideStepConfItem = getGuideStepConfItem
function getGuideStepConfItem(guideId, stepId)
	local cfg = Cfg_GuideStep[guideId]
	if cfg then
		return cfg[stepId]
	end
end

-- 获取 引导表 主键
cpp_getGuideStepItemList = getGuideStepItemList
function getGuideStepItemList(guideId)
	local cfg = Cfg_GuideStep[guideId]
	if cfg then
		local list = CommonHelper.getKeys(cfg)
		table.sort(list, function (a, b) return a < b end)
		return list
	end
end

----------------- Guide目录 end -----------------

----------------- Hall目录 -----------------

-- 获取 激活这个成就的成就ID
cpp_getPreAchieveID = getPreAchieveID
function getPreAchieveID(curId)
	for i, v in pairs(Cfg_Achievement) do
		for _, id in pairs(v.EndStartID) do
			if id == curId then
				return i
			end
		end
	end
end

-- 获取 成就表
cpp_getAchieveConfItem = getAchieveConfItem
function getAchieveConfItem(id)
	return Cfg_Achievement[id]
end

-- 获取 成就表 主键
cpp_getAchieveItemList = getAchieveItemList
function getAchieveItemList()
	local list = CommonHelper.getKeys(Cfg_Achievement)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 活动副本表
cpp_getActivityInstanceItem = getActivityInstanceItem
function getActivityInstanceItem(id)
	return Cfg_ActivityInstance[id]
end

-- 获取 活动副本主键
cpp_getActivityInstanceList = getActivityInstanceList
function getActivityInstanceList()
	local list = CommonHelper.getKeys(Cfg_ActivityInstance)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 道具表
cpp_getPropConfItem = getPropConfItem
function getPropConfItem(id)
	return Cfg_Item[id]
end

-- 获取 道具表主键
cpp_getPropItemList = getPropItemList
function getPropItemList()
	local list = CommonHelper.getKeys(Cfg_Item)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 邮件配表
cpp_getMailConfItem = getMailConfItem
function getMailConfItem(id)
	return Cfg_Mail[id]
end

-- 获取 英雄升星表
cpp_getSoldierUpRateConfItem = getSoldierUpRateConfItem
function getSoldierUpRateConfItem(id)
	return Cfg_SoldierUpRate[id]
end

-- 获取 英雄升星主键
cpp_getSoldierUpRateItemList = getSoldierUpRateItemList
function getSoldierUpRateItemList()
	local list = CommonHelper.getKeys(Cfg_SoldierUpRate)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 根据竞技场T级获取解锁的英雄id列表
function getSoldierIdListByTLevel(tLevel)
	local list = {}
	for index, item in pairs(Cfg_SoldierUpRate) do
		if item.Source == tLevel then
			table.insert(list, index)
		end
	end
	return list
end

-- 获取 购买召唤师表主键
cpp_getSaleSummonerItemList = getSaleSummonerItemList
function getSaleSummonerItemList()
	local list = CommonHelper.getKeys(Cfg_Summoner)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 购买召唤师表
cpp_getSaleSummonerConfItem = getSaleSummonerConfItem
function getSaleSummonerConfItem(id)
	return Cfg_Summoner[id]
end

-- 获取 任务表
cpp_getTaskConfItem = getTaskConfItem
function getTaskConfItem(id)
	return Cfg_Task[id]
end

-- 获取 任务表 主键
cpp_getTaskItemList = getTaskItemList
function getTaskItemList()
	local list = CommonHelper.getKeys(Cfg_Task)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 金币试炼表
cpp_getGoldTestConfItem = getGoldTestConfItem
function getGoldTestConfItem(id)
	return Cfg_GoldTest[id]
end

-- 获取 金币试炼表 主键
cpp_getGoldTestItemList = getGoldTestItemList
function getGoldTestItemList()
	local list = CommonHelper.getKeys(Cfg_GoldTest)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 金币试炼表
cpp_getGoldTestChestConfItem = getGoldTestChestConfItem
function getGoldTestChestConfItem(id)
	return Cfg_GoldTestChest[id]
end

-- 获取 金币试炼表 主键
cpp_getGoldTestChestItemList = getGoldTestChestItemList
function getGoldTestChestItemList()
	local list = CommonHelper.getKeys(Cfg_GoldTestChest)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 英雄试炼表
cpp_getHeroTestConfItem = getHeroTestConfItem
function getHeroTestConfItem(id)
	return Cfg_HeroTest[id]
end

-- 获取 英雄试炼表 主键
cpp_getHeroTestItemList = getHeroTestItemList
function getHeroTestItemList()
	local list = CommonHelper.getKeys(Cfg_HeroTest)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 爬塔试炼表
cpp_getTowerFloorConfItem = getTowerFloorConfItem
function getTowerFloorConfItem(id)
	return Cfg_TowerFloor[id]
end

-- 获取 爬塔试炼表 主键
cpp_getTowerFloorItemList = getTowerFloorItemList
function getTowerFloorItemList()
	local list = CommonHelper.getKeys(Cfg_TowerFloor)
	table.sort(list, function (a, b) return a < b end)
	return list
end

cpp_getTowerBuffItemList = getTowerBuffItemList
function getTowerBuffItemList()
	local list = CommonHelper.getKeys(Cfg_TowerBuff)
	table.sort(list, function (a, b) return a < b end)
	return list
end

cpp_getTowerRankConfItem = getTowerRankConfItem
function getTowerRankConfItem(id)
	return Cfg_TowerRank[id]
end

cpp_getTowerRankItemList = getTowerRankItemList
function getTowerRankItemList()
	local list = CommonHelper.getKeys(Cfg_TowerRank)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 充值商店配置表
cpp_getDiamondShopConfData = getDiamondShopConfData
function getDiamondShopConfData()
	return Cfg_DiamondShop
end

-- 获取 运营活动标题
cpp_getOperateActiveTitleName = getOperateActiveTitleName
function getOperateActiveTitleName(id)
	local cfg = Cfg_GameOp[id]
	if cfg then
		return getUILanConfItem(cfg.GameOp_name)
	end
	return ""
end

-- 获取 运营活动标签的图片资源
cpp_getOperateActiveMenuIcon = getOperateActiveMenuIcon
function getOperateActiveMenuIcon(id)
	local cfg = Cfg_GameOp[id]
	if cfg then
		return cfg.GameOp_MenuPic
	end
	return ""
end

-- 获取 运营活动标签
cpp_getOperateActiveMenuName = getOperateActiveMenuName
function getOperateActiveMenuName(id)
	local cfg = Cfg_GameOp[id]
	if cfg then
		return getUILanConfItem(cfg.GameOp_MenuName)
	end
	return ""
end

-- 获取 运营活动掉落描述
cpp_getOperateActiveDropDesc = getOperateActiveDropDesc
function getOperateActiveDropDesc(id)
	local cfg = Cfg_GameOp2[id]
	if cfg then
		return getUILanConfItem(cfg.GameOp_des)
	end
	return ""
end

-- 获取 运营活动掉落的宣传图
cpp_getOperateActiveDropPic = getOperateActiveDropPic
function getOperateActiveDropPic(id)
	local cfg = Cfg_GameOp2[id]
	if cfg then
		return cfg.GameOp_Pic
	end
	return ""
end

-- 获取 运营活动任务的图片资源
cpp_GetOperateActiveTaskIcon = GetOperateActiveTaskIcon
function GetOperateActiveTaskIcon(activeId, taskId)
	local cfg = Cfg_GameOp3[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return data.GameOptask_Pic
		end
	end
	return ""
end

-- 获取 运营活动任务
cpp_GetOperateActiveTaskName = GetOperateActiveTaskName
function GetOperateActiveTaskName(activeId, taskId)
	local cfg = Cfg_GameOp3[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return getUILanConfItem(data.GameOptask_des)
		end
	end
	return ""
end

-- 获取 运营活动任务的宣传图
cpp_GetOperateActiveTaskPic = GetOperateActiveTaskPic
function GetOperateActiveTaskPic(activeId, taskId)
	local cfg = Cfg_GameOp3[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return data.GameOp_Pic
		end
	end
	return ""
end

-- 获取兑换活动某活动数据
function GetOperateActiveExchangeData(activeId, taskId)
	local cfg = Cfg_GameOp5[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return data
		end
	end
end

-- 兑换活动任务宣传图
function GetOperateActiveExchangePic(activeId, taskId)
	local cfg = Cfg_GameOp5[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return data.Exchange_Pic2
		end
	end
	return ""
end

function GetOperateActiveExchangeStr(activeId, taskId)
	local cfg = Cfg_GameOp5[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return getUILanConfItem(data.Exchange_des)
		end
	end
	return ""
end

-- 获取 商店类型表
cpp_getShopConfData = getShopConfData
function getShopConfData()
	return Cfg_Shop
end

-- 获取 获取某个类型商店数据
cpp_getShopTypeData = getShopTypeData
function getShopTypeData(shopType)
	return Cfg_Shop[shopType]
end

-- 获取 关卡掉落
cpp_getDropPropItem = getDropPropItem
function getDropPropItem(id)
	local cfg = Cfg_ItemDrop[id]
	if cfg then
		local newDropIDs = {}
		for _, data in ipairs(cfg.DropIDs) do
			if data.DropID ~= 0 then
				table.insert(newDropIDs, data)
			end 
		end
		cfg.DropIDs = newDropIDs

		return cfg
	end
end

-- 获取装备基础属性个数
cpp_getEquipBaseAttriteCount = getEquipBaseAttriteCount
function getEquipBaseAttriteCount(id)
	local cfg = Cfg_EquipmentCreat[id]
	if cfg then
		local n = 0
		for _, data in ipairs(cfg.BaseProp) do
			if data.nEffectID ~= 0 then
				n = n + 1
			end
		end
		return n
	end
end

-- 获取装备随机属性个数
cpp_getEquipRandAttriteCount = getEquipRandAttriteCount
function getEquipRandAttriteCount(id)
	local cfg = Cfg_EquipmentCreat[id]
	if cfg then
		local n = 0
		for _, data in ipairs(cfg.ExtraProp) do
			if data.nEffectID ~= 0 then
				n = n + 1
			end
		end
		return n
	end
end

-- 获取装备生成器配表
cpp_getEquipPropCreateConfItem = getEquipPropCreateConfItem
function getEquipPropCreateConfItem(id)
	local cfg = Cfg_EquipmentCreat[id]
	if cfg then
		local newBaseProp = {}
		for _, data in ipairs(cfg.BaseProp) do
			if data.nEffectID ~= 0 then
				data.nMinValue = data.param and data.param[1] or data.nMinValue
				data.nMaxValue = data.param and data.param[2] or data.nMaxValue
				data.param = nil
				data.nWeight = 0
				table.insert(newBaseProp, data)
			end
		end
		cfg.BaseProp = newBaseProp

		local newExtraProp = {}
		for _, data in ipairs(cfg.ExtraProp) do
			if data.nEffectID ~= 0 then
				data.nMinValue = data.param and data.param[1] or data.nMinValue
				data.nMaxValue = data.param and data.param[2] or data.nMaxValue
				data.param = nil
				table.insert(newExtraProp, data)
			end
		end 
		cfg.ExtraProp = newExtraProp

		return cfg
	end
end

-- 通过装备id获取装备打造id
function getCreateIdByEquipId(eId)
	for _, info in pairs(Cfg_EquipmentCreat) do
		if info.nEquipID == eId then
			return info.EqCreat_ID
		end
	end
end

-- 获取 每日签到的配置
cpp_getMonthSignConf = getMonthSignConf
function getMonthSignConf(month)
	local ret = {}
	for i = 1, 26 do
		local cfg = Cfg_Checkin[i]
		for j, _ in pairs(cfg) do
			if j == month then
				local data = cfg[j]
				table.insert(ret, {
					nGoodsID = data.nGoodsID,
					nGoodsNum = data.nGoodsNum,
					nShowNum = data.nShowNum,
					nVipDoubleNeed = data.nVipDoubleNeed
				})
				break
			end
		end
	end
	return ret
end

-- 获取 累计签到的配置
cpp_getConDaySignConf = getConDaySignConf
function getConDaySignConf(id)
	local cfg = Cfg_ConCheckin[id]
	if cfg then
		local ret = {}
		ret.DayNeeds = cfg.DayNeeds
		for _, v in ipairs(cfg.Items) do
			table.insert(ret, v)
		end
		return ret
	end
	return {}
end

function getConDaySignData()
	return Cfg_ConCheckin
end

-- 获取 首次充值活动的配置
cpp_GetFirstPayData = GetFirstPayData
function GetFirstPayData()
	local cfg = Cfg_FirstPay[1]
	if cfg then
		if not cfg.GoodsID and not cfg.GoodsNum then
			cfg.GoodsID = {}
			cfg.GoodsNum = {}

			for i = 1, #cfg.FirstPayRewards, 2 do
				table.insert(cfg.GoodsID, cfg.FirstPayRewards[i])
				table.insert(cfg.GoodsNum, cfg.FirstPayRewards[i + 1])
			end
			cfg.FirstPayRewards = nil
		end
		return cfg
	end
	return {}
end
-- 获取七日活动某一天的数据
function getSevenDayConfByDay(day)
	return Cfg_SevenDay[day]
end


function getGameOp1(activeId)
	local cfg = Cfg_GameOp1[activeId]
	if cfg then
		return cfg
	end
	return {}
end

function getGameOp3Data(activeId)
	local cfg = Cfg_GameOp3[activeId]
	if cfg then
		return cfg
	end
	return {}
end

function getGameOp3byTaskId(activeId,taskId)
	local cfg = Cfg_GameOp3[activeId]
	if cfg then
		local data = cfg[taskId]
		if data then
			return data
		end
	end
	return {}
end

-- 竞技场电脑
cpp_getConfArenaComputerItem = getConfArenaComputerItem
function getConfArenaComputerItem()
	return Cfg_ArenaScollBar
end

-- 点击播放动画
cpp_getConfAnimationPlayOrderItem = getConfAnimationPlayOrderItem
function getConfAnimationPlayOrderItem(id)
	local cfg = Cfg_Animation_LabelCombination[id]
	if cfg then
		local newVecAnim = {}
		for _, v in ipairs(cfg.vecAnimations) do
			if #v > 0 then
				table.insert(newVecAnim, v)
			end
		end
		cfg.vecAnimations = newVecAnim
		return cfg
	end
end

-- 大厅站位顺序
cpp_getConfHallStandingItem = getConfHallStandingItem
function getConfHallStandingItem(i)
	return Cfg_HallStanding[i]
end

-- 获取 竞技场训练场配置
cpp_getArenaTrainings = getArenaTrainings
function getArenaTrainings()
	local ret = {}
	for _, v in ipairs(Cfg_ArenaTraining) do
		ret[v.Computer_ID] = v.TRstageID
	end
	return ret
end

-- 获取 商店物品表
cpp_getGoods = getGoods
function getShopGood(id)
    for _, v in pairs(Cfg_Goods) do
        if v.Goods_ID == id then
            return v
        end
    end
end

-- 获取通知信息
function getConfNoticeItem(noticeId)
    return Cfg_Notices[noticeId]
end

-- 获取 月卡天数
function getMonthCardDays(activeId, cardId)
    local cfg = Cfg_GameOp4[activeId]
    if cfg then
        local data = cfg[cardId]
        if data then
            return data.MCard_Time
        end
    end
    return 0
end

-- 获取 月卡PID
function getMonthCardPID(activeId, cardId)
    local cfg = Cfg_GameOp4[activeId]
    if cfg then
        local data = cfg[cardId]
        if data then
            return data.Mcard_PID
        end
    end
    return 0
end

-- 获取 月卡奖励钻石
function getMonthCardDiamond(activeId, cardId)
    local cfg = Cfg_GameOp4[activeId]
    if cfg then
        local data = cfg[cardId]
        if data then
            return data.MCard_Number
        end
    end
    return 0
end

-- 获取 蓝钻配置
function getBlueDiamondConfig(id, taskId)
	if taskId then
		if Cfg_BlueDiamond[id] then
			return Cfg_BlueDiamond[id][taskId]
		end
	else
		return Cfg_BlueDiamond[id]
	end
end

-- 获取装备技能配置
function getEquipSkillConfig(id)
	return Cfg_EquipSkill[id]
end

-- 获取天赋页
function getTalentArrangeConf(id)
	return Cfg_TalentArrangement[id]
end

-- 获取PVP分享配置
function getPVPShareConfig()
	return Cfg_PVPShare[1]
end

function getPVPUploadConfig()
	return Cfg_PVPUpload[1]
end

function getSummonerLvUpConfig()
	return Cfg_SummonerLvUp
end

----------------- Hall目录 end -----------------

---------------- Language目录 begin ---------------

-- 获取 道具语言表
cpp_getPropLanConfItem = getPropLanConfItem
function getPropLanConfItem(id)
	local cfg = Cfg_ItemLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取 关卡语言表
cpp_getStageLanConfItem = getStageLanConfItem
function getStageLanConfItem(id)
	local cfg = Cfg_StageLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取 boss monster 技能语言表
cpp_getBMCSkillLanConfItem = getBMCSkillLanConfItem
function getBMCSkillLanConfItem(id)
	local cfg = Cfg_BossMonsterCall_Skill[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取剧情文本
cpp_getStoryLanConfItem = getStoryLanConfItem
function getStoryLanConfItem(id)
	local cfg = Cfg_GuildLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取任务文本
cpp_getTaskLanConfItem = getTaskLanConfItem
function getTaskLanConfItem(id)
	local cfg = Cfg_TaskLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取成就文本
cpp_getAchieveLanConfItem = getAchieveLanConfItem
function getAchieveLanConfItem(id)
	local cfg = Cfg_AchievementLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- 获取角色属性文本
cpp_getRoleAttributeLanConfItem = getRoleAttributeLanConfItem
function getRoleAttributeLanConfItem(id)
	local cfg = Cfg_RoleAttributeLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- vip文字
cpp_getVipLanConfItem = getVipLanConfItem
function getVipLanConfItem(id)
	local cfg = Cfg_Vip[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

function getNoticeLanConfItem(id)
	return Cfg_NoticesLan[id]
end

-- Loading提示文字
cpp_getLoadingTipsConfItem = getLoadingTipsConfItem
function getLoadingTipsConfItem(id)
	local cfg = Cfg_BattleTips[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

-- Loading提示个数
cpp_getLoadingTipsCount = getLoadingTipsCount
function getLoadingTipsCount()
	return #Cfg_BattleTips
end

function getPushLanConfItem(id)
	local cfg = Cfg_Push_Lan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

function getBlueDiamondLanConfItem(id)
	local cfg = Cfg_BlueDiamondLan[id]
	if cfg then
		return cfg.Content
	end
	return ""
end

---------------- Language目录 end ---------------

---------------- Role目录 begin ----------------

-- 获取 角色缩放配置
cpp_getRoleZoom = getRoleZoom
function getRoleZoom(id)
	id = tonumber(id)
	return Cfg_Zoom[id]
end

---------------- Role目录 end ------------------

----------------- Stage目录 begin -----------------

-- 获取 章节配置表
cpp_getChapterConfItem = getChapterConfItem
function getChapterConfItem(id)
	local cfg = Cfg_Chapter[id]
	if cfg then
		if not cfg.FirstStageID then
			local newStages = {}
			for i, v in ipairs(cfg.Stages) do
				if i == 1 then
					cfg.FirstStageID = v.ID[1]
				end

				if #v.ID > 0 and v.ID[1] > 0 then
					local nextV = cfg.Stages[i + 1]
					if nextV and #nextV.ID > 0 and nextV.ID[1] > 0 then
						v.NextID = nextV.ID[1]
					else
						v.NextID = 0
					end
					newStages[v.ID[1]] = v
				end
			end
			cfg.Stages = newStages
		end

		if not cfg.NextID then
			if Cfg_Chapter[id + 1] then
				cfg.NextID = id + 1
			else
				cfg.NextID = 0
			end
		end

		if not cfg.PrevID then
			if Cfg_Chapter[id - 1] then
				cfg.PrevID = id - 1
			else
				cfg.PrevID = 0
			end
		end
		--[[
		if not cfg.RecoverTime.Week then
			local newRecoverTime
			if cfg.RecoverType == 2 then		-- 周恢复
				newRecoverTime = {
					Week = cfg.RecoverTime[1] or 0,
					Hour = cfg.RecoverTime[2] or 0,
					Min = cfg.RecoverTime[3] or 0,
					Sec = 0
				}
			elseif cfg.RecoverType == 1 then 	-- 日恢复
				newRecoverTime = {
					Week = 0,
					Hour = cfg.RecoverTime[1] or 0,
					Min = cfg.RecoverTime[2] or 0,
					Sec = 0
				}
			elseif cfg.RecoverType == 2 then 	-- 每隔多少秒恢复
				newRecoverTime = {
					Week = 0,
					Hour = 0,
					Min = 0,
					Sec = cfg.RecoverTime[1] or 0
				}
			else
				newRecoverTime = {
					Week = 0,
					Hour = 0,
					Min = 0,
					Sec = 0
				}
			end
			
			cfg.RecoverTime = {
					Week = 0,
					Hour = 0,
					Min = 0,
					Sec = 0
				}
		end
		--]]
		return cfg
	end
end

-- 获取 章节配置表主键
cpp_getChapterItemList = getChapterItemList
function getChapterItemList()
	local list = CommonHelper.getKeys(Cfg_Chapter)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 获得章节中指定关卡数据
cpp_getStageInfoInChapter = getStageInfoInChapter
function getStageInfoInChapter(chapId, stageId)
	local cfg = Cfg_Chapter[chapId]
	if cfg then
		for _, v in pairs(cfg.Stages) do
			if v.ID[1] == stageId then
				return {
					StageID = v.ID[1],
					Level = v.ID[2],
					Title = v.ID[2],
					Desc = v.Desc,
					Energy = v.Energy,
					Drop = v.Drop,
					Thumbnail = v.Thumbnail,
				}
			end
		end
	end
end

function getChapterBoxData(ChapterID)
	local cfg = Cfg_Chapter[ChapterID]
	if cfg then
		return {[1] = { star = cfg.Star1,
						StarAward = cfg.StarAward1
				},
				[2] = { star = cfg.Star2,
						StarAward = cfg.StarAward2
				},
				[3] = { star = cfg.Star3,
						StarAward = cfg.StarAward3
				}
			}
	end
end


cpp_getMapConfItem = getMapConfItem
function getMapConfItem(id)
	return Cfg_ChapterMap[id]
end

cpp_getMapItemList = getMapItemList
function getMapItemList()
	local list = CommonHelper.getKeys(Cfg_ChapterMap)
	table.sort(list, function (a, b) return a < b end)
	return list
end

-- 获取 引导战斗配置
cpp_getGuideBattleConfItem = getGuideBattleConfItem
function getGuideBattleConfItem()
	local cfg = Cfg_FirstStage[1]
	if cfg then
		local newSoliders = {}
		for _, v in ipairs(cfg.Soliders) do
			if v.SoliderId > 0 then
				table.insert(newSoliders, v)
			end
		end
		cfg.Soliders = newSoliders
		return cfg
	end
end

------------------ Stage目录 end --------------------

------------------ Music目录 start --------------------
function getGuideMusicPath(id)
	local cfg = Cfg_GuideMusic[id]
	if cfg then
		return cfg.Res
	end
end
------------------ Music目录 end --------------------