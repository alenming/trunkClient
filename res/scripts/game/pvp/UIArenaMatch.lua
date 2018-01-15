--[[
竞技场的匹配界面
1、匹配机器人
]]

local Scheduler = require("framework.scheduler")
local UIArenaMatch = class("UIArenaMatch", function ()
	return require("common.UIView").new()
end)

local PvpBattle = require("game.battle.PvpBattle")
local UILang = {predictTime = 1715, priorMatch = 1716, waitTime = 1726}

function UIArenaMatch:createBattleSceneAndReplace()
    print("create battle scene!!!")
    local isBattleOver = self.isBattleOver
    local resultData = self.resultData
    local battleScene = createBattleScene(getGameModel():getRoom())
    battleScene:retain()
    -- 注册Pvp结束回调
    BattleHelper.overPVP(self.isRobot)
    UIManager.closeAll()
	UIManager.clearCache()
    -- 切换战斗场景
    cc.Director:getInstance():replaceScene(battleScene)
    battleScene:release()

    if isBattleOver then
        isBattleOver = false
        print("open battle result ui")
        PvpBattle:openUI(resultData)
    end
end

function UIArenaMatch:ctor()

end

function UIArenaMatch:init()
    self.UICsb = ResConfig.UIArenaMatch.Csb2
    self.rootPath = self.UICsb.arenaMatching
    self.root = getResManager():getCsbNode(self.rootPath)
    self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
    self.root:runAction(self.rootAct)
    self:addChild(self.root)

    self.isRobot = false
    self.isReady = false
    self.isStartRoom = false
    self.isMatch = false
    self.isEnterRoom = false
    self.isBeginLoading = false
    self.start = 1 -- 滚动电脑头像

    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "MainPanel/Button_Cancel")
        , handler(self, self.cancelArenaCallBack), CommonHelper.getUIString(501)
        , "Button_Green/ButtomName", "Button_Green")
    
    self.playerHead = CsbTools.getChildFromPath(self.root, "MainPanel/Arena_PlayerHead")
    self.playerHeadAct = cc.CSLoader:createTimeline(self.UICsb.playerHead)
    self.playerHead:runAction(self.playerHeadAct)

    self.playerHeadInfo = {}
    for i = 1, 3 do
        self.playerHeadInfo[i] = {}
        self.playerHeadInfo[i].img = CsbTools.getChildFromPath(self.playerHead, "HeadPanel/PlayerHeadImage_"..i)
        self.playerHeadInfo[i].level = CsbTools.getChildFromPath(self.playerHead, "HeadPanel/PlayerHeadImage_"..i.."/LevelNum_"..i)
        self.playerHeadInfo[i].name = CsbTools.getChildFromPath(self.playerHead, "PlayerName_"..i)
    end

    self.leftLoadingBar = CsbTools.getChildFromPath(self.root, "PlayerLeft/LoadingBar")
    self.rightLoadingBar = CsbTools.getChildFromPath(self.root, "PlayerRight/LoadingBar")
    self.leftLoadingBar:setPercent(0)
    self.rightLoadingBar:setPercent(0)

    -- 敌对双方名字等级
    self.LvTipsL = CsbTools.getChildFromPath(self.root, "PlayerLeft/LvTips")
    self.LvTipsR = CsbTools.getChildFromPath(self.root, "PlayerRight/LvTips")
    self.playerNameL = CsbTools.getChildFromPath(self.root, "PlayerLeft/PlayerName")
    self.playerLvL = CsbTools.getChildFromPath(self.root, "PlayerLeft/Lv")
    self.playerNameR = CsbTools.getChildFromPath(self.root, "PlayerRight/PlayerName")
    self.playerLvR = CsbTools.getChildFromPath(self.root, "PlayerRight/Lv")
    self.tencentLogoL = CsbTools.getChildFromPath(self.root, "PlayerLeft/TencentLogo")
    self.tencentLogoR = CsbTools.getChildFromPath(self.root, "PlayerRight/TencentLogo")

    -- 匹配提示
    self.waitTimeLb = CsbTools.getChildFromPath(self.root, "MainPanel/LoadingTimeTips")
    self.passTimeLb = CsbTools.getChildFromPath(self.root, "MainPanel/LoadingTimeTips2")
    self.loadTipsLb = CsbTools.getChildFromPath(self.root, "MainPanel/LoadingTips2")

    -- 获取电脑玩家信息
    self.computerConf = getConfArenaComputerItem()
    if not self.computerConf then
        print("getConfArenaComputerItem is nil!!!")
    end
