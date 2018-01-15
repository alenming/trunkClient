--[[
聊天室主界面
1、显示聊天信息(公会/世界)
2、播放语音聊天
]]

local UIChat = class("UIChat", function()
    return require("common.UIView").new()
end)

local ExpressionSViewExtend = require("common.ScrollViewExtend").new()
local HeroSViewExtend = require("common.ScrollViewExtend").new()
local UIEquipViewHelper = require("game.hero.UIEquipViewHelper")
local UILanguage = {joinUnionTips = 448, recordShort = 1996}
local MAX_CHAT = 100 -- 最多显示的聊天数
local VIEW_CONFIG = {topMargin = 5, padding = 15, noticeDVal = 25, shareHeight = 250}
local expressionItemSize = cc.size(56, 56)
local downButton = {"Expression", "Hero", "Equip", "Null"} 
local expressionType = {Expression = 1, Hero = 2, Equip = 3}
local downIconCsb = "ui_new/g_gamehall/c_chat/ChatItem/Chat_DownButtonIcon.csb"
local downButtonCsb = "ui_new/g_gamehall/c_chat/ChatItem/Chat_DownButton.csb"

function UIChat:ctor()

end

function UIChat:init()
    self.UICsb = ResConfig.UIChat.Csb2
    self.rootPath = self.UICsb.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
    self.root:runAction(self.rootAct)
    self:addChild(self.root)

    self.chats = {}
    self.voices = {}
    self.allChats = {}
    self.curAudio = 0
    -- 初始化UI
    self:initUI()
end

