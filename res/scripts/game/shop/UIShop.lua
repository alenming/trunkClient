--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  商店主界面
** 应  用:
********************************************************************/
--]]
local ScrollViewExtend = require("common.ScrollViewExtend").new()
local scheduler = require("framework.scheduler")
local SdkManager = require("common.sdkmanager.SdkManager")

local userModel = getGameModel():getUserModel()
local shopModel = getGameModel():getShopModel()

local UnionShopType = 4

local UIShop = class("UIShop", function()
    return require("common.UIView").new()
end)

UIShop.coinType = {
    gold    = 1,    -- 金币
    arena   = 2,    -- 竞技场
    tower   = 3,    -- 爬塔
    diamond = 4,    -- 钻石
    union   = 5,    -- 公会币
}

UIShop.coinImage = {
    [1] = "pub_gold.png",       -- 金币
    [2] = "pub_fightcoin.png",  -- 竞技场
    [3] = "pub_enfragment.png", -- 爬塔
    [4] = "pub_gem.png",        -- 钻石
    [5] = "pub_points.png",     -- 公会币
    [6] = "pub_rmb.png",        -- 人民币
}

-- 构造函数
function UIShop:ctor()
    -------------------------- Data --------------------------
    self.curType = 0            -- 当前商店类型
    self.shopConfData = {}      -- 商店配置表数据
    self.commonShopData = {}     -- 商店模型数据
    -- 购买物品用到的数据
    self.buyCount = 0       -- 物品购买个数
    self.buyMax = 0         -- 物品最大个数
    self.buyIndex = 0       -- 购买物品的索引

    -------------------------- Node --------------------------
    self.rootPath = ResConfig.UIShop.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.maskPanel = getChild(self.root, "Mask")        -- 屏蔽层
    
    local btnBack = getChild(self.root, "BackButton")   -- 关闭按钮
    CsbTools.initButton(btnBack, handler(self, self.onClick))

    self.coinNode   = getChild(self.root, "Coin")       -- 货币类型
    self.coinBg     = getChild(self.coinNode, "Coin/Image_bg")
    self.coinImg    = getChild(self.coinNode, "Coin/CoinImage")
    self.coinLab    = getChild(self.coinNode, "Coin/CoinLabel")
    self.coinBtn    = getChild(self.coinNode, "Coin/CoinButton")
    CsbTools.initButton(self.coinBtn, handler(self, self.onClick))
    --
    self.diamondNode    = getChild(self.root, "Diamond")    -- 钻石
    self.diamondBg      = getChild(self.diamondNode, "Diamond/Image_4_0_0")
    self.diamondImg     = getChild(self.diamondNode, "Diamond/DiamondImage")
    self.diamondLab     = getChild(self.diamondNode, "Diamond/PowerLabel_0")
    self.diamondBtn     = getChild(self.diamondNode, "Diamond/PowerButton_0")
    CsbTools.initButton(self.diamondBtn, handler(self, self.onClick))

    self.mainPanel      = getChild(self.root, "MainPanel")                      -- 商店界面主Panel
    self.titleText      = getChild(self.mainPanel, "Image_Tittle/TittleText")   -- 商店名称
    --
    self.refreshText    = getChild(self.mainPanel, "Text_1")
    self.refreshTime    = getChild(self.mainPanel, "Time")                      -- 下次刷新时间
    self.refreshBtn     = getChild(self.mainPanel, "RefreshButton")             -- 刷新按钮
    CsbTools.initButton(self.refreshBtn, handler(self, self.onClick))
    self.refreshBtnName = getChild(self.refreshBtn, "ButtomName")
    -- 语言包
    self.refreshText:setString(CommonHelper.getUIString(77))
    self.refreshBtnName:setString(CommonHelper.getUIString(109))
    --
    self.scrollView     = getChild(self.mainPanel, "ShopScrollView")            -- 商品滚动容器
    self.viewSize       = self.scrollView:getContentSize()                      -- 滚动容器可视区域大小
    self.cellCSB        = ResConfig.UIShop.Csb2.cell                            -- 商品节点csb名称
    self.cellTable      = {}                                                    -- 商品节点table
    --
    self.btnCSB         = ResConfig.UIShop.Csb2.btn                             -- 商店按钮CSB
    
    self.questionButton = getChild(self.mainPanel, "QuestionButton")
    CsbTools.initButton(self.questionButton, handler(self, self.onClick))
    self.unionShopTips = getChild(self.mainPanel, "GuildShopTips")

    self.mMask = CsbTools.getChildFromPath(self.root, "Mask")

    self.mOpenVIPPanel = CsbTools.getChildFromPath(self.mainPanel, "OpenVipPanel")
    self.mOpenVIPBtn = CsbTools.getChildFromPath(self.mOpenVIPPanel, "OpenVipButton")
    CsbTools.initButton(self.mOpenVIPBtn, handler(self, self.onClick))
end

-- 当界面被创建时回调
-- 只初始化一次
function UIShop:init()

