local HeadModel = class("HeadModel")

function HeadModel:ctor()
	self.mNum = 0
	self.mUnlockedHead = {}
end

function HeadModel:init(buffData)
	self.mNum = buffData:readInt()									-- 头像个数
	self.mUnlockedHead = {}
	for i = 1, self.mNum do
		table.insert(self.mUnlockedHead, buffData:readInt())		-- 头像id
	end

	return true
end

-- 获取已解锁头像列表
function HeadModel:getUnlockedHeads()
	return self.mUnlockedHead
end

-- 判断头像是否已解锁
function HeadModel:isUnlocked(id)
	for _, v in ipairs(self.mUnlockedHead) do
		if v == id then
			return true
		end
	end
	return false
end

function HeadModel:addHead(id)
	for _, v in ipairs(self.mUnlockedHead) do
		if v == id then
			return false
		end
	end
	table.insert(self.mUnlockedHead, id)
	return true
end

return HeadModel