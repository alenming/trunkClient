-- 英雄试炼模型
local HeroTestModel = class("HeroTestModel")

function HeroTestModel:ctor()
	self.mStamp = 0
	self.mTimes = {}
end

function HeroTestModel:init(buffData)
	self.mStamp = buffData:readInt()						-- 时间戳
	local count = buffData:readInt()						-- 副本数量
	self.mTimes = {}
	for i = 1, count do
		local instanceId = buffData:readInt()				-- 副本id
		local times = buffData:readInt()					-- 挑战次数
		self.mTimes[instanceId] = times
	end
	return true
end

function HeroTestModel:getHeroTestCount(id)
	return self.mTimes[id] or 0
end

function HeroTestModel:setHeroTestCount(id, times)
	if self.mTimes[id] then
		self.mTimes[id] = times
	end
end

function HeroTestModel:addHeroTestCount(id, times)
	self.mTimes[id] = (self.mTimes[id] or 0) + times
end

function HeroTestModel:getHeroTestStamp()
	return self.mStamp
end

function HeroTestModel:setHeroTestStamp(stamp)
	self.mStamp = stamp
end

function HeroTestModel:resetHeroTest()
	for id, _ in pairs(self.mTimes) do
		self.mTimes[id] = 0
	end
end

return HeroTestModel