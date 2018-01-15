GlobalListen = {}
require("game.mail.MailHelper")
require("game.comm.ConnectionTips")
require("game.comm.NotificationHelper")
require("game.union.UnionHelper")
require("framework.cocos2dx.Cocos2dConstants")
local scheduler = require("framework.scheduler")

function GlobalListen.init()
    if not GlobalListen.isInit then
        GlobalListen.isInit = true
    else
        return
    end

    --------------------------------本地监听------------------------------------
    -- 界面开启关闭监听
    UIManager.uiOpenBeforeDelegate = function(ui, pre)
        EventManager:raiseEvent(GameEvents.EventOpenUIBefore, ui, pre)
    end
    UIManager.uiOpenDelegate = function(ui, pre)
        EventManager:raiseEvent(GameEvents.EventOpenUI, ui, pre)
    end
    UIManager.uiCloseDelegate = function(ui)
        EventManager:raiseEvent(GameEvents.EventCloseUI, ui)
    end
    -- 场景切换监听
    SceneManager.ChangeSceneDelegate = function()
        EventManager:raiseEvent(GameEvents.EventChangeScene)
    end

    GlobalListen.UserOldLv = getGameModel():getUserModel():getUserLevel()
    -- 监听召唤师升级
    EventManager:addEventListener(GameEvents.EventPlayerUpgradeLevel, GlobalListen.onUserUpgarde)
    -- 监听打开召唤师升级界面
    EventManager:addEventListener(GameEvents.EventUserUpgradeUI, GlobalListen.onOpenUserUpgarde)
    -- 时间达到
    EventManager:addEventListener(GameEvents.EventTimeCall, GlobalListen.onTimeCall)
    -- 询问关闭游戏窗口
    GlobalListen.closeGameListener = cc.EventListenerCustom:create("AskCloseGame", GlobalListen.onAskCloseGameCall)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(GlobalListen.closeGameListener, 1)
    --------------------------------网络监听------------------------------------
	-- 邮件接收监听
	local cmd = NetHelper.makeCommand(MainProtocol.Mail, MailProtocol.SendMailSC)
	NetHelper.setResponeHandler(cmd, GlobalListen.onReceiveMail)

	-- 背包添加物品监听
	local bagAddCmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.AddSC)
	NetHelper.setResponeHandler(bagAddCmd, GlobalListen.onAddItem)

    -- 运营活动任务数据更新监听
    local operateActiveCmd = NetHelper.makeCommand(MainProtocol.OperateActive, OperateActiveProtocol.OperateActiveTaskUpdateSC)
    NetHelper.setResponeHandler(operateActiveCmd, GlobalListen.onOperateActiveTaskUpdate)

    -- 七日活动数据更新监听
    -- local sevenCrazyCmd = NetHelper.makeCommand(MainProtocol.OperateActive, SevenCrazyProtocol.SevenCrazyGetUpdateSC)
    -- NetHelper.setResponeHandler(sevenCrazyCmd, GlobalListen.onSevenCrazyUpdate)

    -- 错误码
    local errorCodeCmd = NetHelper.makeCommand(MainProtocol.ErrorCode, ErrorCodeProtocol.errorCode)
    NetHelper.setResponeHandler(errorCodeCmd, GlobalListen.onReceiveErrorCode)

    -- 被踢, 被顶
    local rechangeCmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.RechangeSC)
    local tickCmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.TickSC)
    NetHelper.setResponeHandler(rechangeCmd, GlobalListen.onLogin)
    NetHelper.setResponeHandler(tickCmd, GlobalListen.onLogin)

    -- 被审核者应答
    local beAuditCmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionBeAuditSC)
    NetHelper.setResponeHandler(beAuditCmd, GlobalListen.onBeAudit)
    local beFunctionCmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionBeFunctionSC)
    NetHelper.setResponeHandler(beFunctionCmd, GlobalListen.onBeFunction)
    -- 公会信息通知
    local messageCmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMessageSC)
    NetHelper.setResponeHandler(messageCmd, GlobalListen.onUnionMessage)

    -- 公会远征: 目标选择
    local expeditionMapSetCmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.MapSetSC)
    NetHelper.setResponeHandler(expeditionMapSetCmd, GlobalListen.onExpeditionMapSet)
    -- 公会远征: 关卡通过
    local expeditionStagePassCmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.StagePassSC)
    NetHelper.setResponeHandler(expeditionStagePassCmd, GlobalListen.onExpeditionStagePass)
    -- 公会远征: 奖励标识
    local expeditionRewardFlagCmd = NetHelper.makeCommand(MainProtocol.Expedition, ExpeditionProtocol.RewardFlagSC)
    NetHelper.setResponeHandler(expeditionRewardFlagCmd, GlobalListen.onExpeditionRewardFlag)

    -- 公会商店刷新通知
    local unionShopFreshCmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopUnionFreshSC)
    NetHelper.setResponeHandler(unionShopFreshCmd, GlobalListen.onUnionShopFresh)
    -- 公会商店购买通知
    local unionShopBuyCmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopUnionBuySC)
    NetHelper.setResponeHandler(unionShopBuyCmd, GlobalListen.onUnionShopBuy)
    -- 通知消息
    local noticeCmd = NetHelper.makeCommand(MainProtocol.Notice, NoticeProtocol.NoticeSC)
    NetHelper.setResponeHandler(noticeCmd, GlobalListen.onNotice)
    -- 聊天消息
    local chatCmd = NetHelper.makeCommand(MainProtocol.Chat, ChatProtocol.ReceiveMoreMessageSC)
    NetHelper.setResponeHandler(chatCmd, GlobalListen.onMoreChat)
    local chatCmd = NetHelper.makeCommand(MainProtocol.Chat, ChatProtocol.ReceiveSingleMessageSC)
    NetHelper.setResponeHandler(chatCmd, GlobalListen.onSingleChat)
    -- pvp宝箱刷新
    local refreshChestCmd = NetHelper.makeCommand(MainProtocol.PvpChest, PvpChestProtocol.RefreshChestSC)
	NetHelper.addResponeHandler(refreshChestCmd, GlobalListen.onRefreshChestCmd)
    -- 支付消息事件监听
    EventManager:addEventListener(GameEvents.EventSDKPaySuccess, GlobalListen.onSDKPaySucess)
    -- 支付结果事件
    EventManager:addEventListener(GameEvents.EventRecharge, GlobalListen.onRechargeEvent)    
    -- 充值结果
    local rechargeCmd = NetHelper.makeCommand(MainProtocol.Pay, PayProtocol.payYSDKSC)
    NetHelper.addResponeHandler(rechargeCmd, GlobalListen.onRechargeCmd)
    -- 监听查看英雄消息
    local lookHeroCmd = NetHelper.makeCommand(MainProtocol.Look, LookProtocol.LookHeroSC)
    NetHelper.addResponeHandler(lookHeroCmd, GlobalListen.onLookHeroInfo)
