--[==[
热更新完成后的界面显示: (这里不是一个UI界面, 只是管理一个UI)
1. 游戏按钮
2. 切换帐号 
3. 选择服务器
-- 该界面尽量不要热更新
]==]

local UpdateOverViewHelper = class("UpdateOverViewHelper")

require ("game.login.ServerConfig")
require("common.PushManager")
local SdkManager = require("common.sdkmanager.SdkManager")

local CONN_TYPE = { session = 0, chat = 1 }
local SOCK_VERSION= { ipv4 = 0, ipv6 = 1 }

local uiType = {
	Null = 0,
    SDKInit                 = 1, -- sdk进入初始化
    SKDInitSucess           = 2, -- sdk初始化成功
    SDKInitFail             = 3, -- sdk初始化失败
    SDKLogin                = 4, -- sdk登陆
    SDKLoginSucess          = 5, -- sdk登陆成功
    SDKLoginNetError        = 6, -- sdk登陆失败    
    SDKLoginCancel          = 7, -- sdk取消登陆
    SDKLoginFail            = 8, -- sdk登陆失败
    --SDKLogoutSucess         = 9, -- sdk注销成功
    SDKLogoutFail           = 10,-- sdk注销失败
    SDKAccountSwitch        = 11,-- 切换帐号
    SDKAccountSwitchCancel  = 12,-- 账户切换取消
    SDKAccountSwitchFail    = 13,-- 账户切换失败
    ConnectToServer         = 14,-- 连接服务器
    ConnectToServerSucess   = 15,-- 链接服务器成功
    ConnectToServerFail     = 16,-- 链接服务器失败
    LoginCheck              = 17,-- 链接确认
    LoginCheckSucess        = 18,-- 链接确认成功
    ModelInit               = 19,-- 模型初始化
    ModelInitSucess         = 20,-- 模型初始化成功
    EnterGame               = 21,-- 进入游戏
    Maintain                = 22,-- 游戏维护
    QQHallVerify            = 23,-- QQ大厅登陆验证
    QQHallVerifySucess      = 24,-- QQ大厅登陆验证成功
    QQHallVerifyFail        = 25,-- QQ大厅登陆验证失败
}

gServerID = cc.UserDefault:getInstance():getIntegerForKey("ServerId")
if not gServerID or 0 == gServerID then
    gServerID = 1
    cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
end

--游客对应的uid key
function guestUidKey()
    return "g-uid-"..gServerID
end
--游客对应的password key
local function guestPasswordKey()
    return "g-pw-"..gServerID        
end

function UpdateOverViewHelper:ctor(loginCsb, maintain)
    -- 保存维护信息
    self.maintain = maintain
    dump(self.maintain or {}, "维护信息")

	-- 进度条相关面板
    self.barLayout = CsbTools.getChildFromPath(loginCsb, "MainPanel/UpdateLoading")
    -- 进度条
    self.loadingBar = CsbTools.getChildFromPath(self.barLayout, "LoadingBar")
    -- 进度条背景
    self.barBgImg = CsbTools.getChildFromPath(self.barLayout, "LoadingBg")
    -- 进度条提示
    self.tipsLab = CsbTools.getChildFromPath(self.barLayout, "LoadingTips")
    -- 进度条进度
    self.barLab = CsbTools.getChildFromPath(self.barLayout, "LoadingNum")
    -- 登陆面板
    self.loginLayout = CsbTools.getChildFromPath(loginCsb, "MainPanel/OnlineMode")
    -- 进入游戏文字图片
    self.enterGameSpr = CsbTools.getChildFromPath(self.loginLayout, "Login_EnterText_1")
    -- 切换帐号按钮
    self.changeAccountBtn = CsbTools.getChildFromPath(self.loginLayout, "ChangeUserButton")
    -- 进入游戏 闪烁动画
    local action = cc.FadeOut:create(2)
    local actionBack = action:reverse()
    self.enterGameSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(action, actionBack)))

 	CsbTools.initButton(self.loginLayout, handler(self, self.enterGameBtnCallBack))
    CsbTools.initButton(self.changeAccountBtn, handler(self, self.changeAccountBtnCallBack), 
        nil, nil, "Button_Enter")

    self.loadingBarWidth = self.loadingBar:getContentSize().width
    self.cmdLine = getCmdLine()

    self:changeShowUI(uiType.Null)
    self:setServerInfo()
    self:initListener()

    --初始化sdk
    if device.platform == "android" or device.platform == "ios" then
        self:changeShowUI(uiType.SDKInit)
        SdkManager.init()
    elseif gIsQQHall then
        PlatformModel.loginType = "QQHall"
        PlatformModel.pfType = 1
        PlatformModel.openId = self.cmdLine.ID
        PlatformModel.token = self.cmdLine.Key

        self:requestQQHallVerify()
    else
        self:changeShowUI(uiType.SDKLoginSucess)
        self.userId = cc.UserDefault:getInstance():getIntegerForKey("UserId", 666666666)
        print("当前userId " .. self.userId)
    end
