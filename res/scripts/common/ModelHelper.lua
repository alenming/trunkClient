--[[
    模型相关操作
]]

local scheduler = require("framework.scheduler") 
ModelHelper = ModelHelper or {}
ModelHelper.AllTimer = ModelHelper.AllTimer or {}
-- 统一刷新时间
ModelHelper.AllRefreshTime = {H = math.floor(getTimeRecoverSetting().AllTimeReset / 60),
    M = math.floor(getTimeRecoverSetting().AllTimeReset % 60), S = 0}

-- 天赋状态：未解锁、解锁、开启、激活、装备激活, 解锁动画
ModelHelper.talentStatus = {Lock = 0, UnLock = 1, UnActive = 2, Active = 3, EquipActive = 4, UnLockAct = 5} 
ModelHelper.teamType = {Pass = 0, Arena = 1}    -- 队伍类型 通关、竞技
ModelHelper.equipStatus = {equip = 1, noEquip = 2, lv = 3, vocation = 4}    -- 装备显示状态

local EQUIP_REF = 1000000
local ChampionTimeInit = false
local resetTime = 0

function ModelHelper.init()
    -- 初始化所有的重置时间活动
    ModelHelper.initTimer()
end

--重置时间(数据)-------------------------------------------------------------------

function ModelHelper.initTimer()
    resetTime = getNextTimeStamp(getGameModel():getNow(), ModelHelper.AllRefreshTime.M
        , ModelHelper.AllRefreshTime.H) + 5

    ModelHelper.schedulePerSecond()
end

function ModelHelper.getCurTime()
    local now = getGameModel():getNow()
    local y = tonumber(os.date("%Y", now))
    local w = tonumber(os.date("%w", now))
    local h = tonumber(os.date("%H", now))
    local m = tonumber(os.date("%M", now))
    local s = tonumber(os.date("%S", now))
    local d = tonumber(os.date("%d", now))
    local month = tonumber(os.date("%m", now))
    w = w == 0 and 7 or w

    return {now = now, y = y, w = w, h = h, m = m, s = s, d = d, month = month}
end

function ModelHelper.schedulePerSecond()
    ModelHelper.allTimer = {}
    local gameModel = getGameModel()
    local userModel = gameModel:getUserModel()
    local curTime = ModelHelper.getCurTime()
    -- 1、神秘商店刷新
    local shopData = gameModel:getShopModel():getShopModelData(1)
    if shopData then
        local nextTime = shopData.nNextFreshTime
        local interval = getShopTypeData(1).nFreshTime * 60
        while nextTime < curTime.now do
            nextTime = nextTime + interval
        end

        ModelHelper.addTimer(nextTime, {system = RedPointHelper.System.Shop, time = nextTime})
    end

    -- 2、活动整点
    local operateActivityModel = gameModel:getOperateActiveModel()
    local activityData = operateActivityModel:getActiveData()
    for _, activityInfo in pairs(activityData) do
        -- 该活动为开启
        if curTime.now >= activityInfo.startTime and curTime.now < activityInfo.endTime then
            -- 活动类型(3)为任务的整点在线(9)
            if 3 == activityInfo.activeType then
                local allTask = operateActivityModel:getActiveTaskData(activityInfo.activeID) or {}
                for _, taskInfo in pairs(allTask) do
                    -- 未到时间未领取
                    if 0 == taskInfo.finishFlag 
                      and 9 == taskInfo.finishCondition 
                      and curTime.h < taskInfo.conditionParam[1] then
                        local nextTime = getNextTimeStamp(curTime.now, 0, taskInfo.conditionParam[1])
                        ModelHelper.addTimer(nextTime, {system = RedPointHelper.System.Activity, activeID = activityInfo.activeID})
                    end
                end
                
            end
        end
    end

    -- 3、任务整点

    -- 4、竞技场整点
    --ModelHelper.addArenaTime(true)

    -- 5、畅玩基金
    --ModelHelper.addBoonTime()

    if gameModel:getUnionModel():getHasUnion() then
        -- 6、远征时间
        ModelHelper.addExpeditionTime()
    end

    -- 开启每秒计时
    ModelHelper.perSecondSchedule = scheduler.scheduleGlobal(ModelHelper.perSecondCall, 1)
end

