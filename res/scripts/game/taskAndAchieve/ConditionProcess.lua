--[[
	ConditionProcess 主要处理GameEvents事件分发给不同的成就或任务监听ID,
	通过传入conditionId, prams, completeTimes, args, 计算出新的 completeTimes
]]

ConditionProcess = {}
require("summonerComm.GameEvents")
require("game.comm.StageHelper")

local taskType = {task = 1, achieve = 2, unionPresonal = 3, unionTeam = 4}

-- 任务成就监听
ConditionProcess.conditionId = {
 	------ 动作 -------
	passStage 			= 1,	-- 通关N次指定/任意关卡
	heroWearEquip 		= 2,	-- 为任意英雄穿戴N次装备
	heroUpLevel			= 3,	-- 为任意N个英雄升级
	heroUpStar 			= 4,	-- 为任意N个英雄升星
	heroUpSkill			= 5,	-- 为任意N个技能升级
	drawCard			= 6,	-- 抽卡N次
	useExpCard 			= 7,	-- 使用N次任意经验卡
	pointGold			= 8,	-- 点金（钻石购买金币）X次
	receiveVit 			= 9,	-- 领取N次每日体力
	finishHeroTest 		= 20,  	-- 完成N次英雄试炼
	finishGoldTest 		= 21, 	-- 完成N次金币试炼
	finishTowerTestFloor= 22,	-- 完成N层爬塔试炼
	finishPVP			= 23,	-- 完成N次竞技
	finishUnionTask 	= 24,	-- 完成N次公会任务
	passFBStage			= 25,	-- 完成N次副本关卡
	monthCard			= 26,	-- 月卡
	receiveGold			= 19,	-- 累计获得XXXXX金币
	shopBuy				= 31,	-- 商店购买
	singleRaceWin		= 33,	-- 累计只使用某种族英雄取得N场胜利
	dispatchMercenary	= 43,	-- 完成派遣佣兵
	equipMake			= 204,	-- 装备打造

	----- 状态 -------			
	userLevel 			= 10,	-- 玩家已经达到X级
	ownHeroLevel 		= 11,	-- 拥有N个X级英雄
	ownHeroStar			= 12,	-- 拥有X星英雄
	ownHeroSkillLevel 	= 13,	-- 拥有X级技能的英雄
	ownEquip 			= 14,	-- 拥有X件Ｘ色XX装备
	ownHero 			= 15,	-- 拥有X个不同的英雄
	ownSummonerCount	= 16,	-- 拥有X个召唤师
	ownSummonerID 		= 17,	-- 获得XXX召唤师
	StageStars 			= 18,	-- 玩家关卡拥有XXX个星星
	stagePass			= 27,	-- 关卡通过
	onwUnion 			= 30,	-- 拥有公会
	onwHeroStarCount	= 32,	-- 拥有n个x星的英雄
	pvpContinuCount		= 34,	-- 竞技场连胜
	pvpScore			= 35,	-- 竞技积分达到N分
	meetRank			= 36,	-- 达到排名
	finishUnionActive	= 42,	-- 完成公会活跃	
	useMercenary 		= 44,	-- 完成使用佣兵
}

