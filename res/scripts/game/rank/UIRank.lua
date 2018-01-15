--[[
	排行榜界面
    1、显示排行榜(竞技, 锦标赛 ,等级, 公会, 爬塔)信息
--]]
require("game.rank.RankData")

local UIRank = class("UIRank", require("common.UIView"))
local ScrollViewExtend = require("common.ScrollViewExtend").new()

local csbFile = ResConfig.UIRank.Csb2
local rankFile = "ui_new/g_gamehall/i_instance/ClimbTower/RankingNum.csb"
local rankBtnFile = "ui_new/g_gamehall/g_gpub/SetButton.csb"

function UIRank:ctor()
	self.rootPath = csbFile.rank
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.itemsCache = {}
	self.items = {}

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function()
		UIManager.close()
	end)

	local panel = CsbTools.getChildFromPath(self.root, "MainPanel/MovePanel")
	self.titleLab = CsbTools.getChildFromPath(panel, "TitleFontLabel")
	self.listLab1 = CsbTools.getChildFromPath(panel, "RankingNum")
	self.listLab2 = CsbTools.getChildFromPath(panel, "Name")
	self.listLab3 = CsbTools.getChildFromPath(panel, "TowerNum")
	self.listLab4 = CsbTools.getChildFromPath(panel, "Points")
	self.rankLab1 = CsbTools.getChildFromPath(panel, "MyRanking")
	self.rankLab2 = CsbTools.getChildFromPath(panel, "HighestTower")
	self.rankNumLab1 = CsbTools.getChildFromPath(panel, "MyRankingNum")
	self.rankNumLab2 = CsbTools.getChildFromPath(panel, "HighestTowerNum")
	self.tipsLab = CsbTools.getChildFromPath(panel, "TimeTips")
	self.tipBtn = CsbTools.getChildFromPath(panel, "QuestionButton")

	self.titleLab:setString(CommonHelper.getUIString(18))
	CsbTools.initButton(self.tipBtn, function()
		UIManager.open(UIManager.UI.UITowerRankDesc);
	end)

	local tabScrollView = CsbTools.getChildFromPath(panel, "TabButtonScrollView")
	tabScrollView:setScrollBarEnabled(false)

	local rankTag = {0, 1, 2}
	local rankTypeLanID = {1350, 1351, 19}
	local imgFileName = {"RankingArena.png", "RankingLevel.png", "RankingGuild.png"}
	self.rankTypeBtnCsb = {}
	for i=1, 3 do
		local rankTypeBtn = CsbTools.getChildFromPath(panel, "TabButtonScrollView/PushSetButton_" .. i)
		local nameLab = CsbTools.getChildFromPath(rankTypeBtn, "SetButton/SetButtonPanel/NameLabel")
		local iconImg = CsbTools.getChildFromPath(rankTypeBtn, "SetButton/SetButtonPanel/ButtonImage")
		local frameImg = CsbTools.getChildFromPath(rankTypeBtn, "SetButton/SetButtonPanel/IronImage")
		self.rankTypeBtnCsb[rankTag[i]] = CsbTools.getChildFromPath(rankTypeBtn, "SetButton")

		nameLab:setString(CommonHelper.getUIString(rankTypeLanID[i]))
        CsbTools.initButton(rankTypeBtn, function ()
            self:changeRankType(rankTag[i])
        end)

		CsbTools.replaceImg(iconImg, imgFileName[i])
	end

	-- 排行数据列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/MovePanel/RankingItemScrollView")
	local itemCsb = getResManager():getCsbNode(csbFile.rankItem)
	self.itemSize = CsbTools.getChildFromPath(itemCsb, "RankingItem"):getContentSize()
    itemCsb:cleanup()
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()
end

function UIRank:onOpen(preUIID, rankType)
	self.showPart = nil
	self.rankData = {}

	self:changeRankType(rankType)	
end

function UIRank:onClose()
	RankData.clearUIAllCallFunc(UIManager.UI.UIRank)
	if self.showPart ~= nil then
		CommonHelper.playCsbAnimate(self.rankTypeBtnCsb[self.showPart], rankBtnFile, "Normal", false, nil, true)
	end
	self:clearScroll()
end

function UIRank:getNewScrollItem()
	local itemNode = nil
	if #self.itemsCache ~= 0 then
		itemNode = self.itemsCache[1]
		table.remove(self.itemsCache, 1)
		itemNode:setVisible(true)
	else
		itemNode = getResManager():cloneCsbNode(csbFile.rankItem)
		self.scroll:addChild(itemNode)
	end
	table.insert(self.items, itemNode)
	return itemNode
end

function UIRank:clearScroll()	
	-- 跳转到开始位置
	self.scroll:jumpToTop()
	self.scroll:setInnerContainerSize(self.scroll:getContentSize())
	for _, node in ipairs(self.items) do
		table.insert(self.itemsCache, node)
		node:setVisible(false)
	end
	self.items = {}