function ModelHelper.addArenaTime(isInit)
    if isInit then
        if ChampionTimeInit then
            return
        end
        ChampionTimeInit = true
    end

    local areanSetting = getArenaSetting()
    local curTime = ModelHelper.getCurTime()
    
    local function getNextChampionWDay(wday, startWday, endWday)
        wday = wday == 0 and 7 or wday
        if wday >= startWday and wday <= endWday then
            return wday
        end

        return startWday
    end

    local wday = 0
    -- 周几到周几
    if curTime.w >= areanSetting.ArenaDay[1] and curTime.w <= areanSetting.ArenaDay[2] then
        local n = curTime.h * 60 + curTime.m
        local startT = areanSetting.ArenaTime[1] * 60 + areanSetting.ArenaTime[2]
        local endT = areanSetting.ArenaTime[3] * 60 + areanSetting.ArenaTime[4]
        -- 处于开启阶段,增加红点并添加下次开启定时器
        if n >= startT and n <= endT then
            local userLv = getGameModel():getUserModel():getUserLevel()
            if userLv >= getArenaLevel()[3] then
                RedPointHelper.setCount(RedPointHelper.System.Arena, 1, RedPointHelper.AreanSystem.ChampionOpen)
            end
            
            wday = getNextChampionWDay(curTime.w + 1, areanSetting.ArenaDay[1], areanSetting.ArenaDay[2])
        -- 还未到开启时间 
        elseif n < startT then
            wday = curTime.w
            
        -- 下次(明天或下周)开启时间    
        else
            wday = getNextChampionWDay(curTime.w + 1, areanSetting.ArenaDay[1], areanSetting.ArenaDay[2])
        end
    else
        wday = areanSetting.ArenaDay[1]
    end

    local openTime = getWNextTimeStamp(curTime.now, areanSetting.ArenaTime[2], areanSetting.ArenaTime[1], wday)
    ModelHelper.addTimer(openTime, {system = RedPointHelper.System.Arena})
end

function ModelHelper.addBoonTime()
    local userModel = getGameModel():getUserModel()
    local curTime = ModelHelper.getCurTime()
    -- 开始时间
    local startTime = userModel:getFundStartFlag()  
    local endTime = startTime + GetFirstPayData().GetTimes * 86400
    if startTime > 0 and curTime.now < endTime then
        -- 今天是否领取
        local nextZeroTime = getNextTimeStamp(curTime.now, 0, 0)
        if (curTime.month > month or (curTime.month == month and curTime.d ~= day))
          and curTime.now < nextZeroTime then
            RedPointHelper.addBoonRed()
        end

        -- 下次领取时间
        if nextZeroTime <= endTime then
            ModelHelper.addTimer(nextZeroTime, {system = RedPointHelper.System.Boon})
        end
    end
end

function ModelHelper.addExpeditionTime()
    local expeditionModel = getGameModel():getExpeditionModel()
    -- 还没到开启时间
    if expeditionModel:getRestEndTime() > getGameModel():getNow() then
        ModelHelper.addTimer(expeditionModel:getRestEndTime(), {expedition = 1})
    end

    -- 远征结束时间
    if expeditionModel:getWarEndTime() > getGameModel():getNow() then
        ModelHelper.addTimer(expeditionModel:getWarEndTime(), {expedition = 2})
    end
end

function ModelHelper.addTimer(time, data)
    if "number" ~= type(time) then
        return
    end

    if not ModelHelper.allTimer[time] then
        ModelHelper.allTimer[time] = {}
    end

    table.insert(ModelHelper.allTimer[time], data)
end

function ModelHelper.perSecondCall(dt)
    local now = getGameModel():getNow()
    for time, datas in pairs(ModelHelper.allTimer) do
        if now >= time then
            for _, data in pairs(datas) do
                EventManager:raiseEvent(GameEvents.EventTimeCall, data)
            end

            ModelHelper.allTimer[time] = nil
        end
    end

    if now >= resetTime then
        resetTime = getNextTimeStamp(now, ModelHelper.AllRefreshTime.M
            , ModelHelper.AllRefreshTime.H) + 5
        ModelHelper.onTimeToResetData()
    end
end

