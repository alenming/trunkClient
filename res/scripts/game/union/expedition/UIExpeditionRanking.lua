--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征伤害排行榜
** 应  用:
********************************************************************/
--]]
local scrollViewExtend = require("common.ScrollViewExtend").new()
local PropTips = require("game.comm.PropTips")

local expeditionModel = getGameModel():getExpeditionModel()
local rankCsbTag = {
    [1] = "One",
    [2] = "Two",
    [3] = "Three",
    [4] = "Other",
}

local UIExpeditionRanking = class("UIExpeditionRanking", function()
    return require("common.UIView").new()
end)

function UIExpeditionRanking:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionRanking:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionRanking.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 退出按钮
    local backButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(backButton, handler(self, self.onClick))
    
    -- 语言包相关
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/BarImage1/TitleFont"):setString(CommonHelper.getUIString(2025))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/Tips1"):setString(CommonHelper.getUIString(2030))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/LevelTitle"):setString(CommonHelper.getUIString(2026))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/NameTitle"):setString(CommonHelper.getUIString(2027))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/JobTitle"):setString(CommonHelper.getUIString(2028))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/StateTitle"):setString(CommonHelper.getUIString(2029))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/ActiveTitle"):setString(CommonHelper.getUIString(2031))
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/Tips2"):setString(CommonHelper.getUIString(2032))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionRanking:onOpen(openerUIID, ...)
    self.propTips = PropTips.new()

    local mapName = CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/StageName")
    mapName:setString("")
    self.scrollView = CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/RankingListPanel/PlayerScrollView")
    self.scrollView:removeAllChildren()
    self.scrollView:setScrollBarEnabled(false)

    local mapId = expeditionModel:getRankMapId()
    if mapId < 0 then return end
    local mapConf = getExpeditionMapConf(mapId)
    if not mapConf then return end
    self.mapConf = mapConf

    -- 地图名称
    mapName:setString(CommonHelper.getStageString(mapConf.mapName))
    -- 排行榜列表
    self:initScrollView()
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionRanking:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionRanking:onClose()
    scrollViewExtend:removeAllChild()

    if self.propTips then
        self.propTips:removePropAllTips()
        self.propTips = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionRanking:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIExpeditionRanking:onClick(obj)
    local objName = obj:getName()
    if objName == "BackButton" then             -- 返回
        UIManager.close()
    elseif objName == "AwradBoxButton" then
        local awardId = obj.awardId
        if awardId > 0 then
        
        end
    end
end

-- 初始化排行榜列表
function UIExpeditionRanking:initScrollView()
    local rankList = expeditionModel:getRankList() or {}
    self.maxHurt = rankList[1] and rankList[1].damage or 1
    self.rankList = {}
    for i, v in pairs(rankList or {}) do
        table.insert(self.rankList, v)
    end
    local csb = getResManager():getCsbNode(ResConfig.UIExpeditionRanking.Csb2.rankItem)
    local cell = CsbTools.getChildFromPath(csb, "PlayerBarPanel")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = #self.rankList,               -- 初始节点个数
        maxCellCount    = #self.rankList,               -- 最大节点个数
        csbName         = ResConfig.UIExpeditionRanking.Csb2.rankItem, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = nil,                          -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.scrollView,              -- 滚动区域
        distanceX       = 0,                            -- 节点X轴间距
        distanceY       = 0,                            -- 节点Y轴间距
        offsetX         = 0,                            -- 第一列的偏移
        offsetY         = 10,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setRankItemData),  -- 设置节点数据回调函数
    }
    scrollViewExtend:init(tabParam)
    scrollViewExtend:create()
    scrollViewExtend:reloadData()
end

