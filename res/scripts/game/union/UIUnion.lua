--[[
	公会主界面
	1. 显示公会建筑物
--]]
local scheduler = require("framework.scheduler")

local expeditionModel = getGameModel():getExpeditionModel()

local UIUnion = class("UIUnion", function ()
	return require("common.UIView").new()
end)

-- csb文件
local csbFile = ResConfig.UIUnion.Csb2
local fogFile = "ui_new/w_worldmap/EliteMaskFog.csb"

-- 可以点击的入口
local enterInfo = {
    unionHall = {path = "GuildHouse", lan = 293, subSystem = 1},
    expedition = {path = "Dock", lan = 295, subSystem = 2},
    mercenary = {path = "ExpedHouse", lan = 1953, subSystem = 3},
    guildShop = {path = "GuildShop", lan = 2042, subSystem = 4},
    unKnow1 = {path = "Church", lan = 11, subSystem = 5},
    unKnow2 = {path = "Sealtai", lan = 11, subSystem = 6},
}

function UIUnion:ctor()
    self.rootPath = csbFile.union
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 滚动列表
    self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/MainScrollView")
    self.scroll:setScrollBarEnabled(false)
    -- 入口
    self.enterBtn = {}
    for k, v in pairs(enterInfo) do
        self.enterBtn[k] = CsbTools.getChildFromPath(self.root, "MainPanel/MainScrollView/" .. v.path)
        print(self.enterBtn[k], k)
        self.enterBtn[k]:getChildByName("NameText"):setString(CommonHelper.getUIString(v.lan))
        CsbTools.initButton(self.enterBtn[k], handler(self, self.enterBtnCallBack), nil, nil, k)
        -- 禁用远征按钮
        if k == "expedition" then
            self.enterBtn[k]:setTouchEnabled(false)
        end
    end
    -- 返回按钮
    self.backBtn = CsbTools.getChildFromPath(self.root, "MainPanel/BackButton")
    CsbTools.initButton(self.backBtn, handler(self, self.backBtnCallback))

    -- 喇叭按钮
    local talkButton = CsbTools.getChildFromPath(self.root, "MainPanel/TalkButton")
    CsbTools.getChildFromPath(self.root, "MainPanel/TalkButton/Button/Panel_1"):setTouchEnabled(false)
    CsbTools.initButton(talkButton, function() 
        UIManager.open(UIManager.UI.UIChat)
    end)

    -- 聊天界面
    self.talkPanel = CsbTools.getChildFromPath(self.root, "MainPanel/TalkPanel")
    CsbTools.getChildFromPath(self.root, "MainPanel/TalkPanel/TalkPanel"):setTouchEnabled(false)
    self.talkView = CsbTools.getChildFromPath(self.talkPanel, "TalkPanel/TalkPanel/TalkScrollView")
    self.talkView:setScrollBarEnabled(false)
    self.talkView:removeAllChildren()
    self.talkViewSize = self.talkView:getContentSize()
    -- 录音按钮
    self.recordChatButton = CsbTools.getChildFromPath(self.talkPanel, "TalkPanel/TalkPanel/GuildChatButton")
    self.recordChatButton:addTouchEventListener(handler(self, self.touchRecordCallBack))
    self.recordChatButton:setVisible(false)

    -- 显示录音
    self.recordVoice = (require "game.chat.ChatRecord").new()
    self.recordVoice:setPosition(cc.p(display.cx, display.cy))
    self:addChild(self.recordVoice)

    -- 顶部的会徽和公会名
    self.emblemSpr = CsbTools.getChildFromPath(self.root, "MainPanel/Title/GuildLogoItem/Logo/Logo")
    self.unionName = CsbTools.getChildFromPath(self.root, "MainPanel/Title/TitleText")
end

