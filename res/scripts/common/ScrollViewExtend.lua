--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-22 11:01
** 版  本:	1.0
** 描  述:  ScrollView控件的扩展(实现动态添加子节点，解决初始创建多个子节点导致界面卡顿的问题)
** 应  用:
********************************************************************/
--]]

--[[
tabParam = 
{
    rowCellCount,           -- 每行节点个数
    defaultCount,           -- 初始节点个数(每行个数的整数倍)
    maxCellCount,           -- 最大节点个数(每行个数的整数倍)
    csbName,                -- 节点的CSB名称
    csbUnlock,              -- 节点的解锁动画
    cellName,               -- 节点触摸层的名称
    cellSize,               -- 节点触摸层的大小
    uiScrollView,           -- 滚动区域
    distanceX,              -- 节点X轴间距
    distanceY,              -- 节点Y轴间距
    offsetX,                -- 第一列的偏移
    offsetY,                -- 第一行的偏移
    setCellDataCallback,    -- 设置节点数据回调函数
}
--]]
local ScrollViewExtend = class("ScrollViewExtend")

-- 初始化
function ScrollViewExtend:init(tabParam)
    self.rowCellCount   = tabParam.rowCellCount             -- 每行节点个数
    self.defaultCount   = tabParam.defaultCount             -- 初始节点个数
    self.maxCellCount   = tabParam.maxCellCount             -- 最大节点个数
    self.csbName        = tabParam.csbName                  -- 节点的CSB名称
    self.csbFiles       = tabParam.csbFiles                 -- 所有CSB名称(每个都不一样)
    self.csbAnimateName = tabParam.csbAnimateName           -- CSB动画名
    self.loopAnimate    = tabParam.loopAnimate or false     -- 动画是否循环
    self.cellScale      = tabParam.cellScale or 1.0         -- 缩放值
    self.csbUnlock      = tabParam.csbUnlock                -- 节点的解锁动画
    self.cellName       = tabParam.cellName                 -- 节点触摸层的名称
    self.cellSize       = tabParam.cellSize                 -- 节点触摸层的大小
    self.scrollView     = tabParam.uiScrollView             -- 滚动区域
    self.distanceX      = tabParam.distanceX or 0           -- 节点X轴间距
    self.distanceY      = tabParam.distanceY or 0           -- 节点Y轴间距
    self.offsetX        = tabParam.offsetX or 0             -- 第一列的偏移
    self.offsetY        = tabParam.offsetY or 0             -- 第一行的偏移
    self.setCellDataCallback = tabParam.setCellDataCallback -- 设置节点数据回调函数
    --
    self.viewSize   = self.scrollView:getContentSize()  -- 可视区域的大小
    self.direction  = self.scrollView:getDirection()    -- 滚动方向
    self.innerSize  = self:calculateInnerSize()         -- 滚动区域的大小
    self.scrollView:setTouchEnabled(true)
    self.scrollView:setBounceEnabled(true)
    self.scrollView:setScrollBarEnabled(tabParam.isBarEnabled or false)
    self.scrollView:setInnerContainerSize(self.innerSize)
    self.scrollView:addEventListener(function(scrollView, eventType) self:onScrollViewEvent(scrollView, eventType) end)
    self.innerPosX  = self.scrollView:getInnerContainerPosition().x     -- 滚动区域的坐标
    self.innerPosY  = self.scrollView:getInnerContainerPosition().y     -- 滚动区域的坐标
    --
    self.currentCount   = 0     -- 当前节点个数
    self.cellTable      = {}    -- 当前所有子节点
end

-- 创建
function ScrollViewExtend:create()
    local rows = math.ceil(self.defaultCount / self.rowCellCount)
    for i = 1, rows do
        self:createRow(0)
    end
end

-- 刷新数据
function ScrollViewExtend:reloadData()
    for i, csb in pairs(self.cellTable) do
        self.setCellDataCallback(csb, i)
    end
end

-- 刷新节点个数
function ScrollViewExtend:reloadList(defaultCount, maxCellCount)
    self:removeAllChild()
    self.cellTable = {}
    self.currentCount = 0

    self.defaultCount = defaultCount
    self.maxCellCount = maxCellCount

    self.innerSize  = self:calculateInnerSize()         -- 滚动区域的大小
    self.scrollView:setInnerContainerSize(self.innerSize)
    self.innerPosX  = self.scrollView:getInnerContainerPosition().x     -- 滚动区域的坐标
    self.innerPosY  = self.scrollView:getInnerContainerPosition().y     -- 滚动区域的坐标
    -- self:create()
    local rows = math.ceil(self.defaultCount / self.rowCellCount)
    for i = 1, rows do
        self:createRow(1)
    end
end

-- ScrollView滚动回调
function ScrollViewExtend:onScrollViewEvent(scrollView, eventType)
    if 9 == eventType then
        if self.currentCount < self.maxCellCount then
            if 1 == self.direction then  -- 垂直滚动
                local curInnerPosY = self.scrollView:getInnerContainerPosition().y
                if curInnerPosY - self.innerPosY > (self.cellSize.height * self.cellScale / 2) then
                    self:createRow(1)
                    self.innerPosY = self.innerPosY + self.cellSize.height * self.cellScale
                end
            elseif 2 == self.direction then  -- 水平滚动
                local curInnerPosX = self.scrollView:getInnerContainerPosition().x 
                if self.innerPosX - curInnerPosX > (self.cellSize.width * self.cellScale / 2) then
                    self:createRow(1)
                    self.innerPosX = self.innerPosX + self.cellSize.width * self.cellScale
                end
            end
        end
    end
