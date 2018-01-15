--[[
	TaskManage 主要用于过滤出任务事件的监听, 判断条件是否满足, 
		更新任务模型, 执行界面回调, 领取任务, 激活其他任务处理

	TaskManage.TasksInfo = {
		{TaskID = 1, TaskVal = 0, TaskStatus = 0, preTaskVal = 0}
	}
]]

TaskManage = {}

require("summonerComm.GameEvents")

local taskModel = getGameModel():getTaskModel()
local taskStatus = {unActive = -1, active = 0, finish = 1, get = 2}

function TaskManage.init()
	-- 注册监听
	local needListenEvent = {
		"EventStageOver", "EventHeroTestStageOver", "EventGoldTestStageOver", "EventTowerTestStageOver",
		"EventFBTestStageOver", "EventPVPOver", "EventDrawCard", "EventUseItem", "EventTouchGloden", 
		"EventReceiveCurrency", "EventReceiveEquip", "EventReceiveHero", "EventReceiveSummoner", 
		"EventDressEquip", "EventHeroUpgradeLevel", "EventHeroUpgradeStar", "EventHeroUpgradeSkill", 
		"EventPlayerUpgradeLevel", "EventFinishTask", "EventBuyMonthCard", "EventDispatchMercenary",
		"EventUseMercenary", "EventEquipMake",
	}
	for _, eventName in pairs(needListenEvent) do
		EventManager:addEventListener(GameEvents[eventName], TaskManage.onTaskEvent)
	end	

	-- 从模型中取得任务信息
	TaskManage.tasksInfo = taskModel:getTasksData() or {}
	
	TaskManage.conditionTaskIds =  {}
	for id, info in pairs(TaskManage.tasksInfo) do
		local taskConf = getTaskConfItem(id)
		if taskConf ~= nil then
			-- 提取出监听id 对应任务ids 的数据
			if TaskManage.conditionTaskIds[taskConf.FinishCondition] == nil then
				TaskManage.conditionTaskIds[taskConf.FinishCondition] = {}
			end
			table.insert(TaskManage.conditionTaskIds[taskConf.FinishCondition], id)

			-- 状态判断
			if info.taskStatus == taskStatus.active then
				local completeTimes = ConditionProcess.getStateTaskCompleteTimes(
					taskConf.FinishCondition, taskConf.FinishParameters, info.taskVal)
				TaskManage.setTaskCompleteTimes(id, completeTimes)
			end
		end
	end

	-- 策划说登陆的时候判断任务是否激活
	TaskManage.checkTaskActive(GameEvents.EventPlayerUpgradeLevel, {})

    -- 开启时间判断领取体力任务
    TaskManage.energyUpdate()
    TaskManage.energySchedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(TaskManage.energyUpdate, 60, false)
end

function TaskManage.onTaskEvent(eventName, args)

    print("TaskManage.onTaskEvent(eventName, args) 1")
	-- 任务激活判断
	TaskManage.checkTaskActive(eventName, args)

	-- 事件函数
	local func = ConditionProcess.getFuncByEvent(eventName)
	if func == nil then return end

	-- 影响的任务Id
	local taskIds = TaskManage.getTaskIdsByEvent(eventName)
	if taskIds == nil then return end

	for _, taskId in ipairs(taskIds) do
		TaskManage.checkResetTaskId(taskId)
		local taskInfo = TaskManage.getTaskInfoById(taskId)
		local taskConf = getTaskConfItem(taskId)
		if taskInfo ~= nil and taskConf ~= nil and taskInfo.taskStatus == taskStatus.active then
			local taskVal = taskInfo.taskVal
			local newTaskVal = func(taskConf.FinishCondition, taskConf.FinishParameters, taskVal, args)
			if taskVal ~= newTaskVal then
				TaskManage.setTaskCompleteTimes(taskId, newTaskVal)
			end
		end
	end
    
    print("TaskManage.onTaskEvent(eventName, args) 2")
end

-- 添加任务界面刷新回调
function TaskManage.setUIReloadFunc(func)
	TaskManage.uiCallBackFunc = func
end

-- 注销任务界面刷新回调
function TaskManage.clearUIReloadFunc()
	TaskManage.uiCallBackFunc = nil
end

-- 通过事件, 取出可能受到影响的任务id
function TaskManage.getTaskIdsByEvent(eventName)
	local taskIds = {}
	local conditionIds = ConditionProcess.getConditionIdsByEvent(eventName)
	if conditionIds ~= nil then
		for _, conditionId in ipairs(conditionIds) do
			local ids = TaskManage.conditionTaskIds[conditionId]
			if ids ~= nil then
				for _, id in ipairs(ids) do
					table.insert(taskIds, id)
				end
			end
		end
	end
	return taskIds
