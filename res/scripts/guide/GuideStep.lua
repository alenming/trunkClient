---------------------------------------------------
--名称:GuideStep
--描述:引导步骤
--时间:20160405
--作者:Azure
-------------------------------------------------
require("guide.GuideUI")

local GuideStep = class("GuideStep")
local Scheduler = require("framework.scheduler") 

--引导步骤结束类型
GuideStep.EndType = 
{
    GSET_TOUCHOUT   = -2,      --触摸结束（穿透）
    GSET_TOUCH      = -1,      --触摸结束
    GSET_TIME       = 0,       --时间结束
}

--特效类型
GuideStep.EffectType = 
{
    GSFT_SHAKE  = 1,       --震动
    GSFT_BLINK  = 2        --闪烁
}

--演员表
GuideStep.Actor = 
{
    [1] = {[1] = 1100, [2] = 1200},
    [2] = {[1] = 1100, [2] = 1200},
}

GuideStep.ZOrder = 
{
    LockLayer = 10000,
    TouchLayer = 10001,
    DialogLayer = 10003,
    HightLayer = 10004,
}

--构造函数
function GuideStep:ctor(guide, layer, guideID, stepID)
    self.Guide = guide
    self.Layer = layer
    layer:retain()
    self.guideID = guideID
    self.stepID = stepID
    self.stepConf = getGuideStepConfItem(self.guideID, self.stepID)
end

--执行
function GuideStep:execute()
    print("当前引导：" .. self.guideID .. " 开始步骤:" .. self.stepID)
    print("execute " .. debug.traceback())
    self:start()       
    self:hideUI()
    self:playTip()
    self:lockScreen()          
    self:showButton()          
    self:pauseBattle()         
    self:playCG()              
    self:playEffect()          
    self:playCamera()          
    self:playDialog()   
    self:playSoundEffect()       
end

--清理
function GuideStep:clean()
    if self.Callback then
        EventManager:removeEventListener(self.stepConf.EndType, self.Callback)
    end
    self:resumeAndUnlock()
end 

--开始步骤
function GuideStep:start()
    --如果时间大于0，则开启时间限制
    local time = self.stepConf.TotalTime
    if time > 0 then
        print("stepConf.TotalTime" .. self.stepConf.TotalTime)
        local delay = cc.DelayTime:create(time * 0.001)
        local callback = cc.CallFunc:create(function()
            self:finish()
        end)
        self.Layer:runAction(cc.Sequence:create(delay, callback))
    end
    --如果是触摸消息
    if GuideStep.EndType.GSET_TOUCH == self.stepConf.EndType
    or GuideStep.EndType.GSET_TOUCHOUT == self.stepConf.EndType then
        self.TouchLayer = cc.Layer:create()
        self.TouchLayer:retain()
        self.TouchLayer:setLocalZOrder(GuideStep.ZOrder.HightLayer)
        self.TouchLayer:setContentSize(display.width, display.height)
        display.getRunningScene():addChild(self.TouchLayer)

        local listener = cc.EventListenerTouchOneByOne:create()  
        listener:setSwallowTouches(GuideStep.EndType.GSET_TOUCH == self.stepConf.EndType)  
        listener:registerScriptHandler(function(touch, event) 
            return true 
        end, cc.Handler.EVENT_TOUCH_BEGAN )  
        listener:registerScriptHandler(function(touch, event) end, cc.Handler.EVENT_TOUCH_MOVED )  
        listener:registerScriptHandler(function(touch, event)
            print("触摸层被点击")
            self:finish()
        end, cc.Handler.EVENT_TOUCH_ENDED )  
        self.TouchLayer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self.TouchLayer)  

        --[[self.Layer:setGlobalZOrder()
        self.Layer:setTouchEnabled(true)
        self.Layer:setTouchSwallowEnabled(true)
        self.Layer:registerScriptTouchHandler(function(eventType, x, y)
            if eventType == "began" then
                self:finish()
            end
        end)]]
    end
    
    if GuideStep.EndType.GSET_TIME == self.stepConf.EndType then
        return
    else
        self.Callback = function(eventName, ...)
            -- 步骤结束条件或没有条件
            if GuideCondition.judgeCondition(self.stepConf.EndCondition, ...) 
            or self.stepConf.EndCondition.Type == 0 then
                EventManager:removeEventListener(eventName, self.Callback)
                self:finish()
            end
        end

        if GameEvents.EventButtonClick == self.stepConf.EndType then
            local btn = GuideUI.getUINode(self.stepConf.ButtonID)
            if btn then
                print("extend button " .. self.stepConf.ButtonID .. debug.traceback())
                EventManager:setEventListener(self.stepConf.EndType, self.Callback)
                WidgetExtend.extendClick(btn)
                btn:addClickEx(function()
                    print("extend button click " .. debug.traceback())
                    EventManager:raiseEvent(GameEvents.EventButtonClick, self.stepConf.ButtonID)
                end)
            end 
        else
            EventManager:addEventListener(self.stepConf.EndType, self.Callback)
        end
    end
