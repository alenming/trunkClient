--[[
	佣兵卡包界面
--]]

local UIUnionHeroCard 	= class("UIUnionHeroCard", require("common.UIView"))
local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()

local csbFile           = ResConfig.UIUnionHeroCard.Csb2
local sortFile          = "ui_new/g_gamehall/c_card/DownListButton.csb"
local btnFile = "ui_new/g_gamehall/b_bag/AllButton.csb"
local starFile = "ui_new/g_gamehall/c_card/HeroStar_S.csb"

local parts     = {quanbu = 0, ren = 1, ziran = 2, siling = 3, qita = 4}
local sortType  = {lvMax = 1, starMax = 2, costMin = 3 }
local sortTypeLan = {584, 585, 586}


function UIUnionHeroCard:ctor()
	self.rootPath 	= csbFile.cardBag
	self.root 		= getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 因为卡片数量固定, 所以缓存起卡片
	self.items = {}
	self.itemsCache = {}

	-- 返回按钮
	self.backBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(self.backBtn, function (obj)
		obj:setTouchEnabled(false)
		UIManager.close()
	end)

	-- 召唤用的卡片
	self.callPanel = CsbTools.getChildFromPath(self.root, "SummonPanel")

	-- 标题:英雄卡包
	local titleLab = CsbTools.getChildFromPath(self.root, "MainPanel/Image_Tittle/TittleFontLabel")
	titleLab:setString(CommonHelper.getUIString(591))

	-- 文字: 卡牌数量
	CsbTools.getChildFromPath(self.root, "MainPanel/Text_1")
		:setString(CommonHelper.getUIString(30))
	-- 卡片数量值
	self.cardNumValueLab = CsbTools.getChildFromPath(self.root, "MainPanel/HeroNumLbael")

	-- 排序csb
	self.sortCsb 	= CsbTools.getChildFromPath(self.root, "MainPanel/DownListButton")
	self.sortBtn 	= CsbTools.getChildFromPath(self.sortCsb, "OrderButton")
	self.sortBtnLab = CsbTools.getChildFromPath(self.sortBtn, "ButtonName")
	CsbTools.initButton(self.sortBtn, handler(self, self.sortBtnCallBack))
	self.sortBtnLab:setString(CommonHelper.getUIString(sortTypeLan[1]))
	local filePath 	= {"Button_Level", "Button_Star", "Button_ConS"}
	for i, path in ipairs(filePath) do
		local sortTypeBtn = CsbTools.getChildFromPath(self.sortCsb, "DownListView/" .. path)
		sortTypeBtn:setTitleText(CommonHelper.getUIString(sortTypeLan[i]))
		sortTypeBtn:setTag(i)
		CsbTools.initButton(sortTypeBtn, handler(self, self.sortTypeBtnCallBack))
	end

	-- 五个按钮(全部, 人族, 自然族, 死灵族, 其他) 和各自文字
	local lanIDs = {513, 514, 582, 517, 583}
    self.raceBtn = {}
	for i=0, 4 do
		local raceBtn = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_" .. (i+1))
		local btnCsb  = CsbTools.getChildFromPath(raceBtn, "AllButton")
		local raceLab = CsbTools.getChildFromPath(btnCsb, "ButtonPanel/NameLabel")
		local raceStr = CommonHelper.getUIString(lanIDs[i+1])
		self.raceBtn[i] = raceBtn
		raceBtn:setTag(i)
		raceBtn:setLocalZOrder(i==0 and 10 or -10)		
		CsbTools.initButton(raceBtn, handler(self, self.raceBtnCallBack), raceStr, raceLab, "AllButton")
		CommonHelper.playCsbAnimate(btnCsb, btnFile, i==0 and "On" or "Normal", false, nil, true)
        CsbTools.getChildFromPath(btnCsb, "RedTipPoint"):setVisible(false)
	end

	self.scroll 	= CsbTools.getChildFromPath(self.root, "MainPanel/CardScrollView")
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()

	-- item的size
	local itemCsb 	= getResManager():getCsbNode(csbFile.cardItem)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "HeroCard"):getContentSize()
