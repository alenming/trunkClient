--[[
	装备背包界面，主要实现以下内容
	1. 显示装备, 替换装备, 穿戴装备
--]]

local EquipBag = class("EquipBag", require("common.UIView"))

local ScrollViewExtend 	= require("common.ScrollViewExtend").new()
local UIEquipViewHelper = require("game.hero.UIEquipViewHelper")
local UIEquipInfo 	= require("game.hero.UIEquipInfo")

local csbFile 		= ResConfig.UIEquipBag.Csb2
local btnFile 		= "ui_new/g_gamehall/b_bag/AllButton.csb"

function EquipBag:ctor()
	self.rootPath 	= csbFile.eqBag
	self.root 		= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn 	= CsbTools.getChildFromPath(self.root, "CloseButton")
	CsbTools.initButton(backBtn, function ()
		UIManager.close()
	end)

	-- 屏蔽层
	self.mask 		= CsbTools.getChildFromPath(self.root, "MainPanel/MaskPanel")
	self.mask:addClickEventListener(handler(self, self.maskCallBack))

	-- 装备信息界面
	local eqInfoCsb = CsbTools.getChildFromPath(self.root, "MainPanel/EquipInfo")
	self.UIEquipInfo = UIEquipInfo.new(eqInfoCsb)

	-- 装备显示界面
	self.titleLab 	= CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/TitleTips")
	self.noEqTipLab1= CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TipsText_L")
	self.noEqTipLab2= CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/TipsText_R")
	self.noEqTipLab1:setString(CommonHelper.getUIString(631))
	self.noEqTipLab2:setString(CommonHelper.getUIString(632))

	-- 右侧选择装备部位按钮
	local btnslan = {612, 613, 614, 615, 616, 617}
	for i=1, 6 do
		self["partBtn_" .. i] = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/TabButton_" .. i)
		self["partBtn_" .. i]:setTag(i)
        CsbTools.getChildFromPath(self["partBtn_" .. i], "AllButton/RedTipPoint"):setVisible(false)
		CsbTools.initButton(self["partBtn_" .. i], handler(self, self.partBtnCallBack), 
			CommonHelper.getUIString(btnslan[i]), "AllButton/ButtonPanel/NameLabel", "AllButton")
	end
	-- 铸造
	self.partBtn_7 = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/TabButton_7")
	CsbTools.initButton(self.partBtn_7, handler(self, self.part7BtnCallBack),  "partBtn_7")
	local part7Text = CsbTools.getChildFromPath(self.partBtn_7, "ButtonText")
	part7Text:setString(CommonHelper.getUIString(637))

end

function EquipBag:onOpen(openerUIID, heroID, eqPart, uiCallFunc)
	self.heroID			= heroID	-- 英雄动态ID
	self.showPart 		= eqPart	-- 显示部位
	self.uiCallFunc		= uiCallFunc-- 穿装,卸装界面回调
	self.eqsInfo 		= {}		-- 卡片信息
	self.idList 		= {}		-- 卡片列表顺序
	self.heroEqsInfo 	= {}		-- 英雄升上装备信息
	
	self.mask:setTouchEnabled(false)

	-- 算出等级,职业
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroID)
	if heroModel == nil then return end
	local heroConf 	= getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	self.heroLv		= heroModel:getLevel()
	self.heroJob	= heroConf.Common.Vocation

	self:reGetHeroEqsInfo()
	self:reGetEqsInfo()
	self:reSortEqsID()

	-- 构造动态创建信息
	self:initDyScroll()
	-- 默认显示全部
	self:changeShowPart(eqPart)
end

function EquipBag:onClose()
	self.scroll:removeAllChildren()
	self.mask:setTouchEnabled(false)
end

function EquipBag:reGetHeroEqsInfo()
	self.heroEqsInfo = {}
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
	local eqsDyID = heroModel:getEquips()
	for _, eqDyID in pairs(eqsDyID) do
		local eqConfID = getGameModel():getEquipModel():getEquipConfId(eqDyID)
		if eqConfID ~= nil and eqConfID ~= 0 then
			local eqConf = getEquipmentConfItem(eqConfID)
			if eqConf ~= nil then
				self.heroEqsInfo[eqConf.Parts] = eqDyID
			end
		end
	end
end

