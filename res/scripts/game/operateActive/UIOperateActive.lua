--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-05-25 11:02
** 版  本:	1.0
** 描  述:  运营活动主界面
** 应  用:
********************************************************************/
--]]
local shopScrollViewExtend = require("common.ScrollViewExtend").new()
local taskScrollViewExtend = require("common.ScrollViewExtend").new()
local cardScrollViewExtend = require("common.ScrollViewExtend").new()
local tabScrollViewExtend = require("common.ScrollViewExtend").new()
local exchangeScrollViewExtend = require("common.ScrollViewExtend").new()

local scheduler = require("framework.scheduler")
local SdkManager = require("common.sdkmanager.SdkManager")
local operateActiveModel = getGameModel():getOperateActiveModel()
local userModel = getGameModel():getUserModel()

local CoinImage = {
    [1] = "pub_gold.png",       -- 金币
    [2] = "pub_fightcoin.png",  -- 竞技场
    [3] = "pub_enfragment.png", -- 爬塔
    [4] = "pub_gem.png",        -- 钻石
}

-- 任务状态
local FinishFlag = {
    UNRECEIVE = 0,   -- 未领取
    RECEIVED  = 1,   -- 已领取
}

local GoldType = {
    TYPE_GOLD   = 1,
    TYPE_ARENA  = 2,
    TYPE_TOWER  = 3,
    TYPE_GEM    = 4,
}

local function isSameDay(time1, time2)
    return (os.date("%Y", time1) == os.date("%Y", time2) and 
            os.date("%m", time1) == os.date("%m", time2) and
            os.date("%d", time1) == os.date("%d", time2))
end

local PropTips = require("game.comm.PropTips")

local UIOperateActive = class("UIOperateActive", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIOperateActive:ctor()
    self.rootPath = ResConfig.UIOperateActive.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local backBtn = getChild(self.root, "BackButton")   -- 关闭按钮
    CsbTools.initButton(backBtn, handler(self, self.onClick))
    
    self.titleText = getChild(self.root, "MainPanel/OperatePanel/BarImage1/TitleText")

    self.operatePanel1 = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_1")
    self.operatePanel2 = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2")
    self.operatePanel3 = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_3")
    self.operatePanel4 = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_4")
    self.operatePanel5 = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_5")
    self.operateOver   = getChild(self.root, "MainPanel/OperatePanel/OperateOverTips")
    self.operateOver:setVisible(false)

    self:initListView()
    self:initShopScrollView()
    self:initTaskScrollView()
    self:initCardScrollView()
    self:initExchangeScrollView()
end

-- 当界面被创建时回调
-- 只初始化一次
function UIOperateActive:init(...)
	--self.root
	--self.rootPath
end


-- 当界面被打开时回调
-- 每次调用Open时回调
function UIOperateActive:onOpen(openerUIID, activeData)
    self.itemAction = {}

    self.activeData = activeData
    -- 按活动开启时间, 活动ID进行排序
    table.sort(self.activeData, function(a, b)
        if a.startTime > b.startTime then
            return true
        elseif a.startTime == b.startTime and a.activeID < b.activeID then
            return true
        else
            return false
        end
    end)

    self.curActiveIndex = 1
    local data = self.activeData[self.curActiveIndex]
    if nil == data then
        return
    end
    self.curActiveID = data.activeID
    self.curActiveType = data.activeType

    -- 红点
    self.activitysRedPoint = RedPointHelper.getActivityRedPoint()
    self:setMoneyPanel()
    self:setTitleText()

    tabScrollViewExtend:reloadList(6, #self.activeData)
    self:setOperatePanel()

    if nil == self.surplusTimeSheduler then
        self.surplusTimeSheduler = scheduler.scheduleGlobal(handler(self, self.setSurplusTime), 1)
    end

    self:initNetwork()
    self:initEvent()
end

-- 每次界面Open动画播放完毕时回调
function UIOperateActive:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIOperateActive:onClose()
    self:removeNetwork()
    self:removeEvent()
    if self.surplusTimeSheduler then
        scheduler.unscheduleGlobal(self.surplusTimeSheduler)
        self.surplusTimeSheduler = nil
    end

    if self.propTips then
        self.propTips:removePropAllTips()
        self.propTips = nil
    end

    shopScrollViewExtend:removeAllChild()
    taskScrollViewExtend:removeAllChild()
    cardScrollViewExtend:removeAllChild()
    tabScrollViewExtend:removeAllChild()
    exchangeScrollViewExtend:removeAllChild()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIOperateActive:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIOperateActive:onClick(obj)
    local btnName = obj:getName()
    obj.soundId = nil
    if "BackButton" == btnName then
        UIManager.close()
    elseif "BuyButton" == btnName then
        for i, data in pairs(self.shopData) do
            if data.giftID == obj.giftID then
                if self:checkBuy(data) then
                    local cost = data.price * data.saleRate / 100
                    local params = {}
                    if data.goldType == GoldType.TYPE_GOLD then         -- 金币
                        params.msg = string.format(CommonHelper.getUIString(1476), cost)
                    elseif data.goldType == GoldType.TYPE_GEM then      -- 钻石
                        params.msg = string.format(CommonHelper.getUIString(1472), cost)
                    end
                    params.confirmFun = function () self:sendGetCmd(obj.giftID) end
                    params.cancelFun = function () UIManager.close() end
                    UIManager.open(UIManager.UI.UIDialogBox, params)
                else
                    obj.soundId = MusicManager.commonSound.fail
                end
                break
            end
        end
    elseif "ReciveButton" == btnName then
        for i, data in pairs(self.taskData) do
            if data.taskID == obj.taskID then
                if self:checkGet(data) then
                    self:sendGetCmd(obj.taskID)
                end
                break
            end
        end
    elseif "ExchangeButton" == btnName then
        for i, data in pairs(self.exchangeData) do
            if data.taskID == obj.taskID then
                self:sendGetExchangeCmd(obj.taskID)
                break
            end
        end
    end
end

-- 设置货币面板
function UIOperateActive:setMoneyPanel()
    local goldCountLabel    = getChild(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
    local gemCountLabel     = getChild(self.root, "GemInfo/GemPanel/GemCountLabel")
    goldCountLabel:setString(tostring(userModel:getGold()))
    gemCountLabel:setString(tostring(userModel:getDiamond()))
end

-- 设置标题文本
function UIOperateActive:setTitleText()
    local str = getOperateActiveTitleName(self.curActiveID)
    self.titleText:setString(str or "")
end

-- 设置活动剩余时间(活动结束将当前界面的按钮置灰)
function UIOperateActive:setSurplusTime()
    local data = self.activeData[self.curActiveIndex]
    
    -- 活动剩余时间
    local surplusTime = TimeHelper.restTime(data.endTime)
    local surplusStr = string.format(CommonHelper.getUIString(1470),
                                surplusTime.day, surplusTime.hour, surplusTime.min)
    local nowTime = getGameModel():getNow()
    if self.curActiveType == ActiveType.TYPE_SHOP then
        local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_1/OperatePanel/TimeSurplus")
        if 0 ~= data.timeType then
            if nowTime > data.endTime then
                -- 将商店活动置为灰
                self:setShopPanel()
                -- 将活动标签置为已结束
                tabScrollViewExtend:reloadData()
            else
                -- timeSurplus:setVisible(true)
                timeSurplus:setString(surplusStr)
            end
        end
    elseif self.curActiveType == ActiveType.TYPE_DROP then
        local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2/OperatePanel/TimeSurplus")
        if 0 ~= data.timeType then
            if nowTime > data.endTime then
                -- 将掉落活动置为灰
                self:setDropPanel()
                -- 将活动标签置为已结束
                tabScrollViewExtend:reloadData()
            else
                -- timeSurplus:setVisible(true)
                timeSurplus:setString(surplusStr)
            end
        end
    elseif self.curActiveType == ActiveType.TYPE_TASK then
        local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_3/OperatePanel_1/TimeSurplus")
        if 0 ~= data.timeType then
            if nowTime > data.endTime then
                -- 将任务活动置为灰
                self:setTaskPanel()
                -- 将活动标签置为已结束
                tabScrollViewExtend:reloadData()
            else
                -- timeSurplus:setVisible(true)
                timeSurplus:setString(surplusStr)
            end
        end
    elseif self.curActiveType == ActiveType.TYPE_CARD then
        local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_3/OperatePanel_1/TimeSurplus")
        local data = self.monthCardData[1]
        -- 月卡持续天数
        local cardDays = getMonthCardDays(self.curActiveID, data.cardID)
        local nowTime = getGameModel():getNow()
        local finishTime = data.chargeTime + cardDays * 86400
        if nowTime > finishTime then
            timeSurplus:setVisible(false)
        else
            local surplusTime = TimeHelper.restTime(finishTime)
            local surplusStr = string.format(CommonHelper.getUIString(1470),
                                        surplusTime.day, surplusTime.hour, surplusTime.min)
            timeSurplus:setVisible(true)
        end
    end
end

---------------------------------------------------------------------
-- 初始化网络回调
function UIOperateActive:initNetwork()
end

-- 移除网络回调
function UIOperateActive:removeNetwork()
end

function UIOperateActive:onRechargeSucess(eventName, args)
    local result = args.result
    local vipLv = args.vipLv
    local vipNum = args.vipNum
    local diamond = args.diamond  -- 如果是购买月卡下发的是月卡结束的时间戳
    local pID = args.pID

    if result == 1 then
        if pID == 7 or pID == 8 then
            self:setMoneyPanel()
        elseif pID == 9 then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2115))
        end
        self:setOperatePanel()
    end
end

---------------------------------------------------------------------
-- 初始化事件回调
function UIOperateActive:initEvent()
    -- 添加充值成功事件监听
    self.eventRechargeSucessHandler = handler(self, self.onRechargeSucess)
    EventManager:addEventListener(GameEvents.EventRecharge, self.eventRechargeSucessHandler)
end

-- 移除事件回调
function UIOperateActive:removeEvent()
    -- 移除充值成功事件监听
    if self.eventRechargeSucessHandler then
        EventManager:removeEventListener(GameEvents.EventRecharge, self.eventRechargeSucessHandler)
        self.eventRechargeSucessHandler = nil
    end
end

---------------------------------------------------------------------
-- 初始化标签列表
function UIOperateActive:initListView()
    local scrollView = getChild(self.root, "MainPanel/OperatePanel/TabScrollView")
    local csb = getResManager():getCsbNode(ResConfig.UIOperateActive.Csb2.operateButton)
    local cell = getChild(csb, "ButtonPanel")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    self.activityRedPointNodes = {}
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = 0,                            -- 初始节点个数
        maxCellCount    = 0,                            -- 最大节点个数
        csbName         = ResConfig.UIOperateActive.Csb2.operateButton, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "ButtonPanel",                -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = scrollView,                   -- 滚动区域
        distanceX       = 0,                            -- 节点X轴间距
        distanceY       = 6,                            -- 节点Y轴间距
        offsetX         = 0,                            -- 第一列的偏移
        offsetY         = 5,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setListItemData),  -- 设置节点数据回调函数
    }
    tabScrollViewExtend:init(tabParam)
    tabScrollViewExtend:create()
