--[[
聊天辅助工具
1、全局监听聊天的信息
2、筛选聊天(屏蔽某些等级的玩家等功能)
3、将显示道具、英雄的功能解析成自定义的标签的富文本
4、解析富文本 x
]]

ChatHelper = {}

local scheduler = require("framework.scheduler")
local DEFAULT_FONT = "ui_new/f_font/CN/font_dym/FZcyj.TTF"
local LINE_FEED_LEN = 45

ChatHelper.ChatMode = {WORLD = 1, UNION = 2, SYSTEM = 3, GM_NOTICE = 4, UNION_NOTICE = 5, USER_NOTICE = 6,
    BATTLE_UNIONSHARE = 7}
ChatHelper.ChatMessageType = {TEXT = 1, AUDIO = 2, IMAGE = 3}
ChatHelper.ChatLook = {HERO = 1, EQUIP = 2}

local ChatColor = {WORLD = "24e100", UNION = "f9f92d", NAME = "2ae2fd", SYSTEM = "bb5100"}
local ChatUserData = {ChatLvLimit = "CHAT_LV_LIMIT", ChatMode = "CHAT_MODE"
    , ChatCount = "CHAT_COUNT", ChatResetStamp = "CHAT_RESET_STAMP", ChatSpeakStamp = "CHAT_SPEAK_STAMP"}
local UILanguage = {unlockTips = 431, wordLimitTips = 433, connectTips = 2122,
    textEmptyTips = 432, speakSoonTips = 434, speakLimitTips = 435}

-- 聊天内容 1为世界聊天 2为公会聊天
ChatHelper.AllChat = {{}, {}}
ChatHelper.ChatInfo = {}
ChatHelper.CacheLookInfo = {}

local serverId = 0
local alreadyJoin = false
local downButtonCsb = "ui_new/g_gamehall/c_chat/ChatItem/Chat_DownButton.csb"

function ChatHelper.init()
    -- 聊天服务器连接成功
    EventManager:addEventListener(GameEvents.EventChatConnect, ChatHelper.onEventChatConnect)
    -- 监听聊天事件
    EventManager:addEventListener(GameEvents.EventChatMessage, ChatHelper.onEventChatMessage)
    -- 监听服务器断开
    EventManager:addEventListener(GameEvents.EventChatDisconnect, ChatHelper.onEventChatDisconnect)
    -- 监听点击查看聊天物品
    EventManager:addEventListener(GameEvents.EventChatClickLook, ChatHelper.onChatLookCall)

    local cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginChatSC)
    NetHelper.setResponeHandler(cmd, ChatHelper.onLoginChat)

    ChatHelper.ChatInfo.limitLv = UserDatas.getIntegerForKey(ChatUserData.ChatLvLimit, 1)
    ChatHelper.ChatInfo.chatCount = UserDatas.getIntegerForKey(ChatUserData.ChatCount, 0)
    ChatHelper.ChatInfo.resetStamp = UserDatas.getIntegerForKey(ChatUserData.ChatResetStamp, 0)
    ChatHelper.ChatInfo.chatMode = UserDatas.getIntegerForKey(ChatUserData.ChatMode, 11)
    ChatHelper.ChatInfo.speakStamp = UserDatas.getIntegerForKey(ChatUserData.ChatSpeakStamp, 0)
    
    serverId = cc.UserDefault:getInstance():getIntegerForKey("ServerId")
end

-- 连接聊天服务器
function ChatHelper.connectToChatServer()
    print("send to chat server", PlatformModel.host, PlatformModel.port - 1)
    --connectToServer(PlatformModel.host, PlatformModel.port - 1, 1, ipv and ipv or 1) 
    --connectToServer(PlatformModel.host,5562, 1, ipv and ipv or 1) 
end

