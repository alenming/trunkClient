--[[
红点提示功能
]]

RedPointHelper = {}
-- 红点系统
RedPointHelper.System = 
{
    Invalid = 0,             -- 无效
    DrawCard = 1,            -- 抽卡,免费抽卡+抽卡卷数量
    Mail = 2,                -- 邮件,未读邮件
    WorldMap = 3,            -- 世界地图,宝箱领取
    Summoner = 4,            -- 召唤师,新召唤师
    TaskAndAchieve = 5,      -- 任务与成就,未领取
    Bag = 6,                 -- 背包,新道具
    Shop = 7,                -- 商店,神秘商店刷新
    Hero = 8,                -- 英雄,升星、装备、天赋
    Activity = 9,            -- 活动,未查看+未领取
    Sign = 10,               -- 签到
    Arena = 11,              -- 竞技场,未领取
    FB = 12,                 -- 副本,金币试炼、英雄试炼、爬塔试炼
    HeadUnlock = 13,         -- 头像解锁,新头像
    Boon = 14,               -- 首充福利
    Union = 15,              -- 公会,可审核可领取福利
    SevenDay = 16,           -- 七天活动
    EquipMake = 17,          -- 装备打造
}

-- 英雄系统
RedPointHelper.HeroSystem = 
{
    Star = 1,                -- 升星,碎片足够升星或召唤
    Equip = 2,               -- 装备,可穿戴(更好)装备
    Talent = 3               -- 天赋,可解锁
}

-- 副本系统
RedPointHelper.FBSystem = 
{
    Gold = 1,                -- 金币试炼,次数
    Hero = 2,                -- 英雄试炼,次数
    Tower = 3,               -- 爬塔试炼,次数
    Instance = 4             -- 活动副本
}

-- 公会系统
RedPointHelper.UnionSystem = 
{
    HasUnion = -1,           -- 是否有公会
    Liveness = 0,            -- 活跃度
    Audit = 1,               -- 审核
    ExpiditionReward = 2,    -- 远征奖励
}

-- 竞技场系统
RedPointHelper.AreanSystem = 
{
    ChampionOpen = 0,        -- 锦标赛开启
    ChampionAward = 1,       -- 锦标赛奖励
    ArenaChest = 2,          -- 竞技场宝箱
}

local gameModel = getGameModel()
local userModel = gameModel:getUserModel()
local mailModel = gameModel:getMailModel()
local pvpModel = gameModel:getPvpModel()
local pvpChestModel = gameModel:getPvpChestModel()
local taskModel = gameModel:getTaskModel()
local achieveModel = gameModel:getAchieveModel()
local goldTestModel = gameModel:getGoldTestModel()
local heroTestModel = gameModel:getHeroTestModel()
local towerTestModel = gameModel:getTowerTestModel()
local stageModel = gameModel:getStageModel()
local heroBagModel = gameModel:getHeroCardBagModel()
local equipModel = gameModel:getEquipModel()
local bagModel = gameModel:getBagModel()
local operateActivityModel = gameModel:getOperateActiveModel()
local SevenCrazyModel = gameModel:getSevenCrazyModel()
local unionModel = gameModel:getUnionModel()
local blueGemModel = gameModel:getBlueGemModel()

local EquipRef = 1000000
local UserDefault = {OWEND_ITEM = "OWNED_ITEM", OLD_ACTIVITY = "OLD_ACTIVITY", PRE_UNION = "PRE_UNION"}
-- 道具已经获取
local OwnedItems = {}
-- 已经查看过的(旧)活动
local OldActivity = {}
-- 各英雄各系统的红点数
local AllHeroRedPointCount = {}
RedPointHelper.SystemInfo = {}

-- 保存一连串+的字符,如数据1+数据2...
local function saveStringToXML(key, value)
    local str = UserDatas.getStringForKey(key, "")
    if "" == str then
        UserDatas.setStringForKey(key, value)
    else
        UserDatas.setStringForKey(key, str.."+"..value)
    end
end

function RedPointHelper.init()
    -- 1、初始化各个系统红点信息
    RedPointHelper.initSystemInfo()

    -- 2、监听相应的事件
    local events = {"EventCloseUI", "EventReceiveHead", "EventReceiveSummoner", "EventReceiveCurrency"
        , "EventReceiveEquip", "EventReceiveHero", "EventReceiveItem", "EventHeroUpgradeStar"
        , "EventDressEquip", "EventDrawCard", "EventHeroTestStageOver", "EventGoldTestStageOver"
        , "EventTowerTestStageOver", "EventStageOver", "EventPVPOver", "EventSaleItem", "EventFinishTask"
        , "EventUnDressEquip", "EventSetTalent", "EventSeeActivity", "EventOperateActiveUpdate"
        , "EventUseItem", "EventOpenUI", "EventExpeditionAwardFlag"}
    for _, event in pairs(events) do
        EventManager:addEventListener(GameEvents[event], RedPointHelper.eventProcess)
    end
