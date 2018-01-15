--[[
	卡包界面，主要实现以下内容
	1. 指定种族的英雄
	2. 按照指定排序规则顺序显示
	3. 召唤英雄
	4. 跳转到英雄详细信息界面
--]]
local UIHeroCardBag 	= class("UIHeroInfo", require("common.UIView"))

require("common.TeamHelper")
local ScrollViewExtend 	= require("common.ScrollViewExtend").new()

local csbFile 			= ResConfig.UIHeroCardBag.Csb2
local btnFile 			= "ui_new/g_gamehall/b_bag/AllButton.csb"
local sortFile 			= "ui_new/g_gamehall/c_card/DownListButton.csb"
local jobFile 			= "ui_new/g_gamehall/c_card/card_profesion.csb"
local starFile 			= "ui_new/g_gamehall/c_card/HeroStar_S.csb"

local parts 	= {quanbu = 0, ren = 1, ziran = 2, siling = 3, qita = 4}
local sortType	= {lvMax = 1, starMax = 2, costMin = 3 }
local sortTypeLan = {584, 585, 586}

function UIHeroCardBag:ctor()
	self.rootPath 	= csbFile.cardBag
	self.root 		= getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 因为卡片数量固定, 所以缓存起卡片
	self.items = {}
	self.itemsCache = {}

	-- 返回按钮
	self.backBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(self.backBtn, function (obj)
		UIManager.close()
	end)

	-- 召唤用的卡片
	self.callPanel = CsbTools.getChildFromPath(self.root, "SummonPanel")

	-- 标题:英雄卡包
	local titleLab = CsbTools.getChildFromPath(self.root, "MainPanel/Image_Tittle/TittleFontLabel")
	titleLab:setString(CommonHelper.getUIString(591))

	-- 手动产生bug, 测试bug是否会上传, 点击30次
	self.titleTouchCount = 0
	titleLab:setTouchEnabled(true)
	titleLab:addClickEventListener(function()
		self.titleTouchCount = self.titleTouchCount + 1
		if self.titleTouchCount == 30 then
			testBuglyUpload:testBuglyUpload()
		end
	end)

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
    itemCsb:cleanup()

	-- 添加线条到scroll
	self.lineCsb = getResManager():cloneCsbNode(csbFile.line)
	self.lineSize = CsbTools.getChildFromPath(self.lineCsb, "LinePanel"):getContentSize()
	self.scroll:addChild(self.lineCsb)

    -- 屏蔽层
    self.MaskPanel = CsbTools.getChildFromPath(self.root, "MaskPanel")
    self.MaskPanel:addTouchEventListener(handler(self, self.onMaskPanelTouch))
end

function UIHeroCardBag:onOpen()
	self.titleTouchCount = 0
	self.callPanel:setVisible(false)

	-- 监听召唤
    local callCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.GenSC)
    self.callHanlder = handler(self, self.onCallHero)
    NetHelper.setResponeHandler(callCmd, self.callHanlder)

	self.showPart 		= parts.quanbu	-- 显示部位
	self.sortType		= sortType.lvMax-- 排序方式
	self.isShowSortList	= false			-- 显示排序
	self.cardsInfo 		= {}			-- 卡片信息
	self.idList 		= {}			-- 卡片列表顺序
    self.heroRedPoint   = RedPointHelper.getRedPointHeros() -- 红点英雄

	self:reShowSortList()
	self:reGetHerosInfo()
	self:changeShowPart(parts.quanbu)
    self:showRedPoint()
end

function UIHeroCardBag:onClose()
	self:cacheItems()

	local upgradeStarCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.GenSC)
    NetHelper.removeResponeHandler(upgradeStarCmd, self.callHanlder)  
end

function UIHeroCardBag:onTop(preUIID, heroID)
    self.heroRedPoint = RedPointHelper.getRedPointHeros()
	self:reGetHerosInfo()
	self:reSortHerosID()
	self:reloadScroll()
    self:showRedPoint()

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

function UIHeroCardBag:cacheItems()
	for _, item in pairs(self.items) do
		item:setVisible(false)
		table.insert(self.itemsCache, item)
	end
	self.items = {}
