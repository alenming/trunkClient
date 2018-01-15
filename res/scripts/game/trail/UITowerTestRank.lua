--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local UITowerTestRank = class("UITowerTestRank", function()
    return require("common.UIView").new()
end)

require("game.rank.RankData")

local rankItem = ResConfig.UITowerTestRank.Csb2.item

--构造函数
function UITowerTestRank:ctor()
    self.rootPath = ResConfig.UITowerTestRank.Csb2.main
    self.root = cc.CSLoader:createNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    back:addClickEventListener(function()
        UIManager.close()
    end)

    local questionButton = getChild(self.root, "MainPanel/MovePanel/QuestionButton")
    questionButton:addClickEventListener(function()
        UIManager.open(UIManager.UI.UITowerTestRule, CommonHelper.getUIString(2204), CommonHelper.getUIString(2203))
    end)

    self.scroll = getChild(self.root, "MainPanel/MovePanel/RankingItemScrollView")
    self.mMyRankingNum = getChild(self.root, "MainPanel/MovePanel/MyRankingNum")
    self.mHighestTowerNum = getChild(self.root, "MainPanel/MovePanel/HighestTowerNum")

        -- 排行数据列表
    local itemCsb = getResManager():getCsbNode(rankItem)
    self.itemSize = CsbTools.getChildFromPath(itemCsb, "RankingItem"):getContentSize()
    itemCsb:cleanup()
    self.scroll:setScrollBarEnabled(false)
    self.scroll:removeAllChildren()

    self.itemsCache = {}
    self.items = {}
end

function UITowerTestRank:init()

end


function UITowerTestRank:onOpen()
    self.rankData = {}
    self.showPart = RankData.rankType.tower

            -- 清除本UI获取数据的返回回调
    RankData.clearUIAllCallFunc(UIManager.UI.UITowerTestRank)
    RankData.getRankData(self.showPart, UIManager.UI.UITowerTestRank, function(rankInfo)
        self.rankData[self.showPart] = rankInfo
        -- 滚动列表下自己的信息值刷新
        self:refreshSelfRank()
        -- 显示当前类型排行榜数据
        self:starShowRank()
    end)
end


-- 刷新排行榜数据
function UITowerTestRank:refreshSelfRank()

    local info = RankData.data[self.showPart].selfInfo

    if info.index == 0 then
        self.mMyRankingNum:setString(CommonHelper.getUIString(1372))
    else
        self.mMyRankingNum:setString(info.index)
    end
    self.mHighestTowerNum:setString(info.maxFloor)
end

-- 开始显示排行榜
function UITowerTestRank:starShowRank()

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

-- 设置排行榜列表信息
function UITowerTestRank:setItemInfo(itemCsb, i)
    local itemPanel     = CsbTools.getChildFromPath(itemCsb, "RankingItem")
    
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
function UITowerTestRank:initCardCsb(itemCsb, i)
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
    CommonHelper.playCsbAnimate(itemCsb, rankItem, info.isSelf and "Self" or "Normal", false, nil, true)
    emblemPanel:setVisible(false)
    iconPanel:setVisible(true)

    if self.showPart == RankData.rankType.tower then
        heroLvLab:setString(info.userLevel)
        lab1:setString(info.heroName)
        lab2:setString(info.score)
        lab3:setString(info.unionName)
        if getSystemHeadIconItem()[info.headID] then
            CsbTools.replaceImg(heroIconImg, getSystemHeadIconItem()[info.headID].IconName)
        end
    end
end

function UITowerTestRank:getNewScrollItem()
    local itemNode = nil
    if #self.itemsCache ~= 0 then
        itemNode = self.itemsCache[1]
        table.remove(self.itemsCache, 1)
        itemNode:setVisible(true)
    else
        itemNode = getResManager():cloneCsbNode(rankItem)
        self.scroll:addChild(itemNode)
    end

    return itemNode
end

return UITowerTestRank

--endregion