function ChatHelper.onLoginChat(mainCmd, subCmd, data)
    local uid = data:readInt()

    -- 验证成功加入相应的房间
    if not alreadyJoin then
        alreadyJoin = true
        -- 加入世界聊天室
        ChatHelper.joinRoom(ChatHelper.ChatMode.WORLD, 1)
        -- 如果有公会,加入公会聊天室
        if getGameModel():getUnionModel():getHasUnion() then
            ChatHelper.joinRoom(ChatHelper.ChatMode.UNION, getGameModel():getUnionModel():getUnionID())
        else
            local preUnion = UserDatas.getIntegerForKey("PRE_UNION", 0)
            if preUnion > 0 then
                ChatHelper.quitRoom(ChatHelper.ChatMode.UNION, preUnion)
            end
        end
    end
end

function ChatHelper.toHtmlCode(text, format)
    local htmlText = text
    if format and format.color then
        htmlText = "<font face='"..DEFAULT_FONT.."' color = '"..format.color.."'>"..htmlText.."</font>"
    else
        htmlText = "<font face='"..DEFAULT_FONT.."'>"..htmlText.."</font>"
    end

    return htmlText
end

-- [世界]姓名 内容
function ChatHelper.toFormatCode(chatInfo)
    local chatModeLang = 0
    local chatModeColor = ""
    if chatInfo.chatMode == ChatHelper.ChatMode.WORLD then
        chatModeColor = ChatColor.WORLD
        chatModeLang = CommonHelper.getUIString(436)
    elseif chatInfo.chatMode == ChatHelper.ChatMode.UNION then
        chatModeColor = ChatColor.UNION
        chatModeLang = CommonHelper.getUIString(1352)
    else
        chatModeColor = ChatColor.SYSTEM
        chatModeLang = CommonHelper.getUIString(2059)
    end

    local mode = "<font color='"..chatModeColor.."'>["..chatModeLang.."]</font>"
    local buleDiamondImg = ""
    -- 蓝钻等级*10+蓝钻类型
    if gIsQQHall then
        if type(chatInfo.extend) == "number" and chatInfo.extend > 0 then
            local blueLv = math.floor(chatInfo.extend / 10)
            local blueType = math.floor(chatInfo.extend % 10)

            buleDiamondImg = "<img src='bluediamond_s"..blueLv..".png' />"
            -- 3是年费蓝钻7是豪华版年费蓝钻
            if blueType == 3 or blueType == 7 then
                buleDiamondImg = buleDiamondImg .. "<img src='year_vip_s.png' />"
            else
                buleDiamondImg = buleDiamondImg .. "<img src='Vip_Alpha.png' />"
            end
        elseif (chatInfo.chatMode == ChatHelper.ChatMode.WORLD
            or chatInfo.chatMode == ChatHelper.ChatMode.UNION) then
            buleDiamondImg = "<img src='Vip_Alpha.png' /><img src='Vip_Alpha.png' />"
        end
    end

    local name = ""
    if chatInfo.name then
        name = "<font color='"..ChatColor.NAME.."'>"..chatInfo.name.."：</font>"
    end
    local content = chatInfo.content
    local chat = "<font face='"..DEFAULT_FONT.."'>"..mode..buleDiamondImg..name..content.."</font>"

    return chat
end

local function splitLookInfo(str)
    if type(str) ~= "string" then
        return
    end

    local split = string.split(str, "+")
    if #split == 3 then
        return {lookType = tonumber(split[1]), uid = tonumber(split[2]), itemId = tonumber(split[3])}
    end
end

local function jointLookInfo(type, uid, itemId)
    if not type or not uid or not itemId then
        return ""
    end

    return type.."+"..uid.."+"..itemId
end