end

-- 重新获取英雄数据
function UIHeroCardBag:reGetHerosInfo()
	self.cardsInfo 	= {}

	-- 获取所有卡片
	local soldierList = getSoldierUpRateItemList()
	for _,id in pairs(soldierList) do
		if id ~= 0 then
			self:reGetHeroInfo(id)
		end
	end
end

--[[
self.cardsInfo[id] = {
	id,
	defaultStar,
	topStar,
	icon,
	cost,
	race,
	job,
	frag,
	callFrag,
	lv,
	star,
	rare,
}
]]
function UIHeroCardBag:reGetHeroInfo(id)
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(id)
	local upRateConf = getSoldierUpRateConfItem(id)
	if upRateConf == nil then
		print("error, upRateConf is nil", id)
	end

	local star = upRateConf.DefaultStar
	local heroConf = getSoldierConfItem(id, star)
	if heroConf == nil then
		print("error !!! heroConf", id, star)
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
function UIHeroCardBag:reSortHerosID()
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
			if info1.cost < info2.cost then
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
	if self.showPart == parts.qita then
		-- 策划要求强行将队伍插到其他里面
		_, self.idList = TeamHelper.getTeamInfo()

		self.cardNumValueLab:setString(#self.idList .. "/7")
		
	else
		local cardCount = 0
		for id, info in pairs(self.cardsInfo) do
			if self.showPart == info.race or self.showPart == parts.quanbu then
				table.insert(self.idList, id)
				if info.star ~= 0 then
					cardCount = cardCount + 1
				end
			end
		end

		self.cardNumValueLab:setString(cardCount .. "/" .. #self.idList)
	end

	-- 排序
	table.sort(self.idList, func[self.sortType])
end

-- 重新显示卡包里面的卡片
function UIHeroCardBag:reloadScroll()
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
	local hang = itemPlace[#itemPlace].hang

	local h = offsetY + hang*self.itemSize.height + (hang + 2)*intervalY + self.lineSize.height
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.scroll:getInnerContainerSize().height ~= innerSize.height then
	    self.scroll:setInnerContainerSize(innerSize)
    end    

    self.lineCsb:setVisible(false)
    local preIsFrag = false
	for i, id in ipairs(self.idList) do
		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local lieHeight = itemPlace[i].isFrag and self.lineSize.height + 2*intervalY or 0
		local posX = offsetX + (lie - 0.5)* self.itemSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.itemSize.height - (hang - 1)*intervalY - lieHeight

		if preIsFrag == false and itemPlace[i].isFrag then
			preIsFrag = true
			self.lineCsb:setVisible(true)
			self.lineCsb:setPosition(self.scroll:getContentSize().width/2, 
				posY + 0.5*self.itemSize.height + intervalY + self.lineSize.height/2)
		end
		self:addItem(self.cardsInfo[id], cc.p(posX, posY))
	end
end

function UIHeroCardBag:addItem(info, pos)
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

--[[
info = {id,	race, lv, star, cost, defaultStar, job, icon, frag, callFrag, rare}
]]
function UIHeroCardBag:initCard(itemCsb, info)
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
    CsbTools.getChildFromPath(itemCsb, "RedTipPoint"):setVisible(self.heroRedPoint[info.id] and true or false)

	lvLab:setString(info.lv)
	costLab:setString(info.cost)
	CsbTools.replaceSprite(jobImg, IconHelper.getSoldierJobIcon(info.rare, info.job))
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
function UIHeroCardBag:reShowSortList()
	if self.isShowSortList then
		CommonHelper.playCsbAnimate(self.sortCsb, sortFile, "On", false, nil, true)
	else
		CommonHelper.playCsbAnimate(self.sortCsb, sortFile, "Normal", false, nil, true)
	end
	self.sortBtnLab:setString(CommonHelper.getUIString(sortTypeLan[self.sortType]))
end

function UIHeroCardBag:cardTouchCallBack(ref)
	local info = self.cardsInfo[ref:getTag()]
	if info.star ~= 0 then
		-- 已经召唤出, 跳转到英雄详细界面
		UIManager.open(UIManager.UI.UIHeroInfo, info.id, self.idList)
	else
		if info.frag < info.callFrag then
			-- 不足以召唤, 跳转到英雄详细界面
			UIManager.open(UIManager.UI.UIHeroInfo, info.id, self.idList)
		else
			-- 可以召唤, 开始召唤神龙
			local buffData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.GenCS)
		    buffData:writeInt(ref:getTag())
		    NetHelper.request(buffData)
		end
	end
end

function UIHeroCardBag:raceBtnCallBack(ref)
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
function UIHeroCardBag:changeShowPart(showPart)
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

function UIHeroCardBag:sortBtnCallBack(ref)
	if self.isShowSortList then
		self.isShowSortList = false
	else
		self.isShowSortList = true
	end
	self:reShowSortList()
end

function UIHeroCardBag:sortTypeBtnCallBack(ref)
	local sortType = ref:getTag()
	self.sortType = sortType	
	self.isShowSortList = false

	self:reShowSortList()
	-- 重新计算显示数据
	self:reSortHerosID()
	-- scroll刷新
	self:reloadScroll()
end

function UIHeroCardBag:onCallHero(mainCmd, subCmd, data)
	local heroID = data:readInt()
	local heroFrag = data:readUShort()
	local heroLv = data:readUChar()
	local heroStar = data:readUChar()
	local heroExp = data:readInt()
	local heroTalent = {}
	for i=1, 8 do
		heroTalent[i] = data:readUChar()
	end
	local equips = {}
	for i=1, 6 do
		equips[i] = data:readInt()
	end

	ModelHelper.AddHero(heroID, heroLv, heroStar)
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
	local heroModel = heroCardBagModel:getHeroCard(heroID)
	if not heroModel then 
		print("heroModel is nil", heroID) 
		return 
	end
	heroModel:setFrag(heroFrag)
	heroModel:setExp(heroExp)
	heroModel:setTalent(heroTalent)
	for i=1, 6 do
		heroModel:setEquip(i, equips[i])
	end

	local item = self.scroll:getChildByTag(heroID)
	if item then
		item:setVisible(false)
		self:reGetHeroInfo(heroID)	
		local itemCsb = item:getChildByTag(100100100)
		local pos = itemCsb:convertToWorldSpace(cc.p(0,0))

		self.callPanel:setVisible(true)
		local itemCsb = CsbTools.getChildFromPath(self.callPanel, "HeroCard")
		self:initCard(itemCsb, self.cardsInfo[heroID])
		CsbTools.getChildFromPath(itemCsb, "RedTipPoint"):setVisible(false)
		itemCsb:setPosition(pos)
		itemCsb:runAction(cc.MoveTo:create(0.3, cc.p(display.cx, display.cy)))

        MusicManager.playSoundEffect(MusicManager.commonSound.callHero)
		CommonHelper.playCsbAnimate(itemCsb, csbFile.cardItem, "Summon", false, function()
			self.callPanel:setVisible(false)
			UIManager.open(UIManager.UI.UIHeroInfo, heroID, self.idList)
		end, true)		
	end
    print("77")
end

function UIHeroCardBag:onMaskPanelTouch(obj, eventType)
    if 0 == eventType then -- 触摸开始
        self.MaskPanel:setVisible(false)
        local node = CsbTools.getChildFromPath(self.root, "HeroEnergry")
        CommonHelper.playCsbAnimation(node, "Off", false, nil)
    end
end

function UIHeroCardBag:showRedPoint()
    for _, raceBtn in pairs(self.raceBtn) do
        CsbTools.getChildFromPath(raceBtn, "AllButton/RedTipPoint"):setVisible(false)
    end

    for id, v in pairs(self.heroRedPoint) do
        local info = self.cardsInfo[id]
        if info and v then
            CsbTools.getChildFromPath(self.raceBtn[info.race], "AllButton/RedTipPoint"):setVisible(v)
            CsbTools.getChildFromPath(self.raceBtn[parts.quanbu], "AllButton/RedTipPoint"):setVisible(v)
        end
    end
end

return UIHeroCardBag