-- 事件 可能影响 对应的任务成就
ConditionProcess.eventIds = {
	[GameEvents.EventStageOver] 			= {"passStage", "StageStars", "stagePass", "finishUnionActive"},
	[GameEvents.EventHeroTestStageOver] 	= {"finishHeroTest"},
	[GameEvents.EventGoldTestStageOver] 	= {"finishGoldTest"},
	[GameEvents.EventTowerTestStageOver]	= {"finishTowerTestFloor"},
	[GameEvents.EventFBTestStageOver] 		= {"passFBStage"},
	[GameEvents.EventPVPOver]				= {"finishPVP", "pvpContinuCount", "singleRaceWin", "pvpScore", "meetRank", "finishUnionActive"},
	[GameEvents.EventDrawCard] 				= {"drawCard"},
	[GameEvents.EventUseItem]				= {"useExpCard"},
	[GameEvents.EventTouchGloden]			= {"pointGold"},
	[GameEvents.EventReceiveCurrency]		= {"receiveGold"},
	[GameEvents.EventReceiveEquip]			= {"ownEquip"},
	[GameEvents.EventReceiveHero]			= {"ownHeroLevel", "ownHeroStar", "ownHeroSkillLevel", "ownHero", "onwHeroStarCount"},
	[GameEvents.EventReceiveSummoner]		= {"ownSummonerCount", "ownSummonerID"},
	[GameEvents.EventDressEquip]			= {"heroWearEquip"},
	[GameEvents.EventHeroUpgradeLevel] 		= {"heroUpLevel", "ownHeroLevel"},
	[GameEvents.EventHeroUpgradeStar]		= {"heroUpStar", "ownHeroStar", "onwHeroStarCount"},
	[GameEvents.EventHeroUpgradeSkill] 		= {"heroUpSkill", "ownHeroSkillLevel"},
	[GameEvents.EventPlayerUpgradeLevel]	= {"userLevel"},
	[GameEvents.EventFinishTask] 			= {"finishUnionTask"},
	[GameEvents.EventBuyMonthCard]			= {"monthCard"},
	[GameEvents.EventOwnUnion]				= {"onwUnion"},
	[GameEvents.EventShopBuy]				= {"shopBuy"},
	[GameEvents.EventDispatchMercenary]		= {"dispatchMercenary"},
	[GameEvents.EventUseMercenary]			= {"useMercenary"},
	[GameEvents.EventEquipMake]				= {"equipMake"},
}

-- 完成后需要发送给服务器等级的任务成就类型
ConditionProcess.needSendConditionIds = {
	[ConditionProcess.conditionId.ownHeroLevel] = true, 
	[ConditionProcess.conditionId.ownHeroStar] = true, 
	[ConditionProcess.conditionId.ownHeroSkillLevel] = true,
	[ConditionProcess.conditionId.ownEquip] = true,
	[ConditionProcess.conditionId.ownHero] = true,
	[ConditionProcess.conditionId.ownSummonerCount] = true,
	[ConditionProcess.conditionId.ownSummonerID] = true,
	[ConditionProcess.conditionId.StageStars] = true,
	[ConditionProcess.conditionId.onwHeroStarCount] = true,
	[ConditionProcess.conditionId.pvpScore] = true,
    [ConditionProcess.conditionId.stagePass] = true,
	[ConditionProcess.conditionId.meetRank] = true,
	[ConditionProcess.conditionId.finishUnionActive] = true,
}
-- 每完成一次都需要发送给服务器的任务成就类型
ConditionProcess.everyNeedSendConditionIds = {
	[ConditionProcess.conditionId.finishPVP] = true,
	[ConditionProcess.conditionId.finishUnionTask] = true,
	[ConditionProcess.conditionId.onwUnion] = true,
	[ConditionProcess.conditionId.pvpContinuCount] = true,
	[ConditionProcess.conditionId.singleRaceWin] = true,
	[ConditionProcess.conditionId.dispatchMercenary] = true,
	[ConditionProcess.conditionId.useMercenary] = true,
}

-- 获取战斗使用的种族 0 杂牌 >0 种族类型
function getBattleRace()
	local soldiersInfo = ModelHelper.getBattleSoldiersInfo()
	local race = nil
	for _, info in ipairs(soldiersInfo) do
		local soldierConf = getSoldierConfItem(info.id, info.star)
		if soldierConf ~= nil then
			if race == nil then
				race = soldierConf.Common.Race
			elseif race ~= soldierConf.Common.Race then
				race = 0
				break
			end 
		end
	end
	return race or 0
end

function ConditionProcess.getConditionIdsByEvent(eventName)
	local conditionIds = {}
	if ConditionProcess.eventIds[eventName] ~= nil then
		for _,conditionName in ipairs(ConditionProcess.eventIds[eventName]) do
			table.insert(conditionIds, ConditionProcess.conditionId[conditionName])
		end
	end
	return conditionIds
end