function UIUnion:onOpen()
    self.backBtn:setTouchEnabled(true)
    self:showBuidRedPoint()

    CommonHelper.playCsbAnimate(self.root, self.rootPath, "Open", false, function()
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "Normal", true, nil, true)
    end, true)

    self.scroll:scrollToPercentHorizontal(50, 0.1, true)

    self:initEvent()
    self:initNetwork()
    self:initTimer()
    self:sendExpeditionInfoCmd()

    local unionModel = getGameModel():getUnionModel()
    local emblemConf = getUnionBadgeConfItem()
    self.unionName:setString(unionModel:getUnionName())
    CsbTools.replaceSprite(self.emblemSpr, emblemConf[unionModel:getEmblem()])

    -- 获取新的聊天信息
    local newMessage = ChatHelper.getNewMessages(getGameModel():getUserModel():getUserID(), 0)
    for k, v in pairs(newMessage) do
        self:eventChatCallBack(_, v)
    end
end

function UIUnion:onClose()
    self:removeEvent()
    self:removeNetwork()
    -- 注销定时器
    if self.expeditionScheduler then
        scheduler.unscheduleGlobal(self.expeditionScheduler)
        self.expeditionScheduler = nil
    end
    self.recordVoice:stopRecordVoice()
end

function UIUnion:onTop(preUIID, ...)
    local unionModel = getGameModel():getUnionModel()
    local emblemConf = getUnionBadgeConfItem()
    self.unionName:setString(unionModel:getUnionName())
    CsbTools.replaceSprite(self.emblemSpr, emblemConf[unionModel:getEmblem()])

    self:initTimer()
    self:showBuidRedPoint()
end

function UIUnion:enterBtnCallBack(obj)
    obj.soundId = nil
    local btnName = obj:getName()
    if btnName == enterInfo.unionHall.path then
        UIManager.open(UIManager.UI.UIUnionHall)
    elseif btnName == enterInfo.expedition.path then
        UIManager.open(UIManager.UI.UIExpeditionWorld)
    elseif btnName == enterInfo.mercenary.path then
        UIManager.open(UIManager.UI.UIUnionMercenary)
    elseif btnName == enterInfo.guildShop.path then
        UIManager.open(UIManager.UI.UIShop, ShopType.UnionShop)
    else
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(11))
    end
end

function UIUnion:backBtnCallback(obj)
    UnionHelper.reGetStamp.unionInfo = 0
    UnionHelper.reGetStamp.unionMemberInfo = 0
    UnionHelper.reGetStamp.unionAuditList = 0    

	SceneManager.loadScene(SceneManager.Scene.SceneHall)
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIUnion:initEvent()
    -- 监听通知
    self.funcHandler = handler(self, self.funcCallBack)
    EventManager:addEventListener(GameEvents.EventUnionFunc, self.funcHandler)
    -- 添加远征目标设定事件监听
    self.mapSetHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionMapSet, self.mapSetHandler)
    -- 添加远征开始事件监听
    self.startHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionStart, self.startHandler)
    -- 添加远征胜利事件监听
    self.winHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionWin, self.winHandler)
    -- 添加远征失败事件监听
    self.failHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionFail, self.failHandler)
    -- 聊天监听
    self.chatHandler = handler(self, self.eventChatCallBack)
    EventManager:addEventListener(GameEvents.EventChatMessage, self.chatHandler)
end

-- 移除事件回调
function UIUnion:removeEvent()
    if self.funcHandler then
        EventManager:removeEventListener(GameEvents.EventUnionFunc, self.funcHandler)
        self.funcHandler = nil
    end
    -- 移除远征目标设定事件监听
    if self.mapSetHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionMapSet, self.mapSetHandler)
        self.mapSetHandler = nil
    end
    -- 移除远征开始事件监听
    if self.startHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionStart, self.startHandler)
        self.startHandler = nil
    end
    -- 移除远征胜利事件监听
    if self.winHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionWin, self.winHandler)
        self.winHandler = nil
    end
    -- 移除远征失败事件监听
    if self.failHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionFail, self.failHandler)
        self.winHandler = nil
    end

    if self.chatHandler then
        EventManager:removeEventListener(GameEvents.EventChatMessage, self.chatHandler)
        self.chatHandler = nil
    end
end

function UIUnion:funcCallBack(eventName, params)
	if params.funcType == UnionHelper.FuncType.Kick then
		self:runAction(cc.Sequence:create(  
    		cc.DelayTime:create(1),
    		cc.CallFunc:create(function()
				SceneManager.loadScene(SceneManager.Scene.SceneHall)
    		end)))
	end
