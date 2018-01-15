--[[
    队伍选择UI，主要实现以下内容
    1.显示玩家的英雄和召唤师，提供选择操作，并记录数据
    2.绑定点击回调
    
    2015-9-28 重构 by 宝爷
]]

local heroScrollViewExtend = require("common.ScrollViewExtend").new()
local summonerScrollViewExtend = require("common.ScrollViewExtend").new()
local mercenaryScrollViewExtend = require("common.ScrollViewExtend").new()

ccui.TextureResType = { plistType = 1 }

local maxHeros = 7
local minHeros = 1
local longClickTime = 0.5
local heroUnlockGuidId = 21
local summonerUnlockGuidId = 29

-- 排序类型
local sortType = {Level = 1, Cost = 2, Job = 3, Race = 4}
local sortLan = {584, 586, 499, 498}
------------------------- 英雄排序函数 -------------------------
-- 根据等级、星级、消耗、种族、职业、ID进行排序
local function sortHeroByLevel(hero1, hero2)
	local heroModel1 = getGameModel():getHeroCardBagModel():getHeroCard(hero1)
	local heroModel2 = getGameModel():getHeroCardBagModel():getHeroCard(hero2)
    local cfg1 = getSoldierConfItem(heroModel1:getID(), heroModel1:getStar())
    local cfg2 = getSoldierConfItem(heroModel2:getID(), heroModel2:getStar())
    if not cfg1 then
        print("getSoldierConfItem is nil!!!heroid, star", heroModel1:getID(), heroModel1:getStar())
        return false
    end

    if not cfg2 then
        print("getSoldierConfItem is nil!!!heroid, star", heroModel2:getID(), heroModel2:getStar())
        return false
    end

    local lv = heroModel1:getLevel() - heroModel2:getLevel()
	local star = heroModel1:getStar() - heroModel2:getStar()
	local id = heroModel1:getID() - heroModel2:getID()
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if lv > 0 then
		return true
	elseif lv == 0 and star > 0 then
		return true
	elseif lv == 0 and star == 0 and cost > 0 then
        return true
	elseif lv == 0 and star == 0 and cost == 0 and race > 0 then
        return true
	elseif lv == 0 and star == 0 and cost == 0 and race == 0 and job > 0 then
        return true
    elseif lv == 0 and star == 0 and cost == 0 and race == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据消耗、等级、星级、种族、职业、ID进行排序
local function sortHeroByCost(hero1, hero2)
	local heroModel1 = getGameModel():getHeroCardBagModel():getHeroCard(hero1)
	local heroModel2 = getGameModel():getHeroCardBagModel():getHeroCard(hero2)
    local cfg1 = getSoldierConfItem(heroModel1:getID(), heroModel1:getStar())
    local cfg2 = getSoldierConfItem(heroModel2:getID(), heroModel2:getStar())
    --
    local lv = heroModel1:getLevel() - heroModel2:getLevel()
	local star = heroModel1:getStar() - heroModel2:getStar()
	local id = heroModel1:getID() - heroModel2:getID()
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if cost > 0 then
		return true
	elseif cost == 0 and lv > 0 then
		return true
	elseif cost == 0 and lv == 0 and star > 0 then
        return true
	elseif cost == 0 and lv == 0 and star == 0 and race > 0 then
        return true
	elseif cost == 0 and lv == 0 and star == 0 and race == 0 and job > 0 then
        return true
    elseif cost == 0 and lv == 0 and star == 0 and race == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据职业、等级、星级、消耗、种族、ID进行排序
local function sortHeroByJob(hero1, hero2)
	local heroModel1 = getGameModel():getHeroCardBagModel():getHeroCard(hero1)
	local heroModel2 = getGameModel():getHeroCardBagModel():getHeroCard(hero2)
    local cfg1 = getSoldierConfItem(heroModel1:getID(), heroModel1:getStar())
    local cfg2 = getSoldierConfItem(heroModel2:getID(), heroModel2:getStar())
    --
    local lv = heroModel1:getLevel() - heroModel2:getLevel()
	local star = heroModel1:getStar() - heroModel2:getStar()
	local id = heroModel1:getID() - heroModel2:getID()
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if job > 0 then
		return true
	elseif job == 0 and lv > 0 then
		return true
	elseif job == 0 and lv == 0 and star > 0 then
        return true
	elseif job == 0 and lv == 0 and star == 0 and cost > 0 then
        return true
	elseif job == 0 and lv == 0 and star == 0 and cost == 0 and race > 0 then
        return true
    elseif job == 0 and lv == 0 and star == 0 and cost == 0 and race == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据种族、等级、星级、消耗、职业、ID进行排序
local function sortHeroByRace(hero1, hero2)
	local heroModel1 = getGameModel():getHeroCardBagModel():getHeroCard(hero1)
	local heroModel2 = getGameModel():getHeroCardBagModel():getHeroCard(hero2)
    local cfg1 = getSoldierConfItem(heroModel1:getID(), heroModel1:getStar())
    local cfg2 = getSoldierConfItem(heroModel2:getID(), heroModel2:getStar())
    --
    local lv = heroModel1:getLevel() - heroModel2:getLevel()
	local star = heroModel1:getStar() - heroModel2:getStar()
	local id = heroModel1:getID() - heroModel2:getID()
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if race > 0 then
		return true
	elseif race == 0 and lv > 0 then
		return true
	elseif race == 0 and lv == 0 and star > 0 then
        return true
	elseif race == 0 and lv == 0 and star == 0 and cost > 0 then
        return true
	elseif race == 0 and lv == 0 and star == 0 and cost == 0 and job > 0 then
        return true
    elseif race == 0 and lv == 0 and star == 0 and cost == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end


------------------------- 佣兵排序函数 -------------------------
-- 根据等级、星级、消耗、种族、职业、ID进行排序
local function sortMercenaryByLevel(hero1, hero2)
    local id = hero1.heroId - hero2.heroId
    local lv = hero1.heroLv - hero2.heroLv
	local star = hero1.heroStar - hero2.heroStar
    --
    local cfg1 = getSoldierConfItem(hero1.heroId, hero1.heroStar)
    local cfg2 = getSoldierConfItem(hero2.heroId, hero2.heroStar)
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if lv > 0 then
		return true
	elseif lv == 0 and star > 0 then
		return true
	elseif lv == 0 and star == 0 and cost > 0 then
        return true
	elseif lv == 0 and star == 0 and cost == 0 and race > 0 then
        return true
	elseif lv == 0 and star == 0 and cost == 0 and race == 0 and job > 0 then
        return true
    elseif lv == 0 and star == 0 and cost == 0 and race == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据消耗、等级、星级、种族、职业、ID进行排序