end

function UpdateOverViewHelper:close()
    self:removeListener()
end

function UpdateOverViewHelper:initListener()
    self:removeListener()

    -- 注册监听的事件
    self.eventInfo = {}

    self.eventInfo[GameEvents.EventSDKInitSucess] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKInitFail] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKLoginSucess] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKLoginNetError] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKLoginCancel] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKLoginFail] = handler(self, self.onEvent)
    --self.eventInfo[GameEvents.EventSDKLogoutSucess] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKLogoutFail] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKAccountSwitchCancel] = handler(self, self.onEvent)
    self.eventInfo[GameEvents.EventSDKAccountSwitchFail] = handler(self, self.onEvent)
    -- 网络连接成功
    self.eventInfo[GameEvents.EventNetConnectSuccess] = handler(self, self.onEvent)
    -- 网络连接失败
    self.eventInfo[GameEvents.EventNetConnectFailed] = handler(self, self.onEvent)
    -- 重连
    self.eventInfo[GameEvents.EventNetReconnect] = handler(self, self.onEvent)
    
    for eventID, eventHandler in pairs(self.eventInfo) do
        EventManager:addEventListener(eventID, eventHandler)
    end
    
    -- 注册登录验证命令
    local cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginCheckSC)
    self.loginCheckHandler = handler(self, self.onLoginCheck)
    NetHelper.setResponeHandler(cmd, self.loginCheckHandler)
    -- 注册被封命令, 单独监听
    self.banHandler = handler(self, self.onBan)
    cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.BanSC)
    NetHelper.setResponeHandler(cmd, self.banHandler)  
end

function UpdateOverViewHelper:registerLoginModel()
    for _, v in ipairs(self.loginSubCmds or {}) do
        cmd = NetHelper.makeCommand(MainProtocol.Login, v)
        NetHelper.removeResponeHandler(cmd, self.loginHandler)
    end

    -- 注册登录命令
    self.isGetFinishSC = false
    self.loginHandler = handler(self, self.onLogin)
    self.loginSubCmds = {}
    for i = LoginProtocol.LoginFinishSC, LoginProtocol.LoginBlueGemSC do
        -- 被踢和被顶已经在GlobalListen里面监听了, 被封使用另一个监听
        if i ~= LoginProtocol.TickSC and 
            i ~= LoginProtocol.RechangeSC and 
            i ~= LoginProtocol.BanSC and
            i ~= LoginProtocol.LoginChatSC and
            i ~= LoginProtocol.InstanceModelSC and
            i ~= LoginProtocol.TowerTestModelSC then

            cmd = NetHelper.makeCommand(MainProtocol.Login, i)
            NetHelper.setResponeHandler(cmd, self.loginHandler)
            table.insert(self.loginSubCmds, i)
        end
    end
end

function UpdateOverViewHelper:removeListener()
    for eventID, eventHandler in pairs(self.eventInfo or {}) do
        EventManager:removeEventListener(eventID, eventHandler)
    end

    -- 注销登录验证命令
    local cmd = nil
    if self.loginCheckHandler then
        cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginCheckSC)
        NetHelper.removeResponeHandler(cmd, self.loginCheckHandler)
        self.loginCheckHandler = nil
    end

    for _, v in ipairs(self.loginSubCmds or {}) do
        cmd = NetHelper.makeCommand(MainProtocol.Login, v)
        NetHelper.removeResponeHandler(cmd, self.loginHandler)
    end
    self.loginSubCmds = {}
    self.loginHandler = nil

    if self.banHandler then
        cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.BanSC)
        NetHelper.removeResponeHandler(cmd, self.banHandler)
        self.banHandler = nil
    end
