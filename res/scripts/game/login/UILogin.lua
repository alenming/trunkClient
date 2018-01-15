--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-14 15:17
** 版  本:	1.0
** 描  述:  登录界面
** 应  用:
********************************************************************/
--]]
require("game.login.ServerConfig")

GlobalCloseGuide = cc.UserDefault:getInstance():getBoolForKey("GlobalCloseGuide")

gServerID = cc.UserDefault:getInstance():getIntegerForKey("ServerId")
if not gServerID or 0 == gServerID then
    gServerID = 1
    cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
end

gNotBusinessVersion = true

local UILogin = class("UILogin", function()
    return require("common.UIView").new()
end)

local SOCK_VERSION = { ipv4 = 0, ipv6 = 1 }
local CONN_TYPE = { session = 0, chat = 1 }

function UILogin:ctor()
    self.rootPath = ResConfig.UILogin.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 新手引导开启复选框
    local newBieCheckBox = getChild(self.root, "MainPanel/LoginInput/NewBieText/CheckBox")
    newBieCheckBox:addEventListener(handler(self, self.onCheckBox))
    newBieCheckBox:setSelected(not GlobalCloseGuide)

    -- 玩家ID文本框
    self.userIdTextField = getChild(self.root, "MainPanel/LoginInput/IDBar/IDTextField")
    
    -- 服务器选项
    local serverNode    = getChild(self.root, "MainPanel/LoginInput/OnlineItem")
    self.serverBtn      = getChild(serverNode, "OnlinePanel")
    self.serverBtn:addClickEventListener(handler(self, self.onClick))
    self.zoneId         = getChild(serverNode, "OnlinePanel/Text_1")    -- 区id
    self.serverName     = getChild(serverNode, "OnlinePanel/Text_2")    -- 名称
    self.serverState    = getChild(serverNode, "OnlinePanel/Text_3")    -- 状态

    self.enterBtn = getChild(self.root, "MainPanel/LoginInput/EnterButton_1")
    CsbTools.initButton(self.enterBtn, handler(self, self.onClick), "Enter", "Button_Enter/ButtomName", "Button_Enter")

    local previewBtn = getChild(self.root, "MainPanel/LoginInput/EnterButton_2")
    CsbTools.initButton(previewBtn, handler(self, self.onClick), "Preview", "Button_Enter/ButtomName", "Button_Enter")
    previewBtn:setVisible(gNotBusinessVersion)
end

-- 当界面被打开时回调
function UILogin:onOpen(openerUIID, ...)
    self:initEvent()
    self:initNetwork()

    self:setUserId()
    self:setServerInfo()
end

-- 当界面被关闭时回调
-- 可以返回多个数据
function UILogin:onClose()
    print("关闭界面，移除回调")
    self:removeEvent()
    self:removeNetwork()
end

-- 新手引导复选框点击回调
function UILogin:onCheckBox(obj, checkType)
    MusicManager.playSoundEffect(obj:getName())

    if 0 == checkType then  -- 选中
        GlobalCloseGuide = false
    else                    -- 取消
        GlobalCloseGuide = true
    end

    -- 存储新手引导开关状态到本地
    cc.UserDefault:getInstance():setBoolForKey("GlobalCloseGuide", GlobalCloseGuide)
end

-- 设置玩家ID
function UILogin:setUserId()
    local userId = cc.UserDefault:getInstance():getIntegerForKey("UserId")
    print("获取userId" .. userId)
    if not userId or 0 == userId then
        math.newrandomseed()
        userId = math.random(1, 10000000)
        print("随机userId" .. userId)
        cc.UserDefault:getInstance():setIntegerForKey("UserId", userId)
    end

    self.userIdTextField:setString(tostring(userId))
end

-- 设置服务器信息
function UILogin:setServerInfo()
    local serverConfig = ServerConfig[gServerID]
    if nil == serverConfig then
        gServerID = 1
        serverConfig = ServerConfig[gServerID]
        cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
    end

    self.zoneId:setString(serverConfig.Id)
    self.serverName:setString(serverConfig.Name)
    self.serverState:setString(serverConfig.Status)

    self.ip = serverConfig.Ip
    self.port = serverConfig.Port
    self.connectStatus = 0 -- 0默认状态,1连接成功,2连接失败
