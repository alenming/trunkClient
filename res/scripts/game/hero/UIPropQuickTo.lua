--[[
	快速前往界面，主要实现以下内容
	1. 显示快速前往关卡界面
	2. 点击关卡进入关卡
--]]
local UIPropQuickTo = class("UIPropQuickTo", function ()
	return require("common.UIView").new()
end)

local UIQuickToHelper = require("game.hero.UIQuickToHelper")

local resCsb = ResConfig.UIPropQuickTo.Csb2
local backBtnFile = "ui_new/g_gamehall/c_collection/GeneralButton.csb"

function UIPropQuickTo:ctor()
	self.rootPath = resCsb.meterial
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.scroll = CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/PathScrollView")

	-- 文本: 获取途径
	CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/Text_11"):setString(CommonHelper.getUIString(156))

	-- 返回按钮
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MaiPanelPanel/PathPanel/BackButton")
        , function () UIManager.close() end
        , CommonHelper.getUIString(529)
        , "GeneralButton/ButtomImage/NameLabel", "GeneralButton")

    -- 道具csb
    self.propCsb = CsbTools.getChildFromPath(self.root, "MaiPanelPanel/IntroPanel/PropItem")
end

function UIPropQuickTo:onOpen(preUIID, id)
	self.id = id

	local propConf = getPropConfItem(self.id)
	if not propConf then
		print("propConf is nil", self.id)
		return 
	end

	-- 初始化道具信息
	self:initPropInfo(propConf)
	-- 设置scroll
	self:reloadScroll(propConf.QuickToStage)
end

function UIPropQuickTo:onClose()
	if self.star then
		return self.id
	end
end

function UIPropQuickTo:onTop(preUIID)
	local propConf = getPropConfItem(self.id)
	if not propConf then
		print("propConf is nil", self.id)
		return 
	end

	-- 初始化英雄信息
	self:initPropInfo(propConf)
	-- 设置scroll
	self:reloadScroll(propConf.QuickToStage)
end

function UIPropQuickTo:initPropInfo(propConf)
	UIAwardHelper.setPropItemOfConf(self.propCsb, propConf, 0)

	local introPanel = CsbTools.getChildFromPath(self.root, "MaiPanelPanel/IntroPanel")
	local nameLab = CsbTools.getChildFromPath(introPanel, "HeroNameLabel")
	local countLab = CsbTools.getChildFromPath(introPanel, "BitmapFontLabel_2")
	local descLab = CsbTools.getChildFromPath(introPanel, "IntroLabel")

	local itemCount = 0
	local nameStr = "unKnow"
	local descStr = "unKonw"
	if propConf.Type == UIAwardHelper.ItemType.HeroCard or
		propConf.Type == UIAwardHelper.ItemType.Frag then
		local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(propConf.TypeParam[1])
		itemCount = heroModel and heroModel:getFrag() or 0
		nameStr = CommonHelper.getHSString(propConf.Name)
		descStr = CommonHelper.getHSString(propConf.Desc)

	elseif propConf.Type == UIAwardHelper.ItemType.SummonerCard then
		itemCount = getGameModel():getSummonersModel():hasSummoner() and 1 or 0
		nameStr = CommonHelper.getHSString(propConf.Name)
		descStr = CommonHelper.getHSString(propConf.Desc)

	elseif propConf.Type == UIAwardHelper.ItemType.Equip then
		nameStr = CommonHelper.getPropString(propConf.Name)
		descStr = CommonHelper.getPropString(propConf.Desc)
		itemCount = 0

		local eqs = getGameModel():getEquipModel():getEquips()
		for _, eqInfo in pairs(eqs) do
			if eqInfo.confId == propConf.ID then
				itemCount = itemCount + 1
			end
		end

	else
		itemCount = getGameModel():getBagModel():getItems()[propConf.ID] or 0
		nameStr = CommonHelper.getPropString(propConf.Name)
		descStr = CommonHelper.getPropString(propConf.Desc)

	end

    nameLab:setString(nameStr)
    countLab:setString(string.format(CommonHelper.getUIString(61), itemCount))
    descLab:setString(descStr)

    local color = getItemLevelSettingItem(propConf.Quality).Color
    nameLab:setTextColor(cc.c3b(color[1], color[2], color[3]))
end

function UIPropQuickTo:reloadScroll(quickToData)
	UIQuickToHelper:reloadScroll(self.scroll, quickToData)
end

return UIPropQuickTo