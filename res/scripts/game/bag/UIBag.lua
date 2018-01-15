--------------------------------------------------
--名称:UIBag
--描述:装物品用
--日期:2016年2月29日
--作者:Azure
--------------------------------------------------
require("game.comm.UIAwardHelper")

local ScrollViewExtend = require("common.ScrollViewExtend").new()
local bagModel = getGameModel():getBagModel()
local userModel = getGameModel():getUserModel()

local UIBag = class("UIBag", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIBag:ctor()

end

-- 初始化
function UIBag:init()
    --初始化
    self.rootPath = ResConfig.UIBag.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.maskPanel = getChild(self.root, "MaskPanel")        -- 屏蔽层

    --添加关闭事件
    local btnClose = getChild(self.root, "BackButton")
    CsbTools.initButton(btnClose, function()
        UIManager.close() 
    end)

    --添加按钮事件
    local btnSale = getChild(self.root, "MainPanel/InfoPanel/SaleItemButton")
    CsbTools.initButton(btnSale, function() 
        --CommonHelper.playCsbAnimation(getChild(btnSale, "GeneralButton"), "OnAnimation", false, nil)
        local itemData = self.curBagData[self.bagCurItem]
        if nil == itemData then
            return
        end
        self.maskPanel:setVisible(true)

        local propConf = getPropConfItem(itemData.config_id)
        local isEq = (propConf.Type == 1)

        if self.bUse then
            UIManager.open(UIManager.UI.UIBagUse, itemData, handler(self, self.saleOrUseCallback))
        else
            if isEq  then
                UIManager.open(UIManager.UI.UIBagTip, itemData, handler(self, self.saleOrUseCallback))
            else
                UIManager.open(UIManager.UI.UIBagSale, itemData, handler(self, self.saleOrUseCallback))
            end
        end
    end)

    -- 获取途径按钮    
    local getBtn = getChild(self.root, "MainPanel/InfoPanel/GetPathButton")
    CsbTools.initButton(
        getBtn, 
        function()
            --数据
            local data = self.curBagData[self.bagCurItem]
            -- 材料立即前往
            if data and data.config_id ~= nil then
                self.maskPanel:setVisible(true)
                UIManager.open(UIManager.UI.UIPropQuickTo, data.config_id)
            end
        end, 
        CommonHelper.getUIString(156), "Name", "Name"
    )
    
    getChild(self.root, "MainPanel/InfoPanel/OtherPanel/EqInfoScrollView"):setScrollBarEnabled(false)

    self:initBagScrollview()
end

-- 初始化
function UIBag:onOpen(openerUIID, curTab)
    self.maskPanel:setVisible(false)

    self.bagCurTab = curTab or 1
    self.bagCurItem = 1
    -- 背包当前容量
    self.curCapacity = bagModel:getCurCapacity()
    -- 背包最大容量
    local config = getNewPlayerSettingConf()
    if nil == config then
        return
    end
    self.maxCapacity = config.MaxBagCapacity

    self.clickItems = {}

    -- 获取背包模型数据和当前背包数据
    self:getBagModelData()
    self:getCurBagData()
    -- 初始化标签按钮
    self:initTabButton()
    self:calcItemRedPoint()
    -- 设置货币面板
    self:setMoneyPanel()
    -- 设置背包容量
    self:setCapacityLabel()
    -- 更新背包格子的信息
    self:updateItem()
    -- 更新选中的物品信息
    self:updateInfo()

    self.view:scrollToTop(0.05, false)
end

function UIBag:onTop()
    self:calcItemRedPoint()
    -- 获取背包模型数据和当前背包数据
    self:getBagModelData()
    self:getCurBagData()
    -- 设置货币面板
    self:setMoneyPanel()
    -- 设置背包容量
    self:setCapacityLabel()
    -- 更新背包格子的信息
    self:updateItem()
    -- 更新选中的物品信息
    self:updateInfo()
    
    self.maskPanel:setVisible(false)
end

function UIBag:onClose()
    self.clickItems = {}
end

-- 背包模型数据
function UIBag:getBagModelData()
    --背包模型数据
    self.bagModelData = {
        [1] = {},  --全部
        [2] = {},  --装备
        [3] = {},  --经验书
        [4] = {},  --消耗品
    }
    --分类数据
    local bagItems = bagModel:getItems()
    for k,v in pairs(bagItems) do
        --装备[唯一ID，配置ID] 非装备[配置ID，数量]  其中装备k>1000000
        local cfgId   = k < 1000000 and k or v
        local cfgItem = getPropConfItem(cfgId)
        if cfgItem then
            local t = cfgItem.BagLabel     --道具背包类型
            local temp = {unique_id = k, config_id = cfgId, tp = t, count = (t == 2 and 1 or v)}
            if t > 1 then   --需要能放在背包里的才可以
                table.insert(self.bagModelData[1], temp)     --放到全部
                table.insert(self.bagModelData[t], temp)     --分别放置
            end
        end
    end

    --排序算子：物品类型（从低到高）、等级限制(从高到低)、品质（从高到低）、ID（从小到大）
    local function sort_compare(a, b)
    	local item_a = getPropConfItem(a.config_id)
    	local item_b = getPropConfItem(b.config_id)
        if item_a.BagLabel < item_b.BagLabel then
            return true
        elseif item_a.BagLabel == item_b.BagLabel then
            if item_a.UseLevel > item_b.UseLevel then 
    	    	return true
    	    elseif item_a.UseLevel == item_b.UseLevel then
    	    	if item_a.Quality > item_b.Quality  then
    	    		return true
    	    	elseif item_a.Quality == item_b.Quality then
    	    		return item_a.ID < item_b.ID
    	    	end
    	    end
        end
    	return false
    end
    --排序数据
    for k,v in pairs(self.bagModelData) do
        table.sort(v, sort_compare)
    end
end

-- 当前背包的数据
function UIBag:getCurBagData()
    self.curBagData = self.bagModelData[self.bagCurTab]
end

-- 设置货币面板
function UIBag:setMoneyPanel()
    local goldLable     = getChild(self.root, "MoneyPanel/MoneyPanel/GoldCountLabel")
    local diamondLable  = getChild(self.root, "MoneyPanel/MoneyPanel/GemCountLabel")
    goldLable:setString(tostring(userModel:getGold()))
    diamondLable:setString(tostring(userModel:getDiamond()))
end

-- 设置背包容量文本
function UIBag:setCapacityLabel()
    local label     = getChild(self.root, "MainPanel/BagPanel/CapacityLabel_0_0")
    local itemCount = bagModel:getItemCount()
    label:setString(tostring(itemCount .. "/" .. self.curCapacity))
end


---------------------------------------------------------------------
-- 初始化标签按钮
local tabButton = { 
    [1] = {name = "AllButton", lan = 58},
    [2] = {name = "EqButton", lan = 59},
    [3] = {name = "ExpButton", lan = 526},
    [4] = {name = "CostButton", lan = 60},
}
local curTabName = "AllButton"
function UIBag:initTabButton()
    curTabName = "AllButton"
    self.tabRedPoint = {}
    for i, v in pairs(tabButton) do
        local button = getChild(self.root, "MainPanel/BagPanel/" .. v.name)
        button:setTag(i)
        CsbTools.initButton(button, handler(self, self.onTabButtonClick), getUILanConfItem(v.lan),
            "AllButton/ButtonPanel/NameLabel", "AllButton/ButtonPanel")
        local node = getChild(button, "AllButton")
        if i == self.bagCurTab then
            button:setLocalZOrder(100)
            CommonHelper.playCsbAnimate(node, ResConfig.UIBag.Csb2.tab, "OnAnimation", false)
        else
            button:setLocalZOrder(-1)
            CommonHelper.playCsbAnimate(node, ResConfig.UIBag.Csb2.tab, "Normal", false)
        end

        self.tabRedPoint[i] = {}
        self.tabRedPoint[i].obj   = getChild(button, "AllButton/RedTipPoint")
        self.tabRedPoint[i].obj:setVisible(false)
        self.tabRedPoint[i].redCount = 0
    end
end

function UIBag:onTabButtonClick(obj)
    local objName = obj:getName()
    if curTabName == objName then return end

    self.bagCurTab = obj:getTag()

    -- 切换标签按钮状态
    local prevButton = getChild(self.root, "MainPanel/BagPanel/" .. curTabName)
    prevButton:setLocalZOrder(-1)
    local prevNode = getChild(prevButton, "AllButton")
    prevNode:stopAllActions()
    CommonHelper.playCsbAnimate(prevNode, ResConfig.UIBag.Csb2.tab, "Normal", false)
    curTabName = objName
    local curbutton = getChild(self.root, "MainPanel/BagPanel/" .. curTabName)
    curbutton:setLocalZOrder(100)
    local curNode = getChild(curbutton, "AllButton")
    curNode:stopAllActions()
    CommonHelper.playCsbAnimate(curNode, ResConfig.UIBag.Csb2.tab, "OnAnimation", false)    

    -- 获取当前背包数据
    self:getCurBagData()
    --切换标签的时候，默认选中第一个格子，并更新格子，回到顶部
    self.bagCurItem = 1
    self:updateItem()
    self:updateInfo()
    self.view:scrollToTop(0.05, false)
end


---------------------------------------------------------------------
-- 初始化背包列表
function UIBag:initBagScrollview()
    self.view = getChild(self.root, "MainPanel/BagPanel/AllScrollView")
    -- 获取节点大小
    local csb   = getResManager():getCsbNode(ResConfig.UIBag.Csb2.item)
    local item  = getChild(csb, "Item")
    local itemSize = item:getContentSize()
    csb:cleanup()
    -- 获取节点总数
    local maxCount = bagModel:getCurCapacity() + 5
    local config = getNewPlayerSettingConf()
    if not config then return end
    if maxCount > config.MaxBagCapacity then
        maxCount = config.MaxBagCapacity
    end
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 5,        -- 每行节点个数
        defaultCount    = 40,       -- 初始节点个数
        maxCellCount    = maxCount, -- 最大节点个数
        csbName         = ResConfig.UIBag.Csb2.item,    -- 节点的CSB名称
        csbUnlock       = "UnlockAnimation",            -- 节点的解锁动画
        cellName        = "Item",                       -- 节点触摸层的名称
        cellSize        = itemSize,                     -- 节点触摸层的大小
        uiScrollView    = self.view,                    -- 滚动区域
        distanceX       = 4,                            -- 节点X轴间距
        distanceY       = 3,                            -- 节点Y轴间距
        offsetX         = 8,                            -- 第一列的偏移
        offsetY         = 5,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setItemData),  -- 设置节点数据回调函数
    }
    ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