function UIChat:initUI()
    -- 输入框
    self.textField = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/TextField")
    self.textField:setMaxLength(getChatSetting().WordNumLimit)
    -- 敏感词屏蔽
    self.textField:addEventListener(function(ref, eventType)
        if eventType == 2 then
            local newStr = FilterSensitive.FilterStr(ref:getString())
            ref:setString(newStr)

            self.chatInputText = newStr
        end
    end)

    -- 返回按钮
    self.hideButton = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/HideButton")
    CsbTools.initButton(self.hideButton, function ()
        UIManager.close()
    end)
    
    -- 当前的表情
    self.curExpressionPanel = 0
    -- 显示表情
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/Button_Expression"), handler(self, self.showExpressionCallBack))
    -- 设置
    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/SettingButton"), function ()
        UIManager.open(UIManager.UI.UIChatSetting)
    end)

    -- 发送按钮
    local enterButton = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/Button_Enter")
    CsbTools.initButton(enterButton, handler(self, self.enterCallBack))
    if device.platform == "windows" then
        -- 回车发送
        local function keyboardPressed(keyCode, event)
            if keyCode == 35 or keyCode == 164 then
                self:enterCallBack(enterButton)
            end
        end

        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(keyboardPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
    end

    self:initTalkScrollView()
    self:initRecord()
    self:initDownPanel()
    self:initShowItemTip()
end

function UIChat:initTalkScrollView()
    -- 按钮关联view
    self.chatViewInfo = {TabButton_World = {viewName = "WorldScrollView", lang = 436, record = 0, mode = ChatHelper.ChatMode.WORLD}
                    , TabButton_Guild = {viewName = "GuildScrollView", lang = 1352, record = 1, mode = ChatHelper.ChatMode.UNION}}
    self.chatViewObjInfo = {}
    self.modeZorder = 0
    for k, v in pairs(self.chatViewInfo) do
        -- view
        local view = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/"..v.viewName)
        view:setScrollBarEnabled(false)
        view:removeAllChildren()
        -- button
        local button = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/"..k)
        CsbTools.initButton(button, handler(self, self.changeChatCallBack)
            , CommonHelper.getUIString(v.lang), "Chat_TabButton/TabButton/NameText", "Chat_TabButton")
        button:setTag(v.mode)

        self.chatViewObjInfo[v.mode] = {}
        self.chatViewObjInfo[v.mode].view = view
        self.chatViewObjInfo[v.mode].viewSize = view:getContentSize()
        self.chatViewObjInfo[v.mode].button = button

        if self.modeZorder <= 0 then
            self.modeZorder = button:getLocalZOrder()
        end
    end

    self.lastMessageTime = 0
end

function UIChat:initRecord()
    self.recordChatButton = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/Button_Chat")
    self.recordChatButton:setVisible(false)
    self.recordChatButton:addTouchEventListener(handler(self, self.touchRecordCallBack))
    -- 显示录音
    self.recordVoice = (require "game.chat.ChatRecord").new()
    self.recordVoice:setPosition(cc.p(display.cx, display.cy))
    self:addChild(self.recordVoice)
end

function UIChat:initDownPanel()
    self.downPanel = CsbTools.getChildFromPath(self.root, "MainPanel/ChatPanel/DownCut/DownPanel")
    self.downButtonAct = {}
    for i = 1, #downButton do
        local downBtn = CsbTools.getChildFromPath(self.downPanel, "DownButton_"..i)
        downBtn:setTag(i)
        
        if "Null" ~= downButton[i] then
            CommonHelper.playCsbAnimate(downBtn, downIconCsb, downButton[i], false)
            self.downButtonAct[i] = cc.CSLoader:createTimeline(downButtonCsb)
            downBtn:runAction(self.downButtonAct[i])

            if "Expression" == downButton[i] then
                self:initExpressionScrollView()
            elseif "Hero" == downButton[i] then
                self:initHeroScrollView()
            end
        else
            downBtn:setVisible(false)
        end
        
        CsbTools.initButton(downBtn, handler(self, self.downButtonCallBack), "", nil, "DownButton")
    end
end

function UIChat:initShowItemTip()
    self.eqInfoCsb = getResManager():getCsbNode(self.UICsb.eqInfo)
    CommonHelper.layoutNode(self.eqInfoCsb)
    self:addChild(self.eqInfoCsb)
    self.eqInfoCsb:setVisible(false)

    -- 位置固定在隐藏按钮旁边
    local x, y = self.hideButton:getPosition()
    self.eqInfoCsb:setPosition(cc.p(x - 190, y - 50))

    -- 隐藏多余按钮
    self.effectBtnCsb = CsbTools.getChildFromPath(self.eqInfoCsb, "FileNode_2")
	local closeEquipBtn = CsbTools.getChildFromPath(self.effectBtnCsb, "WearButton")
    CsbTools.getChildFromPath(closeEquipBtn, "ButtonName"):setString(CommonHelper.getUIString(2172))
    closeEquipBtn:addClickEventListener(function (obj)
        self.eqInfoCsb:setVisible(false)
    end)
	CsbTools.getChildFromPath(self.effectBtnCsb, "ChangeButton"):setVisible(false)

    self.effectBtnCsb:setPositionX(self.effectBtnCsb:getPositionX() + closeEquipBtn:getContentSize().width/2 + 12)
    self.equipInfoCsb = CsbTools.getChildFromPath(self.eqInfoCsb, "EqInfoPanel/EquipInfo")
end

function UIChat:initExpressionScrollView()
    -- 表情拖动视图
    self.expressionScrollView = CsbTools.getChildFromPath(self.downPanel, "DownScrollView1")
    self.expressionScrollView:removeAllChildren()

    local function getExpressionCsbs()
        local expressonCsbs = {}
        for _, v in ipairs(getExpressionSetting() or {}) do
            table.insert(expressonCsbs, v.Expression_Res)
        end

        return expressonCsbs
    end

    local allExpressionCSB = getExpressionCsbs()
    local tabParam = 
    {
        rowCellCount    = 2,                  -- 每行节点个数
        defaultCount    = 18,                 -- 初始节点个数
        maxCellCount    = #allExpressionCSB,  -- 最大节点个数
        csbFiles        = allExpressionCSB,   -- 所有表情csb
        csbAnimateName  = "animation0",       -- 动画标签
        loopAnimate     = true,               -- 是否循环
        isBarEnabled    = true,               -- 拖动条是否激活
        cellSize        = expressionItemSize, -- 节点触摸层的大小
        uiScrollView    = self.expressionScrollView,          -- 滚动区域
        distanceX       = 3,                  -- 节点X轴间距
        distanceY       = 1,                  -- 节点Y轴间距
        offsetX         = 2,                  -- 第一列的偏移
        offsetY         = 10,                 -- 第一行的偏移
        setCellDataCallback = function(node, i) self:setExpressionItemData(node, i) end,          -- 设置节点数据回调函数
    }
    ExpressionSViewExtend:init(tabParam)
    ExpressionSViewExtend:create()
    ExpressionSViewExtend:reloadData()
end

function UIChat:initHeroScrollView()
    local csb = getResManager():getCsbNode(self.UICsb.item)
    local itemSize = CsbTools.getChildFromPath(csb, "HeroImage"):getContentSize()
    csb:cleanup()
    
    self.heros = {}
    -- 英雄拖动视图
    self.heroScrollView = CsbTools.getChildFromPath(self.downPanel, "DownScrollView2")
    self.heroScrollView:removeAllChildren()
    
    local tabParam = 
    {
        rowCellCount    = 2,                   -- 每行节点个数
        defaultCount    = 18,                  -- 初始节点个数
        maxCellCount    = #getSoldierUpRateItemList(),  -- 最大节点个数
        csbName         = self.UICsb.item,     -- 节点的CSB名称
        cellName        = "HeroImage",         -- 节点触摸层的名称
        cellSize        = itemSize,            -- 节点触摸层的大小
        isBarEnabled    = true,                -- 拖动条是否激活
        cellScale       = 0.8,                 -- 节点缩放比例
        uiScrollView    = self.heroScrollView, -- 滚动区域
        distanceX       = 5,                   -- 节点X轴间距
        distanceY       = 5,                   -- 节点Y轴间距
        offsetX         = 2,                   -- 第一列的偏移
        offsetY         = 8,                   -- 第一行的偏移
        setCellDataCallback = function(node, i) self:setHeroItemData(node, i) end,          -- 设置节点数据回调函数
    }
    HeroSViewExtend:init(tabParam)
    HeroSViewExtend:create()
end

function UIChat:setExpressionItemData(itemCsb, i)
    itemCsb:setTag(i)
    local csbX, csbY = itemCsb:getPosition()
    itemCsb:setPosition(cc.p(csbX - expressionItemSize.width/2, csbY - expressionItemSize.height/2))

    -- 自己添加一个触摸,方便美术
    local layer = itemCsb:getChildByName("TouchLayer")
    if not layer then
        layer = ccui.Layout:create()
        layer:setName("TouchLayer")
        layer:setContentSize(expressionItemSize.width, expressionItemSize.height)
        layer:setTouchEnabled(true)
        layer:setSwallowTouches(false)
        itemCsb:addChild(layer)
    end

    layer:setTag(i)
    -- 添加点击监听
	layer:addTouchEventListener(function(obj, event)
	    if event == 2 then
            local beginPos = obj:getTouchBeganPosition()
            local endPos = obj:getTouchEndPosition()
            if cc.pGetDistance(beginPos, endPos) > 40 then
                return
            end

            -- 点击的表情对应标签输入到输入框
            self:appendTextField(expressionType.Expression, obj:getTag())
	    end
	end)
end

function UIChat:setHeroItemData(itemCsb, i)
    itemCsb:setTag(i)
    local node = CsbTools.getChildFromPath(itemCsb, "HeroImage")
    self:setHeroIconNode(itemCsb, i)
    node:setTag(i)
    node:setTouchEnabled(true)
    node:setSwallowTouches(false)
    -- 添加点击监听
	node:addTouchEventListener(function(obj, event)
	    if event == 2 then
            local beginPos = obj:getTouchBeganPosition()
            local endPos = obj:getTouchEndPosition()
            if cc.pGetDistance(beginPos, endPos) > 40 then
                return
            end
            
            -- 点击的英雄对应标签输入到输入框
            self:appendTextField(expressionType.Hero, obj:getTag())
	    end
	end)
end

function UIChat:onOpen(fromUI, ...)
    local chatMode = ChatHelper.ChatMode.WORLD
    if UIManager.UI.UIHall == fromUI then
        chatMode = ChatHelper.ChatMode.WORLD
    elseif UIManager.UI.UIUnion == fromUI then
        chatMode = ChatHelper.ChatMode.UNION
    end

    self:changeChatPanel(self.chatViewObjInfo[chatMode].button)
    -- 监听聊天事件
    self.onEventChatHanlder = handler(self, self.onEventChat)
    EventManager:addEventListener(GameEvents.EventChatMessage, self.onEventChatHanlder)
    -- 监听查看装备消息
    local lookEquipCmd = NetHelper.makeCommand(MainProtocol.Look, LookProtocol.LookEquipSC)
    self.lookEquipHandler = handler(self, self.acceptLookEquipInfo)
    NetHelper.addResponeHandler(lookEquipCmd, self.lookEquipHandler)

    self.isShowExpression = false
    self.chatInputText = ""
    self.textField:setString("")

    -- 获取新的聊天信息
    self.userId = getGameModel():getUserModel():getUserID()
    local newMessage = ChatHelper.getNewMessages(self.userId, self.lastMessageTime)
    for _, v in pairs(newMessage) do
        self:addChatItem(v)
    end

    -- 刷新英雄表情
    self:updateHeroExpression()
end

function UIChat:onTop(fromUI, data)
    self:showExpressionPanel(1)
    -- 将选择的装备输入到输入框
    if fromUI == UIManager.UI.UIChatBag then
        self:appendTextField(expressionType.Equip, data)
    end
end

function UIChat:onClose()
    EventManager:removeEventListener(GameEvents.EventChatMessage, self.onEventChatHanlder)

    local lookEquipCmd = NetHelper.makeCommand(MainProtocol.Look, LookProtocol.LookEquipSC)
    NetHelper.removeResponeHandler(lookEquipCmd, self.lookEquipHandler)

    self.recordVoice:stopRecordVoice()
    self.eqInfoCsb:setVisible(false)
end

function UIChat:showExpressionCallBack(obj)
    self.isShowExpression = not self.isShowExpression
    if self.isShowExpression then
        self.rootAct:play("Appear", false)
        self:showExpressionPanel(1)
    else
        self.rootAct:play("Hide", false)
    end
end

function UIChat:updateHeroExpression()
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    local heros = heroCardBagModel:getWholeCards()

    self.heros = {}
    -- 获取英雄显示相关信息
    for _, heroId in ipairs(heros) do
        local heroModel = heroCardBagModel:getHeroCard(heroId)
        
        local soldierCfg = getSoldierConfItem(heroId, heroModel:getStar())
        if soldierCfg then
            local soldierInfo = {}
            soldierInfo.HeroId = heroId
            soldierInfo.HeadIcon = soldierCfg.Common.HeadIcon
            soldierInfo.Rare = soldierCfg.Rare
            soldierInfo.Cost = soldierCfg.Cost
            soldierInfo.Lv = heroModel:getLevel()
            soldierInfo.Star = heroModel:getStar()

            table.insert(self.heros, soldierInfo)
        end
    end

    -- 排序英雄:金—紫—蓝—绿，品质相同按星级、星级相同按等级
    local function sortHero(heroA, heroB)
        if heroA.Rare > heroB.Rare then
            return true
        elseif heroA.Rare == heroB.Rare then
            if heroA.Star > heroB.Star then
                return true
            elseif heroA.Star == heroB.Star then
                if heroA.Lv > heroB.Lv then
                    return true
                end
            end
        end

        return false
    end

    table.sort(self.heros, sortHero)
    HeroSViewExtend:reloadData()
end

function UIChat:changeChatCallBack(obj)
    if self.curMode == obj then return end

    self:changeChatPanel(obj)
end

function UIChat:enterCallBack(obj)
    obj.soundId = nil
    local text = self.textField:getString()
    if ChatHelper.canSendMessage(text) then
        -- 发送消息
        ChatHelper.sendChatMessage({chatMode = self.curMode:getTag(), 
           content = string.htmlspecialchars(self.chatInputText), chatMessageType = 1})

        self.textField:setString("")
        self.chatInputText = ""
    else
        obj.soundId = MusicManager.commonSound.fail
    end
end

function UIChat:downButtonCallBack(obj)
    self:showExpressionPanel(obj:getTag())
end

function UIChat:touchRecordCallBack(obj, event)
    if not ChatHelper.canSendMessage() then return end

    if event == 0 then
        -- 开始录音
        self.recordVoice:startRecordVoice()
	elseif event == 1 then
        -- 拖动取消录音
	    if cc.pGetDistance(obj:getTouchBeganPosition(), obj:getTouchMovePosition()) > 30 then
            self.recordVoice:cancelRecordVoice()
	    end

    elseif event == 2 or event == 3 then
        self.recordVoice:stopRecordVoice()
	end
end

--{聊天类型(语音或文图混合),UserID,头像,等级,内容}
function UIChat:addChatItem(chatData)
    if not chatData then return end

    local function addItem(chatMode, chatData, chatItem)
        if not self.chats[chatMode] then
            self.chats[chatMode] = {}
        end
        
        table.insert(self.chats[chatMode], 1, chatData)
        local view = self.chatViewObjInfo[chatMode].view
        view:addChild(chatItem)
        
        -- 最新的信息都是插到头部
        self.chats[chatMode][1].obj = chatItem
        self.lastMessageTime = chatData.sendTime
        self:updateScrollView(chatMode)
    end

    local chatItem = nil
    if chatData.chatMode == ChatHelper.ChatMode.WORLD
      or chatData.chatMode == ChatHelper.ChatMode.UNION then
        table.insert(self.allChats, chatData)
        chatItem = self:fillChatItem(chatData, chatData.chatMode)

        addItem(chatData.chatMode, chatData, chatItem)
    elseif chatData.chatMode == ChatHelper.ChatMode.BATTLE_UNIONSHARE then
        chatItem = self:fillReplayItem(chatData, chatData.chatMode)
        addItem(ChatHelper.ChatMode.WORLD, chatData, chatItem)
    else
        if chatData.chatRoom < 1 or chatData.chatRoom > 3 then
            return
        end

        if 1 == chatData.chatRoom then
            chatItem = self:fillNoticesItem(chatData, ChatHelper.ChatMode.WORLD)
            addItem(ChatHelper.ChatMode.WORLD, chatData, chatItem)
        elseif 2 == chatData.chatRoom then
            chatItem = self:fillNoticesItem(chatData, ChatHelper.ChatMode.UNION)
            addItem(ChatHelper.ChatMode.UNION, chatData, chatItem)
        elseif 3 == chatData.chatRoom then
            chatItem = self:fillNoticesItem(chatData, ChatHelper.ChatMode.WORLD)
            addItem(ChatHelper.ChatMode.WORLD, chatData, chatItem)
            chatItem = self:fillNoticesItem(chatData, ChatHelper.ChatMode.UNION)
            addItem(ChatHelper.ChatMode.UNION, chatData, chatItem)
        end
    end
end

function UIChat:fillChatHeadItem(chatItem, chatData, isRight)
    if not self.itemSize then
        self.itemSize = CsbTools.getChildFromPath(chatItem, "HeadPanel/Image_Icon"):getContentSize()
    end

    --CsbTools.getChildFromPath(chatItem, "HeadPanel/Image_Level") -- 边框
    local chatName = chatData.name and chatData.sendUid and (chatData.name.." ("..chatData.sendUid..")") or "unknow"
    local nameText = CsbTools.getChildFromPath(chatItem, "NameText")
    local blueDiamond = CsbTools.getChildFromPath(chatItem, "TencentLogo")
    -- 蓝钻
    CommonHelper.showBlueDiamond(blueDiamond, 
        math.floor(chatData.extend%10), 
        math.floor(chatData.extend/10),
        nameText, 
        {text = chatName, color = cc.c3b(159, 106, 52)}, 
        isRight)

    CsbTools.getChildFromPath(chatItem, "HeadPanel/Level"):setString(chatData.lv or 0)
    local headIcon = CsbTools.getChildFromPath(chatItem, "HeadPanel/Image_Icon") -- 头像
    local headIconItem = getSystemHeadIconItem()
    if headIconItem then
        headIcon:loadTexture(headIconItem[chatData.headId].IconName, 1)
    end
end

function UIChat:fillChatItem(chatData, chatMode)
    local chatItemCsb = nil
    local isRight = chatData.sendUid == self.userId
    local format = {}
    if isRight then
        chatItemCsb = self.UICsb.talkBarR
        format.color = "195113"
    else
        chatItemCsb = self.UICsb.talkBarL
        format.color = "703115"
    end

    local chatItem = getResManager():cloneCsbNode(chatItemCsb)
    local chatItemAct = cc.CSLoader:createTimeline(chatItemCsb)
    chatItem:runAction(chatItemAct)
    -- 设置头像信息
    self:fillChatHeadItem(chatItem, chatData, isRight)

    if ChatHelper.ChatMessageType.TEXT == chatData.chatMessageType then
        chatItemAct:play("Text", false)
        local textBar = CsbTools.getChildFromPath(chatItem, "Chat_Text")
        local textLb = CsbTools.getChildFromPath(textBar, "TextBar")
        textLb:setVisible(false)
        local content = ChatHelper.toHtmlCode(chatData.content, format)
        local richText = createRichTextWithCode(content, self.chatViewObjInfo[chatMode].viewSize.width*3/4)
        local textSize = richText:getContentSize()
        local barBg = CsbTools.getChildFromPath(textBar, "Panel_Bg")
        barBg:setTouchEnabled(false)
        richText:setPosition(14, 10)
        barBg:addChild(richText)
        barBg:setContentSize(textSize.width + 35, textSize.height + 15)
    else
        chatItemAct:play("Sound", false)
        local soundBar = CsbTools.getChildFromPath(chatItem, "Chat_Sound")
        local sountBarAct = cc.CSLoader:createTimeline(isRight and self.UICsb.soundBarR or self.UICsb.soundBarL)
        soundBar:runAction(sountBarAct)
        self.voices[chatData.messageId] = {act = sountBarAct}
        local barBg = CsbTools.getChildFromPath(soundBar, "Panel_Bg")
        barBg:setTag(chatData.messageId)
        barBg:addClickEventListener(handler(self, self.playVoiceCallBack))
        CsbTools.getChildFromPath(soundBar, "SoundLength"):setString(chatData.extend.."''")
    end

    return chatItem
end

function UIChat:fillNoticesItem(chatData, chatMode)
    local format = {}
    format.color = "703115"

    local chatItem = getResManager():cloneCsbNode(self.UICsb.talkBarL)
    if not self.itemSize then
        self.itemSize = CsbTools.getChildFromPath(chatItem, "HeadPanel/Image_Icon"):getContentSize()
    end

    local chatItemAct = cc.CSLoader:createTimeline(self.UICsb.talkBarL)
    chatItem:runAction(chatItemAct)
    chatItemAct:play("Text", false)

    CsbTools.getChildFromPath(chatItem, "NameText_2"):setVisible(true)
    CsbTools.getChildFromPath(chatItem, "NameText"):setString("")
    local headPanel = CsbTools.getChildFromPath(chatItem, "HeadPanel") -- 头像
    headPanel:setVisible(false)

    CsbTools.getChildFromPath(chatItem, "TencentLogo"):setVisible(false)

    local textBar = CsbTools.getChildFromPath(chatItem, "Chat_Text")
    local textLb = CsbTools.getChildFromPath(textBar, "TextBar")
    textLb:setVisible(false)
    local content = ChatHelper.toHtmlCode(chatData.chatContent or chatData.content, format)
    local richText = createRichTextWithCode(content, self.chatViewObjInfo[chatMode].viewSize.width*3/4)
    local textSize = richText:getContentSize()
    local barBg = CsbTools.getChildFromPath(textBar, "Panel_Bg")
    richText:setAnchorPoint(cc.p(0, 0))
    richText:setPosition(14, 10)
    barBg:addChild(richText)
    barBg:setContentSize(textSize.width + 35, textSize.height + 15)

    return chatItem
end

function UIChat:fillReplayItem(chatData, chatMode)
    local isRight = chatData.sendUid == self.userId

    local barCsb = isRight and self.UICsb.talkBarR or self.UICsb.talkBarL
    local chatItem = getResManager():cloneCsbNode(barCsb)
    local chatItemAct = cc.CSLoader:createTimeline(barCsb)
    chatItem:runAction(chatItemAct)
    chatItemAct:play("ShareTop", false)

    -- 设置头像信息
    self:fillChatHeadItem(chatItem, chatData, isRight)

    local shareVS = CsbTools.getChildFromPath(chatItem, "ShareVS")
    CsbTools.getChildFromPath(shareVS, "ReplayPanel/TipsText"):setString(chatData.content)
    CsbTools.getChildFromPath(shareVS, "ReplayPanel/Tips"):setVisible(false)
    CsbTools.getChildFromPath(shareVS, "ReplayPanel/InfoButton"):addClickEventListener(function ()
        UIManager.open(UIManager.UI.UIReplayInfo)
    end)

    CsbTools.getChildFromPath(shareVS, "ReplayPanel/ViewButton"):addClickEventListener(function ()
        CsbTools.addTipsToRunningScene("hello world")
    end)

    return chatItem
end

function UIChat:updateScrollView(mode)
    if not self.chats[mode] then return end

    local scrollHeight = VIEW_CONFIG.topMargin
    for k, v in pairs(self.chats[mode]) do
        if k > MAX_CHAT then break end

        if v.chatMode == ChatHelper.ChatMode.WORLD or v.chatMode == ChatHelper.ChatMode.UNION then
            scrollHeight = scrollHeight + self.itemSize.height + VIEW_CONFIG.padding
        elseif v.chatMode == ChatHelper.ChatMode.BATTLE_UNIONSHARE then
            scrollHeight = scrollHeight + VIEW_CONFIG.shareHeight + VIEW_CONFIG.padding
        else
            scrollHeight = scrollHeight + self.itemSize.height + VIEW_CONFIG.padding - VIEW_CONFIG.noticeDVal
        end
    end

    local viewInfo = self.chatViewObjInfo[mode]
    local viewSize = viewInfo.viewSize
    if scrollHeight > viewSize.height then
        viewSize.height = scrollHeight
        viewInfo.view:setInnerContainerSize(viewSize)
    end

    -- 移动位置
    local y = VIEW_CONFIG.topMargin + self.itemSize.height / 2
    local preMode = nil
    for k, v in pairs(self.chats[mode]) do
        if k > MAX_CHAT then
            local view = self.chatViewObjInfo[mode].view
            view:removeChild(v.obj)
            table.remove(self.chats[mode], k)
        else
            y = y + VIEW_CONFIG.padding
            if not preMode then
                preMode = v.chatMode
            else
                if preMode == ChatHelper.ChatMode.WORLD or preMode == ChatHelper.ChatMode.UNION then
                    y = y + self.itemSize.height
                elseif preMode == ChatHelper.ChatMode.BATTLE_UNIONSHARE then
                    y = y + VIEW_CONFIG.shareHeight
                else
                    y = y + self.itemSize.height - VIEW_CONFIG.noticeDVal
                end

                preMode = v.chatMode
            end

            v.obj:setPosition(v.sendUid == self.userId and 625 or 50, viewSize.height - y)
        end
    end
end

function UIChat:onEventChat(eventName, chatInfo)
    -- 等级限制
    if chatInfo.sendUid and chatInfo.lv then
        if self.userId ~= chatInfo.sendUid and ChatHelper.getLimitLv() > chatInfo.lv then
            return
        end
    end

    self:addChatItem(chatInfo)
end

function UIChat:playVoiceCallBack(obj)
    local messageid = obj:getTag()
    local voicePath = ChatHelper.getVoice(messageid)
    if voicePath == "" then return end

    local soundBarAct = self.voices[messageid].act
    if not soundBarAct then return end
    
    if self.curAudio > 0 and self.voices[self.curAudio] then
        cc.SimpleAudioEngine:getInstance():stopEffect(self.voices[self.curAudio].soundId)
        self.voices[self.curAudio].act:play("Off", false)

        if self.curAudio == messageid then
            self.curAudio = 0
            return
        end

        self.curAudio = 0
    end

    --print("voicePath", voicePath)
    self.curAudio = messageid
    -- 不是FMOD的文件
    local soundId = cc.SimpleAudioEngine:getInstance():playEffect(voicePath, false)
    self.voices[messageid].soundId = soundId
    print("self.curAudio", soundId)
    soundBarAct:play("On", false)
    if self.curAudio and self.curAudio > 0 then
        obj:runAction(cc.Sequence:create(cc.DelayTime:create(self.allChats[messageid].extend), cc.CallFunc:create(function()
            soundBarAct:play("Off", false)
        end)))
    end
end

function UIChat:changeChatPanel(obj)
    if not obj then return end

    if ChatHelper.ChatMode.UNION == obj:getTag() then
        local unionConf = getUnionConfItem()
        if unionConf and getGameModel():getUserModel():getUserLevel() < unionConf.UnLockLv then
            CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(300), unionConf.UnLockLv))
            return
        end

        -- 没有公会提示加入公会
        if not getGameModel():getUnionModel():getHasUnion() then
            local params = {}
            params.msg = CommonHelper.getUIString(UILanguage.joinUnionTips)
            params.confirmFun = function () UIManager.replace(UIManager.UI.UIUnionList) end
            params.cancelFun = function () print("nothing to do...") end
            UIManager.open(UIManager.UI.UIDialogBox, params)
            return
        end
        --self.recordChatButton:setVisible(true)
    else
        --self.recordChatButton:setVisible(false)
    end

    -- 显示相应的view
    for k, v in pairs(self.chatViewObjInfo) do
        v.view:setVisible(k == obj:getTag())
    end

    if self.curMode then
        self.curMode:setLocalZOrder(self.modeZorder - 1)
    end
    
    self.curMode = obj
    obj:setLocalZOrder(self.modeZorder + 1)