local function sortMercenaryByCost(hero1, hero2)
    local id = hero1.heroId - hero2.heroId
    local lv = hero1.heroLv - hero2.heroLv
	local star = hero1.heroStar - hero2.heroStar
    --
    local cfg1 = getSoldierConfItem(hero1.heroId, hero1.heroStar)
    local cfg2 = getSoldierConfItem(hero2.heroId, hero2.heroStar)
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if cost > 0 then
		return true
	elseif cost == 0 and lv > 0 then
		return true
	elseif cost == 0 and lv == 0 and star > 0 then
        return true
	elseif cost == 0 and lv == 0 and star == 0 and race > 0 then
        return true
	elseif cost == 0 and lv == 0 and star == 0 and race == 0 and job > 0 then
        return true
    elseif cost == 0 and lv == 0 and star == 0 and race == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据职业、等级、星级、消耗、种族、ID进行排序
local function sortMercenaryByJob(hero1, hero2)
    local id = hero1.heroId - hero2.heroId
    local lv = hero1.heroLv - hero2.heroLv
	local star = hero1.heroStar - hero2.heroStar
    --
    local cfg1 = getSoldierConfItem(hero1.heroId, hero1.heroStar)
    local cfg2 = getSoldierConfItem(hero2.heroId, hero2.heroStar)
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if job > 0 then
		return true
	elseif job == 0 and lv > 0 then
		return true
	elseif job == 0 and lv == 0 and star > 0 then
        return true
	elseif job == 0 and lv == 0 and star == 0 and cost > 0 then
        return true
	elseif job == 0 and lv == 0 and star == 0 and cost == 0 and race > 0 then
        return true
    elseif job == 0 and lv == 0 and star == 0 and cost == 0 and race == 0 and id > 0 then
		return true
	else
	 	return false
	end
end

-- 根据种族、等级、星级、消耗、职业、ID进行排序
local function sortMercenaryByRace(hero1, hero2)
    local id = hero1.heroId - hero2.heroId
    local lv = hero1.heroLv - hero2.heroLv
	local star = hero1.heroStar - hero2.heroStar
    --
    local cfg1 = getSoldierConfItem(hero1.heroId, hero1.heroStar)
    local cfg2 = getSoldierConfItem(hero2.heroId, hero2.heroStar)
    local cost = cfg1.Cost - cfg2.Cost
    local race = cfg1.Common.Race - cfg2.Common.Race
    local job = cfg1.Common.Vocation - cfg2.Common.Vocation
    --
	if race > 0 then
		return true
	elseif race == 0 and lv > 0 then
		return true
	elseif race == 0 and lv == 0 and star > 0 then
        return true
	elseif race == 0 and lv == 0 and star == 0 and cost > 0 then
        return true
	elseif race == 0 and lv == 0 and star == 0 and cost == 0 and job > 0 then
        return true
    elseif race == 0 and lv == 0 and star == 0 and cost == 0 and job == 0 and id > 0 then
		return true
	else
	 	return false
	end
end


------------------------- 队伍排序函数 -------------------------
-- 按照消耗、等级、星级进行排序
local function sortTeamHeroByCost(hero1, hero2)
	local heroModel1 = getGameModel():getHeroCardBagModel():getHeroCard(hero1)
	local heroModel2 = getGameModel():getHeroCardBagModel():getHeroCard(hero2)
    local cfg1 = getSoldierConfItem(heroModel1:getID(), heroModel1:getStar())
    local cfg2 = getSoldierConfItem(heroModel2:getID(), heroModel2:getStar())
    --
    local lv = heroModel1:getLevel() - heroModel2:getLevel()
	local star = heroModel1:getStar() - heroModel2:getStar()
    local cost = cfg1.Cost - cfg2.Cost
    --
    if cost < 0 then
		return true
	elseif cost == 0 and lv < 0 then
		return true
	elseif cost == 0 and lv == 0 and star < 0 then
		return true
    elseif cost == 0 and lv == 0 and star == 0 and hero1 > hero2 then
        return true
	else
	 	return false
	end
end

local function findValueInTable(tab, var)
    for k,v in pairs(tab or {}) do
        if v == var then
            return true
        end
    end
    return false
end

-- 判断指定引导id是否已经执行
local function haveExecutedGuid(_id)
    -- 引导提示
    if GuideManager.guideList then
        for _, guide in pairs(GuideManager.guideList) do
            if guide <= _id then
                return false
            end
        end
    end
    return true
end


local UITeam = class("UITeam", function()
    return require("common.UIView").new()
end)

local csb = ResConfig.UITeam.Csb2
UITeam.pvpType = 1
UITeam.stageType = 2

-- 需要传入战斗类型和战斗ID（PVE战斗ID传入关卡ID）
function UITeam:ctor()    
    self.rootPath = csb.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 语言包相关
    getChild(self.root, "MainPanel/BarLabel"):setString(getUILanConfItem(86))
    getChild(self.root, "MainPanel/FormationButton/Text"):setString(getUILanConfItem(87))
    getChild(self.root, "OrderPanel/OrderButton/OrderButton/Text"):setString(CommonHelper.getUIString(238))
    self.tipsText = getChild(self.root, "MainPanel/TipsText")

    -- 退出按钮
    local btnBack = getChild(self.root, "BackButton")
    CsbTools.initButton(btnBack, handler(self, self.onUIClose))
    -- 一键编队按钮
    local btnForm = getChild(self.root, "MainPanel/FormationButton")
    CsbTools.initButton(btnForm, handler(self, self.onOneKey))
    -- 开始战斗按钮
    local btnFight = getChild(self.root, "MainPanel/SaveTeamButton")
    CsbTools.initButton(btnFight, handler(self, self.onBattle))
    -- 向右切换队伍按钮
    local btnNext = getChild(self.root, "MainPanel/NextButton")
    CsbTools.initButton(btnNext, handler(self,  self.onNextTeam))
    -- 向左切换队伍按钮
    local btnLast = getChild(self.root, "MainPanel/LastButton")
    CsbTools.initButton(btnLast, handler(self, self.onLastTeam))
    -- 变更排序按钮
    self.sortPanel  = getChild(self.root, "OrderPanel")
    CsbTools.initButton(self.sortPanel, handler(self, self.onSortModify))
    self.sortCsb 	= getChild(self.sortPanel, "OrderButton")
	self.sortBtn 	= getChild(self.sortCsb, "OrderButton")
    CsbTools.initButton(self.sortBtn, handler(self, self.onSortModify))
    -- 排序按钮
    for i, v in pairs(sortType) do
        local sortTypeBtn = getChild(self.sortCsb, "OrderListView/OrderButton_" .. v)
        sortTypeBtn:setTitleText(CommonHelper.getUIString(sortLan[v]))
        sortTypeBtn:setTag(v)
        CsbTools.initButton(sortTypeBtn, handler(self, self.onSortHeros))
    end

    -- 锁定一些节点
    self.heroTab = getChild(self, "TeamSet/MainPanel/HeroButton/AllButton")
    self.summonerTab = getChild(self, "TeamSet/MainPanel/SunmmonerButton/AllButton")
    self.mercenaryTab = getChild(self, "TeamSet/MainPanel/MercenaryButton/AllButton")
    getChild(self.heroTab, "RedTipPoint"):setVisible(false)
    getChild(self.summonerTab, "RedTipPoint"):setVisible(false)
    getChild(self.mercenaryTab, "RedTipPoint"):setVisible(false)
    --
    self.heroView = getChild(self, "TeamSet/MainPanel/HeroIconScrollView")
    self.summonerView = getChild(self, "TeamSet/MainPanel/SummonerIconScrollView")
    self.mercenaryView = getChild(self, "TeamSet/MainPanel/MercenaryIconScrollView")
