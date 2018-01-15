UIEquipMakeRedHelper = {}

local equipMakeModel = getGameModel():getEquipMakeModel()
local bagModel = getGameModel():getBagModel()
local tableEquip = getEquipmentForCast()


UIEquipMakeRedHelper.mCanShowRed = {}
UIEquipMakeRedHelper.mCanShowJob = false
UIEquipMakeRedHelper.mCanShowLevel = false
UIEquipMakeRedHelper.mCanShowJobRed = {}
UIEquipMakeRedHelper.mCanShowLevelRed = {}
UIEquipMakeRedHelper.mCanShowPartsRed = {}

local isQuality = false--cc.UserDefault:getInstance():setBoolForKey("isQuality", isQuality)
local myGold = getGameModel():getUserModel():getGold()


function UIEquipMakeRedHelper:abcdefg()
	UIEquipMakeRedHelper.mCanShowRed = {}
	UIEquipMakeRedHelper.mCanShowJob = false
	UIEquipMakeRedHelper.mCanShowLevel = false
	UIEquipMakeRedHelper.mCanShowJobRed = {}
	UIEquipMakeRedHelper.mCanShowLevelRed = {}
	UIEquipMakeRedHelper.mCanShowPartsRed = {}
	for index,info in pairs(tableEquip) do
		self:oneEquip(index, info)
	end

	self:xxxxx()
	--[[print("有红点的装备如下")
	dump(self.mCanShowJobRed)
	dump(self.mCanShowLevelRed)
	dump(self.mCanShowPartsRed)
	--]]
end


function UIEquipMakeRedHelper:oneEquip(index, info)
	self.mCanShowRed[index] = {}

	local needGold = isQuality and info.Eq_QualityCastGoldCost or info.Eq_NormalCastGoldCost
	if myGold < needGold then
		self.mCanShowRed[index] = nil
		return
	end
	for i=1,5 do
		local id = info["Eq_Synthesis"..i]
		if id ==0  then
		
		else
			local count = bagModel:getItemCountById(info["Eq_Synthesis"..i])
			local needCount = info["Eq_Synthesis"..i.."Param"]
			if count < needCount and i~=5 then
				self.mCanShowRed[index] = nil
				return
			end
		end
	end
	self.mCanShowRed[index].job = info.Eq_Vocation
	self.mCanShowRed[index].level = info.Eq_Level
	self.mCanShowRed[index].parts = info.Eq_Parts
end


function UIEquipMakeRedHelper:xxxxx()
	self.mCanShowPartsRed = {}

	for index,info in pairs(self.mCanShowRed) do
		if info ~= nil then
			self.mCanShowPartsRed[index] = {}
			self.mCanShowJob = true
			self.mCanShowLevel = true
			self.mCanShowJobRed[info.job] = info.job
			--self.mCanShowLevelRed[info.level] = info.level

			if type(self.mCanShowLevelRed[info.job]) ~= "table" then
				self.mCanShowLevelRed[info.job] = {}
			end
			table.insert(self.mCanShowLevelRed[info.job], info.level, info.level)
			--self.mCanShowLevelRed[info.job][info.level] = info.level
			
			table.insert(self.mCanShowPartsRed[index], info)
		end
	end
end

return UIEquipMakeRedHelper