end

function RedPointHelper.initSystemInfo()
    RedPointHelper.SystemInfo = {} 
    for _, v in pairs(RedPointHelper.System) do
        if v == RedPointHelper.System.DrawCard
          or v == RedPointHelper.System.Mail
          or v == RedPointHelper.System.Sign
          or v == RedPointHelper.System.Shop
          or v == RedPointHelper.System.Boon then
            RedPointHelper.SystemInfo[v] = 0
        else
            RedPointHelper.SystemInfo[v] = {}
        end
    end

    -- 模型数据
    -- 抽卡
    RedPointHelper.drawCard()
    -- 邮件
    RedPointHelper.mail()
    -- 世界地图
    RedPointHelper.worldMap()
    -- 任务和成就
    RedPointHelper.taskAndAchieve()
    -- 试炼副本
    RedPointHelper.trail()
    -- 背包
    RedPointHelper.bag()
    -- 英雄
    RedPointHelper.heroRedPoint()
    -- 活动
    RedPointHelper.activity()
    -- 签到
    RedPointHelper.sign()
    -- 商店(神秘商店)

    -- 竞技场
    RedPointHelper.arena()
    -- 首充福利
    RedPointHelper.boon()
    -- 公会
    RedPointHelper.union()
    -- 七天
    RedPointHelper.sevenDay()
end

-- 数据重置导致红点变化
function RedPointHelper.dataReset()
    RedPointHelper.sign()
    RedPointHelper.arena()
    RedPointHelper.trail()
    RedPointHelper.drawCard()
    RedPointHelper.taskAndAchieve()
    RedPointHelper.union()
    RedPointHelper.activity()
    -- 通知刷新主按钮红点
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

function RedPointHelper.mail()
    RedPointHelper.SystemInfo[RedPointHelper.System.Mail] = 0
    local mailsData = mailModel:getMails()

    local count = 0
	-- 去掉超时邮件
	for k,v in pairs(mailsData) do
		if v.sendTimeStamp + MailHelper.validSce > getGameModel():getNow() then
			count = count + 1
		end
	end
    RedPointHelper.SystemInfo[RedPointHelper.System.Mail] = count
end

function RedPointHelper.drawCard()
    RedPointHelper.SystemInfo[RedPointHelper.System.DrawCard] = 
        (userModel:getFreeHeroTimes() > 0 and 1 or 0) + userModel:getFlashcard()+userModel:getFlashcard10()
end

function RedPointHelper.sign()
    RedPointHelper.SystemInfo[RedPointHelper.System.Sign] = 0 == userModel:getDaySignFlag() and 1 or 0
end

function RedPointHelper.arena()
    RedPointHelper.SystemInfo[RedPointHelper.System.Arena] = {}
    -- 竞技场宝箱
    RedPointHelper.arenaChest()

    -- 锦标赛奖励
--    local curTime = gameModel:getNow()
--    local pvpInfo = pvpModel:getPvpInfo()
--    if pvpInfo.CpnWeekResetStamp < curTime
--      and pvpInfo.CpnGradingNum > 0 then
--        RedPointHelper.SystemInfo[RedPointHelper.System.Arena][RedPointHelper.AreanSystem.ChampionAward] = 1
--    end
end

function RedPointHelper.arenaChest()
    local pvpInfo = pvpModel:getPvpInfo()
    if pvpInfo.ChestStatus > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Arena][RedPointHelper.AreanSystem.ArenaChest] = 1
    end
end

function RedPointHelper.boon()
    -- 1、首充
    local vipPayment = userModel:getPayment()
    if vipPayment and vipPayment > 0 then
        -- 奖励状态(0未领取, 1已领取)
        if 0 == userModel:getFirstPayFlag() then
            RedPointHelper.SystemInfo[RedPointHelper.System.Boon] = 1
        end
    end
end