end

-- 传入回调 + 样式
-- 不传style为默认样式
-- sytle为1表示竞技场出战队伍设置样式
function UITeam:onOpen(openerUIID, func, style)
    self.onBattleCallback = func
    self.style = style

    self.longClickHandler = nil
    -- if self.style == 1 or self.style == 3 then
        -- -- 获取竞技场默认队伍
        -- self.teamSummonerId, self.teamHeroIds = getGameModel():getTeamModel():getTeamInfo(ModelHelper.teamType.Arena)
    -- else
        -- -- 获取通用默认队伍
        -- self.teamSummonerId, self.teamHeroIds = getGameModel():getTeamModel():getTeamInfo(ModelHelper.teamType.Pass)
    -- end

    self.teamId = TeamHelper.getTeamId()
    self.teamHeroIds = TeamHelper.getTeamHeros(self.teamId)
    self.teamSummonerId = TeamHelper.getTeamSummoner(self.teamId)
    self.teamMercenary = nil

    -- 初始化整个界面视图
    self:initTeamView()
    -- 初始化标签栏按钮
    self:initTabButton()
    -- 初始化英雄列表
    self:initHeroScrollView()
    -- 初始化召唤师列表
    self:initSummonerScrollView()
    -- 初始化佣兵列表
    self:initMercenaryScrollView()
    -- 初始化队伍英雄
    self:setTeamHeroIcon()
    -- 初始化队伍召唤师
    self:setTeamSummonerIcon()

    self:initNetwork()
    self:initEvent()

    self:setNodeEventEnabled(true)
end

function UITeam:onClose()
    self.onBattleCallback = nil
    self.longClickHandler = nil
    heroScrollViewExtend:removeAllChild()
    summonerScrollViewExtend:removeAllChild()
    mercenaryScrollViewExtend:removeAllChild()
    self:removeNetwork()
    self:removeEvent()
end

function UITeam:onTop(preUIID, ...)
    -- 刷新英雄列表
    self.heros = {}
    local heros = getGameModel():getHeroCardBagModel():getHeroCards()
    for _,heroId in pairs(heros or {}) do
        local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
        if heroModel:getStar() ~= 0 then
            table.insert(self.heros, heroId)
        end
    end
    if 0 == #self.heros then
        return
    end
    self:reSortHerosID()
    self:setTeamHeroIcon()
end


-- 初始化整个界面视图
-- 包括已选择的面板（可能根据队伍模型）
function UITeam:initTeamView()
    -- 绑定按钮回调
    local battleLanId = 88
    if 3 == self.style then
        battleLanId = 237
    end
    getChild(self, "TeamSet/MainPanel/TeamLogo/Text"):setString(getUILanConfItem(236) .. self.teamId)
    getChild(self, "TeamSet/MainPanel/SaveTeamButton/Text"):setString(getUILanConfItem(battleLanId))
    self.sortPanel:setTouchEnabled(false)
    self.sortCsb:setVisible(true)
    self.tipsText:setString(CommonHelper.getUIString(497))
end


---------------------------------------------------------------------
-- 初始化标签按钮
local tabButton = { 
    [1] = {name = "HeroButton", lan = 609},
    [2] = {name = "SunmmonerButton", lan = 14},
    [3] = {name = "MercenaryButton", lan = 2040},
}
local curTabName = "HeroButton"
function UITeam:initTabButton()
    curTabName = "HeroButton"
    for i, v in pairs(tabButton) do
        local button = getChild(self, "TeamSet/MainPanel/" .. v.name)
        CsbTools.initButton(button, handler(self, self.onTabButtonClick), getUILanConfItem(v.lan),
            "AllButton/ButtonPanel/NameLabel", "AllButton/ButtonPanel")
        local node = getChild(button, "AllButton")
        if v.name == curTabName then
            button:setLocalZOrder(100)
            CommonHelper.playCsbAnimate(node, csb.tab, "On", false)
        else
            button:setLocalZOrder(-1)
            CommonHelper.playCsbAnimate(node, csb.tab, "Normal", false)
        end
    end
    -- 佣兵按钮特殊处理
    if self.style == 1 or self.style == 3 then
        getChild(self, "TeamSet/MainPanel/MercenaryButton"):setVisible(false)
    else
        getChild(self, "TeamSet/MainPanel/MercenaryButton"):setVisible(true)
    end
    --
    self.heroView:setVisible(true)
    self.summonerView:setVisible(false)
    self.mercenaryView:setVisible(false)
end

-- 标签按钮点击回调
function UITeam:onTabButtonClick(obj)
    local objName = obj:getName()
    if curTabName == objName then return end
    -- 切换标签按钮状态
    local prevButton = getChild(self, "TeamSet/MainPanel/" .. curTabName)
    prevButton:setLocalZOrder(-1)
    local prevNode = getChild(prevButton, "AllButton")
    prevNode:stopAllActions()
    CommonHelper.playCsbAnimate(prevNode, csb.tab, "Normal", false)
    curTabName = objName
    local curbutton = getChild(self, "TeamSet/MainPanel/" .. curTabName)
    curbutton:setLocalZOrder(100)
    local curNode = getChild(curbutton, "AllButton")
    curNode:stopAllActions()
    CommonHelper.playCsbAnimate(curNode, csb.tab, "On", false)    
    -- 处理标签按钮逻辑
    if objName == "HeroButton" then
        self.heroView:setVisible(true)
        self.summonerView:setVisible(false)
        self.mercenaryView:setVisible(false)
        --
        self.sortCsb:setVisible(true)
        self.tipsText:setString(CommonHelper.getUIString(497))
    elseif objName == "SunmmonerButton" then
        self.heroView:setVisible(false)
        self.summonerView:setVisible(true)
        self.mercenaryView:setVisible(false)
        --
        self.sortCsb:setVisible(false)
        self.tipsText:setString(CommonHelper.getUIString(496))
    elseif objName == "MercenaryButton" then
        self.heroView:setVisible(false)
        self.summonerView:setVisible(false)
        self.mercenaryView:setVisible(true)
        --
        self.sortCsb:setVisible(true)
        self.tipsText:setString(CommonHelper.getUIString(2058))
    end
