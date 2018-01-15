--[[
竞技场任务界面
]]

local UIArenaTask = class("UIArenaTask", function ()
	return require("common.UIView").new()
end)

local scheduler = require("framework.scheduler")
local UIArenaLanguage = {dayWinCount = 818, dayContinusWinCount = 819, BattleCount = 817,
    getAwardText = 79, alreadyText = 503, dailyArenaTask = 1709}

-- 0=日累计胜场奖励,1=日连胜场奖励,2=日排名奖励,3=锦标赛周排名奖励,4=日战斗场次奖励
local ArenaRewardType = {
    dayWin = 0, 
    dayContinusWin = 1, 
    dayRank = 2, 
    championRank = 3, 
    dayBattle = 4
}

function UIArenaTask:ctor()
end

function UIArenaTask:init()
    self.UICsb = ResConfig.UIArenaTask.Csb2
    self.UICsb.arenaTaskState = "ui_new/g_gamehall/a_arena/ArenaTaskState.csb"
    self.UICsb.awardItem = "ui_new/g_gamehall/t_task/MoneyItem.csb"

    self.rootPath = self.UICsb.task
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.arenaTasks = {}
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BackButton"), function ()
        UIManager.close()
    end)

    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/CloseButton"), function ()
        UIManager.close()
    end)
    -- 标题
    CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/BarImage1/TitleText")
        :setString(CommonHelper.getUIString(UIArenaLanguage.dailyArenaTask))

    self.arenaTaskView = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/TaskScrollView")
    self.arenaTaskView:removeAllChildren()
end

function UIArenaTask:addTaskItem(taskId, index)
    local taskConf = getArenaTask(taskId)
    if not taskConf then
        return
    end

    local topMargin = 8
    local leftMargin = 5
    local viewSize = self.arenaTaskView:getContentSize()

    if not self.arenaTasks[taskId] then
        local taskBar = getResManager():cloneCsbNode(self.UICsb.arenaTaskBar)
        local barAct = cc.CSLoader:createTimeline(self.UICsb.arenaTaskBar)
        local stateNode = CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/ArenaTaskState")
        local stateAction = cc.CSLoader:createTimeline(self.UICsb.arenaTaskState)

        taskBar:runAction(barAct)
        stateNode:runAction(stateAction)

        self.arenaTasks[taskId] = {}
        self.arenaTasks[taskId].taskBar = taskBar
        self.arenaTasks[taskId].stateNode = stateNode
        self.arenaTasks[taskId].stateAction = stateAction
        self.arenaTasks[taskId].completeTimes = taskConf.Complete_Times    
        self.arenaTaskView:addChild(taskBar)
        -- 提示挑战场数
        local tipsText = string.format(CommonHelper.getTaskString(taskConf.PVPTask_Text), taskConf.Complete_Times)
        CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/TipsText"):setString(tipsText)
        -- 任务图标
        CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/TaskImage"):loadTexture(taskConf.PVPTask_Pic, 1)

        -- 领取按钮, 设置tag为任务id, 领取奖励时发送对应任务id进行领取
        local receiveButton = CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/ArenaTaskState/ReceiveButton")
        receiveButton:setTag(taskId) 
        CsbTools.initButton(receiveButton, handler(self, self.receiveCallBack), 
            CommonHelper.getUIString(UIArenaLanguage.getAwardText), "TaskReceiveButton/ButtomName", "TaskReceiveButton")
        -- 已领取按钮
        local alreadyText = CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/ArenaTaskState/received_log_1/Text_1")
        alreadyText:setString(CommonHelper.getUIString(UIArenaLanguage.alreadyText))
        -- 显示可获得物品  
        local nodePoint = CsbTools.getChildFromPath(taskBar, "ArenaTaskBar/NodePoint")
        local x, y = nodePoint:getPosition()
        local arenaTaskBar = CsbTools.getChildFromPath(self.arenaTasks[taskId].taskBar, "ArenaTaskBar")
        self:showArenaTaskAward(arenaTaskBar, taskConf, cc.p(x, y))
    else
        self.arenaTasks[taskId].taskBar:setVisible(true)
    end

    local arenaTaskBar = CsbTools.getChildFromPath(self.arenaTasks[taskId].taskBar, "ArenaTaskBar")
    local taskBarSize = arenaTaskBar:getContentSize()
    -- 推导:减一半(锚点)再减个数高度
    self.arenaTasks[taskId].taskBar:setPosition(taskBarSize.width/2 + leftMargin, 
        viewSize.height - taskBarSize.height * (0.5 + index) - topMargin)
   
    -- 按钮状态
    local isFinish = false
    local curTimes = 0
    local pvpModel = getGameModel():getPvpModel()
    if taskConf.PVPTask_Type == 0 then
        curTimes = pvpModel:getPvpInfo().DayBattleCount
    elseif taskConf.PVPTask_Type == 1 then
        curTimes = pvpModel:getPvpInfo().DayWin
    elseif taskConf.PVPTask_Type == 2 then
        curTimes = pvpModel:getPvpInfo().DayMaxContinusWinTimes
    else
        -- illegal
    end

    isFinish = curTimes >= taskConf.Complete_Times
    if isFinish then
        self.arenaTasks[taskId].stateAction:play("ReceiveButton", false)
    else
        self.arenaTasks[taskId].stateAction:play("TaskLoadingNum", false)
        local timesText = curTimes.."/"..taskConf.Complete_Times
        CsbTools.getChildFromPath(self.arenaTasks[taskId].stateNode, "TaskLoadingNum"):setString(timesText)
    end