end

function GlobalListen.onReceiveMail(mainCmd, subCmd, data)
print("GlobalListen.onReceiveMail")
	local mailInfo = {}
	mailInfo.mailType = data:readChar()
	mailInfo.mailID = data:readInt()
	mailInfo.isGetContent = false
	mailInfo.vecItem = {}

	if mailInfo.mailType == MailHelper.Type.normal or
		mailInfo.mailType == MailHelper.Type.web then
		mailInfo.mailConfID = data:readInt()
		mailInfo.sendTimeStamp = data:readInt()
		mailInfo.title = data:readCharArray(32) or ""

		local mailConf = getMailConfItem(mailInfo.mailConfID)	
		if mailConf then
            -- 拼接内容
            local hello = getUILanConfItem(408)
            if mailInfo.mailConfID == 4 or mailInfo.mailConfID == 5 then
                -- 公会邮件特殊处理 ~_~
                mailInfo.content = string.format(hello.."\n\t".. getUILanConfItem(mailConf.Content), mailInfo.title)
            else
                 mailInfo.content = hello.."\n\t"..getUILanConfItem(mailConf.Content)
            end

			mailInfo.title = CommonHelper.getUIString(mailConf.Topic)
			mailInfo.sender = CommonHelper.getUIString(mailConf.Sender)

			MailHelper.addMail(mailInfo)
            dump(mailInfo, "onReceiveMail")
		end
	end

	-- 过滤邮件
	local mailsData = MailHelper.getMailsData()
	MailHelper.filterMail(mailsData)
end