end


---------------------------------------------------------------------
-- 初始化英雄列表
function UITeam:initHeroScrollView()
    self.heros = {}
    local heros = getGameModel():getHeroCardBagModel():getHeroCards()
    for _,heroId in pairs(heros or {}) do
        local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
        if heroModel:getStar() ~= 0 then
            table.insert(self.heros, heroId)
        end
    end
    -- 进行排序
    self.curHeroSortType = sortType.Level
    table.sort(self.heros or {}, sortHeroByLevel)

    local node = getResManager():getCsbNode(csb.hero)
    local cell = getChild(node, "HeroImage")
    local cellSize = cell:getContentSize()
    node:cleanup()
    local defaultCount = #(self.heros)      -- 初始节点个数
    if defaultCount > 24 then
        defaultCount = 24
    end
    local maxCellCount = #(self.heros)      -- 最大节点个数

    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 4,                            -- 每行节点个数
        defaultCount    = defaultCount,                 -- 初始节点个数
        maxCellCount    = maxCellCount,                 -- 最大节点个数
        csbName         = csb.hero,                     -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "HeroImage",                  -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.heroView,                -- 滚动区域
        distanceX       = 18,                           -- 节点X轴间距
        distanceY       = 18,                           -- 节点Y轴间距
        offsetX         = 9,                            -- 第一列的偏移
        offsetY         = 10,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setHeroIconData),  -- 设置节点数据回调函数
    }
    heroScrollViewExtend:init(tabParam)
    heroScrollViewExtend:create()
    heroScrollViewExtend:reloadData()
end

-- 设置英雄的头像信息
function UITeam:setHeroIconData(csbNode, idx)
    local heroId = self.heros[idx]
    if nil == heroId then
        csbNode:setVisible(false)
        return
    end

    csbNode:setTag(heroId)
    csbNode:setName(csbNode:getName() .. heroId)
    local selected = findValueInTable(self.teamHeroIds, heroId)
    CommonHelper.playCsbAnimate(csbNode, csb.hero, selected and "Choose" or "Normal", true)
    --
    self:initHeroIcon(csbNode, heroId)
end

-- 传入英雄图标节点，英雄模型
-- 初始化英雄的星级、等级、头像、边框等信息
function UITeam:initHeroIcon(csbNode, heroId, hide)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroId)
    local soldierCfg = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
    if nil == soldierCfg then
        csbNode:setVisible(false)
        return
    end

    local heroImage = getChild(csbNode, "HeroImage")
    local bgImage = getChild(csbNode, "LvBgImage")
    local lvLabel   = getChild(csbNode, "LvLabel")
    local costLabel = getChild(csbNode, "GemLabel")
    local starLabel = getChild(csbNode, "StarLabel")
    local lvImage   = getChild(csbNode, "HeroImage/LvImage")
    local jobImage  = getChild(csbNode, "ProfesionIcon")
    local raceImage = getChild(csbNode, "RaceIcon")
    local mercenaryLogo = getChild(csbNode, "MercenaryLogo")
    jobImage:setVisible(false)
    raceImage:setVisible(false)
    mercenaryLogo:setVisible(false)
    if not hide and sortType.Job == self.curHeroSortType then
        -- 设置职业图标
        local job = getIconSettingConfItem().JobIcon[soldierCfg.Common.Vocation]
        jobImage:setSpriteFrame(job)
        jobImage:setVisible(true)
    elseif not hide and sortType.Race == self.curHeroSortType then
        -- 设置种族图标
        local race = getIconSettingConfItem().RaceIcon[soldierCfg.Common.Race]        
        raceImage:setSpriteFrame(race)
        raceImage:setVisible(true)
    end
    -- 设置召唤师的头像、背景、边框
    heroImage:loadTexture(soldierCfg.Common.HeadIcon, ccui.TextureResType.plistType)
    bgImage:loadTexture(IconHelper.getSoldierHeadBg(soldierCfg.Rare), ccui.TextureResType.plistType)
    lvImage:loadTexture(IconHelper.getSoldierHeadFrame(soldierCfg.Rare), ccui.TextureResType.plistType)
    -- 设置等级、消耗与星级的文本
    lvLabel:setString(tostring(heroModel:getLevel()))
    starLabel:setString(tostring(heroModel:getStar()))
    costLabel:setString(tostring(soldierCfg.Cost))
    -- 绑定英雄头像点击回调
    heroImage:setTouchEnabled(true)
    heroImage:setSwallowTouches(false)
    local longFlag = false
    heroImage:addTouchEventListener(function(obj, event)
        if 0 == event then
            if haveExecutedGuid(heroUnlockGuidId) and not self.longClickHandler then
                self.longClickHandler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
                    longFlag = true
                    --
                    if self.longClickHandler ~= nil then
                        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                        self.longClickHandler = nil
                    end
                    UIManager.open(UIManager.UI.UIHeroInfo, heroId, self.heros)
                end, longClickTime, false)
            end
        elseif 1 == event then
            local beginPos = obj:getTouchBeganPosition()
            local movePos = obj:getTouchMovePosition()
            if cc.pGetDistance(beginPos, movePos) > 40 then
                if self.longClickHandler ~= nil then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                    self.longClickHandler = nil
                end
            end
        elseif 2 == event then
            MusicManager.playSoundEffect(obj:getName())
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
            --
            if longFlag then
                longFlag = false
                return
            end
            --
            local beginPos = obj:getTouchBeganPosition()
            local endPos = obj:getTouchEndPosition()
            if cc.pGetDistance(beginPos, endPos) > 40 then
                return
            end
            --
            self:onHeroIconClick(heroId, not findValueInTable(self.teamHeroIds, heroId))
        elseif 3 == event then
            longFlag = false
            --
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
        end
    end)
end


---------------------------------------------------------------------
-- 初始化召唤师列表
function UITeam:initSummonerScrollView()
    self.summoners = getGameModel():getSummonersModel():getSummoners() or {}

    local node = getResManager():getCsbNode(csb.sum)
    local cell = getChild(node, "SummonerImage")
    local cellSize = cell:getContentSize()
    node:cleanup()
    local defaultCount = #(self.summoners)      -- 初始节点个数
    if defaultCount > 15 then
        defaultCount = 15
    end
    local maxCellCount = #(self.summoners)      -- 最大节点个数

    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 3,                            -- 每行节点个数
        defaultCount    = defaultCount,                 -- 初始节点个数
        maxCellCount    = maxCellCount,                 -- 最大节点个数
        csbName         = csb.sum,                      -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "SummonerImage",              -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.summonerView,            -- 滚动区域
        distanceX       = 24,                           -- 节点X轴间距
        distanceY       = 18,                           -- 节点Y轴间距
        offsetX         = 18,                           -- 第一列的偏移
        offsetY         = 6,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setSummonerIconData),  -- 设置节点数据回调函数
    }
    summonerScrollViewExtend:init(tabParam)
    summonerScrollViewExtend:create()
    summonerScrollViewExtend:reloadData()