end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIShop:onOpen(openerUIID, shopType)
    self.curType = shopType
    self.eqDynID = nil      -- 装备的动态ID
    -- 钻石商店数据
    self.diamondShopData = getDiamondShopConfData()
    -- 公会商店数据
    self.unionShopData = shopModel:getUnionShopData()
    -- 普通商店数据
    self.commonShopData = shopModel:getShopModelData(shopType) or {}

    self.maskPanel:setVisible(false)
    --播放美女动画
    self.shopGirl = getChild(self.mainPanel, "Image_Tittle/Node_Girl")    -- 商店美女
    self.girlSpine = nil
    for k, v in pairs(ResConfig.UIShop.Spine) do
        self.girlSpine = getResManager():createSpine(k)
        self.girlSpine:setName("girlSpine")
        self.shopGirl:addChild(self.girlSpine)
    end
    if self.girlSpine then
        self.girlSpine:setAnimation(0, "Stand1", true)
    end
    -- 创建商店按钮
    self:initTabButton()
    -- 设置商店名称
    self:setShopTitle()
    -- 创建商店物品节点
    self:initShopScrollview()
    self:showUnionShopTips()

    print("============================ UIShop:onOpen")
    -- 初始化定时器
    self:initTimer()
    self:initEvent()
    self:initNetwork()

    -- 金币(神秘)商店红点
    self.coinRedPoint:setVisible(RedPointHelper.getSystemRedPoint(RedPointHelper.System.Shop))
    self.coinNode:setVisible(false)
    self.diamondNode:setVisible(false)

    self.mOpenVIPPanel:setVisible(gIsQQHall)
end

-- 每次界面Open动画播放完毕时回调
function UIShop:onOpenAniOver()
    -- 设置货币面板
    self:setMoneyPanel()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIShop:onClose()
    self.eqDynID = nil
    self:removeEvent()
    self:removeNetwork()

    if self.schedulerHandler then
        scheduler.unscheduleGlobal(self.schedulerHandler)
        self.schedulerHandler = nil
    end

    -- 场景切换动画显示
    self.shopGirl:removeChildByName("girlSpine")
    for i = 1, #self.shopConfData + 1 do
        self.mainPanel:removeChildByTag(i, true)
    end
    ScrollViewExtend:removeAllChild()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIShop:onTop(preUIID, nIndex, num)
    if nIndex and num then
        if self.curType == ShopType.UnionShop then
            self:unionBuyCallback(nIndex, num)
        else
            self:buyCallback(nIndex, num)
        end
    end
    self.maskPanel:setVisible(false)
end

-- 当前界面按钮点击回调
function UIShop:onClick(obj)
    local btnName = obj:getName()
    if btnName == "BackButton" then             -- 返回
        UIManager.close()
    elseif btnName == "CoinButton" then         -- 购买金币
        UIManager.open(UIManager.UI.UIGold)
    elseif btnName == "PowerButton_0" then      -- 购买钻石
        if self.curType ~= ShopType.DiamondShop then
            local node = self.mainPanel:getChildByTag(ShopType.DiamondShop)
            local button = getChild(node, "ButtonPanel")
            self:onTabButtonClick(button)
        end
    elseif btnName == "RefreshButton" then      -- 刷新
        self.maskPanel:setVisible(true)
        UIManager.open(UIManager.UI.UIShopRefresh, self.curType, handler(self, self.acceptAutoRefreshCmd))
    elseif btnName == "QuestionButton" then
        UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2049))
    elseif btnName == "OpenVipButton" then
        SdkManager.openVip()
    end
end

-- 设置货币面板
function UIShop:setMoneyPanel()
    self.coinNode:setVisible(false)
    self.diamondNode:setVisible(false)

    if self.curType == ShopType.DiamondShop then   -- 钻石商店
        self.coinNode:setVisible(true)
        self.coinBtn:setVisible(true)
        self.coinImg:loadTexture(UIShop.coinImage[1], 1)
        self.coinLab:setString(tostring(userModel:getGold()))

        self.diamondNode:setVisible(true)
        self.diamondLab:setString(tostring(userModel:getDiamond()))
    else
        local coinType = {}
        if self.shopConfData then
            local curConfData = self.shopConfData[self.curType]
            if curConfData then
                coinType = curConfData.tCoinType
            end
        end
        for i, v in pairs(coinType or {}) do
            if v == UIShop.coinType.gold then
                self.coinNode:setVisible(true)
                self.coinBtn:setVisible(true)
                self.coinImg:loadTexture(UIShop.coinImage[v], 1)
                self.coinLab:setString(tostring(userModel:getGold()))
            elseif v == UIShop.coinType.arena then
                self.coinNode:setVisible(true)
                self.coinBtn:setVisible(false)
                self.coinImg:loadTexture(UIShop.coinImage[v], 1)
                self.coinLab:setString(tostring(userModel:getPVPCoin()))
            elseif v == UIShop.coinType.tower then
                self.coinNode:setVisible(true)
                self.coinBtn:setVisible(false)
                self.coinImg:loadTexture(UIShop.coinImage[v], 1)
                self.coinLab:setString(tostring(userModel:getTowerCoin()))
            elseif v == UIShop.coinType.union then
                self.coinNode:setVisible(true)
                self.coinBtn:setVisible(false)
                self.coinImg:loadTexture(UIShop.coinImage[v], 1)
                self.coinLab:setString(tostring(userModel:getUnionContrib()))
            elseif v == UIShop.coinType.diamond then
                self.diamondNode:setVisible(true)
                self.diamondLab:setString(tostring(userModel:getDiamond()))
            end
        end
    end
