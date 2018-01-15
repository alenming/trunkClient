--[[
    EventManager主要用于管理事件
    提供注册监听、触发事件以及移除监听等功能

    当事件发生时，会传入事件名以及事件参数作为回调参数
	
	2016-3-19 by 宝爷
]]

local EventManager = class("EventManager")

EventManager.eventListeners = EventManager.eventListeners or {} 

function EventManager:addEventListener(eventName, callback)
    if nil == eventName or type(callback) ~= "function" then
        print("eventName is nil or type callback error " .. type(callback)..type(eventName))
        return false
    end

    if self.eventListeners[eventName] == nil then
        self.eventListeners[eventName] = { [callback] = true }
    else
        self.eventListeners[eventName][callback] = true
    end
end

function EventManager:setEventListener(eventName, callback)
    if nil == eventName or type(callback) ~= "function" then
        print("eventName is nil or type callback error " .. type(callback)..type(eventName))
        return false
    end
    print("setEventListener " .. eventName)
    self.eventListeners[eventName] = { [callback] = true }
end

function EventManager:removeEventListener(eventName, callback)
    if self.eventListeners[eventName] ~= nil then
        if callback == nil then
            print("removeEventListener " .. eventName)
            self.eventListeners[eventName] = nil
        else
            -- 删除指定的回调
            print("removeEventListener " .. eventName .. " callback")
            self.eventListeners[eventName][callback] = nil
        end
    end
end

function EventManager:raiseEvent(eventName, ...)

    print("=================== Lua raiseEvent !!!!")

    if self.eventListeners[eventName] ~= nil then
        print("===== raise event begin =====" .. eventName)
        for callback, _ in pairs(self.eventListeners[eventName]) do
            print("----------------- execute callback ------------- begin" .. eventName)
            callback(eventName, ...)
            print("----------------- execute callback ------------- end" .. eventName)
        end
        print("===== raise event end =====" .. eventName)
    end
end

return EventManager