end

-- 设置召唤师的头像信息
function UITeam:setSummonerIconData(csbNode, idx)
    local summonerId = self.summoners[idx]
    if nil == summonerId then
        csbNode:setVisible(false)
        return
    end

    csbNode:setTag(summonerId)
    csbNode:setName(csbNode:getName() .. summonerId)
    local selected = self.teamSummonerId and self.teamSummonerId == summonerId
    CommonHelper.playCsbAnimate(csbNode, csb.sum, selected and "Choose" or "Normal", false)
    --
    self:initSummonerIcon(csbNode, summonerId, true)
end

function UITeam:initSummonerIcon(csbNode, summonerId, flag)
    local heroConf = getHeroConfItem(summonerId)
    if not heroConf then
        csbNode:setVisible(false)
        return
    end
    local image = getChild(csbNode, "SummonerImage")
    image:loadTexture(heroConf.Common.HeadIcon, ccui.TextureResType.plistType)
    -- 绑定召唤师头像点击回调（可以有取消）
    image:setTouchEnabled(true)
    image:setSwallowTouches(false)
    local longFlag = false
    image:addTouchEventListener(function(obj, event)
        if 0 == event then
            if haveExecutedGuid(summonerUnlockGuidId) and not self.longClickHandler then
                self.longClickHandler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
                    longFlag = true
                    --
                    if self.longClickHandler ~= nil then
                        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                        self.longClickHandler = nil
                    end
                    --
                    local idx = 0
                    local summoners = {}
                    for i, v in pairs(self.summoners or {}) do
                        local summoner = {}
                        summoner.sumID = v
                        summoner.isBuy = true
                        summoner.orderBuy = i
                        table.insert(summoners, summoner)
                        if v == summonerId then
                            idx = i
                        end
                    end
                    if idx > 0 and #summoners > 0 and idx <= #summoners then
                        UIManager.open(UIManager.UI.UISummonerInfo, summoners, idx)
                    end
                end, longClickTime, false)
            end
        elseif 1 == event then
            local beginPos = obj:getTouchBeganPosition()
            local movePos = obj:getTouchMovePosition()
            if cc.pGetDistance(beginPos, movePos) > 40 then
                if self.longClickHandler ~= nil then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                    self.longClickHandler = nil
                end
            end
        elseif 2 == event then
            MusicManager.playSoundEffect(obj:getName())
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
            --
            if longFlag then
                longFlag = false
                return
            end
            --
            local beginPos = obj:getTouchBeganPosition()
            local endPos = obj:getTouchEndPosition()
            if cc.pGetDistance(beginPos, endPos) > 40 then
                return
            end
            --
            self:onSummonerIconClick(summonerId, flag)
        elseif 3 == event then
            longFlag = false
            --
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
        end
    end)
end


---------------------------------------------------------------------
-- 初始化佣兵列表
function UITeam:initMercenaryScrollView()
    self.mercenarys = {}
    local mercenarys = getGameModel():getUnionMercenaryModel():getOtherMercenarys()
    for _, v in pairs(mercenarys or {}) do
        table.insert(self.mercenarys, v)
    end
    -- 进行排序
    self.curMercenarySortType = sortType.Level
    table.sort(self.mercenarys or {}, sortMercenaryByLevel)

    local node = getResManager():getCsbNode(csb.hero)
    local cell = getChild(node, "HeroImage")
    local cellSize = cell:getContentSize()
    node:cleanup()
    local defaultCount = #(self.mercenarys)      -- 初始节点个数
    if defaultCount > 15 then
        defaultCount = 15
    end
    local maxCellCount = #(self.mercenarys)      -- 最大节点个数

    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 4,                            -- 每行节点个数
        defaultCount    = defaultCount,                 -- 初始节点个数
        maxCellCount    = maxCellCount,                 -- 最大节点个数
        csbName         = csb.hero,                     -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "HeroImage",                  -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.mercenaryView,           -- 滚动区域
        distanceX       = 18,                           -- 节点X轴间距
        distanceY       = 18,                           -- 节点Y轴间距
        offsetX         = 9,                            -- 第一列的偏移
        offsetY         = 10,                           -- 第一行的偏移
        setCellDataCallback = handler(self, self.setMercenaryIconData),  -- 设置节点数据回调函数
    }
    mercenaryScrollViewExtend:init(tabParam)
    mercenaryScrollViewExtend:create()
    mercenaryScrollViewExtend:reloadData()
end

-- 设置佣兵信息
function UITeam:setMercenaryIconData(csbNode, idx)
    local mercenary = self.mercenarys[idx]
    if not mercenary then
        csbNode:setVisible(false)
        return
    end

    csbNode:setTag(mercenary.heroId)
    csbNode:setName(csbNode:getName() .. mercenary.heroId)
    local selected = self.teamMercenary and self.teamMercenary.heroId == mercenary.heroId
    CommonHelper.playCsbAnimate(csbNode, csb.hero, selected and "Choose" or "Normal", false)
    --
    self:initMercenaryIcon(csbNode, mercenary)
end

