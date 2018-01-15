-- 英雄卡片模型
local HeroCardModel = class("HeroCardModel")

function HeroCardModel:ctor()
	self.mID = 0							
	self.mFrag = 0							
	self.mLv = 0							
	self.mStar = 0							
	self.mExp = 0							
	self.mTalent = {}	
	self.mEquips = {} 						
	for i = 1, 6 do
		self.mEquips[i] = 0
	end
	-- 佣兵相关数据
	self.mUserId = 0
	self.mUserName = ""
	self.mTime = 0
	--这个数据可以用mEquips,都是保存装备的ID,是configId,不是dyId
	self.mMercenaryeEquips = {}

end

function HeroCardModel:init(heroId, heroFrag, heroLv, heroStar, heroExp, heroTalent, equips)
	self.mID = heroId						-- 英雄id
	self.mFrag = heroFrag					-- 英雄碎片
	self.mLv = heroLv						-- 等级
	self.mStar = heroStar					-- 星级
	self.mExp = heroExp						-- 经验
	self.mTalent = heroTalent 				-- 激活天赋
	self.mEquips = equips 					-- 装备, 个数一定是6个, 未装备为0
	return true
end

function HeroCardModel:setID(id)
	self.mID = id
end

function HeroCardModel:getID()
	return self.mID
end

function HeroCardModel:setFrag(frag)
	self.mFrag = frag
end

function HeroCardModel:getFrag()
	return self.mFrag
end

function HeroCardModel:setLevel(lv)
	self.mLv = lv
end

function HeroCardModel:getLevel()
	return self.mLv
end

function HeroCardModel:setStar(star)
	self.mStar = star
end

function HeroCardModel:getStar()
	return self.mStar
end

function HeroCardModel:setExp(exp)
	self.mExp = exp
end

function HeroCardModel:getExp()
	return self.mExp
end

function HeroCardModel:setTalent(talent)
	self.mTalent = talent
end

function HeroCardModel:getTalent()
	return self.mTalent
end

-- 添加, 删除, 替换 英雄装备 
-- @param eqPart: 装备部位，类型EquipPartType
-- @param eqDynID: 0表示该部位没有装备
function HeroCardModel:setEquip(eqPart, eqDynID)
	if eqPart >= 1 and eqPart <= 6 then
		self.mEquips[eqPart] = eqDynID
	end
end

-- @param eqPart: 装备部位，类型EquipPartType
function HeroCardModel:getEquip(eqPart)
	if eqPart >= 1 and eqPart <= 6 then
		return self.mEquips[eqPart]
	end
	return 0
end

function HeroCardModel:getEquips()
	return self.mEquips
end

return HeroCardModel