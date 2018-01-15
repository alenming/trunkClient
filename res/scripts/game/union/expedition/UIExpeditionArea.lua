--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征区域地图
** 应  用:
********************************************************************/
--]]
local scheduler = require("framework.scheduler")

local expeditionModel = getGameModel():getExpeditionModel()

local UIExpeditionArea = class("UIExpeditionArea", function()
    return require("common.UIView").new()
end)

function UIExpeditionArea:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionArea:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionArea.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 退出按钮
    local backButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(backButton, handler(self, self.onClick))

    self.tipsTime = CsbTools.getChildFromPath(self.root, "MainPanel/MapPanel/TipsPanel/Time")
    self.tipsTime:setVisible(false)
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionArea:onOpen(openerUIID, ...)
    self.index = 0      -- 挑战的关卡索引
    self:initEvent()
    self:initNetwork()
    self:initTimer()
    self:createMap()
    self:initStage()
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionArea:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionArea:onClose()
    if self.schedulerHandler then
        scheduler.unscheduleGlobal(self.schedulerHandler)
        self.schedulerHandler = nil
    end
    self.tipsTime:setVisible(false)

    self:removeEvent()
    self:removeNetwork()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionArea:onTop(preUIID, ...)
    self:initTimer()
    self:initStage()
end

-- 当前界面点击回调
function UIExpeditionArea:onClick(obj)
    local btnName = obj:getName()
    if btnName == "BackButton" then             -- 返回
        UIManager.close()
    end
end

-- 创建地图
function UIExpeditionArea:createMap()
    local mapId = expeditionModel:getMapId()
    if mapId <= 0 then return end
    if self.mapId and self.mapId == mapId then return end
    self.mapId = mapId

    -- 地图节点
    local mapCsb = "ui_new/g_gamehall/g_guild/expedmap/map/ExpedMap_" .. mapId .. ".csb"
    local mapNode = getResManager():cloneCsbNode(mapCsb)
    if not mapNode then
        mapNode = cc.CSLoader:createNode(mapCsb)
    end
    self.mapNode = mapNode
    -- 自适应分辨率
    mapNode:setContentSize(display.size)
    ccui.Helper:doLayout(mapNode)
    -- 添加地图节点
    local scrollView = CsbTools.getChildFromPath(self.root, "MainPanel/MapPanel/MapScrollView")
    scrollView:setScrollBarEnabled(false)
    scrollView:setTouchEnabled(false)
    scrollView:removeAllChildren()
    scrollView:addChild(mapNode)
    -- 地图动画
    local action = cc.CSLoader:createTimeline(mapCsb)
    if action then
        mapNode:runAction(action)
        action:play("Normal", true)
    end

    local mapConf = getExpeditionMapConf(mapId)
    if not mapConf then return end
    self.mapConf = mapConf
    -- 地图名称
    local mapName = CsbTools.getChildFromPath(self.root, "MainPanel/MapPanel/BarImage1/TitleFontLabel")
    mapName:setString(CommonHelper.getStageString(mapConf.mapName))
end

-- 初始化关卡
function UIExpeditionArea:initStage()
    if not self.mapConf then return end

    local nowTime = getGameModel():getNow()
    local restEndTime = expeditionModel:getRestEndTime()
    local stagePanel = CsbTools.getChildFromPath(self.mapNode, "Stage")
    for i, node in pairs(stagePanel:getChildren()) do
        local stage = self.mapConf.Stages[i]
        if i == self.mapConf.stageNum then  -- Boss关
            self:initBossStage(node, nowTime, restEndTime, stage)
        elseif stage.headIcon == "" then    -- 普通关
            self:initCommonStage(node, nowTime, restEndTime)
        else                                -- 助战关
            self:initHelpStage(node, nowTime, restEndTime, stage)
        end
    end
end

