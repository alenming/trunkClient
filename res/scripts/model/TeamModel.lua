require"model.ModelConst"

-- 队伍模型
local TeamModel = class("TeamModel")

function TeamModel:ctor()
	self.mTeamSummoner = {}
	self.mTeamHero = {}
end

function TeamModel:init(buffData)
	local count = buffData:readInt()						-- 队伍数(多种类型的队伍)
	self.mTeamSummoner = {}									-- teamType, summoner
	self.mTeamHero = {}										-- teamType, herolist
	for i = 1, count do
		local teamType = buffData:readInt()					-- 队伍类型
		local summonerID = buffData:readInt()				-- 召唤师ID
		self.mTeamSummoner[teamType] = summonerID

		self.mTeamHero[teamType] = {}
		for j = 1, 7 do
			local heroID = buffData:readInt()				-- 英雄id
			table.insert(self.mTeamHero[teamType], heroID)
		end
	end

	return true
end

-- 根据队伍类型获取队伍
function TeamModel:getTeamInfo(teamType)
	return self.mTeamSummoner[teamType], self.mTeamHero[teamType]
end
  
-- 根据队伍类型设置队伍信息
function TeamModel:setTeamInfo(teamType, summonerID, heroList)
	if teamType > ETeamType.ETT_SPORTE or teamType < ETeamType.ETT_PASE then
		return
	end
	self.mTeamSummoner[teamType] = summonerID
	self.mTeamHero[teamType] = heroList
end

-- 从所有队伍中去掉某个英雄
function TeamModel:removeHeroFromAllTeam(heroID)
	for _, heroList in pairs(self.mTeamHero) do
		for idx, id in ipairs(heroList) do
			if id == heroID then
				table.remove(heroList, idx)
				break
			end
		end
	end
end

-- 英雄是否存在队伍中(任意队伍)
function TeamModel:hasHeroAllTeam(heroID)
	for _, heroList in pairs(self.mTeamHero) do
		for _, id in ipairs(heroList) do
			if id == heroID then return true end
		end
	end
	return false
end

return TeamModel