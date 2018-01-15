-- 王向明
-- 2016年10月12日 11:43:34
-- 公会佣兵模型
local scheduler = require("framework.scheduler")
local HeroCardModel = require"model.HeroCardModel"
local UnionMercenaryModel = class("UnionMercenaryModel")
local MercenaryNumber = getMercenaryNumber()

function UnionMercenaryModel:ctor()
	self.mCount = 0						-- 公会佣兵人数
	self.countSize = 0-- 已经雇佣过的英雄
	self.mMyselfMecenaryCount	= 0		-- 自己派遣的英雄的个数
	self.mMyselfMecenarys = {}
	self.UnionMercenarys = {}			-- 公会佣兵信息

	self.mMyMercenariedHero = {}		-- 已经雇佣过的英雄的佣兵
	self.mCurMercenaryInfo  = {}		-- 当前要显示的佣兵详细信息,用表,在左右切换时,如果有数据就不再请求

	self.mSortTable = {}                -- 为了排序用,下标必须以1开始
    self.isInit = false
end

function UnionMercenaryModel:init(buffData)
    self.isInit = true
	self.mCount = buffData:readInt()					-- 英雄卡牌数

	self.UnionMercenarys = {}							-- 英雄卡牌容器
	for i = 1, self.mCount do
		local heroCard = {}
		heroCard.userName 	= buffData:readCharArray(32)		--该英雄的玩家名字
		heroCard.dyId 		= buffData:readInt()
		heroCard.heroId 	= buffData:readInt()				-- 英雄id
		heroCard.heroLv 	= buffData:readInt()				-- 等级
		heroCard.heroStar	= buffData:readInt()				-- 星级
		self.UnionMercenarys[heroCard.dyId] = heroCard
	end

	--自己派遣的佣兵, 没有为0 ,根据这个值和自己的ID 去公会佣兵里找自己的数据
	self.mMyselfMecenaryCount = buffData:readInt()
	self.mMyselfMecenarys = {}
	for i=1,self.mMyselfMecenaryCount do
		local oneMercenary = {}
		oneMercenary.tag = buffData:readInt()
		oneMercenary.dyId = buffData:readInt()
		oneMercenary.time = buffData:readInt()
		oneMercenary.money = buffData:readInt()
		oneMercenary.heroId = self.UnionMercenarys[oneMercenary.dyId] and self.UnionMercenarys[oneMercenary.dyId].heroId or 0
		self.mMyselfMecenarys[oneMercenary.tag] = oneMercenary
	end

	local temp = buffData:readInt()

	self.countSize = temp and temp or 0 

	self.mMyMercenariedHero = {}

	for k=1,self.countSize do
		local mercenaryId = buffData:readInt()
		table.insert(self.mMyMercenariedHero, mercenaryId)
		self:deleteUsedHero(mercenaryId)
	end
	self:sortMercenaryHero()
	-- 时间到12点之后
	--self.surplusTimeSheduler = scheduler.scheduleGlobal(handler(self, self.update), 1)
	return true
end

--点击详细信息时,这个佣兵的数据放在这
function UnionMercenaryModel:refreshCurMercenaryData(buffData)
 	local dyId = buffData:readInt()
	local heroId = buffData:readInt()				-- 英雄id
	local heroLv = buffData:readInt()				-- 等级
	local heroStar = buffData:readInt()				-- 星级
	local heroExp = buffData:readInt() 					--没卵用的经验
	--local heroTalent = buffData:readInt()			-- 激活天赋
	local skillLvs = {}
	local equips = {}
	local oneHeroEquips = {}	

	for j = 1, 8 do
		table.insert(skillLvs, buffData:readChar())	-- 技能1, 2等级
	end

	local equipCount = buffData:readInt()

	for i = 1, 6 do
		local oneEquip = {}	
		--  confId是装备在道具表中的ID
		oneEquip.confId = buffData:readInt()	
		--oneEquip.dyId = buffData:readInt()  -- 此ID没啥用了....占个位置								
		oneEquip.eqEffectIDs = {}
		for j = 1, 8 do
			table.insert(oneEquip.eqEffectIDs, buffData:readChar()) 	
		end
		oneEquip.eqEffectValues = {}
		for j = 1, 8 do
			table.insert(oneEquip.eqEffectValues, buffData:readShort())	
		end

		table.insert(equips, oneEquip.confId)
		oneHeroEquips[i] = oneEquip		
	end

	local heroCard = {}
	heroCard.dyId 			= dyId
	heroCard.userName 		= userName	
	heroCard.userId 		= userId	
	heroCard.heroId 		= heroId	
	heroCard.heroLv 		= heroLv	
	heroCard.heroStar		= heroStar
	heroCard.heroExp        = heroExp			
	heroCard.tallent 		= skillLvs				
	heroCard.oneHeroEquips	= oneHeroEquips				
	heroCard.equips 		= equips 				
	heroCard.heroTalent 	= heroTalent 
	self.mCurMercenaryInfo[dyId] = heroCard