-- 统一刷新时间
function ModelHelper.onTimeToResetData()
    local gameModel = getGameModel()
    -- 恢复体力以及体力购买次数
    local userModel = gameModel:getUserModel()
    userModel:setFreeHeroTimes(1)
    userModel:setBuyGoldTimes(0)

    -- 金币试炼模型刷新
    local goldTestModel = gameModel:getGoldTestModel()
    goldTestModel:resetGoldTest(goldTestModel:getStamp()+86400) 
    -- pvp模型刷新
    local pvpModel = gameModel:getPvpModel()
    pvpModel:resetPvp()
    -- 英雄试炼模型刷新
    local heroTestModel = gameModel:getHeroTestModel()
    heroTestModel:resetHeroTest(heroTestModel:getHeroTestStamp()+86400)
    -- 公会模型
    local unionModel = gameModel:getUnionModel()
    if not unionModel:getHasUnion() then
        unionModel:setApplyCount(0)
        unionModel:setOriginUnionLv(unionModel:getUnionLv())
    else
        unionModel:setTodayStageLiveness(0)
        unionModel:setTodayPvpLiveness(0)
        unionModel:setWelfareTag(0)
    end
    -- 远征挑战次数刷新
    local expeditionModel = getGameModel():getExpeditionModel()
    expeditionModel:resetFightCount(0)

    -- 七天活动刷新
    local cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.SevenCrazySC)
    --local mCallBack = handler(self, self.sevenDayCallBack)
    NetHelper.setResponeHandler(cmd, ModelHelper.sevenDayCallBack)

    --公会佣兵
    getGameModel():getUnionMercenaryModel():updateReFresh() 

    -- 签到要修改数据
    getGameModel():getUserModel():setDaySignFlag(0)

    local buffData = NetHelper.createBufferData(MainProtocol.Login, CommonProtocol.RefreshCS)
    NetHelper.request(buffData)
    -- 蓝钻啊大厅什么的 0点刷新这里触发
    getGameModel():getBlueGemModel():updateToRefreshUI()

    --爬塔刷新
    getGameModel():getTowerTestModel():updateUI()
    --------------------------------------------------------------
    -- 红点刷新
    RedPointHelper.dataReset()
end

--HeroModel-------------------------------------------------------------------------------------------
-- 统计卡片数量
function ModelHelper.GetHeroCount()
	local heroCount = {}
	
	-- C++模型管理,单例
	local gameModel = getGameModel()
	-- 获取英雄模型
	local heroCardBagModel = gameModel:getHeroCardBagModel()
	-- 获取英雄ID列表
	local heroCardIDList = heroCardBagModel:getHeroCards()
	
	for _, heroID in pairs(heroCardIDList) do
		local heroModel = heroCardBagModel:getHeroCard(heroID)
		local heroCardID = heroModel:getCardID()
        local heroStar = heroModel:getStar()
		heroCount[heroCardID] = heroCount[heroCardID] or {}
        heroCount[heroCardID][heroStar] = (heroCount[heroCardID][heroStar] or 0) + 1
	end
	
	return heroCount
end

-- 添加英雄 返回(类型 + 数量)
-- 类型: 1. 整卡 2.碎片 3. 粉尘
function ModelHelper.AddHero(heroID, heroLv, starLv)
    print("=============ModelHelper.AddHero============", heroID)
    -- 判断是否有整卡
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    local heroCardModel = heroCardBagModel:getHeroCard(heroID)

    if heroCardModel and heroCardModel:getStar() ~= 0 then
        local starSettingConf = getSoldierStarSettingConfItem(starLv)
        if not starSettingConf then print("starSettingConf is nil", starLv) end

        return ModelHelper.addFrag(heroID, starSettingConf.TurnFragCount)
    else
        if not heroCardModel then
            -- 没有模型, 创建一个模型
            heroCardBagModel:addHeroCard(heroID)
            heroCardModel = heroCardBagModel:getHeroCard(heroID)
        end

        heroCardModel:setStar(starLv)
        heroCardModel:setLevel(heroLv)
        heroCardModel:setExp(0)
        heroCardModel:setTalent({0,0,0,0,0,0,0,0})
        EventManager:raiseEvent(GameEvents.EventReceiveHero, { heroId = heroID})

        return 1, 1
    end
end

