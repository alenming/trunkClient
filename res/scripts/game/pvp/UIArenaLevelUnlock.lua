local gameModel = getGameModel()
local pvpModel = gameModel:getPvpModel()

local UIArenaLevelUnlock = class("UIArenaLevelUnlock", function () 
	return require("common.UIView").new()
end)

local LEVEL_BAR_MARGIN = 5

local LEFT_SIDE_X = 40
local RIGHT_SIDE_X = 460
local BOTTOM_SIDE_Y = 130
local UP_SIDE_Y = 440

function UIArenaLevelUnlock:init()
	self.rootPath = ResConfig.UIArena.Csb2.levelUnlock
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mainPanel = getChild(self.root, "MainPanel")
	self.levelPanel = getChild(self.mainPanel, "LevelPanel")

	self.title = getChild(self.levelPanel, "Name")
	self.levelIcon = getChild(self.levelPanel, "LevelIcon")

	self.heroCards = {}	-- 解锁的英雄卡片
	self.heroCardsController = {}
	for i = 1, 8 do
		self.heroCards[i] = getChild(self.levelPanel, "HeroCard_"..i)

		local controller = require("game.pvp.HeroCardController").new()
		controller:setTarget(self.heroCards[i])
		controller:setClickCallback(handler(self, self.onClickHeroCard))
		self.heroCardsController[i] = controller
	end
	self:initHeroCardsLayout()

	self.worldMap = CsbTools.getChildFromPath(self.levelPanel, "WorldMap/WorldMap/WorldMap") -- 解锁章节地图
	self.chapterName = getChild(self.levelPanel, "TipsText") -- 解锁章节名称
	self.chapterName:setPositionX(self.chapterName:getPositionX() - 8)

	self.levelBarListView = getChild(self.levelPanel, "ScrollView")
	self:initLevelBarListView()

	------------------- Buttons --------------------
	self.closeButton = getChild(self.levelPanel, "CloseButton")
	CsbTools.initButton(self.closeButton, handler(self, self.onClickClose))

	self.leftButton = getChild(self.levelPanel, "LeftButton")
	CsbTools.initButton(self.leftButton, handler(self, self.onLeft))

	self.rightButton = getChild(self.levelPanel, "RightButton")
	CsbTools.initButton(self.rightButton, handler(self, self.onRight))
end

function UIArenaLevelUnlock:initLevelBarListView()
	local listLen = #getArenaRankIndexList()
	local bar = require("game.pvp.UIArenaLevelBar").new()
	local size = bar:getLevelBarSize()
	local w = size.width * listLen + LEVEL_BAR_MARGIN * (listLen + 1)
	local h = self.levelBarListView:getContentSize().height
	self.levelBarListView:setInnerContainerSize(cc.size(w, h))
end

-- 初始化英雄卡片的摆放布局
function UIArenaLevelUnlock:initHeroCardsLayout()
	if not self.heroCardsLayout then
		self.heroCardsLayout = {}
	end

	local frameHeight = UP_SIDE_Y - BOTTOM_SIDE_Y
	local frameWidth = RIGHT_SIDE_X - LEFT_SIDE_X

	for i = 1, 8 do
		local layout = {}
		if i <= 4 then	-- 一行
			local y = BOTTOM_SIDE_Y + frameHeight / 2
			for j = 1, i do
				local x = LEFT_SIDE_X + j * frameWidth / (i + 1)
				layout[j] = cc.p(x, y)
			end
		else			-- 两行
			local y_lower = BOTTOM_SIDE_Y + frameHeight / 3
			local y_upper = BOTTOM_SIDE_Y + 2 * frameHeight / 3

			local mid = math.ceil(i / 2)
			local distance = frameWidth / (mid + 1)
			-- 上面一行
			for j = 1, mid do
				local x = LEFT_SIDE_X + j * distance
				layout[j] = cc.p(x, y_upper)
			end
			-- 下面一行
			local x_begin = LEFT_SIDE_X + (frameWidth - distance * (i - mid - 1)) / 2
			for j = mid + 1, i do
				local x = x_begin + (j - mid - 1) * distance
				layout[j] = cc.p(x, y_lower) 
			end
		end
		self.heroCardsLayout[i] = layout
	end