end

-- 设置格子内容
function UIBag:setItemData(csbNode, idx)
    csbNode:setName(idx)
    local effect = csbNode:getChildByName("EffectNode")
    if effect then effect:removeFromParent() end
    --
    getChild(csbNode, "Item/RedTipPoint"):setVisible(false)
    --
    local item = getChild(csbNode, "Item")
    item:setTag(idx)
    item:setTouchEnabled(true)
    item:setSwallowTouches(false)
    item:addTouchEventListener(handler(self, self.onItemTouch))

    -- 有数据
    if idx <= table.getn(self.curBagData or {}) then
        local propConf = getPropConfItem(self.curBagData[idx].config_id)
        local count  = self.curBagData[idx].count
        UIAwardHelper.setPropItemOfConf(csbNode, propConf, count)
        -- 效果
        if idx == self.bagCurItem then
            local effectNode = getResManager():cloneCsbNode(ResConfig.UIBag.Csb2.effect)
            effectNode:setName("EffectNode")
            csbNode:addChild(effectNode)
            --
            CommonHelper.playCsbAnimation(effectNode, "OnAnimation", false, nil)
        end
        -- 红点
        local b = self.itemsRedPoint[self.curBagData[idx].config_id]
        if b and not self.clickItems[self.curBagData[idx].unique_id] then
            getChild(csbNode, "Item/RedTipPoint"):setVisible(b)
        end
    -- 已解锁
    elseif idx <= self.curCapacity then
        UIAwardHelper.setPropItemOfConf(csbNode, nil, 0)
    -- 未解锁
    else
        UIAwardHelper.setPropItemOfConf(csbNode, nil, 0)
        -- 效果
        local effectNode = getResManager():cloneCsbNode(ResConfig.UIBag.Csb2.effect)
        effectNode:setName("EffectNode")
        csbNode:addChild(effectNode)
        --
        CommonHelper.playCsbAnimation(effectNode, "Lock", false, nil)
    end