end

-- 设置商店名称
function UIShop:setShopTitle()
    -- 钻石商店
    if self.curType == ShopType.DiamondShop then
        self.titleText:setString(CommonHelper.getUIString(1303))
    else
        local data = self.shopConfData[self.curType] or {}
        self.titleText:setString(CommonHelper.getUIString(data.nName or 0))
    end
end


---------------------------------------------------------------------
-- 创建商店物品节点
function UIShop:initShopScrollview()
    local csb = getResManager():getCsbNode(self.cellCSB)
    local cell = getChild(csb, "ShopItem")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    local defaultCount = 0      -- 初始节点个数
    local maxCellCount = 0      -- 最大节点个数
    if self.curType == ShopType.DiamondShop then   -- 钻石商店
        if self.diamondShopData then
            -- defaultCount = #(self.diamondShopData)
            -- maxCellCount = #(self.diamondShopData)
            defaultCount = 6
            maxCellCount = 6
        end
    elseif self.curType == ShopType.UnionShop then -- 公会商店
        defaultCount = shopModel:getUnionGoodsCount()
        maxCellCount = shopModel:getUnionGoodsCount()
    else
        if self.commonShopData then
            defaultCount    = self.commonShopData.nCurCount
            maxCellCount    = self.commonShopData.nCurCount
        end
    end

    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 2,                            -- 每行节点个数
        defaultCount    = defaultCount,                 -- 初始节点个数
        maxCellCount    = maxCellCount,                 -- 最大节点个数
        csbName         = self.cellCSB,                 -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "ShopItem",                   -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.scrollView,              -- 滚动区域
        distanceX       = 6,                            -- 节点X轴间距
        distanceY       = 24,                           -- 节点Y轴间距
        offsetX         = 9,                            -- 第一列的偏移
        offsetY         = 6,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setCellData),  -- 设置节点数据回调函数
    }
    ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
    ScrollViewExtend:reloadData()
end

-- 设置节点数据
function UIShop:setCellData(csbNode, idx)
    if self.curType == ShopType.DiamondShop then     -- 钻石商店
        self:setDiamondCellData(csbNode, idx)
    elseif self.curType == ShopType.UnionShop then   -- 公会商店
        self:setUnionCellData(csbNode, idx)
    else
        self:setCommonCellData(csbNode, idx)
    end
end

-- 设置普通商店的节点数据
function UIShop:setCommonCellData(csbNode, idx)
    csbNode:setTag(idx)
    if nil == self.commonShopData then
        csbNode:setVisible(false)
        return
    end
    local goodsData = self.commonShopData.GoodsData
    if nil == goodsData then
        csbNode:setVisible(false)
        return
    end
    local data = goodsData[idx]
    if nil == data then
        csbNode:setVisible(false)
        return
    end

    local cell = getChild(csbNode, "ShopItem")
    cell.data  = data
    cell.index = idx
    cell:addTouchEventListener(handler(self, self.onCommonCellTouch))
    getChild(cell, "AwardLogo"):setVisible(false)
    getChild(cell, "RareLogo"):setVisible(false)

    local num       = getChild(cell, "Sum")
    local discount  = getChild(cell, "Discount")
    local sale      = getChild(discount, "DiscountNum")
    local price     = getChild(cell, "GoldSum")
    local coin      = getChild(cell, "GoldImage")
    local soldOut   = getChild(cell, "received_log_1")
    local soldText  = getChild(soldOut, "Text_1")
    -- 道具的配置表信息
    local propConf = getPropConfItem(data.nGoodsID)
    if propConf then
        -- 道具图片
        local allItem = getChild(cell, "AllItem")
        UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
        -- 道具名称
        local name = getChild(cell, "NameText")
        local color = getItemLevelSettingItem(propConf.Quality).Color
        name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
        if 3 == propConf.Type or 4 == propConf.Type then
            name:setString(getHSLanConfItem(propConf.Name))
        else
            name:setString(getPropLanConfItem(propConf.Name))
        end
    end
    if data.nSale < 100 then
        sale:setString(string.format("%0.1f%s", data.nSale/10, CommonHelper.getUIString(1307)))
        discount:setVisible(true)
    else
        discount:setVisible(false)
    end
    num:setString(tostring(data.nGoodsNum))
    price:setString(string.format("%d", math.ceil(data.nCoinNum * (data.nSale/100))))
    coin:setSpriteFrame(UIShop.coinImage[data.nCoinType])

    -- 售罄了
    if data.nGoodsNum <= 0 then
        cell:setTouchEnabled(false)
        soldOut:setVisible(true)
        soldText:setString(CommonHelper.getUIString(76))
    else
        cell:setTouchEnabled(true)
        soldOut:setVisible(false)
    end