function RedPointHelper.union()
    RedPointHelper.SystemInfo[RedPointHelper.System.Union] = {}
    -- 1、公会从有到无或从无到有需红点
    local preUnionId = UserDatas.getIntegerForKey(UserDefault.PRE_UNION, 0)
    local hasUnion = unionModel:getHasUnion()
    if preUnionId > 0 and not hasUnion then
        RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] = 1
        UserDatas.setIntegerForKey(UserDefault.PRE_UNION, 0)
    elseif preUnionId <= 0 and hasUnion then
        RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] = 1
        UserDatas.setIntegerForKey(UserDefault.PRE_UNION, unionModel:getUnionID())
    end

    -- 后面的红点需要有公会
    if not hasUnion then
        return
    end

    -- 2、职位是否可审核
    if unionModel:getPos() > 0 then
       if unionModel:getHasAudit() == 1 then
           RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.Audit] = 1
       end
    end

    -- 3、福利是否可领取
    local unionConf = getUnionLevelConfItem(unionModel:getUnionLv())
	if not unionConf then
		print("unionLevelConf is nil ", unionModel:getUnionLv())
		return
	end
    
    local count = 0
    local liveness = unionModel:getUnionLiveness()
    local welfareTag = unionModel:getWelfareTag()
    if liveness >= unionConf.ActiveReward then
        if 0 == bit.band(welfareTag, bit.blshift(1, 0)) then
            count = count + 1
        end

        if liveness >= unionConf.ActiveSReward then
             if 0 == bit.band(welfareTag, bit.blshift(1, 1)) then
                count = count + 1
            end
        end

        if count > 0 then
            RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.Liveness] = count
        end
    end

    -- 4、远征红点
    if unionModel:getHasExpiditionReward() == 1 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.ExpiditionReward] = 1
    end
end

function RedPointHelper.sevenDay()
    RedPointHelper.SystemInfo[RedPointHelper.System.SevenDay] = {}
    local activityData = SevenCrazyModel:getActiveData()
    for _, activityInfo in pairs(activityData) do
        -- 该活动为开启
        if 3 == activityInfo.activeType then
            RedPointHelper.sevenDayTaskActivity(activityInfo.activeID)
        end
    end
end

function RedPointHelper.bag()
    local items = UserDatas.getStringForKey(UserDefault.OWEND_ITEM)
    items = string.split(items, "+")
    for _, itemId in pairs(items) do
        if itemId ~= "" then
            OwnedItems[tonumber(itemId)] = true
        end
    end

    local bagItems = bagModel:getItems()
    for id, v in pairs(bagItems) do
        local itemId = id > EquipRef and v or id

        if not OwnedItems[itemId] then
            OwnedItems[itemId] = true
            saveStringToXML(UserDefault.OWEND_ITEM, itemId)
        end
    end
end

function RedPointHelper.trail()
    local curTime = gameModel:getNow()
    local w = tonumber(os.date("%w", curTime))
    w = (w == 0 and 7 or w)
    
    -- 金币试炼
    local count = 0
    local goldTestConf = getGoldTestConfItem(w)
    count = goldTestConf.Frequency - goldTestModel:getCount()
    RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Gold] = count > 0 and count or nil
    -- 英雄试炼
    count = 0
    local list = getHeroTestItemList()
    for _, id in pairs(list) do
        local conf = getHeroTestConfItem(id)
        for _, t in pairs(conf.Time) do
            if t == w then
                count = count + conf.Times - heroTestModel:getHeroTestCount(id)
            end
        end
    end

    RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Hero] = count > 0 and count or nil
    -- 爬塔试炼
    --RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Tower] = 0--towerTestModel:getTowerTestTimes()
end

function RedPointHelper.worldMap()
    local chestBox = 0
    local states = stageModel:getChapterStates()
    for chapterId, state in pairs(states) do
        local conf = getChapterConfItem(chapterId)
        if nil == conf then
            print("redPoint conf==nil, chapterId ", chapterId)
            return
        end
        -- 章节状态为已经完成
        if 2 == state then
            local star = StageHelper.getChapterStar(chapterId)
            if star == conf.FullStar then
                chestBox = chestBox + 1
            end
        end
    end
    RedPointHelper.SystemInfo[RedPointHelper.System.WorldMap] = chestBox
end

function RedPointHelper.taskAndAchieve()
    local finishCount = 0
    for _, v in pairs(taskModel:getTasksData()) do
        if 1 == v.taskStatus then
            finishCount = finishCount + 1
        end
    end
    for _, v in pairs(achieveModel:getAchievesData()) do
        if 1 == v.achieveStatus then
            finishCount = finishCount + 1
        end
    end
    RedPointHelper.SystemInfo[RedPointHelper.System.TaskAndAchieve] = finishCount
end

