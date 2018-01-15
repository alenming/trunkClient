-- 王向明
-- 2016年12月26日 19:02:59
-- 蓝钻特权活动模型

require"model.ModelConst"

local BlueGemModel = class("BlueGemModel")

local BlueGemData = require"configlua.BlueDiamend"

local everyDayActId = 1001  --蓝钻贵族每日领取活动ID
local blueGemYearActId =  1009 -- 年费蓝钻每日额外领取活动ID
local haoBlueGemActId = 1010  -- 豪华蓝钻额外领取活动ID
local growActId = 3001
local newPlayerActId = 2001

local commoneveryDayActId = 4001  --每日领取活动ID
local commongrowActId = 6001
local commonnewPlayerActId = 5001


function BlueGemModel:ctor()
	self.mActivityData = {}

	self.mIsShowRedPointForBlueGem = 0
	self.mIsShowRedPointForCommonHall = 0

	self.mBlueGemRedPoint = {everyDay = false, growUp = false , newPlayer = false}
	self.mCommonHallRedPoint = {everyDay = false, growUp = false , newPlayer = false}
end

function BlueGemModel:init(buffData)

	self.mActCount = buffData:readInt()

	for i=1,self.mActCount do
		local oneAct = {}
		oneAct.acId = buffData:readInt()
		oneAct.taskId = buffData:readInt()
		oneAct.adAttribute = buffData:readInt()
		table.insert(self.mActivityData, oneAct.acId*100 + oneAct.taskId , oneAct)	
	end

	self:isShowRedPointForBlueGem()
	self:isShowRedPointForCommonHall()
	return true
end

function BlueGemModel:getActivityData()
	return self.mActivityData
end

-- 获取活动的子任务状态
function BlueGemModel:getActivityById(acId, taskId)
    local realAcId = acId*100+taskId
	if self.mActivityData and self.mActivityData[realAcId] then
		-- for id,info in pairs(self.mActivityData) do
		-- 	if id== realAcId and info.taskId == taskId then
		-- 		return info.adAttribute
		-- 	end
		-- end
		return self.mActivityData[realAcId].adAttribute
	end
end

function BlueGemModel:setActivityById(acId, taskId, flag)
    local realAcId = acId*100+taskId
	if self.mActivityData and self.mActivityData[realAcId] then
		for id,info in pairs(self.mActivityData) do
			if id== realAcId and info.taskId == taskId then
				info.adAttribute = flag
			end
		end
	end

	self.mIsShowRedPointForBlueGem = 0
	self.mIsShowRedPointForCommonHall = 0

	self.mBlueGemRedPoint = {everyDay = false, growUp = false , newPlayer = false}
	self.mCommonHallRedPoint = {everyDay = false, growUp = false , newPlayer = false}

	self:isShowRedPointForBlueGem()
	self:isShowRedPointForCommonHall()
end

function BlueGemModel:isShowRedPointForBlueGem()

	self.mIsShowRedPointForBlueGem = 0

	local blueGemType = getGameModel():getUserModel():getBDType()
	local isBd, isYearBd, isHaoBd = QQHallHelper:getBDInfo(blueGemType)
	local useBlueLv = getGameModel():getUserModel():getBDLv()

	-- 蓝钻每日活动有没有可领取的
	local data1 = getBlueDiamondConfig(everyDayActId)
	for i=1,#data1 do

		local attrubute = self:getActivityById(everyDayActId, i)

		if isBd==1 and useBlueLv == i and attrubute == 0 then
			self.mIsShowRedPointForBlueGem =  self.mIsShowRedPointForBlueGem + 1
			self.mBlueGemRedPoint.everyDay = true
			break
		end
	end

	--年费蓝钻可否领取
	local attrubute1 = self:getActivityById(blueGemYearActId, 1)
	if isBd==1 and isYearBd == 1 and attrubute1 == 0 then --是年费
		self.mIsShowRedPointForBlueGem =  self.mIsShowRedPointForBlueGem + 1
		self.mBlueGemRedPoint.everyDay = true
	end

	--土豪蓝钻
	local attrubute2 = self:getActivityById(haoBlueGemActId, 1)
	if isBd==1 and isYearBd == 1 and attrubute2 == 0 then --是土豪
		self.mIsShowRedPointForBlueGem  =  self.mIsShowRedPointForBlueGem + 1
		self.mBlueGemRedPoint.everyDay = true
	end

	-- 成长礼包
	local data2 = getBlueDiamondConfig(growActId)
	for i=1,#data2 do
		local oneData = getBlueDiamondConfig(growActId, i)
		local condition = oneData.ConditionsType1
		local attrubute = self:getActivityById(growActId, i)
		local userLv = getGameModel():getUserModel():getUserLevel()
		if isBd==1 and userLv >= condition  and attrubute == 0 then
			self.mIsShowRedPointForBlueGem =  self.mIsShowRedPointForBlueGem + 1
			self.mBlueGemRedPoint.growUp = true
		end
	end

	-- 新手礼包 
	local adAttribute3 = self:getActivityById(newPlayerActId, 1)
	if adAttribute3 == 0 and isBd == 1 then
		self.mIsShowRedPointForBlueGem =  self.mIsShowRedPointForBlueGem + 1
		self.mBlueGemRedPoint.newPlayer = true
	end

    return self.mIsShowRedPointForBlueGem