end

function UIUnionHeroCard:onOpen(preId, tag, mmcallback)
	self.titleTouchCount = 0
	self.backBtn:setTouchEnabled(true)
	self.callPanel:setVisible(false)
	self.mCaback = 	mmcallback

	self.showPart 		= parts.quanbu	-- 显示部位
	self.sortType		= sortType.lvMax-- 排序方式
	self.isShowSortList	= false			-- 显示排序
	self.cardsInfo 		= {}			-- 卡片信息
	self.idList 		= {}			-- 卡片列表顺序

	self.mTag = tag  --派遣类型

	self:reShowSortList()
	self:reGetHerosInfo()
	self:changeShowPart(parts.quanbu)
end

function UIUnionHeroCard:onClose()
	self:cacheItems()
end

function UIUnionHeroCard:onTop(preUIID, heroID)
	self:reGetHerosInfo()
	self:reSortHerosID()
	self:reloadScroll()


	if heroID == nil or heroID == 0 then
		self.scroll:scrollToPercentVertical(0, 0.8, true)
	else
		local cardNode = self.scroll:getChildByTag(heroID)
		if cardNode == nil then return end

		local _, cardPosY = cardNode:getPosition()
		local scrollSize 	= self.scroll:getContentSize()
		local innerSize = self.scroll:getInnerContainerSize()
        local percent = 0
        if innerSize.height > scrollSize.height then
		    percent = (innerSize.height - cardPosY - self.itemSize.height/2 - 7) / (innerSize.height - scrollSize.height)
        end
		if percent > 1 then	percent = 1	end
		self.scroll:scrollToPercentVertical(percent*100, 0.8, true)
	end
end

function UIUnionHeroCard:cacheItems()
	for _, item in pairs(self.items) do
		item:setVisible(false)
		table.insert(self.itemsCache, item)
	end
	self.items = {}
end

-- 重新获取英雄数据
function UIUnionHeroCard:reGetHerosInfo()
	self.cardsInfo 	= {}

	-- 获取所有卡片
	local soldierList = getGameModel():getHeroCardBagModel():getHeroCardKeyIsHeroId()
	-- 过滤已经派遣的卡片
	local allHero = UnionMercenaryModel:getMyselfInfo()

	for j,info in pairs(allHero) do
		if info.heroId~=0 then
			if soldierList[info.heroId] then
			   soldierList[info.heroId] = nil
			end
		end

	end

	for i,id in pairs(soldierList) do
		self:reGetHeroInfo(id,id)
	end
end

function UIUnionHeroCard:reGetHeroInfo(id)
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(id)
	local upRateConf = getSoldierUpRateConfItem(id)
	local star = upRateConf.DefaultStar
	if heroModel and heroModel:getStar() ~= 0 then
		star = heroModel:getStar()
	end
	local heroConf = getSoldierConfItem(id, star)
	if heroConf == nil or upRateConf == nil then
		print("error !!! heroConf or upRateConf is nil by id:", 
			id, heroModel and heroModel:getStar() or upRateConf.DefaultStar)
	end

	-- 初始化固定属性, 及默认属性
	self.cardsInfo[id] = {
		id = id,
		defaultStar = upRateConf.DefaultStar,
		topStar = TopStar,
		icon = heroConf.Common.HeadIcon,
		cost = heroConf.Cost,
		race = heroConf.Common.Race,
		job = heroConf.Common.Vocation,
		frag = 0,
		callFrag = 0,
		lv = 0,
		star = 0,
		rare = heroConf.Rare,
		source = upRateConf.Source	
	}

	if heroModel then
		self.cardsInfo[id].frag = heroModel:getFrag()
		self.cardsInfo[id].lv = heroModel:getLevel()
		self.cardsInfo[id].star = heroModel:getStar()
	end
	if self.cardsInfo[id].star == 0 then
		local soldierStarConf = getSoldierStarSettingConfItem(self.cardsInfo[id].defaultStar)
		self.cardsInfo[id].callFrag = soldierStarConf.TurnCardCount
	end
