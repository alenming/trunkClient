local HeroCardModel = require"model.HeroCardModel"

-- 英雄卡包模型
local HeroCardBagModel = class("HeroCardBagModel")

function HeroCardBagModel:ctor()
	self.mCount = 0										
	self.mHeroCards = {}								
end

function HeroCardBagModel:init(buffData)
	self.mCount = buffData:readUChar()					-- 英雄卡牌数量
	self.mHeroCards = {}								-- 英雄卡牌容器
	for i = 1, self.mCount do
		local heroId = buffData:readInt()				-- 英雄id
		local heroFrag = buffData:readUShort()			-- 英雄碎片
		local heroLv = buffData:readUChar()				-- 等级
		local heroStar = buffData:readUChar()			-- 星级
		local heroExp = buffData:readInt()				-- 经验
		local heroTalent = {}
        for j = 1, 8 do
			table.insert(heroTalent, buffData:readUChar()) -- 天赋
		end
		local equips = {}
		for j = 1, 6 do
			table.insert(equips, buffData:readInt())	-- 装备
		end

		local heroCard = HeroCardModel.new()
		heroCard:init(heroId, heroFrag, heroLv, heroStar, heroExp, heroTalent, equips)
		self.mHeroCards[heroId] = heroCard
	end
	return true
end

function HeroCardBagModel:addHeroCard(id)
	if self.mHeroCards[id] then
		return false
	else
		local hero = HeroCardModel.new()
		hero:setID(id)
		self.mHeroCards[id] = hero
		self.mCount = self.mCount + 1
		return true
	end
end

function HeroCardBagModel:hasHeroCard(id)
	return self.mHeroCards[id] ~= nil
end

function HeroCardBagModel:getHeroCard(id)
	return self.mHeroCards[id]
end

-- @return 英雄卡牌id的列表
function HeroCardBagModel:getHeroCards()
	local ids = {}
	for id, _ in pairs(self.mHeroCards) do
		table.insert(ids, id)
	end
	return ids
end

-- @return 英雄卡牌id的列表
function HeroCardBagModel:getHeroCardKeyIsHeroId()
	local ids = {}
	for id, _ in pairs(self.mHeroCards) do
		table.insert(ids,id, id)
	end
	return ids
end

function HeroCardBagModel:getHeroCardCount()
	return self.mCount
end

function HeroCardBagModel:getWholeCardCount()
	local count = 0
	for _, heroCard in pairs(self.mHeroCards) do
		if heroCard:getStar() ~= 0 then
			count = count + 1
		end
	end
	return count
end

-- 获取整卡列表
function HeroCardBagModel:getWholeCards()
	local wholeCards = {}
	for heroid, heroCard in pairs(self.mHeroCards) do
		if heroCard:getStar() ~= 0 then
			table.insert(wholeCards, heroid)
		end
	end
	return wholeCards
end

return HeroCardBagModel