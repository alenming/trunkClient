--[[
英雄试炼主界面
]]

local UIHeroTestChoose = class("UIHeroTestChoose", function()
    return require("common.UIView").new()
end)
 
local HeroTestStage = 5 -- 英雄试炼关卡数,对应美术资源
local HeroTestUILanguage = {openDate = 1019, comma = 1149, noOpen = 1001, noEnoughCount = 1002}
local Date = {1127, 1128, 1129, 1130, 1131, 1132, 1147} -- 一至日语言包

-- 实现功能如:一、二05:00
local function getHeroTestDateText(time)
    local text = ""
    local n = 0
    for _, w in pairs(time) do
        if n > 0 then -- 加个顿号
            text = text .. CommonHelper.getUIString(HeroTestUILanguage.comma).. CommonHelper.getUIString(Date[w]) 
        else
            text = text .. CommonHelper.getUIString(Date[w]) 
        end

        n = n + 1
    end
    
    text = text .. string.format("%02d:%02d", ModelHelper.AllRefreshTime.H, ModelHelper.AllRefreshTime.M) -- 如05:00

    return text
end

function UIHeroTestChoose:ctor()
end

function UIHeroTestChoose:init()
    self.rootPath = ResConfig.UIHeroTestChoose.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.back = getChild(self.root, "BackButton")
    CsbTools.initButton(self.back, function(obj)
        obj:setTouchEnabled(false)
        UIManager.close()
    end)
    
    local view = getChild(self.root, "MainPanel/PlaceScrollView")
    view:setScrollBarEnabled(false)
    local heroTestModel = getGameModel():getHeroTestModel()
    for i = 1, HeroTestStage do
        local btn = getChild(self.root, "MainPanel/PlaceScrollView/HeroTrialPlace_" .. i)
        CsbTools.initButton(btn, function(obj)
            obj.soundId = nil
            local conf = getHeroTestConfItem(self.heroTest[i].id)
            if conf.Times <= heroTestModel:getHeroTestCount(self.heroTest[i].id) then
                obj.soundId = MusicManager.commonSound.fail
                CsbTools.createDefaultTip(CommonHelper.getUIString(HeroTestUILanguage.noEnoughCount)):addTo(self)
                return
            end
      
            if self.heroTest[i].state <= 0 then
                obj.soundId = MusicManager.commonSound.fail
                CsbTools.createDefaultTip(CommonHelper.getUIString(HeroTestUILanguage.noOpen)):addTo(self)
                return 
            end

            obj:setTouchEnabled(false)
            -- 播放效果后在打开界面
            CommonHelper.playCsbAnimate(getChild(btn, "TrialBar"), ResConfig.UIHeroTestChoose.Csb2.card, "On", false, function ()
                UIManager.open(UIManager.UI.UIHeroTestDifficulty, self.heroTest[i].id)
                obj:setTouchEnabled(true)
            end)
        end)
    end
end

function UIHeroTestChoose:onOpen(fromUIID)
    print("Open UIHeroTestChoose! fromUIID", fromUIID)
    self.back:setTouchEnabled(true)
    local model = getGameModel():getHeroTestModel()
    local w = self:checkUseStamp()
    
    self.heroTest = self:getHeroTest(w) -- 英雄试炼关卡状态(排序)
    for i = 1, #self.heroTest do
        local conf = getHeroTestConfItem(self.heroTest[i].id)
        local place = getChild(self.root, "MainPanel/PlaceScrollView/HeroTrialPlace_" .. i .. "/TrialBar")
        getChild(place, "MainPanel/NameText"):setString(getUILanConfItem(conf.Desc))
        local str = string.format(getUILanConfItem(HeroTestUILanguage.openDate), getHeroTestDateText(conf.Time)) -- 每周%s开启
        getChild(place, "MainPanel/TipText"):setString(str)
        CsbTools.replaceImg(getChild(place, "MainPanel/HeroImage"), conf.Pic)
        getChild(place, "MainPanel/HeroImage_Grey"):loadTextures(conf.Pic, conf.Pic, conf.Pic, 1)
        
        local s = nil
        local canChallenge = true
        if self.heroTest[i].state == 1 then   --可挑战
            s = "Normal"
            if conf.Times <= model:getHeroTestCount(self.heroTest[i].id) then     --已挑战
                s = "Over"
                canChallenge = false
            end
        else
            s = "NoOpen"   --未开启
            canChallenge = false
        end
        CommonHelper.playCsbAnimate(place, ResConfig.UIHeroTestChoose.Csb2.card, s, false)

        getChild(place, "MainPanel/RedTipPoint"):setVisible(canChallenge)
    end
end

function UIHeroTestChoose:checkUseStamp()
    local curTime = getGameModel():getNow()
    local w = tonumber(os.date("%w", curTime))-- 周日为0
    local h = tonumber(os.date("%H", curTime))
    local m = tonumber(os.date("%M", curTime))
    w = (w == 0 and 7 or w)

    if h < ModelHelper.AllRefreshTime.H
        or (h == ModelHelper.AllRefreshTime.H and m < ModelHelper.AllRefreshTime.M) then
            w = w - 1 -- 这时间段前的boss为前一天
            w = (w == 0 and 7 or w)
    end
    
    local model = getGameModel():getHeroTestModel()
    local useStamp = model:getHeroTestStamp()
    if curTime > useStamp then -- 时间判断,过了时间前端需要自己算出下次刷新时间
        local nextWday = 8 -- 找出活动中最近的周几
        local minWday = 8
        local b = false
        local list = getHeroTestItemList()
        for _, id in pairs(list) do
            local conf = getHeroTestConfItem(id)
            for _, d in pairs(conf.Time) do
                if minWday > d then
                    minWday = d
                end

                if d > w and d < nextWday then -- 大于当前星期几,并且最小
                    nextWday = d
                    b = true
                end
            end
        end

        if b then
            useStamp = getWNextTimeStamp(curTime, ModelHelper.AllRefreshTime.M, ModelHelper.AllRefreshTime.H, nextWday)
        else
            useStamp = getWNextTimeStamp(curTime, ModelHelper.AllRefreshTime.M, ModelHelper.AllRefreshTime.H, minWday)
        end
        
        model:resetHeroTest(useStamp)
    end

    return w
end

function UIHeroTestChoose:getHeroTest(w)
    local tb = {}
    local function isin(tb, i) -- 如果是在开启时间则返回1,否则0
        for k,v in pairs(tb) do
            if v == i then
                return 1
            end
        end
        return 0
    end

    local list = getHeroTestItemList()
    for _, id in pairs(list) do
        local conf = getHeroTestConfItem(id)
        local s = isin(conf.Time, w)
        table.insert(tb, {id = id, state = s})
    end

    local function cmp(a, b)
        if a.state > b.state then
            return true
        elseif a.state == b.state and a.id < b.id then
            return true
        end
        return false
    end

    table.sort(tb, cmp)

    return tb
end

return UIHeroTestChoose