end

-- 重新排序
function UIUnionHeroCard:reSortHerosID()
	-- 最高优先级 : 返回值 0小于 1相等 2大于
	-- 所有卡牌排序，先显示已有卡牌，再显示未获得卡牌，未获得卡牌在同规则排序时，按照召唤英雄碎片比例大的排在前面
	local function hightest(id1, id2)
		local info1 = self.cardsInfo[id1]
		local info2 = self.cardsInfo[id2]
		if info1.star ~= 0 and info2.star == 0 then
			return 2
		elseif info1.star == 0 and info2.star ~= 0 then
			return 0
		elseif info1.star == 0 and info2.star == 0 then
			if (info1.frag/info1.callFrag) > (info2.frag/info2.callFrag) then
				return 2
			elseif (info1.frag/info1.callFrag) < (info2.frag/info2.callFrag) then
				return 0
			end
		end
		return 1
	end

	-- 排序函数
	-- 最高优先级>等级>星级>ID
	local function sortIDByLv(id1, id2)
		local info1 = self.cardsInfo[id1]
		local info2 = self.cardsInfo[id2]
		local hightStatus = hightest(id1, id2)
		if hightStatus == 2 then
			return true
		elseif hightStatus == 1 then
			if info1.lv > info2.lv then
				return true
			elseif info1.lv == info2.lv then
				if info1.star > info2.star then
					return true
				elseif info1.star == info2.star then
					if info1.defaultStar > info2.defaultStar then
						return true
					elseif info1.defaultStar == info2.defaultStar then
						if info1.id < info2.id then
							return true
						end
					end
				end
			end
		end
		return false
	end

	-- 最高优先级>星级>等级>ID
	local function sortIDByStar(id1, id2)
		local info1 = self.cardsInfo[id1]
		local info2 = self.cardsInfo[id2]
		local hightStatus = hightest(id1, id2)
		if hightStatus == 2 then
			return true
		elseif hightStatus == 1 then
			if info1.star > info2.star then
				return true
			elseif info1.star == info2.star then
				if info1.defaultStar > info2.defaultStar then
					return true
				elseif info1.defaultStar == info2.defaultStar then
					if info1.lv > info2.lv then
					 	return true
					elseif info1.lv == info2.lv then
						if info1.id < info2.id then
							return true
						end
					end
				end
			end
		end
		return false
	end

	-- 最高优先级>消耗>等级>星级>ID
	local function sortIDByCost(id1, id2)
		local info1 = self.cardsInfo[id1]
		local info2 = self.cardsInfo[id2]
		local hightStatus = hightest(id1, id2)
		if hightStatus == 2 then
			return true
		elseif hightStatus == 1 then
			if info1.cost > info2.cost then
				return true
			elseif info1.cost == info2.cost then
				if info1.lv > info2.lv then
					return true
				elseif info1.lv == info2.lv then
					if info1.star > info2.star then
						return true
					elseif info1.star == info2.star then
						if info1.defaultStar > info2.defaultStar then
							return true
						elseif info1.defaultStar == info2.defaultStar then
							if info1.id < info2.id then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end

	local func = {
		[sortType.lvMax]	= sortIDByLv,
		[sortType.starMax]	= sortIDByStar,
		[sortType.costMin]	= sortIDByCost
	}

	-- 显示的卡片
	self.idList = {}
	local cardCount = 0
	for id, info in pairs(self.cardsInfo) do
		if self.showPart == info.race or self.showPart == parts.quanbu then
			table.insert(self.idList, id)
			if info.star ~= 0 then
				cardCount = cardCount + 1
			end
		end
	end

	-- 排序
	table.sort(self.idList, func[self.sortType])

	self.cardNumValueLab:setString(cardCount .. "/" .. #self.idList)
end

-- 重新显示卡包里面的卡片
function UIUnionHeroCard:reloadScroll()
	self:cacheItems()

	if #self.idList == 0 then
		self.scroll:setInnerContainerSize(self.scroll:getContentSize())
		return
	end

	local itemPlace = {}
	local hang = 0
	local lie = 6
	local isFrag = false
	for i, v in ipairs(self.idList) do
		if self.cardsInfo[v].star == 0 and isFrag == false then
			isFrag = true
			hang = hang + 1
			lie = 1
		else
			if lie == 6 then
				hang = hang + 1
				lie = 1
			else
				lie = lie + 1
			end
		end
		table.insert(itemPlace, {hang = hang, lie = lie, isFrag = isFrag})
	end

	local intervalX = 9
	local intervalY = 10
	local offsetX = 5
	local offsetY = 15
	local innerSize = self.scroll:getContentSize()
	--算scrollview高的大小
	local hang = itemPlace[#itemPlace].hang


	for i=1,#itemPlace do
		if itemPlace[i].isFrag then
		hang = itemPlace[i].hang
		break
		end
	end

	local h = offsetY + hang*self.itemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.scroll:getInnerContainerSize().height ~= innerSize.height then
	    self.scroll:setInnerContainerSize(innerSize)
    end      

	for i, id in ipairs(self.idList) do
		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local posX = offsetX + (lie - 0.5)* self.itemSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.itemSize.height - (hang - 1)*intervalY

		if not itemPlace[i].isFrag then
			self:addItem(self.cardsInfo[id], cc.p(posX, posY))
		end
	end
end

function UIUnionHeroCard:addItem(info, pos)
	local item = nil
	if #self.itemsCache ~= 0 then
		item = self.itemsCache[1]
		table.remove(self.itemsCache, 1)
		item:setVisible(true)
	else
		item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.itemSize)
		CsbTools.initButton(item, handler(self, self.cardTouchCallBack))
		self.scroll:addChild(item)
		local itemCsb = getResManager():cloneCsbNode(csbFile.cardItem)
		itemCsb:setTag(100100100)
		itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
		item:addChild(itemCsb)
		local callBtn = CsbTools.getChildFromPath(itemCsb, "SumButton")
		local callBtnName = CsbTools.getChildFromPath(callBtn, "NameText")
		callBtn:setTouchEnabled(false)
		callBtnName:setString(CommonHelper.getUIString(271))
	end
	table.insert(self.items, item)

	item:setPosition(pos)
	item:setTag(info.id)
	item:setName(info.id)

	local itemCsb = item:getChildByTag(100100100)
	CsbTools.getChildFromPath(itemCsb, "SumButton"):setTag(info.id)

	self:initCard(itemCsb, info)
end

function UIUnionHeroCard:initCard(itemCsb, info)
	local lvLab = CsbTools.getChildFromPath(itemCsb, "HeroCard/Level")
	local costLab = CsbTools.getChildFromPath(itemCsb, "HeroCard/GemSum")
	local fragCountLab = CsbTools.getChildFromPath(itemCsb, "PieceNum")
	local jobImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/Profesion")
	local jobBgImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/ProfesionBar")
	local raceImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/RaceImage")
	local frameImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/LvImage")
	local iconImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/HeroImage")
	local starCsb = CsbTools.getChildFromPath(itemCsb, "HeroCard/Star")
	local lvImg = CsbTools.getChildFromPath(itemCsb, "HeroCard/LvBar")
	local sourceLab = CsbTools.getChildFromPath(itemCsb, "GetPathTips")

    CsbTools.getChildFromPath(itemCsb, "RedTipPoint"):setVisible(false)
	CsbTools.getChildFromPath(self.raceBtn[info.race], "AllButton/RedTipPoint"):setVisible(false)
    CsbTools.getChildFromPath(self.raceBtn[parts.quanbu], "AllButton/RedTipPoint"):setVisible(false)

	lvLab:setString(info.lv)
	costLab:setString(info.cost)
	CsbTools.replaceSprite(jobImg, IconHelper.getSoldierJobIcon(info.star, info.job))
	CsbTools.replaceSprite(jobBgImg, IconHelper.getSoldierJobIconCircle(info.rare))
	CsbTools.replaceImg(lvImg, IconHelper.getCardLevelBorder(info.rare))
	CsbTools.replaceImg(raceImg, getIconSettingConfItem().RaceIcon[info.race])
	CsbTools.replaceImg(frameImg, IconHelper.getSoldierBigHeadFrame(info.rare))
	CsbTools.replaceImg(iconImg, info.icon)

	if info.source == -2 then
		sourceLab:setString(CommonHelper.getUIString(2174))
	elseif info.source == -1 then
		sourceLab:setString(CommonHelper.getUIString(2175))
	else
		sourceLab:setString(string.format(CommonHelper.getUIString(2173), info.source))
	end

	if info.star == 0 then
		fragCountLab:setString(info.frag .. "/" .. info.callFrag)
		if info.frag >= info.callFrag then
			CommonHelper.playCsbAnimate(itemCsb, csbFile.cardItem, "Full", true, nil, true)
		else
			CommonHelper.playCsbAnimate(itemCsb, csbFile.cardItem, "Null", false, nil, true)
		end
	else
		CommonHelper.playCsbAnimate(itemCsb, csbFile.cardItem, "Normal", false, nil, true)
		CommonHelper.playCsbAnimate(starCsb, starFile, "Star" .. info.star, false, nil, true)
	end	
end

-- 显示排序规则
function UIUnionHeroCard:reShowSortList()
	if self.isShowSortList then
		CommonHelper.playCsbAnimate(self.sortCsb, sortFile, "On", false, nil, true)
	else
		CommonHelper.playCsbAnimate(self.sortCsb, sortFile, "Normal", false, nil, true)
	end
	self.sortBtnLab:setString(CommonHelper.getUIString(sortTypeLan[self.sortType]))
end

function UIUnionHeroCard:cardTouchCallBack(ref)
	local info = self.cardsInfo[ref:getTag()]
	--确认派遣卡牌回调到之前那界面
	print("派遣的英雄ID为"..info.id)
	self.mCaback(info.id, self.mTag)
	UIManager:close()
end

function UIUnionHeroCard:raceBtnCallBack(ref)
	if self.isShowSortList then
		self.isShowSortList = false
		self:reShowSortList()
	end

	local part = ref:getTag()
	if part ~= self.showPart then
		self:changeShowPart(part)
	end
end

-- 切换显示的种族
function UIUnionHeroCard:changeShowPart(showPart)
	self.showPart = showPart
	
	-- 按钮切换
	for name, part in pairs(parts) do
		local raceBtn = self.raceBtn[part]
		local btnCsb = CsbTools.getChildFromPath(raceBtn, "AllButton")
		raceBtn:setLocalZOrder(part==showPart and 10 or -10)
		CommonHelper.playCsbAnimate(btnCsb, btnFile, part==showPart and "On" or "Normal", false, nil, true)
	end

	-- 重新计算显示数据
	self:reSortHerosID()
	-- scroll刷新
	self:reloadScroll()
end

function UIUnionHeroCard:sortBtnCallBack(ref)
	if self.isShowSortList then
		self.isShowSortList = false
	else
		self.isShowSortList = true
	end
	self:reShowSortList()
end

function UIUnionHeroCard:sortTypeBtnCallBack(ref)
	local sortType = ref:getTag()
	self.sortType = sortType	
	self.isShowSortList = false

	self:reShowSortList()
	-- 重新计算显示数据
	self:reSortHerosID()
	-- scroll刷新
	self:reloadScroll()
end


return UIUnionHeroCard