end

-- 战斗结束
function UIArenaMatch:onPvpBattleResult(mainCmd, subCmd, bufferData)
    print("have not enter battle scene, but pvp is over")
    self.isBattleOver = true
    self.resultData = {}
    self.resultData.pvpType = -1
    self.resultData.roomType = bufferData:readInt()
    self.resultData.battleResult = bufferData:readInt()
    self.resultData.integral = bufferData:readInt()
    self.resultData.rankNow = bufferData:readInt()
end

function UIArenaMatch:onOpen(fromUIID, ...)
    -- 注册网络相关回调
    self:registerResponse()

    -- 玩家数据
    local userModel = getGameModel():getUserModel()
    self.userLevel = userModel:getUserLevel()
    self.userName = userModel:getUserName()

    self.summonerID, self.heroList = TeamHelper.getTeamInfo()
    if self.summonerID <= 0 then
        print("local userdefault can't find team")
        self.summonerID = 1500
    end

    self.currentCount = 0
    self.allCount = 0

    self.roomType = getGameModel():getPvpModel():getRoomType()
    --播放打开动画
    self.rootAct:play("Open", false)
    self.rootAct:setFrameEventCallFunc(handler(self, self.openFrameCallBack))
    --打开参数
    self.roomState = select(1, ...) or 0
    --没有参数
    if self.roomState == 0 then
        -- 发送匹配信息
        local BufferData = NetHelper.createBufferData(MainProtocol.PvpMatch, PvpMatchProtocol.MatchCS)
         -- 匹配类型
        BufferData:writeInt(self.roomType)
        NetHelper.request(BufferData)
        print("Send pvp Matching......")
    else
        local battleId = getGameModel():getPvpModel():getPvpInfo().BattleId
        if self.roomState == 2 then
            --还有玩家没进入房间, 切到匹配界面(进入时默认), 发送进入房间请求
            self:sendEnterRoom(battleId)
        elseif self.roomState == 3 
            or self.roomState == 4 then
            --加载中, 切到加载界面
            --重连提示
            self.isStartRoom = true
            self:openReconnectDialog()
            self:sendReconnectRoomData(battleId)
        else
            --异常
            print("get an exception of UIArenaMatch open parameter!")
        end
    end

    self.waitTime = 0
    local predictTime = string.format(CommonHelper.getUIString(UILang.predictTime), 30)
    self.waitTimeLb:setString(predictTime)
    local passTime = string.format(CommonHelper.getUIString(UILang.waitTime), self.waitTime)
    self.passTimeLb:setString(passTime)
    -- 倒计时
    self.scheduleHandler = Scheduler.scheduleGlobal(function(dt)
        self.waitTime = self.waitTime + dt
        -- 已经等待时间
        local passTime = string.format(CommonHelper.getUIString(UILang.waitTime), self.waitTime)
        self.passTimeLb:setString(passTime)
        -- 等待中战斗小提示(5秒随机提示)
        if self.waitTime % 5 == 0 then
            local tipsStr = getLoadingTipsConfItem(math.random(0, getLoadingTipsCount()))
            self.loadTipsLb:setString(tipsStr)
        end

        -- 模拟机器人进度条
        if self.isBeginLoading and self.isRobot then
            local curPercent = self.enemyLoadingBar:getPercent()
            curPercent = curPercent + math.random(0, 25)
            self.enemyLoadingBar:setPercent(curPercent > 100 and 100 or curPercent)
        end
    end, 1.0)

    --self.waitTimeLb:setString("open match UI ... ")
