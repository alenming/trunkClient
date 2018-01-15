--region *.lua
--网络连接回调
--此文件由[BabeLua]插件自动生成
--endregion

ConnectionTips = {}

require("game.comm.PlatformModel")
local scheduler = require("framework.scheduler")
--添加监听
function ConnectionTips.init()
    print("ConnectionTips")
    ConnectionTips.isConnecting = false
    ConnectionTips.isKick = false
    EventManager:addEventListener(GameEvents.EventNetDisconnect, ConnectionTips.DisconnectCallback)
    EventManager:addEventListener(GameEvents.EventNetReconnect, ConnectionTips.ReconnectCallback)

    if device.platform == "ios" then
        ConnectionTips.CheckNetworkReachablityAways()
    end
end

function ConnectionTips.CheckNetworkReachablityAways()
    ConnectionTips.checkReachabilityFunc = scheduler.scheduleGlobal(function(dt)
        local ok, ret = luaoc.callStaticMethod("LuaCallOC", "getNetStatus")
        if ok then
            if ret == 0 then
                --网络不通
                print("ConnectionTips CheckNetworkReachablityAways network disconnect!!!")
                ConnectionTips.DisconnectCallback()
            end
        else
            print("ConnectionTips CheckNetworkReachablityAways error in iOS!!", ok, ret)
        end
    end, 3.0)
end


function ConnectionTips.createTips()
    local wifiTips = display.getRunningScene():getChildByName("WIFITIPS")
    local wifiAction
    if wifiTips then
        if not wifiTips:isVisible() then
            wifiTips:setVisible(true)
            wifiAction = wifiTips:getActionByTag(wifiTips:getTag())
            if wifiAction then
                wifiAction:play("Normal", true)
            end
        end
    else
        -- 第一次断线将tips添加到主场景中
        wifiTips = getResManager():getCsbNode(ResConfig.Common.Csb2.wifiTips)
        CommonHelper.layoutNode(wifiTips)
        if wifiTips then
            wifiAction = cc.CSLoader:createTimeline(ResConfig.Common.Csb2.wifiTips)
            wifiTips:runAction(wifiAction)
            wifiAction:play("Normal", true)
            wifiTips:setName("WIFITIPS")
            wifiTips:setGlobalZOrder(6)
	        wifiTips:setLocalZOrder(6)
            display.getRunningScene():addChild(wifiTips)
        end
    end
    return wifiTips
end

--断线回调
function ConnectionTips.DisconnectCallback(eventName, noShowTips)
    print("DisconnectCallback========== b")
    if ConnectionTips.isConnecting or ConnectionTips.isKick then
        return
    end
    
    ConnectionTips.isConnecting = true
    ConnectionTips.isTipsShow = false

    if not noShowTips then
        --延迟显示wifi提示, 定时循环是
        ConnectionTips.tipsFunc = scheduler.scheduleGlobal(function(dt) 
                if not ConnectionTips.isTipsShow then
                    ConnectionTips.createTips()
                    ConnectionTips.isTipsShow = true
                end
	        end, 1.5)
    end

    --定时发送重连请求
    ConnectionTips.updateFunc = scheduler.scheduleGlobal(function(dt) 
            print("重连session ing")
            reconnectToServer(0)
	    end, 0.5)
   print("DisconnectCallback========== e")
end

--重连成功回调
function ConnectionTips.ReconnectCallback(eventName, result)
    if 0 == result then
        print("ReconnectCallback reconnect fail==========")
        return
    end
    print("ReconnectCallback reconnect success==========")
    --重连成功, 移除重连定时
    scheduler.unscheduleGlobal(ConnectionTips.updateFunc)
    --发送验证信息
    if PlatformModel.loginType == "SDKLogin" or PlatformModel.loginType == "QQHall" then
        print("ReconnectCallback send check with SDKLogin!!!!")
        local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckPfCS) 
        BufferData:writeInt(PlatformModel.pfType)
        BufferData:writeCharArray(PlatformModel.openId, 128)
        BufferData:writeCharArray(PlatformModel.token or "", 256)
        NetHelper.request(BufferData)
    elseif PlatformModel.userId ~= 0 then
        print("PlatformModel.userId", PlatformModel.userId)
        print("ReconnectCallback send check with testCS!!!!")
        -- 暂时使用uid登录, 不使用openId, token
        local bufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckTestCS) 
        bufferData:writeInt(tonumber(PlatformModel.userId))  
        NetHelper.request(bufferData)
    else
        --游客登录
        print("ReconnectCallback send check with guest!!!!")
        local deviceId = cc.UserDefault:getInstance():getStringForKey("DeviceIdentifier")
        local password = cryptoMd5("fanhouzhs" .. deviceId .. "yueliushui10yi")
        local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginCheckGuestCS)
        BufferData:writeCharArray(deviceId, 40)
        BufferData:writeCharArray(password, 32)
        NetHelper.request(BufferData)
    end

    --监听验证
    local cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginCheckSC)
    NetHelper.setResponeHandler(cmd, ConnectionTips.ReconnectCheck)
end

function ConnectionTips.ReconnectCheck(mainCmd, subCmd, buffData)
    print("ReconnectCallback check success==========")
    local userId = buffData:readInt()
    local isNewUser = buffData:readInt()
    local isGuest = buffData:readInt()

    print("UILoginSDK onLoginCheck buffData: ", userId, isNewUser, isGuest)

    if userId < 0 then
        print("====== Reconnect: check error!! userid < 0!!!")
    else
        -- 验证通过，发送重连信息
        bufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginReconnectCS) 
        NetHelper.request(bufferData)
        ConnectionTips.ReconnectFinish()
    end
end

function ConnectionTips.ReconnectFinish()
    print("ReconnectCallback finish==========")
    local wifiTips = display.getRunningScene():getChildByName("WIFITIPS")
    if wifiTips then
        wifiTips:setVisible(false)
    end
 
    local cmd = NetHelper.makeCommand(MainProtocol.Login, LoginProtocol.LoginCheckSC)
    NetHelper.removeResponeHandler(cmd, ConnectionTips.ReconnectCheck)

    if ConnectionTips.tipsFunc then
        scheduler.unscheduleGlobal(ConnectionTips.tipsFunc)
    end
    ConnectionTips.isConnecting = false

    -- 通知战斗内进行战斗数据序列化
    local bufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginReconnectCS) 
    raiseEvent(bufferData)

    -- 提示重连成功
    EventManager:raiseEvent(GameEvents.EventNetReconnectFinish)
end
