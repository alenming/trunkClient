--[[
聊天录音节点
1、录音时间设置超时自动关闭
]]

local Scheduler = require("framework.scheduler")
local ChatRecord = class("ChatRecord", function()
    return cc.Node:create()
end)

function ChatRecord:ctor()
    self.recordVoice = getResManager():cloneCsbNode(ResConfig.Common.Csb2.record)
    self.recordVoiceAct = cc.CSLoader:createTimeline(ResConfig.Common.Csb2.record)
    self.recordVoice:runAction(self.recordVoiceAct)
    self.recordVoice:setVisible(false)
    self:addChild(self.recordVoice, 5)

    CommonHelper.layoutNode(self.recordVoice)

    self.startTimeStamp = 0                -- 开始录音时间戳
    self.limitRecordTime = 10              -- 限制录音时长
    self.isCancelRecord = false            -- 是否取消录音
    self.isRecord = false                  -- 是否在录音
end

function ChatRecord:startRecordVoice()
    ChatHelper.startRecordVoice()
    self.startTimeStamp = os.time()
    self.isCancelRecord = false
    self.isRecord = true
    self.schedulerHandler = Scheduler.scheduleGlobal(handler(self, self.recordTimeCall), 1)

    self.recordVoice:setVisible(true)
    self.recordVoiceAct:play("Loading", false)
end

function ChatRecord:stopRecordVoice()
    if not self.isCancelRecord and self.isRecord then
        ChatHelper.stopRecordVoice()
        self:stopRecordSchedule()

        if os.time() == self.startTimeStamp then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1996))
        end
    end
    
    self.isRecord = false
    self.recordVoice:setVisible(false)
end

function ChatRecord:cancelRecordVoice()
    ChatHelper.cancelRecordVoice()
    self.isCancelRecord = true
    self.isRecord = false
    self:stopRecordSchedule()
    
    self.recordVoiceAct:play("Cancel", false)
end

function ChatRecord:recordTimeCall(dt)
    if os.time() - self.startTimeStamp > self.limitRecordTime then
        self:stopRecordVoice()
    end
end

function ChatRecord:stopRecordSchedule()
    if self.schedulerHandler then
        Scheduler.unscheduleGlobal(self.schedulerHandler)
        self.schedulerHandler = nil
    end
end

return ChatRecord