end

function BlueGemModel:isShowRedPointForCommonHall()
	local data1 = getBlueDiamondConfig(commoneveryDayActId, 1)
	local attrubute1 = self:getActivityById(commoneveryDayActId, 1)
	if attrubute1 == 0 then   -- 可领取已领取
		self.mIsShowRedPointForCommonHall =  self.mIsShowRedPointForCommonHall + 1
		self.mCommonHallRedPoint.everyDay = true
	end

	local data2 = getBlueDiamondConfig(commongrowActId)
	for i=1,#data2 do
		local oneData = getBlueDiamondConfig(commongrowActId, i)
		local userLv = getGameModel():getUserModel():getUserLevel()
		local condition = oneData.ConditionsType1
		local attrubute2 = self:getActivityById(commongrowActId, i)
		if userLv >= condition and attrubute2 == 0 then
			self.mIsShowRedPointForCommonHall =  self.mIsShowRedPointForCommonHall + 1
			self.mCommonHallRedPoint.growUp = true
		end
	end

	local attrubute3 = self:getActivityById(commonnewPlayerActId, 1)
	if attrubute3 == 0 then   -- 可领取已领取
		self.mIsShowRedPointForCommonHall =  self.mIsShowRedPointForCommonHall + 1
		self.mCommonHallRedPoint.newPlayer = true
	end

    return self.mIsShowRedPointForCommonHall
end

--大厅用的红点
function BlueGemModel:getShowRedPointForBlueGem()
	return self.mIsShowRedPointForBlueGem 
end

function BlueGemModel:getShowRedPointForCommon()
	return self.mIsShowRedPointForCommonHall
end


--界面用的红点
function BlueGemModel:getRedPointForBlueGem()
	return self.mBlueGemRedPoint 
end

function BlueGemModel:getRedPointForCommon()
	return self.mCommonHallRedPoint
end

-- 任务刷新后来刷新一下界面
function BlueGemModel:updateToRefreshUI()


	self.mIsShowRedPointForBlueGem = 0
	self.mIsShowRedPointForCommonHall = 0

	self.mBlueGemRedPoint = {everyDay = false, growUp = false , newPlayer = false}
	self.mCommonHallRedPoint = {everyDay = false, growUp = false , newPlayer = false}

	--self:setActivityById(blueGemYearActId, 1 , 0)
	--self:setActivityById(haoBlueGemActId, 1 , 0)

	self.mActivityData[blueGemYearActId*100+1].adAttribute = 0
	self.mActivityData[haoBlueGemActId*100+1].adAttribute = 0

	local useBlueLv = getGameModel():getUserModel():getBDLv()
	if useBlueLv ~= 0 then
		--self:setActivityById(everyDayActId, useBlueLv, 0)
		self.mActivityData[everyDayActId*100+useBlueLv].adAttribute = 0
	end

	--self:setActivityById(commoneveryDayActId, 1, 0)
	self.mActivityData[commoneveryDayActId*100+1].adAttribute = 0

	self:isShowRedPointForBlueGem()
	self:isShowRedPointForCommonHall()

	print("BlueGemModel:updateToRefreshUI()")
	local ui = UIManager.getUI(UIManager.UI.UIBlueGem)
	if ui then
		ui:refreshUI()
	end
	local uicommon = UIManager.getUI(UIManager.UI.UICommonHall)
	if uicommon then
		uicommon:refreshUI()
	end
end


return BlueGemModel