end

function UpdateOverViewHelper:changeShowUI(showType)
    print("UpdateOverViewHelper:changeShowUI pre, cur", self.curUIType, showType)
    
    self.barLayout:setVisible(true)
    self.tipsLab:setVisible(true)
    self.loadingBar:setVisible(false)
    self.barBgImg:setVisible(false)
    self.barLab:setVisible(false)
    self.changeAccountBtn:setVisible(false)

    self.curUIType = showType
    if showType == uiType.Null then
        return
    end

    if showType == uiType.SDKInit then
        self.tipsLab:setString("SDK 初始化中")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.SKDInitSucess then
        self.tipsLab:setString("SDK 初始化成功")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.SDKInitFail then
        self.tipsLab:setString("SDK 初始化失败")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKLogin then
        self.tipsLab:setString("SDK 登陆中")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.SDKLoginSucess then
        self.tipsLab:setString("")
        self.loginLayout:setVisible(true)

        if self:autoPopNotic() then
            return
        end

        if device.platform ~= "ios" and (not gIsQQHall) then
            self.changeAccountBtn:setVisible(true)
        end

    elseif showType == uiType.SDKLoginNetError then
        self.tipsLab:setString("SDK 网络错误")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKLoginCancel then
        self.tipsLab:setString("SDK 取消登陆")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKLoginFail then
        self.tipsLab:setString("SDK 登陆失败")
        self.loginLayout:setVisible(true)

    -- elseif showType == uiType.SDKLogoutSucess then
    --     self.tipsLab:setString("SDK 登出成功")
    --     self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKLogoutFail then
        self.tipsLab:setString("SDK 登出失败")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKAccountSwitch then
        self.tipsLab:setString("SDK 切换帐号")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.SDKAccountSwitchCancel then
        self.tipsLab:setString("SDK 取消帐号切换")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.SDKAccountSwitchFail then
        self.tipsLab:setString("SDK 帐号切换失败")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.ConnectToServer then
        self.tipsLab:setString("连接服务器中")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.ConnectToServerSucess then
        self.tipsLab:setString("连接服务器成功")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.ConnectToServerFail then
        self.tipsLab:setString("连接服务器失败")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.LoginCheck then
        self.tipsLab:setString("获取帐号数据")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.LoginCheckSucess then
        self.tipsLab:setString("获取帐号数据成功")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.ModelInit then
        self.tipsLab:setString("模型初始化中")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.ModelInitSucess then
        self.tipsLab:setString("模型初始化成功")
        self.loginLayout:setVisible(false)

    elseif showType == uiType.Maintain then
        self.tipsLab:setString("游戏维护中")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.EnterGame then
        self.loginLayout:setVisible(false)
        self.loadingBar:setVisible(true)
        self.barBgImg:setVisible(true)
        self.barLab:setVisible(true)

    elseif showType == uiType.QQHallVerify then
        self.tipsLab:setString("QQ大厅登陆验证")
        self.loginLayout:setVisible(false)
        if self:autoPopNotic() then
            return
        end

    elseif showType == uiType.QQHallVerifySucess then
        self.tipsLab:setString("QQ大厅登陆验证成功")
        self.loginLayout:setVisible(true)

    elseif showType == uiType.QQHallVerifyFail then
        self.tipsLab:setString("QQ大厅登陆验证失败")
        self.loginLayout:setVisible(true)
    end
end