function EquipBag:reGetEqsInfo()
	self.eqsInfo 	= {}
	local bagItems 	= getGameModel():getBagModel():getItems()
	for k, _ in pairs(bagItems) do
		-- 筛选出装备
		if k > 1000000 then
			local eqConfID 	= getGameModel():getEquipModel():getEquipConfId(k)
			if eqConfID ~= nil and eqConfID ~= 0 then
				local eqConf 	= getEquipmentConfItem(eqConfID)
				local propConf 	= getPropConfItem(eqConfID)
				if eqConf ~= nil and propConf ~= nil then
					self.eqsInfo[k] = eqConfID
				else
					print("fuck of equip", eqConfID)
				end
			end
		end
	end
end

function EquipBag:reSortEqsID()
	self.idList = {}
	for dyID, confID in pairs(self.eqsInfo) do
		local eqConf = getEquipmentConfItem(confID)
		if self.showPart == eqConf.Parts and self.heroLv >= eqConf.Level then
			-- 判断职业
			local jobPass = false
			for _, job in ipairs(eqConf.Vocation) do
				if job == self.heroJob then
					jobPass = true
					break
				end
			end
			if jobPass then
				table.insert(self.idList, dyID)
			end
		end
	end

	local function sortEqs(dyID1, dyID2)
		local confID1 = self.eqsInfo[dyID1]
		local confID2 = self.eqsInfo[dyID2]
		local eqConf1 = getEquipmentConfItem(confID1)
		local eqConf2 = getEquipmentConfItem(confID2)
		if eqConf1.Rank > eqConf2.Rank then
			return true
		elseif eqConf1.Rank == eqConf2.Rank then
			if eqConf1.Level > eqConf2.Level then
				return true
			elseif eqConf1.Level == eqConf2.Level then
				local propConf1 = getPropConfItem(confID1)
				local propConf2 = getPropConfItem(confID2)
				if propConf1.Quality > propConf2.Quality then
					return true
				elseif propConf1.Quality == propConf2.Quality then
					if dyID1 > dyID2 then
						return true
					end
				end
			end
		end
		return false
	end
	-- 排序
	table.sort(self.idList, sortEqs)
end

function EquipBag:initDyScroll()
	if #self.idList == 0 then
		self.noEqTipLab2:setVisible(true)
	else
		self.noEqTipLab2:setVisible(false)
	end

	self.scroll 	= CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/EqScrollView")
	local itemCsb 	= getResManager():getCsbNode(csbFile.item)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "EqItemPanel"):getContentSize()
    itemCsb:cleanup()

	self.scroll:removeAllChildren()
	self.itemSize.width = self.itemSize.width + 5

	local tabParam ={
		rowCellCount		= 4,								-- 每行节点个数
		defaultCount		= #self.idList,						-- 初始节点个数
		maxCellCount		= #self.idList,						-- 最大节点个数
		csbName				= csbFile.item,						-- 节点csb名称
		cellName			= "EqItemPanel",					-- 节点触摸区域
		--csbUnlock			= "UnLock",							-- 解锁动画
		cellSize			= self.itemSize,					-- cell大小
		uiScrollView		= self.scroll,						-- scroll
		distanceX			= 2,								-- 节点X轴间距
		distanceY			= 3,								-- 节点Y轴间距
		offsetX				= 5,								-- 第一列的偏移
		offsetY				= 5,								-- 第一行的偏移
		setCellDataCallback	= handler(self, self.setItemInfo),	-- 设置节点数据回调函数
	}
	ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
end

function EquipBag:resetEqInfoCsb()
	local infoCsb = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/EquipInfo")
	if self.heroID ~= nil and self.heroEqsInfo[self.showPart] ~= nil then
		self.noEqTipLab1:setVisible(false)
		infoCsb:setVisible(true)
		UIEquipViewHelper:setCsbInfo(infoCsb, self.heroID, self.heroEqsInfo[self.showPart], 370)
	else
		self.noEqTipLab1:setVisible(true)
		infoCsb:setVisible(false)
	end
end

function EquipBag:setItemInfo(itemCsb, i)
	--local itemCsb 		= self.scroll:getChildByTag(i)
	local itemPanel 	= CsbTools.getChildFromPath(itemCsb, "EqItemPanel")
	local moveDist  	= 0
	local starInnerPos  = cc.p(0, 0)

	-- 添加点击监听
	itemPanel:setTouchEnabled(true)
	itemPanel:setSwallowTouches(false)
	itemPanel:addTouchEventListener(function(obj, event)
		if event == 0 then
			self.canClick = true
			starInnerPos = self.scroll:getInnerContainerPosition()
		elseif event == 1 then
			local innerPos = self.scroll:getInnerContainerPosition()
			if cc.pGetDistance(starInnerPos, innerPos) > 5 then
				self.canClick = false
			end
		elseif event == 2 then
			if self.canClick then
				self:equipClickCallBack(itemCsb, i)
			end
		end
	end)

	-- 初始化节点
	self:initCardCsb(itemCsb, i)
