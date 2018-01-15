-- 金币试炼模型
local GoldTestModel = class("GoldTestModel")

function GoldTestModel:ctor()
	self.mCount = 0
	self.mStamp = 0
	self.mDamage = 0
	self.mState = 0
end

function GoldTestModel:init(buffData)
	self.mCount = buffData:readInt()				-- 挑战次数
	self.mStamp = buffData:readInt()				-- 时间戳
	self.mDamage = buffData:readInt()				-- 总伤害
	self.mState = buffData:readInt()				-- 宝箱状态
	return true
end

function GoldTestModel:getCount()
	return self.mCount
end

function GoldTestModel:addCount(count)
	self.mCount = self.mCount + count
end

function GoldTestModel:getStamp()
	return self.mStamp
end

function GoldTestModel:setStamp(stamp)
	self.mStamp = stamp
end

function GoldTestModel:getDamage()
	return self.mDamage
end

function GoldTestModel:addDamage(damage)
	self.mDamage = self.mDamage + damage
end

function GoldTestModel:getState(id)
	if id < 0 or id > 31 then
		return -1
	end

	local conf = getGoldTestChestConfItem(id)
	if self.mDamage < conf.Damage then			-- 未达到伤害，不可领取
		return -1
	end

	return bit.band(self.mState, bit.blshift(1, id - 1))	-- 0表示未领取
end

-- 设置为已领取
function GoldTestModel:setState(id)
	if id < 0 or id > 31 then
		return 
	end

	local conf = getGoldTestChestConfItem(id)
	if self.mDamage < conf.Damage then			-- 未达到伤害，不可领取
		return
	end

	self.mState = bit.bor(self.mState, bit.blshift(1, id - 1))
end

function GoldTestModel:setGoldTestFlag(flag)
	self.mState = flag
end

function GoldTestModel:resetGoldTest(stamp)
	self.mStamp = stamp
	self.mCount = 0
	self.mDamage = 0
	self.mState = 0
end

return GoldTestModel