end

function UIOperateActive:setListItemData(csb, i)
    local data = self.activeData[i]
    if nil == data then
        return
    end

    local panel = getChild(csb, "ButtonPanel")
    panel:addTouchEventListener(handler(self, self.onTouch))
    panel.index = i
    print("data.activeID", data.activeID)
    local buttonLogo = getChild(csb, "ButtonPanel/ButtonLogo")
    CsbTools.replaceSprite(buttonLogo, getOperateActiveMenuIcon(data.activeID))
    local buttonText  = getChild(csb, "ButtonPanel/ButtonText")
    buttonText:setString(getOperateActiveMenuName(data.activeID) or "")

    local activityOnLog = getChild(csb, "ButtonPanel/ActivityOnLog")
    activityOnLog:setVisible(false)
    local newLogo = getChild(csb, "ButtonPanel/NewLogo")
    newLogo:setVisible(false)
    
    local redTipPoint = getChild(csb, "ButtonPanel/RedTipPoint")
    self.activityRedPointNodes[data.activeID] = redTipPoint
    self:showActiveRedPoint(data.activeID)

    local action = cc.CSLoader:createTimeline(ResConfig.UIOperateActive.Csb2.operateButton)
    csb:runAction(action)
    self.itemAction[i] = action
    if i == self.curActiveIndex then
        action:play("On", false)
    end
end

function UIOperateActive:onTouch(obj, eventType)
    if 2 == eventType then
        MusicManager.playSoundEffect(obj:getName())
        local beginPos = obj:getTouchBeganPosition()
        local endPos = obj:getTouchEndPosition()
        if cc.pGetDistance(beginPos, endPos) > 50 then
            return
        end
        if obj.index ~= self.curActiveIndex then
            local data = self.activeData[obj.index]
            if nil == data then
                return
            end

            local prevAction = self.itemAction[self.curActiveIndex]
            prevAction:play("Off", false)
            --
            self.curActiveID = data.activeID
            self.curActiveType = data.activeType
            self.curActiveIndex = obj.index
            --
            local curAction = self.itemAction[self.curActiveIndex]
            curAction:play("On", false)

            self:setTitleText()
            self:setOperatePanel()
            self:clickActiveRedPoint(self.curActiveID)
        end
    end
end

---------------------------------------------------------------------
-- 初始化商店列表
function UIOperateActive:initShopScrollView()
    local scrollView = getChild(self.operatePanel1, "OperatePanel/TaskScrollView")

    local csb = getResManager():getCsbNode(ResConfig.UIOperateActive.Csb2.salePanel)
    local cell = getChild(csb, "ImageBg")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = 0,                            -- 初始节点个数
        maxCellCount    = 0,                            -- 最大节点个数
        csbName         = ResConfig.UIOperateActive.Csb2.salePanel, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = nil,                          -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = scrollView,                   -- 滚动区域
        distanceX       = 6,                            -- 节点X轴间距
        distanceY       = 0,                            -- 节点Y轴间距
        offsetX         = 0,                            -- 第一列的偏移
        offsetY         = 3,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setShopItemData),  -- 设置节点数据回调函数
    }
    shopScrollViewExtend:init(tabParam)
    shopScrollViewExtend:create()
end