end

function UIArenaMatch:onClose()
    -- 移除网络监听
    for cmd, handler in pairs(self.response) do
        NetHelper.removeResponeHandler(cmd, handler)
    end
    -- 移除事件监听
    EventManager:removeEventListener(GameEvents.EventNetReconnectFinish, self.onReconnectSuccessHandler)

    if self.scheduleHandler then
        Scheduler.unscheduleGlobal(self.scheduleHandler)
        self.scheduleHandler = nil
    end

    MusicManager.stopEffect(self.soundId)
end

function UIArenaMatch:timeUpdate(dt)
    self.waitTime = self.waitTime - dt
    if self.waitTime <= 0 then
        self.waitTimeLb:setString(CommonHelper.getUIString(UILang.priorMatch))
    else
        local predictTime = string.format(CommonHelper.getUIString(UILang.predictTime), self.waitTime)
        self.waitTimeLb:setString(predictTime)
    end
end

function UIArenaMatch:registerResponse()
    self.response = {}
    -- 服务器在匹配中回调
    local matchCmd = NetHelper.makeCommand(MainProtocol.PvpMatch, PvpMatchProtocol.MatchSC)
    self.onMatchHandler = handler(self, self.onResponseMatched)
	NetHelper.setResponeHandler(matchCmd, self.onMatchHandler)
    self.response[matchCmd] = self.onMatchHandler
    -- 重新匹配回调
    local rematchCmd = NetHelper.makeCommand(MainProtocol.PvpMatch, PvpMatchProtocol.RematchSC)
    self.onRematchHandler = handler(self, self.onResponseRematched)
	NetHelper.setResponeHandler(rematchCmd, self.onRematchHandler)
    self.response[rematchCmd] = self.onRematchHandler
    -- 匹配到玩家回调
    local matchPlayerCmd = NetHelper.makeCommand(MainProtocol.PvpMatch, PvpMatchProtocol.MatchSuccessSC)
    self.onMatchSuccess = handler(self, self.onResponseMatchSuccess)
	NetHelper.setResponeHandler(matchPlayerCmd, self.onMatchSuccess)
    self.response[matchPlayerCmd] = self.onMatchSuccess
    -- 取消匹配回调
    local cancelMatchCmd = NetHelper.makeCommand(MainProtocol.PvpMatch, PvpMatchProtocol.CancelSC)
    self.onCancelHandler = handler(self, self.onResponseCancel)
	NetHelper.setResponeHandler(cancelMatchCmd, self.onCancelHandler)
    self.response[cancelMatchCmd] = self.onCancelHandler
    -- 进入房间回调
    local enterRoomCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.EnterRoomSC)
    self.onEnterRoomHandler = handler(self, self.onResponeEnterRoom)
	NetHelper.setResponeHandler(enterRoomCmd, self.onEnterRoomHandler)
    self.response[enterRoomCmd] = self.onEnterRoomHandler
    -- 进入机器人房间回调
    local robotRoomCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.RobotRoomDataSC)
    self.onRobotDataHandler = handler(self, self.onResponeRobotRoomData)
	NetHelper.setResponeHandler(robotRoomCmd, self.onRobotDataHandler)
    self.response[robotRoomCmd] = self.onRobotDataHandler

    -- 开始加载资源回调
    local prepareCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.PrepareSC)
    self.onPrepareHandler = handler(self, self.onResponsePrepare)
	NetHelper.setResponeHandler(prepareCmd, self.onPrepareHandler)
    self.response[prepareCmd] = self.onPrepareHandler
    -- 同步加载信息回调
    local loadingCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.LoadingSC)
    self.onLoadingHandler = handler(self, self.onResponseLoading)
	NetHelper.setResponeHandler(loadingCmd, self.onLoadingHandler)
    self.response[loadingCmd] = self.onLoadingHandler
    -- 加载完成回调
    local readyCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ReadySC)
    self.onReadyHandler = handler(self, self.onResponseReady)
	NetHelper.setResponeHandler(readyCmd, self.onReadyHandler)
    self.response[readyCmd] = self.onReadyHandler
    -- 开始战斗回调
    local startCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.IdleTimeSC)
    self.onStartHandler = handler(self, self.onResponseStart)
	NetHelper.setResponeHandler(startCmd, self.onStartHandler)
    self.response[startCmd] = self.onStartHandler
    --重连
    local startCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ReconnectRoomDataSC)
    self.onReconnectRoomDataHandler = handler(self, self.onResponseReconnectRoomData)
	NetHelper.setResponeHandler(startCmd, self.onReconnectRoomDataHandler)
    self.response[startCmd] = self.onReconnectRoomDataHandler
    -- 房间状态消息
    local reconnectStateCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ReconnectSC)
    self.onRoomState = handler(self, self.onResponseRoomState)
	NetHelper.setResponeHandler(reconnectStateCmd, self.onRoomState)
    self.response[reconnectStateCmd] = self.onRoomState
    
    -- 注册回调监听战斗结束
    local resultCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ResultSC)
    self.onBattleResultCallBack = handler(self, self.onPvpBattleResult)
	NetHelper.setResponeHandler(resultCmd, self.onBattleResultCallBack)
    self.response[resultCmd] = self.onBattleResultCallBack