end

--完成步骤
function GuideStep:finish()
    -- 请求统计步骤锚点
    if self.stepConf.Anchor ~= 0 then
        local bufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginGuideInfoCS)
        bufferData:writeInt(self.stepConf.Anchor)
        NetHelper.request(bufferData)
    end

    print("当前引导：" .. self.guideID .. " 结束步骤:" .. self.stepID)
    -- 关闭上个步骤音效
    if self.stepEndCloseSoundId and self.stepEndCloseSoundId > 0 then
        MusicManager.stopEffect(self.stepSoundId)
        self.stepEndCloseSoundId = 0
    end

    print("step finish " .. debug.traceback())
    self.Guide:stepOver(self)
end

--隐藏UI
function GuideStep:hideUI()
    if 1 == self.stepConf.IsHideUI then
        --屏蔽战斗层UI
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            self.HideUINode = uiLayer
            self.HideUINode:retain()
            uiLayer:setVisible(false)
        end
    elseif 2 == self.stepConf.IsHideUI then
        --屏蔽技能UI
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            for i = 1, 3 do
                local skillBtn = CommonHelper.getChild(uiLayer, "Fight/MainPanel/SkillButton_" .. i)
                if skillBtn then
                    skillBtn:setVisible(false)
                end
            end
        end
    elseif 3 == self.stepConf.IsHideUI then
        -- 屏蔽下方的战斗UI
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            local downPanel = CommonHelper.getChild(uiLayer, "Fight/MainPanel/DownPanel")
            if downPanel then
                downPanel:setVisible(false)
            end
        end
    end
end