function GlobalListen.onAddItem(mainCmd, subCmd, data)
    local itemType = {[1] = "equip", [3] = "hero", [4] = "summoner",[13]="EquipCreate",[14]="resource", [15] = "frag", [16]="head"}

    local count = data:readInt()
    for i=1, count do
        local type = data:readInt()
        local itemID = data:readInt()
        if itemType[type] == "equip" or itemType[type] == "EquipCreate" then
            local eqDyID = data:readInt()
            local eqMainPropNum = data:readChar()
            local eqEffectIDs = {}
            local eqEffectValues = {}
            for i=1, 8 do
                eqEffectIDs[i] = data:readChar()
            end
            for i=1,8 do
                eqEffectValues[i] = data:readShort()
            end

            ModelHelper.addEquip(eqDyID, itemID,eqMainPropNum,eqEffectIDs, eqEffectValues)
        elseif itemType[type] == "hero" then
            local heroStar = data:readInt()
            local cardID = data:readInt()
            ModelHelper.AddHero(cardID, 1, heroStar)
        elseif itemType[type] == "summoner" then
            ModelHelper.AddSummoner(itemID)
            
            -- 添加头像(此时的itemID是召唤师ID)
            local sumConfItem = getSaleSummonerConfItem(itemID)
            ModelHelper.addHead(sumConfItem.HeadID)
        elseif itemType[type] == "resource" then
            local ResourceNum = data:readInt()
            ModelHelper.addCurrency(itemID, ResourceNum)
        elseif itemType[type] == "head" then
            data:readInt()
            -- 添加头像
            local propConfItem = getPropConfItem(itemID)
            ModelHelper.addHead(propConfItem.TypeParam[1])
        elseif itemType[type] == "frag" then
        	local heroID = data:readInt()
        	local fragCount = data:readInt()
        	ModelHelper.addFrag(heroID, fragCount)
        else
            local propCount = data:readInt()
            ModelHelper.addItem(itemID, propCount)
        end
    end
end

function GlobalListen.onUserUpgarde()
    EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
end

function GlobalListen.onOpenUserUpgarde()
    -- 召唤师升级
    local userLv = getGameModel():getUserModel():getUserLevel()
    if GlobalListen.UserOldLv > 0 and GlobalListen.UserOldLv ~= userLv then
        UIManager.open(UIManager.UI.UISummonerUpgrade, GlobalListen.UserOldLv, userLv)
        -- 锦标赛解锁监听开赛
        --if userLv >= getArenaLevel()[3] then
        --    ModelHelper.addArenaTime(true)
        --end
    end

    GlobalListen.UserOldLv = userLv
end

-- 运营活动任务数据更新回调
function GlobalListen.onOperateActiveTaskUpdate(mainCmd, subCmd, data)
	local model = getGameModel():getOperateActiveModel()
    local activeID = data:readShort()
	local count = data:readShort()
    -- 运营活动1,七天活动2
    local activeType = 0
    for i = 1, count do
        local value = data:readInt()                 -- 参数更新
        local taskID = data:readChar()               -- 活动任务ID

        if model:setActiveTaskProgress(activeID, taskID, value) then
            activeType = 1
        elseif getGameModel():getSevenCrazyModel():setActiveTaskValue(activeID, taskID, value) then
            activeType = 2
        end
    end

    EventManager:raiseEvent(GameEvents.EventOperateActiveUpdate, {activeType = activeType, activityId = activeID})
    if activeType == 2 then
         getGameModel():getSevenCrazyModel():updateToRefreshUI()
    end
end

-- -- 七日活动任务数据更新回调
-- function GlobalListen.onSevenCrazyUpdate(mainCmd, subCmd, data)
--     local model = getGameModel():getSevenCrazyModel()
--     local activeID = data:readInt()
--     local count = data:readInt()
--     for i = 1, count do
--         local taskID = data:readInt()               -- 活动任务ID
--         local value = data:readInt()                -- 参数更新
        
--         model:setActiveTaskProgress(activeID, taskID, value)
--     end

--     EventManager:raiseEvent(GameEvents.EventSevenCrazyUpdate, {activityId = activeID})
-- end


function GlobalListen.onReceiveErrorCode(mainCmd, subCmd, data)
	local errorID = data:readInt()
    print("onReceiveErrorCode ", errorID)
	local str = CommonHelper.getErrorCodeString(errorID) or errorID
	CsbTools.createFloatTip(str, {})
		:addTo(display.getRunningScene())
end

function GlobalListen.onLogin(mainCmd, subCmd, data)
    ConnectionTips.isKick = true
    GlobalListen.ShowLoginTips(subCmd)
end