end

function UIArenaMatch:cancelArenaCallBack(obj)
    --self.waitTimeLb:setString("Cancel match ... ")
    if self.isMatch then
        print("you have matched, can't cancel match!")
        return
    end

    local BufferData = NetHelper.createBufferData(MainProtocol.PvpMatch, PvpMatchProtocol.CancelCS)
	NetHelper.request(BufferData) -- 发送取消匹配挑战
end

function UIArenaMatch:openFrameCallBack(frame)
    if "Open" == frame:getEvent() then
        -- 正常匹配并且还没播
        if 0 == self.roomState then
            if nil == self.soundId then
                self.soundId = MusicManager.playSoundEffect(MusicManager.commonSound.matchRoll)
            end
        end
        self.playerHeadAct:play("LoopQuickly", false)
        self.playerHeadAct:setFrameEventCallFunc(handler(self, self.playerHeadCallBack))
    end
end

function UIArenaMatch:setPlayerHead(index, summonerId, userLv, userName)
    if self.playerHeadInfo[index] == nil then
        return
    end
    -- 将匹配到的玩家头像(美术第一个资源)缓慢移动出现
    local summonerConf = getHeroConfItem(summonerId)
    if summonerConf then
        -- 召唤师头像
        self.playerHeadInfo[index].img:loadTexture(summonerConf.Common.Picture, 1) 
    end
    
    self.playerHeadInfo[index].level:setString(userLv)
    self.playerHeadInfo[index].name:setString(userName)
end

function UIArenaMatch:playerHeadCallBack(frame)
    if frame:getEvent() ~= "LoopEnd" and frame:getEvent() ~= "LastEnd" then 
        return 
    end
    --已进入房间
    if self.isEnterRoom then
        if 0 == self.roomState then
            MusicManager.stopEffect(self.soundId)

            self.soundId = MusicManager.playSoundEffect(MusicManager.commonSound.matchPlayer)
        end
        print("play endSlowly action!!")
        -- 设置第一张图片的信息
        self:setPlayerHead(1, self.enemyInfo.summonerID, self.enemyInfo.usrLv, self.enemyInfo.usrName)
        CommonHelper.playActOverFrameCallBack(
            self.playerHeadAct, 
            "EndSlowly", 
            false, 
            function() 
                self.playerHeadAct:clearFrameEventCallFunc()
                --开始加载
                self.isBeginLoading = true
                if self.isRobot then
                    self:beginLoadingRobot(handler(self, self.loadingFinishCallback))
                else
                    self:beginLoading(handler(self, self.loadingFinishCallback))
                end

            end) 
    else
        -- 不断替换电脑玩家资源(一次三个)
        local computer = 3
        local endPos = self.start + computer - 1
        local pos = 0
        local headIndex = 1
        for i = self.start, endPos do
            pos = i
            if pos > #self.computerConf then
                pos = pos % #self.computerConf + 1
            end
            --设置伪随机的图片信息
            self:setPlayerHead(
                headIndex, 
                0, 
                self:randComputerLevel(self.userLevel), 
                CommonHelper.getUIString(self.computerConf[pos].ComputerName))
            headIndex = headIndex + 1
        end

        self.start = pos + 1
        CommonHelper.playActOverFrameCallBack(
            self.playerHeadAct, 
            "LoopQuickly", 
            false, 
            handler(self, self.playerHeadCallBack)) 
    end