function UpdateOverViewHelper:onEvent(eventName, args)
    print("UpdateOverViewHelper:onEvent", eventName)
    CsbTools.printValue(args, "eventArgs")

    if eventName == GameEvents.EventSDKInitSucess then
        self:changeShowUI(uiType.SKDInitSucess)
        self:loginSDK()

    elseif eventName == GameEvents.EventSDKInitFail then
        self:changeShowUI(uiType.SDKInitFail)

    elseif eventName == GameEvents.EventSDKLoginSucess then
        self:changeShowUI(uiType.SDKLoginSucess)

        self.channelName = args.channelName
        PlatformModel.loginType = "SDKLogin"
        PlatformModel.pfType = args.pfType
        PlatformModel.openId = args.openId
        PlatformModel.token = args.token
        httpAnchor(4001)

    elseif eventName == GameEvents.EventSDKLoginNetError then
        self:changeShowUI(uiType.SDKLoginNetError)

    elseif eventName == GameEvents.EventSDKLoginCancel then
        self:changeShowUI(uiType.SDKLoginCancel)

    elseif eventName == GameEvents.EventSDKLoginFail then
        self:changeShowUI(uiType.SDKLoginFail)

    -- elseif eventName == GameEvents.EventSDKLogoutSucess then
    --     self:changeShowUI(uiType.SDKLogoutSucess)

    elseif eventName == GameEvents.EventSDKLogoutFail then
        self:changeShowUI(uiType.SDKLogoutFail)

    elseif eventName == GameEvents.EventSDKAccountSwitchCancel then
        self:changeShowUI(uiType.SDKAccountSwitchCancel)

    elseif eventName == GameEvents.EventSDKAccountSwitchFail then
        self:changeShowUI(uiType.SDKAccountSwitchFail)

    elseif eventName == GameEvents.EventNetConnectSuccess then
        self:requsetLogin()

    elseif eventName == GameEvents.EventNetConnectFailed then
        self:changeShowUI(uiType.ConnectToServerFail)
    elseif eventName == GameEvents.EventNetReconnect then
        if args == 0 then
            self:changeShowUI(uiType.ConnectToServerFail)
        else
            self:requsetLogin()
        end
    end
end

function UpdateOverViewHelper:requsetLogin()
    self:registerLoginModel()

    self:changeShowUI(uiType.ConnectToServerSucess)
    cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
    --连接成功发送验证消息
    if not PlatformModel.pfType
     or not PlatformModel.openId
     or not PlatformModel.token then
        print("PlatformModel.pfType, PlatformModel.openId, PlatformModel.token",
            PlatformModel.pfType, PlatformModel.openId, PlatformModel.token)
        return
    end

    if device.platform == "android" or device.platform == "ios" or gIsQQHall then
        if SdkManager.TargetUserPlugin ~= SdkManager.SDKType.UNKNOWN or gIsQQHall then
            local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckPfCS)
            BufferData:writeInt(PlatformModel.pfType)
            BufferData:writeCharArray(PlatformModel.openId, 128)
            BufferData:writeCharArray(PlatformModel.token, 256)
            NetHelper.request(BufferData)
        else    
            --[[ 游客登录
            local deviceId = cc.UserDefault:getInstance():getStringForKey("DeviceIdentifier")
            local cryptID = cryptoMd5(deviceId)
            print("device id: " .. cryptID)
            local password = cryptoMd5("fanhouzhs" .. cryptID .. "yueliushui10yi")
            local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckGuestCS)
            BufferData:writeCharArray(cryptID, 40)
            BufferData:writeCharArray(password, 32)
            NetHelper.request(BufferData)
            --]]

            UIManager.open(UIManager.UI.UILoginAccountInput)
        end
    else
        local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckTestCS)
        BufferData:writeInt(self.userId)
        NetHelper.request(BufferData)
    end

    self:changeShowUI(uiType.LoginCheck)
end

function UpdateOverViewHelper:loginSDK()
    self:changeShowUI(uiType.SDKLogin)
    if SdkManager.TargetUserPlugin == SdkManager.SDKType.UNKNOWN then
        -- 没有用户插件，默认走游客登录
        self:changeShowUI(uiType.SDKLoginSucess)
    else
        SdkManager.login()
    end
end

-- 弹出公告, 需要弹出返回true, 不需要则返回false
function UpdateOverViewHelper:autoPopNotic()
    if self.maintain then
        local curTime = os.time()
        local startTime = self.maintain.startTime
        local endTime = self.maintain.endTime
        local message = self.maintain.message
        if curTime >= startTime and curTime <= endTime then
            self:changeShowUI(uiType.Maintain)
            updateHelper.sceneAddNotice(message)
            return true
        end
    end
	updateHelper.sceneRemoveNotice()
    return false
end

function UpdateOverViewHelper:setServerInfo()
    local serverConfig = ServerConfig[gServerID]
    if nil == serverConfig then
        gServerID = 1
        serverConfig = ServerConfig[gServerID]
        cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
    end
    self.ip = serverConfig.Ip
    self.port = serverConfig.Port
    print("server info: ", gServerID, self.ip, self.port)
