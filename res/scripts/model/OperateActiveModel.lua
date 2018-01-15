require"model.ModelConst"
require("common.TimeHelper")

-- 运营活动模型
local OperateActiveModel = class("OperateActiveModel")

function OperateActiveModel:ctor()
    self.mActiveCount = 0
    self.mActiveData = {}
    self.mActiveShopData = {}
    self.mActiveTaskData = {}
    self.mActiveCardData = {}   -- 月卡
    self.mExchangeData = {}
end

function OperateActiveModel:init(buffData)
    self.mActiveCount = buffData:readShort() 							-- 活动个数
    self.mActiveData = {}											-- 运营活动基础信息, 以活动id为索引
    self.mActiveShopData = {}										-- 商店活动数据
    self.mActiveTaskData = {}										-- 任务活动数据
    self.mActiveCardData = {}                                       -- 月卡数据
    for i = 1, self.mActiveCount do
        local startTime = buffData:readInt()                        -- 开始时间
        local endTime = buffData:readInt()                          -- 结束时间
        local activeId = buffData:readShort()
        local activeType = buffData:readChar()
        local timeType = buffData:readChar()
        local lvLimit = buffData:readChar()							-- 活动等级限制

        self.mActiveData[activeId] = {
            activeID = activeId,
            activeType = activeType,
            timeType = timeType,
            levLimit = lvLimit,
            startTime = startTime,
            endTime = endTime,
        }

        if activeType == ActiveType.TYPE_SHOP then
            local giftNum = buffData:readShort()						-- 礼包个数
            local gifts = {}
            for j = 1, giftNum do
                local goodsIds = {}
                for k = 1, 4 do
                    table.insert(goodsIds, buffData:readInt())      -- 道具id 
                end
                local goodsNums = {}
                for k = 1, 4 do
                    table.insert(goodsNums, buffData:readInt())     -- 道具数量
                end
                local price = buffData:readInt()
                local giftId = buffData:readChar()
                local coinType = buffData:readChar()					-- 货币类型
                local saleRate = buffData:readChar()
                local maxBuyTimes = buffData:readChar()
                local buyTimes = buffData:readChar()					-- 已经购买次数		

                table.insert(gifts, {
                    giftID = giftId,
                    goodsID = goodsIds,
                    goodsNum = goodsNums,
                    goldType = coinType,
                    price = price,
                    saleRate = saleRate,
                    maxBuyTimes = maxBuyTimes,
                    buyTimes = buyTimes
                })
            end

            self.mActiveShopData[activeId] = {
                giftNum = giftNum,
                gifts = gifts
            }
        elseif activeType == ActiveType.TYPE_TASK then
            local taskNum = buffData:readShort()						-- 活动任务数
            local tasks = {}
            for j = 1, taskNum do
                local conditionParam = {}
                for k = 1, 2 do
                    table.insert(conditionParam, buffData:readInt())
                end
                local rewardGold = buffData:readInt()
                local rewardGoodsID = {}
                for k = 1, 4 do
                    table.insert(rewardGoodsID, buffData:readInt())
                end
                local rewardGoodsNum = {}
                for k = 1, 4 do
                    table.insert(rewardGoodsNum, buffData:readInt())
                end
                local value = buffData:readInt()                    -- 任务完成进度
                local finishCondition = buffData:readShort()
                local rewardDiamond = buffData:readShort()
                local taskID = buffData:readChar()
                local finishFlag = buffData:readChar()				-- 是否领取，0-未领取，1-领取

                table.insert(tasks, {
                    taskID = taskID,
                    finishCondition = finishCondition,
                    conditionParam = conditionParam,
                    rewardDimand = rewardDiamond,
                    rewardGold = rewardGold,
                    rewardEnergy = rewardEnergy,
                    rewardGoodsID = rewardGoodsID,
                    rewardGoodsNum = rewardGoodsNum,
                    value = value,
                    finishFlag = finishFlag,
                })
            end

            self.mActiveTaskData[activeId] = {
                taskNum = taskNum,
                tasks = tasks
            }
        elseif activeType == ActiveType.TYPE_CARD then  -- 月卡
             local cardNum = buffData:readChar()
             for j = 1, cardNum do
                 local card = {}
                 card.cardID = buffData:readInt()       -- 月卡id
                 card.rewardTime = buffData:readInt()   -- 月卡领取时间
                 card.chargeTime = buffData:readInt()   -- 月卡充值时间
                 card.cardType = buffData:readChar()    -- 月卡类型
                 self.mActiveCardData[card.cardID] = card
             end
        elseif activeType == ActiveType.TYPE_EXCHANGE then
            local cardNum = buffData:readChar()
            self.mExchangeData[activeId] = {}
            for j = 1, cardNum do
                local acData = {}
                acData.acId = buffData:readShort()
                acData.taskID = buffData:readChar()
                acData.count = buffData:readChar()
                self.mExchangeData[activeId][acData.taskID] = acData
            end
        end
    end
end

-- 获取活动个数
function OperateActiveModel:getActiveCount()
	return self.mActiveCount
end

function OperateActiveModel:delActiveCount()
	self.mActiveCount = self.mActiveCount - 1
end

-- 获取活动基础信息
function OperateActiveModel:getActiveData()
	local ret = {}
	for _, data in pairs(self.mActiveData) do
		table.insert(ret, data)
	end
	return ret
end

-- 获取商店活动数据
function OperateActiveModel:getActiveShopData(activeID)
	if not self.mActiveShopData[activeID] then return end

	local ret = {}
	for _, data in pairs(self.mActiveShopData[activeID].gifts) do
		table.insert(ret, data)
	end
	return ret
end