end

function UIArenaLevelUnlock:onOpen(_, tLevel)
	self:loadLevelBarList()
	self:updateTLevel(tLevel)
end

function UIArenaLevelUnlock:onClickClose()
	UIManager.close()
end

function UIArenaLevelUnlock:onLeft()
	self:lastTLevel()
end

function UIArenaLevelUnlock:onRight()
	self:nextTLevel()
end

function UIArenaLevelUnlock:onClickHeroCard(heroId)
	local list = getSoldierIdListByTLevel(self.tLevel)
	table.sort(list, function (a, b) return a < b end)
	UIManager.open(UIManager.UI.UIHeroInfo, heroId, list)
end

function UIArenaLevelUnlock:lastTLevel()
	if self.tLevel > 1 then
		self:updateTLevel(self.tLevel - 1)
	end
end

function UIArenaLevelUnlock:nextTLevel()
	if self.tLevel < #getArenaRankIndexList() then
		self:updateTLevel(self.tLevel + 1)
	end
end

function UIArenaLevelUnlock:updateTLevel(tLevel)
	self.tLevel = tLevel

	self:updateTitle()
	self:updateWorldMap()
	self:updateHeroes()
	self:updateLevelBarList()
end

function UIArenaLevelUnlock:updateTitle()
	local arenaRankItem = getArenaRankItemByLevel(self.tLevel)
	local levelName = CommonHelper.getUIString(arenaRankItem.GroupNumber - 1 + 806)

	self.title:setString(string.format(CommonHelper.getUIString(1727), levelName))
	self.levelIcon:setSpriteFrame(arenaRankItem.GNPic)
end

function UIArenaLevelUnlock:updateWorldMap()
	self.worldMap:setSpriteFrame(string.format("worldmap_%02d.png", self.tLevel))
	self.chapterName:setString(string.format(CommonHelper.getUIString(2187), self.tLevel))
end

function UIArenaLevelUnlock:updateHeroes()
	local curTLevel = 1
	local arenaRankItem = getArenaRankItem(pvpModel:getPvpInfo().Score)
	if arenaRankItem then
        curTLevel = arenaRankItem.GroupNumber
    end

	local list = getSoldierIdListByTLevel(self.tLevel)
	table.sort(list, function (a, b) return a < b end)

	local num = #list

	local layout = self.heroCardsLayout[num]

	for i = 1, 8 do
		local card = self.heroCards[i]
		if i <= num then
			card:setVisible(true)
			card:setPosition(layout[i])

			local controller = self.heroCardsController[i]
			controller:updateHero(list[i])

			if self.tLevel <= curTLevel then
				controller:setHeroPanelColor(cc.c4b(255, 255, 255, 255))
			else
				controller:setHeroPanelColor(cc.c4b(100, 100, 100, 255))
			end
		else
			card:setVisible(false)
		end
	end
end

function UIArenaLevelUnlock:updateLevelBarList()
	if self.levelBarList then
		local len = #getArenaRankIndexList()
		for j = 1, len do
			if self.tLevel == j then
				self.levelBarList[j]:playRootAnimation("On", false)
			else
				self.levelBarList[j]:playRootAnimation("Off", false)
			end
		end
	end
end

function UIArenaLevelUnlock:loadLevelBarList()
	if not self.levelBarList then
		self.levelBarList = {}
	end

	self.levelBarListView:removeAllChildren()

	local len = #getArenaRankIndexList()
	local y = self.levelBarListView:getContentSize().height / 2
	for i = 1, len do
		local bar = require("game.pvp.UIArenaLevelBar").new()
		local size = bar:getLevelBarSize()
		local x = (i - 0.5) * (size.width + LEVEL_BAR_MARGIN)
		bar:setPosition(x, y)
		bar:updateLevel(i)
		bar:setClickCallback(function (level) 
			self:updateTLevel(level)
		end)
		self.levelBarListView:addChild(bar)
		self.levelBarList[i] = bar
	end
end

return UIArenaLevelUnlock