end

function UIBag:onItemTouch(obj, event)
    if 2 == event then
        MusicManager.playSoundEffect(obj:getName())
        local idx = obj:getTag()
        -- 重复
        if idx == self.bagCurItem then
            return
        end
        -- 滑动
        local beginPos = obj:getTouchBeganPosition()
        local endPos = obj:getTouchEndPosition()
        if cc.pGetDistance(beginPos, endPos) > 40 then
            return
        end

        -- 有数据
        if idx <= table.getn(self.curBagData) then
            -- 切换当前Item
            local preItem = self.bagCurItem
            -- 如果有上一个
            if preItem > 0 then
                -- local preNode = self.view:getChildByTag(preItem)
                local preNode = self.view:getChildByName(preItem)
                preNode:removeChildByName("EffectNode")
            end

            self.bagCurItem = idx

            -- 红点
            self:clickItemRedPoint(obj)
            -- 效果
            -- local csbNode = self.view:getChildByTag(self.bagCurItem)
            local csbNode = self.view:getChildByName(self.bagCurItem)
            local effectNode = getResManager():cloneCsbNode(ResConfig.UIBag.Csb2.effect)
            effectNode:setName("EffectNode")
            csbNode:removeChildByName("EffectNode")
            csbNode:addChild(effectNode)
            --
            CommonHelper.playCsbAnimation(effectNode, "OnAnimation", false, nil)
            --
            self:updateInfo()

        -- 已解锁
        elseif idx <= self.curCapacity then
            return

        -- 未解锁
        else
            self.maskPanel:setVisible(true)
            -- 判断解锁个数是否达到格子数上限
            if self.curCapacity >= self.maxCapacity then  
                CsbTools.addTipsToRunningScene(CommonHelper.getUIString(370))
            else
                --计算价格
                local line = self.curCapacity / 5 + 1
                local increasePayConf = getIncreasePayConfItem(line)
                if not increasePayConf then
                    print("Error: UIBag:onItemTouch -- line", line)
                    return
                end
                local price = increasePayConf.BagCost
                UIManager.open(UIManager.UI.UIBagUnlock, price, handler(self, self.unlockCallback))
            end
        end
    end