-- 设置已经购买次数
function OperateActiveModel:setActiveShopBuyTimes(activeID, giftID, buyTimes)
	if self.mActiveShopData[activeID] then
		for _, data in pairs(self.mActiveShopData[activeID].gifts) do
			if data.giftID == giftID then
				data.buyTimes = buyTimes
				return 
			end
		end
	end
end

-- 获取任务活动数据
function OperateActiveModel:getActiveTaskData(activeID)
	if not self.mActiveTaskData[activeID] then return end

	local ret = {}
	for _, data in pairs(self.mActiveTaskData[activeID].tasks) do
		table.insert(ret, data)
	end
	return ret
end

-- 设置任务完成进度
function OperateActiveModel:setActiveTaskProgress(activeID, taskID, value)
	if self.mActiveTaskData[activeID] then
		for _, data in pairs(self.mActiveTaskData[activeID].tasks) do
			if data.taskID == taskID then
				data.value = value
				return true
			end
		end
	end

    return false
end

-- 设置任务状态
function OperateActiveModel:setActiveTaskFinishFlag(activeID, taskID, flag)
	if self.mActiveTaskData[activeID] then
		for _, data in pairs(self.mActiveTaskData[activeID].tasks) do
			if data.taskID == taskID then
				data.finishFlag = flag
				return 
			end
		end
	end
end

-- 设置兑换任务状态
function OperateActiveModel:setExchangeFinishFlag(activeID, taskID, count)
    if self.mExchangeData[activeID] then
        for _, data in pairs(self.mExchangeData[activeID]) do
            if data.taskID == taskID then
                data.count = count
                return 
            end
        end
    end
end

-- 移除已经结束的活动
function OperateActiveModel:removeActiveData(activeID, activeType)
	self.mActiveData[activeID] = nil
	if activeType == ActiveType.TYPE_SHOP then
		self.mActiveShopData[activeID] = nil
	elseif activeType == ActiveType.TYPE_TASK then
		self.mActiveTaskData[activeID] = nil
	end
end

-- 获取月卡数据
function OperateActiveModel:getMonthCardData()
    return self.mActiveCardData
end

-- 设置月卡充值时间
function OperateActiveModel:setMonthCardChargeTime(cardID)
    if self.mActiveCardData[cardID] then
        local nowTime = getGameModel():getNow()
        local year = os.date("%Y", nowTime)
        local month = os.date("%m", nowTime)
        local day = os.date("%d", nowTime)
        nowTime = os.time({year=year, month=month, day=day, hour=0, min=0, sec=0})
        self.mActiveCardData[cardID].chargeTime = nowTime
    end
end

-- 设置月卡领取时间
function OperateActiveModel:setMonthCardRewardTime(cardID)
    if self.mActiveCardData[cardID] then
        self.mActiveCardData[cardID].rewardTime = os.time()
    end
end

-- 判断月卡状态
function OperateActiveModel:getCardState(activeID, cardID)
    local state = 0
    local cardData = self.mActiveCardData[cardID]
    if not cardData then return state end

    if 0 == cardData.cardType then      -- 终身月卡
        state = self:getGoldCardState(activeID)
    elseif 1 == cardData.cardType then  -- 普通月卡
        state = self:getMonthCardState(activeID)
    end
    
    return state
end

-- 获取普通月卡状态
function OperateActiveModel:getMonthCardState(activeID)
    local cardData = self.mActiveCardData[1]
    if not cardData then return 0 end
    -- 月卡持续天数
    local cardDays = getMonthCardDays(activeID, cardData.cardID)
    local nowTime = getGameModel():getNow()
    local rewardTime = cardData.rewardTime
    local chargeTime = cardData.chargeTime
    local finishTime = chargeTime + cardDays * 86400
    -- 可以购买: 充值时间 == 0 or 当前时间 > 结束时间
    if nowTime > finishTime then
        print("购买")

        return MonthCardState.STATE_NONE
    -- 全部领完: 领取时间日期 == 结束时间日期
    elseif TimeHelper.isSameDay(rewardTime, finishTime) then
        print("全部领完")

        return MonthCardState.STATE_FINISH
        -- 明日再来: 充值时间日期 == 当前时间日期 or 领取时间日期 == 当前时间日期
    elseif TimeHelper.isSameDay(chargeTime, nowTime) or TimeHelper.isSameDay(rewardTime, nowTime) then
        print("明日再来")

        return MonthCardState.STATE_RECEIVED
    -- 可以领取: 领取时间日期 ~= 当前时间日期
    elseif not TimeHelper.isSameDay(rewardTime, nowTime) then
        print("领取")

        return MonthCardState.STATE_REWARD
    end

    return MonthCardState.STATE_NONE
end

function OperateActiveModel:getGoldCardState()
    local cardData = self.mActiveCardData[2]
    if not cardData then return 0 end
    local nowTime = getGameModel():getNow()
    local rewardTime = cardData.rewardTime
    local chargeTime = cardData.chargeTime
    -- 可以购买: 充值时间 == 0
    if 0 == chargeTime then
        print("购买")

        return MonthCardState.STATE_NONE
    -- 明日再来: 充值时间日期 == 当前时间日期 or 领取时间日期 == 当前时间日期
    elseif TimeHelper.isSameDay(chargeTime, nowTime) or TimeHelper.isSameDay(rewardTime, nowTime) then
        print("明日再来")

        return MonthCardState.STATE_RECEIVED
    -- 可以领取: 领取时间日期 ~= 当前时间日期
    elseif not TimeHelper.isSameDay(rewardTime, nowTime) then
        print("领取")

        return MonthCardState.STATE_REWARD
    end
    
    return MonthCardState.STATE_NONE
end

-- 获取兑换活动数据
function OperateActiveModel:getExchangeData(activeID)
    if not self.mExchangeData[activeID] then return end

    return self.mExchangeData[activeID]
end

return OperateActiveModel