end

-- 进入游戏
function UpdateOverViewHelper:enterGameBtnCallBack(obj)
    print("UpdateOverViewHelper:enterGameBtnCallBack")

    if self.curUIType == uiType.SDKInitFail then
        self:changeShowUI(uiType.SDKInit)
        SdkManager.init()

    elseif self.curUIType == uiType.SDKLoginNetError or
        self.curUIType == uiType.SDKLoginCancel or
        self.curUIType == uiType.SDKLoginFail or
        self.curUIType == uiType.SDKAccountSwitchFail or
        self.curUIType == uiType.SDKLogoutFail then

        self:loginSDK()

    elseif self.curUIType == uiType.SDKLoginSucess or 
        self.curUIType == uiType.SDKAccountSwitchCancel or
        self.curUIType == uiType.ConnectToServerFail or
        self.curUIType == uiType.QQHallVerifySucess then

        if self:autoPopNotic() then
            return
        end
        if self.curUIType == uiType.ConnectToServerFail then
            reconnectToServer(0)
            
        else
            connectToServer(self.ip, self.port, CONN_TYPE.session, SOCK_VERSION.ipv6)
        end
        self:changeShowUI(uiType.ConnectToServer)

        PlatformModel.host = self.ip
        PlatformModel.port = self.port
        httpAnchor(5001)

    elseif self.curUIType == uiType.Maintain then
        if not self:autoPopNotic() then
            if gIsQQHall then
                self:changeShowUI(uiType.QQHallVerifySucess)
            else
                self:changeShowUI(uiType.SDKLoginSucess)
            end
        end

    elseif self.curUIType == uiType.QQHallVerifyFail then
        self:requestQQHallVerify()
    end
end

-- 切换帐号
function UpdateOverViewHelper:changeAccountBtnCallBack(obj)
    if device.platform == "android" or device.platform == "ios" then
        if self.curUIType == uiType.SDKLoginSucess then
            self:changeShowUI(uiType.SDKAccountSwitch)
            SdkManager.switchAccount()
        end
	else
        self:changeShowUI(uiType.SDKAccountSwitch)
        math.randomseed(os.time())
		self.userId = math.random(1, 999999999)
		cc.UserDefault:getInstance():setIntegerForKey("UserId", self.userId)
    	print("随机userId " .. self.userId)

        require("app.SummonerUpdateApp").new():run()
        EventManager:raiseEvent(GameEvents.EventSDKLogoutSucess, {})
	end
end

function UpdateOverViewHelper:onLoginCheck(mainCmd, subCmd, buffData)
    self:changeShowUI(uiType.LoginCheckSucess)

    if device.platform ~= "android" and device.platform ~= "ios" and (not gIsQQHall) then        
        initUserId(self.userId)
        self:sendLoginAndUnion()
        return
    end

    self.userId = buffData:readInt()
    self.isNewUser = buffData:readInt()
    self.isGuest = buffData:readInt()
    local deviceModel = cc.UserDefault:getInstance():getStringForKey("DeviceModel") or ""

    if self.isNewUser ~= 0 and gIsQQHall then
        QQHallHelper.requestHttp(QQHallHelper.requestType.register)
    end

    print("userId ", self.userId)
    print("isNewUser ", self.isNewUser)
    print("isGuest ", self.isGuest)
    print("pfType ", PlatformModel.pfType)
    print("openId ", PlatformModel.openId)
    print("deviceModel ", deviceModel)

    if self.userId < 0 then
        EventManager:raiseEvent(GameEvents.EventLoginResult, "fail")

        httpAnchor(5002)
        self.tipsLab:setString("用户数据错误 " .. self.userId .. " " .. self.isNewUser .. " " .. self.isGuest ..
            " " .. PlatformModel.pfType .. " " .. PlatformModel.openId .. " " .. deviceModel)
    else
        EventManager:raiseEvent(GameEvents.EventLoginResult, "success")

        if self.isGuest == 0 then
            local BuffData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginUserInfoCS)
            BuffData:writeInt(self.isGuest)
            BuffData:writeInt(self.userId)
            BuffData:writeInt(self.isNewUser)
            BuffData:writeInt(PlatformModel.pfType)
            BuffData:writeCharArray(PlatformModel.openId, 128)
            BuffData:writeCharArray(deviceModel, 40)
            NetHelper.request(BuffData)
        end
        initUserId(self.userId)
        self:sendLoginAndUnion()
        httpAnchor(5003)
    end

    if self.isNewUser == 1 then
        cc.UserDefault:getInstance():setIntegerForKey(guestUidKey(), self.userId)
        PushManager:getInstance():setRegisterTime(os.time())
    end

    if device.platform == "android" or device.platform == "ios" then
        buglySetUserId(tostring(self.userId))
        buglySetTag(self.loginType)
    end