function UITeam:initMercenaryIcon(csbNode, mercenary)
    local soldierCfg = getSoldierConfItem(mercenary.heroId, mercenary.heroStar)
    if nil == soldierCfg then
        csbNode:setVisible(false)
        return
    end
    local soldierStarCfg = getSoldierStarSettingConfItem(mercenary.heroStar)
    if nil == soldierStarCfg then
        csbNode:setVisible(false)
        return
    end

    local heroImage = getChild(csbNode, "HeroImage")
    local bgImage   = getChild(csbNode, "LvBgImage")
    local lvLabel   = getChild(csbNode, "LvLabel")
    local costLabel = getChild(csbNode, "GemLabel")
    local starLabel = getChild(csbNode, "StarLabel")
    local lvImage   = getChild(csbNode, "HeroImage/LvImage")
    local jobImage  = getChild(csbNode, "ProfesionIcon")
    local raceImage = getChild(csbNode, "RaceIcon")
    local mercenaryLogo = getChild(csbNode, "MercenaryLogo")
    jobImage:setVisible(false)
    raceImage:setVisible(false)
    mercenaryLogo:setVisible(true)
    mercenaryLogo:setString(CommonHelper.getUIString(2041))
    if sortType.Job == self.curMercenarySortType then
        -- 设置职业图标
        local job = getIconSettingConfItem().JobIcon[soldierCfg.Common.Vocation]
        jobImage:setSpriteFrame(job)
        jobImage:setVisible(true)
    elseif sortType.Race == self.curMercenarySortType then
        -- 设置种族图标
        local race = getIconSettingConfItem().RaceIcon[soldierCfg.Common.Race]        
        raceImage:setSpriteFrame(race)
        raceImage:setVisible(true)
    end
    -- 设置召唤师的头像、背景、边框
    heroImage:loadTexture(soldierCfg.Common.HeadIcon, ccui.TextureResType.plistType)
    bgImage:loadTexture(IconHelper.getSoldierHeadBg(soldierCfg.Rare), ccui.TextureResType.plistType)
    lvImage:loadTexture(IconHelper.getSoldierHeadFrame(soldierCfg.Rare), ccui.TextureResType.plistType)
    -- 设置等级、消耗与星级的文本
    lvLabel:setString(tostring(mercenary.heroLv))
    starLabel:setString(tostring(mercenary.heroStar))
    costLabel:setString(tostring(soldierCfg.Cost))
    -- 绑定佣兵头像点击回调
    heroImage:setTouchEnabled(true)
    heroImage:setSwallowTouches(false)
    local longFlag = false
    heroImage:addTouchEventListener(function(obj, event)
        if 0 == event then
            if haveExecutedGuid(heroUnlockGuidId) and not self.longClickHandler then
                self.longClickHandler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
                    longFlag = true
                    --
                    if self.longClickHandler ~= nil then
                        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                        self.longClickHandler = nil
                    end
                    local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()
                    if UnionMercenaryModel:getCurMercenaryInfo(mercenary and mercenary.dyId or 0) then
                        UIManager.open(UIManager.UI.UIUnionMercenaryInfo, mercenary.dyId)
                    else
                        self:sendMercenaryGetCmd(mercenary)
                    end
                end, longClickTime, false)
            end
        elseif 1 == event then
            local beginPos = obj:getTouchBeganPosition()
            local movePos = obj:getTouchMovePosition()
            if cc.pGetDistance(beginPos, movePos) > 40 then
                if self.longClickHandler ~= nil then
                    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                    self.longClickHandler = nil
                end
            end
        elseif 2 == event then
            MusicManager.playSoundEffect(obj:getName())
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
            --
            if longFlag then
                longFlag = false
                return
            end
            --
            local beginPos = obj:getTouchBeganPosition()
            local endPos = obj:getTouchEndPosition()
            if cc.pGetDistance(beginPos, endPos) > 40 then
                return
            end
            --
            self:onMercenaryIconClick(mercenary, not self.teamMercenary)
        elseif 3 == event then
            longFlag = false
            --
            if self.longClickHandler ~= nil then
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.longClickHandler)
                self.longClickHandler = nil
            end
        end
    end)
end


---------------------------------------------------------------------
-- 设置队伍英雄图标
function UITeam:setTeamHeroIcon()
    local _maxHeros = maxHeros
    local offset = 0
    if self.teamMercenary and self.teamMercenary.heroId > 0 then
        _maxHeros = _maxHeros - 1
        offset = 1
        --
        local heroIcon = getChild(self, "TeamSet/MainPanel/HeroIcon_" .. 1)
        self:initMercenaryIcon(heroIcon, self.teamMercenary)
        -- 刷新出征的佣兵
        CommonHelper.playCsbAnimate(heroIcon, csb.hero, "Normal", false, true)
    end
    -- 更新已出征的英雄
    -- 重新排序
    table.sort(self.teamHeroIds or {}, sortTeamHeroByCost)
    for i = 1, _maxHeros do
        local heroIcon = getChild(self, "TeamSet/MainPanel/HeroIcon_" .. i + offset)
        local heroId = self.teamHeroIds[i]
        if heroId and heroId > 0 then
            self:initHeroIcon(heroIcon, heroId, true)
            -- 刷新出征的英雄
            CommonHelper.playCsbAnimate(heroIcon, csb.hero, "Normal", false, true)
        else
            -- 刷新空格
            CommonHelper.playCsbAnimate(heroIcon, csb.hero, "Empty", false, true)
        end
    end
end

-- 设置队伍召唤师图标
function UITeam:setTeamSummonerIcon()
    local summonerIcon = getChild(self, "TeamSet/MainPanel/SummonerIcon")
    local summonerImage = getChild(self, "TeamSet/MainPanel/SummonerIcon/SummonerImage")
    if self.teamSummonerId and self.teamSummonerId > 0 then
        self:initSummonerIcon(summonerIcon, self.teamSummonerId, false)
        -- 刷新出征的召唤师
        CommonHelper.playCsbAnimate(summonerIcon, csb.sum, "Normal", false)
    else
        -- 刷新空格
        CommonHelper.playCsbAnimate(summonerIcon, csb.sum, "Empty", false)
    end
end


------------------------------------------点击回调-----------------------------------------------------