-- 设置商店物品数据
function UIOperateActive:setShopItemData(csb, i)
    local itemData = self.shopData[i]
    if nil == itemData then
        csb:setVisible(false)
        return
    end

    local buyBtn = getChild(csb, "ImageBg/BuyButton")
    buyBtn.giftID = itemData.giftID
    CsbTools.initButton(buyBtn, handler(self, self.onClick))
    buyBtn:setSwallowTouches(false)
    local btnText = getChild(csb, "ImageBg/BuyButton/Text")
    btnText:setString(string.format(CommonHelper.getUIString(1471), itemData.buyTimes, itemData.maxBuyTimes))

    -- 活动已结束 or 商品已卖完
    local nowTime = getGameModel():getNow()
    local data = self.activeData[self.curActiveIndex]
    if itemData.buyTimes >= itemData.maxBuyTimes or nowTime >= data.endTime then
        buyBtn:setTouchEnabled(false)
        buyBtn:setBright(false)
        btnText:enableOutline(cc.c4b(127, 127, 127, 255), 2)
    end

    local pubGem1 = getChild(csb, "ImageBg/pub_gem1")
    local pubGem2 = getChild(csb, "ImageBg/pub_gem2")
    pubGem1:setSpriteFrame(CoinImage[itemData.goldType])
    pubGem2:setSpriteFrame(CoinImage[itemData.goldType])
    local gemCountLabel1 = getChild(csb, "ImageBg/GemCountLabel_1")
    local gemCountLabel2 = getChild(csb, "ImageBg/GemCountLabel_2")
    gemCountLabel1:setString(itemData.price)
    gemCountLabel2:setString(itemData.price * itemData.saleRate / 100)

    local index = 0
    for i, goodsID in pairs(itemData.goodsID) do
        if goodsID > 0 then
            index = index + 1
            --
            local num = itemData.goodsNum[i] or 1
            -- 道具的配置表信息
            local propConf = getPropConfItem(goodsID)
            if propConf then
                local buyItem = getChild(csb, "ImageBg/SaleItem/SalePanel/BuyItem_" .. i .. "/BuyItem")
                buyItem:setSwallowTouches(false)
                -- 道具图标
                local allItem = getChild(buyItem, "AllItem")
                UIAwardHelper.setAllItemOfConf(allItem, propConf, num)
                -- 道具tips
                local touchPanel = getChild(allItem, "MainPanel")
                self.propTips:addPropTips(touchPanel, propConf)
                -- 道具名称
                local name = getChild(buyItem, "NameText")
                local color = getItemLevelSettingItem(propConf.Quality).Color
                name:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
                if 3 == propConf.Type  or 4 == propConf.Type then
                    name:setString(getHSLanConfItem(propConf.Name))
                else
                    name:setString(getPropLanConfItem(propConf.Name))
                end
            end
        end
    end
    --
    local saleItem = getChild(csb, "ImageBg/SaleItem")
    CommonHelper.playCsbAnimation(saleItem, tostring(index), false, nil)
    -- 商品已卖完
    local receivedLog = getChild(csb, "ImageBg/SaleItem/received_log_1")
    receivedLog:setVisible(false)
    if itemData.buyTimes >= itemData.maxBuyTimes then
        receivedLog:setVisible(true)
    end
end

---------------------------------------------------------------------
-- 初始化任务列表
function UIOperateActive:initTaskScrollView()
    local scrollView = getChild(self.operatePanel3, "OperatePanel_1/TaskScrollView")

    local csb = getResManager():getCsbNode(ResConfig.UIOperateActive.Csb2.taskBar)
    local cell = getChild(csb, "OperateTaskBar")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = 0,                            -- 初始节点个数
        maxCellCount    = 0,                            -- 最大节点个数
        csbName         = ResConfig.UIOperateActive.Csb2.taskBar,   -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = nil,                          -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = scrollView,                   -- 滚动区域
        distanceX       = 0,                            -- 节点X轴间距
        distanceY       = 5,                            -- 节点Y轴间距
        offsetX         = -2,                           -- 第一列的偏移
        offsetY         = 2,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setTaskItemData),  -- 设置节点数据回调函数
    }
    taskScrollViewExtend:init(tabParam)
    taskScrollViewExtend:create()
end

-- 设置任务奖励数据
function UIOperateActive:setTaskItemData(csb, i)
    local itemData = self.taskData[i]
    if nil == itemData then
        csb:setVisible(false)
        return
    end

    local stateCsb = ResConfig.UIOperateActive.Csb2.taskState
    local stateNode = getChild(csb, "OperateTaskBar/TaskState")
    stateNode:setVisible(true)
    local receiveBtn = getChild(stateNode, "ReciveButton")
    CsbTools.initButton(receiveBtn, handler(self, self.onClick))
    receiveBtn.taskID = itemData.taskID
    local nowTime = getGameModel():getNow()
    -- 特殊处理: 整点领取活动
    if 9 == itemData.finishCondition then
        if itemData.finishFlag == FinishFlag.UNRECEIVE then -- 未领取
            local data = self.activeData[self.curActiveIndex]
            if nil == data then
                return
            end
            -- 活动已结束
            if nowTime >= data.endTime then
                stateNode:setVisible(false)
            else
                -- 未达成
                if tonumber(os.date("%H")) < itemData.conditionParam[1] then
                    stateNode:setVisible(false)
                -- 可领取
                elseif tonumber(os.date("%H")) >= itemData.conditionParam[1] and nowTime < data.endTime then
                    CommonHelper.playCsbAnimate(stateNode, stateCsb, "Receive", false)
                end
            end
        elseif itemData.finishFlag == FinishFlag.RECEIVED then  -- 已领取
            local text = getChild(csb, "OperateTaskBar/TaskState/received_log/Text_2")
            text:setString(CommonHelper.getUIString(1474))
            CommonHelper.playCsbAnimate(stateNode, stateCsb, "Received", false)
        end
    else
        if itemData.value < itemData.conditionParam[1] then     -- 未达成
            stateNode:setVisible(false)
        elseif itemData.finishFlag == FinishFlag.UNRECEIVE then -- 未领取
            local data = self.activeData[self.curActiveIndex]
            if nil == data then
                return
            end
            -- 活动已结束
            if 0 ~= data.timeType and nowTime >= data.endTime then
                receiveBtn:setTouchEnabled(false)
                receiveBtn:setBright(false)
                local btnName = getChild(stateNode, "ReciveButton/ButtomName")
                btnName:enableOutline(cc.c4b(127, 127, 127, 255), 2)
            else
                CommonHelper.playCsbAnimate(stateNode, stateCsb, "Receive", false)
            end
        elseif itemData.finishFlag == FinishFlag.RECEIVED then  -- 已领取
            local text = getChild(csb, "OperateTaskBar/TaskState/received_log/Text_2")
            text:setString(CommonHelper.getUIString(1474))
            CommonHelper.playCsbAnimate(stateNode, stateCsb, "Received", false)
        end
    end
    --
    local tipsStr = ""
    local str = GetOperateActiveTaskName(self.curActiveID, itemData.taskID)
    if str then
        tipsStr = string.format(str, itemData.conditionParam[1])
    end
    local tipsText = getChild(csb, "OperateTaskBar/TipsText")
    tipsText:setString(tipsStr)
    --
    -- local iconName = GetOperateActiveTaskIcon(self.curActiveID, itemData.taskID)
    -- local iconImg = getChild(csb, "OperateTaskBar/TaskIcon")
    -- CsbTools.replaceImg(iconImg, iconName)
    --
    local tipsNum = getChild(csb, "OperateTaskBar/TipsNum")
    local value = itemData.value
    if value > itemData.conditionParam[1] then
        value = itemData.conditionParam[1]
    end
    tipsNum:setString(value .. "/" .. itemData.conditionParam[1])
    tipsNum:setVisible(true)
    -- 特殊处理: 整点领取活动
    if 9 == itemData.finishCondition then
        tipsNum:setVisible(false)
    end
    --
    local awardPanel = getChild(csb, "OperateTaskBar/AwardPanel")
    awardPanel:removeAllChildren()
    local currencyType = {
        [1] = "pub_gem.png",
        [2] = "pub_gold.png",
        [3] = "pub_energy.png"
    }
    local posX = 10
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(ResConfig.UIOperateActive.Csb2.awardItem)
        item:setPosition(posX, 30)
        item:setVisible(true)
        awardPanel:addChild(item)

        local panel = getChild(item, "TaskAwradPanel")

        local propConf = getPropConfItem(id)
        if propConf then
            -- 道具图片
            local allItem = getChild(panel, "Award1")
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        end

        -- 道具数量
        local propNumLab = getChild(panel, "Award1_Num")
        propNumLab:setString(num)

        local panelWidht = panel:getContentSize().width
        local lableWidth = propNumLab:getContentSize().width
        posX = posX + lableWidth + panelWidht
    end
    -- 显示顺序：道具物品、钻石、金币、体力
    for i, id in pairs(itemData.rewardGoodsID) do
        local num = itemData.rewardGoodsNum[i] or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
    if itemData.rewardDimand > 0 then
        createAwardItem(2, itemData.rewardDimand)
    end
    if itemData.rewardGold > 0 then
        createAwardItem(1, itemData.rewardGold)
    end
    -- if itemData.rewardEnergy > 0 then
    --     createAwardItem(5, itemData.rewardEnergy)
    -- end
end