--锁屏
function GuideStep:lockScreen()
    if 0 < self.stepConf.IsLock then
        print("执行锁屏")
        --添加屏蔽层
        self.LockLayer = require("guide.LockLayer").new()
        self.LockLayer:retain()
        self.LockLayer:setName("LockLayer")
        self.LockLayer:setContentSize(display.width, display.height)
        self.LockLayer:setLocalZOrder(GuideStep.ZOrder.LockLayer)
        --self.LockLayer:setTouchEnabled(true)
        --self.LockLayer:setTouchSwallowEnabled(true)
        if 2 ==  self.stepConf.IsLock then
            self.LockLayer:setOpacity(0)
        end
        display.getRunningScene():addChild(self.LockLayer)

        --设置按钮到最外层
        local btn = GuideUI.getUINode(self.stepConf.ButtonID)
        if not btn then
            print("find button Id " .. self.stepConf.ButtonID .. " error")
            return
        end
        print("找到按钮" .. self.stepConf.ButtonID)
        self.HightButton = btn
        self.HightButton:setVisible(true)
        self.HightButton:retain()
        self.Z = self.HightButton:getLocalZOrder()
        self.HightButton:setLocalZOrder(GuideStep.ZOrder.HightLayer)
        if type(self.HightButton.isSwallowTouches) == "function" then
            self.BtnSwallow = self.HightButton:isSwallowTouches()
            self.HightButton:setSwallowTouches(true)
            print("self.HightButton:setSwallowTouches(true)")
        end
        --高亮按钮
        if self.stepConf.HighlightRes ~= "0" then
            local hl = cc.CSLoader:createNode(self.stepConf.HighlightRes)
            if nil ~= hl then
                self.HightNodeEffect = hl
                self.HightNodeEffect:retain()
                hl:setName("Highlight")
                hl:setLocalZOrder(100)
                btn:addChild(hl)
                if #self.stepConf.HighlightPos == 2 then
                    local size = btn:getContentSize()
                    hl:setPosition(cc.p(size.width * 0.5 + self.stepConf.HighlightPos[1], size.height * 0.5 + self.stepConf.HighlightPos[2]))
                end
                if self.stepConf.HighlightAni ~= ""
                    and self.stepConf.HighlightAni ~= "0" then
                    CommonHelper.playCsbAnimate(hl, self.stepConf.HighlightRes, self.stepConf.HighlightAni, true)
                end
            else
                print("load HighlightRes error " .. self.stepConf.HighlightRes)
            end
        end

        self.LockLayer.callback = function ()
            local badtouch = cc.CSLoader:createNode("ui_new/g_guide/BadTouch.csb")
            if nil ~= badtouch then
                if #self.stepConf.HighlightPos == 2 then
                    local size = btn:getContentSize()
                    badtouch:setPosition(cc.p(size.width * 0.5 + self.stepConf.HighlightPos[1], size.height * 0.5 + self.stepConf.HighlightPos[2]))
                end
                badtouch:setLocalZOrder(99)
                btn:addChild(badtouch)
                -- 点击高亮按钮外的地方播放 提醒点击高亮按钮的效果
                CommonHelper.playCsbAnimate(badtouch, "ui_new/g_guide/BadTouch.csb", "BadTouch", false, 
                function ()
                    badtouch:removeFromParent()
                end)
            end
        end

        -- 移动按钮
        self.OldParent = CommonHelper.moveNode(btn, display.getRunningScene())
        self.OldParent:retain()
        btn:setLocalZOrder(GuideStep.ZOrder.DialogLayer)
        print("锁屏执行完成")
        --setCsbGlobalZOrder(btn, GuideStep.ZOrder.DialogLayer)
    end
end

--开启新按钮
function GuideStep:showButton() 
    for _,id in pairs(self.stepConf.ShowButton) do
        print("解锁按钮" .. id)
        local btn = GuideUI.unlockButton(id)
        if btn then
            print("按钮解锁CSB动画" .. self.stepConf.ShowCSB)
            -- 播放按钮解锁动画
            if tostring(self.stepConf.ShowCSB) ~= "0" then
                local hl = cc.CSLoader:createNode(self.stepConf.ShowCSB)
                hl:setLocalZOrder(100)
                btn:addChild(hl)
                if self.stepConf.ShowTag ~= "" and tostring(self.stepConf.ShowTag) ~= "0" then
                    --btn:setVisible(false)
                    CommonHelper.playCsbAnimate(hl, self.stepConf.ShowCSB, self.stepConf.ShowTag, false)
                end
            end
        else
            print("找不到按钮" .. id)
        end
    end 
end

--暂停战斗
function GuideStep:pauseBattle()
    if 1 == self.stepConf.IsPause then
        -- 不暂停动画
        pauseBattle(1)
    elseif 2 == self.stepConf.IsPause then
        -- 暂停动画
        pauseBattle(2)
    end
end