-- 英雄图标被点击，传入英雄的Id，以及是否选中
function UITeam:onHeroIconClick(heroId, selected)
    local _maxHeros = maxHeros
    if self.teamMercenary and self.teamMercenary.heroId > 0 then
        _maxHeros = _maxHeros - 1
    end
    -- 如果超过英雄上限则不处理
    if selected and #self.teamHeroIds >= _maxHeros then
        -- 播放一个抖动效果
        CommonHelper.playCsbAnimate(self.root, csb.main, "TeamFull")
        -- 浮动文字提示
        self:addChild(require("game.comm.PopTip").new({
					text = CommonHelper.getUIString(89) or "89", 
					font = "../fonts/msyh.ttf",
					animate = 1,
					x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0),
					align = cc.ui.TEXT_ALIGN_CENTER,
					valign= cc.ui.TEXT_VALIGN_CENTER,
					dimensions = cc.size(500, 500)
					}))
        return
    end

    -- 改变英雄列表面板内容
    local heroIcon = self.heroView:getChildByTag(heroId or 0)
    if heroIcon then
        CommonHelper.playCsbAnimate(heroIcon, csb.hero, selected and "Choose" or "Normal", true)
    end

    -- 更新队伍英雄ID
    if selected then
        self.teamHeroIds[#self.teamHeroIds + 1] = heroId
    else
        for k,v in pairs(self.teamHeroIds or {}) do
            if v == heroId then
                table.remove(self.teamHeroIds, k)
                break
            end
        end
    end
    -- 设置队伍面板英雄节点数据
    self:setTeamHeroIcon()
end

-- 召唤师图标被点击，传入召唤师的Id，以及是否被选中
function UITeam:onSummonerIconClick(summonerId, selected)
    -- 原先的召唤师恢复正常，并选中当前召唤师
    if self.teamSummonerId and self.teamSummonerId > 0 then
        local prev = self.summonerView:getChildByTag(self.teamSummonerId or 0)
        if prev then
            CommonHelper.playCsbAnimate(prev, csb.sum, "Normal", false, true)
        end
        -- 切换的召唤师面板
        local button = getChild(self, "TeamSet/MainPanel/SunmmonerButton")
        self:onTabButtonClick(button)
    end

    -- 改变召唤师列表面板内容
    local summonerIcon = self.summonerView:getChildByTag(summonerId or 0)
    if summonerIcon then
        CommonHelper.playCsbAnimate(summonerIcon, csb.sum, selected and "Choose" or "Normal", true)
    end

    -- 更新队伍召唤师ID
    self.teamSummonerId = selected and summonerId or nil
    -- 设置队伍面板召唤师节点数据
    self:setTeamSummonerIcon()
end


-- 佣兵图标被点击，传入佣兵的Id，以及是否被选中
function UITeam:onMercenaryIconClick(mercenary, selected)
    if not mercenary then
        return
    end
    -- 如果超过英雄上限则不处理
    if selected and #self.teamHeroIds >= maxHeros then
        -- 播放一个抖动效果
        CommonHelper.playCsbAnimate(self.root, csb.main, "TeamFull")
        -- 浮动文字提示
        self:addChild(require("game.comm.PopTip").new({
					text = CommonHelper.getUIString(89) or "89", 
					font = "../fonts/msyh.ttf",
					animate = 1,
					x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0),
					align = cc.ui.TEXT_ALIGN_CENTER,
					valign= cc.ui.TEXT_VALIGN_CENTER,
					dimensions = cc.size(500, 500)
					}))
        return
    end

    if self.teamMercenary and self.teamMercenary.heroId > 0 then
        local prev = self.mercenaryView:getChildByTag(self.teamMercenary.heroId or 0)
        if prev then
            CommonHelper.playCsbAnimate(prev, csb.hero, "Normal", false, true)
        end

        if self.teamMercenary.heroId ~= mercenary.heroId then
            self.teamMercenary = mercenary
            -- 改变佣兵列表面板内容
            local mercenaryIcon = self.mercenaryView:getChildByTag(mercenary.heroId or 0)
            if mercenaryIcon then
                CommonHelper.playCsbAnimate(mercenaryIcon, csb.hero, "Choose", true)
            end
        else
            self.teamMercenary = nil
        end
    else
        self.teamMercenary = mercenary
        -- 改变佣兵列表面板内容
        local mercenaryIcon = self.mercenaryView:getChildByTag(mercenary.heroId or 0)
        if mercenaryIcon then
            CommonHelper.playCsbAnimate(mercenaryIcon, csb.hero, "Choose", true)
        end
    end
    -- 设置队伍面板英雄节点数据
    self:setTeamHeroIcon()
end


---------------------------------------------------------------------
-- 初始化网络回调
function UITeam:initNetwork()
    -- 注册请求公会佣兵信息的网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryGetSC)
    self.mercenaryInfoHandler = handler(self, self.acceptMercenaryGetCmd)
    NetHelper.setResponeHandler(cmd, self.mercenaryInfoHandler)
end

-- 移除网络回调
function UITeam:removeNetwork()
    -- 移除请求公会佣兵信息的网络回调
    if self.mercenaryInfoHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryGetSC)
        NetHelper.removeResponeHandler(cmd, self.mercenaryInfoHandler)
        self.mercenaryInfoHandler = nil
    end
end

-- 发送获取佣兵详细信息的请求
function UITeam:sendMercenaryGetCmd(mercenary)
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryGetCS)
    bufferData:writeInt(mercenary and mercenary.dyId or 0)
   	NetHelper.request(buffData)
   	self.curDyId = mercenary and mercenary.dyId or 0
end

-- 接收获取佣兵详细信息的请求
function UITeam:acceptMercenaryGetCmd(mainCmd, subCmd, buffData)
	-- 把这个佣兵的信息写入model
    local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()
	UnionMercenaryModel:refreshCurMercenaryData(buffData)
	--打开界面,这个界面需要的数据从model中取就好了
	-- 打开UI栈,看下当前界面是啥子
    UIManager.open(UIManager.UI.UIUnionMercenaryInfo, self.curDyId)
end


---------------------------------------------------------------------
-- 初始化事件回调
function UITeam:initEvent()
    -- 添加佣兵派遣事件监听
    self.dispatchHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventOtherDispatchMercenary, self.dispatchHandler)
    -- 添加佣兵召回事件监听
    self.recallHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventOtherRecallMercenary, self.recallHandler)
end

-- 移除事件回调
function UITeam:removeEvent()
    -- 移除佣兵派遣事件监听
    if self.dispatchHandler then
        EventManager:removeEventListener(GameEvents.EventOtherDispatchMercenary, self.dispatchHandler)
        self.dispatchHandler = nil
    end
    -- 移除佣兵召回事件监听
    if self.recallHandler then
        EventManager:removeEventListener(GameEvents.EventOtherRecallMercenary, self.recallHandler)
        self.recallHandler = nil
    end
end