function GlobalListen.ShowLoginTips(subCmd)
    if UIManager.isTopUI(UIManager.UI.UINoticeActivity) then
        UIManager.close()
    end
    
    -- tipsNode 不存在或者没在NotificationNode里面, 创建一个新的
    if (not GlobalListen.tipsNode) or (not NotificationHelper.hasNode(GlobalListen.tipsNode)) then
        GlobalListen.tipsNode = cc.CSLoader:createNode("ui_new/g_gamehall/g_gpub/TipPanel.csb")
        NotificationHelper.addNode(GlobalListen.tipsNode, 9999999)
        CommonHelper.layoutNode(GlobalListen.tipsNode)

        -- 文字: 提示
        CsbTools.getChildFromPath(GlobalListen.tipsNode, "BuyEnergyPanel/BarNameLabel")
            :setString(CommonHelper.getUIString(605))

        -- 按钮
        local confirmBtn = CsbTools.getChildFromPath(GlobalListen.tipsNode, "BuyEnergyPanel/ConfrimButton")
        local cancelBtn = CsbTools.getChildFromPath(GlobalListen.tipsNode, "BuyEnergyPanel/CancelButton")
        local confirmLab = CsbTools.getChildFromPath(confirmBtn, "Text")
        local cancelLab = CsbTools.getChildFromPath(cancelBtn, "Text")
        confirmLab:setString(CommonHelper.getUIString(500))
        cancelLab:setString(CommonHelper.getUIString(501))

        -- 是否点击到按钮范围
        function isContains(btn, location)
            local pos = btn:convertToNodeSpace(location)
            local size = btn:getContentSize()
            if pos.x < 0 or pos.x > size.width or
                pos.y < 0 or pos.y > size.height then
                return false
            end
            return true
        end
        -- 按钮播放放大缩小
        function btnScale(btn, isScale)
            if btn.isScale ~= true then
                if isScale then
                    btn.isScale = true
                    btn:runAction(cc.ScaleTo:create(0.1, 1.2))
                end
            else
                if not isScale then
                    btn.isScale = false
                    btn:runAction(cc.ScaleTo:create(0.1, 1.0))
                end
            end
        end

        if not GlobalListen.listener then
            -- 触摸事件回调
            function onTouchBegan(touch, event)
                local isConfirmBtnTouch = isContains(confirmBtn, touch:getLocation())
                local isCancelBtnTouch = isContains(cancelBtn, touch:getLocation())
                confirmBtn.isTouch = isConfirmBtnTouch
                cancelBtn.isTouch = isCancelBtnTouch
                btnScale(confirmBtn, isConfirmBtnTouch)
                btnScale(cancelBtn, isCancelBtnTouch)

                return true
            end
            function onTouchMoved(touch, event)
                if confirmBtn.isTouch then
                    if isContains(confirmBtn, touch:getLocation()) then
                        btnScale(confirmBtn, true)
                    else
                        btnScale(confirmBtn, false)
                    end
                end
                if cancelBtn.isTouch then
                    if isContains(cancelBtn, touch:getLocation()) then
                        btnScale(cancelBtn, true)
                    else
                        btnScale(cancelBtn, false)
                    end
                end
            end
            function onTouchEnded(touch, event)
                if GlobalListen.tipsNode then
                    if (confirmBtn.isTouch and isContains(confirmBtn, touch:getLocation())) or
                        (cancelBtn.isTouch and isContains(cancelBtn, touch:getLocation())) then

                        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
                        eventDispatcher:removeEventListener(GlobalListen.listener) 
                        closeGame()
                    end
                end
            end

            -- 触摸事件注册
            local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
            GlobalListen.listener = cc.EventListenerTouchOneByOne:create()
            GlobalListen.listener:setSwallowTouches(true)        
            GlobalListen.listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
            GlobalListen.listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
            GlobalListen.listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
            eventDispatcher:addEventListenerWithFixedPriority(GlobalListen.listener, -129)
        end
    else
        GlobalListen:setVisible(true)
    end

    -- 提示内容
    local tipsLanID = (subCmd == LoginProtocol.RechangeSC) and 803 or 801
    CsbTools.getChildFromPath(GlobalListen.tipsNode, "BuyEnergyPanel/TipLabel1")
        :setString(CommonHelper.getErrorCodeString(tipsLanID))
end

function GlobalListen.onBeAudit(mainCmd, subCmd, data)
    local unionModel = getGameModel():getUnionModel()
    unionModel:setHasUnion(true)

    getGameModel():getUnionModel():readOwnUnionBuffData(data)

    CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(2002), unionModel:getUnionName()))

    EventManager:raiseEvent(GameEvents.EventOwnUnion, {})
    RedPointHelper.updateUnion()
    ChatHelper.joinRoom(ChatHelper.ChatMode.UNION, unionModel:getUnionID())

    -- 自动拉取佣兵信息
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoCS)
    NetHelper.request(buffData)
    local UnionMercenaryCmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoSC)
    local mercenarysInfoHandler = nil
    mercenarysInfoHandler = function (mainCmd, subCmd, data)
        if getGameModel():getUnionMercenaryModel():init(data) then
    	    print("GlobalListen.onBeAudit 数据初始化成功!!!!!")
        end
        NetHelper.removeResponeHandler(UnionMercenaryCmd, mercenarysInfoHandler)
    end
    NetHelper.setResponeHandler(UnionMercenaryCmd, mercenarysInfoHandler)
    -- 远征开始结束通知
    ModelHelper.addExpeditionTime()
