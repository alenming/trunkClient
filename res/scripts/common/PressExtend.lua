--[[
	实现长短按的功能
]]

PressExtend = {}

local TouchType = {
    TouchBegan = 0,
    TouchMove = 1,
    TouchEnd = 2,
    TouchCanceled = 3,
}

local function addPressCallbackEX(button, pressTime, clickCallBack, pressCallBack, cancelCallBack)	
	button:addTouchEventListener(function(obj, touchType)
		function delayCallBack()
			pressTime = -pressTime
            if type(pressCallBack) == "function" then
                pressCallBack(button, 2)
            end
		end

        if touchType == TouchType.TouchBegan then
        	button._pressEx = transition.sequence({
                cc.DelayTime:create(pressTime),
                cc.CallFunc:create(delayCallBack),
            })
            button._pressEx:retain()            
            button:runAction(button._pressEx)

        elseif touchType == TouchType.TouchEnd or touchType == TouchType.TouchCanceled then
            button:stopAction(button._pressEx)
            button._pressEx:release()
            if pressTime < 0 then
                if type(cancelCallBack) == "function" then
                    cancelCallBack(button, 3)
                end
            	pressTime = -pressTime
            else
                if type(clickCallBack) == "function" then
            	   clickCallBack(button, 1)
                end
            end
        end
    end)
end

--[[ 
    为控件添加长短按的功能
    pressTime: 多长时间算长按
    clickCallBack: 点击回调(没达到长按时间)
    pressCallBack: 长按回调
    cancelCallBack: 长按后取消回调
]]
function PressExtend.addPressEX(button, pressTime, clickCallBack, pressCallBack, cancelCallBack)
	if type(button.addTouchEventListener) ~= "function" then
		print("PressExtend not support !")
		return
	end

	addPressCallbackEX(button, pressTime, clickCallBack, pressCallBack, cancelCallBack)
end