-- 初始化普通关卡
function UIExpeditionArea:initCommonStage(node, nowTime, restEndTime)
    local stageID = tonumber(node:getName())            -- 关卡id
    local index = self:getIndexByStageId(stageID)       -- 关卡序列索引
    local restHp = expeditionModel:getStageHp(index)    -- BOSS剩余血量

    -- 普通关卡按钮
    local stageCommon = CsbTools.getChildFromPath(node, "StageCommon")
    stageCommon.index = index
    stageCommon:setVisible(true)
    CsbTools.initButton(stageCommon, handler(self, self.onChallengeClick))
    -- 休战: 当前时间 < 休息结束时间
    if nowTime < restEndTime then
        stageCommon:setTouchEnabled(false)
        local actionNode = CsbTools.getChildFromPath(node, "StageCommon/StageCommon")
        CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
    else
        stageCommon:setTouchEnabled(true)
        local actionNode = CsbTools.getChildFromPath(node, "StageCommon/StageCommon")
        if nil == restHp then   -- 未解锁
            CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
        elseif 0 == restHp then -- 已通过
            CommonHelper.playCsbAnimation(actionNode, "Over", true, nil)
        else                    -- 可挑战
            CommonHelper.playCsbAnimation(actionNode, "On", true, nil)
        end
    end

    -- 隐藏助战节点
    CsbTools.getChildFromPath(stageCommon, "StageHelp"):setVisible(false)
    -- 隐藏BOSS按钮
    CsbTools.getChildFromPath(node, "StageBoss"):setVisible(false)
end

-- 初始化助战关卡
function UIExpeditionArea:initHelpStage(node, nowTime, restEndTime, stage)
    local stageID = tonumber(node:getName())            -- 关卡id
    local index = self:getIndexByStageId(stageID)       -- 关卡序列索引
    local restHp = expeditionModel:getStageHp(index)    -- BOSS剩余血量

    -- 普通关卡按钮
    local stageCommon = CsbTools.getChildFromPath(node, "StageCommon")
    stageCommon.index = index
    stageCommon:setVisible(true)
    CsbTools.initButton(stageCommon, handler(self, self.onChallengeClick))
    -- 休战: 当前时间 < 休息结束时间
    if nowTime < restEndTime then            
        stageCommon:setTouchEnabled(false)
        local actionNode = CsbTools.getChildFromPath(stageCommon, "StageCommon")
        CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
    else
        stageCommon:setTouchEnabled(true)
        local actionNode = CsbTools.getChildFromPath(stageCommon, "StageCommon")
        if nil == restHp then   -- 未解锁
            CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
        elseif 0 == restHp then -- 已通过
            CommonHelper.playCsbAnimation(actionNode, "Over", true, nil)
        else                    -- 可挑战
            CommonHelper.playCsbAnimation(actionNode, "On", true, nil)
        end
    end

    -- 助战提示节点
    local helpNode = CsbTools.getChildFromPath(stageCommon, "StageHelp")
    helpNode:setVisible(true)
    local helpImage = CsbTools.getChildFromPath(helpNode, "StagePoint/HeroCut/HeroImage")
    CsbTools.replaceImg(helpImage, stage.headIcon)
    local greyButton = CsbTools.getChildFromPath(helpNode, "StagePoint/HeroCut/HeroImage_Grey")
    greyButton:loadTextures(stage.headIcon, stage.headIcon, nil, 1)
    if 0 == restHp then
        CommonHelper.playCsbAnimation(helpNode, "Unlock", true, nil)
    else
        CommonHelper.playCsbAnimation(helpNode, "Lock", true, nil)
    end
    --
    local helpButton = CsbTools.getChildFromPath(helpNode, "StagePoint")
    helpButton:setTouchEnabled(true)
    CsbTools.initButton(helpButton, function(obj)
        UIManager.open(UIManager.UI.UIExpeditionHelpTips, stage)
    end)

    -- 隐藏BOSS按钮
    CsbTools.getChildFromPath(node, "StageBoss"):setVisible(false)
end

