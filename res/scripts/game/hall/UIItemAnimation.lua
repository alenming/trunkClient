--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-13 19:59
** 版  本:	1.0
** 描  述:  播放物品获得的飞行动画
** 应  用:
********************************************************************/
--]]

local UIItemAnimation = class("UIItemAnimation")

-- 构造函数
function UIItemAnimation:ctor(addCount, extend, layer, csbPath, callfunc)
    local itemCsb = getResManager():cloneCsbNode(csbPath)
    layer:addChild(itemCsb)
    CommonHelper.layoutNode(itemCsb)

    local itemAct = cc.CSLoader:createTimeline(csbPath)
    itemCsb:runAction(itemAct)

    -- 回调返回需要增加的数量 
    local allCallCount = 4
    local onceAddCount = math.floor(addCount * extend / 4)
    local lastAddCount = addCount * extend - onceAddCount*3
    itemAct:setFrameEventCallFunc(function(frame)
        print("frame:getEvent()", frame:getEvent())
        if frame:getEvent() == "Add" then
            if type(callfunc) == "function" then
                if allCallCount > 1 then
                    callfunc(onceAddCount)
                elseif allCallCount == 1 then
                    callfunc(lastAddCount)
                end
                allCallCount = allCallCount - 1
            end
        elseif frame:getEvent() == "End" then
            itemCsb:removeFromParent()
        end
    end)

    if addCount * extend > 0 then
        itemAct:play("Big", false)
    end
end

return UIItemAnimation