-- 活动
function RedPointHelper.activity()
    RedPointHelper.SystemInfo[RedPointHelper.System.Activity] = {}
    local activitys = UserDatas.getStringForKey(UserDefault.OLD_ACTIVITY)
    activitys = string.split(activitys, "+")
    for _, activityId in pairs(activitys) do
        if activityId ~= "" then
            OldActivity[tonumber(activityId)] = true
        end
    end

    local curTime = gameModel:getNow()
    local activityData = operateActivityModel:getActiveData()
    for _, activityInfo in pairs(activityData) do
        -- 该活动为开启
        if 0 == activityInfo.timeType or (curTime >= activityInfo.startTime and curTime < activityInfo.endTime) then
            -- 根据活动类型
            if 1 == activityInfo.activeType then
                RedPointHelper.shopActivity(activityInfo.activeID)
            elseif 2 == activityInfo.activeType then
                RedPointHelper.dropActivity(activityInfo.activeID)
            elseif 3 == activityInfo.activeType then
                RedPointHelper.taskActivity(activityInfo.activeID)
            elseif 4 == activityInfo.activeType then
                RedPointHelper.monthCardActivity(activityInfo.activeID)
            elseif 5 == activityInfo.activeType then
                RedPointHelper.exchangeActivity(activityInfo.activeID)
            end
        end
    end
end

-- 兑换活动
function RedPointHelper.exchangeActivity(activeID)
    local count = 0
    -- 新活动+1
    if not OldActivity[activeID] then
        count = count + 1
    end

    local exchangeActivity = operateActivityModel:getExchangeData() or {}
    for _, info in pairs(exchangeActivity) do
        local acData = GetOperateActiveExchangeData(activeID, info.taskID)
        if acData and acData.Exchange_limit >= info.count then
            count = count + 1
        end
    end

    if count > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activeID] = count
    end
end

-- 月卡活动
function RedPointHelper.monthCardActivity(activeID)
    local count = 0
    -- 新活动+1
    if not OldActivity[activeID] then
        count = count + 1
    end

    local allCardTask = operateActivityModel:getMonthCardData() or {}
    for _, cardInfo in pairs(allCardTask) do
        if operateActivityModel:getCardState(activeID, cardInfo.cardID) == MonthCardState.STATE_REWARD then
            count = count + 1
        end
    end

    if count > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activeID] = count
    end
end

-- 任务活动
function RedPointHelper.taskActivity(activeID)
    local count = 0
    -- 新活动+1
    if not OldActivity[activeID] then
        count = count + 1
    end
    -- 有可以领取的任务+1
    local allTask = operateActivityModel:getActiveTaskData(activeID) or {}
    for _, taskInfo in pairs(allTask) do
        if 0 == taskInfo.finishFlag 
          and taskInfo.value >= taskInfo.conditionParam[1] then
            count = count + 1
        end
    end
    
    if count > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activeID] = count
    end
end

-- 掉落活动
function RedPointHelper.dropActivity(activeID)
    -- 新活动+1
    if not OldActivity[activeID] then
        RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activeID] = 1
    end
end

-- 商店活动
function RedPointHelper.shopActivity(activeID)
    local count = 0
    -- 新活动+1
    if not OldActivity[activeID] then
        count = count + 1
    end
    
--    local allTask = operateActivityModel:getActiveShopData(activeID) or {}
--    for _, taskInfo in pairs(allTask) do
--        if taskInfo.buyTimes < taskInfo.maxBuyTimes then
--            count = count + 1
--        end
--    end
    
    if count > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activeID] = count
    end
end

-- 七天任务
function RedPointHelper.sevenDayTaskActivity(activeID)
    local allTask = SevenCrazyModel:getActiveTaskData(activeID) or {}
    local count = 0
    for _, taskInfo in pairs(allTask) do
        if 0 == taskInfo.finishFlag 
          and taskInfo.value >= taskInfo.conditionParam[1] then
            count = count + 1
        end

        if count > 0 then
            RedPointHelper.SystemInfo[RedPointHelper.System.SevenDay][activeID] = count
        end
    end
end