---------------------------------------------------------------------
-- 初始化月卡列表
function UIOperateActive:initCardScrollView()
    local scrollView = getChild(self.operatePanel4, "OperatePanel/TaskScrollView")

    local csb = getResManager():getCsbNode(ResConfig.UIOperateActive.Csb2.monthCard)
    local cell = getChild(csb, "CardPanel")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = 0,                            -- 初始节点个数
        maxCellCount    = 0,                            -- 最大节点个数
        csbName         = ResConfig.UIOperateActive.Csb2.monthCard, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = nil,                          -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = scrollView,                   -- 滚动区域
        distanceX       = 10,                            -- 节点X轴间距
        distanceY       = 0,                            -- 节点Y轴间距
        offsetX         = 5,                            -- 第一列的偏移
        offsetY         = 3,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setCardItemData),  -- 设置节点数据回调函数
    }
    cardScrollViewExtend:init(tabParam)
    cardScrollViewExtend:create()
end

-- 设置月卡物品数据
function UIOperateActive:setCardItemData(csb, i)
    local itemData = self.monthCardData[i]
    if nil == itemData then
        csb:setVisible(false)
        return
    end

    if 0 == itemData.cardType then      -- 终身月卡
        self:setGoldCardData(csb, i)
    elseif 1 == itemData.cardType then  -- 普通月卡
        self:setMonthCardData(csb, i)
    end
end


-- 设置普通月卡物品数据
function UIOperateActive:setMonthCardData(csb, i)
    local itemData = self.monthCardData[i]
    if nil == itemData then
        csb:setVisible(false)
        return
    end

    CommonHelper.playCsbAnimation(csb, "MonthCard", false, nil)
    local buyButton = getChild(csb, "CardPanel/MonthCard/BuyButton")
    buyButton.cardID = itemData.cardID

    local rmb = getChild(buyButton, "RMB")
    local text = getChild(buyButton, "RMB/Text")
    local text2 = getChild(buyButton, "Text2")

    local state = operateActiveModel:getCardState(self.curActiveID, i)
    if state == MonthCardState.STATE_NONE then
        print("购买")

        local diamondShopData = getDiamondShopConfData()
        local price = diamondShopData[7].nPrice
        text:setString(price)
        text:setVisible(true)
        rmb:setVisible(true)
        text2:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.buyMonthCard), nil, nil, "RMB")
    elseif state == MonthCardState.STATE_FINISH then
        print("全部领完")

        text2:setVisible(true)
        text2:setString(CommonHelper.getUIString(2111))
        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)
    elseif state == MonthCardState.STATE_RECEIVED then
        print("明日再来")

        text2:setVisible(true)
        text2:setString(CommonHelper.getUIString(2109))
        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)
    elseif state == MonthCardState.STATE_REWARD then
        print("领取")

        text2:setVisible(true)
        text2:setString(CommonHelper.getUIString(2110))
        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.getMonthCard), nil, nil, "RMB")
    end
    
    
    --[[
    -- 月卡持续天数
    local cardDays = getMonthCardDays(self.curActiveID, itemData.cardID)
    local nowTime = getGameModel():getNow()
    local rewardTime = itemData.rewardTime
    local finishTime = itemData.chargeTime + cardDays * 86400
    -- 可以购买: 当前时间 > 结束时间
    if nowTime > finishTime then
        print("购买")

        local diamondShopData = getDiamondShopConfData()
        local price = diamondShopData[7].nPrice
        text:setString(price)
        text:setVisible(true)

        rmb:setVisible(true)
        text2:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.buyMonthCard))
    -- 全部领完: 领取时间日期 == 结束时间日期
    elseif isSameDay(rewardTime, finishTime) then
        print("全部领完")

        text2:setVisible(true)
        -- text2:setString("全部领完")
        text2:setString(CommonHelper.getUIString(2111))

        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)

        -- 明日再来: 充值时间日期 == 当前时间日期 or 领取时间日期 == 当前时间日期
    elseif isSameDay(itemData.chargeTime, nowTime) or isSameDay(rewardTime, nowTime) then
        print("明日再来")

        text2:setVisible(true)
        -- text2:setString("明日再来")
        text2:setString(CommonHelper.getUIString(2109))

        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)

    -- 可以领取: 领取时间日期 ~= 当前时间日期
    elseif not isSameDay(rewardTime, nowTime) then
        print("领取")

        text2:setVisible(true)
        -- text2:setString("领取")
        text2:setString(CommonHelper.getUIString(2110))

        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.getMonthCard))

    end
    --]]
end
-- 购买普通月卡
function UIOperateActive:buyMonthCard(obj)
    local diamondShopData = getDiamondShopConfData()
    SdkManager.payForProduct(diamondShopData[7])
end
-- 领取普通月卡
function UIOperateActive:getMonthCard(obj)
    self:sendGetCmd(obj.cardID)
end


-- 设置终身月卡物品数据
function UIOperateActive:setGoldCardData(csb, i)
    local itemData = self.monthCardData[i]
    if nil == itemData then
        csb:setVisible(false)
        return
    end

    CommonHelper.playCsbAnimation(csb, "GoldCard", false, nil)
    local buyButton = getChild(csb, "CardPanel/GoldCard/BuyButton")
    buyButton.cardID = itemData.cardID

    local rmb = getChild(buyButton, "RMB")
    local text = getChild(buyButton, "RMB/Text")
    local text2 = getChild(buyButton, "Text2")

    -- local rmb = getChild(buyButton, "pub_rmb_31")
    -- local text = getChild(buyButton, "Text")

    local state = operateActiveModel:getCardState(self.curActiveID, i)
    if state == MonthCardState.STATE_NONE then
        print("购买")

        local diamondShopData = getDiamondShopConfData()
        local price = diamondShopData[8].nPrice
        text:setString(price)
        text:setVisible(true)
        rmb:setVisible(true)
        text2:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.buyGoldCard), nil, nil, "RMB")
    elseif state == MonthCardState.STATE_RECEIVED then
        print("明日再来")

        text2:setVisible(true)
        text2:setString(CommonHelper.getUIString(2109))
        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)
    elseif state == MonthCardState.STATE_REWARD then
        print("领取")

        text2:setVisible(true)
        text2:setString(CommonHelper.getUIString(2110))
        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.getGoldCard), nil, nil, "RMB")
    end

    --[[
    local nowTime = getGameModel():getNow()
    local rewardTime = itemData.rewardTime
    -- 可以购买: 充值时间 == 0
    if 0 == itemData.chargeTime then
        print("购买")
        
        local diamondShopData = getDiamondShopConfData()
        local price = diamondShopData[8].nPrice
        text:setString(price)
        text:setVisible(true)

        rmb:setVisible(true)
        text2:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.buyGoldCard))

    -- 明日再来: 充值时间日期 == 当前时间日期 or 领取时间日期 == 当前时间日期
    elseif isSameDay(itemData.chargeTime, nowTime) or isSameDay(rewardTime, nowTime) then
        print("明日再来")

        text2:setVisible(true)
        -- text2:setString("明日再来")
        text2:setString(CommonHelper.getUIString(2109))

        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(false)

    -- 可以领取: 领取时间日期 ~= 当前时间日期
    elseif not isSameDay(rewardTime, nowTime) then
        print("领取")

        text2:setVisible(true)
        -- text2:setString("领取")
        text2:setString(CommonHelper.getUIString(2110))

        rmb:setVisible(false)
        text:setVisible(false)
        buyButton:setTouchEnabled(true)

        CsbTools.initButton(buyButton, handler(self, self.getGoldCard))
    end
    --]]
end
-- 购买终身月卡
function UIOperateActive:buyGoldCard(obj)
    local diamondShopData = getDiamondShopConfData()
    SdkManager.payForProduct(diamondShopData[8])
end
-- 领取终身月卡
function UIOperateActive:getGoldCard(obj)
    self:sendGetCmd(obj.cardID)
end

