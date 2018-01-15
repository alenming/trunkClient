--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-08-09 10:03
** 版  本:	1.0
** 描  述:  头像更换界面
** 应  用:
********************************************************************/
--]]
local userModel = getGameModel():getUserModel()
local headModel = getGameModel():getHeadModel()

local ScrollViewExtend = require("common.ScrollViewExtend").new()

local UIHeadSetting = class("UIHeadSetting", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIHeadSetting:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIHeadSetting:init(...)
    self.rootPath = ResConfig.UIHeadSetting.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- UI文本
    CsbTools.getChildFromPath(self.root, "MainPanel/TitleText"):setString(CommonHelper.getUIString(1666))
    CsbTools.getChildFromPath(self.root, "MainPanel/UseButton/ButtonName"):setString(CommonHelper.getUIString(1014))
    self.tipsText = CsbTools.getChildFromPath(self.root, "MainPanel/TipsText")
    self.tipsText:setPositionY(self.tipsText:getPositionY() + 8)
    self.tipsText:setString("")

    -- 关闭按钮
    local btnClose = CsbTools.getChildFromPath(self.root, "MainPanel/CloseButton")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 使用按钮
    local btnUse = CsbTools.getChildFromPath(self.root, "MainPanel/UseButton")
    CsbTools.initButton(btnUse, handler(self, self.onClick))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIHeadSetting:onOpen(openerUIID, callback)
    self.callback = callback
    
    self.headIcon = {}
    self.curHeadID = userModel:getHeadID()        -- 当前使用的头像ID
    self.curIndex = 1
    self.newHeads = RedPointHelper.getSystemInfo(RedPointHelper.System.HeadUnlock)

    self:sortHeadIcon()
    self:initHeadScrollView()
end

function UIHeadSetting:sortHeadIcon()
    local headIconItem = getSystemHeadIconItem()
    if nil == headIconItem then
        print("Error: UIHeadSetting:sortHeadIcon, headIconItem==nil")
        return
    end
    -- 1. 插入当前使用头像
    for id, item in pairs(headIconItem) do
        local data = {}
        data.id = id
        data.icon = item.IconName
        data.tips = item.IconTips
        data.unlocked = true
        if id == self.curHeadID then
            table.insert(self.headIcon, 1, data)
            break
        end
    end
    -- 2. 插入已解锁
    for id, item in pairs(headIconItem) do
        local data = {}
        data.id = id
        data.icon = item.IconName
        data.tips = item.IconTips
        data.unlocked = true
        if id ~= self.curHeadID and headModel:isUnlocked(id) then
            table.insert(self.headIcon, data)
        end
    end
    -- 3. 插入未解锁
    for id, item in pairs(headIconItem) do
        local data = {}
        data.id = id
        data.icon = item.IconName
        data.tips = item.IconTips
        data.unlocked = false
        if id ~= self.curHeadID and not headModel:isUnlocked(id) then
            table.insert(self.headIcon, data)
        end
    end
end

-- 每次界面Open动画播放完毕时回调
function UIHeadSetting:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIHeadSetting:onClose()
    self.headIcon = nil
    self.curHeadID = nil
    self.curIndex = nil
    ScrollViewExtend:removeAllChild()

    if self.changeHeadHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.ChangeHeadIconSC)
        NetHelper.removeResponeHandler(cmd, self.changeHeadHandler)
        self.changeHeadHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIHeadSetting:onTop(preUIID, ...)

end

function UIHeadSetting:onClick(obj)
    local name = obj:getName()
    if "CloseButton" == name then
        UIManager.close()
    elseif "UseButton" == name then
        local data = self.headIcon[self.curIndex]
        if data and not data.unlocked then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(data.tips))
        elseif data and data.unlocked and self.curHeadID ~= userModel:getHeadID() then -- 不同头像
            self:sendChangeHeadCmd()
        else
            UIManager.close()
        end
    end
end

function UIHeadSetting:initHeadScrollView()
    self.headScrollView = CsbTools.getChildFromPath(self.root, "MainPanel/HeadScrollView")

    local csb = getResManager():getCsbNode(ResConfig.UIHeadSetting.Csb2.item)
    local cell = CsbTools.getChildFromPath(csb, "HeadPanel")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 7,                            -- 每行节点个数
        defaultCount    = 28,                           -- 初始节点个数
        maxCellCount    = #self.headIcon,               -- 最大节点个数
        csbName         = ResConfig.UIHeadSetting.Csb2.item, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "HeadPanel",                  -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.headScrollView,          -- 滚动区域
        distanceX       = 8,                            -- 节点X轴间距
        distanceY       = 2,                            -- 节点Y轴间距
        offsetX         = 8,                            -- 第一列的偏移
        offsetY         = 5,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setCellData),  -- 设置节点数据回调函数
    }
    ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
    ScrollViewExtend:reloadData()