end

-- 设置排行榜列表信息
function UIRank:setItemInfo(itemCsb, i)
	local itemPanel 	= CsbTools.getChildFromPath(itemCsb, "RankingItem")
	
	local starInnerPos  = cc.p(0, 0)
	-- 添加点击监听
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
				--self:itemClickCallBack(itemCsb, i)
			end
		end
	end)

	-- 初始化节点
	self:initCardCsb(itemCsb, i)
end

-- 设置排行榜列表信息
function UIRank:initCardCsb(itemCsb, i)
	local info = self.rankData[self.showPart][i]

	local panel = CsbTools.getChildFromPath(itemCsb, "RankingItem")
	local rankNumCsb = CsbTools.getChildFromPath(panel, "RankingNum")
	local rankNumLab = CsbTools.getChildFromPath(rankNumCsb, "RankingPanel/RankingNum")
	local iconPanel = CsbTools.getChildFromPath(panel, "HeroIcon")
	local emblemPanel = CsbTools.getChildFromPath(panel, "GuildLogoItem")
	local heroIconImg = CsbTools.getChildFromPath(iconPanel, "HeadIcon")
	local emblemIconImg = CsbTools.getChildFromPath(emblemPanel, "Logo/Logo")
	local heroLvLab = CsbTools.getChildFromPath(iconPanel, "LevelNum")
	local lab1 = CsbTools.getChildFromPath(panel, "NameText")
	local lab2 = CsbTools.getChildFromPath(panel, "TowerNum")
	local lab3 = CsbTools.getChildFromPath(panel, "PointsNum")

	local rankName = {"One", "Two", "Three", "Other"}
	local rankActName = rankName[info.index <= 3 and info.index or 4]
	CommonHelper.playCsbAnimate(rankNumCsb, rankFile, rankActName, false, nil, true)
	rankNumLab:setString(info.index)

    local tencentLogo = CsbTools.getChildFromPath(panel, "TencentLogo")
    CommonHelper.showBlueDiamond(tencentLogo, info.BDType, info.BDLv)
    tencentLogo:setVisible(true)
	CommonHelper.playCsbAnimate(itemCsb, csbFile.rankItem, info.isSelf and "Self" or "Normal", false, nil, true)

	emblemPanel:setVisible(false)
	iconPanel:setVisible(true)
	if self.showPart == RankData.rankType.arena or 
        self.showPart == RankData.rankType.champion then
		heroLvLab:setString(info.userLevel)
		lab1:setString(info.heroName)
		lab2:setString(info.unionName)
		lab3:setString(info.score)
        if getSystemHeadIconItem()[info.headID] then
		    CsbTools.replaceImg(heroIconImg, getSystemHeadIconItem()[info.headID].IconName)
        end

	elseif self.showPart == RankData.rankType.summoner then
		heroLvLab:setString(info.userLevel)
		lab1:setString(info.heroName)
		lab2:setString(info.unionName)
		lab3:setString(info.userLevel)
        if getSystemHeadIconItem()[info.headID] then
		    CsbTools.replaceImg(heroIconImg, getSystemHeadIconItem()[info.headID].IconName)
        end

	elseif self.showPart == RankData.rankType.union then
		iconPanel:setVisible(false)
		emblemPanel:setVisible(true)
		lab1:setString(info.unionName)
		lab2:setString(info.unionMembersCount)
		lab3:setString(info.unionLevel)
        tencentLogo:setVisible(false)
        if not self.emblemConf then
        	self.emblemConf = getUnionBadgeConfItem()
        end
        if self.emblemConf[info.emblemID] then
        	CsbTools.replaceSprite(emblemIconImg, self.emblemConf[info.emblemID])
        else
        	print("error emblem not find", info.emblemID)
        end

	elseif self.showPart == RankData.rankType.tower then
		heroLvLab:setString(info.userLevel)
		lab1:setString(info.heroName)
		lab2:setString(info.maxFloor)
		lab3:setString(info.score)
        if getSystemHeadIconItem()[info.headID] then
		    CsbTools.replaceImg(heroIconImg, getSystemHeadIconItem()[info.headID].IconName)
        end
	end
end

-- 排行榜点击回调
function UIRank:itemClickCallBack(itemCsb, i)
	CsbTools.addTipsToRunningScene(CommonHelper.getUIString(11) 
		.. "\n" .. "curPart " .. self.showPart .. " click " .. i)
end

