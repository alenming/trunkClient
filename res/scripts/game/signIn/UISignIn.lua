--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-07-27 14:46
** 版  本:	1.0
** 描  述:  签到主界面
** 应  用:
********************************************************************/
--]]

local ScrollViewExtend = require("common.ScrollViewExtend").new()
local PropTips = require("game.comm.PropTips")

local UISignIn = class("UISignIn", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UISignIn:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UISignIn:init(...)
    self.rootPath = ResConfig.UISignIn.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local accumText = getChild(self.root, "MainPanel/SignPanel/TitleText_2")
    accumText:setString(CommonHelper.getUIString(252))

    local btnBack = getChild(self.root, "MainPanel/BackButton")   -- 关闭按钮
    CsbTools.initButton(btnBack, handler(self, self.onClick))

    local btnSign = getChild(self.root, "MainPanel/SignPanel/SignButton/SignButton")   -- 签到按钮
    CsbTools.initButton(btnSign, handler(self, self.onClick))

    self:initSignScrollView()
    self:initAccumulateScrollView()
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UISignIn:onOpen(openerUIID, ...)
    self.propTips = PropTips.new()

    local userModel = getGameModel():getUserModel()
    self.mTotalSignSucCount = userModel:getTotalSignSucCount()      -- 当前已经领取的阶段奖励的次数
    --第一次为0取奖励数据要加1
    self.monthSignDay = userModel:getMonthSignDay()                 -- 当月累计签到天数
    self.totalSignDay = userModel:getTotalSignDay()                 -- 总共累计签到次数
    self.daySignFlag = userModel:getDaySignFlag()                   -- 是否已经签到，0-未签到，1-已经签到
    self.nowTime = os.date("*t", getGameModel():getNow())

    self.signCfg = getMonthSignConf(self.nowTime.month)
    print(",,,,,,,,,,,,,,,,,self.mTotalSignSucCount="..self.mTotalSignSucCount)
    self.conCfg = getConDaySignConf(self.mTotalSignSucCount+1) -- 在哪个阶段直接获取当前阶段的数据

    self:setSignMonth()
    self:setSignCount()
    self:setSignBtnState()

    ScrollViewExtend:reloadData()
    self:reloadAccmulateData()
end


function UISignIn:ReFreshUI()
    --整点平滑过度刷新
    local userModel = getGameModel():getUserModel()
    self.daySignFlag = userModel:getDaySignFlag()           -- 是否已经签到，0-未签到，1-已经签到

    local oldMonth = self.nowTime.month
    self.nowTime = os.date("*t", getGameModel():getNow())
    local newMonth = self.nowTime.month
    if oldMonth~=newMonth then
        print("过了一个月了")
        userModel:setMonthSignDay(0)
    end

    self.monthSignDay = userModel:getMonthSignDay()         -- 当月累计签到天数
    self.signCfg = getMonthSignConf(self.nowTime.month)

    self.conCfg = getConDaySignConf(self.mTotalSignSucCount+1) -- 在哪个阶段直接获取当前阶段的数据

    self:setSignMonth()
    self:setSignCount()
    self:setSignBtnState()

    ScrollViewExtend:reloadData()
    self:reloadAccmulateData()
end


-- 每次界面Open动画播放完毕时回调
function UISignIn:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UISignIn:onClose()
    self.propTips:removePropAllTips()
    self.propTips = nil
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UISignIn:onTop(preUIID, ...)

end

-- 按钮点击回调
function UISignIn:onClick(obj)
    local name = obj:getName()
    if "BackButton" == name then
        UIManager.close()
    elseif "SignButton" == name then
        self:sendSignInCmd()
    end
end

-- 设置签到月份
function UISignIn:setSignMonth()
    local titleText = getChild(self.root, "MainPanel/SignPanel/BarImage1/TitleText")
    titleText:setString(string.format(CommonHelper.getUIString(253), self.nowTime.month))
end

-- 设置每日签到奖励内容
function UISignIn:initSignScrollView()
    self.signScrollView = getChild(self.root, "MainPanel/SignPanel/SignScrollView")
    local csb = getResManager():getCsbNode(ResConfig.UISignIn.Csb2.item)
    local cell = getChild(csb, "SignPanel")
    local cellSize = cell:getContentSize()
    csb:cleanup()
    --csb:release()
    -- 1.创建初始的格子
    local tabParam = 
    {
        rowCellCount    = 7,                            -- 每行节点个数
        defaultCount    = 26,                           -- 初始节点个数
        maxCellCount    = 26,                           -- 最大节点个数
        csbName         = ResConfig.UISignIn.Csb2.item, -- 节点的CSB名称
        csbUnlock       = nil,                          -- 节点的解锁动画
        cellName        = "SignPanel",                  -- 节点触摸层的名称
        cellSize        = cellSize,                     -- 节点触摸层的大小
        uiScrollView    = self.signScrollView,          -- 滚动区域
        distanceX       = 8,                            -- 节点X轴间距
        distanceY       = 9,                            -- 节点Y轴间距
        offsetX         = 8,                            -- 第一列的偏移
        offsetY         = 9,                            -- 第一行的偏移
        setCellDataCallback = handler(self, self.setDailyCellData),  -- 设置节点数据回调函数
    }
    ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
    self.signScrollView:setTouchEnabled(false)
end

function UISignIn:setDailyCellData(csbNode, idx)
    local data = self.signCfg[idx]
    if nil == data then
        csbNode:setVisible(false)
        return
    end
    csbNode:setTag(idx)
    csbNode:stopAllActions()

    -- 设置物品状态
    if 0 == self.daySignFlag then       -- 0-当天未签到
        if idx <= self.monthSignDay then            -- 已签到
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Signed", false)
        elseif idx == self.monthSignDay + 1 then    -- 可签到
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Next", false)
        elseif idx > self.monthSignDay + 1 then     -- 未签到
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Normal", false)
        end
    elseif 1 == self.daySignFlag then   -- 1-当天已签到
        if idx <= self.monthSignDay then            -- 已签到
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Signed", false)
        elseif idx > self.monthSignDay then         -- 未签到
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Normal", false)
        end
    end

    local propConf = getPropConfItem(data.nGoodsID)
    if propConf then
        -- 道具图标
        local allItem = getChild(csbNode, "SignPanel/AllItem")
        UIAwardHelper.setAllItemOfConf(allItem, propConf, data.nShowNum)
        -- 道具tips
        local touchPanel = getChild(allItem, "MainPanel")
        self.propTips:addPropTips(touchPanel, propConf)
    end
end

-- 设置累计签到天数
function UISignIn:setSignCount()
    local signCount = getChild(self.root, "MainPanel/SignPanel/SignCount")
    signCount:setString(string.format("%d / %d", self.totalSignDay, self.conCfg.DayNeeds))
end

-- 设置累计签到奖励内容
function UISignIn:initAccumulateScrollView()
    self.tabScrollView = getChild(self.root, "MainPanel/SignPanel/TabScrollView")
    self.tabScrollView:setScrollBarEnabled(false)

    -- 设置累计签到奖励内容
    for i = 1, 3 do
        local csb = getResManager():cloneCsbNode(ResConfig.UISignIn.Csb2.item)
        csb:setPosition(55, 245 - 95 * (i - 1))
        csb:setTag(i)
        self.tabScrollView:addChild(csb)
    end
end

function UISignIn:reloadAccmulateData()
    for i = 1, 3 do
        local csbNode = self.tabScrollView:getChildByTag(i)
        -- 获取累计签到奖励配置
        local data = self.conCfg[i]
        if nil == data then
            csbNode:setVisible(false)
            return
        end
        csbNode:stopAllActions()

        -- 设置物品状态
        if self.mTotalSignSucCount < self.conCfg.DayNeeds then         -- 未达成
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Normal", false)
        elseif self.mTotalSignSucCount == self.conCfg.DayNeeds then    -- 已达成
            CommonHelper.playCsbAnimate(csbNode, ResConfig.UISignIn.Csb2.item, "Next", false)
        end

        local propConf = getPropConfItem(data.nGoodsID)
        -- 道具图标
        local allItem = getChild(csbNode, "SignPanel/AllItem")
        UIAwardHelper.setAllItemOfConf(allItem, propConf, data.nShowNum)
        -- 道具tips
        local touchPanel = getChild(allItem, "MainPanel")
        self.propTips:addPropTips(touchPanel, propConf)
    end
end

-- 设置签到按钮状态
function UISignIn:setSignBtnState()
    local btnSign = getChild(self.root, "MainPanel/SignPanel/SignButton")
    btnSign:stopAllActions()
    -- 是否已经签到，0-未签到，1-已经签到
    if 0 == self.daySignFlag then
        local btnText = getChild(self.root, "MainPanel/SignPanel/SignButton/SignButton/ButtonName")
        btnText:setString(CommonHelper.getUIString(250))
        CommonHelper.playCsbAnimate(btnSign, ResConfig.UISignIn.Csb2.btn, "Sign", false)
    elseif 1 == self.daySignFlag then
        local btnText = getChild(self.root, "MainPanel/SignPanel/SignButton/SignedButton/ButtonName")
        btnText:setString(CommonHelper.getUIString(251))
        CommonHelper.playCsbAnimate(btnSign, ResConfig.UISignIn.Csb2.btn, "Signed", false)
    end
end

-- 发送签到请求
function UISignIn:sendSignInCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.SignCS)
    NetHelper.requestWithTimeOut(buffData,
        NetHelper.makeCommand(MainProtocol.User, UserProtocol.SignSC),
        handler(self, self.acceptSignInCmd))