end

function UIArenaMatch:beginLoading(callback)
    MusicManager.stopEffect(self.soundId) 
    self.soundId = MusicManager.playSoundEffect(MusicManager.commonSound.matchLoading)
    -- 开启加载定时器
    self.loadingSchedule = Scheduler.scheduleGlobal(function(dt)
        if type(self.allCount) == "number" and self.allCount > 0 then
            --loading完成
            if self.isReady then
                Scheduler.unscheduleGlobal(self.loadingSchedule)
                self.loadingSchedule = nil
            else
                --发送进度
                local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.LoadingCS)
                BufferData:writeInt(self.currentCount * 100.0 / self.allCount)
                NetHelper.request(BufferData)
            end
        end
    end, 0.2)

    --切到正常界面(重连的时候有用, 正常时无所谓)
    self.playerHeadAct:play("Normal", false)
    --直接切至加载界面
    self.rootAct:play("Loading", false)
    self.rootAct:setFrameEventCallFunc(function(frame)
        local eventName = frame:getEvent()
        if "LoadingOver" == eventName then
            self.rootAct:clearFrameEventCallFunc()
            -- 战斗数据
            openAndinitRoom(self.roomData)
            releaseBufferData(self.roomData)

            -- 获取加载资源进行加载,并发送进度
            SceneManager.addAllPreloadRes(SceneManager.Scene.SceneBattle)
            -- 加载资源回调
            ResLoader.LoadingCallback = function (currentCount, allCount, resName, succuss)
                self.currentCount = currentCount
                self.allCount = allCount
            end
            -- 加载完全部资源回调
            ResLoader.LoadFinishCallback = function () 
                -- 完成加载发送加载完成
                local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.ReadyCS)
                NetHelper.request(BufferData) 
                self.isReady = true
                if "function" == type(callback) then
                    callback()
                end
                -- 加载完成之后，只要出现了断线重连成功，必须发送
                self.onReconnectSuccessHandler = function ()
                    print("send ready")
                    --如果已经加载完成,且游戏状态不为游戏中, 重发准备完成
                    local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.ReadyCS)
                    NetHelper.request(BufferData) 
                end
                EventManager:addEventListener(GameEvents.EventNetReconnectFinish, self.onReconnectSuccessHandler)
            end
            -- 开始加载
            print("Pvp startLoadResAsyn!!!")
            ResLoader.startLoadResAsyn()

        elseif "PlayLeft" == eventName then
            self.summonerLAct:play("Play", false)

        elseif "PlayRight" == eventName then
            self.summonerRAct:play("Play", false)
        end 
    end) 
end