function ConditionProcess.getFuncByEvent(eventName)
	return ConditionProcess.ConditionCallbacks[eventName]
end

-- 获取结束后启动ID的新信息
function ConditionProcess.getEndStarIdInfo(conditionId, prams, unLockLv)
	local completeTimes = 0
	local isAcitve = false
	local userLv = getGameModel():getUserModel():getUserLevel()
	if userLv >= unLockLv then
		isAcitve = true
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
    if completeTimes == -1 then completeTimes = 0 end
	return completeTimes, isAcitve
end

-- 获取状态任务当前完成次数
function ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, completeTimes)
	completeTimes = completeTimes or 0
	local pram1 = prams[1] or 0
	local pram2 = prams[2] or 0
	if conditionId == ConditionProcess.conditionId.userLevel then
		local userLv = getGameModel():getUserModel():getUserLevel()
		completeTimes = userLv
	elseif conditionId == ConditionProcess.conditionId.ownHeroLevel then
		completeTimes = 0
		local heroCards = getGameModel():getHeroCardBagModel():getHeroCards()
		for _, dynID in pairs(heroCards) do
			local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(dynID)
			if heroCard:getLevel() >= pram1 then
				completeTimes = completeTimes + 1
			end
		end
	elseif conditionId == ConditionProcess.conditionId.ownHeroStar then
		completeTimes = 0
		local heroCards = getGameModel():getHeroCardBagModel():getHeroCards()
		for _, dynID in pairs(heroCards) do
			local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(dynID)
			if heroCard:getStar() >= completeTimes then
				completeTimes = heroCard:getStar()
			end
		end		
	elseif conditionId == ConditionProcess.conditionId.onwHeroStarCount then
		completeTimes = 0
		local heroCards = getGameModel():getHeroCardBagModel():getHeroCards()
		for _, dynID in pairs(heroCards) do
			local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(dynID)
			if heroCard:getStar() >= pram1 then
				completeTimes = completeTimes + 1
			end
		end
	elseif conditionId == ConditionProcess.conditionId.ownHeroSkillLevel then
		completeTimes = 0
		local heroCards = getGameModel():getHeroCardBagModel():getHeroCards()
		for _, dynID in pairs(heroCards) do
			local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(dynID)
			for skillId, skillLv in pairs(heroCard:getSkills()) do
				if skillLv > completeTimes then
					completeTimes = skillLv
				end
			end
		end
	elseif conditionId == ConditionProcess.conditionId.ownEquip then
		completeTimes = 0
		local equips = getGameModel():getEquipModel():getEquips()
		for dynId, eqInfo in pairs(equips) do
			local eqConf = getEquipmentConfItem(eqInfo.confId)
            local propConf = getPropConfItem(eqInfo.confId)
			if eqConf and propConf and propConf.Quality >= pram1 and (eqConf.Parts == pram2 or pram2 == 0) then
				completeTimes = completeTimes + 1
			end
		end
	elseif conditionId == ConditionProcess.conditionId.ownHero then		
        local diffHeroCount = getGameModel():getHeroCardBagModel():getWholeCardCount()
		completeTimes = diffHeroCount or 0
	elseif conditionId == ConditionProcess.conditionId.ownSummonerCount then
		local summonerIds = {}
		local summoners = getGameModel():getSummonersModel():getSummoners()
		for _, id in ipairs(summoners) do
			table.insert(summonerIds, id)
		end
		completeTimes = #summonerIds
	elseif conditionId == ConditionProcess.conditionId.ownSummonerID then
		completeTimes = 0
		local summoners = getGameModel():getSummonersModel():getSummoners()
		for _, id in ipairs(summoners) do
			if id == pram1 then
				completeTimes = 1
			end
		end
	elseif conditionId == ConditionProcess.conditionId.StageStars then
		completeTimes = StageHelper.getAllChapterStar()
	elseif conditionId == ConditionProcess.conditionId.receiveGold then
		ConditionProcess.receiveGold = ConditionProcess.receiveGold or completeTimes
		completeTimes = ConditionProcess.receiveGold or 0
	elseif conditionId == ConditionProcess.conditionId.monthCard then
		-- 判断是否拥有月卡
		local stamp = getGameModel():getNow()
		local monthCardStamp = getGameModel():getUserModel():getMonthCardStamp()
		if stamp > monthCardStamp then
			completeTimes = 0
		else
			completeTimes = 1
		end
	elseif conditionId == ConditionProcess.conditionId.pvpContinuCount then
		completeTimes = getGameModel():getPvpModel():getHistoryContinueWinTimes()
	elseif conditionId == ConditionProcess.conditionId.onwUnion then
		if getGameModel():getUnionModel():getHasUnion() then
		    completeTimes = 1
		end
	elseif conditionId == ConditionProcess.conditionId.pvpScore then
		completeTimes = getGameModel():getPvpModel():getScore(0)
	elseif conditionId == ConditionProcess.conditionId.stagePass then
		-- 关卡状态
		local stageType = StageHelper.StageState.SS_HIDE
		if pram1 < 10000 then
			stageType = getGameModel():getStageModel():getComonStageState(pram1)
		else
			stageType = getGameModel():getStageModel():getEliteStageState(pram1)
		end
		if stageType == StageHelper.StageState.SS_ONE
			or stageType == StageHelper.StageState.SS_TWO
			or stageType == StageHelper.StageState.SS_TRI then
			completeTimes = 1
		end
     elseif conditionId == ConditionProcess.conditionId.meetRank then
        local topRank = getGameModel():getPvpModel():getHistoryRank(pram1)
		if pram2 >= topRank and topRank ~= 0 then
			completeTimes = 1
		end
	elseif conditionId == ConditionProcess.conditionId.finishUnionActive then
		local unionModel = getGameModel():getUnionModel()
		completeTimes = unionModel:getTodayStageLiveness() + unionModel:getTodayPvpLiveness()
	end

	return completeTimes