--播放动画
function GuideStep:playCG()
    if "0" == self.stepConf.BgRes then       
        return
    elseif "-1" == self.stepConf.BgRes then     
        return
    elseif "1" == self.stepConf.BgRes then    
        self.Layer:removeChildByName("CG")
    else                
        local CG = cc.CSLoader:createNode(self.stepConf.BgRes)
        CommonHelper.layoutNode(CG) -- 自适应
        CG:setName("CG")
        self.Layer:addChild(CG)
        local action  = cc.CSLoader:createTimeline(self.stepConf.BgRes)
        CG:runAction(action)
        action:play(self.stepConf.BgTag, false)
        self:playAnimation(CG, action)
    end
end

--动画事件
function GuideStep:playAnimation(node, action)
    if not node then
        return
    end
    local children = node:getChildren()
    for k,v in pairs(children) do
        local name = v:getName()
        local ret = string.find(name, "Role_")
        if ret then
            local roleID = tonumber(string.sub(name, ret + 5))
            v:getChildByName("ArmatureNode_" .. roleID):setVisible(false)
            local new = v:getChildByName("Node_" .. roleID)
            local actor = GuideStep.Actor[1][roleID]
            local aniID = getHeroConfItem(actor).Common.AnimationID
            AnimatePool.createAnimate(aniID, function(animation)
                if animation then
                    new:addChild(animation)
                end
            end)
            action:setFrameEventCallFunc(function(frame)
                local n = frame:getNode()
                local e = frame:getEvent()
            end)
        end
        self:playAnimation(v, action)
    end
end

--播放特效
function GuideStep:playEffect()
    if GuideStep.EffectType.GSFT_SHAKE == self.stepConf.EffectType then
        doShake(display.getRunningScene(), self.stepConf.EffectTime * 0.001, self.stepConf.EffectParam)
    elseif GuideStep.EffectType.GSFT_BLINK == self.stepConf.EffectType then
        local str = "ui_new/p_public/effect/Dying.csb"
        self.Blink = cc.CSLoader:createNode(str)
        CommonHelper.layoutNode(self.Blink) -- 自适应
        self.Layer:addChild(self.Blink)
        CommonHelper.playCsbAnimate(self.Blink, str, "Dying", true)
        local delay = cc.DelayTime:create(self.stepConf.EffectTime * 0.001)
        local rd = cc.removeSelf()
        self.Blink:runAction(cc.Sequence(delay, rd))
    end
end 

--播放镜头
function GuideStep:playCamera()
    local id = self.stepConf.CameraID
    if id > 0 then
        doCamera(id)
    end
end