-- 事件处理
function RedPointHelper.eventProcess(eventName, params)
    if eventName == GameEvents.EventCloseUI then
        RedPointHelper.closeUI(params)
    elseif eventName == GameEvents.EventOpenUI then
        RedPointHelper.openUI(params)

    elseif eventName == GameEvents.EventReceiveHead then
        RedPointHelper.SystemInfo[RedPointHelper.System.HeadUnlock][params] = true
        
    elseif eventName == GameEvents.EventReceiveSummoner then
        RedPointHelper.SystemInfo[RedPointHelper.System.Summoner][params.summonerId] = true

    elseif eventName == GameEvents.EventReceiveCurrency then
        RedPointHelper.receiveResource(params.currencyType, params.currencyCount)

    elseif eventName == GameEvents.EventDrawCard then
        -- 抽卡券+免费
        RedPointHelper.drawCard()

    elseif eventName == GameEvents.EventHeroTestStageOver
      or eventName == GameEvents.EventTowerTestStageOver 
      or eventName == GameEvents.EventGoldTestStageOver
      or eventName == GameEvents.EventPVPOver
      or eventName == GameEvents.EventStageOver then
        RedPointHelper.stageChallenge(eventName, params)

    elseif eventName == GameEvents.EventReceiveEquip then
        RedPointHelper.receiveItem(params.equipId)

    elseif eventName == GameEvents.EventDressEquip then
        RedPointHelper.useItemRedPoint(params.equipId)
        RedPointHelper.heroRedPoint(RedPointHelper.HeroSystem.Equip)
    elseif eventName == GameEvents.EventUnDressEquip then
        RedPointHelper.heroRedPoint(RedPointHelper.HeroSystem.Equip)
    elseif eventName == GameEvents.EventHeroUpgradeStar then
        -- 升星会开启天赋
        RedPointHelper.singleHeroRedPoint(params.heroId, RedPointHelper.HeroSystem.Star)
        RedPointHelper.singleHeroRedPoint(params.heroId, RedPointHelper.HeroSystem.Talent)
    elseif eventName == GameEvents.EventSetTalent then
        RedPointHelper.singleHeroRedPoint(params.heroId, RedPointHelper.HeroSystem.Talent)
    elseif eventName == GameEvents.EventReceiveHero then
        RedPointHelper.singleHeroRedPoint(params.heroId)

    elseif eventName == GameEvents.EventReceiveItem then
        RedPointHelper.receiveItem(params.itemId)

    elseif eventName == GameEvents.EventSaleItem then
        RedPointHelper.saleItem(params.itemId)

    elseif eventName == GameEvents.EventFinishTask then
        -- 可能刷出一些能完成的任务成就
        RedPointHelper.taskAndAchieve()

    elseif eventName == GameEvents.EventSeeActivity then
        RedPointHelper.seeActivity(params.activityId)
    elseif eventName == GameEvents.EventOperateActiveUpdate then
        if params.activeType == 1 then
            RedPointHelper.taskActivity(params.activityId)
        elseif params.activeType == 2 then
            RedPointHelper.sevenDayTaskActivity(params.activityId)
        end
        
    elseif eventName == GameEvents.EventUseItem then
        RedPointHelper.useItemRedPoint(params.itemId)
    elseif eventName == GameEvents.EventExpeditionAwardFlag then
        RedPointHelper.setCount(RedPointHelper.System.Union, 1, RedPointHelper.UnionSystem.ExpiditionReward)
    end

    -- 通知刷新主按钮红点
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

function RedPointHelper.openUI(uiID)
    if uiID == UIManager.UI.UIUnion then
        if RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] then
            RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] = nil
        end
    end
end
-- 关闭UI处理
function RedPointHelper.closeUI(uiID)
    -- 背包、头像界面关闭清除红点
    if uiID == UIManager.UI.UIHeadSetting then
        RedPointHelper.SystemInfo[RedPointHelper.System.HeadUnlock] = {}
    elseif uiID == UIManager.UI.UIBag then
        RedPointHelper.SystemInfo[RedPointHelper.System.Bag] = {}
    elseif uiID == UIManager.UI.UIShop then
        RedPointHelper.SystemInfo[RedPointHelper.System.Shop] = 0
    elseif uiID == UIManager.UI.UIArena then
        -- 如果有锦标赛开启红点,关闭界面减一
        if RedPointHelper.SystemInfo[RedPointHelper.System.Arena][RedPointHelper.AreanSystem.ChampionOpen] then
            RedPointHelper.SystemInfo[RedPointHelper.System.Arena][RedPointHelper.AreanSystem.ChampionOpen] = nil
        end
    elseif uiID == UIManager.UI.UIUnionList then
        if RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] then
            RedPointHelper.SystemInfo[RedPointHelper.System.Union][RedPointHelper.UnionSystem.HasUnion] = nil
        end
    end
end

