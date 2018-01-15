local TaskViewHelper = class("TaskViewHelper")

local PropTips = require("game.comm.PropTips")

local csbFile = ResConfig.UITaskAchieve.Csb2
local awardItemFile = "ui_new/g_gamehall/t_task/TaskAwardItem.csb"
local taskStateFile = "ui_new/g_gamehall/t_task/TaskState.csb"
local confrimBtnFile = "ui_new/p_public/Button_Confrim.csb"

local taskStatus = {unActive = -1, active = 0, finish = 1, get = 2}

function TaskViewHelper:ctor(taskAchieve, uiTask)
	self.taskAchieve = taskAchieve
	self.root = uiTask

	-- {id1, id2, ...}
	self.tasksID = {}
	-- {id = 任务ID, taskVal = 完成次数, taskStatus = 任务状态, type = 0支线1主线}
	self.tasksInfo = {}

	-- scroll上的item {[taskId1] = Node1, [taskId2] = Node2}
	self.items = {}
	self.itemsCache = {}

	self.scroll = CsbTools.getChildFromPath(self.root, "TaskPanel/TaskScrollView")
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()
	local itemCsb = getResManager():getCsbNode(csbFile.taskItem)
	local itemLayout = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel")
	self.itemSize = itemLayout:getContentSize()
    itemCsb:cleanup()
end

function TaskViewHelper:onOpen(preUIID, part)
	self.immediatelyRefresh = true
	
	-- 道具点击提示
	self.propTips = PropTips.new()
	
	self:initTasksInfo()
	self:reloadScroll()
	TaskManage.setUIReloadFunc(handler(self, self.changeCallBack))

	-- 任务领取回调监听
	local cmd = NetHelper.makeCommand(MainProtocol.Task, TaskProtocol.TaskAwardSC)
	self.taskHandler = handler(self, self.onTaskCallBack)
	NetHelper.setResponeHandler(cmd, self.taskHandler)
end

function TaskViewHelper:onClose()
	TaskManage.clearUIReloadFunc()
	self:stopItemUpdate()
	self:cacheItems()

	local cmd = NetHelper.makeCommand(MainProtocol.Task, AchievementProtocol.GainSC)
	NetHelper.removeResponeHandler(cmd, self.taskHandler)

	self.propTips:removePropAllTips()
	self.propTips = nil
end

function TaskViewHelper:cacheItems()
	for id, node in pairs(self.items) do
		table.insert(self.itemsCache, node)
		node:setVisible(false)
	end
	self.items = {}
end

function TaskViewHelper:initTasksInfo()
	TaskManage.checkResetTaskAll()

	self.tasksID = {}
	self.tasksInfo = {}
	local tasksInfo = getGameModel():getTaskModel():getTasksData()
	for id, info in pairs(tasksInfo) do
		local taskConf = getTaskConfItem(id)
		if taskConf ~= nil and taskConf.Show == 1 then
			if info.taskStatus==taskStatus.active or info.taskStatus==taskStatus.finish then
				self.tasksInfo[id] = {
					taskID = info.taskID, 
					taskVal = info.taskVal, 
					taskStatus = info.taskStatus, 
					resetTime = info.resetTime,
					type = taskConf.Type}
				table.insert(self.tasksID, id)
			end
		end
	end

	local function sortTask(taskID1, taskID2)
		local info1 = self.tasksInfo[taskID1]
		local info2 = self.tasksInfo[taskID2]
		if info1.taskStatus > info2.taskStatus then
			return true
		elseif info1.taskStatus == info2.taskStatus then
			if info1.type < info2.type then
				return true
			elseif info1.type == info2.type then
				if taskID1 < taskID2 then
					return true
				end
			end
		end
		return false
	end

	table.sort(self.tasksID, sortTask)	-- 排序

	self:showTipsCount()
end

-- 计算并显示提示个数
function TaskViewHelper:showTipsCount()
	local taskTipsNum = 0
	for id, info in pairs(self.tasksInfo) do
		if info.taskStatus == taskStatus.finish then
			taskTipsNum = taskTipsNum + 1
		end
	end
	self.taskAchieve:setRedTipsNum("task", taskTipsNum)
end