end
-- 普通商店物品点击回调
function UIShop:onCommonCellTouch(obj, eventType)
    if 2 == eventType then
        MusicManager.playSoundEffect(obj:getName())
        local beginPos = obj:getTouchBeganPosition()
        local endPos = obj:getTouchEndPosition()
        if cc.pGetDistance(beginPos, endPos) > 40 then
            return
        end
        CommonHelper.playCsbAnimate(obj, self.cellCSB, "OnAnimation", false, function()
            CommonHelper.playCsbAnimate(obj, self.cellCSB, "Normal", false)
        end)

        local data = obj.data
        if nil == data then
            print("Error: UIShop:onCommonCellTouch(), data==nil")
            return
        end

        if not self:checkBuySummoner(data.nGoodsID) then
            return
        end

        self.maskPanel:setVisible(true)

        local propConf = getPropConfItem(data.nGoodsID)
        -- 英雄卡牌(3),召唤师卡片(4)类型道具
        if 3 == propConf.Type  or 4 == propConf.Type then
            UIManager.open(UIManager.UI.UIShopBuyHero, self.curType, obj.data, obj.index)
        -- 装备生成器类型(13)道具
        elseif 13 == propConf.Type then
            UIManager.open(UIManager.UI.UIShopBuyEquip, self.curType, obj.data, obj.index)
        -- 装备材料(2),经验书(5),技能书(6),金币袋子(7),体力袋子(8),经验袋子(9),钻石袋子(10),宝箱(11),升星材料(12)类型道具
        else
            UIManager.open(UIManager.UI.UIShopBuyMeterial, self.curType, obj.data, obj.index)
        end
    end
end

-- 设置钻石商店的节点数据
function UIShop:setDiamondCellData(csbNode, idx)
    csbNode:setTag(idx)
    if nil == self.diamondShopData then
        csbNode:setVisible(false)
        return
    end
    local data = self.diamondShopData[idx]
    if nil == data then
        csbNode:setVisible(false)
        return
    end

    local cell      = getChild(csbNode, "ShopItem")
    cell.data  = data
    cell.index = idx
    cell:addTouchEventListener(handler(self, self.onDiamondCellTouch))
    getChild(cell, "Discount"):setVisible(false)
    getChild(cell, "received_log_1"):setVisible(false)
    getChild(cell, "RareLogo"):setVisible(false)

    local allItem   = getChild(cell, "AllItem")
    CommonHelper.playCsbAnimate(allItem, "ui_new/g_gamehall/b_bag/PropItem.csb", "Prop", false, nil, true)
    local icon      = getChild(allItem, "MainPanel/Prop/Item/icon")
    icon:loadTexture(data.strPicName, 1)
    local num       = getChild(allItem, "MainPanel/Prop/Item/Num")
    num:setVisible(false)

    local name      = getChild(cell, "NameText")
    local diamond   = getChild(cell, "Sum")
    local price     = getChild(cell, "GoldSum")
    local coin      = getChild(cell, "GoldImage")
    name:setString(CommonHelper.getUIString(data.nNameLanID))
    if data.nDiamond <= 0 then
        diamond:setVisible(false)
        getChild(cell, "AwardLogo"):setVisible(false)
    else
        diamond:setString(tostring(data.nDiamond))
        diamond:setVisible(true)
        if shopModel:isFirstCharge(idx) then
            getChild(cell, "AwardLogo/AwardText"):setString(string.format(CommonHelper.getUIString(1724), data.nDiamond))
            getChild(cell, "AwardLogo"):setVisible(true)
        else
            getChild(cell, "AwardLogo"):setVisible(false)
        end
    end
    price:setString(tostring(data.nPrice))
    coin:setSpriteFrame(UIShop.coinImage[6])
end

-- 钻石商店物品点击回调
function UIShop:onDiamondCellTouch(obj, eventType)
    if 2 == eventType then
        local beginPos = obj:getTouchBeganPosition()
        local endPos = obj:getTouchEndPosition()
        if cc.pGetDistance(beginPos, endPos) > 40 then
            return
        end
        CommonHelper.playCsbAnimate(obj, self.cellCSB, "OnAnimation", false, function()
            CommonHelper.playCsbAnimate(obj, self.cellCSB, "Normal", false)
        end)

        SdkManager.payForProduct(obj.data)
    end
end

