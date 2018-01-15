--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征世界地图
** 应  用:
********************************************************************/
--]]
require("game.comm.UIAwardHelper")
local scheduler = require("framework.scheduler")

local unionModel = getGameModel():getUnionModel()
local expeditionModel = getGameModel():getExpeditionModel()

local awardFlag = {
    null = 0,
    have = 1
}

local UIExpeditionWorld = class("UIExpeditionWorld", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIExpeditionWorld:ctor()
    self:setNodeEventEnabled(true)
end

function UIExpeditionWorld:onExit()
    self:removeEvent()
    self:removeNetwork()
end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionWorld:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionWorld.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 退出按钮
    local backButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(backButton, handler(self, self.onClick))
    -- 远征排行
    local rankButton = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/RankingButton")
    CsbTools.initButton(rankButton, handler(self, self.onClick))
    -- 远征日志
    local introButton = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/IntroButton")
    CsbTools.initButton(introButton, handler(self, self.onClick))
    -- 远征奖励
    local awardButton = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/AwardButton")
    CsbTools.initButton(awardButton, handler(self, self.onClick))
    -- 帮助按钮
    local questionButton = CsbTools.getChildFromPath(self.root, "QuestionButton")
    CsbTools.initButton(questionButton, handler(self, self.onClick))

    -- 语言包相关
    CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/BarImage/BarLabel"):setString(CommonHelper.getUIString(2054))
    CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/AwardButton/Text"):setString(CommonHelper.getUIString(2035))
    CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/IntroButton/Text"):setString(CommonHelper.getUIString(2034))
    CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/RankingButton/Text"):setString(CommonHelper.getUIString(2033))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionWorld:onOpen(openerUIID, ...)
    self:setAwardBtnState()
    self:initArea()
    self:initEvent()
    self:initNetwork()
    self:initTimer()
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionWorld:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionWorld:onClose()
    self:removeEvent()
    self:removeNetwork()
    -- 移除奖励发放等待定时器
    if self.awardScheduler then
        scheduler.unscheduleGlobal(self.awardScheduler)
        self.awardScheduler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionWorld:onTop(preUIID, ...)
    self:initArea()
end

-- 当前界面点击回调
function UIExpeditionWorld:onClick(obj)
    obj.soundId = nil
    local btnName = obj:getName()
    if btnName == "BackButton" then             -- 返回
        UIManager.close()
    elseif btnName == "RankingButton" then      -- 远征排行
        local nowTime = os.time()
        local rankTime = expeditionModel:getRankTime()
        if nowTime - rankTime < 60 then
            UIManager.open(UIManager.UI.UIExpeditionRanking)
        else
            self:sendDamageRankCmd()
        end
    elseif btnName == "IntroButton" then        -- 远征日志
        UIManager.open(UIManager.UI.UIExpeditionDiary)
    elseif btnName == "AwardButton" then        -- 远征奖励
        local flag = expeditionModel:getAwardFlag()
        if flag == awardFlag.have then
            self:sendRewardGetCmd()
        else
            obj.soundId = MusicManager.commonSound.fail
        end
    elseif btnName == "QuestionButton" then     -- 帮助按钮
        UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2053))
    end
end

-- 设置奖励按钮状态
function UIExpeditionWorld:setAwardBtnState()
    local awardButton = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/AwardButton")
    local buttonText = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/AwardButton/Text")

    local point = CsbTools.getChildFromPath(awardButton, "RedTipPoint")
    local flag = expeditionModel:getAwardFlag()
    if flag == awardFlag.null then
        awardButton:setBright(false)
        buttonText:setTextColor(cc.c4b(191, 191, 191, 255))
        buttonText:enableOutline(cc.c4b(127, 127, 127, 255), 2)
        point:setVisible(false)
    elseif flag == awardFlag.have then
        awardButton:setBright(true)
        buttonText:setTextColor(cc.c4b(255, 255, 0, 255))
        buttonText:enableOutline(cc.c4b(104, 19, 0, 255), 2)
        point:setVisible(true)
    end
end

