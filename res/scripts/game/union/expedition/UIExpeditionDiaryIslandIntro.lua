local scheduler = require("framework.scheduler")  

local UIExpeditionDiaryIslandIntro = class("UIExpeditionDiaryIslandIntro", function()
    return require("common.UIView").new()
end)

function UIExpeditionDiaryIslandIntro:ctor()
	self.mUnionModel = getGameModel():getUnionModel()
    self.mUserModel = getGameModel():getUserModel()
end

function UIExpeditionDiaryIslandIntro:init()
	self.rootPath = ResConfig.UIExpeditionDiaryIslandIntro.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.mMainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    self.mMapPanel = CsbTools.getChildFromPath(self.mMainPanel, "MapPanel")
    self.mTitleText = CsbTools.getChildFromPath(self.mMapPanel, "TitleText")
    self.mTextScrollView = CsbTools.getChildFromPath(self.mMapPanel, "TextScrollView")
    self.mIntroText = CsbTools.getChildFromPath(self.mTextScrollView, "IntroText")
    self.mEnemyListView = CsbTools.getChildFromPath(self.mMapPanel, "EnemyListView")
    self.mRangeTime = CsbTools.getChildFromPath(self.mMapPanel, "RangeTime")
    self.mOverTime = CsbTools.getChildFromPath(self.mMapPanel, "OverTime")

    self.mTime = CsbTools.getChildFromPath(self.root, "Time")
    self.mEnergInfo = CsbTools.getChildFromPath(self.root, "EnergInfo")
    self.mGemInfo = CsbTools.getChildFromPath(self.root, "GemInfo")
    self.mGoldInfo = CsbTools.getChildFromPath(self.root, "GoldInfo")

    self.mBackButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(self.mBackButton, handler(self, self.onClick))

    self.mRightButton = CsbTools.getChildFromPath(self.root, "RightButton")
    CsbTools.initButton(self.mRightButton, handler(self, self.onClick))

    self.mLeftButton = CsbTools.getChildFromPath(self.root, "LeftButton")
    CsbTools.initButton(self.mLeftButton, handler(self, self.onClick))

    -- 调整介绍文字的大小
    local originSize = self.mIntroText:getContentSize()
    local newSize = cc.size(originSize.width, 800)
    self.mIntroText:setContentSize(newSize)
    self.mIntroText:setPositionY(newSize.height)
    self.mTextScrollView:setInnerContainerSize(newSize)

    self.mEnemyListView:setItemsMargin(5)
    self.mEnemyListView:setScrollBarEnabled(false)
end

function UIExpeditionDiaryIslandIntro:initTime()
    self.mTime:setString(os.date("%H:%M"))
    self.mSchedulerHandler = scheduler.scheduleGlobal(function()
        self.mTime:setString(os.date("%H:%M"))
    end, 1)
end

function UIExpeditionDiaryIslandIntro:onOpen(_, areaId)
    self:updateGold()
    self:updateDiamond()
    self:setArea(areaId)

    self:initTime()
end

function UIExpeditionDiaryIslandIntro:onClose()
    scheduler.unscheduleGlobal(self.mSchedulerHandler)
end

function UIExpeditionDiaryIslandIntro:onClick(obj)
	local name = obj:getName()
	if name == "BackButton" then
		UIManager.close()
    elseif name == "RightButton" then
        local cfgExpdBook = getExpeditionBookItem(self.mAreaId + 1)
        if cfgExpdBook then
            local cfgExpd = getExpeditionItem(self.mAreaId + 1)
            if cfgExpd and self.mUnionModel:getUnionLv() >= cfgExpd.Expedition_Level then
                self:setArea(self.mAreaId + 1)
            end
        end
    elseif name == "LeftButton" then
        if getExpeditionBookItem(self.mAreaId - 1) then
            self:setArea(self.mAreaId - 1)
        end
	end
end

function UIExpeditionDiaryIslandIntro:setArea(arenaId)
    self.mAreaId = arenaId

    local cfgExpd = getExpeditionItem(self.mAreaId)
    local cfgExpdBook = getExpeditionBookItem(self.mAreaId)

    -- 设置区域名字
    self.mTitleText:setString(getStageLanConfItem(cfgExpd.Expedition_Name))

    -- 设置区域介绍
    self.mIntroText:setString(getStageLanConfItem(cfgExpd.Expedition_Desc))

    -- 设置远征时间
    self.mRangeTime:setString(string.format(getUILanConfItem(2052), cfgExpd.Expedition_FightTime / 60 / 60))
    self.mOverTime:setString(string.format(getUILanConfItem(2052), cfgExpd.Expedition_RestTime / 60 / 60))
    
    -- 设置人物列表
    self.mEnemyListView:removeAllItems()
    for i, _ in ipairs(cfgExpdBook.Role) do
        local itemView = self:createEnemyListViewItem(i)
        self.mEnemyListView:pushBackCustomItem(itemView)
    end
end

function UIExpeditionDiaryIslandIntro:createEnemyListViewItem(roleIndex)
    local cfgExpdBook = getExpeditionBookItem(self.mAreaId)
    local roleCfg = cfgExpdBook.Role[roleIndex]

    local itemView = require("game.union.expedition.UIExpeditionEnemyListViewItem").new()
    itemView:setRoleCfg(roleCfg)
    itemView:setClickCallback(function () 
        UIManager.open(UIManager.UI.UIExpeditionEnemyIntro, self.mAreaId, roleIndex)
    end)
    return WidgetExtend.wrapNodeWithWidget(itemView)
end

function UIExpeditionDiaryIslandIntro:updateGold()
    local gold = self.mUserModel:getGold()
    local label = CsbTools.getChildFromPath(self.mGoldInfo, "GoldPanel/GoldCountLabel")
    label:setString(gold)
end

function UIExpeditionDiaryIslandIntro:updateDiamond()
    local diamond = self.mUserModel:getDiamond()
    local label = CsbTools.getChildFromPath(self.mGemInfo, "GemPanel/GemCountLabel")
    label:setString(diamond)
end

return UIExpeditionDiaryIslandIntro