---------------------------------------------------------------------
-- 初始化兑换列表
function UIOperateActive:initExchangeScrollView()
    local scrollView = getChild(self.operatePanel5, "OperatePanel_1/TaskScrollView")

    local csb = getResManager():getCsbNode(ResConfig.UIOperateActive.Csb2.taskBar)
    local cell = getChild(csb, "OperateTaskBar")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 1,                            -- 每行节点个数
        defaultCount    = 0,                            -- 初始节点个数
        maxCellCount    = 0,                            -- 最大节点个数
        csbName         = ResConfig.UIOperateActive.Csb2.taskBar, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = nil,                          -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = scrollView,                   -- 滚动区域
        distanceX       = 10,                            -- 节点X轴间距
        distanceY       = 0,                            -- 节点Y轴间距
        offsetX         = 5,                            -- 第一列的偏移
        offsetY         = 3,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setExchangeItemData),  -- 设置节点数据回调函数
    }
    exchangeScrollViewExtend:init(tabParam)
    exchangeScrollViewExtend:create()
end

-- 设置兑换物品数据
function UIOperateActive:setExchangeItemData(csb, i)
    local itemData = self.exchangeData[i]
    local acData = GetOperateActiveExchangeData(itemData.acId, itemData.taskID)
    local bagModel = getGameModel():getBagModel()
    if nil == itemData then
        csb:setVisible(false)
        return
    end
    local stateCsb = ResConfig.UIOperateActive.Csb2.taskState
    local stateNode = getChild(csb, "OperateTaskBar/TaskState")
    stateNode:setVisible(true)

    local receiveBtn = getChild(stateNode, "ReciveButton")
    CsbTools.initButton(receiveBtn, handler(self, self.onClick))
    receiveBtn.taskID = itemData.taskID
    receiveBtn:setName("ExchangeButton")
    local text = getChild(receiveBtn, "ButtomName")

    -- 条件完成度判断
    local lock = true
    local isEnough = false
    local isEnoughCount = false

    local tipsStr = ""
    local str = GetOperateActiveExchangeStr(self.curActiveID, itemData.taskID)
    local strData = acData.Exchange_Type1

    if #strData == 1 then
        local count1 = bagModel:getItemCountById(strData[1][1])
        if count1 >= strData[1][2] then
            isEnough = true
        else
            isEnough = false
        end
        if str then
            local propConf = getPropConfItem(strData[1][1])
            tipsStr = string.format(str, strData[1][2], CommonHelper.getPropString(propConf.Name))
        end
    elseif #strData == 2 then
        local count1 = bagModel:getItemCountById(strData[1][1])
        local count2 = bagModel:getItemCountById(strData[2][1])
        if count1 >= strData[1][2] and count2 >= strData[2][2] then
            isEnough = true
        else
            isEnough = false
        end
        if str then
            local propConf1 = getPropConfItem(strData[1][1])
            local propConf2 = getPropConfItem(strData[2][1])
            tipsStr = string.format(str, strData[1][2], CommonHelper.getPropString(propConf1.Name), 
                                         strData[2][2], CommonHelper.getPropString(propConf2.Name))
        end
    elseif #strData == 3 then
        local count1 = bagModel:getItemCountById(strData[1][1])
        local count2 = bagModel:getItemCountById(strData[2][1])
        local count3 = bagModel:getItemCountById(strData[3][1])
        if count1 >= strData[1][2] and count2 >= strData[2][2] and count3 >= strData[3][2] then
            isEnough = true
        else
            isEnough = false
        end
        if str then
            local propConf1 = getPropConfItem(strData[1][1])
            local propConf2 = getPropConfItem(strData[2][1])
            local propConf3 = getPropConfItem(strData[3][1])
            tipsStr = string.format(str, strData[1][2], CommonHelper.getPropString(propConf1.Name), 
                                         strData[2][2], CommonHelper.getPropString(propConf2.Name),  
                                         strData[3][2], CommonHelper.getPropString(propConf3.Name))
        end
    elseif #strData == 4 then
        local count1 = bagModel:getItemCountById(strData[1][1])
        local count2 = bagModel:getItemCountById(strData[2][1])
        local count3 = bagModel:getItemCountById(strData[3][1])
        local count4 = bagModel:getItemCountById(strData[4][1])
        if count1 >= strData[1][2] and count2 >= strData[2][2] and count3 >= strData[3][2] and count4 >= strData[4][2] then
            isEnough = true
        else
            isEnough = false
        end
        if str then
            local propConf1 = getPropConfItem(strData[1][1])
            local propConf2 = getPropConfItem(strData[2][1])
            local propConf3 = getPropConfItem(strData[3][1])
            local propConf4 = getPropConfItem(strData[4][1])
            tipsStr = string.format(str, strData[1][2], CommonHelper.getPropString(propConf1.Name),
                                         strData[2][2], CommonHelper.getPropString(propConf2.Name),  
                                         strData[3][2], CommonHelper.getPropString(propConf3.Name), 
                                         strData[4][2], CommonHelper.getPropString(propConf4.Name))
        end
    end

    local tipsText = getChild(csb, "OperateTaskBar/TipsText")
    tipsText:setString(tipsStr)

    local tipsNum = getChild(csb, "OperateTaskBar/TipsNum")

    local value = itemData.count
    if value >= acData.Exchange_limit then
        value = acData.Exchange_limit
        isEnoughCount = false
    else
        isEnoughCount = true
    end

    tipsNum:setString(string.format(CommonHelper.getUIString(2148),acData.Exchange_limit-value))
    tipsNum:setVisible(true)

    if isEnough  then --什么都够
        receiveBtn:setVisible(true)
        receiveBtn:setEnabled(true)
        text:setString(CommonHelper.getUIString(2155))--领取
    else
        receiveBtn:setVisible(true)
        receiveBtn:setEnabled(false)
        text:setString(CommonHelper.getUIString(2155))--领取
    end

    if not isEnoughCount then --次数不够
        receiveBtn:setVisible(true)
        receiveBtn:setEnabled(false)
        text:setString(CommonHelper.getUIString(2156))--兑换完成
        tipsNum:setVisible(false)
    end

    local awardPanel = getChild(csb, "OperateTaskBar/AwardPanel")
    awardPanel:removeAllChildren()
    local posX = 10
    local function createAwardItem(id, num)
        local item = getResManager():cloneCsbNode(ResConfig.UIOperateActive.Csb2.awardItem)
        item:setPosition(posX, 30)
        item:setVisible(true)
        awardPanel:addChild(item)

        local panel = getChild(item, "TaskAwradPanel")

        local propConf = getPropConfItem(id)
        if propConf then
            -- 道具图片
            local allItem = getChild(panel, "Award1")
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        end

        -- 道具数量
        local propNumLab = getChild(panel, "Award1_Num")
        propNumLab:setString(num)

        local panelWidht = panel:getContentSize().width
        local lableWidth = propNumLab:getContentSize().width
        posX = posX + lableWidth + panelWidht
    end

    -- 显示顺序：道具物品、钻石、金币、体力
    for i, info in pairs(acData.Exchange_reward) do
        local id = info[1] or 0
        local num = info[2] or 0
        if id > 0 and num > 0 then
            createAwardItem(id, num)
        end
    end
end

---------------------------------------------------------------------
-- 设置活动面板内容
function UIOperateActive:setOperatePanel()
    self.operatePanel1:setVisible(false)
    self.operatePanel2:setVisible(false)
    self.operatePanel3:setVisible(false)
    self.operatePanel4:setVisible(false)
    self.operatePanel5:setVisible(false)

    if self.propTips then
        self.propTips:removePropAllTips()
        self.propTips = nil
    end

    self.propTips = PropTips.new()
    print("self.curActiveType"..self.curActiveType)
    if self.curActiveType == ActiveType.TYPE_SHOP then
        self:setShopPanel()
    elseif self.curActiveType == ActiveType.TYPE_DROP then
        self:setDropPanel()
    elseif self.curActiveType == ActiveType.TYPE_TASK then
        self:setTaskPanel()
    elseif self.curActiveType == ActiveType.TYPE_CARD then
        self:setCardPanel()
    elseif self.curActiveType == ActiveType.TYPE_EXCHANGE then
        self:setExchangePanel()
    end