end

function GlobalListen.onBeFunction(mainCmd, subCmd, data)
    local funcType = data:readChar()

    -- 修改公会模型
    local unionModel = getGameModel():getUnionModel()   

    if funcType == UnionHelper.FuncType.Kick then
        ChatHelper.quitRoom(ChatHelper.ChatMode.UNION, getGameModel():getUnionModel():getUnionID())

        CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(1999), unionModel:getUnionName()))
        unionModel:setHasUnion(false)
        unionModel:setApplyStamp(getGameModel():getNow() + getUnionConfItem().ApplyCD*60)

        -- 退出公会清空公会商店数据
        local shopModel = getGameModel():getShopModel()
        shopModel:clearUnionShopData()
    elseif funcType == UnionHelper.FuncType.Appoint then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1997))
        unionModel:setPos(UnionHelper.pos.ViceChairman)

    elseif funcType == UnionHelper.FuncType.Transfer then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2000))

        local membersInfo = unionModel:getMembersInfo()
        for _, v in ipairs(membersInfo) do
            if v.pos == UnionHelper.pos.Chairman then
                v.pos = UnionHelper.pos.Normal
                break
            end
        end
        local onlineMembersInfo = unionModel:getOnlineMembersInfo()
        for _,v in ipairs(onlineMembersInfo) do
            if v.pos == UnionHelper.pos.Chairman then
                v.pos = UnionHelper.pos.Normal
                break
            end
        end
        
        unionModel:setMembersInfo(membersInfo)
        unionModel:setOnlineMembersInfo(onlineMembersInfo)
        unionModel:setPos(UnionHelper.pos.Chairman)

    elseif funcType == UnionHelper.FuncType.Relieve then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1998))
        unionModel:setPos(UnionHelper.pos.Normal)

    elseif funcType == UnionHelper.FuncType.Dismiss then
        CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(1960), unionModel:getUnionName()))
        ChatHelper.quitRoom(ChatHelper.ChatMode.UNION, getGameModel():getUnionModel():getUnionID())
        unionModel:setHasUnion(false)
    end
    
    RedPointHelper.updateUnion()
    EventManager:raiseEvent(GameEvents.EventUnionFunc, {funcType = funcType})
end

function GlobalListen.onTimeCall(eventName, data)
    if data.system then
        -- 商店刷新
        if data.system == RedPointHelper.System.Shop then
            RedPointHelper.addCount(data.system, 1)

            local nextTime = getShopTypeData(1).nFreshTime * 60 + data.time
            ModelHelper.addTimer(nextTime, {system = data.system, time = nextTime})
        elseif data.system == RedPointHelper.System.Activity then
            RedPointHelper.addCount(data.system, 1, data.activeID)

        elseif data.system == RedPointHelper.System.Boon then
            ModelHelper.addBoonTime()

        -- 锦标赛开启
        elseif data.system == RedPointHelper.System.Arena then
            --ModelHelper.addArenaTime()
            --getGameModel():getNoticesModel():addNotice(1)
        end
    elseif data.expedition then
        if getGameModel():getUnionModel():getHasUnion() then
            -- 远征开始
            if 1 == data.expedition then 
                getGameModel():getNoticesModel():addNotice(8)

            -- 远征结束
            else   
                -- 远征失败
                if not getGameModel():getExpeditionModel():getWinState() then
                    getGameModel():getNoticesModel():addNotice(10)
                end
            end
        end
    end
end

function GlobalListen.onAskCloseGameCall()
    if KeyBoardListener then
        KeyBoardListener:openEndTips()
    end
end