-- 设置公会商店的节点数据
function UIShop:setUnionCellData(csbNode, idx)
    csbNode:setTag(idx)
    if nil == self.unionShopData then
        csbNode:setVisible(false)
        return
    end
    local data = self.unionShopData[idx]
    if nil == data then
        csbNode:setVisible(false)
        return
    end

    local cell = getChild(csbNode, "ShopItem")
    cell.data  = data
    cell.index = idx
    cell:addTouchEventListener(handler(self, self.onCommonCellTouch))
    getChild(cell, "AwardLogo"):setVisible(false)

    local allItem   = getChild(cell, "AllItem")
    local name      = getChild(cell, "NameText")
    local num       = getChild(cell, "Sum")
    local discount  = getChild(cell, "Discount")
    local sale      = getChild(discount, "DiscountNum")
    local price     = getChild(cell, "GoldSum")
    local coin      = getChild(cell, "GoldImage")
    local soldOut   = getChild(cell, "received_log_1")
    local soldText  = getChild(soldOut, "Text_1")
    -- 道具的配置表信息
    local propConf = getPropConfItem(data.nGoodsID)
    if propConf then
        -- 道具图片
        UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
        -- 道具名称
        local color = getItemLevelSettingItem(propConf.Quality).Color
        name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
        if 3 == propConf.Type  or 4 == propConf.Type then
            name:setString(getHSLanConfItem(propConf.Name))
        else
            name:setString(getPropLanConfItem(propConf.Name))
        end
    end
    if data.nSale < 100 then
        sale:setString(string.format("%0.1f%s", data.nSale/10, CommonHelper.getUIString(1307)))
        discount:setVisible(true)
    else
        discount:setVisible(false)
    end
    num:setString(tostring(data.nGoodsNum))
    price:setString(string.format("%d", math.ceil(data.nCoinNum * (data.nSale/100))))
    coin:setSpriteFrame(UIShop.coinImage[data.nCoinType])
    -- 售罄了
    if data.nGoodsNum <= 0 then
        cell:setTouchEnabled(false)
        soldOut:setVisible(true)
        soldText:setString(CommonHelper.getUIString(76))
    else
        cell:setTouchEnabled(true)
        soldOut:setVisible(false)
    end
    -- 稀有度
    local rareLog = getChild(cell, "RareLogo")
    rareLog:setVisible(false)
    local goodsConf = getShopGood(data.nGoodsShopID)
    if goodsConf and goodsConf.Goods_kinds == 1 then
        local rareText = getChild(cell, "RareLogo/Text")
        rareText:setString(CommonHelper.getUIString(2044))
        rareLog:setVisible(true)
    end
end