end

--测试数据
function UnionMercenaryModel:initDebugData()
end

function UnionMercenaryModel:getCurMercenaryInfo(dyId)
	if self.mCurMercenaryInfo then
		return self.mCurMercenaryInfo[dyId]
	end
end

function UnionMercenaryModel:getMyselfInfo()
	return self.mMyselfMecenarys
end
-- 用下标查找
function UnionMercenaryModel:getMyselfInfoByTag(tag)
	for _,info in pairs(self.mMyselfMecenarys) do
		if tag == info.tag then
			return info
		end
	end
	return {tag=tag, heroId=0, dyId = 0,time = 0, money = 0}
end
-- 用佣兵ID查找
function UnionMercenaryModel:getMyselfInfoByDyId(dyId)
	for _,info in pairs(self.mMyselfMecenarys) do
		if dyId == info.dyId then
			return info
		end
	end
	return {tag=tag, heroId=0, dyId = 0,time = 0, money = 0}
end
-- 以下标为索引的方式修改自己所派遣佣兵的数据
function UnionMercenaryModel:setMyselfInfoByTag(tag, nowInfo)
	self.mMyselfMecenarys[tag] = nowInfo
end

-- 所有公会佣兵数据
function UnionMercenaryModel:getUnionMercenarys()
	return self.UnionMercenarys
end
-- 查找公会佣兵中的某一个佣兵的数据,以佣兵ID为索引
function UnionMercenaryModel:getUnionMercenaryByDyId(dyId)
	if self.UnionMercenarys[dyId] then
		return self.UnionMercenarys[dyId]
	end
	return {userName = "", dyId = dyId, heroId = 0,heroLv = 1,heroStar = 1}
end

-- 英雄佣兵id的列表
function UnionMercenaryModel:getUnionMercenaryList()
	local ids = {}
	if table.maxn(self.mSortTable) > 0 then
		for _,dyId in pairs(self.mSortTable) do
			table.insert(ids, dyId)
		end
		return ids
	end
end

--所有佣兵简单数据,外在全部简单卡牌初始化用,详细界面不能用这接口
function UnionMercenaryModel:getUnionMercenarysSimpleInfo()
	local cardsInfo = {}
	if table.maxn(self.mSortTable) > 0 then
		local i = 1
		for _,dyId in pairs(self.mSortTable) do
			local heroModel = self.UnionMercenarys[dyId]
			local heroId = heroModel.heroId
			local upRateConf = getSoldierUpRateConfItem(heroId)
			local star = heroModel.heroStar
			local heroConf = getSoldierConfItem(heroId, star)

			if heroConf == nil or upRateConf == nil then
				print("error !!! heroConf or upRateConf is nil by heroId:", 
					heroId, heroModel and heroModel.heroStar or upRateConf.DefaultStar)
			end

			-- 初始化固定属性, 及默认属性
			cardsInfo[i] = {
					dyId = heroModel.dyId,
					heroId = heroModel.heroId,
					userName = heroModel.userName,
					userId = heroModel.userId,

					defaultStar = upRateConf.DefaultStar,
					topStar = TopStar,
					icon = heroConf.Common.HeadIcon,
					cost = heroConf.Cost,
					race = heroConf.Common.Race,
					job = heroConf.Common.Vocation,
					callFrag = 0,
					lv = heroModel.heroLv,
					star = heroModel.heroStar,
					rare = heroConf.Rare,
			}
			i = i + 1
		end
	end
	return cardsInfo
end


