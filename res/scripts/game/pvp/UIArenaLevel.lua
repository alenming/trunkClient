local UIArenaLevel = class("UIArenaLevel", function ()
	return require("common.UIView").new()
end)

local LEFT_SIDE_X = 234
local RIGHT_SIDE_X = 727
local BOTTOM_SIDE_Y = 71
local UP_SIDE_Y = 400

function UIArenaLevel:init()
	self.rootPath = ResConfig.UIArena.Csb2.level
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mainScrollView = getChild(self.root, "MainScrollView")

	self.mainPanel = getChild(self.mainScrollView, "MainPanel")

	-- 段位图标1和2. PS：为什么要放两个呢？
	self.tLevelIcon1 = CsbTools.getChildFromPath(self.mainPanel, "HighPanel/TLevelIcon_New_1")
	self.tLevelIcon2 = CsbTools.getChildFromPath(self.mainPanel, "HighPanel/TLevelIcon_New_2")
	self.tLevelIconOld = CsbTools.getChildFromPath(self.mainPanel, "LowPanel/TLevelIcon_Old")

	-- 段位名称
	self.tLevelNameNew = CsbTools.getChildFromPath(self.mainPanel, "HighPanel/TLevel_New")
	self.tLevelNameOld = CsbTools.getChildFromPath(self.mainPanel, "LowPanel/TLevel_Old")

	-- 解锁的章节名称
	self.chapterName = CsbTools.getChildFromPath(self.mainPanel, "UnlockPanel/Tips1")

	self.heroCards = {}	-- 解锁的英雄卡片
	self.heroCardsController = {}
	for i = 1, 8 do
		self.heroCards[i] = CsbTools.getChildFromPath(self.mainPanel, "UnlockPanel/HeroCard_"..i)

		local controller = require("game.pvp.HeroCardController").new()
		controller:setTarget(self.heroCards[i])
		self.heroCardsController[i] = controller
	end
	self:initHeroCardsLayout()

	-- 确认按钮
	self.confirmButton = CsbTools.getChildFromPath(self.root, "ButtonPanel/ConfirmButtom")
	CsbTools.initButton(self.confirmButton, handler(self, self.onClickConfirm))

	-- 升级提示文字
	self.upLevelTips = CsbTools.getChildFromPath(self.mainPanel, "HighPanel/FontLabel")

	-- 降级提示文字
	self.downLevelTips = CsbTools.getChildFromPath(self.mainPanel, "Tips4")
end

-- 初始化英雄卡片的摆放布局
function UIArenaLevel:initHeroCardsLayout()
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

-- isUpLevel: 是升级吗？
-- curLevel: 当前T级
function UIArenaLevel:onOpen(_, isUpLevel, curLevel)
	self.isUpLevel = isUpLevel
	self.tLevel = curLevel

	if isUpLevel then
		CommonHelper.playCsbAnimate(self, self.rootPath, "UpLv", false)
	else
		CommonHelper.playCsbAnimate(self, self.rootPath, "DownLv", false)
	end

	self:updateAll()
end

function UIArenaLevel:onClose()
	if self.isUpLevel then
		CommonHelper.playCsbAnimate(self, self.rootPath, "UpClose", false)
	else
		CommonHelper.playCsbAnimate(self, self.rootPath, "DownClose", false)
	end
end

-- 点击确定按钮的回调
function UIArenaLevel:onClickConfirm()
	UIManager.close()
end

function UIArenaLevel:updateAll()
	self:updateTLevelIcon()
	self:updateTLevelName()
	self:updateChapterName()
	self:updateHeroCards()
	self:updateUpLevelTips()
	self:updateDownLevelTips()
end

-- 刷新段位图标
function UIArenaLevel:updateTLevelIcon()
	local arenaRankItem = getArenaRankItemByLevel(self.tLevel)

	self.tLevelIcon1:setSpriteFrame(arenaRankItem.GNPic)
	self.tLevelIcon2:setSpriteFrame(arenaRankItem.GNPic)

	local oldLevel = self.isUpLevel and self.tLevel - 1 or self.tLevel + 1

	local arenaRankItemOld = getArenaRankItemByLevel(oldLevel)
	if arenaRankItemOld then
		self.tLevelIconOld:setSpriteFrame(arenaRankItemOld.GNPic)
	else
		self.tLevelIconOld:setSpriteFrame(arenaRankItem.GNPic)
	end
end

-- 刷新段位名称
function UIArenaLevel:updateTLevelName()
	self.tLevelNameNew:setString(CommonHelper.getUIString(self.tLevel - 1 + 806))

	local oldLevel = self.isUpLevel and self.tLevel - 1 or self.tLevel + 1
	if oldLevel >= 1 and oldLevel <= #getArenaRankIndexList() then
		self.tLevelNameOld:setString(CommonHelper.getUIString(oldLevel - 1 + 806))
	else
		self.tLevelNameOld:setString(CommonHelper.getUIString(self.tLevel - 1 + 806))
	end
end

-- 刷新解锁章节的名称
function UIArenaLevel:updateChapterName()
	if self.isUpLevel then 
		local conf = getChapterConfItem(self.tLevel)
		self.chapterName:setString(getStageLanConfItem(conf.Name))
	end
end

-- 刷新英雄卡片
function UIArenaLevel:updateHeroCards()
	if self.isUpLevel then
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
			else
				card:setVisible(false)
			end
		end
	end
end

-- 刷新升级提示
function UIArenaLevel:updateUpLevelTips()
	if self.isUpLevel then
		self.upLevelTips:setString(CommonHelper.getUIString(1728))
	end
end

-- 刷新降级提示
function UIArenaLevel:updateDownLevelTips()
	if not self.isUpLevel then
		self.downLevelTips:setString(CommonHelper.getUIString(1729))
	end
end

return UIArenaLevel