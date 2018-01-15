---------------------------------------------------
--名称:LockLayer
--描述:锁定图层
--时间:20160328
--作者:Azure
------------------------------------------------- 
local LockLayer = class("LockLayer", function ()  
    return cc.LayerColor:create(cc.c4b(0,0,0,125))  
end)  
  
--初始化  
function LockLayer:ctor()  
    local  listenner = cc.EventListenerTouchOneByOne:create()  
    listenner:setSwallowTouches(true)  
    listenner:registerScriptHandler(function(touch, event) 
        if self.callback then
            self.callback()
        end
        print("锁屏层被点击")
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN )  
    listenner:registerScriptHandler(function(touch, event) end, cc.Handler.EVENT_TOUCH_MOVED )  
    listenner:registerScriptHandler(function(touch, event) end, cc.Handler.EVENT_TOUCH_ENDED )  
    local eventDispatcher = self:getEventDispatcher()   
    eventDispatcher:addEventListenerWithSceneGraphPriority(listenner, self)  
end 

return LockLayer
