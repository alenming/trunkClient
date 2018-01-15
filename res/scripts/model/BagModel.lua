-- 背包模型
local BagModel = class("BagModel")

function BagModel:ctor()
	self.mCapacity = 0							
	self.mCount = 0								
	self.mBagItems = {}							
end

function BagModel:init(buffData)
	self.mCapacity = buffData:readShort()					-- 当前容量
	self.mCount = buffData:readShort()					-- 背包物品数量
	self.mBagItems = {}									-- 物品容器
	for i = 1, self.mCount do
		local id = buffData:readInt()					-- 物品id
		local val = buffData:readInt()					-- 物品数量
		self.mBagItems[id] = val
	end
	return true
end

-- 扩展背包修改容量上限
function BagModel:extra(add)
	if add < 0 then return false end
	self.mCapacity = self.mCapacity + add
	return true
end

-- 添加物品: 装备ID，配置ID；消耗品ID，数量
function BagModel:addItem(id, param)
	if not self.mBagItems[id] then
		self.mBagItems[id] = param
		self.mCount = self.mCount + 1
	else
		self.mBagItems[id] = self.mBagItems[id] + param
	end
	return true
end

-- 删除物品
function BagModel:removeItem(id)
	return self:removeItems(id)
end

-- 删除物品
function BagModel:removeItems(id, count)
	count = count or 1
	if not self.mBagItems[id] then
		return false
	else
		if id > 1000000 or self.mBagItems[id] == count then			-- 装备id > 1000000
			self.mBagItems[id] = nil
			self.mCount = self.mCount - 1
			return true
		elseif self.mBagItems[id] > count then
			self.mBagItems[id] = self.mBagItems[id] - count
			return true
		end
		return false
	end
end

-- 判断是否有某物品
function BagModel:hasItem(id)
	return self.mBagItems[id] ~= nil
end

-- 获取背包存放的数量
function BagModel:getItemCount()
	return self.mCount
end

function BagModel:getItems()
	return self.mBagItems
end

function BagModel:getCurCapacity()
	return self.mCapacity
end

function BagModel:setCurCapacity(c)
	self.mCapacity = c
end

-- 获取背包物品的数量
function BagModel:getItemCountById(id)
	return self.mBagItems[id] and self.mBagItems[id] or 0
end

return BagModel