end

function UIChat:showExpressionPanel(cur)
    if self.curExpressionPanel == cur then return end

    if self.downButtonAct[self.curExpressionPanel] then
        self.downButtonAct[self.curExpressionPanel]:play("Off", false)
    end

    if self.downButtonAct[cur] then
        self.downButtonAct[cur]:play("On", false)
    end

    self.curExpressionPanel = cur
    self.expressionScrollView:setVisible(1 == self.curExpressionPanel)
    self.heroScrollView:setVisible(2 == self.curExpressionPanel)

    if 3 == self.curExpressionPanel then
        -- 打开聊天道具背包界面
        UIManager.open(UIManager.UI.UIChatBag)
    end
end

function UIChat:appendTextField(type, data)
    if not type or not data then
        return
    end

    local input = nil
    local showInput = nil
    if expressionType.Expression == type then
        local expression = getExpressionSetting()[data]
        if expression then
            showInput = expression.Expression_Input
            input = expression.Expression_Input
        end

    elseif expressionType.Hero == type then
        local heroInfo = self.heros[data]
        if heroInfo and heroInfo.HeroId then
            local soldierConf = getSoldierConfItem(heroInfo.HeroId, 1)
            if soldierConf then
                showInput = "["..CommonHelper.getHSString(soldierConf.Common.Name).."]"
                input = "[H"..heroInfo.HeroId.."]"
            end
        end

    elseif expressionType.Equip == type then
        local propConf = getPropConfItem(data.config_id)
        if propConf and propConf.Type == 1 then
            showInput = "["..CommonHelper.getPropString(propConf.Name).."]"
            input = "[E"..data.config_id.."D"..data.unique_id.."]"
        end
    end

    if input and showInput then
        showInput = self.textField:getString()..showInput
        if string.len(showInput) > self.textField:getMaxLength() then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(433))
        else
            self.textField:setString(showInput) 
            self.chatInputText = self.chatInputText..input
        end
    end