--删除已经雇佣过的佣兵 ,拉取信息里要调用一次
function UnionMercenaryModel:deleteUsedHero(dyid)
    for i,heroModel in pairs(self.UnionMercenarys or {}) do
        local this_merceanryId = heroModel.dyId
        if this_merceanryId == dyid  then
            self.UnionMercenarys[i] = nil
            break
        end
    end
end


-- 排序,抄别人的就好了
function UnionMercenaryModel:sortMercenaryHero()
	-- 排序
	local function sortIDByLv(id1, id2)
		local info1 = self.UnionMercenarys[id1]
		local info2 = self.UnionMercenarys[id2]
		if info1.heroLv > info2.heroLv then
			return true
		elseif info1.heroLv == info2.heroLv then
			if info1.heroStar > info2.heroStar then
				return true
			elseif info1.heroStar == info2.heroStar then --星级相同看消耗
				local heroConf1 = getSoldierConfItem(info1.heroId, info1.heroStar)
				local heroConf2 = getSoldierConfItem(info2.heroId, info2.heroStar)

				if heroConf1.Cost > heroConf2.Cost then
					return true
				end	
			end
		end
		return false
	end
	self.mSortTable = {}

	local i  = 1
	for _,info in pairs(self.UnionMercenarys) do

		table.insert(self.mSortTable,i, info.dyId)
		i = i+1
	end

	table.sort(self.mSortTable, sortIDByLv)

end

-- 派遣后插到佣兵背包里
function UnionMercenaryModel:insertHeroToMercenaryBag(dyId, heroId, name, lv, star)
	if dyId <= 0 or heroId <= 0 or name == "" then
		return
	end

	local heroModel = {}
	heroModel.dyId 	   = dyId
	heroModel.heroId   = heroId
	heroModel.userName = name
	heroModel.heroLv   = lv				-- 等级
	heroModel.heroStar = star 	 		-- 星级

	self.UnionMercenarys[dyId] = heroModel

	self:sortMercenaryHero()

end

--删除自己,或者别人召回的佣兵
function UnionMercenaryModel:deleteHeroToMercenaryBag(dyId)
	if dyId <= 0 then
		return
	end

	if table.maxn(self.UnionMercenarys) > 0 then
		for i,heroModel in pairs(self.UnionMercenarys) do
			local mDyId = heroModel.dyId

			if dyId == mDyId then
				self.UnionMercenarys[i] = nil
				break
			end
		end
	end

	self:sortMercenaryHero()
end

function UnionMercenaryModel:getMecenartyCount()
	local count = 0
	for i,info in ipairs(MercenaryNumber) do
		if info.MercenaryPrice == 0 then
			count = i	
		end
	end
	return count
end

-- 获取所有非自己的佣兵: 等级限制
function UnionMercenaryModel:getOtherMercenarys()
    local userLevel = getGameModel():getUserModel():getUserLevel()
    local otherMercenarys = {}
    for i, v in pairs(self.UnionMercenarys) do
        local temp = {}
        temp.userName = v.userName
        temp.dyId = v.dyId
        temp.heroId = v.heroId
        temp.heroLv = v.heroLv
        temp.heroStar = v.heroStar
        if temp.heroLv >  userLevel + 15 then
            temp.heroLv = userLevel + 15
        end
        otherMercenarys[i] = temp
    end

    for i, v in pairs(self.mMyselfMecenarys) do
        otherMercenarys[v.dyId] = nil
    end
    return otherMercenarys
end

function UnionMercenaryModel:update(dt)  
    local cur = getGameModel():getNow()
    local delta = cur --time 
    if delta < 0 then
        delta = 0
    end
    local d = math.modf(delta / 86400)
    local h = math.modf((delta - d * 86400) / 3600)
    local m = math.modf((delta - d * 86400 - h * 3600) / 60)
    local s = math.modf(delta - d * 86400 - h * 3600 - m * 60)
    if h==0 and m==0 and s==0 then
    	print("24点.清空本地的需要清空的数据")
    	self.mMyMercenariedHero  = {}
    end
end  

function UnionMercenaryModel:updateReFresh()  
    self.mMyMercenariedHero  = {}
    if UIManager.isTopUI(UIManager.UI.UIUnionMercenary) then
		local ui = UIManager.getUI(UIManager.UI.UIUnionMercenary)
		ui:initUnionUI()
	end
end 

return UnionMercenaryModel