end

gRequestQQHallVerifyCallBack = nil

function UpdateOverViewHelper:onReadyStateChanged(code, data)
    if code == 200 then
        local json = require("game.update.json")
        local output = json.decode(data)
        table.foreach(output,function(i, v) print ("QQHallVerify: ", i, v) end)

        if output.ret == "0" or output.ret == 0 then
            self:changeShowUI(uiType.QQHallVerifySucess)
        else
            self:changeShowUI(uiType.QQHallVerifyFail)
        end
    else
        self:changeShowUI(uiType.QQHallVerifyFail)
        print("code, data:", code, data)
    end
end

function UpdateOverViewHelper:requestQQHallVerify()
    self:changeShowUI(uiType.QQHallVerify)

    local url = "2dfcb7-0.gz.1251013877.clb.myqcloud.com/front/QQGame/login"
    url = url .. "?openid=" .. self.cmdLine.ID .. "&openkey=" .. self.cmdLine.Key
    gRequestQQHallVerifyCallBack = handler(self, self.onReadyStateChanged)
    requestHttpWithCallback(url, "", "gRequestQQHallVerifyCallBack")
end

function UpdateOverViewHelper:sendLoginAndUnion()
    self:changeShowUI(uiType.ModelInit)
    --发送登录消息
    local buffData1 = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCS)
    buffData1:writeInt(self.userId)
    NetHelper.request(buffData1)
    -- 发送公会登录消息
    local buffData2 = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginUnionCS)
    buffData2:writeInt(self.userId)
    NetHelper.request(buffData2)
end

function UpdateOverViewHelper:onLogin(mainCmd, subCmd, buffData)
    print("接受登录返回" .. mainCmd .. " - " .. subCmd)

    if mainCmd == MainProtocol.Login then
        if mainCmd == MainProtocol.Login then
            if subCmd == LoginProtocol.LoginFinishSC then
                self.isGetFinishSC = true
                -- 连接聊天服务器
                print("connect to chat server!!!!!!")
                ChatHelper.connectToChatServer()
            else
                initModelData(subCmd, buffData)
            end
        end
    end

    for i, v in ipairs(self.loginSubCmds) do
        if v == subCmd then
            NetHelper.removeResponeHandler(NetHelper.makeCommand(mainCmd, subCmd), self.loginHandler)
            table.remove(self.loginSubCmds, i)
            break
        end
    end

    -- 将所有注册的协议接收完跳转
    if #self.loginSubCmds == 0 and self.isGetFinishSC then
        self:changeShowUI(uiType.ModelInitSucess)
        self.loadingBar:setPercent(0)
        self.barLab:setString("0%")
        self:enterGame()
    end
end

function UpdateOverViewHelper:onBan(mainCmd, subCmd, buffData)
    print("fuck 号被封了")

    local timestamp = buffData:readInt()
    local year = os.date("%Y", timestamp)
    local month = os.date("%m", timestamp)
    local day = os.date("%d", timestamp)
    local hour = os.date("%H", timestamp)
    local min = os.date("%M", timestamp)

    local args = {}
    args.msg = string.format(CommonHelper.getErrorCodeString(802), year, month, day, hour, min)
    args.confirmFun = function ()       
        closeGame()
    end
    args.cancelFun = function ()
        closeGame()
    end
    UIManager.open(UIManager.UI.UIDialogBox, args)
end