-- 匹配到机器人的loading
function UIArenaMatch:beginLoadingRobot()
    self.playerHeadAct:play("Normal", false)
    --直接切至加载界面
    CommonHelper.playActOverFrameCallBack(self.rootAct, "Loading", false, function(frame)
        local eventName = frame:getEvent()
        if "LoadingOver" == eventName then
            -- 初始化房间战斗数据 c++接口
            openAndinitRoom(self.roomData)
            releaseBufferData(self.roomData)
            local room = getGameModel():getRoom()
            if room ~= nil then
                room:setRobotName(self.enemyInfo.usrName)
            end

            -- 机器人的进度条100%
            --self.enemyLoadingBar:setPercent(100)
            -- 自己的进度条加载
            SceneManager.addAllPreloadRes(SceneManager.Scene.SceneBattle)
            -- 加载资源回调
            ResLoader.LoadingCallback = function (currentCount, allCount, resName, succuss)
                local percent = currentCount * 100.0 / allCount
                self.myLoadingBar:setPercent(percent)
                if percent >= 100 then
                    self.enemyLoadingBar:setPercent(100)
                end
            end
            -- 加载完全部资源进入战斗
            ResLoader.LoadFinishCallback = function () 
                self:createBattleSceneAndReplace(self.isRobot)
            end
            -- 开始加载
            print("Pvp startLoadResAsyn!!!")
            ResLoader.startLoadResAsyn() 
        end
    end)
end

function UIArenaMatch:sendEnterRobotRoom()
    --获得队伍信息
    local summonerID, heroList = TeamHelper.getTeamInfo()
    local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.EnterRobotRoomCS)
    --召唤师id
    bufferData:writeInt(summonerID)
    bufferData:writeInt(#heroList)
    --士兵id
    for _, heroID in pairs(heroList) do
        bufferData:writeInt(heroID)
    end
    NetHelper.request(BufferData)
    print("Send Request Enter Robot Room ...")
end

-- 匹配到机器人返回房间信息
function UIArenaMatch:onResponeRobotRoomData(mainCmd, subCmd, data)
    print("robot room data recive ...........")
    self.isStartRoom = true
    self.roomData = cloneBufferData(data)
end

function UIArenaMatch:randComputerLevel(level)
    local seed = os.time() * os.time()
	math.randomseed(seed)
    local randLevel = level + math.random(-2, 2)
    if randLevel <= 0 then
        randLevel = 1
    end
    return randLevel
end

--发送进入房间
function UIArenaMatch:sendEnterRoom(battleId)
    --self.waitTimeLb:setString("Send enter room ... ")
    local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.EnterRoomCS)
    bufferData:writeInt(battleId)
    bufferData:writeInt(self.roomType)
    bufferData:writeInt(self.summonerID)
    bufferData:writeInt(#self.heroList)
    for _, heroID in pairs(self.heroList) do
        bufferData:writeInt(heroID)
    end
    NetHelper.request(BufferData)
    print("Send Request Enter Room ...")
end

--重连对话框
function UIArenaMatch:openReconnectDialog()
    local reconnectText = CommonHelper.getUIString(839)
    local btnText =  CommonHelper.getUIString(836)
    local dialog = getResManager():getCsbNode(self.UICsb.reconnect)
    self:addChild(dialog)
    CommonHelper.layoutNode(dialog)

    local tips = CsbTools.getChildFromPath(dialog, "MainPanel/TipsPanel/Tips")
    local button = CsbTools.getChildFromPath(dialog, "MainPanel/TipsPanel/Button_Cancel")
    local buttonText = CsbTools.getChildFromPath(dialog, "MainPanel/TipsPanel/Button_Cancel/Button_Green/ButtomName")

    tips:setString(reconnectText)
    CsbTools.initButton(button, function() 
            dialog:removeFromParent()
        end, btnText, buttonText, button)
end

--请求重连的房间信息
function UIArenaMatch:sendReconnectRoomData(battleId)
    --self.waitTimeLb:setString("Request Reconnect Room Data ...")
    print("Send Reconnect Room Data")
    local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.ReconnectRoomDataCS)
    bufferData:writeInt(battleId)
    NetHelper.request(BufferData)
end

function UIArenaMatch:onResponseMatched(mainCmd, subCmd, data)
    --self.waitTimeLb:setString("Server Matching ...")
    print("Server is matching......")
end

