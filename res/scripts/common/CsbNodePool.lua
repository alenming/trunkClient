--[[
    CsbNodePool 用于复用CsbNode，节省从ResManager中clone的开销

    2015-11-5 By 宝爷
]]

local CsbNodePool = class("CsbNodePool")
local Scheduler = require("framework.scheduler")
-- 传入csb的路径
function CsbNodePool:ctor(csbPath)
    self.csbPath = csbPath
    self.preloadCount = 0
    self.autoreleasePool = {}
    self.freePool = {}
end

-- 自动预加载，要加载多少个，每帧加载多少个，默认每帧加载2个
function CsbNodePool:preload(count, batch, callback)
    if self.preloadCount > 0 then
        self.preloadCount = self.preloadCount + count;
    else
        self.preloadCount = count
        self.batch = batch or 2
        self.scheduleFunc = Scheduler.scheduleGlobal(function(dt)
            for i = 1, self.batch do
                self.preloadCount = self.preloadCount - 1
                local csbNode = getResManager():cloneCsbNode(self.csbPath)
                if csbNode then
                    csbNode:retain()
                    self.freePool[#self.freePool + 1] = csbNode
                end

                if self.preloadCount <= 0 then
                    Scheduler.unscheduleGlobal(self.scheduleFunc)
                    self.scheduleFunc = nil
                    if type(callback) == "function" then
                        callback()
                    end
                    return
                end
            end
        end, 0.01)
    end
end

-- 回收一个csb
function CsbNodePool:freeCsb(csbNode)
    if csbNode then
        csbNode:retain()
        self.freePool[#self.freePool + 1] = csbNode
    end
end

-- 从池中获取一个csb
function CsbNodePool:getCsb()
    if #self.freePool >= 1 then
        local csbNode = self.freePool[#self.freePool]
        -- csbNode:autorelease() cocos2d-x并未导出该接口
        self.autoreleasePool[#self.autoreleasePool + 1] = csbNode
        self.freePool[#self.freePool] = nil
        return csbNode
    else
        return getResManager():cloneCsbNode(self.csbPath)
    end
end

-- 清理池子
function CsbNodePool:clear()
    if self.scheduleFunc then
        self.preloadCount = 0
        scheduler.unscheduleGlobal(self.scheduleFunc)
    end
    for _,node in ipairs(self.freePool) do
        node:cleanup()
        node:release()
    end
    self.freePool = {}
    for _,node in ipairs(self.autoreleasePool) do
        node:cleanup()
        node:release()
    end
    self.autoreleasePool = {}   
end

return CsbNodePool