-- 0活跃度 1审核
function GlobalListen.onUnionMessage(mainCmd, subCmd, data)
    local messageType = data:readInt()

    if 0 == messageType then
        RedPointHelper.addCount(RedPointHelper.System.Union, 1, RedPointHelper.UnionSystem.Liveness)
        UnionHelper.reGetStamp.unionInfo = 0
    elseif 1 == messageType then
        local unionModel = getGameModel():getUnionModel()
        unionModel:setHasAudit(1)
        if unionModel:getPos() > 0 then
            RedPointHelper.addCount(RedPointHelper.System.Union, 1, RedPointHelper.UnionSystem.Audit)
            UnionHelper.reGetStamp.unionAuditList = 0
        end
    elseif 2 == messageType then        -- 派遣监听
        print("全局派遣回调从这里开始")
        UnionHelper:sendMercenary(data)
    elseif 3 == messageType  then       -- 召回监听
        print("全局召回回调从这里开始")
        UnionHelper:callMercenary(data)
    end
end



function GlobalListen.onExpeditionMapSet(mainCmd, subCmd, data)
    local areaId = data:readInt()
    local mapId = data:readInt()
    local warEndTime = data:readInt()
    local expeditionModel = getGameModel():getExpeditionModel()
    -- 设置区域ID
    expeditionModel:setAreaId(areaId)
    -- 设置地图ID
    expeditionModel:setMapId(mapId)
    -- 设置结束时间
    expeditionModel:setWarEndTime(warEndTime)
    -- 添加初始关卡id
    local mapConf = getExpeditionMapConf(mapId) or {}
    local stages = mapConf.Stages or {}
    for _, v in pairs(mapConf.startStages or {}) do
        local stage = stages[v] or {}
        expeditionModel:addStage(v, stage.bossHp or 0)
    end
    -- 设置排行榜地图id
    expeditionModel:setRankMapId(mapId)
    -- 清空排行榜列表
    expeditionModel:clearRankList()
    expeditionModel:setWinState(false)

    -- 触发远征目标设定成功事件
    EventManager:raiseEvent(GameEvents.EventExpeditionMapSet)
    getGameModel():getNoticesModel():addNotice(7)

    -- 如果设置目标处于开始阶段
    if expeditionModel:getRestEndTime() <= getGameModel():getNow() then
        getGameModel():getNoticesModel():addNotice(8)
    end

    ModelHelper.addExpeditionTime()
end

function GlobalListen.onExpeditionStagePass(mainCmd, subCmd, data)
    local index = data:readInt()
    local expeditionModel = getGameModel():getExpeditionModel()
    local mapId = expeditionModel:getMapId()
    local mapConf = getExpeditionMapConf(mapId) or {}
    -- 远征结束: Boss死亡, 将所有数据重置
    if index == mapConf.stageNum then
        -- 进入远征休息阶段
        local nowTime = getGameModel():getNow()
        local curAreaId = expeditionModel:getAreaId()
        local areaConf = getExpeditionItem(curAreaId)
        local _time = areaConf and areaConf.Expedition_RestTime or 0
        expeditionModel:setRestEndTime(nowTime + _time)
        expeditionModel:setWarEndTime(nowTime)
        expeditionModel:setAreaId(0)
        expeditionModel:setMapId(0)
        expeditionModel:clearStages()
        expeditionModel:setWinState(true)
        -- 奖励发放时间点
        local unionConf = getUnionConfItem() or {}
        expeditionModel:setAwardSendTime(nowTime + unionConf.RewardTime or 600)

        -- 下架公会商店商品
        local shopModel = getGameModel():getShopModel()
        shopModel:clearUnionShopData()
        shopModel:setUnionGoodsCount(0)
        shopModel:setUnionShopState(1)

        -- 触发 远征胜利 事件
        EventManager:raiseEvent(GameEvents.EventExpeditionWin)
        getGameModel():getNoticesModel():addNotice(9)
    else
        -- 设置关卡boss血量
        expeditionModel:setStageHp(index, 0)
        -- 添加解锁关卡id
        local stages = mapConf.Stages or {}
        local stage = stages[index] or {}
        for _, v in pairs(stage.unLockStages or {}) do
            local stage = stages[v] or {}
            expeditionModel:addStage(v, stage.bossHp)
        end

        -- 触发 远征关卡通过 事件
        EventManager:raiseEvent(GameEvents.EventExpeditionStagePass)
    end
end

function GlobalListen.onExpeditionRewardFlag(mainCmd, subCmd, data)
    local flag = data:readChar()
    local expeditionModel = getGameModel():getExpeditionModel()
    expeditionModel:setAwardFlag(flag)
    expeditionModel:setAwardSendTime(0)

    -- 触发 奖励标识 事件
    EventManager:raiseEvent(GameEvents.EventExpeditionAwardFlag)
    getGameModel():getNoticesModel():addNotice(11)
end