---------------------------------------------------------------------
-- 创建商店按钮
function UIShop:initTabButton()
    -- 商店配置
    self.shopConfData = getShopConfData()
    local userLevel = userModel:getUserLevel()
    local startPosX = 890 - 110 * (#self.shopConfData + 1)
    for i = 1, #self.shopConfData + 1 do
        local node = getResManager():cloneCsbNode(self.btnCSB)
        node:setTag(i)
        node:setPosition(cc.p(startPosX + 110 * i, 40))
        self.mainPanel:addChild(node, 10 + i)
        if i == self.curType then
            CommonHelper.playCsbAnimate(node, self.btnCSB, "On", false)
        else
            CommonHelper.playCsbAnimate(node, self.btnCSB, "Normal", false)
        end
        --
        local button = getChild(node, "ButtonPanel")
        button:setTag(i)
        CsbTools.initButton(button, handler(self, self.onTabButtonClick))
        local buttonImage = getChild(button, "ButtonImage")
        local buttonName  = getChild(button, "NameText")
        if i <= #self.shopConfData then
            local data = self.shopConfData[i]
            CsbTools.replaceImg(buttonImage, data.strShopIcon)
            buttonName:setString(CommonHelper.getUIString(data.nName))
            -- 神秘商店红点
            if data.nShopType == ShopType.MysteryShop then
                self.coinRedPoint = getChild(button, "RedTipPoint")
            end
        -- 钻石商店
        else
            CsbTools.replaceImg(buttonImage, "ui_pnb_storegem.png")
            buttonName:setString(CommonHelper.getUIString(1303))
        end
    end
end

-- 商店按钮点击回调
function UIShop:onTabButtonClick(obj)
    local shopType = obj:getTag()
    if self.curType == shopType then return end
    -- 切换按钮状态
    local prevButton = self.mainPanel:getChildByTag(self.curType)
    prevButton:stopAllActions()
    CommonHelper.playCsbAnimate(prevButton, self.btnCSB, "Normal", false)
    self.curType = shopType
    local curButton = self.mainPanel:getChildByTag(self.curType)
    curButton:stopAllActions()
    CommonHelper.playCsbAnimate(curButton, self.btnCSB, "On", false)

    -- 设置货币面板
    self:setMoneyPanel()
    -- 设置商店名称
    self:setShopTitle()
    -- 刷新商店物品
    local num = 0
    -- 钻石商店
    if self.curType == ShopType.DiamondShop then
        -- num = self.diamondShopData and #(self.diamondShopData) or 0
        num = 6
    -- 公会商店
    elseif self.curType == ShopType.UnionShop then
        num = shopModel:getUnionGoodsCount()
        self.unionShopData = shopModel:getUnionShopData()
    -- 其他商店
    else
        self.commonShopData = shopModel:getShopModelData(shopType)
        num = self.commonShopData and self.commonShopData.nCurCount or 0
    end
    ScrollViewExtend:reloadList(num, num)
    -- 初始化定时器
    self:initTimer()
    --
    self:showUnionShopTips()
end


---------------------------------------------------------------------
-- 初始化定时器
function UIShop:initTimer()
    self.refreshText:setVisible(false)
    self.refreshTime:setVisible(false)
    self.refreshBtn:setVisible(false)
    self.questionButton:setVisible(false)
    --
    if self.curType == ShopType.DiamondShop then
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
    elseif self.curType == ShopType.UnionShop then
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
        self.refreshText:setString(CommonHelper.getUIString(2045))
        self.refreshText:setPosition(cc.p(800, 540))
        self.refreshText:setVisible(true)
        self.questionButton:setVisible(true)
    else
        if nil == self.schedulerHandler then
            self.schedulerHandler = scheduler.scheduleGlobal(handler(self, self.refreshTimeUpdate), 1)
        end
        self.refreshText:setString(CommonHelper.getUIString(77))
        self.refreshText:setPosition(cc.p(682, 532))
        self.refreshText:setVisible(true)
        self.refreshBtn:setVisible(true)
    end
end

-- 更新刷新时间
function UIShop:refreshTimeUpdate()
    local nowTime = getGameModel():getNow()
    if self.commonShopData and nowTime > self.commonShopData.nNextFreshTime then
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
        self:sendAutoRefreshCmd()
    else
        local delta = self.commonShopData.nNextFreshTime - nowTime
        local times = TimeHelper.gapTimeS(delta)
        self.refreshTime:setVisible(true)
        self.refreshTime:setString(
            string.format("%.02d", times.hour) .. ":" ..
            string.format("%.02d", times.min) .. ":" ..
            string.format("%.02d", times.sec))
    end
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIShop:initEvent()
    -- 添加充值成功事件监听
    self.eventRechargeSucessHandler = handler(self, self.onRechargeSucess)
    EventManager:addEventListener(GameEvents.EventRecharge, self.eventRechargeSucessHandler)    
    -- 添加生成装备事件监听
    self.eventAddEquipHandler = handler(self, self.onEventReceiveEquip)
    EventManager:addEventListener(GameEvents.EventReceiveEquip, self.eventAddEquipHandler)
    -- 添加金币刷新事件监听
    self.eventUpdateGoldHandler = handler(self, self.setMoneyPanel)
    EventManager:addEventListener(GameEvents.EventUpdateGold, self.eventUpdateGoldHandler)
    -- 添加钻石刷新事件监听
    self.eventUpdateDiamond = handler(self, self.setMoneyPanel)
    EventManager:addEventListener(GameEvents.EventUpdateDiamond, self.eventUpdateDiamond)
    -- 添加远征胜利事件监听(公会商店商品下架架)
    self.winHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionWin, self.winHandler)
    -- 添加公会商店购买事件监听
    self.eventUnionBuyHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionShopBuy, self.eventUnionBuyHandler)
    -- 添加公会商店刷新事件监听(公会商店商品上架)
    self.eventUnionFreshHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionShopFresh, self.eventUnionFreshHandler)
    -- 添加公会操作事件监听
    self.eventUnionFuncHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventUnionFunc, self.eventUnionFuncHandler)
end

-- 移除事件回调
function UIShop:removeEvent()
    -- 移除充值成功事件监听
    if self.eventRechargeSucessHandler then
        EventManager:removeEventListener(GameEvents.EventRecharge, self.eventRechargeSucessHandler)
        self.eventRechargeSucessHandler = nil
    end
    -- 移除生成装备事件监听
    if self.eventAddEquipHandler then
        EventManager:removeEventListener(GameEvents.EventReceiveEquip, self.eventAddEquipHandler)
        self.eventAddEquipHandler = nil
    end
    -- 移除金币刷新事件监听
    if self.eventUpdateGoldHandler then
        EventManager:removeEventListener(GameEvents.EventUpdateGold, self.eventUpdateGoldHandler)
        self.eventUpdateGoldHandler = nil
    end
    -- 移除钻石刷新事件监听
    if self.eventUpdateDiamond then
        EventManager:removeEventListener(GameEvents.EventUpdateDiamond, self.eventUpdateDiamond)
        self.eventUpdateDiamond = nil
    end
    -- 移除远征胜利事件监听(公会商品下架)
    if self.winHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionWin, self.winHandler)
        self.winHandler = nil
    end
    -- 移除公会商店购买事件监听
    if self.eventUnionBuyHandler then
        EventManager:removeEventListener(GameEvents.EventUnionShopBuy, self.eventUnionBuyHandler)
        self.eventUnionBuyHandler = nil
    end
    -- 移除公会商店刷新事件监听(公会商品上架)
    if self.eventUnionFreshHandler then
        EventManager:removeEventListener(GameEvents.EventUnionShopFresh, self.eventUnionFreshHandler)
        self.eventUnionFreshHandler = nil
    end
    -- 移除公会操作事件监听
    if self.eventUnionFuncHandler then
        EventManager:removeEventListener(GameEvents.EventUnionFunc, self.eventUnionFuncHandler)
        self.eventUnionFuncHandler = nil
    end