end

function UIHeadSetting:setCellData(csbNode, idx)
    if nil == self.headIcon then
        csbNode:setVisible(false)
        return
    end
    local data = self.headIcon[idx]
    if nil == data then
        csbNode:setVisible(false)
        return
    end
    csbNode:setTag(idx)

    -- 设置头像节点的状态
    if data.id == self.curHeadID then
        CommonHelper.playCsbAnimate(csbNode, ResConfig.UIHeadSetting.Csb2.item, "Choose", false)
    elseif data.unlocked then
        CommonHelper.playCsbAnimate(csbNode, ResConfig.UIHeadSetting.Csb2.item, "Normal", false)
    elseif not data.unlocked then
        CommonHelper.playCsbAnimate(csbNode, ResConfig.UIHeadSetting.Csb2.item, "Lock", false)
    end

    local cell = CsbTools.getChildFromPath(csbNode, "HeadPanel")
    cell.data  = data
    cell.index = idx
    cell:addTouchEventListener(handler(self, self.onCellTouch))
    
    CsbTools.getChildFromPath(csbNode, "RedTipPoint"):setVisible(self.newHeads[data.id])

    local headImage = CsbTools.getChildFromPath(cell, "HeadImage")
    CsbTools.replaceImg(headImage, data.icon)
end

function UIHeadSetting:onCellTouch(obj, eventType)
    if 2 == eventType then
        local beginPos = obj:getTouchBeganPosition()
        local endPos = obj:getTouchEndPosition()
        if cc.pGetDistance(beginPos, endPos) > 50 then
            return
        end

        local data = obj.data
        local idx = obj.index
        if idx == self.curIndex or data.id == self.curHeadID then
            return
        end
        --
        local preData = self.headIcon[self.curIndex]
        local preHeadID = self.curHeadID
        local preIndex = self.curIndex
        -- 切换当前Item
        self.curHeadID = data.id
        self.curIndex = idx

        -- 如果上一个的不是正在使用的, 才做处理
        if preHeadID and preHeadID ~= userModel:getHeadID() then
            -- 如果有上一个
            if preIndex and preIndex > 0 then
                local preNode = self.headScrollView:getChildByTag(preIndex)
                if preData.unlocked then
                    CommonHelper.playCsbAnimate(preNode, ResConfig.UIHeadSetting.Csb2.item, "Normal", false)
                else
                    CommonHelper.playCsbAnimate(preNode, ResConfig.UIHeadSetting.Csb2.item, "Lock", false)
                end
            end
        end

        -- 如果当前点击的不是正在使用的, 才做处理
        if self.curHeadID and self.curHeadID ~= userModel:getHeadID() then
            local curNode = self.headScrollView:getChildByTag(self.curIndex)
            if data.unlocked then
                CommonHelper.playCsbAnimate(curNode, ResConfig.UIHeadSetting.Csb2.item, "On", false)
            else
                CommonHelper.playCsbAnimate(curNode, ResConfig.UIHeadSetting.Csb2.item, "OnLock", false)
            end
        end

        if data.unlocked then
            self.tipsText:setString("")
            MusicManager.playSoundEffect(obj:getName())
        else
            self.tipsText:setString(CommonHelper.getUIString(data.tips) or "")
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(data.tips))
            MusicManager.playFailSoundEffect()
        end
    end
end

-- 发送更换头像请求
function UIHeadSetting:sendChangeHeadCmd()
	-- 注册更换头像命令
	local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.ChangeHeadIconSC)
    self.changeHeadHandler = handler(self, self.acceptChangeHeadCmd)
	NetHelper.setResponeHandler(cmd, self.changeHeadHandler)

    local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.ChangeHeadIconCS)
    buffData:writeInt(self.curHeadID)
    NetHelper.request(buffData) -- 发送改头像
end

-- 接收更换头像请求
function UIHeadSetting:acceptChangeHeadCmd(mainCmd, subCmd, buffData)
    -- 注销更换头像命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.changeHeadHandler)
    self.changeHeadHandler = nil

    local headIconID = buffData:readInt()
    userModel:setHeadID(headIconID)

    if self.callback and "function" == type(self.callback) then
        self.callback()
    end
    UIManager.close()
end

return UIHeadSetting