end

function TaskManage.getTaskInfoById(taskId)
	return TaskManage.tasksInfo[taskId]
end

-- 设置完成次数
function TaskManage.setTaskCompleteTimes(taskId, times)
	local taskInfo = TaskManage.getTaskInfoById(taskId)
	if taskInfo ~= nil then
		if taskInfo.taskStatus == taskStatus.active and taskInfo.taskVal ~= times then
			local taskConf = getTaskConfItem(taskId)
			if taskConf ~= nil then
				taskInfo.taskVal = times
				-- 是否告知服务器
				TaskManage.autoSendServer(taskInfo, taskConf)

				if times >= taskConf.CompleteTimes then
					-- 判断是否是隐藏的任务
					if taskConf.Show == 0 then
						-- 将任务切换成领取状态
						taskInfo.taskStatus = taskStatus.get
						TaskManage.setTaskAboutComplete(taskInfo)
						TaskManage.receiveTask(taskId)
					else
						-- 任务完成
						taskInfo.taskStatus = taskStatus.finish
						TaskManage.setTaskAboutComplete(taskInfo)
                        -- 红点
                        RedPointHelper.addCount(RedPointHelper.System.TaskAndAchieve, 1)
					end
				else
					TaskManage.setTaskAboutComplete(taskInfo)					
				end
			end
		end
	end
end

-- 根据信息, 判断是否需要发送给服务器
function TaskManage.autoSendServer(taskInfo, taskConf)
	if not taskInfo.preTaskVal then
		taskInfo.preTaskVal = 0
	end

	-- 数据没有改变不发送
	if taskInfo.preTaskVal == taskInfo.taskVal then
		return
	end
	taskInfo.preTaskVal = taskInfo.taskVal

	if ConditionProcess.needSendConditionIds[taskConf.FinishCondition] then
		-- 完成时发送的, 在没有完成前不发送
		if taskInfo.taskStatus ~= taskStatus.finish and taskInfo.taskVal < taskConf.CompleteTimes then
			return
		end
	elseif not ConditionProcess.everyNeedSendConditionIds[taskConf.FinishCondition] then
		-- 不是完成发送, 也不是改变时发送的不发送
		return
	end
	
	local bufferData = NetHelper.createBufferData(MainProtocol.Task, TaskProtocol.TaskFinishCS)
	bufferData:writeInt(taskConf.ID)
	bufferData:writeInt(taskInfo.taskVal)
	NetHelper.request(bufferData)
end

-- 领取任务, 激活新的任务(此处不计算奖励领取)
function TaskManage.receiveTask(taskId)
    TaskManage.raiseUI(taskId, "receiveBegin")
	local isReset = TaskManage.checkResetTaskId(taskId)
	if isReset == true then return end

	local taskConf = getTaskConfItem(taskId)
	if taskConf ~= nil then
		-- 处理任务本身
		if taskConf.TaskReset == 0 then
			taskModel:delTask(taskId)
            TaskManage.tasksInfo[taskId] = nil         
		else
			local taskInfo = TaskManage.getTaskInfoById(taskId)
			if taskInfo == nil then return end
			taskInfo.taskStatus = taskStatus.get
			TaskManage.setTaskAboutComplete(taskInfo)
		end
		if TaskManage.conditionTaskIds[taskConf.FinishCondition] ~= nil then
			for i, id in ipairs(TaskManage.conditionTaskIds[taskConf.FinishCondition]) do
				if id == taskId then
					table.remove(TaskManage.conditionTaskIds[taskConf.FinishCondition], i)
					break
				end
			end
		end

		-- 激活其他任务
		local endStarIds = taskConf.EndStartID
		for _, id in ipairs(endStarIds) do
			local endStarIdConf = getTaskConfItem(id)
			if endStarIdConf ~= nil and TaskManage.tasksInfo[id] == nil then
				if TaskManage.conditionTaskIds[endStarIdConf.FinishCondition] == nil then
					TaskManage.conditionTaskIds[endStarIdConf.FinishCondition] = {}
				end
				table.insert(TaskManage.conditionTaskIds[endStarIdConf.FinishCondition], id)

				local newTaskVal, isActive = ConditionProcess.getEndStarIdInfo(
					endStarIdConf.FinishCondition, endStarIdConf.FinishParameters, endStarIdConf.UnlockLv)
				local nextResetTime = TaskManage.getNextResetTime(endStarIdConf)
				local status = isActive and taskStatus.active or taskStatus.unActive
				-- 添加任务
				TaskManage.tasksInfo[id] = {taskID=id, taskVal=0, taskStatus=status , resetTime = nextResetTime, preTaskVal = 0}
				taskModel:addTask(TaskManage.tasksInfo[id])
				TaskManage.setTaskCompleteTimes(id, newTaskVal)
			end
		end
        TaskManage.energyUpdate()
	end
	TaskManage.raiseUI(taskId, "receiveEnd")