end

function UIShop:onRechargeSucess(eventName, args)
    local result = args.result
    local vipLv = args.vipLv
    local vipNum = args.vipNum
    local diamond = args.diamond  -- 如果是购买月卡下发的是月卡结束的时间戳
    local pID = args.pID

    print("result, vipLv, vipNum, diamond, pID", result, vipLv, vipNum, diamond, pID)

    if result == 1 then
        if pID ~= 7 and pID ~= 8 and pID ~= 9 then
            self:setCellData(self.scrollView:getChildByTag(pID), pID)
            self:setMoneyPanel()
        end
    end
end

-- 生成装备
function UIShop:onEventReceiveEquip(eventName, args)
    self.eqDynID = args.equipId
end

function UIShop:onEventCallback(eventName, args)
    if eventName == GameEvents.EventExpeditionWin or
       eventName == GameEvents.EventUnionShopBuy or
       eventName == GameEvents.EventUnionShopFresh then
       -- 公会商店
        if self.curType == ShopType.UnionShop then
            local num = shopModel:getUnionGoodsCount()
            self.unionShopData = shopModel:getUnionShopData()
            ScrollViewExtend:reloadList(num, num)
            --
            self:showUnionShopTips()
        end
    elseif eventName == GameEvents.EventUnionFunc then
        -- 被踢出公会
        if args.funcType == UnionHelper.FuncType.Kick then
            -- 公会商店
            if self.curType == ShopType.UnionShop then
                local num = shopModel:getUnionGoodsCount()
                self.unionShopData = shopModel:getUnionShopData()
                ScrollViewExtend:reloadList(num, num)
                --
                self:showUnionShopTips()
            end
        end
    end
end


---------------------------------------------------------------------
-- 初始化网络回调
function UIShop:initNetwork()
    -- 注册自动刷新的网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopRefreshSC)
    self.refreshHandler = handler(self, self.acceptAutoRefreshCmd)
    NetHelper.setResponeHandler(cmd, self.refreshHandler)
end

-- 移除网络回调
function UIShop:removeNetwork()
    -- 移除自动刷新的网络回调
    if self.refreshHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopRefreshSC)
        NetHelper.removeResponeHandler(cmd, self.refreshHandler)
        self.refreshHandler = nil
    end
end

-- 发送自动刷新请求
function UIShop:sendAutoRefreshCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopRefreshCS)
    buffData:writeChar(self.curType)     -- 商店类型
    buffData:writeChar(0)                -- 刷新类型, 自动：0， 手动：1
    NetHelper.request(buffData)
end

-- 接收自动刷新请求
function UIShop:acceptAutoRefreshCmd(mainCmd, subCmd, buffData)
    self.commonShopData = {}
    self.commonShopData.nFreshedCount  = buffData:readInt()
    self.commonShopData.nNextFreshTime = buffData:readInt()
    local flag = buffData:readChar()   --刷新类型
    self.commonShopData.nShopType      = buffData:readChar()
    self.commonShopData.nCurCount      = buffData:readChar()


    self.commonShopData.GoodsData = {}
    for i = 1, self.commonShopData.nCurCount do
        local goods = {}
        goods.nGoodsID      = buffData:readInt()
        goods.nGoodsNum     = buffData:readInt()
        goods.nCoinNum      = buffData:readInt()
        goods.nGoodsShopID  = buffData:readShort()
        goods.nSale         = buffData:readChar()
        goods.nCoinType     = buffData:readChar()
        goods.nIndex        = buffData:readChar()
        
        self.commonShopData.GoodsData[goods.nIndex] = goods
    end
    shopModel:setShopModelData(self.commonShopData)
    -- 刷新商店物品
    ScrollViewExtend:reloadList(self.commonShopData.nCurCount, self.commonShopData.nCurCount)
    if 1 == flag then
        local conf = getIncreasePayConfItem(self.commonShopData.nFreshedCount)
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -conf.FreshShopCost)
        -- 设置货币面板
        self:setMoneyPanel()
    end
    -- 初始化定时器
    self:initTimer()

    local uiShopBuy = UIManager.getUI(UIManager.UI.UIShopBuyMeterial) or
                      UIManager.getUI(UIManager.UI.UIShopBuyHero) or
                      UIManager.getUI(UIManager.UI.UIShopBuyEquip)
    if uiShopBuy then
        uiShopBuy:autoRefresh()
    end
end