-- 初始化BOSS关卡
function UIExpeditionArea:initBossStage(node, nowTime, restEndTime, stage)
    local stageID = tonumber(node:getName())            -- 关卡id
    local index = self:getIndexByStageId(stageID)       -- 关卡序列索引
    local restHp = expeditionModel:getStageHp(index)    -- BOSS剩余血量
    -- 普通关卡按钮
    local stageBoss = CsbTools.getChildFromPath(node, "StageBoss")
    stageBoss.index = index
    stageBoss:setVisible(true)
    CsbTools.initButton(stageBoss, handler(self, self.onChallengeClick))
    -- BOSS的特殊标识
    local nameLabel = CsbTools.getChildFromPath(stageBoss, "StageBoss/StageInfoBar/StageNameLabel")
    nameLabel:setString("BOSS")
    local StageImage = CsbTools.getChildFromPath(stageBoss, "StageBoss/StageInfoBar/StageImage")
    StageImage:loadTextures(stage.thumbnail, stage.thumbnail, nil, 1)
    local StageBar = CsbTools.getChildFromPath(stageBoss, "StageBoss/StageInfoBar/StageBar")
    -- 休战: 当前时间 < 休息结束时间
    if nowTime < restEndTime then
        StageImage:setBright(false)
        StageBar:setBright(false)
        stageBoss:setTouchEnabled(false)
        local actionNode = CsbTools.getChildFromPath(stageBoss, "StageBoss")
        CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
    else
        stageBoss:setTouchEnabled(true)
        local actionNode = CsbTools.getChildFromPath(stageBoss, "StageBoss")
        if nil == restHp then   -- 未解锁
            StageImage:setBright(false)
            StageBar:setBright(false)
            CommonHelper.playCsbAnimation(actionNode, "Lock", true, nil)
        elseif 0 == restHp then -- 已通过
            StageImage:setBright(true)
            StageBar:setBright(true)
            CommonHelper.playCsbAnimation(actionNode, "Over", true, nil)
        else                    -- 可挑战
            StageImage:setBright(true)
            StageBar:setBright(true)
            CommonHelper.playCsbAnimation(actionNode, "On", true, nil)
        end
    end

    -- 隐藏普通按钮
    CsbTools.getChildFromPath(node, "StageCommon"):setVisible(false)
end

-- 根据关卡id获取关卡序列索引
function UIExpeditionArea:getIndexByStageId(id)
    if not self.mapConf then return 0 end

    for i, v in pairs(self.mapConf.Stages or {}) do
        if v.stageID == id then
            return i
        end
    end
    return 0
end

-- 挑战点击
function UIExpeditionArea:onChallengeClick(obj)
    local index = obj.index
    local restHp = expeditionModel:getStageHp(index)   -- boss剩余血量
    if nil == restHp then   -- 未解锁
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1987))
    -- elseif 0 == restHp then -- 已通过
        -- CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1988))
    else                    -- 可挑战
        local nowTime = getGameModel():getNow()
        local warEndTime = expeditionModel:getWarEndTime()
        if nowTime >= warEndTime then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2006))
            return
        end
        self.index = index
        self:sendStageInfoCmd()
    end
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIExpeditionArea:initEvent()
    -- 添加远征关卡通过事件监听
    self.stagePassHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionStagePass, self.stagePassHandler)
    -- 添加远征胜利事件监听
    self.winHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionWin, self.winHandler)
    -- 添加远征失败事件监听
    self.failHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionFail, self.failHandler)
end

-- 移除事件回调
function UIExpeditionArea:removeEvent()
    -- 移除远征关卡通过事件监听
    if self.stagePassHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionStagePass, self.stagePassHandler)
        self.stagePassHandler = nil
    end
    -- 移除远征胜利事件监听
    if self.winHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionWin, self.winHandler)
        self.winHandler = nil
    end
    -- 移除远征失败事件监听
    if self.failHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionFail, self.failHandler)
        self.failHandler = nil
    end
end

-- 远征 胜利/失败 事件回调
function UIExpeditionArea:onEventCallback(eventName)
    if eventName == GameEvents.EventExpeditionWin or
       eventName == GameEvents.EventExpeditionFail then
        -- 注销定时器
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
        self:initTimer()
        self:initStage()
    elseif eventName == GameEvents.EventExpeditionStagePass then
        self:initStage()
    end
