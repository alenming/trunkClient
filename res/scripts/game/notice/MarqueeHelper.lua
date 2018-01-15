
--[[
/*******************************************************************
** 创建人:	wsy
** 日  期:  2016-11-21 19:59
** 版  本:	1.0
** 描  述:  跑马灯辅助
** 应  用:
********************************************************************/
--]]

MarqueeHelper = {}
local scheduler = require("framework.scheduler")

function MarqueeHelper.init()
    MarqueeHelper.updateSchedule = nil
    MarqueeHelper.isRunnig = false
    MarqueeHelper.marqueeList = {}

    EventManager:addEventListener(GameEvents.EventChangeScene, MarqueeHelper.changeScene)
end

function MarqueeHelper.addMarquee(marquee)
    table.insert(MarqueeHelper.marqueeList, marquee)

    if not MarqueeHelper.updateSchedule then
        MarqueeHelper.updateSchedule = scheduler.scheduleGlobal(MarqueeHelper.update, 10)
    end
end

function MarqueeHelper.changeScene()
    if MarqueeHelper.isRunnig then
        MarqueeHelper.isRunnig = false
    end
end

function MarqueeHelper.update(dt)
    if MarqueeHelper.isRunnig or #MarqueeHelper.marqueeList <= 0 then
        return
    end

    for i, marquee in ipairs(MarqueeHelper.marqueeList) do
        local isRun = false
        -- 大厅跑马灯
        if 1 == marquee.highLight then
            if SceneManager.CurScene == SceneManager.Scene.SceneHall then
                isRun = true
            end
            
        -- 全局跑马灯
        elseif 2 == marquee.highLight then
            isRun = true
        end

        if isRun then
            MarqueeHelper.isRunnig = true
            table.remove(MarqueeHelper.marqueeList, i)

            local node = display.getRunningScene():getChildByName("MARQUEE")
            if not node then
                node = require("game.notice.MarqueeNode").new()
                node:setPosition(cc.p(display.cx, -100))
                node:setName("MARQUEE")
                display.getRunningScene():addChild(node, 555)
            end

            node:setString(marquee.highContent, true)
            node:running(function ()
                MarqueeHelper.isRunnig = false
            end)
            break
        end
    end
end

return MarqueeHelper