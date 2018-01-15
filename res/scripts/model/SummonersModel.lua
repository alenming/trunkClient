-- 召唤师列表模型
local SummonersModel = class("SummonersModel")

function SummonersModel:ctor()
	self.mSummoners = {}					
end

function SummonersModel:init(buffData)
	local count = buffData:readUChar()
	self.mSummoners = {}									-- 召唤师容器
	for i = 1, count do
		table.insert(self.mSummoners, buffData:readInt())
	end
	return true
end

function SummonersModel:hasSummoner(id)
	for _, v in ipairs(self.mSummoners) do
		if v == id then return true end
	end
	return false
end

function SummonersModel:addSummoner(id)
	if self:hasSummoner(id) then return false end
	table.insert(self.mSummoners,1, id)
	return true
end

function SummonersModel:getSummonerCount()
	return #self.mSummoners
end

function SummonersModel:getSummoners()
	return self.mSummoners
end

return SummonersModel