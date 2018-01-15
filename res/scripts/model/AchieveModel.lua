require"model.ModelConst"

-- 成就模型
local AchieveModel = class("AchieveModel")

function AchieveModel:ctor()
	self.mCount = 0
	self.mAchieves = {}
end

function AchieveModel:init(buffData)
	self.mCount = buffData:readInt()						-- 成就个数
	self.mAchieves = {}
	for i = 1, self.mCount do
		local achieveID = buffData:readInt()				-- 成就ID
		local achieveVal = buffData:readInt()				-- 累计数值
		local achieveStatus = buffData:readInt()			-- 成就状态

		local achieveConf = getAchieveConfItem(achieveID)
		if achieveConf and achieveStatus == EAchieveStatus.EACHIEVE_STATUS_ACTIVE
		   and achieveVal >= achieveConf.CompleteTimes then
		   	achieveStatus = EAchieveStatus.EACHIEVE_STATUS_FINISH
		end

		self:addAchieve{
			achieveID = achieveID, 
			achieveVal = achieveVal, 
			achieveStatus = achieveStatus
		}
	end

	return true
end

-- 添加成就
function AchieveModel:addAchieve(info)
	if self.mAchieves[info.achieveID] then
		return false
	end
	self.mAchieves[info.achieveID] = info
	self.mCount = self.mCount + 1
	return true
end

-- 删除成就
function AchieveModel:delAchieve(id)
	if not self.mAchieves[id] then return false end
	self.mAchieves[id] = nil
	self.mCount = self.mCount - 1
	return true
end

-- 设置成就
function AchieveModel:setAchieve(info)
	if not self.mAchieves[info.achieveID] then return false end
	self.mAchieves[info.achieveID] = info
	return true
end
	
function AchieveModel:getAchievesData()
	return self.mAchieves
end

return AchieveModel