end

function UIChat:setHeroIconNode(csbNode, idx)
    local soldierInfo = self.heros[idx]
    if nil == soldierInfo then
        --csbNode:setVisible(false)
        CommonHelper.playCsbAnimate(csbNode, self.UICsb.item, "Empty", false, true)
        return
    else
        CommonHelper.playCsbAnimate(csbNode, self.UICsb.item, "Normal", false, true)
    end

    local heroImage = getChild(csbNode, "HeroImage")
    local bgImage   = getChild(csbNode, "LvBgImage")
    local lvLabel   = getChild(csbNode, "LvLabel")
    local costLabel = getChild(csbNode, "GemLabel")
    local starLabel = getChild(csbNode, "StarLabel")
    local lvImage   = getChild(csbNode, "HeroImage/LvImage")
    local jobImage  = getChild(csbNode, "ProfesionIcon")
    local raceImage = getChild(csbNode, "RaceIcon")
    local mercenaryLogo = getChild(csbNode, "MercenaryLogo")
    jobImage:setVisible(false)
    raceImage:setVisible(false)
    mercenaryLogo:setVisible(false)
    -- 设置头像、背景、边框
    heroImage:loadTexture(soldierInfo.HeadIcon, 1)
    bgImage:loadTexture(IconHelper.getSoldierHeadBg(soldierInfo.Rare), 1)
    lvImage:loadTexture(IconHelper.getSoldierHeadFrame(soldierInfo.Rare), 1)
    -- 设置等级、消耗与星级的文本
    lvLabel:setString(tostring(soldierInfo.Lv))
    starLabel:setString(tostring(soldierInfo.Star))
    costLabel:setString(tostring(soldierInfo.Cost))
end

function UIChat:acceptLookEquipInfo(mainCmd, subCmd, data)
    local uid = data:readInt()
    if uid <= 0 then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2171))
        return
    end

    local equipInfo = {}
    equipInfo.equipId = data:readInt()
    equipInfo.confId = data:readInt()
    equipInfo.nMainPropNum = data:readUChar()
    equipInfo.eqEffectIDs = {}
    for i = 1, 8 do
        table.insert(equipInfo.eqEffectIDs, data:readUChar())
    end

    equipInfo.eqEffectValues = {}
    for i = 1, 8 do
        table.insert(equipInfo.eqEffectValues, data:readUChar())
    end

    -- 查看数据缓存
    ChatHelper.addChatCacheInfo(ChatHelper.ChatLook.EQUIP, uid, equipInfo.equipId, equipInfo)
    self:showEquipInfo(equipInfo)
end

function UIChat:showEquipInfo(equipInfo)
    self.eqInfoCsb:setVisible(true)
    UIEquipViewHelper:setCsbByEquipInfo(self.equipInfoCsb, equipInfo, 340)
end

return UIChat