--播放对话框
function GuideStep:playDialog()
    if "0" ~= self.stepConf.DialogRes and 
        "" ~= self.stepConf.DialogRes then
        -- 创建对话框CSB
        local Dialog = cc.CSLoader:createNode(self.stepConf.DialogRes)
        if Dialog == nil then
            print("playDialog Load csbNode Error " .. self.stepConf.DialogRes)
            return
        end
        
        CommonHelper.layoutNode(Dialog) -- 自适应
        Dialog:setName("Dialog")
        self.Layer:addChild(Dialog)

        if self.stepConf.DialogAni and self.stepConf.DialogAni ~= "" then
            local DialogAct = cc.CSLoader:createTimeline(self.stepConf.DialogRes)
            Dialog:runAction(DialogAct)
            DialogAct:play(self.stepConf.DialogAni, false)
        else
            print("playDialog animate Error")
        end

        -- 不理会小三角
        --local btn = CommonHelper.getChild(Dialog, "MainPanel/TipsButton")
        --btn:addClickEventListener(function() end)

        -- 设置对话文本
        local text = CommonHelper.getChild(Dialog, "MainPanel/TalkText")
        if text and tonumber(self.stepConf.DialogContent) > 0 then
            local guideRichStr = getStoryLanConfItem(self.stepConf.DialogContent)
            print("set text .......................... " .. guideRichStr)
            if string.find(guideRichStr, "</") ~= nil then
                print("goto rich " .. guideRichStr)
    	        local guideRichText = createRichTextWithCode(guideRichStr, text:getContentSize().width)
                text:getParent():addChild(guideRichText)
                local x, y = text:getPosition()
	            guideRichText:setPosition(cc.p(x, y - guideRichText:getContentSize().height))
                text:setString("")
            else
                text:setString(guideRichStr)
            end
        end

        -- 设置标题
        local title = CommonHelper.getChild(Dialog, "MainPanel/TitleText")
        if title then
            title:setString(getStoryLanConfItem(self.stepConf.HeadName))
        end

        --local icon = CommonHelper.getChild(Dialog, "MainPanel/Image_Head")
        --if icon then
        --    local b = cc.SpriteFrameCache:getInstance():getSpriteFrame(self.stepConf.HeadRes)
        --    icon:loadTexture(b and self.stepConf.HeadRes or "", 1)
        --end

        if #(self.stepConf.DialogPos) == 2 then
            Dialog:setPosition(cc.p(self.stepConf.DialogPos[1], self.stepConf.DialogPos[2]))
        end

        local icon = CommonHelper.getChild(Dialog, "MainPanel/Head")
        if "0" ~= self.stepConf.HeadRes 
            and "" ~= self.stepConf.HeadRes and icon ~= nil then
            local head = cc.CSLoader:createNode(self.stepConf.HeadRes)
            if head then
                local action = cc.CSLoader:createTimeline(self.stepConf.HeadRes)
                head:runAction(action)
                action:play(self.stepConf.HeadTag, false)
                icon:addChild(head)
            else
                print("Head Res Load Error" .. self.stepConf.HeadRes)
            end
        end
        Dialog:setLocalZOrder(GuideStep.ZOrder.DialogLayer)
        --setCsbGlobalZOrder(Dialog, GuideStep.ZOrder.DialogLayer)
    end
end

--播放提示框
function GuideStep:playTip()
    if "0" == self.stepConf.TipsRes or "" == self.stepConf.TipsRes then
        return
    else
        local tip = cc.CSLoader:createNode(self.stepConf.TipsRes)
        if tip ~= nil then
            tip:setName("Tip")
            tip:setLocalZOrder(100)
            local text = CommonHelper.getChild(tip, "MainPanel/TalkText")
            if text and tonumber(self.stepConf.TipsContent) > 0 then
                local guideRichStr = getStoryLanConfItem(self.stepConf.TipsContent)
                print(self.stepConf.TipsContent .. " set text .......................... " .. guideRichStr)
                if string.find(guideRichStr, "</") ~= nil then
                    print("goto rich " .. guideRichStr)
    	            local guideRichText = createRichTextWithCode(guideRichStr, text:getContentSize().width)
                    text:getParent():addChild(guideRichText)
                    local x, y = text:getPosition()
	                guideRichText:setPosition(cc.p(x, y - guideRichText:getContentSize().height))
                    text:setString("")
                else
                    text:setString(guideRichStr)
                end
            end
            local btn = GuideUI.getUINode(self.stepConf.ButtonID)
            if btn then
                btn:addChild(tip)
                self.Tip = tip
                self.Tip:retain()
                if #(self.stepConf.TipsPos) == 2 then
                    local size = btn:getContentSize()
                    tip:setPosition(cc.p(size.width * 0.5 + self.stepConf.TipsPos[1], size.height * 0.5 + self.stepConf.TipsPos[2]))
                end
                
                if self.stepConf.TipsAni ~= ""
                    and self.stepConf.TipsAni ~= "0" then
                    CommonHelper.playCsbAnimate(tip, self.stepConf.TipsRes, self.stepConf.TipsAni, true)
                end
            end
        else
            print("GuideStep:playTip error " .. self.stepConf.TipsRes)
        end
    end
end

