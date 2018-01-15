--------------------------------------------------
--name:UIMap
--desc:Better No Event
--data:20151106
--author:Azure
--------------------------------------------------

local EventManager = class("EventManager")

--事件集合
EventManager.Events = {}

--构造函数
function EventManager:ctor()
    
end

--添加监听
function EventManager:addEventListener(name, fun)
    table.insert(EventManager.Events, {id = name, callback = fun})
end

--删除监听
function EventManager:removeEventListener(name)
    for k,v in pairs(EventManager.Events) do
        if v.id == name then
            table.remove(EventManager.Events, k)
        end
    end
end

--触发监听
function EventManager:raiseEvent(name, ...)
     for k,v in pairs(EventManager.Events) do
        if v.id == name then
            v.callback(...)
        end
    end
end

return EventManager