end

-- 远征 目标设定, 通关, 胜利, 失败 事件回调
function UIUnion:onEventCallback(eventName)
    if eventName == GameEvents.EventExpeditionMapSet then
        self:initTimer()
    elseif eventName == GameEvents.EventExpeditionStart then
        -- 移除休战定时器, 创建交战定时器
        if self.expeditionScheduler then
            scheduler.unscheduleGlobal(self.expeditionScheduler)
            self.expeditionScheduler = nil
        end
        self:initTimer()
    elseif eventName == GameEvents.EventExpeditionWin then
        -- 移除交战定时器, 创建休战定时器
        if self.expeditionScheduler then
            scheduler.unscheduleGlobal(self.expeditionScheduler)
            self.expeditionScheduler = nil
        end
        self:initTimer()
    elseif eventName == GameEvents.EventExpeditionFail then
        -- 移除交战定时器, 创建休战定时器
        if self.expeditionScheduler then
            scheduler.unscheduleGlobal(self.expeditionScheduler)
            self.expeditionScheduler = nil
        end
        self:initTimer()
    end
end


---------------------------------------------------------------------
-- 初始化网络回调
function UIUnion:initNetwork()
    -- 公会远征: 请求远征信息
    local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.InfoSC)
    self.infoHandler = handler(self, self.acceptExpeditionInfoCmd)
    NetHelper.setResponeHandler(cmd, self.infoHandler)
end

-- 移除网络回调
function UIUnion:removeNetwork()
    -- 注销请求远征信息网络回调
    if self.infoHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.InfoSC)
        NetHelper.removeResponeHandler(cmd, self.infoHandler)
        self.infoHandler = nil
    end
end

-- 发送请求远征信息的命令
function UIUnion:sendExpeditionInfoCmd()
    -- 发送命令
    local buffData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.InfoCS)
    NetHelper.request(buffData)
end
-- 接收请求远征信息的命令
function UIUnion:acceptExpeditionInfoCmd(mainCmd, subCmd, buffData)
    local expeditionModel = getGameModel():getExpeditionModel()
    expeditionModel:init(buffData)
    -- 激活远征按钮
    local expeditionButton = self.enterBtn.expedition
    if expeditionButton then
        expeditionButton:setTouchEnabled(true)
        print("UIUnion:acceptExpeditionInfoCmd 激活远征按钮")
    end
    self:initTimer()

    -- 预加载远征地图资源
    local curMapId = expeditionModel:getMapId() or 1
    local mapCsb = "ui_new/g_gamehall/g_guild/expedmap/map/ExpedMap_" .. curMapId .. ".csb"
    getResManager():addPreloadRes(mapCsb, function(mapCsb, success)
        if success then
            print("UIUnion:acceptExpeditionInfoCmd 预加载远征地图资源成功 curMapId", curMapId)
        else
            print("UIUnion:acceptExpeditionInfoCmd 预加载远征地图资源失败 curMapId", curMapId)
        end
    end)
    getResManager():startResAsyn()
end


---------------------------------------------------------------------
-- 初始化定时器回调
function UIUnion:initTimer()
    CsbTools.getChildFromPath(self.root, "MainPanel/MainScrollView/Dock/TipsText"):setVisible(false)

    local nowTime = getGameModel():getNow()
    local warEndTime = expeditionModel:getWarEndTime()
    local restEndTime = expeditionModel:getRestEndTime()
    -- 休战: 当前时间 < 休息结束时间
    if nowTime < restEndTime then
        if nil == self.expeditionScheduler then
            self.expeditionScheduler = scheduler.scheduleGlobal(handler(self, self.onExpeditionResting), 1)
        end
    -- 交战: 当前时间 >= 休息时间 and 当前时间 < 交战结束时间
    elseif nowTime < warEndTime then
        if nil == self.expeditionScheduler then
            self.expeditionScheduler = scheduler.scheduleGlobal(handler(self, self.onExpeditionWarring), 1)
        end
    end
end