--取消暂停和锁屏
function GuideStep:resumeAndUnlock()
    if 0 < self.stepConf.IsLock then
        -- 移除锁屏
        if self.LockLayer then
            self.LockLayer:removeFromParent()
            self.LockLayer:release()
            self.LockLayer = nil
        end
        -- 移除按钮高亮资源
        if self.HightNodeEffect then
            self.HightNodeEffect:removeFromParent()
            self.HightNodeEffect:release()
            self.HightNodeEffect = nil
        end
        -- 重置按钮全局ZOrder
        if self.HightButton then       
            -- 恢复按钮点击回调
            --setCsbGlobalZOrder(self.HightButton, self.Z)

            -- 移动按钮
            if self.OldParent then
                CommonHelper.moveNode(self.HightButton, self.OldParent)
                self.OldParent:release()
                self.OldParent = nil
            end
            
            self.HightButton:setLocalZOrder(self.Z)
            
            if type(self.HightButton.isSwallowTouches) == "function" then
                self.HightButton:setSwallowTouches(self.BtnSwallow)
                self.HightButton:release()
            end
            self.HightButton = nil
        end
    end

    if GameEvents.EventButtonClick == self.stepConf.EndType then
        local btn = GuideUI.getUINode(self.stepConf.ButtonID)
        if btn then
            btn:removeClickEx()
        end
    end

    if self.Tip ~= nil then
        self.Tip:removeFromParent()
        self.Tip:release()
        self.Tip = nil
    end

    if 1 == self.stepConf.IsHideUI then
        if nil ~= self.HideUINode then
            self.HideUINode:setVisible(true)
            self.HideUINode:release()
            self.HideUINode = nil
        end
    elseif 2 == self.stepConf.IsHideUI then
        --显示技能UI
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            for i = 1, 3 do
                local skillBtn = CommonHelper.getChild(uiLayer, "Fight/MainPanel/SkillButton_" .. i)
                if skillBtn then
                    skillBtn:setVisible(true)
                end
            end
        end
    elseif 3 == self.stepConf.IsHideUI then
        -- 显示下方的战斗UI
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            local downPanel = CommonHelper.getChild(uiLayer, "Fight/MainPanel/DownPanel")
            if downPanel then
                downPanel:setVisible(true)
            end
        end
    end

    if self.Layer then
        self.Layer:removeChildByName("Dialog")
        if GuideStep.EndType.GSET_TOUCH == self.stepConf.EndType then
            self.Layer:unregisterScriptHandler()
            self.Layer:setTouchEnabled(false)
        end
        self.Layer:release()
        self.Layer = nil
    end

    if self.TouchLayer then
        self.TouchLayer:removeFromParent()
        self.TouchLayer:release()
        self.TouchLayer = nil
    end

    if 1 == self.stepConf.IsPause
      or 2 == self.stepConf.IsPause then
        resumeBattle()
    end
end

-- 播放音效
function GuideStep:playSoundEffect()
    if self.stepConf.StepSoundId and self.stepConf.StepSoundId > 0 then
        -- 延迟播放
        if self.stepConf.SoundDelayTime > 0 then
            if self.delaySoundSchedule then
                return
            end

            local delayCallback = function()
                local soundId = MusicManager.playGuideSound(self.stepConf.StepSoundId)
                -- 当前步骤结束是否关闭
                if self.stepConf.IsStepCloseSound then
                    self.stepEndCloseSoundId = soundId
                end

                Scheduler.unscheduleGlobal(self.delaySoundSchedule)
                self.delaySoundSchedule = nil
            end
           
            self.delaySoundSchedule = Scheduler.scheduleGlobal(delayCallback, 
                self.stepConf.SoundDelayTime * 0.001)
        else
            local soundId = MusicManager.playGuideSound(self.stepConf.StepSoundId)
            -- 当前步骤结束是否关闭
            if self.stepConf.IsStepCloseSound then
                self.stepEndCloseSoundId = soundId
            end
        end
    end
end

return GuideStep