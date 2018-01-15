---------------------------------------------------
--名称:Guide
--描述:引导
--时间:20160328
--作者:Azure
-------------------------------------------------
local Guide = class("Guide")

--构造函数
function Guide:ctor(id)
    self.guideID = id
    self.guideConf = getGuideConfItem(self.guideID)
    if not self.guideConf then
        print("大策划，你开启了一个不存在的引导" .. id)
        return
    end
    self.listenCallback = handler(self, self.onGuideRaise)
    print("引导" .. id .. "监听事件" .. self.guideConf.Listen)
    if  self.guideConf.Listen ~= 0 then
        EventManager:addEventListener(self.guideConf.Listen, self.listenCallback)
    end
end

function Guide:onEnter()
    if self.guideConf.Listen == 0 then
        self.listenCallback(0)
    end
end

--触发回调
function Guide:onGuideRaise(eventName, ...)
    print("引导" .. self.guideID .. "监听事件触发" .. eventName)
    --跳过条件
    local skip = false
    for _, d in pairs(self.guideConf.SkipCondition) do
        if d.Type ~= 0 then
            skip = GuideCondition.judgeCondition(d, ...)
            -- 如果没有配置跳过条件
            if not skip then
                break
            end 
        end
    end
    if skip then
        -- 跳过引导相当于完成引导，需要将引导中会解锁的按钮全部解锁
        -- 强制结束
        print("引导满足完成条件，直接结束")
        self:finish(true)
        GuideManager.finishGuide(self)
        return
    end
    
    --开始条件
    for _, d in pairs(self.guideConf.StartCondition) do
        if d.Type ~= 0 then
            print("判断条件" .. d.Type)
            if not GuideCondition.judgeCondition(d, ...) then
                print("引导不满足开始条件")
                return
            end
        end
    end

    --确定开始
    EventManager:removeEventListener(self.guideConf.Listen, self.listenCallback)
    GuideManager.executeGuide(self)
    self:startGuide()
end

--开始引导
function Guide:startGuide()
    if UIManager.isTopUI(UIManager.UI.UIUnionReNotice) then
        UIManager.close()
    end

    local list = getGuideStepItemList(self.guideID)
    if list == nil then
        print("getGuideStepItemList error guideID " .. self.guideID)
        return
    end

    local scene = cc.Director:getInstance():getRunningScene()
    self.guideLayer = cc.Layer:create()
    self.guideLayer:setName("GuideLayer")
   -- self.guideLayer:setTouchEnabled(false)

    self.steps = {}
    for _,v in pairs(list) do
        local step = require("guide.GuideStep").new(self, self.guideLayer, self.guideID, v)
        table.insert(self.steps, step)
    end
    
    self.stepIndex = 1
    self.currentStep = self.steps[self.stepIndex]
    self.guideLayer:setLocalZOrder(self.currentStep.ZOrder.TouchLayer)
    scene:addChild(self.guideLayer)
    self.guideLayer:retain()
    self.currentStep:execute()
end

--步骤结束
function Guide:stepOver(step)
    if step == self.currentStep then
        self.stepIndex = self.stepIndex + 1
        if self.stepIndex > #self.steps then
            self:finish()
            GuideManager.finishGuide(self)
            print("Guide finish" .. self.guideID .. " step " .. self.stepIndex)
        else
            print("Guide step over " .. self.guideID .. " step " .. self.stepIndex)
            self.currentStep:clean()
            self.currentStep = self.steps[self.stepIndex]
            self.currentStep:execute()
        end
    else
        print("Guide stepOver error " .. self.currentStep.stepID .. " step " .. step.stepID )
    end
end

--自动解锁跳过引导的按钮
function Guide:autoUnlockButton()
    local list = getGuideStepItemList(self.guideID)
    if list == nil or #list <= 0 then
        return
    end

    for _, stepId in ipairs(list) do
        local stepConf = getGuideStepConfItem(self.guideID, stepId)
        if stepConf then
            if stepConf.ShowButton ~= nil and #stepConf.ShowButton > 0 then
                for btnIdx, btnId in pairs(stepConf.ShowButton) do
                    -- 已解锁的按钮不会重复解锁
                    GuideUI.unlockButton(btnId)
                end
            end
        end
    end
end

--结束引导，分为正常结束和强制结束，强制结束为跳过、被替换
function Guide:finish(isfouce)
    print("guide finish ==========")
    EventManager:removeEventListener(self.guideConf.Listen, self.listenCallback)
    -- 如果是被强制结束，需要自动解锁【未解锁】的按钮
    if isfouce then
        self:autoUnlockButton()
    end

    if self.currentStep then
        self.currentStep:clean()
    end
    if self.guideLayer then
        self.guideLayer:removeFromParent()
        self.guideLayer:release()
        self.guideLayer = nil
    end
end

return Guide