end


---------------------------------------------------------------------
-- 初始化网络回调
function UIExpeditionArea:initNetwork()
    -- 注册关卡信息的网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StageInfoSC)
    self.stageInfoHandler = handler(self, self.acceptStageInfoCmd)
    NetHelper.setResponeHandler(cmd, self.stageInfoHandler)
end

-- 移除网络回调
function UIExpeditionArea:removeNetwork()
    -- 移除关卡信息的网络回调
    if self.stageInfoHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StageInfoSC)
        NetHelper.removeResponeHandler(cmd, self.stageInfoHandler)
        self.stageInfoHandler = nil
    end
end

-- 发送关卡信息的请求
function UIExpeditionArea:sendStageInfoCmd()
    local index = self.index
    local buffData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.StageInfoCS)
    buffData:writeInt(index)
    NetHelper.request(buffData)
end

-- 接收关卡信息的请求
function UIExpeditionArea:acceptStageInfoCmd(mainCmd, subCmd, buffData)
    -- 注销定时器
    if self.schedulerHandler then
        scheduler.unscheduleGlobal(self.schedulerHandler)
        self.schedulerHandler = nil
    end

    local bossHp = buffData:readInt()
    local record = {}
    record.head = buffData:readInt()
    record.name = buffData:readCharArray(32)
    record.level = buffData:readChar()
    record.damage = buffData:readInt()
    expeditionModel:setStageHp(self.index, bossHp)
    UIManager.open(UIManager.UI.UIExpeditionChallenge, self.index, record)
end


---------------------------------------------------------------------
-- 初始化定时器回调
function UIExpeditionArea:initTimer()
    self.tipsTime:setVisible(false)
    local nowTime = getGameModel():getNow()
    local warEndTime = expeditionModel:getWarEndTime()
    local restEndTime = expeditionModel:getRestEndTime()
    -- 休战: 当前时间 < 休息结束时间
    if nowTime < restEndTime then
        if nil == self.schedulerHandler then
            self.schedulerHandler = scheduler.scheduleGlobal(handler(self, self.onExpeditionResting), 1)
        end
    -- 交战: 当前时间 >= 休息结束时间 and 当前时间 < 交战结束时间
    elseif nowTime < warEndTime then
        if nil == self.schedulerHandler then
            self.schedulerHandler = scheduler.scheduleGlobal(handler(self, self.onExpeditionWarring), 1)
        end
    end
end

-- 设置休息结束时间
function UIExpeditionArea:onExpeditionResting(dt)
    -- 休息结束: 当前时间大于远征休息结束时间
    local nowTime = getGameModel():getNow()
    local restEndTime = expeditionModel:getRestEndTime()
    if nowTime > restEndTime then
        -- 注销定时器
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
        self:initTimer()
        self:initStage()
    else
        local times = TimeHelper.restTime(restEndTime)
        self.tipsTime:setString(string.format(CommonHelper.getStageString(6093), times.day, times.hour, times.min, times.sec))
        self.tipsTime:setVisible(true)
    end
end

-- 设置交战结束时间
function UIExpeditionArea:onExpeditionWarring(dt)
    -- 远征结束: 当前时间大于远征结束时间, 将所有数据重置
    local nowTime = getGameModel():getNow()
    local warEndTime = expeditionModel:getWarEndTime()
    if nowTime > warEndTime then
        -- 注销定时器
        if self.schedulerHandler then
            scheduler.unscheduleGlobal(self.schedulerHandler)
            self.schedulerHandler = nil
        end
        self:initTimer()
        self:initStage()
    else
        local times = TimeHelper.restTime(warEndTime)
        self.tipsTime:setString(string.format(CommonHelper.getStageString(6001), times.day, times.hour, times.min, times.sec))
        self.tipsTime:setVisible(true)
    end
end

return UIExpeditionArea