function ChatHelper.analysisChatContent(content, uid)
    local analysisContent = content
    
    local t, _ = string.find(analysisContent, "%]")
    if not t then
        return analysisContent
    end
    
    -- 1、解析表情
    local i, j = string.find(analysisContent, "%[#")
    if i and j then
        local p, _ = string.find(analysisContent, "%]", j)
        if not p then
            return analysisContent
        end

        local id = string.sub(analysisContent, j + 1, p - 1)
        local expression = getExpressionSetting()[tonumber(id)]
        if not expression then
            return analysisContent
        end

        analysisContent = ChatHelper.analysisChatContent(string.sub(analysisContent, 1, i - 1), uid)..
            "<CSB path = '"..expression.Expression_Res.."'width='56' height='56' scale='0.5' ANIMATION='animation0' />" .. 
            ChatHelper.analysisChatContent(string.sub(analysisContent, p + 1), uid)
        return analysisContent
    end

    -- 2、解析英雄
    i, j = string.find(analysisContent, "%[H")
    if i and j then
        local p, _ = string.find(analysisContent, "%]", j)
        if not p then
            return analysisContent
        end

        -- 英雄品质和星级无关,都取一星
        local id = tonumber(string.sub(analysisContent, j + 1, p - 1))
        local analysic = ""
        local soldierConf = getSoldierConfItem(id, 1)
        if not soldierConf then
            analysic = string.sub(analysisContent, i, p)
        else
            -- 获取品质对应的文本颜色
            local color = getItemLevelSettingItem(soldierConf.Rare).ChatColor
            color = CommonHelper.c3bToHex(color[1], color[2], color[3])

            analysic = "<font click='"..jointLookInfo(ChatHelper.ChatLook.HERO, uid, id).."' color ='"..color.."' outline='4A2E20&1'>["..
                CommonHelper.getHSString(soldierConf.Common.Name).."]</font>"
        end

        analysisContent = ChatHelper.analysisChatContent(string.sub(analysisContent, 1, i - 1), uid)..
            analysic..
            ChatHelper.analysisChatContent(string.sub(analysisContent, p + 1), uid)
        return analysisContent
    end

    -- 3、解析装备
    i, j = string.find(analysisContent, "%[E")
    if i and j then
        -- 装备动态id
        local d, _ = string.find(analysisContent, "D", j)
        if not d then
            return analysisContent
        end

        local p, _ = string.find(analysisContent, "%]", d)
        if not p then
            return analysisContent
        end

        local configID = tonumber(string.sub(analysisContent, j + 1, d - 1))
        local dynEquipID = tonumber(string.sub(analysisContent, d + 1, p - 1))
        local analysic = ""
        local propConf = getPropConfItem(configID)
        if not propConf or propConf.Type ~= 1 then
            analysic = string.sub(analysisContent, i, p)
        else
            -- 获取品质对应的文本颜色
            local color = getItemLevelSettingItem(propConf.Quality).ChatColor
            color = CommonHelper.c3bToHex(color[1], color[2], color[3])

            analysic = "<font click='"..jointLookInfo(ChatHelper.ChatLook.EQUIP, uid, dynEquipID).."' color ='"..color.."' outline='4A2E20&1'>["..
                CommonHelper.getPropString(propConf.Name).."]</font>"
        end

        analysisContent = ChatHelper.analysisChatContent(string.sub(analysisContent, 1, i - 1), uid)..
            analysic..
            ChatHelper.analysisChatContent(string.sub(analysisContent, p + 1), uid)
        return analysisContent
    end

    return analysisContent
end

