--[[
	英雄快速前往界面，主要实现以下内容
	1. 显示快速前往关卡界面
	2. 点击关卡进入关卡或提示不能进入
--]]

local UIHeroQuickTo = class("UIHeroQuickTo", function()
	return require("common.UIView").new()
end)

local UIQuickToHelper = require("game.hero.UIQuickToHelper")

local resCsb = ResConfig.UIHeroQuickTo.Csb2
local backBtnFile = "ui_new/g_gamehall/c_collection/GeneralButton.csb"

local jobLanID = {521, 524, 522, 523, 525, 520}
local raceLanID = {514, 582, 517, 583}

function UIHeroQuickTo:ctor()
	self.rootPath = resCsb.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.scroll = CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/PathScrollView")

	-- 文本: 获取途径
	CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/Text_11")
		:setString(CommonHelper.getUIString(156))

	-- 返回按钮
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/BackButton")
        , function () UIManager.close() end
        , CommonHelper.getUIString(529)
        , "GeneralButton/ButtomImage/NameLabel", "GeneralButton")
end

function UIHeroQuickTo:onOpen(preUIID, id)
	self.id = id

	-- 获取快速前往信息
	local upRateConf = getSoldierUpRateConfItem(self.id)
	if not upRateConf then
		print("upRateConf is nil", self.id)
		return
	end

	-- 设置scroll
	self:reloadScroll(upRateConf.QuickToStage)
end

function UIHeroQuickTo:onTop()
	-- 获取快速前往信息
	local upRateConf = getSoldierUpRateConfItem(self.id)
	if not upRateConf then
		print("upRateConf is nil", self.id)
		return
	end

	-- 设置scroll
	self:reloadScroll(upRateConf.QuickToStage)
end

function UIHeroQuickTo:onClose()
	return self.id
end

function UIHeroQuickTo:reloadScroll(quickToData)
	UIQuickToHelper:reloadScroll(self.scroll, quickToData)
end

return UIHeroQuickTo