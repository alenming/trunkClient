------------------------------
-- 名称：UIMapLock
-- 描述：世界地图界面的未解锁扇区
-- 日期：2017/2/27
-- 作者：尚志
------------------------------

local UIMapLock = class("UIMapLock", function () 
	return require("common.UIView").new()
end)

function UIMapLock:ctor()
	self.rootPath = ResConfig.UIMap.Csb2.lock
	self.root = getResManager():getCsbNode(self.rootPath)
	self.root:setContentSize(display.width, display.height)
	ccui.Helper:doLayout(self.root)

	self:addChild(self.root)

	self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
	self.chestButton = CsbTools.getChildFromPath(self.mainPanel, "ChestButton")
end

function UIMapLock:setChestButtonVisible(visible)
	self.chestButton:setVisible(visible)
end

return UIMapLock