end

function UIArenaTask:updateTaskItems()
    local index = 0
    local pvpTaskModel = getGameModel():getPvpTaskModel()
    for _, id in pairs(pvpTaskModel.taskIds) do
        self:addTaskItem(id, index)
        index = index + 1
    end
end

function UIArenaTask:finishTask(taskId)
    local taskConf = getArenaTask(taskId)
    local pvpTaskModel = getGameModel():getPvpTaskModel()
    local pvpModel = getGameModel():getPvpModel()
    --重置对应的次数
    pvpModel:resetPvpTaskWithType(taskConf.PVPTask_Type)
    --开启新任务
    if taskConf.IsReset == 0 then
        pvpTaskModel:removeTaskId(taskId)
        self.arenaTasks[taskId].taskBar:removeFromParent(true)
        self.arenaTasks[taskId] = nil
    end

    for _, id in pairs(taskConf.End_StartID) do
        pvpTaskModel:addTaskId(id)
    end
    -- 重排任务
    self:updateTaskItems()
end

function UIArenaTask:onOpen(fromUIID)
    -- 刷新选项
    self:updateTaskItems()
end

function UIArenaTask:onClose()

end

function UIArenaTask:receiveCallBack(obj)
    local taskId = obj:getTag()
    -- 发送领取
    local BufferData = NetHelper.createBufferData(MainProtocol.PvpInfo, PvpInfoProtocol.RewardCS)
	BufferData:writeInt(taskId)
	NetHelper.requestWithTimeOut(BufferData,
        NetHelper.makeCommand(MainProtocol.PvpInfo, PvpInfoProtocol.RewardSC),
        handler(self, self.onResponseReceive))
end

function UIArenaTask:onResponseReceive(mainCmd, subCmd, data)
    local taskId = data:readInt()
    local propCount = data:readInt()
   
    local awardData = {}
    local countIndex = 1
    while countIndex <= propCount do
        --解析每个道具的数据
        local dropInfo = {}
        dropInfo.id = data:readInt()
        dropInfo.num = data:readInt()
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
        countIndex = countIndex + 1
    end
	-- 显示奖励
	UIManager.open(UIManager.UI.UIAward, awardData)
    -- 移除任务
    self:finishTask(taskId)
    -- 红点
    RedPointHelper.addCount(RedPointHelper.System.Arena, -1, RedPointHelper.AreanSystem.ArenaTask)
end

local CurrencyIcon = {coin = "pub_gold.png", diamond = "pub_gem.png", 
    pvpCoin = "pub_fightcoin.png", flashcard = "icon_flashcard2.png", 
    exp = "pub_exp.png", energy = "pub_energy.png" }

function UIArenaTask:showArenaTaskAward(taskBar, awardData, pos)
    local awardInfo = {}
    local function pushAwardInfo(iconImg, num)
        if num > 0 then
            table.insert(awardInfo, {iconImg = iconImg, num = num})
        end
    end
    -- 货币
    pushAwardInfo(CurrencyIcon.pvpCoin, awardData.Award_PvPCoin)
    pushAwardInfo(CurrencyIcon.diamond, awardData.Award_Diamond)
    pushAwardInfo(CurrencyIcon.coin, awardData.Award_coin)
    pushAwardInfo(CurrencyIcon.flashcard, awardData.Award_Flashcard)
    pushAwardInfo(CurrencyIcon.exp, awardData.Award_Exp)
    pushAwardInfo(CurrencyIcon.energy, awardData.Award_Energy)
    -- 物品
    for _, item in pairs(awardData.Award_Items) do
        local itemConf = getPropConfItem(item["ID"])
        if itemConf then
            table.insert(awardInfo, {iconImg = itemConf.Icon, num = item["num"]})
        end
    end

    local position = pos
    for _, info in pairs(awardInfo) do
        local awardItem = getResManager():cloneCsbNode(self.UICsb.awardItem)
        awardItem:setPosition(position)
        taskBar:addChild(awardItem)

        local currencyImg = CsbTools.getChildFromPath(awardItem, "MoneyPanel/AwardImage")
        currencyImg:loadTexture(info.iconImg, 1)
        CsbTools.getChildFromPath(awardItem, "MoneyPanel/AwardNumLabel"):setString(info.num)
        position = cc.p(position.x + 100, position.y)
    end
end

return UIArenaTask