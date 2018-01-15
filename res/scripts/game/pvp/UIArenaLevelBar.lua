local UIArenaLevelBar = class("UIArenaLevelBar", function () 
	return require("common.UIView").new()
end)

function UIArenaLevelBar:ctor()
	self.rootPath = ResConfig.UIArena.Csb2.levelBar
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.levelBar = getChild(self.root, "LevelBar")
	self.levelBar:setTouchEnabled(true)
	self.levelBar:setSwallowTouches(false)
	self.levelBar:addClickEventListener(handler(self, self.onClick))

	self.levelIcon = getChild(self.levelBar, "LevelIcon")
	self.levelName = getChild(self.levelIcon, "Level")

	self.score = getChild(self.levelBar, "Num")
end

function UIArenaLevelBar:onClick()
	if self.clickCallback then
		self.clickCallback(self.level)
	end
end

function UIArenaLevelBar:setClickCallback(callback)
	self.clickCallback = callback
end

function UIArenaLevelBar:getLevelBarSize()
	if self.levelBar then
		return self.levelBar:getContentSize()
	end
end

function UIArenaLevelBar:updateLevel(level)
	self.level = level

	local arenaRankItem = getArenaRankItemByLevel(level)
	self.levelIcon:setSpriteFrame(arenaRankItem.GNPic)
	self.levelName:setString(CommonHelper.getUIString(arenaRankItem.GroupNumber - 1 + 806) or "")
	self.score:setString(string.format(CommonHelper.getUIString(2186), arenaRankItem.GNRank[1]))
end

function UIArenaLevelBar:playRootAnimation(name, loop)
	CommonHelper.playCsbAnimate(self.root, self.rootPath, name, loop)
end

return UIArenaLevelBar