-- 初始化区域
function UIExpeditionWorld:initArea()
    local unionLevel = unionModel:getUnionLv()
    local unlockID = 0
    for idx, data in pairs(getExpeditionConf() or {}) do
        local areaId = data.Expedition_ID
        -- 区域迷雾
        if data.Expedition_Level <= unionLevel and data.Expedition_ID > unlockID then
            unlockID = data.Expedition_ID
        end
        -- 区域状态
        self:setAreaState(areaId)
        -- 区域点击
        local areaNode = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/PointPanel/IslandStage_" .. areaId)
        CsbTools.initButton(areaNode, function(obj)
            obj.soundId = nil
            if unionLevel < data.Expedition_Level then
                obj.soundId = MusicManager.commonSound.fail
                local unlockLevel = data.Expedition_Level
                CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(1905), unlockLevel))
            else
                local curAreaId = expeditionModel:getAreaId()
                if curAreaId <= 0 then
                    local unionPos = unionModel:getPos()
                    if unionPos > 0 then
                        UIManager.open(UIManager.UI.UIExpeditionAreaSet, areaId)
                    else
                        obj.soundId = MusicManager.commonSound.fail
                        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1964))
                    end
                else
                    if curAreaId ~= data.Expedition_ID then
                        obj.soundId = MusicManager.commonSound.fail
                        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1906))
                    else
                        UIManager.open(UIManager.UI.UIExpeditionArea)
                    end
                end
            end
        end)
    end

    -- 区域迷雾
    local maskPanel = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/MaskPanel")
    for i, node in pairs(maskPanel:getChildren()) do
        if i == unlockID then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
    -- 剩余次数
    local Tips1 = CsbTools.getChildFromPath(self.root, "Tips1")
    local fightCount = expeditionModel:getFightCount()
    local unionConf = getUnionConfItem() or {}
    local haveCount = unionConf.Expedition_Num - fightCount
    Tips1:setString(string.format(CommonHelper.getStageString(6003), haveCount))
end

-- 设置区域状态
function UIExpeditionWorld:setAreaState(areaId)
    local areaConf = getExpeditionItem(areaId)
    if not areaConf then return end

    local node = CsbTools.getChildFromPath(self.root, "MainPanel/MapCut/MapCut/MapPanel/PointPanel/IslandStage_" .. areaId .. "/ExpedStage")

    local unionLevel = unionModel:getUnionLv()
    -- 未解锁
    if unionLevel < areaConf.Expedition_Level then
        CommonHelper.playCsbAnimation(node, "Hide", true, nil)
    -- 已解锁
    else
        local curAreaId = expeditionModel:getAreaId()
        -- 已选择远征区域
        if curAreaId > 0 then
            -- 目标区域
            if areaId == curAreaId then
                local nowTime = getGameModel():getNow()
                local warEndTime = expeditionModel:getWarEndTime()
                local restEndTime = expeditionModel:getRestEndTime()
                -- 休战: 当前时间 < 休息结束时间
                if nowTime < restEndTime then
                    CommonHelper.playCsbAnimation(node, "Next", true, nil)
                -- 交战: 当前时间 >= 休息结束时间 and 当前时间 < 交战结束时间
                elseif nowTime < warEndTime then
                    CommonHelper.playCsbAnimation(node, "Fighting", true, nil)
                end
            -- 其他区域
            else
                CommonHelper.playCsbAnimation(node, "Hide", false, nil)
            end
        -- 未选择远征区域
        else
            local unionPos = unionModel:getPos()
            -- 会长/副会长
            if unionPos > 0 then
                CommonHelper.playCsbAnimation(node, "Choose", true, nil)
            -- 普通成员
            else
                CommonHelper.playCsbAnimation(node, "Hide", false, nil)
            end
        end
    end
end


---------------------------------------------------------------------
-- 初始化事件回调
function UIExpeditionWorld:initEvent()
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
    -- 添加远征奖励标识事件监听
    self.awardFlagHandler = handler(self, self.onEventCallback)
    EventManager:addEventListener(GameEvents.EventExpeditionAwardFlag, self.awardFlagHandler)
end

-- 移除事件回调
function UIExpeditionWorld:removeEvent()
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
        self.failHandler = nil
    end
    -- 移除远征奖励标识事件监听
    if self.awardFlagHandler then
        EventManager:removeEventListener(GameEvents.EventExpeditionAwardFlag, self.awardFlagHandler)
        self.awardFlagHandler = nil
    end
end

-- 远征 目标设定, 开始, 胜利, 失败 事件回调
function UIExpeditionWorld:onEventCallback(eventName)
    if eventName == GameEvents.EventExpeditionMapSet or
       eventName == GameEvents.EventExpeditionStart or
       eventName == GameEvents.EventExpeditionFail then
        self:initArea()
   elseif eventName == GameEvents.EventExpeditionWin then
        self:initArea()
        self:initTimer()
    elseif eventName == GameEvents.EventExpeditionAwardFlag then
        self:setAwardBtnState()
    end
end