-- 添加碎片 返回(类型 + 数量)
-- 类型: 2.碎片 3. 粉尘
function ModelHelper.addFrag(heroID, count)
    -- 判断是否存在该英雄模型
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    local heroCardModel = heroCardBagModel:getHeroCard(heroID)
    if not heroCardModel then
        -- 没有该模型, 创建新的模型
        heroCardBagModel:addHeroCard(heroID)
        heroCardModel = heroCardBagModel:getHeroCard(heroID)
    end

    local upRateConf = getSoldierUpRateConfItem(heroID)
    if not upRateConf then print("upRateConf is nil", heroID) end
    if heroCardModel:getStar() < upRateConf.TopStar then
        -- 不是最高星级, 将碎片添加到模型
        heroCardModel:setFrag(heroCardModel:getFrag() + count)
        RedPointHelper.singleHeroRedPoint(heroID, RedPointHelper.HeroSystem.Star, true)
        return 2, count
    else
        -- 最高星级, 将碎片转化成金币后添加到模型
        local dustCount = getCardGambleSettingConfItem().exchangeRatio * count
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, dustCount)
        return 3, dustCount
    end
end

function ModelHelper.AddSummoner(summonerID)
    local summonersModel = getGameModel():getSummonersModel()
    summonersModel:addSummoner(summonerID)

    EventManager:raiseEvent(GameEvents.EventReceiveSummoner, { summonerId = summonerID })
end

-- 英雄升级
function ModelHelper.upgradeHeroLv(heroId, addExp, limitLv)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
    if not heroModel then
        print("cann't find heroModel,", heroId)
        return
    end
    
    local userModel = getGameModel():getUserModel()
    local userLv    = userModel:getUserLevel()
    local preLevel  = heroModel:getLevel()
    local heroLv    = preLevel
    local heroExp   = heroModel:getExp() + addExp
    local starLvConf= getSoldierStarSettingConfItem(heroModel:getStar())
    local heroMaxLv = starLvConf.TopLevel

    if not limitLv then
        limitLv = 15
    end

    local curHeroMax = heroMaxLv
    if userLv <= limitLv then
        if heroMaxLv > limitLv then
            curHeroMax = limitLv
        end
    else
        if heroMaxLv >= userLv then
            curHeroMax = userLv
        end
    end

    if heroLv >= curHeroMax then
        return
    end

    for i=heroLv, heroMaxLv do
        local nextLvExp = getSoldierLevelSettingConfItem(heroLv + 1).Exp
        if heroExp - nextLvExp >= 0 then
            heroLv = i + 1
            if heroLv >= curHeroMax then
                heroExp = 0
                break
            else
                heroExp = heroExp - nextLvExp
            end
        else
            break
        end
    end

    heroModel:setLevel(heroLv)
    heroModel:setExp(heroExp)
    EventManager:raiseEvent(GameEvents.EventHeroUpgradeLevel, { heroId = heroId, preLevel = preLevel })
end

-- 英雄穿装备
function ModelHelper.heroDressEq(heroId, equipId)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
    if not heroModel then
        print("cann't find heroModel,", heroId)
        return
    end

    local eqConfId = getGameModel():getEquipModel():getEquipConfId(equipId)
    if eqConfId == nil and eqConfId ~= 0 then print("no find equip in ModelHelper.heroUndressEq") return end
    
    local eqConf = getEquipmentConfItem(eqConfId)
    if eqConf == nil then print("no find equip by id", eqConfId) return end

    -- 先卸载原来的装备
    ModelHelper.heroUndressEq(heroId, eqConf.Parts)


    if not getGameModel():getBagModel():removeItem(equipId) then
        print("bag remove equip fail,", equipId)
        return
    end

    heroModel:setEquip(eqConf.Parts, equipId)

    EventManager:raiseEvent(GameEvents.EventDressEquip, { heroId = heroId, equipId = equipId })
end

-- 英雄卸载装备
function ModelHelper.heroUndressEq(heroId, part)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
    if heroModel == nil then print("no find hero in ModelHelper.heroUndressEq") return end

    local eqsDyId = heroModel:getEquips()
    if eqsDyId[part] ~= 0 then
        local eqConfId = getGameModel():getEquipModel():getEquipConfId(eqsDyId[part])
        if eqConfId == nil or eqConfId == 0 then print("no find equip in ModelHelper.heroUndressEq") return end

        if not getGameModel():getBagModel():addItem(eqsDyId[part], eqConfId) then
            print("bag add equip fail, equipId, eqConfId", equipId, eqConfId)
        end
        heroModel:setEquip(part, 0)
    end

    EventManager:raiseEvent(GameEvents.EventUnDressEquip, { heroId = heroId })