function GlobalListen.onUnionShopFresh(mainCmd, subCmd, data)
    local shopModel = getGameModel():getShopModel()
    shopModel:initUnionShop(data)

    -- 触发 公会商店刷新 事件
    EventManager:raiseEvent(GameEvents.EventUnionShopFresh)
end

function GlobalListen.onUnionShopBuy(mainCmd, subCmd, data)
    local userID = data:readInt()
    local nGoodsShopID = data:readShort()
    local buyNum = data:readChar()

    -- 更新公会商店商品数据
    local shopModel = getGameModel():getShopModel()
    shopModel:setUnionShopGoodsData(nGoodsShopID, buyNum)

    -- 触发 公会商店购买 事件
    EventManager:raiseEvent(GameEvents.EventUnionShopBuy, {buyNum = buyNum, userID = userID})
end

function GlobalListen.onNotice(mainCmd, subCmd, data)
    local noticeCount = data:readChar()

    for i = 1, noticeCount do
        local noticeId = data:readInt()
        local paramCount = data:readChar()
        local param = {}
        for j = 1, paramCount do
            local paramType = data:readChar()
            -- int类型
            if 0 == paramType then
                local iVal = data:readInt()
                table.insert(param, iVal)
            -- 字符串类型
            elseif 1 == paramType then
                local len = data:readShort()
                local szVal = data:readCharArray(len)
                table.insert(param, szVal)
            end
        end

        getGameModel():getNoticesModel():addNotice(noticeId, param)

        -- 2成员加入, 3成员退出, 4任命, 5转职, 6公会公告更新
        if noticeId == 2 or noticeId == 3 or noticeId == 4 or noticeId == 5 then
            UnionHelper.reGetStamp.unionInfo = 0    
            UnionHelper.reGetStamp.unionMemberInfo = 0
        elseif noticeId == 6 then
            UnionHelper.reGetStamp.unionInfo = 0
        end
    end
end

----------------------------------聊天相关----------------------------------------
local function readMessageInfo(data)
    local messageInfo = {}
    messageInfo.headId = tonumber(data:readChar())
    messageInfo.chatMode = tonumber(data:readChar())
    messageInfo.lv = tonumber(data:readChar())
    messageInfo.chatMessageType = tonumber(data:readChar())
    messageInfo.sendUid = data:readInt()
    messageInfo.sendTime = data:readInt()
    messageInfo.targetId = data:readInt()
    messageInfo.extend = data:readInt()
    messageInfo.name = data:readCharArray(20)
    messageInfo.content = ChatHelper.analysisChatContent(data:readCharArray(128), messageInfo.sendUid)

    return messageInfo
end

function GlobalListen.onMoreChat(mainCmd, subCmd, data)
    local count = tonumber(data:readChar())

    for i = 1, count do
        EventManager:raiseEvent(GameEvents.EventChatMessage, readMessageInfo(data))
    end
end

function GlobalListen.onSingleChat(mainCmd, subCmd, data)
    EventManager:raiseEvent(GameEvents.EventChatMessage, readMessageInfo(data))
end

function GlobalListen.onRefreshChestCmd(mainCmd, subCmd, data)
    local count = data:readChar()
    local newChests = {}
    for i = 1, count do
        local chestId = data:readInt()
        table.insert(newChests, chestId)
    end
    
    -- 设置模型数据
    local pvpModel = getGameModel():getPvpModel()
    local pvpChestModel = getGameModel():getPvpChestModel()

    for j = 1, count do
        pvpChestModel:addChest(newChests[j])
    end
    
    if #pvpChestModel:getChests() >= 5 then
        pvpModel:setLastChestTime(0)
    else
        pvpModel:setLastChestTime(pvpModel:getLastChestTime() + count * getArenaSetting().Arena_ChestRefresh)
    end

    EventManager:raiseEvent(GameEvents.EventUpdatePvpChest)
end

function GlobalListen.onSDKPaySucess(eventName, args)
    if GlobalListen.verifyPayUpdate then
        scheduler.unscheduleGlobal(GlobalListen.verifyPayUpdate)
        GlobalListen.verifyPayUpdate = nil
    end

    local time = 0
    local timeUpper = (device.platform == "windows" and 10 or 10)
    GlobalListen.verifyPayUpdate = scheduler.scheduleGlobal(function(dt) 
        time = time + 1
        local BufferData = NetHelper.createBufferData(MainProtocol.Pay, PayProtocol.payYSDKCS)
        NetHelper.request(BufferData)
        print("request payYSDKCS " .. time)

        if time >= timeUpper then
            if GlobalListen.verifyPayUpdate then
                scheduler.unscheduleGlobal(GlobalListen.verifyPayUpdate)
                GlobalListen.verifyPayUpdate = nil
            end
            print("paying timeout")
        end
    end, 1)