---------------------------------------------------------------------
-- 初始化网络回调
function UIExpeditionWorld:initNetwork()
    -- 注册奖励领取网络监听
    local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.RewardGetSC)
    self.rewardGetHandler = handler(self, self.acceptRewardGetCmd)
    NetHelper.setResponeHandler(cmd, self.rewardGetHandler)
    -- 注册伤害排行网络监听
    local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.DamageRankSC)
    self.damageRankHandler = handler(self, self.acceptDamageRankCmd)
    NetHelper.setResponeHandler(cmd, self.damageRankHandler)
end

-- 移除网络回调
function UIExpeditionWorld:removeNetwork()
    -- 移除奖励领取网络监听
    if self.rewardGetHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.RewardGetSC)
        NetHelper.removeResponeHandler(cmd, self.rewardGetHandler)
        self.rewardGetHandler = nil
    end
    -- 移除伤害排行网络监听
    if self.damageRankHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.DamageRankSC)
        NetHelper.removeResponeHandler(cmd, self.damageRankHandler)
        self.damageRankHandler = nil
    end
end

-- 发送领取奖励请求
function UIExpeditionWorld:sendRewardGetCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.RewardGetCS)
    NetHelper.request(buffData)
end

-- 接收领取奖励请求
function UIExpeditionWorld:acceptRewardGetCmd(mainCmd, subCmd, buffData)
    expeditionModel:setAwardFlag(0)
    self:setAwardBtnState()

    local awardData = {}
    local dropInfo  = {}    
    local num = buffData:readInt()
    for i = 1, num do
        dropInfo.id     = buffData:readInt()    -- 物品id
        dropInfo.num    = 1                     -- 物品个数
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end
    -- 显示奖励
    UIManager.open(UIManager.UI.UIAward, awardData)

    RedPointHelper.setCount(RedPointHelper.System.Union, nil, RedPointHelper.UnionSystem.ExpiditionReward)
end

-- 发送伤害排行请求
function UIExpeditionWorld:sendDamageRankCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.Expedition, ExpeditionProtocol.DamageRankCS)
    NetHelper.request(buffData)
end

-- 接收伤害排行请求
function UIExpeditionWorld:acceptDamageRankCmd(mainCmd, subCmd, buffData)
    local mapID = buffData:readInt()
    local myRank = buffData:readInt()
    local num = buffData:readInt()
    local rankList = {}
    for i = 1, num do
        local info = {}
        info.index = buffData:readInt()
        info.damage = buffData:readInt()
        info.name = buffData:readCharArray(32)
        info.summonerID = buffData:readInt()
        info.heroIDs = {}
        for i = 1, 7 do
            info.heroIDs[i] = buffData:readInt()
        end
        info.heroStars = {}
        for i = 1, 7 do
            info.heroStars[i] = buffData:readInt()
        end
        info.blueType = buffData:readChar()
        info.blueLv = buffData:readChar()
        rankList[info.index] = info
    end
    expeditionModel:setRankTime()
    expeditionModel:setRankMapId(mapID)
    expeditionModel:setMyRank(myRank)
    expeditionModel:setRankList(rankList)
    UIManager.open(UIManager.UI.UIExpeditionRanking)
end


---------------------------------------------------------------------
-- 初始化定时器回调
function UIExpeditionWorld:initTimer()
    CsbTools.getChildFromPath(self.root, "Tips2"):setVisible(false)

    local nowTime = getGameModel():getNow()
    local awardSendTime = expeditionModel:getAwardSendTime()
    local warEndTime = expeditionModel:getWarEndTime()
    -- 奖励发放等待
    if nowTime >= warEndTime and nowTime < awardSendTime then
        if nil == self.awardScheduler then
            self.awardScheduler = scheduler.scheduleGlobal(handler(self, self.onExpeditionAward), 1)
        end
    end
end

function UIExpeditionWorld:onExpeditionAward(dt)
    local nowTime = getGameModel():getNow()
    local awardSendTime = expeditionModel:getAwardSendTime()
    if nowTime > awardSendTime then
        -- 移除奖励发放等待定时器
        if self.awardScheduler then
            scheduler.unscheduleGlobal(self.awardScheduler)
            self.awardScheduler = nil
        end
        CsbTools.getChildFromPath(self.root, "Tips2"):setVisible(false)
    else
        local delta = awardSendTime - nowTime
        local times = TimeHelper.gapTimeS(delta)
        local text = CsbTools.getChildFromPath(self.root, "Tips2")
        text:setString(string.format(CommonHelper.getStageString(6002), times.hour, times.min, times.sec))
        text:setVisible(true)
    end
end

return UIExpeditionWorld