-- 切换排行榜类型
function UIRank:changeRankType(rankType)
	CommonHelper.playCsbAnimate(self.rankTypeBtnCsb[rankType], rankBtnFile, "On", false, nil, true)
	
	if self.showPart ~= rankType then
		if self.showPart ~= nil then
			CommonHelper.playCsbAnimate(self.rankTypeBtnCsb[self.showPart], rankBtnFile, "Normal", false, nil, true)
		end
		self.showPart = rankType
		-- 清除本UI获取数据的返回回调
		RankData.clearUIAllCallFunc(UIManager.UI.UIRank)
		-- 排行列的名称
		self:setListLab()
		-- 滚动列表下自己的信息文字刷新
		self:refreshSelfLab()
		-- 滚动列表设置成初始值
		self:clearScroll()

		RankData.getRankData(rankType, UIManager.UI.UIRank, function(rankInfo)
			self.rankData[rankType] = rankInfo
			-- 滚动列表下自己的信息值刷新
			self:refreshSelfRank(rankType)
			-- 显示当前类型排行榜数据
			self:starShowRank(rankType)
		end)
	end
end

-- 设置排行榜显示那几列数据
function UIRank:setListLab()
	local listLanID = {
		[RankData.rankType.arena] = {1360, 1361, 1362, 828},
		[RankData.rankType.summoner] = {1360, 1361, 1362, 1363},
		[RankData.rankType.union] = {1360, 1364, 1365, 1366},
		[RankData.rankType.tower] = {1360, 1361, 1367, 1368},
        [RankData.rankType.champion] = {1360, 1361, 1362, 828},
	}

	self.listLab1:setString(CommonHelper.getUIString(listLanID[self.showPart][1]))
	self.listLab2:setString(CommonHelper.getUIString(listLanID[self.showPart][2]))
	self.listLab3:setString(CommonHelper.getUIString(listLanID[self.showPart][3]))
	self.listLab4:setString(CommonHelper.getUIString(listLanID[self.showPart][4]))

	--self.tipBtn:setVisible(self.showPart == RankData.rankType.tower)
end

-- 刷新自己的数据
function UIRank:refreshSelfLab()
	local lanID = {
		[RankData.rankType.arena] = {1370, 1369, 1349},
		[RankData.rankType.summoner] = {1370, 1371},
		[RankData.rankType.union] = {1373, 1362},
		[RankData.rankType.tower] = {1370, 1367, 1374},
        [RankData.rankType.champion] = {1370, 1369, 1349},
	}
	self.rankLab1:setString(CommonHelper.getUIString(lanID[self.showPart][1]))
	self.rankLab2:setString(CommonHelper.getUIString(lanID[self.showPart][2]))
	if lanID[self.showPart][3] ~= nil then
		self.tipsLab:setVisible(true)
		self.tipsLab:setString(CommonHelper.getUIString(lanID[self.showPart][3]))
	else
		self.tipsLab:setVisible(false)
	end
	self.rankNumLab1:setString("--")
	self.rankNumLab2:setString("--")
end

-- 刷新排行榜数据
function UIRank:refreshSelfRank(rankType)
	if rankType ~= self.showPart then
		return
	end
	
	local info = RankData.data[self.showPart].selfInfo

	if self.showPart == RankData.rankType.arena or 
        self.showPart == RankData.rankType.champion then
		self.rankNumLab2:setString(info.score)
		if info.index == 0 then
			self.rankNumLab1:setString(CommonHelper.getUIString(1372))
		else
			self.rankNumLab1:setString(info.index)
		end
	elseif self.showPart == RankData.rankType.summoner then
		self.rankNumLab2:setString(info.userLevel)
		if info.index == 0 then
			self.rankNumLab1:setString(CommonHelper.getUIString(1372))
		else
			self.rankNumLab1:setString(info.index)
		end
	elseif self.showPart == RankData.rankType.union then
		if info.unionName and info.index and info.unionName ~= "" then
			self.rankNumLab2:setString(info.unionName)
			if info.index == 0 then
				self.rankNumLab1:setString(CommonHelper.getUIString(1372))
			else
				self.rankNumLab1:setString(info.index)
			end
		else
			self.rankNumLab1:setString("--")
			self.rankNumLab2:setString("--")
		end
	elseif self.showPart == RankData.rankType.tower then
		if info.index == 0 then
			self.rankNumLab1:setString(CommonHelper.getUIString(1372))
		else
			self.rankNumLab1:setString(info.index)
		end
		self.rankNumLab2:setString(info.maxFloor)
	end
end

-- 开始显示排行榜
function UIRank:starShowRank(rankType)
	if self.rankData[self.showPart] == nil or rankType ~= self.showPart then
		return 
	end

	local innerSize = self.scroll:getContentSize()
	if innerSize.height < #self.rankData[self.showPart] * (self.itemSize.height + 1) then
		innerSize.height = #self.rankData[self.showPart] * (self.itemSize.height + 1)
	end
	self.scroll:setInnerContainerSize(innerSize)

	for i=1, #self.rankData[self.showPart] do
		local itemNode = self:getNewScrollItem()
		self:setItemInfo(itemNode, i)
		itemNode:setPosition(cc.p(self.itemSize.width/2 + 4, innerSize.height - (self.itemSize.height + 1)*(i -0.5)))
	end
end

return UIRank