end

function GlobalListen.onRechargeEvent(eventName, args)
    if GlobalListen.verifyPayUpdate then
        scheduler.unscheduleGlobal(GlobalListen.verifyPayUpdate)
        GlobalListen.verifyPayUpdate = nil
    end
end

function GlobalListen.onRechargeCmd(mainCmd, subCmd, buffData)
    print("============== onPayYSDVerify !!")    
    local result = buffData:readInt()
    local vipLv = buffData:readInt()
    local vipNum = buffData:readInt()
    local diamond = buffData:readInt()  -- 如果是购买月卡下发的是月卡结束的时间戳
    local pID = buffData:readInt()

    print(vipLv, vipNum, diamond, pID)

    if result == 1 then            
        local userModel = getGameModel():getUserModel()
        local shopModel = getGameModel():getShopModel()
        local operateActiveModel = getGameModel():getOperateActiveModel()

        -- 月卡
        if 7 == pID then
            -- 设置月卡到期时间
            local oldStamp = userModel:getMonthCardStamp()
            if diamond > oldStamp then
                userModel:setMonthCardStamp(diamond)
            end
            -- 设置月卡充值时间
            operateActiveModel:setMonthCardChargeTime(1)
            -- 更新货币数量
            local diamondShopData = getDiamondShopConfData()
            local diamond = diamondShopData[7].nDiamond + diamondShopData[7].Extra
            ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, diamond)

            -- 提示月卡购买成功
            local awardData = {}
            UIAwardHelper.formatAwardData(awardData, "dropInfo", {
                id = 2,
                num = diamond
            })
            UIManager.open(UIManager.UI.UIAward, awardData)

            EventManager:raiseEvent(GameEvents.EventBuyMonthCard)
         elseif 8 == pID then    -- 终身月卡
            -- 设置终身卡充值时间
            operateActiveModel:setMonthCardChargeTime(2)

            -- 更新货币数量
            local diamondShopData = getDiamondShopConfData()
            local diamond = diamondShopData[8].nDiamond + diamondShopData[8].Extra
            ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, diamond)

            -- 提示月卡购买成功
            local awardData = {}
            local diamondShopData = getDiamondShopConfData()
            UIAwardHelper.formatAwardData(awardData, "dropInfo", {
                id = 2,
                num = diamond
            })
            UIManager.open(UIManager.UI.UIAward, awardData)
        elseif 9 == pID then    -- 基金
            -- 设置基金购买时间
            userModel:setFundStartFlag(os.time())
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2115))
        else
            -- 设置首次充值状态
            shopModel:setFirstChargeState(pID)
            -- 获得钻石
            local oldDiamond = userModel:getDiamond()
            if diamond > oldDiamond then
                local awardData = {}
                UIAwardHelper.formatAwardData(awardData, "dropInfo", {
                    id = 2,
                    num = diamond - oldDiamond
                })
                UIManager.open(UIManager.UI.UIAward, awardData)
                userModel:setDiamond(diamond)

                EventManager:raiseEvent(GameEvents.EventUpdateDiamond)
            end
        end

        -- 设置充值数额
        local oldVipNum = userModel:getPayment()
        if vipNum > oldVipNum then
            userModel:setPayment(vipNum)
        end

        EventManager:raiseEvent(GameEvents.EventRecharge, {
            result = result,
            vipLv = vipLv,
            vipNum = vipNum,
            diamond = diamond,
            pID = pID,
        })
    else
        printInfo("pay result not success")
    end
end

function GlobalListen.onLookHeroInfo(mainCmd, subCmd, data)
    local heroInfo = {}
    heroInfo.heroID = data:readInt()
    if heroInfo.heroID <= 0 then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2171))
        return
    end

    heroInfo.heroExp = data:readInt()
    heroInfo.heroLv = data:readUChar()
    heroInfo.heroStar = data:readUChar()
    local equipCount = data:readUChar()

    -- 天赋
    heroInfo.talents = {}
    for i = 1, 8 do
        table.insert(heroInfo.talents, data:readUChar())
    end

    -- 装备
    heroInfo.equips = {}
    for j = 1, equipCount do
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

        local eqConf = getEquipmentConfItem(equipInfo.confId)
        if eqConf then
            heroInfo.equips[eqConf.Parts] = equipInfo
        end
    end

    UIManager.open(UIManager.UI.UILookHeroInfo, heroInfo)
end