function UIArenaMatch:onResponseRematched(mainCmd, subCmd, data)
    --self.waitTimeLb:setString("PVP Rematch ...")
    print("PVP Rematch ...")
    self.isMatch = false
    --重新发送匹配请求
    local BufferData = NetHelper.createBufferData(MainProtocol.PvpMatch, PvpMatchProtocol.MatchCS)
    BufferData:writeInt(self.roomType)
    NetHelper.request(BufferData)
end

--匹配成功回调
function UIArenaMatch:onResponseMatchSuccess(mainCmd, subCmd, data)
    --self.waitTimeLb:setString("Match Success, Send Enter Room ...")
    print("Match Success, Send Enter Room")
    self.isMatch = true

    local battleId = data:readInt()
    local robotId = data:readInt()

    if robotId == 0 then
        self:sendEnterRoom(battleId)
    else
        self.isRobot = true
        self:sendEnterRobotRoom()
    end
end

function UIArenaMatch:onResponseCancel(mainCmd, subCmd, data)
    --self.waitTimeLb:setString("Cancel match success!! Change scene......")
    print("Cancel match success!! Change scene......")
    CommonHelper.playActOverFrameCallBack(self.rootAct, "Cancel", false, function ()
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end) 
end

-- 进入房间成功, 需要区别是否是机器人
function UIArenaMatch:onResponeEnterRoom(mainCmd, subCmd, data)
    --self.waitTimeLb:setString("server respone onResponeEnterRoom ")
    local result = data:readInt() -- 进房间结果
    if 1 == result then
        self.enemyInfo = {}
        self.myCamp = data:readInt()
        self.enemyInfo.uid = data:readInt()
        self.enemyInfo.usrLv = data:readInt()
        self.enemyInfo.summonerID = data:readInt()
        self.enemyInfo.integral = data:readInt()
        self.enemyInfo.progress = data:readInt()
        self.enemyInfo.userIdentity = data:readInt()
        self.enemyInfo.usrName = data:readCharArray(32)

        print("====================== opponent name "..self.enemyInfo.usrName)
        print("PVP EnterRoom Success!!!result, myCamp", result, self.myCamp)
        
        if self.isRobot then
            --这是bossId, 需要转换成召唤师ID
            local bossId = self.enemyInfo.summonerID
            local bossConf = getBossConfItem(bossId)

            self.enemyInfo.summonerID = string.match(bossConf.Common.Picture, "%d+")
            print("match robot and translate boss id to summonerId", bossId, self.enemyInfo.summonerID)
        end

        self:createEachSummoner()
        self.isEnterRoom = true
    else
        print("PVP EnterRoom Fail!!!", result)
    end
end

-- 开始加载
function UIArenaMatch:onResponsePrepare(mainCmd, subCmd, data)
    print("Pvp Prepare, init room!!!Loading......")
    self.roomData = cloneBufferData(data)
end

function UIArenaMatch:onResponseLoading(mainCmd, subCmd, data)
    local uid = data:readInt()
    local progress = data:readInt()
    -- 进度条
    if self.enemyInfo.uid == uid then
        self.enemyLoadingBar:setPercent(progress)    
    else
        self.myLoadingBar:setPercent(progress)    
    end
end

function UIArenaMatch:onResponseReady(mainCmd, subCmd, data)
    local uid = data:readInt()
    print(uid, "Player is Ready!!!")
end

function UIArenaMatch:onResponseStart(mainCmd, subCmd, data)
    local stamp = data:readInt()
    print("Pvp Start! replace battle scene, time:", stamp)
    if self.isReady then
        self:createBattleSceneAndReplace()
    else
       --等待客户端慢慢加载
       --进入游戏后处理与游戏大重连一样
       self.isStartRoom = true
       getGameModel():getPvpModel():setReconnect(1)
    end
end

-- 需要刷新
function UIArenaMatch:onResponseRoomState(mainCmd, subCmd, data)
    local roomState = data:readInt()
    local roomType = data:readInt()
    -- 已经在战斗中，需要刷新
    if roomState == 5 then
        getGameModel():getPvpModel():setReconnect(1)
    end