function UpdateOverViewHelper:enterGame()
    self:changeShowUI(uiType.EnterGame)
    cc.UserDefault:getInstance():setIntegerForKey("LoginTime", os.time())
    QQHallHelper.requestHttp(QQHallHelper.requestType.login, "level=" .. getGameModel():getUserModel():getUserLevel())
    if not gLoginInitGame then
        gLoginInitGame = true
        UserDatas.init()
        ChatHelper.init()
        TaskManage.init()
        AchieveManage.init()
        RedPointHelper.init()
        ModelHelper.init()
        RankData.init()
        NetworkTips.init()
        ConnectionTips.init()
        MarqueeHelper.init()
    end

	math.randomseed(os.time())
    local ran = math.random(getLoadingTipsCount())
    local str = getLoadingTipsConfItem(math.max(1, ran))
    self.tipsLab:setString(str)

    --引导监听
    require("guide.GuideManager")
    GuideManager.init()

    -- 先判断是否首次开启新手引导
    for k,v in pairs(getGameModel():getGuideModel():getActives()) do
        print("=========== Open Guide ============ " .. v)
        if v == 1 and not GlobalCloseGuide then
            httpAnchor(7001, "enter guide stage")
            self:enterGuideStage()
            return
        end
    end
    local pvpModel = getGameModel():getPvpModel()
    if pvpModel:getPvpInfo().BattleId > 0 then
        --如果pvp模型中的battleid不为0, 切到重连场景
        httpAnchor(7001, "enter pvp")
        SceneManager.loadScene(SceneManager.Scene.ScenePvp)
    else
        --切到普通大厅
        httpAnchor(7001, "enter hall")
        SceneManager.onlyLoad(SceneManager.Scene.SceneHall, handler(self, self.sceneCallBack))
    end
end

function UpdateOverViewHelper:enterGuideStage()
    -- 根据配置表构造第一关的战斗包
    local conf = getGuideBattleConfItem()
    local bufferData = newBufferData()
    bufferData:writeInt(conf.StageId) -- 关卡ID
    bufferData:writeInt(1) -- 关卡等级
    bufferData:writeInt(8) -- 房间对战类型
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 战斗内buff字段
    bufferData:writeInt(1) -- 房间内的玩家数量

    -- 玩家属性
    bufferData:writeInt(-1) -- 玩家id
    bufferData:writeInt(conf.HeroLv) -- 玩家等级
    bufferData:writeInt(1) -- 玩家阵营
    bufferData:writeInt(0) -- 战斗外BUFF数量
    bufferData:writeInt(#conf.Soliders) -- 玩家士兵个数
    bufferData:writeInt(0) -- 佣兵数量
    bufferData:writeInt(0) -- 玩家身份显示(蓝钻)
    local playerName = "莱奥"
    bufferData:writeString(playerName) -- 玩家名字 32字节
    -- 写入后面额外的字节
    for i = string.len(playerName) + 2, 32 do
        bufferData:writeChar(0)
    end

    -- 召唤师
    bufferData:writeInt(conf.HeroId)

    -- 士兵列表
    for k,v in ipairs(conf.Soliders) do
        bufferData:writeInt(v.SoliderId) -- 士兵id
        bufferData:writeInt(v.SoliderLevel) -- 士兵等级
        bufferData:writeInt(v.SoliderStar) -- 士兵星级
        bufferData:writeInt(0) -- 士兵经验
        for j = 1, 8 do
            bufferData:writeChar(0)     -- 天赋
        end
        bufferData:writeInt(0) -- 装备个数
    end

    bufferData:resetOffset()
    -- 打开房间
    openAndinitRoom(bufferData)
    deleteBufferData(bufferData)

    -- 加载战斗界面资源
    SceneManager.onlyLoad(SceneManager.Scene.SceneBattle, handler(self, self.sceneCallBack))

    -- 设置战斗结束回调
    BattleHelper.finishCallback = function()
        finishBattle()
        UIManager.pushSaveUI(UIManager.UI.UIHallBG)
        UIManager.pushSaveUI(UIManager.UI.UIHall)
        UIManager.pushSaveUI(UIManager.UI.UIArena)
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end
end

function UpdateOverViewHelper:sceneCallBack(allResCount, loadResCount, curResName, isSuccess)
    if isSuccess then
        local percent = allResCount / loadResCount
        self.loadingBar:setPercent(percent * 100)
        self.barLab:setString(string.format("%d%%", percent*100))
    end
end

return UpdateOverViewHelper