end

function EquipBag:initCardCsb(itemCsb, i)
	local layout = CsbTools.getChildFromPath(itemCsb, "EqItemPanel")
	if i <= #self.idList then
		-- 有装备的格子
		local eqDyID 	= self.idList[i]
		local confID 	= self.eqsInfo[eqDyID]
		local eqConf 	= getEquipmentConfItem(confID)
		local propConf 	= getPropConfItem(confID)

		local eqImg 	= CsbTools.getChildFromPath(layout, "EqImage")
		local bgEqImg 	= CsbTools.getChildFromPath(layout, "EqBgImage")
		local frameImg 	= CsbTools.getChildFromPath(layout, "BgImage")
		CsbTools.replaceImg(eqImg, propConf.Icon)
		CsbTools.replaceSprite(bgEqImg, getIconSettingConfItem().EqIcon[eqConf.Parts])
		CsbTools.replaceImg(frameImg, getItemLevelSettingItem(propConf.Quality).ItemFrame)
	else
		itemCsb:setVisible(false)
	end	
end

function EquipBag:equipClickCallBack(itemCsb, i)	
	self.mask:setTouchEnabled(true)
	if self.heroID ~= nil and self.heroEqsInfo[self.showPart] ~= nil then
		self.UIEquipInfo:setUIInfo(self.heroID, self.idList[i], 3, handler(self, self.uiEqBagCallFunc))
	else
		self.UIEquipInfo:setUIInfo(self.heroID, self.idList[i], 2, handler(self, self.uiEqBagCallFunc))
	end
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipInfoOpen", false, function()
    	-- 新手引导需要
    	EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIEquipBag)
    end, true)
end

function EquipBag:uiEqBagCallFunc(args)	
	self.mask:setTouchEnabled(false)
	self.uiCallFunc(args)
	UIManager.close()
end

function EquipBag:maskCallBack(ref)	
	self.mask:setTouchEnabled(false)    
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipInfoClose", false, nil, true)
end

function EquipBag:partBtnCallBack(ref)	
	local part = ref:getTag()
	if part ~= self.showPart then
		self:changeShowPart(part)
	end
end

function EquipBag:part7BtnCallBack(ref)	
	local levelName = {20,35,50,65}
	local Eq_Level = 0
	if self.heroLv < levelName[2] then
  		Eq_Level = 1
  	elseif  levelName[2] <= self.heroLv and self.heroLv < levelName[3] then
  		Eq_Level = 2
  	elseif  levelName[3] <= self.heroLv and self.heroLv < levelName[4] then
  		Eq_Level = 3
  	elseif  levelName[4] <= self.heroLv then
  		Eq_Level = 4
  	end
  	print("Eq_Level", Eq_Level)
  	UIManager.open(UIManager.UI.UIEquipMake, false, {Eq_Vocation=self.heroJob,  Eq_Level=Eq_Level,  Eq_Parts=self.showPart})
end

function EquipBag:changeShowPart(showPart)
	self.showPart 		= showPart
	local partLanID = {612, 613, 614, 615, 616, 617}
	local partStr = CommonHelper.getUIString(partLanID[showPart])
	self.titleLab:setString(string.format(CommonHelper.getUIString(630), partStr))

	-- 按钮切换
	for i=1, 6 do
		local partBtn = self["partBtn_" .. i]
		local btnCsb = CsbTools.getChildFromPath(partBtn, "AllButton")
		partBtn:setLocalZOrder(i==showPart and 10 or -10)
		CommonHelper.playCsbAnimate(btnCsb, btnFile, i==showPart and "On" or "Normal", false, nil, true)
	end

	-- 重新显示左边的装备
	self:resetEqInfoCsb()
	-- 重新设置显示数据
	self:reSortEqsID()
	-- 构造动态创建信息
	self:initDyScroll()
	-- scroll刷新
	ScrollViewExtend:reloadData()
end

return EquipBag