function UIExpeditionRanking:setRankItemData(csb, i)
    local data = self.rankList[i]
    if not data then
        csb:setVisible(false)
        return
    end

    local myRank = expeditionModel:getMyRank()
    local csbName = "ui_new/g_gamehall/g_guild/expedmap/RankingBar.csb"
    if myRank == data.index then
        CommonHelper.playCsbAnimation(csb, "Self", false)
    else
        CommonHelper.playCsbAnimation(csb, "Normal", false)
    end
    -- 奖励id
    local awardId = 0
    local mapConf = self.mapConf
    -- 名次
    local rankNode = CsbTools.getChildFromPath(csb, "PlayerBarPanel/RankingNum")
    local index = CsbTools.getChildFromPath(rankNode, "RankingPanel/RankingNum")
    index:setString(data.index)
    if data.index > 0 and data.index < 4 then
        awardId = mapConf.RewardExtra[data.index]
        CommonHelper.playCsbAnimation(rankNode, rankCsbTag[data.index], false, nil)
    else
        awardId = mapConf.RewardExtra[4]
        CommonHelper.playCsbAnimation(rankNode, rankCsbTag[4], false, nil)
    end
    -- 礼包按钮
    local boxButton = CsbTools.getChildFromPath(csb, "PlayerBarPanel/AwradBoxButton")
    local propConf = getPropConfItem(awardId)
    if propConf then
        -- 道具tips
        self.propTips:addPropTips(boxButton, propConf)
        boxButton:loadTextures(propConf.Icon, nil, nil, 1)
        boxButton:setVisible(true)
    else
        boxButton:setVisible(false)
    end
    -- 名称
    local name = CsbTools.getChildFromPath(csb, "PlayerBarPanel/NameText")
    name:setString(data.name)
    -- 伤害
    local hurt = CsbTools.getChildFromPath(csb, "PlayerBarPanel/HurtsNum")
    hurt:setString(data.damage)
    local loadingBar = CsbTools.getChildFromPath(csb, "PlayerBarPanel/HurtsLoadingBar")
    loadingBar:setPercent((data.damage / self.maxHurt) * 100)
    -- 召唤师
    local summoner = CsbTools.getChildFromPath(csb, "PlayerBarPanel/Head_0/HeadPanel/IconImage")
    local heroConf = getHeroConfItem(data.summonerID)
    if not heroConf then
        print("can't find summondid", data.summonerID)
        return
    end

    CsbTools.replaceImg(summoner, heroConf.Common.HeadIcon)
    CsbTools.getChildFromPath(csb, "PlayerBarPanel/Head_0/HeadPanel/LevelNum"):setVisible(false)
    -- 英雄
    for i = 1, 7 do
        local heroNode = CsbTools.getChildFromPath(csb, "PlayerBarPanel/Head_" .. i)
        CsbTools.getChildFromPath(csb, "PlayerBarPanel/Head_" .. i .."/HeadPanel/LevelNum"):setVisible(false)
        local id = data.heroIDs[i]
        local star = data.heroStars[i]
        local soldierConf = getSoldierConfItem(id, star)
        if soldierConf and "" ~= soldierConf.Common.HeadIcon then
            local heroIcon = CsbTools.getChildFromPath(heroNode, "HeadPanel/IconImage")
            CsbTools.replaceImg(heroIcon, soldierConf.Common.HeadIcon)
            --
            local starConf= getSoldierStarSettingConfItem(star)
            if starConf then
                local heroBack = CsbTools.getChildFromPath(heroNode, "HeadPanel/HeroBg")
                CsbTools.replaceImg(heroBg, starConf.HeadboxBgRes)
                local heroFrame = CsbTools.getChildFromPath(heroNode, "HeadPanel/LvImage")
                CsbTools.replaceImg(heroFrame, starConf.HeadboxRes)
            end
            heroNode:setVisible(true)
        else
            heroNode:setVisible(false)
        end
    end   
    -- 蓝钻
    CommonHelper.showBlueDiamond(CsbTools.getChildFromPath(csb, "PlayerBarPanel/TencentLogo"),
        data.blueType, data.blueLv)
end

return UIExpeditionRanking