end

function ConditionProcess.onStageOver(conditionId, prams, completeTimes, args)
	if args.battleResult ~= 0 then
		local pram1 = prams[1] or 0
		local pram2 = prams[2] or 0
		if conditionId == ConditionProcess.conditionId.passStage then
			local chapterConf = getChapterConfItem(args.chapterId)
			if chapterConf == nil then print("chapterConf is nil", args.chapterId) end
			if pram1 == 0 then
				completeTimes = completeTimes + (args.count or 1)
			elseif pram1 == -1 then
				if chapterConf.Type == 1 then
					completeTimes = completeTimes + (args.count or 1)
				end
			elseif pram1 == -2  then
				if chapterConf.Type == 2 then
					completeTimes = completeTimes + (args.count or 1)
				end
			elseif pram1 == args.stageId then
				completeTimes = completeTimes + (args.count or 1)
			end
		elseif conditionId == ConditionProcess.conditionId.StageStars then
			completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
		elseif conditionId == ConditionProcess.conditionId.stagePass then
			completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
		elseif conditionId == ConditionProcess.conditionId.finishUnionActive then
			completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
		end
	end
	return completeTimes
end

function ConditionProcess.onHeroTestStageOver(conditionId, prams, completeTimes, args)
	if args.battleResult ~= 0 then
		if conditionId == ConditionProcess.conditionId.finishHeroTest then
			if args.stageDifficulty >= (prams[1] or 0) then
				completeTimes = completeTimes + 1
			end
		end
	end
	return completeTimes
end