-- 佣兵 派遣, 召回 事件回调
function UITeam:onEventCallback(eventName, prams)
    -- 派遣
    if eventName == GameEvents.EventOtherDispatchMercenary then
        self.mercenarys = {}
        local mercenarys = getGameModel():getUnionMercenaryModel():getOtherMercenarys()
        for _, v in pairs(mercenarys or {}) do
            table.insert(self.mercenarys, v)
        end
        -- 进行排序
        self.curMercenarySortType = sortType.Level
        table.sort(self.mercenarys or {}, sortMercenaryByLevel)    
        mercenaryScrollViewExtend:reloadList(15, #(self.mercenarys))

    -- 召回
    elseif eventName == GameEvents.EventOtherRecallMercenary then
        self.mercenarys = {}
        local mercenarys = getGameModel():getUnionMercenaryModel():getOtherMercenarys()
        for _, v in pairs(mercenarys or {}) do
            table.insert(self.mercenarys, v)
        end
        -- 进行排序
        self.curMercenarySortType = sortType.Level
        table.sort(self.mercenarys or {}, sortMercenaryByLevel)    
        mercenaryScrollViewExtend:reloadList(15, #(self.mercenarys))

        if self.teamMercenary and self.teamMercenary.dyId == prams.dyId  then
            self.teamMercenary = nil
            self:setTeamHeroIcon()
        end
    end
end


-- 一键编队按钮
function UITeam:onOneKey(obj)
    -- 如果没有选择召唤师，随机选择一个召唤师
    if nil == self.teamSummonerId or self.teamSummonerId <= 0 then
        math.randomseed(os.time())
        local ran = math.random(#self.summoners)
        self:onSummonerIconClick(self.summoners[ran], true)
    end

    -- 如果队伍不满
    if #self.teamHeroIds < maxHeros then
        -- 如果还有英雄，找出剩下的未出战的英雄
        local leftHeros = {}
        for k,v in pairs(self.heros or {}) do
            if not findValueInTable(self.teamHeroIds, v) then
                table.insert(leftHeros, v)
            end
        end
        if #leftHeros > 0 then
            local num = maxHeros - #self.teamHeroIds
            if num > #leftHeros then
                num = #leftHeros
            end
            for i=1, num do
                self:onHeroIconClick(leftHeros[i], true)
            end
        end
    end
end

-- 进入战斗回调
function UITeam:onBattle(obj)
    obj.soundId = nil
	local tip = nil
    if nil == self.teamSummonerId or self.teamSummonerId <= 0 then
		tip = 90
	elseif #self.teamHeroIds == 0 then
		tip = 91
	end
	if tip then
		-- 浮动文字提示
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(tip) or tip)
		return
	end

	-- 二次确认框
    local _maxHeros = maxHeros
    if self.teamMercenary and self.teamMercenary.heroId > 0 then
        _maxHeros = _maxHeros - 1
    end
	if #self.teamHeroIds < _maxHeros and #self.heros > #self.teamHeroIds then
        obj.soundId = MusicManager.commonSound.fail
        local args  = {}
        if self.style == 3 then
            args.msg = CommonHelper.getUIString(1510)
        else
            args.msg = CommonHelper.getUIString(92)
        end
        args.confirmFun = function()
            if self.onBattleCallback and "function" == type(self.onBattleCallback) then
                TeamHelper.setTeamInfo(self.teamId, self.teamSummonerId, self.teamHeroIds)
                if 3 == self.style then
                    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(273))
                end
                --
                table.sort(self.teamHeroIds or {}, sortTeamHeroByCost)
                self.onBattleCallback(self.teamSummonerId, self.teamHeroIds,
                    self.teamMercenary and self.teamMercenary.dyId or 0)
            end
        end
        UIManager.open(UIManager.UI.UIDialogBox, args)
	else
        if self.onBattleCallback and "function" == type(self.onBattleCallback) then
            TeamHelper.setTeamInfo(self.teamId, self.teamSummonerId, self.teamHeroIds)
            if 3 == self.style then
                CsbTools.addTipsToRunningScene(CommonHelper.getUIString(273))
            end
            --
            table.sort(self.teamHeroIds or {}, sortTeamHeroByCost)
            self.onBattleCallback(self.teamSummonerId, self.teamHeroIds,
                self.teamMercenary and self.teamMercenary.dyId or 0)
        end
	end
end

-- 关闭回调
function UITeam:onUIClose(obj)
    UIManager:close()
end

-- 下一个队伍
function UITeam:onNextTeam(obj)
    if self.teamId >= 3 then
        self.teamId = 1
    else
        self.teamId = self.teamId + 1
    end
    self.teamSummonerId = TeamHelper.getTeamSummoner(self.teamId)
    self.teamHeroIds = TeamHelper.getTeamHeros(self.teamId)
    getChild(self, "TeamSet/MainPanel/TeamLogo/Text"):setString(getUILanConfItem(236) .. self.teamId)

    -- 初始化队伍英雄
    self:setTeamHeroIcon()
    -- 初始化队伍召唤师
    self:setTeamSummonerIcon()
    --
    heroScrollViewExtend:reloadData()
    --
    summonerScrollViewExtend:reloadData()
end

-- 上一个队伍
function UITeam:onLastTeam(obj)
    if self.teamId <= 1 then
        self.teamId = 3
    else
        self.teamId = self.teamId - 1
    end
    self.teamSummonerId = TeamHelper.getTeamSummoner(self.teamId)
    self.teamHeroIds = TeamHelper.getTeamHeros(self.teamId)
    getChild(self, "TeamSet/MainPanel/TeamLogo/Text"):setString(getUILanConfItem(236) .. self.teamId)

    -- 初始化队伍英雄
    self:setTeamHeroIcon()
    -- 初始化队伍召唤师
    self:setTeamSummonerIcon()
    --
    heroScrollViewExtend:reloadData()
    --
    summonerScrollViewExtend:reloadData()
end

-- 变更排序按钮
function UITeam:onSortModify(obj)
	if self.isShowSortList then
		self.isShowSortList = false
	else
		self.isShowSortList = true
	end
    self:reShowSortList()
end

-- 显示排序规则
function UITeam:reShowSortList()
	if self.isShowSortList then
        self.sortPanel:setTouchEnabled(true)
		CommonHelper.playCsbAnimate(self.sortCsb, csb.sort, "On", false, nil, true)
	else
        self.sortPanel:setTouchEnabled(false)
		CommonHelper.playCsbAnimate(self.sortCsb, csb.sort, "Off", false, nil, true)
	end
end

-- 排序类型按钮
function UITeam:onSortHeros(obj)
	self.isShowSortList = false
    self:reShowSortList()
    local sortType = obj:getTag()
    if curTabName == "HeroButton" then
        self.curHeroSortType = sortType
        self:reSortHerosID()
    elseif curTabName == "MercenaryButton" then
        self.curMercenarySortType = sortType
        self:reSortMercenarysID()
    end
end

-- 重新排序英雄
function UITeam:reSortHerosID()
    if sortType.Level == self.curHeroSortType then
        table.sort(self.heros or {}, sortHeroByLevel)
    elseif sortType.Cost == self.curHeroSortType then
        table.sort(self.heros or {}, sortHeroByCost)
    elseif sortType.Job == self.curHeroSortType then
        table.sort(self.heros or {}, sortHeroByJob)
    elseif sortType.Race == self.curHeroSortType then
        table.sort(self.heros or {}, sortHeroByRace)
    end
    heroScrollViewExtend:reloadData()
end

-- 重新排序佣兵
function UITeam:reSortMercenarysID()
    if sortType.Level == self.curMercenarySortType then
        table.sort(self.mercenarys or {}, sortMercenaryByLevel)
    elseif sortType.Cost == self.curMercenarySortType then
        table.sort(self.mercenarys or {}, sortMercenaryByCost)
    elseif sortType.Job == self.curMercenarySortType then
        table.sort(self.mercenarys or {}, sortMercenaryByJob)
    elseif sortType.Race == self.curMercenarySortType then
        table.sort(self.mercenarys or {}, sortMercenaryByRace)
    end
    mercenaryScrollViewExtend:reloadData()
end


return UITeam