end


-- 更新背包格子的信息
function UIBag:updateItem()
    -- 无数据
    if #self.curBagData <= 0 then        
        self.bagCurItem = nil
    elseif self.bagCurItem > #self.curBagData then
        self.bagCurItem = #self.curBagData
    end

    -- 设置格子数据
    ScrollViewExtend:reloadData()
end

-- 更新选中的物品信息
function UIBag:updateInfo()
    local infoPanel = getChild(self.root, "MainPanel/InfoPanel")
    local otherPanel = getChild(infoPanel, "OtherPanel")
    local eqPanel = getChild(infoPanel, "EqPanel")
    local saleBtn = getChild(infoPanel, "SaleItemButton")
    local getBtn = getChild(infoPanel, "GetPathButton")
    local goldImg = getChild(infoPanel, "GoldIco")    
    local moneyLab = getChild(infoPanel, "MoneyLabel")
    local kuangImage = getChild(infoPanel, "KuangImage")
    local tipsText = getChild(infoPanel, "TipsText")

    -- 没有道具显示
    otherPanel:setVisible(false)
    eqPanel:setVisible(false)
    kuangImage:setVisible(false)
    tipsText:setVisible(false)

    local isShow = (self.bagCurItem ~= nil)
    if isShow then
        --数据
        local data = self.curBagData[self.bagCurItem]

        local propConf = getPropConfItem(data.config_id)
        local goldLab = getChild(infoPanel, "MoneyLabel")
        saleBtn:setVisible(true)
        getBtn:setVisible(true)
        goldImg:setVisible(true)
        moneyLab:setVisible(true)
        kuangImage:setVisible(true)

         --是否可以使用
        local useItemID = {
            [UIAwardHelper.ItemType.GoldBag] = true,
            [UIAwardHelper.ItemType.EnergyBag] = true,
            [UIAwardHelper.ItemType.ExpBag] = true,
            [UIAwardHelper.ItemType.DiamondBag] = true,
            [UIAwardHelper.ItemType.Treasure] = true,
        }
        self.bUse = useItemID[propConf.Type] and true or false
        local btnlab = getChild(infoPanel, "SaleItemButton/Name")
        btnlab:setString(getUILanConfItem(self.bUse and 1014 or 62))

        goldLab:setString(propConf.SellPrice)
        --是否是装备
        local isEq = (propConf.Type == 1)
        if isShow and isEq then
            eqPanel:setVisible(true)
            local UIEquipViewHelper = require("game.hero.UIEquipViewHelper")
            UIEquipViewHelper:setCsbInfo(eqPanel, nil, data.unique_id, 225)
        else
            otherPanel:setVisible(true)
            -- 道具图片
            local allItem = getChild(otherPanel, "AllItem")
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)

            local nameLab   = getChild(otherPanel, "NameLabel")
            -- 道具名称
            local color = getItemLevelSettingItem(propConf.Quality).Color
            nameLab:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
            nameLab:setString(CommonHelper.getPropString(propConf.Name))
            local countLab  = getChild(otherPanel, "CountLabel")
            countLab:setString(data.count)
            local descLab   = getChild(otherPanel, "EqInfoScrollView/ConditionLabel")
            descLab:setString(CommonHelper.getPropString(propConf.Desc))
        end
    else
        saleBtn:setVisible(false)
        getBtn:setVisible(false)
        goldImg:setVisible(false)
        moneyLab:setVisible(false)
        kuangImage:setVisible(false)
        tipsText:setVisible(true)
    end