function ConditionProcess.onGoldTestStageOver(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.finishGoldTest then
		completeTimes = completeTimes + 1
	end
	return completeTimes
end

function ConditionProcess.onTowerTestStageOver(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.finishTowerTestFloor then
		if args.battleResult == 1 and args.stageDifficulty >= (prams[1] or 0) then 
			completeTimes = completeTimes + 1
		end
	end
	return completeTimes
end

function ConditionProcess.onFBTestStageOver(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.passFBStage then
		if args.stageDifficulty >= (prams[1] or 0) then
			completeTimes = completeTimes + 1
		end
	end
	return completeTimes
end

function ConditionProcess.onPVPOver(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.finishPVP then
		if ((prams[1] or 0) == 0 or args.battleResult == 1) and args.pvpType >= 0 then
			completeTimes = completeTimes + 1
		end
	elseif conditionId == ConditionProcess.conditionId.pvpContinuCount 
		or conditionId == ConditionProcess.conditionId.pvpScore then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	elseif conditionId == ConditionProcess.conditionId.singleRaceWin and args.battleResult == 1 and args.pvpType >= 0 then
		if (prams[1] or 0) == 0 or prams[1] == getBattleRace() then
			completeTimes = completeTimes + 1
		end
	elseif conditionId == ConditionProcess.conditionId.meetRank then        
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	elseif conditionId == ConditionProcess.conditionId.finishUnionActive then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onDrawCard(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.drawCard then
		completeTimes = completeTimes + (args.drawCardType == 1 and 1 or 10)
	end	
	return completeTimes
end

function ConditionProcess.onUseItem(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.useExpCard then
		local itemConf = getPropConfItem(args.itemId)
		if itemConf ~= nil then
			if itemConf.Type == UIAwardHelper.ItemType.ExpBook then
				completeTimes = completeTimes + 1
			end
		end
	end
	return completeTimes
end

function ConditionProcess.onTouchGloden(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.pointGold then
		completeTimes = completeTimes + 1
	end
	return completeTimes
end

function ConditionProcess.onReceiveCurrency(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.receiveGold and args.currencyType == UIAwardHelper.ResourceID.Gold 
		and args.currencyCount > 0 then			
		completeTimes = completeTimes + args.currencyCount
		ConditionProcess.receiveGold = completeTimes
	end
	return completeTimes
end

function ConditionProcess.onReceiveEquip(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.ownEquip then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onReceiveHero(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.ownHeroLevel or 
		conditionId == ConditionProcess.conditionId.ownHeroStar or 
		conditionId == ConditionProcess.conditionId.ownHeroSkillLevel or
		conditionId == ConditionProcess.conditionId.ownHero or 
		conditionId == ConditionProcess.conditionId.onwHeroStarCount then
			completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onReceiveSummoner(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.ownSummonerCount or 
		conditionId == ConditionProcess.conditionId.ownSummonerID then
			completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onDressEquip(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.heroWearEquip then
		local pram1 = prams[1] or 0
		local eqConfId = getGameModel():getEquipModel():getEquipConfId(args.equipId)
		if eqConfId ~= nil then
			local eqConf = getEquipmentConfItem(eqConfId)
			if eqConf ~= nil then
				if pram1 == Parts or pram1 == 0 then
					completeTimes = completeTimes + 1
				end
			end
		end
	end
	return completeTimes
end

function ConditionProcess.onHeroUpgradeLevel(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.heroUpLevel then
		local pram1 = prams[1] or 0
		local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(args.heroId)
		if heroCard ~= nil and (heroCard:getLevel() >= pram1 or pram1 == 0) then
			completeTimes = completeTimes + 1
		end
	elseif conditionId == ConditionProcess.conditionId.ownHeroLevel then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onHeroUpgradeStar(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.heroUpStar then
		local pram1 = prams[1] or 0
		local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(args.heroId)
		if heroCard ~= nil and (heroCard:getStar() >= pram1 or pram1 == 0) then
			completeTimes = completeTimes + 1
		end
	elseif conditionId == ConditionProcess.conditionId.ownHeroStar or 
		conditionId == ConditionProcess.conditionId.onwHeroStarCount then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onHeroUpgradeSkill(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.heroUpSkill then
		local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(args.heroId)
		if heroCard ~= nil then
			local skillLv = heroCard:getSkills()[args.skillId] or 0
			if skillLv >= (prams[1] or 0) then
				completeTimes = completeTimes + 1
			end
		end
	elseif conditionId == ConditionProcess.conditionId.ownHeroSkillLevel then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onPlayerUpgradeLevel(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.userLevel then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onFinishTask(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.finishUnionTask then
		local pram1 = prams[1] or 0
		if pram1 == 0 then
			if args.taskType == taskType.unionPresonal or args.taskType == taskType.unionTeam then
				completeTimes = completeTimes + 1
			end
		elseif pram1 == 1 then
			if args.taskType == taskType.unionPresonal then
				completeTimes = completeTimes + 1
			end
		elseif pram1 == 2 then
			if args.taskType == taskType.unionTeam then
				completeTimes = completeTimes + 1
			end
		end
	end
	return completeTimes
end

function ConditionProcess.onBuyMonthCard(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.monthCard then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onOwnUnion(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.onwUnion then
		completeTimes = ConditionProcess.getStateTaskCompleteTimes(conditionId, prams, 0)
	end
	return completeTimes
end

function ConditionProcess.onShopBuy(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.shopBuy then
		completeTimes = completeTimes + 1
	end
	return completeTimes
end

function ConditionProcess.onDispatchMercenary(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.dispatchMercenary then
		completeTimes = completeTimes + 1
	end
	return completeTimes
end

function ConditionProcess.onUseMercenary(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.useMercenary then
		completeTimes = completeTimes + 1
	end
	return completeTimes
end

function ConditionProcess.onEquipMake(conditionId, prams, completeTimes, args)
	if conditionId == ConditionProcess.conditionId.equipMake then
		if args.quality >= (prams[1] or 0) then
			completeTimes = completeTimes + 1
		end
	end
	return completeTimes
end

-- 条件对应函数
ConditionProcess.ConditionCallbacks = {
	[GameEvents.EventStageOver] 		= ConditionProcess.onStageOver,
	[GameEvents.EventHeroTestStageOver] = ConditionProcess.onHeroTestStageOver,
	[GameEvents.EventGoldTestStageOver] = ConditionProcess.onGoldTestStageOver,
	[GameEvents.EventTowerTestStageOver]= ConditionProcess.onTowerTestStageOver,
	[GameEvents.EventFBTestStageOver] 	= ConditionProcess.onFBTestStageOver,
	[GameEvents.EventPVPOver] 			= ConditionProcess.onPVPOver,
	[GameEvents.EventDrawCard] 			= ConditionProcess.onDrawCard,
	[GameEvents.EventUseItem] 			= ConditionProcess.onUseItem,
	[GameEvents.EventTouchGloden] 		= ConditionProcess.onTouchGloden,
	[GameEvents.EventReceiveCurrency] 	= ConditionProcess.onReceiveCurrency,
	[GameEvents.EventReceiveEquip]		= ConditionProcess.onReceiveEquip,
	[GameEvents.EventReceiveHero]		= ConditionProcess.onReceiveHero,
	[GameEvents.EventReceiveSummoner]	= ConditionProcess.onReceiveSummoner,
	[GameEvents.EventDressEquip] 		= ConditionProcess.onDressEquip,
	[GameEvents.EventHeroUpgradeLevel] 	= ConditionProcess.onHeroUpgradeLevel,
	[GameEvents.EventHeroUpgradeStar]	= ConditionProcess.onHeroUpgradeStar,
	[GameEvents.EventHeroUpgradeSkill] 	= ConditionProcess.onHeroUpgradeSkill,
	[GameEvents.EventPlayerUpgradeLevel]= ConditionProcess.onPlayerUpgradeLevel,
	[GameEvents.EventFinishTask] 		= ConditionProcess.onFinishTask,
	[GameEvents.EventBuyMonthCard]		= ConditionProcess.onBuyMonthCard,
	[GameEvents.EventOwnUnion]			= ConditionProcess.onOwnUnion,
	[GameEvents.EventShopBuy]			= ConditionProcess.onShopBuy,
	[GameEvents.EventDispatchMercenary]	= ConditionProcess.onDispatchMercenary,
	[GameEvents.EventUseMercenary]		= ConditionProcess.onUseMercenary,
	[GameEvents.EventEquipMake]			= ConditionProcess.onEquipMake,
}

return ConditionProcess