end

-- 设置商店活动面板
function UIOperateActive:setShopPanel()
    self.operatePanel1:setVisible(true)
    self.operateOver:setVisible(false)
    --
    local data = self.activeData[self.curActiveIndex]
    if nil == data then
        return
    end
    -- 活动结束标识
    local nowTime = getGameModel():getNow()
    if 0 ~= data.timeType and nowTime > data.endTime then
        self.operateOver:setVisible(true)
    end

    -- 活动起始时间
    local timeRange = getChild(self.operatePanel1, "OperatePanel/TimeRange")
    -- 活动剩余时间
    local timeSurplus = getChild(self.operatePanel1, "OperatePanel/TimeSurplus")
    local timeBg = getChild(self.operatePanel1, "OperatePanel/TipsBg")
    if 0 == data.timeType then
        timeRange:setVisible(false)
        timeSurplus:setVisible(false)
        timeBg:setVisible(false)
    else
        -- 活动起始时间
        local startTime = TimeHelper.toTimeS(data.startTime)
        local endTime = TimeHelper.toTimeS(data.endTime)
        local rangeStr = string.format(CommonHelper.getUIString(1469),
                                    startTime.month, startTime.day, startTime.hour, startTime.min,
                                    endTime.month, endTime.day, endTime.hour, endTime.min)
        timeRange:setString(rangeStr)
        -- 活动剩余时间
        local surplusTime = TimeHelper.restTime(data.endTime)
        local surplusStr = string.format(CommonHelper.getUIString(1470),
                                    surplusTime.day, surplusTime.hour, surplusTime.min)
        timeSurplus:setString(surplusStr)
        timeRange:setVisible(true)
        timeSurplus:setVisible(true)    
        timeBg:setVisible(true)
    end
    --
    self.shopData = operateActiveModel:getActiveShopData(self.curActiveID)
    if nil == self.shopData then
        return
    end
    table.sort(self.shopData, function(a, b)
        local flagA = a.buyTimes < a.maxBuyTimes and 0 or 1
        local flagB = b.buyTimes < b.maxBuyTimes and 0 or 1
        if flagA < flagB then
            return true
        elseif flagA == flagB then
            if a.giftID < b.giftID then
                return true
            else
                return false
            end
        end
    end)
    -- 商店活动面板的ScrollView
    shopScrollViewExtend:reloadList(3, #self.shopData)
end

-- 设置掉率活动面板
function UIOperateActive:setDropPanel()
    self.operatePanel2:setVisible(true)
    self.operateOver:setVisible(false)
    --
    local data = self.activeData[self.curActiveIndex]
    if nil == data then
        return
    end
    -- 活动结束标识
    local nowTime = getGameModel():getNow()
    if 0 ~= data.timeType and nowTime > data.endTime then
        self.operateOver:setVisible(true)
    end

    -- 活动起始时间
    local timeRange = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2/OperatePanel/TimeRange")
    -- 活动剩余时间
    local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2/OperatePanel/TimeSurplus")
    local timeBg = getChild(self.operatePanel2, "OperatePanel/TipsBg")
    if 0 == data.timeType then
        timeRange:setVisible(false)
        timeSurplus:setVisible(false)
        timeBg:setVisible(false)
    else
        -- 活动起始时间
        local startTime = TimeHelper.toTimeS(data.startTime)
        local endTime = TimeHelper.toTimeS(data.endTime)
        local rangeStr = string.format(CommonHelper.getUIString(1469),
                                    startTime.month, startTime.day, startTime.hour, startTime.min,
                                    endTime.month, endTime.day, endTime.hour, endTime.min)
        timeRange:setString(rangeStr)
        -- 活动剩余时间
        local surplusTime = TimeHelper.restTime(data.endTime)
        local surplusStr = string.format(CommonHelper.getUIString(1470),
                                    surplusTime.day, surplusTime.hour, surplusTime.min)
        timeSurplus:setString(surplusStr)
        timeRange:setVisible(true)
        timeSurplus:setVisible(true)
        timeBg:setVisible(true)
    end
    -- 活动描述
    local str = getOperateActiveDropDesc(self.curActiveID)
    local introText = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2/OperatePanel/IntroText")
    if nil == self.dropDescRichText then
        self.dropDescRichText = createRichText(introText:getContentSize().width - 10)
        self.dropDescRichText:setName("RichText")
        self.dropDescRichText:setAnchorPoint(introText:getAnchorPoint())
        self.dropDescRichText:setPosition(introText:getPosition())
        self.dropDescRichText:setCascadeOpacityEnabled(true)
        self.dropDescRichText:setLocalZOrder(1000)
        introText:getParent():addChild(self.dropDescRichText)
        introText:removeFromParent()
    end
    self.dropDescRichText:setString(str)

    -- 活动宣传图
    local imageDB = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_2/OperatePanel/Image_DB")
    CsbTools.replaceImg(imageDB, getOperateActiveDropPic(self.curActiveID))
end

-- 设置任务活动面板
function UIOperateActive:setTaskPanel()
    self.operatePanel3:setVisible(true)
    self.operateOver:setVisible(false)
    --
    local data = self.activeData[self.curActiveIndex]
    if nil == data then
        return
    end
    -- 活动起始时间
    local timeRange = getChild(self.operatePanel3, "OperatePanel_1/TimeRange")
    -- 活动剩余时间
    local timeSurplus = getChild(self.operatePanel3, "OperatePanel_1/TimeSurplus")
    local timeBg = getChild(self.operatePanel3, "OperatePanel_1/TipsBg_0")
    if 0 == data.timeType then
        timeRange:setVisible(false)
        timeSurplus:setVisible(false)
        timeBg:setVisible(false)
    else
        -- 活动起始时间
        local startTime = TimeHelper.toTimeS(data.startTime)
        local endTime = TimeHelper.toTimeS(data.endTime)
        local rangeStr = string.format(CommonHelper.getUIString(1469),
                                    startTime.month, startTime.day, startTime.hour, startTime.min,
                                    endTime.month, endTime.day, endTime.hour, endTime.min)
        timeRange:setString(rangeStr)
        -- 活动剩余时间
        local surplusTime = TimeHelper.restTime(data.endTime)
        local surplusStr = string.format(CommonHelper.getUIString(1470),
                                    surplusTime.day, surplusTime.hour, surplusTime.min)
        timeSurplus:setString(surplusStr)
        timeRange:setVisible(true)
        timeSurplus:setVisible(true)
        timeBg:setVisible(true)
    end
    -- 活动结束标识
    local nowTime = getGameModel():getNow()
    if 0 ~= data.timeType and nowTime > data.endTime then
        self.operateOver:setVisible(true)
    end

    -- 活动宣传图
    local imageDB = getChild(self.operatePanel3, "OperatePanel_1/Image_DB")
    CsbTools.replaceImg(imageDB, GetOperateActiveTaskPic(self.curActiveID, 1))
    --
    self.taskData = operateActiveModel:getActiveTaskData(self.curActiveID)
    if nil == self.taskData then
        return
    end
    table.sort(self.taskData, function(a, b)
        if a.finishFlag == 0 and b.finishFlag == 1 then
            return true
		elseif a.finishFlag == 1 and b.finishFlag == 0 then
			return false
		elseif a.finishFlag == 0 and b.finishFlag == 0 then
			-- A已达成, B未达成
			if a.value >= a.conditionParam[1] and b.value < b.conditionParam[1] then
				return true
			-- A未达成, B已达成
			elseif a.value < a.conditionParam[1] and b.value >= b.conditionParam[1] then
				return false
			else
				if a.taskID < b.taskID then
					return true
				else
					return false
				end
			end
		elseif a.finishFlag == 1 and b.finishFlag == 1 then
			if a.taskID < b.taskID then
				return true
			else
				return false
			end
		end
    end)
    -- 任务活动面板的ScrollView
    taskScrollViewExtend:reloadList(4, #self.taskData)
    local rechargeButton = getChild(self.operatePanel3, "OperatePanel_1/RechargeButton")
    CommonHelper.playCsbAnimation(rechargeButton, "Orange", false, nil)
    -- 特殊处理: 基金活动
    if 46 == self.taskData[1].finishCondition then
        -- 基金购买按钮
        local startTime = userModel:getFundStartFlag()    -- 开始时间
        if 0 == startTime then
            rechargeButton:setVisible(true)
            local chargeBtn = getChild(rechargeButton, "Button_Orange")
            CsbTools.initButton(chargeBtn, handler(self, self.buyFunds))
            local chargeText = getChild(chargeBtn, "Text")
            chargeText:setString(CommonHelper.getUIString(23))
        else
            rechargeButton:setVisible(false)
        end
    else
        rechargeButton:setVisible(false)
    end
end

-- 购买基金
function UIOperateActive:buyFunds(obj)
    local diamondShopData = getDiamondShopConfData()
    SdkManager.payForProduct(diamondShopData[9])
end

-- 设置月卡活动面板
function UIOperateActive:setCardPanel()
    self.operatePanel4:setVisible(true)
    self.operateOver:setVisible(false)

    self.monthCardData = operateActiveModel:getMonthCardData()
    local data = self.monthCardData[1]

    -- 月卡持续天数
    local cardDays = getMonthCardDays(self.curActiveID, data.cardID)
    local nowTime = getGameModel():getNow()
    local finishTime = data.chargeTime + cardDays * 86400
    -- 活动起始时间
    local timeRange = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_4/OperatePanel/TimeRange")
    -- 活动剩余时间
    local timeSurplus = getChild(self.root, "MainPanel/OperatePanel/OperatePanel_4/OperatePanel/TimeSurplus")
    local timeBg = getChild(self.operatePanel4, "OperatePanel/TipsBg")
    if nowTime > finishTime then
        timeRange:setVisible(false)
        timeSurplus:setVisible(false)
        timeBg:setVisible(false)
    else
        -- 活动起始时间
        local startTime = TimeHelper.toTimeS(data.chargeTime)
        local endTime = TimeHelper.toTimeS(finishTime)
        local rangeStr = string.format(CommonHelper.getUIString(1469),
                                    startTime.month, startTime.day, startTime.hour, startTime.min,
                                    endTime.month, endTime.day, endTime.hour, endTime.min)
        timeRange:setString(rangeStr)
        -- 活动剩余时间
        local surplusTime = TimeHelper.restTime(finishTime)
        local surplusStr = string.format(CommonHelper.getUIString(1470),
                                    surplusTime.day, surplusTime.hour, surplusTime.min)
        timeSurplus:setString(surplusStr)
        timeRange:setVisible(true)
        timeSurplus:setVisible(true)
        timeBg:setVisible(true)
    end

    cardScrollViewExtend:reloadList(2, #self.monthCardData)
end

-- 设置兑换活动面板
function UIOperateActive:setExchangePanel()

    self.operatePanel5:setVisible(true)
    self.operateOver:setVisible(false)
    --
    local data = self.activeData[self.curActiveIndex]
    if nil == data then
        return
    end

    -- 活动起始时间
    local timeRange = getChild(self.operatePanel5, "OperatePanel_1/TimeRange")
    local timeBg = getChild(self.operatePanel5, "OperatePanel_1/TipsBg_0")
    -- 活动剩余时间
    local timeSurplus = getChild(self.operatePanel5, "OperatePanel_1/TimeSurplus")
    if 0 == data.timeType then
        timeRange:setVisible(false)
        timeSurplus:setVisible(false)
        timeBg:setVisible(false)
    else
        -- 活动起始时间
        local startTime = TimeHelper.toTimeS(data.startTime)
        local endTime = TimeHelper.toTimeS(data.endTime)
        local rangeStr = string.format(CommonHelper.getUIString(1469),
                                    startTime.month, startTime.day, startTime.hour, startTime.min,
                                    endTime.month, endTime.day, endTime.hour, endTime.min)
        timeRange:setString(rangeStr)
        -- 活动剩余时间
        local surplusTime = TimeHelper.restTime(data.endTime)
        local surplusStr = string.format(CommonHelper.getUIString(1470),
                                    surplusTime.day, surplusTime.hour, surplusTime.min)
        timeSurplus:setString(surplusStr)
        timeRange:setVisible(true)
        timeSurplus:setVisible(true)
        timeBg:setVisible(true)
    end
    -- 活动结束标识
    local nowTime = getGameModel():getNow()
    if 0 ~= data.timeType and nowTime > data.endTime then
        self.operateOver:setVisible(true)
    end

    -- 活动宣传图
    local imageDB = getChild(self.operatePanel5, "OperatePanel_1/Image_DB")
    CsbTools.replaceImg(imageDB, GetOperateActiveExchangePic(self.curActiveID, 1))

    self.exchangeData = operateActiveModel:getExchangeData(self.curActiveID)

    local sort = function(info1, info2)

        if  info1.condition > info1.count and  info2.condition <= info2.count then
            return true
        elseif info1.condition > info1.count and info2.condition > info2.count then
            if info1.taskID< info2.taskID then
                return true
            end
        end
        return false 
    end

    for i, data in pairs(self.exchangeData) do
        local acData = GetOperateActiveExchangeData(data.acId, data.taskID)
        data.condition = acData.Exchange_limit
    end

    table.sort(self.exchangeData, sort)

    if nil == self.exchangeData then
        return
    end
    -- 任务活动面板的ScrollView
    exchangeScrollViewExtend:reloadList(4, #self.exchangeData)

end

---------------------------------------------------------------------
-- 发送兑换请求(礼包/任务ID)
function UIOperateActive:sendGetExchangeCmd(paramID)
    print('兑换活动发送协议 self.curActiveID:'..self.curActiveID.." taskID:"..paramID)
    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, OperateActiveProtocol.OperateActiveExchangeGetCS)
    buffData:writeShort(self.curActiveID)     -- 活动ID
    buffData:writeChar(paramID)              -- 礼包/任务ID
    NetHelper.requestWithTimeOut(buffData,
        NetHelper.makeCommand(MainProtocol.OperateActive, OperateActiveProtocol.OperateActiveExchangeGetSC),
        handler(self, self.acceptGetExchangeCmd))
end

-- 接收兑换请求
function UIOperateActive:acceptGetExchangeCmd(mainCmd, subCmd, buffData)
    local activeID = buffData:readShort()    -- 活动ID
    local paramID = buffData:readChar()     -- 礼包ID/任务ID
    local count = buffData:readChar()
    if 1 == count then
        if self.curActiveType == ActiveType.TYPE_EXCHANGE then
            self:exchangeCallback(activeID, paramID)
        end
    else
        print("UIOperateActive Get Error!! count", count)
    end
end


-- 发送请求(礼包/任务ID)
function UIOperateActive:sendGetCmd(paramID)
    local buffData = NetHelper.createBufferData(MainProtocol.OperateActive, OperateActiveProtocol.OperateActiveGetCS)
    buffData:writeShort(self.curActiveID)     -- 活动ID
    buffData:writeChar(paramID)              -- 礼包/任务ID
    NetHelper.requestWithTimeOut(buffData,
        NetHelper.makeCommand(MainProtocol.OperateActive, OperateActiveProtocol.OperateActiveGetSC),
        handler(self, self.acceptGetCmd))
end

-- 接收请求
function UIOperateActive:acceptGetCmd(mainCmd, subCmd, buffData)
    local activeID = buffData:readShort()    -- 活动ID
    local paramID = buffData:readChar()     -- 礼包ID/任务ID
    local flag = buffData:readChar()
    if 1 == flag then
        if self.curActiveType == ActiveType.TYPE_SHOP then
            self:buyCallback(activeID, paramID)
        elseif self.curActiveType == ActiveType.TYPE_TASK then
            self:getTaskCallback(activeID, paramID)
        elseif self.curActiveType == ActiveType.TYPE_CARD then
            self:getCardCallBack(activeID, paramID)
        end
    else
        print("UIOperateActive Get Error!! flag", flag)
    end
end

-- 检测购买的物品,弹出相关提示
function UIOperateActive:checkBuy(data)
    local cost = data.price * data.saleRate / 100
    local money = 0
    if data.goldType == GoldType.TYPE_GOLD then         -- 金币
        if userModel:getGold() < cost then
            UIManager.open(UIManager.UI.UIGold)
            return false
        end
    elseif data.goldType == GoldType.TYPE_GEM then      -- 钻石
        if userModel:getDiamond() < cost then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
            return false
        end
    end

    -- 提示框
    local function dialogTips(lang)
        local params = {}
        params.msg = CommonHelper.getUIString(lang)
        params.confirmFun = function () UIManager.close() end
        params.cancelFun = function () print("nothing to do...") end
        UIManager.open(UIManager.UI.UIDialogBox, params)
    end
    for i, id in pairs(data.goodsID) do
        local propConf = getPropConfItem(id)
        if 4 ~= propConf.Type then       -- 物品
            if not ModelHelper.checkBagCapacity(id, data.goodsNum[i]) then
                dialogTips(118)
                return false
            end
        end
    end

    return true
end

-- 检查领取的奖励,弹出相关提示
function UIOperateActive:checkGet(data)
    -- 提示框
    local function dialogTips(lang)
        local params = {}
        params.msg = CommonHelper.getUIString(lang)
        params.confirmFun = function () UIManager.close() end
        params.cancelFun = function () print("nothing to do...") end
        UIManager.open(UIManager.UI.UIDialogBox, params)
    end

    for i, id in pairs(data.rewardGoodsID) do
        
        local propConf = getPropConfItem(id)
        if propConf then
            if 4 ~= propConf.Type then       -- 物品
                local num = data.rewardGoodsNum[i] or 0
                if not ModelHelper.checkBagCapacity(id, num) then
                    dialogTips(118)
                    return false
                end
            end
        end
    end
    return true
end


-- 购买商品回调
function UIOperateActive:buyCallback(activeID, giftID)
    for i, data in pairs(self.shopData) do
        if data.giftID == giftID then
            data.buyTimes = data.buyTimes + 1
            operateActiveModel:setActiveShopBuyTimes(activeID, giftID, data.buyTimes)
            self:setShopPanel()

            local cost = data.price * data.saleRate / 100
            if data.goldType == GoldType.TYPE_GOLD then         -- 金币
                ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -cost)
            elseif data.goldType == GoldType.TYPE_GEM then      -- 钻石
                ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -cost)
            end
            self:setMoneyPanel()

            -- 显示奖励
            local awardData = {}
            local dropInfo = {}
            for i, goodsID in pairs(data.goodsID) do
                dropInfo.id = goodsID
                dropInfo.num = data.goodsNum[i]
                UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
            end
            local title = CommonHelper.getUIString(1503)
            UIManager.open(UIManager.UI.UIAward, awardData, title)
            break
        end
    end
end

-- 领取任务回调
function UIOperateActive:getTaskCallback(activeID, taskID)
    for i, data in pairs(self.taskData) do
        if data.taskID == taskID then
            data.finishFlag = 1
            operateActiveModel:setActiveTaskFinishFlag(activeID, taskID, data.finishFlag)
            self:setTaskPanel()
            self:setMoneyPanel()

            -- 显示奖励
            local awardData = {}
            local dropInfo = {}
            -- 显示顺序：道具物品、钻石、金币、体力
            for i, id in pairs(data.rewardGoodsID) do
                local num = data.rewardGoodsNum[i] or 0
                if id > 0 and num > 0 then
                    dropInfo.id = id
                    dropInfo.num = num
                    UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
                end
            end
            if data.rewardDimand > 0 then
                dropInfo.id = UIAwardHelper.ResourceID.Diamond
                dropInfo.num = data.rewardDimand
                UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
            end
            if data.rewardGold > 0 then
                dropInfo.id = UIAwardHelper.ResourceID.Gold
                dropInfo.num = data.rewardGold
                UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
            end
            -- if data.rewardEnergy > 0 then
            --     dropInfo.id = UIAwardHelper.ResourceID.Energy
            --     dropInfo.num = data.rewardDimand
            --     UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
            -- end
            UIManager.open(UIManager.UI.UIAward, awardData)
            break
        end
    end

    RedPointHelper.addCount(RedPointHelper.System.Activity, -1, activeID)

    if not self.activitysRedPoint[activeID] then
        print("Error: self.activitysRedPoint[activeID] is nil. activeID", activeID)
        return
    end
    self.activitysRedPoint[activeID].count = self.activitysRedPoint[activeID].count - 1
    self:showActiveRedPoint(activeID)
end

--- 领取月卡回调
function UIOperateActive:getCardCallBack(activeID, cardID)
    operateActiveModel:setMonthCardRewardTime(cardID)
    self:setCardPanel()

    RedPointHelper.addCount(RedPointHelper.System.Activity, -1, activeID)

    -- 月卡奖励钻石
    local diamond = getMonthCardDiamond(self.curActiveID, cardID)
    if diamond > 0 then
        -- 更新货币数量
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, diamond)
        self:setMoneyPanel()

        -- 显示奖励
        local awardData = {}
        local dropInfo = {}
        dropInfo.id = UIAwardHelper.ResourceID.Diamond
        dropInfo.num = diamond
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
        UIManager.open(UIManager.UI.UIAward, awardData)
    end