-- 获取道具处理
function RedPointHelper.receiveItem(itemId)
    if not itemId then
        return
    end

    -- 1、是否为新道具
    local isInBag = true
    if itemId > EquipRef then
        -- 2、如果是装备需判断是否有英雄适用
        RedPointHelper.heroRedPoint(RedPointHelper.HeroSystem.Equip)
        itemId = equipModel:getEquipInfo(itemId).confId
    else
        local propItemConf = getPropConfItem(itemId)
        if not propItemConf then
            return
        end

        -- 3、英雄碎片
        if 15 == propItemConf.Type then
            RedPointHelper.singleHeroRedPoint(propItemConf.TypeParam[1], RedPointHelper.HeroSystem.Star)
        end

        -- 4、不放背包
        if 0 == propItemConf.BagLabel then
            isInBag = false
        end
    end

    if isInBag and not OwnedItems[itemId] then
        OwnedItems[itemId] = true
        RedPointHelper.SystemInfo[RedPointHelper.System.Bag][itemId] = true
        saveStringToXML(UserDefault.OWEND_ITEM, itemId)
    end
end

-- 获取资源处理,对应UIAwardHelper.ResourceID
function RedPointHelper.receiveResource(currencyType, currencyCount)
    -- 1、抽卡券
    if 9 == currencyType or 10 == currencyType then
        RedPointHelper.SystemInfo[RedPointHelper.System.DrawCard] = 
            RedPointHelper.SystemInfo[RedPointHelper.System.DrawCard] + currencyCount
    end
end

-- 战斗相关红点处理
function RedPointHelper.stageChallenge(eventName, params)
    if eventName == GameEvents.EventPVPOver then
        if params.pvpType >= 0 then -- 公平竞技+锦标赛
            RedPointHelper.arenaChest()
        end

        return
    end

    if 1 == params.battleResult then
        if eventName == GameEvents.EventStageOver then
            RedPointHelper.worldMap()
        elseif eventName == GameEvents.EventTowerTestStageOver then
            --RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Tower] = towerTestModel:getTowerTestTimes()
        elseif eventName == GameEvents.EventGoldTestStageOver then
            local count = RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Gold] or 0
            count = count - 1
            RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Gold] = count > 0 and count or nil
        elseif eventName == GameEvents.EventHeroTestStageOver then
            local count = RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Hero] or 0
            count = count - 1
            RedPointHelper.SystemInfo[RedPointHelper.System.FB][RedPointHelper.FBSystem.Hero] = count > 0 and count or nil
        end
    end
end

-- 增加/减少相关红点处理
function RedPointHelper.addCount(systemId, val, id)
    local info = RedPointHelper.SystemInfo[systemId]
    if not info then
        return
    end
    
    if type(info) == "number" then
        RedPointHelper.SystemInfo[systemId] = info + val
    elseif type(info) == "table" then
        if not id then
            print("error: param 'id' is nil!systemId", systemId)
            return
        end
        
        local n = info[id]
        if nil == val then
            RedPointHelper.SystemInfo[systemId][id] = val
        elseif type(n) == "number" then
            n = n + val
            RedPointHelper.SystemInfo[systemId][id] = n > 0 and n or nil
        elseif type(n) == "boolean" or nil == n then
            RedPointHelper.SystemInfo[systemId][id] = val
        end
    end

    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

function RedPointHelper.setCount(systemId, val, id)
    local info = RedPointHelper.SystemInfo[systemId]
    if not info then
        return
    end
    
    if type(info) == "table" then
        if not id then
            print("error: param 'id' is nil!systemId", systemId)
            return
        end

        RedPointHelper.SystemInfo[systemId][id] = val
    else
        RedPointHelper.SystemInfo[systemId] = val
    end

    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

-- 查看活动
function RedPointHelper.seeActivity(activityId)
    -- 不是旧活动
    if not OldActivity[activityId] then
        OldActivity[activityId] = true
        saveStringToXML(UserDefault.OLD_ACTIVITY, activityId)
    else
        return
    end

    local count = RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activityId] or 0
    count = count - 1
    RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activityId] = count > 0 and count or nil
end

-- 出售相关红点处理
function RedPointHelper.saleItem(itemId)
    -- 如果出售的是装备,处理英雄装备红点
    if itemId > EquipRef then
        RedPointHelper.heroRedPoint()
    end
end

-- 英雄红点处理
function RedPointHelper.heroRedPoint(subSystem)
    RedPointHelper.SystemInfo[RedPointHelper.System.Hero] = {}
    local heroCards = heroBagModel:getHeroCards()
    for _, heroId in pairs(heroCards) do
        RedPointHelper.singleHeroRedPoint(heroId, subSystem)
    end
end