end

-- 解锁(notAddLockRow, 解锁到最后一行, 不用增加行数)
function ScrollViewExtend:unLock(rows, notAddLockRow, nodeName, csbName, actionName)
    if notAddLockRow then
        for i = self.maxCellCount - self.rowCellCount + 1, self.currentCount do
            -- 播放解锁动画
            local csb = self.cellTable[i]
            local node = csb:getChildByName(nodeName)
            CommonHelper.playCsbAnimate(node, csbName, actionName, false, function()
                self.setCellDataCallback(csb, i)
            end)
        end
    else
        local height = self.cellSize.height * self.cellScale
        local h = rows * ( height + self.distanceY)
        self.innerSize.height = self.innerSize.height + h                     -- 滚动区域的大小
        self.scrollView:setInnerContainerSize(self.innerSize)
        self.scrollView:scrollToBottom(0.05, false)

        for i = 1, self.currentCount do
            local csb = self.cellTable[i]
            -- 垂直滚动需要重置已经创建节点的坐标
            if 1 == self.direction then
                csb:setPosition(self:calculatePos(i))
            end
            -- 播放解锁动画
            if i > self.maxCellCount - self.rowCellCount then
                local node = csb:getChildByName(nodeName)
                CommonHelper.playCsbAnimate(node, csbName, actionName, false, function()
                    self.setCellDataCallback(csb, i)
                end)
            end
        end
        for i = 1, rows do
            self:createRow(2)
        end
    end
end

-- 创建一行
function ScrollViewExtend:createRow(flag)
    for i = 1, self.rowCellCount do
        self:createNode(flag)
    end
end

-- 创建一个
function ScrollViewExtend:createNode(flag)
    if flag == 2 then
        self.maxCellCount = self.maxCellCount + 1
    end
    if self.currentCount + 1 > self.maxCellCount then
        return
    end
    self.currentCount = self.currentCount + 1

    local csb = nil
    local csbPath = self.csbName
    if self.csbName then
        csb = getResManager():cloneCsbNode(self.csbName)
    elseif self.csbFiles[self.currentCount] then
        csbPath = self.csbFiles[self.currentCount]
        csb = getResManager():cloneCsbNode(self.csbFiles[self.currentCount])
    end

    if not csb then
        print(">>>error: ScrollViewExtend:createNode csb is nil!!!")
        return
    end

    if self.csbAnimateName then
        local act = cc.CSLoader:createTimeline(csbPath)
	    csb:runAction(act)
        act:play(self.csbAnimateName, self.loopAnimate)
    end

    csb:setScale(self.cellScale)
    csb:setPosition(self:calculatePos(self.currentCount))
    self.scrollView:addChild(csb)
    table.insert(self.cellTable, csb)

    -- 为了可以拖动scrollview
    if self.cellName then
        local item = getChild(csb, self.cellName)       --csb是Node，没有区域，没有点击事件
        item:setSwallowTouches(false)
    end

    -- 动态创建的需要设置数据
    if flag == 1 then       -- 滚动创建
        self.setCellDataCallback(csb, self.currentCount)
    elseif flag == 2 then   -- 解锁创建
        self.setCellDataCallback(csb, self.currentCount)
    end
end

function ScrollViewExtend:removeAllChild()
	for k, csb in pairs(self.cellTable or {}) do
		self.scrollView:removeChild(csb, true)
	end
end

--计算坐标
function ScrollViewExtend:calculatePos(idx)
    local i = idx
    local h = self.innerSize.height
    local width  = self.cellSize.width * self.cellScale
    local height = self.cellSize.height * self.cellScale

    local r, c = 0, 0
    if 1 == self.direction then  -- 垂直滚动
        r = math.modf((i-1) / self.rowCellCount)      -- 行
        c = math.modf((i-1) % self.rowCellCount)      -- 列
    elseif 2 == self.direction then  -- 水平滚动
        r = math.modf((i-1) % self.rowCellCount)      -- 行
        c = math.modf((i-1) / self.rowCellCount)      -- 列
    end

    local x = self.offsetX + 0.5 * width + c * (width + self.distanceX)
    local y = h - self.offsetY - (0.5 * height + r * ( height + self.distanceY))

    return cc.p(x, y)
end

--计算滚动区域的大小
function ScrollViewExtend:calculateInnerSize()
    local width  = self.cellSize.width * self.cellScale
    local height = self.cellSize.height * self.cellScale
    local rows = math.ceil(self.maxCellCount / self.rowCellCount)

    if 1 == self.direction then     -- 垂直滚动
        local h = rows * (height + self.distanceY) + self.offsetY
        if h < self.viewSize.height then
            h = self.viewSize.height
        end

        return cc.size(self.viewSize.width, h)
    elseif 2 == self.direction then -- 水平滚动
        local w = rows * (width + self.distanceX) + self.offsetX
        if w < self.viewSize.width then
            w = self.viewSize.width
        end

        return cc.size(w, self.viewSize.height)    
    end
end

-- 扩展大小
function ScrollViewExtend:extendItem(count)
    self.maxCellCount = self.maxCellCount + count

    self.innerSize  = self:calculateInnerSize()
    self.scrollView:setInnerContainerSize(self.innerSize)
    self.innerPosX  = self.scrollView:getInnerContainerPosition().x
    self.innerPosY  = self.scrollView:getInnerContainerPosition().y
    -- 调整所有子节点的位置
    local children = self.scrollView:getChildren()
    for index, child in pairs(children) do
        child:setPosition(self:calculatePos(index))
    end
end

return ScrollViewExtend