function TaskViewHelper:reloadScroll()
	self:cacheItems()
	local scrollInnerSize = self.scroll:getContentSize()
	if self.itemSize.height*(#self.tasksID) > scrollInnerSize.height then
		scrollInnerSize.height = self.itemSize.height*(#self.tasksID)
	end
	self.scroll:setInnerContainerSize(scrollInnerSize)   --设置拖动区域

	self:startItemUpdate()
end

function TaskViewHelper:refreshScroll()
    for i, id in pairs(self.tasksID) do
        local item = self.items[id]
        local scrollInnerSize = self.scroll:getInnerContainerSize()

        if item then
            local pos = cc.p(self.itemSize.width*0.5 + 2, scrollInnerSize.height - self.itemSize.height*(i -0.5))
	        item:setPosition(pos)
            self:initTaskInfo(item, id)
        else
            print("!!! not find taskItem", id)
        end
    end	
end

function TaskViewHelper:startItemUpdate()
	self:stopItemUpdate()
	self.showOrderID = 1
	self.itemUpdateID = cc.Director:getInstance():getScheduler():
		scheduleScriptFunc(handler(self, self.itemUpdate), 0.05, false)
end

function TaskViewHelper:stopItemUpdate()
	if self.itemUpdateID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.itemUpdateID)
		self.itemUpdateID = nil
	end
end

function TaskViewHelper:itemUpdate(dt)
	if self.showOrderID <= #self.tasksID then
		local item = self:createAndAddItem(self.tasksID[self.showOrderID])
		if item ~= nil then
			local scrollSize = self.scroll:getInnerContainerSize()
			local pos = cc.p(self.itemSize.width*0.5 + 2, scrollSize.height - self.itemSize.height*(self.showOrderID -0.5))
			item:setPosition(pos)
			CommonHelper.playCsbAnimate(item, csbFile.taskItem, "TaskIn", false, nil, true)
			self.showOrderID = self.showOrderID + 1
		end
	else
		self:stopItemUpdate()
	end
end

function TaskViewHelper:changeCallBack(taskId, type)
    if type == "receiveBegin" then
    	self.immediatelyRefresh = false
	elseif type == "receiveEnd" then
		self.immediatelyRefresh = true
		local delItemCsb = self.items[taskId]
		if not delItemCsb then 
			return 
		end

		CommonHelper.playCsbAnimate(delItemCsb, csbFile.taskItem, "TaskOver", false, function()
			self.items[taskId] = nil
			delItemCsb:setVisible(false)
			table.insert(self.itemsCache, delItemCsb)			
			self:initTasksInfo()
			self:reloadScroll()
		end, true)
	elseif self.immediatelyRefresh then
		self:initTasksInfo()
		self:refreshScroll()
	end
end

function TaskViewHelper:createAndAddItem(taskId)
	local itemCsb = nil
	if #self.itemsCache ~= 0 then
		itemCsb = self.itemsCache[1]
		itemCsb:setVisible(true)
		table.remove(self.itemsCache, 1)
	else
		itemCsb = getResManager():cloneCsbNode(csbFile.taskItem)
		self.scroll:addChild(itemCsb)
	end
	
	self.items[taskId] = itemCsb
	self:initTaskInfo(itemCsb, taskId)

	return itemCsb
end

function TaskViewHelper:initTaskInfo(itemCsb, taskId)
	if itemCsb == nil then return end
	CommonHelper.playCsbAnimate(itemCsb, csbFile.taskItem, "Normal", false, nil, true)

	local taskInfo = self.tasksInfo[taskId]
	local taskConf = getTaskConfItem(taskId)
	if taskConf == nil or taskInfo == nil then return end

	local taskBtnCsb = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel/TaskState")	-- 用来播放闪烁, 和隐藏快速前往
	local taskIconImg = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel/TaskImage")
	local taskTypeImg = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel/TaskType")

	local taskTitleLab = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel/TaskName")
	local taskDescLab = CsbTools.getChildFromPath(itemCsb, "TaskBarPanel/ConditionTipLabel")
	local taskRateLab = CsbTools.getChildFromPath(taskBtnCsb, "TaskStatePanel/NumValue") -- 0/600
	local timeTip = CsbTools.getChildFromPath(taskBtnCsb, "TaskStatePanel/TimeTipLabel")	-- 时间未到

	local taskBtn = CsbTools.getChildFromPath(taskBtnCsb, "TaskStatePanel/GotoButton")
	local taskBtn2 = CsbTools.getChildFromPath(taskBtnCsb, "TaskStatePanel/GetButton")
	taskBtn:setTag(taskId)
	taskBtn2:setTag(taskId)
	CsbTools.initButton(taskBtn, handler(self, self.taskBtnCallBack))
	CsbTools.initButton(taskBtn2, handler(self, self.taskBtnCallBack))

	local icon = taskConf.Type==1 and getTaskAcheveSettingConfItem().MainTaskIcon or getTaskAcheveSettingConfItem().DailyTaskIcon
	CsbTools.replaceImg(taskIconImg, taskConf.Icon)	
	CsbTools.replaceImg(taskTypeImg, icon)
	
	taskTitleLab:setString(CommonHelper.getTaskString(taskConf.Title))
	taskDescLab:setString(CommonHelper.getTaskString(taskConf.Desc))
	if taskConf.FinishCondition == ConditionProcess.conditionId.monthCard then
		local days = math.ceil((getGameModel():getUserModel():getMonthCardStamp() - getGameModel():getNow())/86400)
		if days < 0 then
			days = 0
		end
		taskDescLab:setString(string.format(CommonHelper.getUIString(404), days))
	end

	if taskInfo.taskStatus == taskStatus.active then
		if taskConf.Tips == 0 then
			taskRateLab:setString(taskInfo.taskVal .. "/" .. taskConf.CompleteTimes)
		else
			taskRateLab:setString(CommonHelper.getUIString(taskConf.Tips))
		end

		if taskConf.FinishCondition == ConditionProcess.conditionId.receiveVit then			
			CommonHelper.playCsbAnimate(taskBtnCsb, taskStateFile, "TimeTip", false, nil, true)
			timeTip:setString(CommonHelper.getUIString(233))
		else
			taskBtn:setTitleText(CommonHelper.getUIString(157))
			if #taskConf.QuickTo ~= 0 then
				CommonHelper.playCsbAnimate(taskBtnCsb, taskStateFile, "GotoTask", false, nil, true)
			else
				CommonHelper.playCsbAnimate(taskBtnCsb, taskStateFile, "ActiveValue", false, nil, true)
			end
		end
	else
		if taskConf.FinishCondition == ConditionProcess.conditionId.receiveVit then
			taskRateLab:setString("")
		else
			taskRateLab:setString(taskConf.CompleteTimes .. "/" .. taskConf.CompleteTimes)
		end		
		taskBtn:setTitleText(CommonHelper.getUIString(79))
		CommonHelper.playCsbAnimate(taskBtnCsb, taskStateFile, "GetTask", true, nil, true)
	end

	-- 显示奖励
	self:addAwardToItem(itemCsb, taskConf)
end

function TaskViewHelper:addAwardToItem(item, taskConf)
	local posX = 0
	local node = CsbTools.getChildFromPath(item, "TaskBarPanel/NodePoint")
	node:removeAllChildren()

	local currencyInfo = {AwardExp = "exp", AwardCoin = "gold", AwardDiamond = "diamond", AwardEnergy = "energy", AwardFlashcard = "flashcard"}

	for k,v in pairs(currencyInfo) do
		if taskConf[k] ~= 0 then
			local awardCsb1 = getResManager():cloneCsbNode(csbFile.taskAward1)
			node:addChild(awardCsb1)
			awardCsb1:setPositionX(posX)
			posX = posX + CsbTools.getChildFromPath(awardCsb1, "MoneyPanel"):getContentSize().width
			self.taskAchieve:setAwardCsb1(awardCsb1, v, taskConf[k])
		end
	end

	for _, propData in ipairs(taskConf.AwardItems) do
		local propID = propData.ID
		local propNum = propData.num
		local awardCsb2 = getResManager():cloneCsbNode(csbFile.taskAward2)
		node:addChild(awardCsb2)
		awardCsb2:setPositionX(posX)
		posX = posX + CsbTools.getChildFromPath(awardCsb2, "TaskAwradPanel"):getContentSize().width
		self.taskAchieve:setAwardCsb2(awardCsb2, propID, propNum)

		local touchNode = CsbTools.getChildFromPath(awardCsb2, "TaskAwradPanel/Award1/MainPanel")
		self.propTips:addPropTips(touchNode, getPropConfItem(propID), cc.p(-20, -50))
	end
end

function TaskViewHelper:taskBtnCallBack(obj)
	local taskID = obj:getTag()

	if self.tasksInfo[taskID].taskStatus == taskStatus.finish then
		-- 发包
		local bufferData = NetHelper.createBufferData(MainProtocol.Task, TaskProtocol.TaskAwardCS)
		bufferData:writeInt(taskID)	
		NetHelper.request(bufferData)	
	else
		local taskConf = getTaskConfItem(taskID)
        obj.soundId = nil
		if not self:quickTo(taskConf.QuickTo) then
            obj.soundId = MusicManager.commonSound.fail
        end
	end
end

function TaskViewHelper:onTaskCallBack(mainCmd, subCmd, data)
	local taskID = data:readInt()	
	local propCount = data:readInt()
	if taskID == 0 then return end

	-- 构造table, 显示奖励
	local awardData = {}
    local dropInfo = {}
	for i=1, propCount do
		dropInfo.id = data:readInt()
		dropInfo.num = data:readInt()
		UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
	end

	-- 显示奖励
	UIManager.open(UIManager.UI.UIAward, awardData)

	-- 结束此任务, 激活其他任务
	TaskManage.receiveTask(taskID)

	-- 完成任务事件
    EventManager:raiseEvent(GameEvents.EventFinishTask, {taskId = taskID, taskType = 1})
end

function TaskViewHelper:quickTo(quickToData)
	if quickToData[1] == nil then
		return
	end

    local canQuickTo = true
	if quickToData[1] == 10 then
        local s = StageHelper.getStageState(quickToData[2], quickToData[3])
        if s <= StageHelper.StageState.SS_LOCK then
            canQuickTo = false
        end
        if not canQuickTo then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1478), {})
        else
		    -- 进入关卡
		    UIManager.open(quickToData[1], quickToData[2], quickToData[3], quickToData[4])
        end
	else
		UIManager.open(quickToData[1], quickToData[2], quickToData[3], quickToData[4])
	end

    return canQuickTo
end

function TaskViewHelper:makeVisible(isVisible)
	self.root:setVisible(isVisible)
end

return TaskViewHelper