-- 发送聊天消息
function ChatHelper.sendChatMessage(conversation)
    if not conversation.chatMode
      or not conversation.chatMessageType then
        print("sendChatMessage param error!!")
        return
    end
    
    local userModel = getGameModel():getUserModel()

    conversation.sendUid = conversation.sendUid or userModel:getUserID()
    conversation.lv = conversation.lv or userModel:getUserLevel()
    conversation.headId = conversation.headId or userModel:getHeadID()
    conversation.name = conversation.name or userModel:getUserName()
    conversation.extend = conversation.extend 
        or (userModel:getBDType() > 0 and (userModel:getBDLv() * 10 + userModel:getBDType()) or 0)

    conversation.targetId = conversation.targetId or 0
    if conversation.chatMode == ChatHelper.ChatMode.UNION then
        conversation.targetId = getGameModel():getUnionModel():getUnionID()
    end
    
    conversation.content = conversation.content or ""

    local buffData = NetHelper.createBufferData(MainProtocol.Chat, ChatProtocol.SendMessageCS)
    buffData:writeChar(conversation.headId)
    buffData:writeChar(conversation.chatMode)
    buffData:writeChar(conversation.lv)
    buffData:writeChar(conversation.chatMessageType)
    buffData:writeInt(conversation.sendUid)
    buffData:writeInt(0)
    buffData:writeInt(conversation.targetId)
    buffData:writeInt(conversation.extend)
    buffData:writeCharArray(conversation.name, 20)
    buffData:writeCharArray(conversation.content, 128)
    -- 注意第二个参数1为发送聊天服务器
    NetHelper.request(buffData, 1)

    -- 保存发言信息
    ChatHelper.ChatInfo.chatCount = ChatHelper.ChatInfo.chatCount + 1
    ChatHelper.ChatInfo.speakStamp = getGameModel():getNow()

    UserDatas.setIntegerForKey(ChatUserData.ChatSpeakStamp, ChatHelper.ChatInfo.speakStamp)
    UserDatas.setIntegerForKey(ChatUserData.ChatCount, ChatHelper.ChatInfo.chatCount)
end

-- 开始录制语音
function ChatHelper.startRecordVoice()
    if getGameModel():getUnionModel():getHasUnion() then
        return
    end

    MusicManager.stopBgMusic()

    -- 发送语音的信息
    local conversation = {}
    conversation.sendUid = userModel:getUserID()
    conversation.lv = userModel:getUserLevel()
    conversation.headId = userModel:getHeadID()
    conversation.name = userModel:getUserName()
    conversation.chatMessageType = ChatHelper.ChatMessageType.AUDIO
    conversation.chatMode = ChatHelper.ChatMode.UNION -- 语音只有公会需要
    conversation.targetId = getGameModel():getUnionModel():getUnionID()    
    conversation.extend = 0
    conversation.content = ""

    --chatManager:startRecordVoice(conversation)
end

-- 停止录制语音
function ChatHelper.stopRecordVoice()
    --chatManager:stopRecordVoice()
    MusicManager.playCurBgMusic()
end

-- 取消录制语音
function ChatHelper.cancelRecordVoice()
    --chatManager:cancelRecordVoice()
    MusicManager.playCurBgMusic()
end

-- 语音播放
function ChatHelper.getVoice(messageid)
    --return chatManager:getVoice(messageid)
end

function ChatHelper.getNewMessages(uid, lastTime)
    local messages = {}
    
    for mode, modeChats in pairs(ChatHelper.AllChat) do
        for _, v in pairs(modeChats) do
            -- 高于限制等级并且大于最后的一条信息id或者是自己发送的
            if (v.lv >= ChatHelper.ChatInfo.limitLv and v.sendTime > lastTime)
                or (uid == v.sendUid and v.sendTime > lastTime) then
                    table.insert(messages, v)
            end
        end
    end

    -- 通知类信息
    local notices = getGameModel():getNoticesModel():getAllNotices()
    for _, noticeInfo in pairs(notices) do
        if noticeInfo.sendTime > lastTime then
            table.insert(messages, noticeInfo)
        end
    end

    -- 比较时间戳
    local function sortMessage(a, b)
        return a.sendTime < b.sendTime
    end

    if #messages > 0 then
        table.sort(messages, sortMessage)
    end

    return messages
end