-- 计算单个英雄红点数
-- subSystem计算指定的子系统(升星、装备、天赋),nil为全部
function RedPointHelper.singleHeroRedPoint(heroId, subSystem, isRefresh)
    AllHeroRedPointCount[heroId] = AllHeroRedPointCount[heroId] or {}
    -- 1、碎片(召唤或升星)
    if not subSystem or RedPointHelper.HeroSystem.Star == subSystem then
        local fragCount = RedPointHelper.heroFragRedPoint(heroId)
        AllHeroRedPointCount[heroId][RedPointHelper.HeroSystem.Star] = fragCount
    end
    -- 2、装备
    if not subSystem or RedPointHelper.HeroSystem.Equip == subSystem then
        local equipCount = RedPointHelper.heroEquipRedPoint(heroId)
        AllHeroRedPointCount[heroId][RedPointHelper.HeroSystem.Equip] = equipCount
    end
    -- 3、天赋
    if not subSystem or RedPointHelper.HeroSystem.Talent == subSystem then
        local talentCount = RedPointHelper.heroTalentRedPoint(heroId)
        AllHeroRedPointCount[heroId][RedPointHelper.HeroSystem.Talent] = talentCount
    end

    local count = 0
    for i = RedPointHelper.HeroSystem.Star, RedPointHelper.HeroSystem.Talent do
        count = count + (AllHeroRedPointCount[heroId][i] or 0)
    end

    if count > 0 then
        RedPointHelper.SystemInfo[RedPointHelper.System.Hero][heroId] = count
    else
        RedPointHelper.SystemInfo[RedPointHelper.System.Hero][heroId] = nil
    end
     
    if isRefresh then
        EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
    end
end

-- 英雄召唤或升星处理
function RedPointHelper.heroFragRedPoint(heroId)
    local cardModel = heroBagModel:getHeroCard(heroId)
    local star = cardModel:getStar()
    local frag = cardModel:getFrag()

    local upRateConf = getSoldierUpRateConfItem(heroId)
    if not upRateConf then
        print("getSoldierUpRateConfItem is nil, heroId", heroId)
        return
    end

    local needFrag = 0
    if star > 0 then
        -- 满星
        if upRateConf.TopStar == star then
            return 0
        end

        local starConf = getSoldierStarSettingConfItem(star + 1)
        if not starConf then
            print("getSoldierStarSettingConfItem is nil!!!heroId, star", heroId, star+1)
            return 0
        end
        needFrag = starConf.UpStarCount
    else
        local starConf = getSoldierStarSettingConfItem(upRateConf.DefaultStar)
        needFrag = starConf.TurnCardCount
    end

    return needFrag > 0 and frag >= needFrag and 1 or 0
end

-- 英雄装备
function RedPointHelper.heroEquipRedPoint(heroId)
    local heroModel = heroBagModel:getHeroCard(heroId)
	local heroStar = heroModel:getStar()
    -- 还没召唤的英雄
    if heroStar <= 0 then
        return 0
    end

    local heroLv = heroModel:getLevel()
	local heroEquips = heroModel:getEquips()
    local allItems = bagModel:getItems()
    local allEquips = equipModel:getEquips()

	-- 英雄配置表
	local soldierConfigItem = getSoldierConfItem(heroId, heroStar)
	if soldierConfigItem == nil then
		print("soldierConfigItem error: heroId:", heroId, ", heroStar:", heroStar)
		return
	end

    -- 是否有更好的装备
    local function haveBestEquip(curEquip, vocation, equipPart, heroLv)
        local equipRank = 0
        if curEquip > 0 then
            local equipConfId = allEquips[curEquip].confId
            equipRank = getEquipmentConfItem(equipConfId).Rank
        end

        local b = false
        for itemId, itemVal in pairs(allItems) do
            -- 装备
            if itemId > EquipRef then
                local equipmentConfItem = getEquipmentConfItem(itemVal)
                if nil == equipmentConfItem then
                    print("can't find equip", itemVal)
                    break
                end
                -- 部位和等级
                if equipPart == equipmentConfItem.Parts then
                    if heroLv >= equipmentConfItem.Level 
                      and equipmentConfItem.Rank > equipRank then
                        -- 符合职业
                        for _, v in pairs(equipmentConfItem.Vocation) do
	 				        if v == vocation then
	 				            b = true
                                break
	 				        end
	 				    end
                    end
                end
            end
        end

        return b
    end

	-- 遍历身上查找更换的装备
    local count = 0
	for part, equipId in pairs(heroEquips) do
        if haveBestEquip(equipId, soldierConfigItem.Common.Vocation, part, heroLv) then
            count = count + 1
        end
    end

    return count
end

-- 英雄天赋
function RedPointHelper.heroTalentRedPoint(heroId)
    local heroModel = heroBagModel:getHeroCard(heroId)
	local heroStar = heroModel:getStar()
    -- 还没召唤的英雄
    if heroStar <= 0 then
        return 0
    end

    local useTalentPoint = 0
    local talents = heroModel:getTalent()
    for _, talentId in ipairs(talents) do
        if talentId > 0 then
            useTalentPoint = useTalentPoint + 1
        end
    end

    return useTalentPoint >= heroStar and 0 or 1