end


-- 解锁格子结果回调
function UIBag:unlockCallback(bagLine)
    --更新背包容量
    self.curCapacity = self.curCapacity + 5 * bagLine
    bagModel:setCurCapacity(self.curCapacity)
    self:setCapacityLabel()

    -- 3. 创建解锁的格子
    local flag = self.curCapacity == self.maxCapacity
    local nodeName = "EffectNode"
    local csbName = ResConfig.UIBag.Csb2.effect
    local actionName = "UnlockAnimation"
    ScrollViewExtend:unLock(bagLine, flag, nodeName, csbName, actionName)
    MusicManager.playSoundEffect(MusicManager.commonSound.unlockBag)
end

-- 出售或者使用 结果回调
function UIBag:saleOrUseCallback(id, num)
    --使用后的处理，如果个数为1，直接删除该项，否则，个数减一，刷新显示
    for k, v in pairs(self.bagModelData[1]) do
        if v.unique_id == id then
            --更新模型数据,此处出售和使用都调用了出售接口
            ModelHelper.saleItem(v.unique_id, num)

            self:getBagModelData()
            self:getCurBagData()
            --
            self:updateItem()
            self:updateInfo()
            --
            self:setCapacityLabel()
        end
    end
end

function UIBag:calcItemRedPoint()
    self.itemsRedPoint = RedPointHelper.getBagRedPoint() or {}
    for itemId, itemVal in pairs(bagModel:getItems()) do
        local isClick = self.clickItems[itemId] and true or false
        if itemId > 1000000 then
            itemId = itemVal
        end

        local propConf = getPropConfItem(itemId)
        if propConf then
            if not isClick and self.itemsRedPoint[itemId] and self.tabRedPoint[propConf.BagLabel] then
                self.tabRedPoint[propConf.BagLabel].obj:setVisible(true)
                self.tabRedPoint[1].obj:setVisible(true)

                self.tabRedPoint[propConf.BagLabel].redCount = self.tabRedPoint[propConf.BagLabel].redCount + 1
                self.tabRedPoint[1].redCount = self.tabRedPoint[1].redCount + 1
            end
        end
    end 
end

-- 设置红点
function UIBag:clickItemRedPoint(node)
    local curData = self.curBagData[node:getTag()]
    if not curData then return end

    local itemId = curData.config_id
    self.clickItems[curData.unique_id] = true
    local redNode = getChild(node, "RedTipPoint")
    if redNode:isVisible() then
        redNode:setVisible(false)

        local propConf = getPropConfItem(itemId)
        if not propConf then
            print("getPropConfItem is nil", itemId)
            return
        end

        if not self.tabRedPoint[propConf.BagLabel] then
            print("error, bagLabel can't find", propConf.BagLabel, itemId)
            return
        end

        -- 相关标签
        self.tabRedPoint[propConf.BagLabel].redCount = self.tabRedPoint[propConf.BagLabel].redCount - 1
        self.tabRedPoint[propConf.BagLabel].obj
            :setVisible(self.tabRedPoint[propConf.BagLabel].redCount > 0)
        -- 全部标签
        self.tabRedPoint[1].redCount = self.tabRedPoint[1].redCount - 1
        self.tabRedPoint[1].obj:setVisible(self.tabRedPoint[1].redCount > 0)
    end
end

return UIBag