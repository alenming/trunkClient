--------------------------------------------------
--名称:UIChatBag
--描述:聊天道具背包界面
--日期:2017年2月13日
--作者:wsy
--------------------------------------------------
require("game.comm.UIAwardHelper")
local ScrollViewExtend = require("common.ScrollViewExtend").new()
local bagModel = getGameModel():getBagModel()
local equipModel = getGameModel():getEquipModel()
local ChatBagType = {AllEquip = 1}

local UIChatBag = class("UIChatBag", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIChatBag:ctor()

end

-- 初始化
function UIChatBag:init()
    --初始化
    self.rootPath = ResConfig.UIChatBag.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.maskPanel = CsbTools.getChildFromPath(self.root, "MaskPanel")        -- 屏蔽层
    CsbTools.getChildFromPath(self.root, "MoneyPanel/MoneyPanel"):setVisible(false)
    --添加关闭事件
    local btnClose = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(btnClose, function()
        UIManager.close() 
    end)

    --发送按钮事件
    self.btnSale = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/SaleItemButton")
    CsbTools.getChildFromPath(self.btnSale, "Name"):setString(getUILanConfItem(2170))
    CsbTools.initButton(self.btnSale, function()
        local itemData = self.curBagData[self.bagCurItem]
        if nil == itemData then
            return
        end
        self.maskPanel:setVisible(true)
        -- 发送的装备id
        self.sendEquip = itemData
        UIManager.close()
    end)

    CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GetPathButton"):setVisible(false)
    CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/OtherPanel/EqInfoScrollView"):setScrollBarEnabled(false)

    self:initBagScrollview()
end

-- 初始化
function UIChatBag:onOpen(openerUIID, chatBagType)
    self.maskPanel:setVisible(false)

    self.bagCurTab = 1
    self.bagCurItem = 1
    self.sendEquip = nil
    local bagType = chatBagType or ChatBagType.AllEquip
    -- 背包容量
    if ChatBagType.AllEquip == bagType then
        self.curCapacity = equipModel:getEquipCount()
        self.maxCapacity = self.curCapacity
        self:getBagModelData(equipModel:getConfEquips())
    else
        self.curCapacity = bagModel:getCurCapacity()
        local config = getNewPlayerSettingConf()
        if nil == config then
            return
        end
        self.maxCapacity = config.MaxBagCapacity
        -- 获取背包模型数据和当前背包数据
        self:getBagModelData(bagModel:getItems())
    end

    self:getCurBagData()
    -- 初始化标签按钮
    self:initTabButton()
    -- 设置背包容量
    self:setCapacityLabel()
    -- 更新背包格子的信息
    self:updateItem()
    -- 更新选中的物品信息
    self:updateInfo()

    self.btnSale:setVisible(self.curCapacity > 0)
    self.view:scrollToTop(0.05, false)
end

function UIChatBag:onClose()
    return self.sendEquip
end

-- 背包模型数据
function UIChatBag:getBagModelData(bagItems)
    --背包模型数据
    self.bagModelData = {
        [1] = {},  --全部
        [2] = {},  --装备
        [3] = {},  --经验书
        [4] = {},  --消耗品
    }
    --分类数据
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
function UIChatBag:getCurBagData()
    self.curBagData = self.bagModelData[self.bagCurTab]
end

-- 设置背包容量文本
function UIChatBag:setCapacityLabel()
    local label     = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/CapacityLabel_0_0")
    label:setString(tostring(self.curCapacity .. "/" .. self.maxCapacity))
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
function UIChatBag:initTabButton()
    curTabName = "AllButton"
    for i, v in pairs(tabButton) do
        local button = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/" .. v.name)
        button:setTag(i)
        CsbTools.initButton(button, handler(self, self.onTabButtonClick), getUILanConfItem(v.lan),
            "AllButton/ButtonPanel/NameLabel", "AllButton/ButtonPanel")
        local node = CsbTools.getChildFromPath(button, "AllButton")
        if i == self.bagCurTab then
            button:setLocalZOrder(100)
            CommonHelper.playCsbAnimate(node, ResConfig.UIChatBag.Csb2.tab, "OnAnimation", false)
        else
            --button:setLocalZOrder(-1)
            --CommonHelper.playCsbAnimate(node, ResConfig.UIChatBag.Csb2.tab, "Normal", false)
            button:setVisible(false)
        end

        CsbTools.getChildFromPath(button, "AllButton/RedTipPoint"):setVisible(false)
    end
end

function UIChatBag:onTabButtonClick(obj)
    local objName = obj:getName()
    if curTabName == objName then return end

    self.bagCurTab = obj:getTag()

    -- 切换标签按钮状态
    local prevButton = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/" .. curTabName)
    prevButton:setLocalZOrder(-1)
    local prevNode = CsbTools.getChildFromPath(prevButton, "AllButton")
    prevNode:stopAllActions()
    CommonHelper.playCsbAnimate(prevNode, ResConfig.UIChatBag.Csb2.tab, "Normal", false)
    curTabName = objName
    local curbutton = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/" .. curTabName)
    curbutton:setLocalZOrder(100)
    local curNode = CsbTools.getChildFromPath(curbutton, "AllButton")
    curNode:stopAllActions()
    CommonHelper.playCsbAnimate(curNode, ResConfig.UIChatBag.Csb2.tab, "OnAnimation", false)    

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
function UIChatBag:initBagScrollview()
    self.view = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/AllScrollView")
    -- 获取节点大小
    local csb   = getResManager():getCsbNode(ResConfig.UIChatBag.Csb2.item)
    local item  = CsbTools.getChildFromPath(csb, "Item")
    local itemSize = item:getContentSize()
    csb:cleanup()
    -- 获取节点总数
    local maxCount = 100
    local config = getNewPlayerSettingConf()
    if config then
        maxCount = config.MaxBagCapacity
    end
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 5,        -- 每行节点个数
        defaultCount    = 20,       -- 初始节点个数
        maxCellCount    = maxCount, -- 最大节点个数
        csbName         = ResConfig.UIChatBag.Csb2.item,    -- 节点的CSB名称
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
function UIChatBag:setItemData(csbNode, idx)
    csbNode:setName(idx)
    local effect = csbNode:getChildByName("EffectNode")
    if effect then effect:removeFromParent() end

    CsbTools.getChildFromPath(csbNode, "Item/RedTipPoint"):setVisible(false)
    --
    local item = CsbTools.getChildFromPath(csbNode, "Item")
    item:setTag(idx)
    item:setTouchEnabled(true)
    item:setSwallowTouches(false)
    item:addTouchEventListener(handler(self, self.onItemTouch))

    -- 有数据
    if idx <= table.getn(self.curBagData or {}) then
        local propConf = getPropConfItem(self.curBagData[idx].config_id)
        --local count  = self.curBagData[idx].count
        UIAwardHelper.setPropItemOfConf(csbNode, propConf, nil)
        -- 效果
        if idx == self.bagCurItem then
            local effectNode = getResManager():cloneCsbNode(ResConfig.UIChatBag.Csb2.effect)
            effectNode:setName("EffectNode")
            csbNode:addChild(effectNode)
            --
            CommonHelper.playCsbAnimation(effectNode, "OnAnimation", false, nil)
        end
    -- 无数据
    else
        csbNode:setVisible(false)
        --UIAwardHelper.setPropItemOfConf(csbNode, nil, 0)
    end
end

function UIChatBag:onItemTouch(obj, event)
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

            -- 效果
            local csbNode = self.view:getChildByName(self.bagCurItem)
            local effectNode = getResManager():cloneCsbNode(ResConfig.UIChatBag.Csb2.effect)
            effectNode:setName("EffectNode")
            csbNode:removeChildByName("EffectNode")
            csbNode:addChild(effectNode)
            --
            CommonHelper.playCsbAnimation(effectNode, "OnAnimation", false, nil)
            --
            self:updateInfo()
        end
    end
end


-- 更新背包格子的信息
function UIChatBag:updateItem()
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
function UIChatBag:updateInfo()
    local infoPanel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel")
    local otherPanel = CsbTools.getChildFromPath(infoPanel, "OtherPanel")
    local eqPanel = CsbTools.getChildFromPath(infoPanel, "EqPanel")
    local goldImg = CsbTools.getChildFromPath(infoPanel, "GoldIco")    
    local moneyLab = CsbTools.getChildFromPath(infoPanel, "MoneyLabel")
    local kuangImage = CsbTools.getChildFromPath(infoPanel, "KuangImage")
    local tipsText = CsbTools.getChildFromPath(infoPanel, "TipsText")

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
        local goldLab = CsbTools.getChildFromPath(infoPanel, "MoneyLabel")
        goldImg:setVisible(true)
        moneyLab:setVisible(true)
        kuangImage:setVisible(true)
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
            local allItem = CsbTools.getChildFromPath(otherPanel, "AllItem")
            UIAwardHelper.setAllItemOfConf(allItem, propConf, 0)

            local nameLab   = CsbTools.getChildFromPath(otherPanel, "NameLabel")
            -- 道具名称
            local color = getItemLevelSettingItem(propConf.Quality).Color
            nameLab:setTextColor(cc.c4b(color[1], color[2], color[3], 255))
            nameLab:setString(CommonHelper.getPropString(propConf.Name))
            local countLab  = CsbTools.getChildFromPath(otherPanel, "CountLabel")
            countLab:setString(data.count)
            local descLab   = CsbTools.getChildFromPath(otherPanel, "EqInfoScrollView/ConditionLabel")
            descLab:setString(CommonHelper.getPropString(propConf.Desc))
        end
    else
        goldImg:setVisible(false)
        moneyLab:setVisible(false)
        kuangImage:setVisible(false)
        tipsText:setVisible(true)
    end
end

return UIChatBag