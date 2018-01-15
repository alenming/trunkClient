--[[
	装备打造数据模型
	王向明
	2016年10月18日 10:32:23
]]

--装配部位	装配等级	装配职业	备注	装备名称    装备图标名称	
--装备合成基础材料1	材料1数量	装备合成材料2	材料2数量	装备合成材料3	材料3数量	装备合成材料4	材料4数量	装备品级提升材料5	材料5数量
--普通铸造金币消耗	精品铸造金币消耗	
--白色品质	普通铸造品级权值	精品铸造品级权值	绿	普通铸造品级权值	精品铸造品级权值	蓝	普通铸造品级权值	精品铸造品级权值	
--紫	普通铸造品级权值	精品铸造品级权值	金	普通铸造品级权值	精品铸造品级权值

 --{ Eq_Parts = 1, Eq_Level = 20, Eq_Vocation = 1, Item_Name = 32033, Eq_Synthesis1 = 120005, Eq_Synthesis1Param = 10,
 --Eq_Synthesis2 = 120005, Eq_Synthesis2Param = 10, Eq_Synthesis3 = 120009, Eq_Synthesis3Param = 10, Eq_Synthesis4 = 120101,
 -- Eq_Synthesis4Param = 1, Eq_Synthesis5 = 120013, Eq_Synthesis5Param = 1, Eq_NormalCastGoldCost = 10000, Eq_QualityCastGoldCost = 10000, 
 --Quality1_EqCreatID = 200017, Quality1_NormalCastWeight = 10, Quality1_QualityCastWeight = 10, Quality2_EqCreatID = 200018, Quality2_NormalCastWeight = {}, 
 --Quality3_EqCreatID = 200019, Quality3_NormalCastWeight = {}, Quality4_EqCreatID = 200020, Quality4_NormalCastWeight = {}, Quality5_EqCreatID = 0, Quality5_NormalCastWeight = {}, }

local tableEquip = getEquipmentForCast()
local EquipmentSetting = getEquipmentSetting()

-- 装备打造模型
local EquipMakeModel = class("EquipMakeModel")

function EquipMakeModel:ctor()
end

function EquipMakeModel:init()

end

function EquipMakeModel:getEquipByIndex(index)
	if tableEquip[index] then
	   return tableEquip[index]
	else
		return nil
	end
end

function EquipMakeModel:getEquipByHead(vocation, lv)	--职业加等级确定好一类装备的下标位置
	local result = {}

	for i,temp in pairs(tableEquip) do
		if temp.Eq_Level == lv and temp.Eq_Vocation == vocation then 		--等级职业相同,把这一系统装备数据取出来
			table.insert(result, i)
		end	
	end

	table.sort(result,function(index1,index2)
		return index1 < index2 and true or false
	end)
	return result
end

--获得装备一共会有多少个属性
function EquipMakeModel:getEquipQualityRandCount(maxQuality)
	if EquipmentSetting[maxQuality] then
		return EquipmentSetting[maxQuality].Eq_AttributeMax
	end
	return nil
end

function EquipMakeModel:getEquipModelCanBreakEquip()
	local equipDyList = {}
	local euqipsCopy = {}
	local allEquip = getGameModel():getEquipModel():getEquips()
	for i,info in pairs(allEquip) do
		table.insert(euqipsCopy,i,info)
	end

	local allHeroid = getGameModel():getHeroCardBagModel():getHeroCards()
	for _,id in pairs(allHeroid) do
		local heroCard = getGameModel():getHeroCardBagModel():getHeroCard(id)
		local equips = heroCard:getEquips()
		for _,equipId in pairs(equips) do
			if equipId ~=0 then
				euqipsCopy[equipId] = nil
			end
		end
	end
	for _,equip in pairs(euqipsCopy) do
		local temp = {}
		local confId = getGameModel():getEquipModel():getEquipConfId(equip.equipId)

		temp.equipId = equip.equipId
		temp.isSelected = false
		temp.confId = confId
		temp.propConf = getPropConfItem(confId)
		temp.breakData = getEquipmentConfItem(confId)

		table.insert(equipDyList, temp)
	end

	return equipDyList
end

return EquipMakeModel