end

-- 英雄升星
function ModelHelper.upgradeHeroStar(heroId, star)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
    if not heroModel then
        print("cann't find heroModel,", heroId)
        return
    end
    local soldierStarConf = getSoldierStarSettingConfItem(star)
    if not soldierStarConf then print("soldierStarConf is nil", heroId) return end

    -- 记录需要解锁的天赋
    if heroModel:getStar() ~= star then
        UserDatas.setBoolForKey("talent_" .. heroId .. "_" .. star, true)
    end
    -- 删除材料
    heroModel:setFrag(heroModel:getFrag() - soldierStarConf.UpStarCount)
    -- 扣除金币
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -soldierStarConf.UpStarCost)
    -- 设置星级
    heroModel:setStar(star)

    local soldierUpRateConf = getSoldierUpRateConfItem(heroId)
    if not soldierUpRateConf then print("soldierUpRateConf is nil", heroId) return end
    if star >= soldierUpRateConf.TopStar then
        -- 到达最高星级, 将碎片转化成粉尘
        local addDustCount = getCardGambleSettingConfItem().exchangeRatio * heroModel:getFrag()
        if heroModel:getFrag() ~= 0 then
            CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(144), heroModel:getFrag(), addDustCount))
        end
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, addDustCount)
        heroModel:setFrag(0)
    end

    EventManager:raiseEvent(GameEvents.EventHeroUpgradeStar, { heroId = heroId })
end

--HeroModel-------------------------------------------------------------------------------------------

--BagModel--------------------------------------------------------------------------------------------

-- eqDynID, eqConfID, {eqEffectIDs}, {eqEffectValues}
function ModelHelper.addEquip(equipId, confId, eqMainPropNum, eqEffectIDs, eqEffectValues)
	local bagModel = getGameModel():getBagModel()
	local eqModel = getGameModel():getEquipModel()
	eqModel:addEquip(equipId, confId,eqMainPropNum, eqEffectIDs, eqEffectValues)
	bagModel:addItem(equipId, confId)

    EventManager:raiseEvent(GameEvents.EventReceiveEquip, { equipId = equipId })
end

function ModelHelper.addItem(confID, count)
    local propConf = getPropConfItem(confID)
    if not propConf then print("propConf is nil", confID) end

    if propConf.Type == UIAwardHelper.ItemType.Frag then
        ModelHelper.addFrag(propConf.TypeParam[1], count)
    else
        getGameModel():getBagModel():addItem(confID, count)
        EventManager:raiseEvent(GameEvents.EventReceiveItem, { itemId = confID, itemCount = count })
    end    
end

-- 移除道具/装备
local function removeItem(itemId, itemVal)
    local bagModel = getGameModel():getBagModel()
    if itemId > EQUIP_REF then
        getGameModel():getEquipModel():removeEquip(itemId)
        bagModel:removeItems(itemId, itemVal)
    else
        bagModel:removeItems(itemId, itemVal)
    end
end

function ModelHelper.saleItem(itemId, itemVal)
    removeItem(itemId, itemVal)

    EventManager:raiseEvent(GameEvents.EventSaleItem, { itemId = itemId, itemCount = itemVal })
end

-- 该接口只适合英雄升级使用经验书和技能书!
function ModelHelper.useItem(confID, count)
    removeItem(confID, count)
       
    EventManager:raiseEvent(GameEvents.EventUseItem, { itemId = confID, itemCount = count })
end

--BagModel--------------------------------------------------------------------------------------------

--UserModel-------------------------------------------------------------------------------------------