-- 聊天服务器连接成功监听
function ChatHelper.onEventChatConnect(eventName, connectionStatus)
    print("onEventChatConnect connectionStatus", connectionStatus)
    ChatHelper.connectionStatus = connectionStatus
    if 0 == connectionStatus then
        return
    end
    
    -- 移除重连计时
    if ChatHelper.updateFunc then
        scheduler.unscheduleGlobal(ChatHelper.updateFunc)
        ChatHelper.updateFunc = nil
    end

    ChatHelper.isConnecting = false
    -- 登录聊天服务器
    local buffData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginChatCS)
    buffData:writeInt(getGameModel():getUserModel():getUserID()) 
    NetHelper.request(buffData, 1)
end

-- 监听到聊天服务器断线
function ChatHelper.onEventChatDisconnect(eventName)
   -- print("chat server disconnect!!!")   
    if not ChatHelper.isConnecting then
        ChatHelper.updateFunc = scheduler.scheduleGlobal(function(dt) 
            --print("重连chat server ing")
            reconnectToServer(1)
        end, 0.5)
    end

    ChatHelper.isConnecting = true
end

-- 聊天监听消息
function ChatHelper.onEventChatMessage(eventName, MessageInfo)
    if ChatHelper.AllChat[MessageInfo.chatMode] then
        table.insert(ChatHelper.AllChat[MessageInfo.chatMode], MessageInfo)
    end
end

-- 判断是否能够发送
function ChatHelper.canSendMessage(text)
    -- 服务器没连上...
    if nil == ChatHelper.connectionStatus or 0 == ChatHelper.connectionStatus then
        -- 如果不是在连接中,发送断开事件重连服务器
        if not ChatHelper.isConnecting then
            EventManager:raiseEvent(GameEvents.EventChatDisconnect)
        end
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.connectTips))
        return
    end

    local chatSetting = getChatSetting()
    if chatSetting.ChatUnlockLv > getGameModel():getUserModel():getUserLevel() then
        local unlockTips = string.format(CommonHelper.getUIString(UILanguage.unlockTips), chatSetting.ChatUnlockLv)
        CsbTools.addTipsToRunningScene(unlockTips)
        return false
    end

    if text then
        if 0 == string.len(text) then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.textEmptyTips))
            return false
        end

        if string.len(text) > chatSetting.WordNumLimit then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.wordLimitTips))
            return false
        end
    end

    local curTime = getGameModel():getNow()
    -- 判断发言间隔
    if ChatHelper.ChatInfo.speakStamp + chatSetting.IntervalTime > curTime then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.speakSoonTips))
        return false
    end

    -- 恢复次数
    if ChatHelper.ChatInfo.resetStamp <= 0 or ChatHelper.ChatInfo.resetStamp < curTime then
        ChatHelper.ChatInfo.resetStamp = getNextTimeStamp(curTime, chatSetting.RecoverTime[2], chatSetting.RecoverTime[1])
        ChatHelper.ChatInfo.chatCount = 0
        UserDatas.setIntegerForKey(ChatUserData.ChatResetStamp, ChatHelper.ChatInfo.resetStamp)
        UserDatas.setIntegerForKey(ChatUserData.ChatCount, ChatHelper.ChatInfo.chatCount)
    end

    -- 判断发言条数
    if ChatHelper.ChatInfo.chatCount >= chatSetting.SpeedTimesLimit then
        local tips = string.format(CommonHelper.getUIString(UILanguage.speakSoonTips), chatSetting.SpeedTimesLimit)
        CsbTools.addTipsToRunningScene(tips)
        return false
    end

    return true
end

-- 加入聊天房间
function ChatHelper.joinRoom(mode, roomId)
    print(mode, roomId)
    if mode ~= ChatHelper.ChatMode.UNION
      and mode ~= ChatHelper.ChatMode.WORLD then
        print(mode, roomId, ChatHelper.ChatMode.UNION, ChatHelper.ChatMode.WORLD)
        return
    end

    local buffData = NetHelper.createBufferData(MainProtocol.Chat, ChatProtocol.JoinRoomCS)
    buffData:writeChar(mode)
    buffData:writeInt(roomId)
    NetHelper.request(buffData, 1)
