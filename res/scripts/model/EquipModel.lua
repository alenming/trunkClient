-- 装备模型
local EquipModel = class("EquipModel")

function EquipModel:ctor()
	self.mCount = 0									
	self.mEquips = {}								
end

function EquipModel:init(buffData)
	self.mCount = buffData:readInt()						-- 装备数量
	self.mEquips = {}										-- 装备容器
	for i = 1, self.mCount do
		local equipId = buffData:readInt()					
		local confId = buffData:readInt()					
		local mainPropNum = buffData:readChar()				
		local effectIds = {}
		for j = 1, 8 do
			table.insert(effectIds, buffData:readChar()) 	
		end
		local effectVals = {}
		for j = 1, 8 do
			table.insert(effectVals, buffData:readShort())	
		end
		self.mEquips[equipId] = {
			equipId = equipId,							-- 装备id
			confId = confId,							-- 配置表id
			nMainPropNum = mainPropNum,					-- 主属性个数
			eqEffectIDs = effectIds,					-- 特效id
			eqEffectValues = effectVals 				-- 特效值
		}
	end
	return true
end

-- 是否有装备
function EquipModel:hasEquip(equipId)
	return self.mEquips[equipId] ~= nil
end

-- 添加装备
function EquipModel:addEquip(equipId, confId, mainPropNum, effectIds, effectVals)
	if self.mEquips[equipId] then return false end
	self.mEquips[equipId] = {
		equipId = equipId,							
		confId = confId,							
		nMainPropNum = mainPropNum,					
		eqEffectIDs = effectIds,					
		eqEffectValues = effectVals 				
	}
	self.mCount = self.mCount + 1
	return true
end

-- 移除装备
function EquipModel:removeEquip(equipId)
	if self.mEquips[equipId] then
	 	self.mEquips[equipId] = nil
	 	self.mCount = self.mCount - 1
	end
end

-- 获得装备的配置id
function EquipModel:getEquipConfId(equipId)
	local info = self.mEquips[equipId]
	if info then
		return info.confId
	else
		return 0
	end
end

-- 获取装备属性
function EquipModel:getEquipInfo(equipId)
	return self.mEquips[equipId]
end

-- 获得所有装备
function EquipModel:getEquips()
	return self.mEquips
end

function EquipModel:getEquipCount()
	return self.mCount
end

function EquipModel:getConfEquips()
	local equips = {}
    for k, v in pairs(self.mEquips) do
        equips[k] = v.confId
    end
    
    return equips
end

return EquipModel