-- 公会远征休息阶段定时回调
function UIUnion:onExpeditionResting(dt)
    -- 休息结束: 当前时间大于休息结束时间
    local nowTime = getGameModel():getNow()
    local restEndTime = expeditionModel:getRestEndTime()
    if nowTime > restEndTime then
        -- 触发 远征开始 事件
        EventManager:raiseEvent(GameEvents.EventExpeditionStart)
    else
        local times = TimeHelper.restTime(restEndTime)
        local text = CsbTools.getChildFromPath(self.root, "MainPanel/MainScrollView/Dock/TipsText")
        text:setString(string.format(CommonHelper.getStageString(6093), times.day, times.hour, times.min, times.sec))
        text:setVisible(true)
    end
end

-- 公会远征交战阶段定时回调
function UIUnion:onExpeditionWarring(dt)
    -- 远征结束: 当前时间大于交战结束时间
    local nowTime = getGameModel():getNow()
    local warEndTime = expeditionModel:getWarEndTime()
    if nowTime > warEndTime then
        -- 进入远征休息阶段
        local curAreaId = expeditionModel:getAreaId()
        local areaConf = getExpeditionItem(curAreaId)
        local _time = areaConf and areaConf.Expedition_RestTime or 0
        expeditionModel:setRestEndTime(nowTime + _time)
        expeditionModel:setAreaId(0)
        expeditionModel:setMapId(0)
        expeditionModel:clearStages()

        -- 触发 远征失败 事件
        EventManager:raiseEvent(GameEvents.EventExpeditionFail)
    else
        local times = TimeHelper.restTime(warEndTime)
        local text = CsbTools.getChildFromPath(self.root, "MainPanel/MainScrollView/Dock/TipsText")
        text:setString(string.format(CommonHelper.getStageString(6001), times.day, times.hour, times.min, times.sec))
        text:setVisible(true)
    end
end

function UIUnion:showBuidRedPoint()
    for k, v in pairs(enterInfo) do
        local redTipPoint = CsbTools.getChildFromPath(self.enterBtn[k], "RedTipPoint")
        if redTipPoint then
            redTipPoint:setVisible(RedPointHelper.getUnionBuildRedPoint(v.subSystem))
        end
	end
end

function UIUnion:eventChatCallBack(eventName, chatInfo)
    local limitLv = cc.UserDefault:getInstance():getIntegerForKey("CHAT_LV_LIMIT", 1)
    local chatMode = cc.UserDefault:getInstance():getIntegerForKey("CHAT_MODE", 11)
    -- 等级限制&语音限制
    if chatInfo.lv and limitLv > chatInfo.lv then
        return
    end

    -- 频道限制
    if chatInfo.chatMode == 1 then
        if math.floor(chatMode/10) == 1 then
            self:addChatItem(chatInfo)
        end
    elseif chatInfo.chatMode == 2 then
        if math.floor(chatMode%10) == 1 then
            self:addChatItem(chatInfo)
        end
    else
        self:addChatItem(chatInfo)
    end
end

function UIUnion:addChatItem(chatInfo)
    local chatStr = ChatHelper.toFormatCode(chatInfo)
    local richText = createRichTextWithCode(chatStr, self.talkViewSize.width-8)
    richText:setTouchEnabled(false)
    if not self.curChatHeight then
        self.curChatHeight = 5
    end

    local posHeight = self.curChatHeight
    self.curChatHeight = self.curChatHeight + richText:getContentSize().height
    if self.curChatHeight > self.talkViewSize.height then
        self.talkViewSize.height = self.curChatHeight
    end

    --richText:setAnchorPoint(cc.p(0, 1))
    richText:setPosition(5, posHeight)
    self.talkView:setInnerContainerSize(self.talkViewSize)
    self.talkView:addChild(richText)
end

function UIUnion:touchRecordCallBack(obj, event)
    if not ChatHelper.canSendMessage() then
        return
    end

    if event == 0 then
        -- 开始录音
        self.recordVoice:startRecordVoice()
	elseif event == 1 then
        -- 拖动取消录音
	    if cc.pGetDistance(obj:getTouchBeganPosition(), obj:getTouchMovePosition()) > 30 then
            self.recordVoice:cancelRecordVoice()
	    end

    elseif event == 2 or event == 3 then
        self.recordVoice:stopRecordVoice()
	end
end

return UIUnion