function ModelHelper.addCurrency(type, count)
	if count == 0 then return end

	local userModel = getGameModel():getUserModel()
	if type == UIAwardHelper.ResourceID.Gold then
		userModel:setGold(userModel:getGold() + count)
		-- 刷新金币显示
		EventManager:raiseEvent(GameEvents.EventUpdateGold)

	elseif type == UIAwardHelper.ResourceID.Diamond then
		userModel:setDiamond(userModel:getDiamond() + count)
		-- 刷新钻石显示
		EventManager:raiseEvent(GameEvents.EventUpdateDiamond)

	elseif type == UIAwardHelper.ResourceID.PvpCoin then
		userModel:setPVPCoin(userModel:getPVPCoin() + count)

	elseif type == UIAwardHelper.ResourceID.TowerCoin then
		userModel:setTowerCoin(userModel:getTowerCoin() + count)

	elseif type == UIAwardHelper.ResourceID.Energy then

	elseif type == UIAwardHelper.ResourceID.UnionContrib then
		userModel:setUnionContrib(userModel:getUnionContrib() + count)

	elseif type == UIAwardHelper.ResourceID.Exp then
		local addExp = count
		local userLv = userModel:getUserLevel()
	    local preLevel = userLv
		local userExp = userModel:getUserExp()
		while(true) do
			if userLv <= getUserMaxLevel() then
				local userLevelItem = getUserLevelSettingConfItem(userLv)
				local upLevelExp = userLevelItem.Exp
				if addExp + userExp >= upLevelExp then
					addExp = addExp + userExp - upLevelExp
					userExp = 0
					userLv = userLv + 1
				else
					addExp = addExp + userExp
					break
				end
			else
				userLv = userLv - 1
				addExp = getUserLevelSettingConfItem(userLv).Exp
				break
			end
		end
		userModel:setUserLevel(userLv)
		userModel:setUserExp(addExp)
	    
		-- 升级监听
	    EventManager:raiseEvent(GameEvents.EventUpdateLvExp, { lv = userLv, exp = addExp })
	    EventManager:raiseEvent(GameEvents.EventPlayerUpgradeLevel, { preLevel = preLevel })

    elseif type == UIAwardHelper.ResourceID.Flashcard then
        userModel:setFlashcard(userModel:getFlashcard() + count)
    elseif type == UIAwardHelper.ResourceID.Flashcard10 then
        userModel:setFlashcard10(userModel:getFlashcard10() + count)
	end

	EventManager:raiseEvent(GameEvents.EventReceiveCurrency, {currencyType = type, currencyCount = count})
end

--UserModel-------------------------------------------------------------------------------------------

--MailModel-----------------------------------------------------------------------------------------------

--UnionModel------------------------------------------------------------------------------------------

--StageModel------------------------------------------------------------------------------------------

--HeadModel  begin------------------------------------------------------------------------------------------
function ModelHelper.addHead(headID)
    local headModel = getGameModel():getHeadModel()
    headModel:addHead(headID)

    EventManager:raiseEvent(GameEvents.EventReceiveHead, headID)
end
--HeadModel    end------------------------------------------------------------------------------------------

--Other------------------------------------------------------------------------------------------
-- 检测背包是否放得下
function ModelHelper.checkBagCapacity(id, count)
    local propCfg = getPropConfItem(id)
    if not propCfg then
        print("can't find item in config, getPropConfItem is nil", id)
        return false
    end

    local gameModel = getGameModel()
    local bagModel = gameModel:getBagModel()
    local items = bagModel:getItems()
    local capacity = bagModel:getCurCapacity()
    local curItemCount = bagModel:getItemCount()

    local needCount = 0
    if 1 == propCfg.Type then -- 装备都占一格
        needCount = needCount + count
    elseif 3 == propCfg.Type or 4 == propCfg.Type then
        -- nothing
    else
        if not items[id] or items[id] <= 0 then -- 道具已经拥有不占格子(叠加)
            needCount = needCount + 1
        end
    end

    return curItemCount + needCount <= capacity
end

--战斗------------------------------------------------------------------------------------------
function ModelHelper.getBattleSoldiersInfo()
    local soldiersInfo = {}

    local userID = getGameModel():getUserModel():getUserID()
    local playModel = getGameModel():getRoom():getPlayer(userID)
    if playModel then
        for i=0, 7 do
            info = playModel:getSoldierInfo(i)
            if info ~= nil then
                table.insert(soldiersInfo, {id = info.Id, star = info.Star})
            end
        end
    end
    return soldiersInfo
end

function ModelHelper.sevenDayCallBack(mainCmd, subCmd, buffData)
    --数据刷新前对界面做处理
    print("七天活动数据过一天请求")
    getGameModel():getSevenCrazyModel():init(buffData)
    getGameModel():getSevenCrazyModel():RefreshUI()

    --签到过一天刷新UI
    if(UIManager.getUI(UIManager.UI.UISignIn)) then
        UIManager.getUI(UIManager.UI.UISignIn):ReFreshUI()
    end
end

return ModelHelper