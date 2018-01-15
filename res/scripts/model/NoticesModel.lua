local NoticesModel = class("NoticesModel")
local noticesKey = "NOTICES_CHAT_"
local maxNoticeCount = 20
local UserDefault = cc.UserDefault:getInstance()

local NoticeId = 
{
    NOTICE_SYSTEM_CHAMPIONSHIP_START = 1,   -- 锦标赛开始

    NOTICE_UNION_NEWMEMBER = 2,             -- 新成员加入
    NOTICE_UNION_QUIT = 3,                  -- 成员退出
    NOTICE_UNION_APPOINT = 4,               -- 任命
    NOTICE_UNION_TRASFER = 5,               -- 转职
    NOTICE_UNION_NOTICEUPDATE = 6,          -- 公会更新
    NOTICE_UNION_EXPIDITION_SET = 7,        -- 远征设置
    NOTICE_UNION_EXPIDITION_START = 8,      -- 远征开始
    NOTICE_UNION_EXPIDITION_SUCCESS = 9,    -- 远征胜利
    NOTICE_UNION_EXPIDITION_FAIL = 10,      -- 远征失败
    NOTICE_UNION_EXPIDITION_AWARD = 11,     -- 远征奖励

    NOTICE_USER_DRAWCARD_PURPLE = 12,       -- 抽卡获得紫卡
    NOTICE_USER_DRAWCARD_GOLD = 13,         -- 抽卡获得金卡
    NOTICE_USER_FORGE_PURPLE = 14,          -- 打造装备紫装
    NOTICE_USER_FORGE_GOLD = 15,            -- 打造装备金装
}

function NoticesModel:ctor()
end

function NoticesModel:init()
    self.allNotices = {}
    self.index = 0
    for i = 1, maxNoticeCount do
        local notice = UserDefault:getStringForKey(getGameModel():getUserModel():getUserID()..noticesKey .. i, "")
        if "" == notice then
            break
        end

        local messageInfo = self:getNoticeMessage(self:getParamInfo(notice))
        if messageInfo then
            self.index = self.index + 1
            table.insert(self.allNotices, messageInfo)
        end
    end

    if self.index > 0 then
        table.sort(self.allNotices, function(a, b)
            return a.sendTime < b.sendTime
        end)
    end
end

function NoticesModel:getAllNotices()
    return self.allNotices
end

-- noticeId+sendTime+paramcount+param1+param2...
function NoticesModel:toString(noticeId, paramInfo)
    local str = noticeId.."+"..paramInfo.sendTime

    if paramInfo.param then
        str = str.."+"..(#paramInfo.param)
        for _, v in pairs(paramInfo.param) do
            str = str.."+"..v
        end
    else
        str = str.."+0"
    end

    return str
end

function NoticesModel:getParamInfo(str)
    local info = string.split(str, "+")
    if #info < 3 then
        print("getParamInfo fail, param count < 3")
        return
    end

    local paramInfo = {}
    paramInfo.noticeId = tonumber(info[1])
    paramInfo.sendTime = tonumber(info[2])
    paramInfo.param = {}
    local count = info[3]
    for i = 1, count do
        table.insert(paramInfo.param, info[i + 3])
    end

    return paramInfo
end

function NoticesModel:addNotice(noticeId, param)
    self.index = self.index + 1
    if self.index > maxNoticeCount then
        self.index = self.index % maxNoticeCount
    end

    local paramInfo = {}
    paramInfo.noticeId = noticeId
    paramInfo.sendTime = getGameModel():getNow()
    paramInfo.param = param

    -- 存本地上
--    UserDefault:setStringForKey(getGameModel():getUserModel():getUserID()..noticesKey .. self.index, 
--        self:toString(noticeId, paramInfo))
--    UserDefault:flush()
    -- 发到聊天室
    local messageInfo = self:getNoticeMessage(paramInfo)
    if messageInfo then
        EventManager:raiseEvent(GameEvents.EventChatMessage, messageInfo)
        self.allNotices[self.index] = messageInfo

        -- 添加到跑马灯列表
        if 1 == messageInfo.highLight
          or 2 == messageInfo.highLight then
            MarqueeHelper.addMarquee(messageInfo)
        end
    end
end

function NoticesModel:getNoticeMessage(paramInfo)
    if not paramInfo then
        return
    end

    local noticeItem = getConfNoticeItem(paramInfo.noticeId)
    if not noticeItem then
        print("can't find noticeid:"..paramInfo.noticeId)
        return
    end

    local noticeLan = getNoticeLanConfItem(noticeItem.Content)
    if not noticeLan then
        return
    end

    local content = self:getNoticeContent(noticeLan.Content or "", paramInfo)
    local highContent = self:getNoticeContent(noticeLan.Content2 or "", paramInfo)
    local chatContent = self:getNoticeContent(noticeLan.Content3 or "", paramInfo)

    local messageInfo = {}
    if 1 == noticeItem.Type then -- 系统通知
        messageInfo.chatMode = 3

    elseif 2 == noticeItem.Type then -- GM通知
        messageInfo.chatMode = 4

    elseif 3 == noticeItem.Type then -- 公会通知
        messageInfo.chatMode = 5

    elseif 4 == noticeItem.Type then -- 玩家通知
        messageInfo.chatMode = 6
    else
        return
    end

    messageInfo.sendTime = paramInfo.sendTime
    messageInfo.chatRoom = noticeItem.Chatroom
    messageInfo.chatHead = noticeItem.Chathead
    messageInfo.highLight = noticeItem.Highlight
    messageInfo.content = content
    messageInfo.highContent = highContent
    messageInfo.chatContent = chatContent

    return messageInfo
end

-- 返回通知内容和跑马灯内容
function NoticesModel:getNoticeContent(content, paramInfo)
    local function getContentText(str, param)
        if not str or str == "" then
            return ""
        end

        if #param == 1 then
            str = string.format(str, param[1])

        elseif #param == 2 then
            str = string.format(str, param[1], param[2])
        end

        return str
    end

    local contentParam = {}
    if paramInfo.param then
        if #paramInfo.param == 1 then
            contentParam[1] = paramInfo.param[1]

        elseif #paramInfo.param == 2 then
            contentParam[1] = paramInfo.param[1]
            contentParam[2] = paramInfo.param[2]
            if paramInfo.noticeId == 14 or paramInfo.noticeId == 15 then
                local itemConf = getPropConfItem(tonumber(paramInfo.param[2]))
                if itemConf then
                    contentParam[2] = CommonHelper.getPropString(itemConf.Name)
                else
                    contentParam[2] = "unKnowItem"
                end
            end

        elseif #paramInfo.param == 3 then
            contentParam[1] = paramInfo.param[1]
            if paramInfo.noticeId == 12 or paramInfo.noticeId == 13 then
                local heroConf = getSoldierConfItem(paramInfo.param[2], paramInfo.param[3])
                if heroConf then
                    contentParam[2] = CommonHelper.getHSString(heroConf.Common.Name)
                else
                    contentParam[2] = "unKnowHero"
                end
            end
        end

        content = getContentText(content, contentParam)
    end

    return content
end

return NoticesModel