end

-- 退出聊天房间
function ChatHelper.quitRoom(mode, roomId)
    if ChatHelper.ChatMode.UNION == mode then
        local buffData = NetHelper.createBufferData(MainProtocol.Chat, ChatProtocol.QuitRoomCS)
        buffData:writeInt(roomId)
        NetHelper.request(buffData, 1)
    end
end

function ChatHelper.getChatMode()
    return ChatHelper.ChatInfo.chatMode
end

function ChatHelper.setChatMode(chatMode)
    UserDatas.setIntegerForKey(ChatUserData.ChatMode, chatMode)
    ChatHelper.ChatInfo.chatMode = chatMode
end

function ChatHelper.getLimitLv()
    return ChatHelper.ChatInfo.limitLv
end

function ChatHelper.setLimitLv(limitLv)
    UserDatas.setIntegerForKey(ChatUserData.ChatLvLimit, limitLv)
    ChatHelper.ChatInfo.limitLv = limitLv
end

-------------------------------查看英雄/装备相关----------------------------------------------
local function showEquipInfo(equipInfo)
    if UIManager.isTopUI(UIManager.UI.UIChat) then
        local uiView = UIManager.getUI(UIManager.UI.UIChat)
        if uiView then
            uiView:showEquipInfo(equipInfo)
        end
    end
end

function ChatHelper.addChatCacheInfo(lookType, uid, itemid, data)
    if not ChatHelper.CacheLookInfo[lookType] then
        ChatHelper.CacheLookInfo[lookType] = {}
    end

    if not ChatHelper.CacheLookInfo[lookType][uid] then
        ChatHelper.CacheLookInfo[lookType][uid] = {}
    end

    ChatHelper.CacheLookInfo[lookType][uid][itemid] = data
end

function ChatHelper.onChatLookCall(eventName, data)
    local lookInfo = splitLookInfo(data)
    if not lookInfo then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2171))
        return
    end

    if ChatHelper.ChatLook.HERO ~= lookInfo.lookType
      and ChatHelper.ChatLook.EQUIP ~= lookInfo.lookType then
        return
    end

    -- 1、如果查看的是自己的
    if lookInfo.uid == getGameModel():getUserModel():getUserID() then
        if ChatHelper.ChatLook.HERO == lookInfo.lookType then
            UIManager.open(UIManager.UI.UIHeroInfo, lookInfo.itemId)
        else
            local equipInfo = getGameModel():getEquipModel():getEquipInfo(lookInfo.itemId)
            showEquipInfo(equipInfo)
        end

        return
    end

    -- 2、如果是查看过的(暂时缓存装备)
    if ChatHelper.ChatLook.EQUIP == lookInfo.lookType then
        local cache = ChatHelper.CacheLookInfo[lookInfo.lookType]
        if cache and cache[lookInfo.uid] and cache[lookInfo.uid][lookInfo.itemId] then
            -- 有缓存的查看数据
            local cacheEquipInfo = cache[lookInfo.uid][lookInfo.itemId]
            if cacheEquipInfo then
                showEquipInfo(cacheEquipInfo)
                return
            end
        end
    end

    -- 3、发送查看
    if ChatHelper.ChatLook.HERO == lookInfo.lookType then
        local buffer = NetHelper.createBufferData(MainProtocol.Look, LookProtocol.LookHeroCS)
		buffer:writeInt(lookInfo.uid)
        buffer:writeInt(lookInfo.itemId)
		NetHelper.request(buffer)
    elseif ChatHelper.ChatLook.EQUIP == lookInfo.lookType then
        local buffer = NetHelper.createBufferData(MainProtocol.Look, LookProtocol.LookEquipCS)
		buffer:writeInt(lookInfo.uid)
        buffer:writeInt(lookInfo.itemId)
		NetHelper.request(buffer)
    end
end

return ChatHelper