end

-- 登录按钮点击回调
function UILogin:onClick(obj)
    local btnName = obj:getName()
    if btnName == "EnterButton_1" then
        if self.userIdTextField:getString() == "" then
            print("Error: self.userIdTextField:getString() == ''")
            return
        end
        local userId = self.userIdTextField:getString()
        local str = string.match(userId, "%d+")
        if str ~= userId then
            self.userIdTextField:setString("请输入数字")
        else
            -- 连接服务器
            if 0 == self.connectStatus then
                print("请求连接服务器" .. self.ip)
                connectToServer(self.ip, self.port, CONN_TYPE.session, SOCK_VERSION.ipv6)
            elseif 2 == self.connectStatus then
                print("重新连接服务器" .. self.ip)
                reconnectToServer(0)
            else
                print("what the fuck self.connectStatus", self.connectStatus)
                return
            end

            PlatformModel.host = self.ip
            PlatformModel.port = self.port
            self.enterBtn:setEnabled(false)
            self.serverBtn:setEnabled(false)
        end
    elseif btnName == "EnterButton_2" then
        require("app.SummonerPreviewApp").new():run()
    elseif btnName == "OnlinePanel" then
        UIManager.open(UIManager.UI.UIServerList, handler(self, self.setServerInfo))
    end
end

-- 初始化事件回调
function UILogin:initEvent()
    -- 网络连接成功
    self.connectCallback = handler(self, self.ConnectedSucceed)
    EventManager:setEventListener(GameEvents.EventNetConnectSuccess, self.connectCallback)
    -- 网络连接失败
    self.disconnectCallback = handler(self, self.ConnectedFailed)
    EventManager:setEventListener(GameEvents.EventNetConnectFailed, self.disconnectCallback)
    -- 网络重连
    self.reconnectCallback = handler(self, self.ReconnectedEvent)
    EventManager:setEventListener(GameEvents.EventNetReconnect, self.reconnectCallback)
end

-- 移除事件回调
function UILogin:removeEvent()
    if self.connectCallback then
        EventManager:removeEventListener(GameEvents.EventNetConnectSuccess, self.connectCallback)
        self.connectCallback = nil
    end 
    if self.disconnectCallback then
        EventManager:removeEventListener(GameEvents.EventNetConnectFailed, self.disconnectCallback)
        self.disconnectCallback = nil
    end
    if self.reconnectCallback then
        EventManager:removeEventListener(GameEvents.EventNetReconnect, self.reconnectCallback)
        self.reconnectCallback = nil
    end
end

-- 初始化网络回调
function UILogin:initNetwork()
    -- 注册登录命令
    self.isGetFinishSC = false
    self.loginHandler = handler(self, self.acceptLoginCmd)
    self.loginSubCmds = {}
    for i = LoginProtocol.LoginFinishSC, LoginProtocol.LoginBlueGemSC do
        -- 被踢和被顶已经在GlobalListen里面监听了, 被封使用另一个监听
        if i ~= LoginProtocol.TickSC and 
            i ~= LoginProtocol.RechangeSC and 
            i ~= LoginProtocol.LoginChatSC and
            i ~= LoginProtocol.BanSC and
            i ~= LoginProtocol.InstanceModelSC  then

            cmd = NetHelper.makeCommand(MainProtocol.Login, i)
            NetHelper.setResponeHandler(cmd, self.loginHandler)
            table.insert(self.loginSubCmds, i)
        end
    end

    -- 注册被封命令, 单独监听
    self.banHandler = handler(self, self.onBan)
    cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.BanSC)
    NetHelper.setResponeHandler(cmd, self.banHandler)
end

function UILogin:removeNetwork()
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

