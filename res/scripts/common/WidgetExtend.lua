--[[
    实现控件的功能扩展，传入按钮对象可以扩展按钮的能力
    1.支持为按钮扩展长按的能力

    依赖于Cocos2d-xLua基础脚本框架
    2016-3-9 by 宝爷
]]

WidgetExtend = {}

local TouchType = {
    TouchBegan = 0,
    TouchMove = 1,
    TouchEnd = 2,
    TouchCanceled = 3,
}

local function addHoldCallbackEX(button, duration, times, callback, cancelCallback)
    if times < 0 then times = 0 end
    button:addTouchEventListener(function(obj, touchType)
        -- 按下时执行一个Action，每隔duration执行一次callback，执行times次
        if touchType == TouchType.TouchBegan then
            local seq = transition.sequence({
                cc.DelayTime:create(duration),
                cc.CallFunc:create(callback),
            })
            if times == 0 then
                button._holdActionEx = cc.RepeatForever:create(seq)
            elseif times == 1 then
                button._holdActionEx = seq
            else
                button._holdActionEx = cc.Repeat:create(seq, times)
            end
            button._holdActionEx:retain()
            button:runAction(button._holdActionEx)
        elseif touchType == TouchType.TouchEnd or touchType == TouchType.TouchCanceled then
            -- 松开时取消这个Action
            button:stopAction(button._holdActionEx)
            button._holdActionEx:release()
            if cancelCallback and type(cancelCallback) == "function" then
                cancelCallback()
            end
        end
    end)
end

--[[ 
    为控件添加长按功能
    添加长按触发时的回调参数分别为时间间隔，次数以及回调函数
    times为0表示循环，1表示只执行一次，>1表示执行time次
    当松开按钮时自动取消
    button:addHoldCallbackEX(duration, times, callback)
]]
function WidgetExtend.extendHold(button)
    -- 如果不是Widget控件
    if type(button.addClickEventListener) ~= "function"
    and type(button.addTouchEventListener) ~= "function" then
        print("Error: extendHold failed!")
        return
    end

    -- 扩展长按功能
    button.addHoldCallbackEX = addHoldCallbackEX;
end

local function addClickEx(button, exClickCallback)
    if exClickCallback == button._curClickCallbackEx then
        print("函数相同")
        return
    end

    button._prevClickCallbackEx = button._curClickCallbackEx
    button._curWarpClickCallbackEx = function(...)
            if type(button._prevClickCallbackEx) == "function" then
                button._prevClickCallbackEx(...)
            end
            if type(exClickCallback) == "function" then
                exClickCallback(...)
            end
        end
    button:addClickEventListener(button._curWarpClickCallbackEx)
end

local function removeClickEx(button)
    if type(button._prevClickCallbackEx) == "function" then
        button:addClickEventListener(button._prevClickCallbackEx)
        button._prevClickCallbackEx = nil
        button._curWarpClickCallbackEx = nil
    end
end

function WidgetExtend.initClick()
    -- 全局变量
    if GIsWidgetExtend == nil or not GIsWidgetExtend then    
        GIsWidgetExtend = true
        if type(ccui.Widget) == "table" then
            ccui.Widget._realAddClickEventListenerEx = ccui.Widget.addClickEventListener
            ccui.Widget.addClickEventListener = function(widget, callback)
                widget._curClickCallbackEx = callback
                widget:_realAddClickEventListenerEx(callback)
            end
            print("WidgetExtend initClick Success !")
        end
    end
end

--[[
    为按钮添加额外的点击事件（在不影响原先点击事件的前提下，触发额外的点击事件）
]]
function WidgetExtend.extendClick(button)
    -- 如果不是Widget控件
    if type(button.addClickEventListener) ~= "function"
    and type(button.addTouchEventListener) ~= "function" then
        print("Error: extendClick failed!")
        return
    end

    button.addClickEx = addClickEx
    button.removeClickEx = removeClickEx
end

-- 给一个节点包裹上一个widget
function WidgetExtend.wrapNodeWithWidget(node)
    if not node then
        print("WidgetExtend.wrapNodeWithWidget got nil")
        return
    end

    local parent = node:getParent()
    if parent then
        node:retain()
        node:removeFromParent()
    end

    local size = node:getContentSize()
    local widget = ccui.Widget:create()
    widget:addChild(node)
    widget:setContentSize(node:getContentSize())
    node:setPosition(cc.p(size.width / 2, size.height / 2))

    if parent then
        node:release()
    end

    return widget
end

return WidgetExtend