end

function UIOperateActive:exchangeCallback(activeID, taskID)

    for i, data in pairs(self.exchangeData) do
        if data.taskID == taskID then
            local acData = GetOperateActiveExchangeData(data.acId, data.taskID)

            -- 手动把背包要消耗的兑换道具干掉
            for i, info in pairs(acData.Exchange_Type1) do
                local id = info[1] or 0
                local num = info[2] or 0

                if id > 0 and num > 0 then
                    getGameModel():getBagModel():removeItems(id, num)
                end
            end

            data.count = data.count+1
            operateActiveModel:setExchangeFinishFlag(activeID, taskID, data.count)

            self:setExchangePanel()

            -- 显示奖励
            local awardData = {}
            local dropInfo = {}

            -- 显示顺序：道具物品、钻石、金币、体力
            for i, info in pairs(acData.Exchange_reward) do
                local id = info[1] or 0
                local num = info[2] or 0

                if id > 0 and num > 0 then
                    dropInfo.id = id
                    dropInfo.num = num
                    UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
                end
            end

            UIManager.open(UIManager.UI.UIAward, awardData)
            break
        end
    end

    RedPointHelper.addCount(RedPointHelper.System.Activity, -1, activeID)
    if not self.activitysRedPoint[activeID] then
        print("Error: self.activitysRedPoint[activeID] is nil. activeID", activeID)
        return
    end
    self.activitysRedPoint[activeID].count = self.activitysRedPoint[activeID].count - 1
    self:showActiveRedPoint(activeID)
end

function UIOperateActive:clickActiveRedPoint(activeID)
    if not self.activitysRedPoint[activeID] or self.activitysRedPoint[activeID].isOld then
        return
    end

    self.activitysRedPoint[activeID].isOld = true
    self.activitysRedPoint[activeID].count = self.activitysRedPoint[activeID].count - 1
    if self.activitysRedPoint[activeID].count <= 0 then
        self.activitysRedPoint[activeID] = nil
        self.activityRedPointNodes[activeID]:setVisible(false)
    end

    EventManager:raiseEvent(GameEvents.EventSeeActivity, {activityId = activeID} )
end

function UIOperateActive:showActiveRedPoint(activeID)
    if not self.activitysRedPoint[activeID] or self.activitysRedPoint[activeID].count <= 0 then
        self.activitysRedPoint[activeID] = nil
        self.activityRedPointNodes[activeID]:setVisible(false)
    else
        self.activityRedPointNodes[activeID]:setVisible(true)
    end
end

return UIOperateActive