-- 购买结果回调
function UIShop:buyCallback(nIndex, num)
    -- 设置节点数据
    self.commonShopData.GoodsData[nIndex].nGoodsNum = self.commonShopData.GoodsData[nIndex].nGoodsNum - num
    shopModel:setShopModelData(self.commonShopData)
    self:setCellData(self.scrollView:getChildByTag(nIndex), nIndex)
    -- 更新货币数量
    local nCoinType = self.commonShopData.GoodsData[nIndex].nCoinType
    local nCoinNum = self.commonShopData.GoodsData[nIndex].nCoinNum
    local nSale = self.commonShopData.GoodsData[nIndex].nSale
    local cost = math.ceil(nCoinNum * num * nSale / 100)
    if nCoinType == UIShop.coinType.gold then           -- 金币
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -cost)
    elseif nCoinType == UIShop.coinType.arena then      -- 竞技场
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.PvpCoin, -cost)
    elseif nCoinType == UIShop.coinType.tower then      -- 爬塔
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.TowerCoin, -cost)
    elseif nCoinType == UIShop.coinType.union then      -- 公会
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.UnionContrib, -cost)
    elseif nCoinType == UIShop.coinType.diamond then    -- 钻石
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -cost)
    end
    self:setMoneyPanel()
    -- 英雄卡片或召唤师、装备要播放动画
    self:showItems(nIndex)
end

-- 公会商店购买结果回调
function UIShop:unionBuyCallback(nIndex, num)
    -- 更新货币数量
    local nCoinType = self.unionShopData[nIndex].nCoinType
    local nCoinNum = self.unionShopData[nIndex].nCoinNum
    local nSale = self.unionShopData[nIndex].nSale

    local cost = math.ceil(nCoinNum * num * nSale / 100)

    if nCoinType == UIShop.coinType.gold then           -- 金币
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -cost)
    elseif nCoinType == UIShop.coinType.arena then      -- 竞技场
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.PvpCoin, -cost)
    elseif nCoinType == UIShop.coinType.tower then      -- 爬塔
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.TowerCoin, -cost)
    elseif nCoinType == UIShop.coinType.union then      -- 公会
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.UnionContrib, -cost)
    elseif nCoinType == UIShop.coinType.diamond then    -- 钻石
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -cost)
    end
    self:setMoneyPanel()
    -- 英雄卡片或召唤师、装备要播放动画
    self:showItems(nIndex)
end

function UIShop:checkBuySummoner(goodsID)
    local propConf = getPropConfItem(goodsID)
    if propConf and 4 == propConf.Type then -- 召唤师
        local summonerModel = getGameModel():getSummonersModel()
        local summoners = summonerModel:getSummoners()
    
        if summonerModel:hasSummoner(propConf.TypeParam[1]) then
            local params = {}
            params.msg = string.format(CommonHelper.getUIString(178), CommonHelper.getHSString(propConf.Name))
            params.confirmFun = function () UIManager.close() end
            params.cancelFun = function () print("nothing to do...") end
            UIManager.open(UIManager.UI.UIDialogBox, params)
    
            return false
        end
    end

    return true
end

function UIShop:showItems(index)
    local goodsInfo = {}
    if self.curType == ShopType.UnionShop then
        goodsInfo = self.unionShopData[index]
    else
        goodsInfo = self.commonShopData.GoodsData[index]
    end

    local propConf = getPropConfItem(goodsInfo.nGoodsID or 0)
    if not propConf then
        return
    end

    local items = {summoners = {}, heroCards = {}}
    if 4 == propConf.Type then -- 召唤师
        table.insert(items.summoners, propConf.TypeParam[1])
        UIManager.open(UIManager.UI.UIShowAll, items)
    elseif 3 == propConf.Type then -- 英雄卡片
        table.insert(items.heroCards, {cardId = propConf.TypeParam[1], star = propConf.TypeParam[2], heroLv = 1})
        UIManager.open(UIManager.UI.UIShowAll, items)
    elseif 13 == propConf.Type then
        if self.eqDynID then
            UIManager.open(UIManager.UI.UIShowEquip, self.eqDynID)
        end
    end
end

function UIShop:showUnionShopTips()
    -- 公会商店
    if self.curType == ShopType.UnionShop then
        local hasUnion = getGameModel():getUnionModel():getHasUnion()
        if hasUnion then
            local count = shopModel:getUnionGoodsCount()
            -- 普通状态
            if count > 0 then
                self.unionShopTips:setVisible(false)
            -- 正在上架状态
            else
                local text = getChild(self.unionShopTips, "TipsPanel/Tips1")
                text:setString(CommonHelper.getUIString(2047))
                -- 提示远征结束上架
                self.unionShopTips:setVisible(true)
                CommonHelper.playCsbAnimate(self.unionShopTips, "ui_new/g_gamehall/s_shop/GuildShopTips.csb", "Case1", false)
            end
        else
            local text = getChild(self.unionShopTips, "TipsPanel/Tips2")
            text:setString(CommonHelper.getUIString(2046))
            -- 提示加入公会后开启
            self.unionShopTips:setVisible(true)
            CommonHelper.playCsbAnimate(self.unionShopTips, "ui_new/g_gamehall/s_shop/GuildShopTips.csb", "Case2", false)
        end
    else
        self.unionShopTips:setVisible(false)
    end
end

return UIShop