end

-- 获取需要红点的英雄
function RedPointHelper.getRedPointHeros()
    local heros = {}
    for heroId, ref in pairs(RedPointHelper.SystemInfo[RedPointHelper.System.Hero]) do
        if ref > 0 then
            heros[heroId] = true
        end
    end

    return heros
end

function RedPointHelper.addBoonRed()
    local count = 0
    local vipPayment = userModel:getPayment()
    if vipPayment and vipPayment > 0 then
        -- 奖励状态(0未领取, 1已领取)
        if 0 == userModel:getFirstPayFlag() then
            count = count + 1
        end
    end

    RedPointHelper.SystemInfo[RedPointHelper.System.Boon] = count + 1
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

-- 获取所有需要红点的活动
function RedPointHelper.getActivityRedPoint()
    local activitys = {}
    for activityId, count in pairs(RedPointHelper.SystemInfo[RedPointHelper.System.Activity]) do
        activitys[activityId] = {}
        activitys[activityId].count = count
        activitys[activityId].isOld = false

        if OldActivity[activityId] then
            activitys[activityId].isOld = true
        end
    end

    return activitys
end

function RedPointHelper.getSevenDayActivityRedPoint()
    local activitys = {}
    for activityId, count in pairs(RedPointHelper.SystemInfo[RedPointHelper.System.SevenDay]) do
        activitys[activityId] = count
    end

    return activitys
end

-- 获取需要红点的活动
function RedPointHelper.getRedPointByActivityId(activityId)
    return RedPointHelper.SystemInfo[RedPointHelper.System.Activity][activityId] or 0
end

-- 获取背包需要红点的道具
function RedPointHelper.getBagRedPoint()
    return RedPointHelper.SystemInfo[RedPointHelper.System.Bag]
end

-- 该物品是不是已经拥有过
function RedPointHelper.isOwned(itemId)
    return RedPointHelper.SystemInfo[RedPointHelper.System.Bag][itemId]
end

-- 获取某个系统的红点状态,true为需要红点
function RedPointHelper.getSystemRedPoint(systemId)
    local info = RedPointHelper.SystemInfo[systemId]
    if not info then
        return false
    end

    if type(info) == "table" then
        return next(info) ~= nil
    elseif type(info) == "number" then
        return info > 0
    end

    return false
end

-- 获取某个系统的红点信息
function RedPointHelper.getSystemInfo(systemId)
    return RedPointHelper.SystemInfo[systemId]
end

-- 竞技场任务红点
function RedPointHelper.getArenaTaskRedPoint()
    --return (RedPointHelper.SystemInfo[RedPointHelper.System.Arena][RedPointHelper.AreanSystem.ArenaTask] or 0) > 0
end

function RedPointHelper.getUnionSubRedPoint(subSystemId)
    if RedPointHelper.SystemInfo[RedPointHelper.System.Union][subSystemId] then
        return true
    end
    
    return false
end

-- 1、公会大厅 2、公会远征
function RedPointHelper.getUnionBuildRedPoint(buildId)
    if 1 == buildId then
        if RedPointHelper.getUnionSubRedPoint(RedPointHelper.UnionSystem.Liveness)
          or RedPointHelper.getUnionSubRedPoint(RedPointHelper.UnionSystem.Audit) then
            return true
        end
    elseif 2 == buildId then
        return RedPointHelper.getUnionSubRedPoint(RedPointHelper.UnionSystem.ExpiditionReward)
    end
    
    return false
end

function RedPointHelper.updateUnion()
    RedPointHelper.union()
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

function RedPointHelper.updateSevenDay()
    RedPointHelper.sevenDay()
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

-- 使用了道具(吃经验书、穿装备)
function RedPointHelper.useItemRedPoint(itemId)
    if type(itemId) ~= "number" then
        return
    end

    if itemId > EquipRef then
        itemId = equipModel:getEquipInfo(itemId).confId
        RedPointHelper.SystemInfo[RedPointHelper.System.Bag][itemId] = nil
    else
        if not bagModel:hasItem(itemId) then
            RedPointHelper.SystemInfo[RedPointHelper.System.Bag][itemId] = nil
        end
    end
end

-- 返回蓝钻相关红点
function RedPointHelper.getBlueGemRedPoint()
    return blueGemModel:isShowRedPointForBlueGem() > 0, 
        blueGemModel:isShowRedPointForCommonHall() > 0
end

return RedPointHelper