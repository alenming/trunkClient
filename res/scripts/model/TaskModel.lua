require"model.ModelConst"

-- 任务模型
local TaskModel = class("TaskModel")

function TaskModel:ctor()
	self.mCount = 0
	self.mTasks = {}
end

function TaskModel:init(buffData)
	self.mCount = buffData:readInt()							-- 任务个数
	self.mTasks = {}
	for i = 1, self.mCount do
		local taskID = buffData:readInt()						-- 任务id
		local taskVal = buffData:readInt()						-- 数值
		local taskStatus = buffData:readInt()					-- 状态
		local resetTime = buffData:readInt()					-- 重置的时间戳

		local taskConf = getTaskConfItem(taskID)
		if taskConf and taskStatus == ETaskStatus.ETASK_ACTIVE
		   and taskVal >= taskConf.CompleteTimes then
		   	taskStatus = ETaskStatus.ETASK_FINISH
		end 

		self:addTask{
			taskID = taskID, 
			taskVal = taskVal, 
			taskStatus = taskStatus, 
			resetTime = resetTime
		}
	end
end

-- 添加任务
function TaskModel:addTask(info)
	if self.mTasks[info.taskID] then
		return false
	end
	self.mTasks[info.taskID] = info
	self.mCount = self.mCount + 1
	return true
end

-- 删除任务
function TaskModel:delTask(id)
	if not self.mTasks[id] then return false end
	self.mTasks[id] = nil
	self.mCount = self.mCount - 1
	return true
end

-- 设置任务
function TaskModel:setTask(info)
	if not self.mTasks[info.taskID] then
		return false
	end
	self.mTasks[info.taskID] = info
	return true
end

function TaskModel:getTasksData()
	return self.mTasks
end

function TaskModel:getFinishTaskNum()
	local num = 0
	for _, task in pairs(self.mTasks) do
		if task.taskStatus == ETaskStatus.ETASK_FINISH then
			num = num + 1
		end
	end
	return num
end

return TaskModel