-- 网络连接成功
function UILogin:ConnectedSucceed()
    print("连接成功")
    self.connectStatus = 1
    -- 存储服务器ID到本地
    cc.UserDefault:getInstance():setIntegerForKey("ServerId", gServerID)
    self:sendLoginCheckCmd()
end

-- 网络连接失败
function UILogin:ConnectedFailed()
    self.connectStatus = 2
    self.serverBtn:setEnabled(true)
    self.enterBtn:setEnabled(true)
    local params = {}
    params.msg = CommonHelper.getUIString(975)
    params.confirmFun = function () UIManager.close() end
    params.cancelFun = function () print("nothing to do...") end
    UIManager.open(UIManager.UI.UIDialogBox, params)
    print("连接失败")
end

-- 重连失败
function UILogin:ReconnectedEvent(eventName, result)
    if 1 == result then
        self:ConnectedSucceed()
    else
        print("重连失败")
        self.connectStatus = 2

        self.serverBtn:setEnabled(true)
        self.enterBtn:setEnabled(true)
        local params = {}
        params.msg = CommonHelper.getUIString(975)
        params.confirmFun = function () UIManager.close() end
        params.cancelFun = function () print("nothing to do...") end
        UIManager.open(UIManager.UI.UIDialogBox, params)
    end
end

-- 发送登陆验证命令
function UILogin:sendLoginCheckCmd()
    local userId = self.userIdTextField:getString()
    local buffData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckTestCS)
    buffData:writeInt(tonumber(userId))  
    print("发送登陆验证 " .. userId)

    NetHelper.requestWithTimeOut(buffData, 
        NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginCheckSC), 
        handler(self, self.acceptLoginCheckCmd)) 
end

-- 接收登录验证命令
function UILogin:acceptLoginCheckCmd(mainCmd, subCmd, buffData)
    -- 存储玩家ID到本地
    cc.UserDefault:getInstance():setIntegerForKey("UserId", tonumber(self.userIdTextField:getString()))
    
    local userId = buffData:readInt()
    local isNewUser = buffData:readInt()
    local isGuest = buffData:readInt()

    print("acceptLoginCheckCmd, userId " .. userId .. " isNewUser " .. isNewUser .. " isGuest " .. isGuest)
    if isGuest == 0 then
        local BuffData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginUserInfoCS)
        BuffData:writeInt(isGuest)
        BuffData:writeInt(userId)
        BuffData:writeInt(isNewUser)
        BuffData:writeInt(PlatformModel.pfType)
        BuffData:writeCharArray(PlatformModel.openId, 128)
        BuffData:writeCharArray("Windows", 40)
        NetHelper.request(BuffData)
    end

    print("发送登录请求 sendLoginCmd")
    self:sendLoginCmd()
end

-- 发送登陆命令
function UILogin:sendLoginCmd()
    if device.platform == "android" or device.platform == "ios" then
        buglySetUserId(self.userIdTextField:getString())
        buglySetTag(1)
    end

    local userId = tonumber(self.userIdTextField:getString())
    initUserId(userId)
    PlatformModel.loginType = "TestLogin"
    PlatformModel.userId = userId
    local buffData1 = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCS)
    buffData1:writeInt(userId)   -- 玩家ID
    NetHelper.request(buffData1)
    local buffData2 = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginUnionCS)
    buffData2:writeInt(userId)   -- 玩家ID
    NetHelper.request(buffData2)
end

-- 接收登陆命令
function UILogin:acceptLoginCmd(mainCmd, subCmd, buffData)
    print("接受登录返回" .. mainCmd .. " - " .. subCmd)

    if mainCmd == MainProtocol.Login then
        if mainCmd == MainProtocol.Login then
            if subCmd == LoginProtocol.LoginFinishSC then
                self.isGetFinishSC = true
                -- 连接聊天服务器
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
    if next(self.loginSubCmds) == nil and self.isGetFinishSC then
        self:enterGame()
    end
end

function UILogin:onBan(mainCmd, subCmd, buffData)
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

function UILogin:enterGame()
    require("app.SummonerApp").new():enterGame()
end

return UILogin