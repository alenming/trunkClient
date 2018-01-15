-- PvpTaskModel
local PvpTaskModel = class("PvpTaskModel")

function PvpTaskModel:ctor()
    self.taskIds = {}    
end

function PvpTaskModel:init(buffData)
    local taskCount = buffData:readInt()
    for i=1, taskCount do
        local taskId = buffData:readInt()
        table.insert(self.taskIds, taskId)
    end
end

function PvpTaskModel:addTaskId(taskId)
    for _, id in pairs (self.taskIds) do
        if id == taskId then
            return
        end
    end
    table.insert(self.taskIds, taskId)
end

function PvpTaskModel:removeTaskId(taskId)
    for k, id in pairs(self.taskIds) do
        if id == taskId then
            self.taskIds[k] = nil
        end
    end
end

function PvpTaskModel:resetPvpTask()
    --local pvpTasksConf = getAllArenaTask()
    --self.taskIds = {}
    --for _, task in pairs(pvpTasksConf) do
    --    if task.IsOpen ~= 0 then
    --        table.insert(self.taskIds, task.PVPTask_ID)
    --    end
    --end
end

return PvpTaskModel