end

-- 接收签到请求
function UISignIn:acceptSignInCmd(mainCmd, subCmd, buffData)
    local userModel = getGameModel():getUserModel()
    -- 显示的奖励内容
    local reward = {}

    self.daySignFlag = buffData:readInt()       -- 是否已经签到，0-未签到，1-已经签到
    userModel:setDaySignFlag(self.daySignFlag)
    -- 设置签到按钮状态
    self:setSignBtnState()

    -- 1. 判断是否已经完成当月每日签到
    if self.monthSignDay < 26 then
        self.monthSignDay = self.monthSignDay + 1   -- 当月签到天数
        userModel:setMonthSignDay(self.monthSignDay)
        -- 设置当日物品状态
        self:setDailyCellData(self.signScrollView:getChildByTag(self.monthSignDay), self.monthSignDay)

        -- 每日签到奖励内容
        local daySignData = self.signCfg[self.monthSignDay]
        if daySignData then
            local data = {}
            data.id = daySignData.nGoodsID
            -- vip双倍计算
            data.num = daySignData.nGoodsNum
            table.insert(reward, data)
        end
    end

    self.totalSignDay  = self.totalSignDay + 1     -- 累计签到次数
    userModel:setTotalSignDay(self.totalSignDay)

    -- 2. 判断是否已经达成累计签到天数
    if self.totalSignDay >= self.conCfg.DayNeeds then   -- 已达成
        -- 累计签到奖励内容
        for i=1, 3 do
            local conSignData = self.conCfg[i]
            if conSignData then
                local data = {}
                data.id = conSignData.nGoodsID
                data.num = conSignData.nGoodsNum
                table.insert(reward, data)
            end
        end

        -- 是否到下一阶段了
        --self.mTotalSignSucCount = self.conCfg.DayNeeds == self.totalSignDay and self.mTotalSignSucCount + 1 or self.mTotalSignSucCount
        self.mTotalSignSucCount = self.mTotalSignSucCount + 1
        userModel:setTotalSignSucCount(self.mTotalSignSucCount)
        self.conCfg = getConDaySignConf(self.mTotalSignSucCount + 1)


        self:reloadAccmulateData()
    end
    -- 设置累计签到天数
    self:setSignCount()

    -- 显示奖励
    local awardData = {}
    local dropInfo = {}
    for i, v in pairs(reward) do
        dropInfo.id = v.id
        dropInfo.num = v.num
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end
    if awardData and #awardData > 0 then
        UIManager.open(UIManager.UI.UIAward, awardData)
    end

    RedPointHelper.addCount(RedPointHelper.System.Sign, -1)
end

return UISignIn