end

-- 任务激活检测
function TaskManage.checkTaskActive(eventName, args)
	if eventName == GameEvents.EventPlayerUpgradeLevel then
		local userLv = getGameModel():getUserModel():getUserLevel()
		for id, info in pairs(TaskManage.tasksInfo) do
			if info.taskStatus == taskStatus.unActive then
				local taskConf = getTaskConfItem(id)
				if taskConf ~= nil then
					if userLv >= taskConf.UnlockLv then
						info.taskStatus = taskStatus.active
						taskModel:setTask(info)
	                    TaskManage.raiseUI(info.taskID, "unActivateToActivate")
					end
				end
			end
		end
	end
end

-- 重置任务检测
function TaskManage.checkResetTaskId(taskId)
	local now = getGameModel():getNow()
	local taskInfo = TaskManage.getTaskInfoById(taskId)
	if taskInfo ~= nil and taskInfo.taskStatus ~= taskStatus.unActive then
		local taskConf = getTaskConfItem(taskId)
		if taskConf and taskConf.TaskReset ~= 0 and taskInfo.resetTime < now then
			local nextResetTime = TaskManage.getNextResetTime(taskConf)			
			taskInfo.taskVal = 0
			taskInfo.taskStatus = taskStatus.active
			taskInfo.resetTime = nextResetTime
			TaskManage.setTaskAboutComplete(taskInfo)
			local taskVal = ConditionProcess.getStateTaskCompleteTimes(taskConf.FinishCondition, taskConf.FinishParameters, 0)
			TaskManage.setTaskCompleteTimes(taskId, taskVal)
			return true
		end
	end
	return false
end

-- 重置任务检测
function TaskManage.checkResetTaskAll()
	for id, info in pairs(TaskManage.tasksInfo) do
		TaskManage.checkResetTaskId(id)
	end
end

-- 设置任务模型
function TaskManage.setTaskAboutComplete(taskInfo)
	taskModel:setTask(taskInfo)
	TaskManage.raiseUI(taskInfo.taskID, "changeCompleteTimes")
end

function TaskManage.getNextResetTime(taskConf)
	local now = getGameModel():getNow()
	local nextTimeStamp = now + 86400
	if taskConf.TaskReset == 1 then
		-- 日重置
		if #taskConf.TaskResetParameters >= 1 then
			local resetHour = taskConf.TaskResetParameters[1]
			if resetHour >= 0 and resetHour < 24 then
				nextTimeStamp = getNextTimeStamp(now, 0, resetHour)
			end
		end
	elseif taskConf.TaskReset == 2 then
		-- 周重置
		if #taskConf.TaskResetParameters >= 2 then
			local resetWeek = taskConf.TaskResetParameters[1]
			local resetHour = taskConf.TaskResetParameters[2]
			if resetWeek >=0 and resetWeek < 7 and resetHour >= 0 and resetHour < 24 then
				nextTimeStamp = getWNextTimeStamp(now, 0, resetHour, resetWeek)
			end
		end
	end
	return nextTimeStamp
end

-- 通知界面刷新
function TaskManage.raiseUI(...)
	if type(TaskManage.uiCallBackFunc) == "function" then
		TaskManage.uiCallBackFunc(...)
	end
end

function TaskManage.energyUpdate()
	for id, info in pairs(TaskManage.tasksInfo) do
		TaskManage.checkResetTaskId(id)

		local taskConf = getTaskConfItem(id)
		if taskConf ~= nil and taskConf.FinishCondition == ConditionProcess.conditionId.receiveVit then
			if info.taskStatus == taskStatus.active then
				if ModelHelper.getCurTime().h >= (taskConf.FinishParameters[1] or 0) then
					info.taskStatus = taskStatus.finish
					TaskManage.setTaskAboutComplete(info)
				end
			end
		end
	end
end

return TaskManage