end

function UIArenaMatch:onResponseReconnectRoomData(mainCmd, subCmd, data)
    print("Recv Reconnect Room Data, Loading Room")
    --重连信息
    self:setPlayerHead(1, self.enemyInfo.summonerID, self.enemyInfo.usrLv, self.enemyInfo.usrName)
    self.enemyLoadingBar:setPercent(self.enemyInfo.progress)  
    self.roomData = cloneBufferData(data)
    --如果在战斗中了, 加载完就切场景, 否则等待服务器start再切场景
    if self.roomState == 4 then
        --战斗内获得, 由此知道是大重连进入游戏
        getGameModel():getPvpModel():setReconnect(1)
    end
    
    self:beginLoading(handler(self, self.loadingFinishCallback))
end

function UIArenaMatch:loadingFinishCallback()
    if self.isStartRoom and self.isReady then
         self:createBattleSceneAndReplace()
    end
end

function UIArenaMatch:createEachSummoner()
    -- 区分左右位置(1为蓝方左,2为红方右)
    local leftSummonerId = 0
    local rightSummonerId = 0
   
    if 1 == self.myCamp then
        -- 如果我在蓝色方
        self.playerNameL:setString(self.userName)
        self.playerNameR:setString(self.enemyInfo.usrName)
        self.playerLvL:setString(self.userLevel)
        self.playerLvR:setString(self.enemyInfo.usrLv)

        leftSummonerId = self.summonerID
        rightSummonerId = self.enemyInfo.summonerID
        self.myLoadingBar = self.leftLoadingBar
        self.enemyLoadingBar = self.rightLoadingBar

        CommonHelper.showBlueDiamond(self.tencentLogoL)
        CommonHelper.showBlueDiamond(self.tencentLogoR, CommonHelper.getIdentity(self.enemyInfo.userIdentity))
    else
        --如果我在红色方   
        self.playerNameL:setString(self.enemyInfo.usrName)
        self.playerNameR:setString(self.userName)
        self.playerLvL:setString(self.enemyInfo.usrLv)
        self.playerLvR:setString(self.userLevel)

        leftSummonerId = self.enemyInfo.summonerID
        rightSummonerId = self.summonerID
        self.myLoadingBar = self.rightLoadingBar
        self.enemyLoadingBar = self.leftLoadingBar
        
        CommonHelper.showBlueDiamond(self.tencentLogoL, CommonHelper.getIdentity(self.enemyInfo.userIdentity))
        CommonHelper.showBlueDiamond(self.tencentLogoR)
    end

--    if 1 == self.roomType then
--        self.playerLvL:setVisible(false)
--        self.playerLvR:setVisible(false)
--        self.LvTipsL:setVisible(false)
--        self.LvTipsR:setVisible(false)
--    end

    local nodeL = CsbTools.getChildFromPath(self.root, "MainPanel/SummonerPanel/Summoner_Left")
    local nodeR = CsbTools.getChildFromPath(self.root, "MainPanel/SummonerPanel/Summoner_Right")
    local summonerCsbL = "ui_new/g_gamehall/a_arena/summoner/Summoner_"..leftSummonerId.."_L.csb"
    local summonerCsbR = "ui_new/g_gamehall/a_arena/summoner/Summoner_"..rightSummonerId.."_R.csb"
    local summonerL = getResManager():getCsbNode(summonerCsbL)
    local summonerR = getResManager():getCsbNode(summonerCsbR)
    self.summonerLAct = cc.CSLoader:createTimeline(summonerCsbL)
    self.summonerRAct = cc.CSLoader:createTimeline(summonerCsbR)
    summonerL:runAction(self.summonerLAct)
    summonerR:runAction(self.summonerRAct)
    nodeL:addChild(summonerL)
    nodeR:addChild(summonerR)
end

return UIArenaMatch
