-- 新手引导模型
local GuideModel = class("GuideModel")

function GuideModel:ctor()
	self.mActives = {}
end

function GuideModel:init(buffData)
	local num = buffData:readInt()						-- 引导个数
	self.mActives = {}
	for i = 1, num do
		local id = buffData:readInt()					-- 引导ID
		self:addGuide(id)
	end
	--dump(self.mActives)
	return true
end

function GuideModel:getActives()
	local list = {}
	for id, _ in pairs(self.mActives) do
		table.insert(list, id)
	end
	return list
end

function GuideModel:delGuide(id)
	self.mActives[id] = nil
end

function GuideModel:addGuide(id)
	if not self.mActives[id] then
		self.mActives[id] = true
	end
end

return GuideModel