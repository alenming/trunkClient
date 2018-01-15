require"common.sdkmanager.anysdk.anysdkConst"

local AnySdkManager = {}

AnySdkManager.AppParam = {
	release = {
		appKey = "DC2C1C6D-7873-1AD1-5784-1FA25A09C6E5",
		appSecret = "3fd7451cce0ce7aae0a7f3bf1680dc82",
		privateKey = "B8B7C434867836A9E2885D3BDC825A69"
	},

	sandbox = {
		appKey = "E0DA15CF-1B6A-EB1D-8BF2-8259D285AB45",
		appSecret = "564230a5dc7e339becfbb88d1121c106",
		privateKey = "136D5A4C2FE8C7B80492AB67827EE977"
	},
}

AnySdkManager.Key_IsLogoutFromChannel = "IsLogoutFromChannel"

-- 是否用户系统已经初始化？只有用户系统初始化成功后才能调用login接口
AnySdkManager.IsUserPluginInitSuccess = false

function AnySdkManager.getUserPlugin()
	if not AgentManager then return end

	local agent = AgentManager:getInstance()
	return agent:getUserPlugin()
end

function AnySdkManager.hasUserPlugin()
	local plugin = AnySdkManager.getUserPlugin()
	return plugin ~= nil
end

function AnySdkManager.getIapPlugin()
	if not AgentManager then return end

	local agent = AgentManager:getInstance()
	local iap_plugins = agent:getIAPPlugin()
	if iap_plugins then
		-- 如果只有一个支付插件，可以直接调用获取该唯一的对象。
		local iap_plugin 
		for _, value in pairs(iap_plugins) do
		    iap_plugin = value
		end
		return iap_plugin
	end
end

function AnySdkManager.init()
	if not AgentManager then
		return 
	end

	local appKey = AnySdkManager.AppParam.release.appKey
	local appSecret = AnySdkManager.AppParam.release.appSecret
	local privateKey = AnySdkManager.AppParam.release.privateKey
	local oauthLoginServer = "http://zhs-rc-linux.fanhougame.com/front/api/any?action=login_info" -- "http://192.168.5.91/php/demo/login.php" -- -- "http://oauth.anysdk.com/api/OauthLoginDemo/Login.php"
	
	local agent = AgentManager:getInstance()
	agent:init(appKey, appSecret, privateKey, oauthLoginServer)
	agent:loadAllPlugins()

	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		-- @param pPlugin: ProtocolUser, 用户系统插件
		-- @param code: UserActionResultCode，登陆回调返回值
		-- @param msg : string，返回登陆信息，可能为空
		local function onActionListener( pPlugin, code, msg )
		    if code == UserActionResultCode.kInitSuccess then
		    	AnySdkManager.IsUserPluginInitSuccess = true
		    	EventManager:raiseEvent(GameEvents.EventSDKInitSucess)
		    elseif code == UserActionResultCode.kInitFail then
		    	print("AnySDK user plugin init fail! %s", msg)
		        EventManager:raiseEvent(GameEvents.EventSDKInitFail)
		    elseif code == UserActionResultCode.kLoginSuccess or 
		    	   code == UserActionResultCode.kAccountSwitchSuccess then
		    	cc.UserDefault:getInstance():setBoolForKey(AnySdkManager.Key_IsLogoutFromChannel, false)

		    	local messages = string.split(msg, "|")
		    	local info = {
		    		pfType 		= tonumber(agent:getChannelId()),
		    		openId 		= pPlugin:getUserID(),
		    		channelName = messages[1],
		    		token 		= messages[2],
		    	}
		    	dump(info, "AnySDK login success info")

		    	EventManager:raiseEvent(GameEvents.EventSDKLoginSucess, info)
		    elseif code == UserActionResultCode.kLoginNetworkError then
		    	printInfo("AnySDK login network error! %s", msg)

		    	httpAnchor(3003, msg)

		    	EventManager:raiseEvent(GameEvents.EventSDKLoginNetError, {})
		    elseif code == UserActionResultCode.kLoginCancel then
		    	EventManager:raiseEvent(GameEvents.EventSDKLoginCancel, {})
		    elseif code == UserActionResultCode.kLoginFail then
		    	printInfo("AnySDK login fail! %s", msg)

		    	httpAnchor(3002, msg)

		    	EventManager:raiseEvent(GameEvents.EventSDKLoginFail, {})
		    elseif code == UserActionResultCode.kLogoutSuccess then
                httpAnchor(3004, msg)

		    	cc.UserDefault:getInstance():setBoolForKey(AnySdkManager.Key_IsLogoutFromChannel, true)

		    	local func = function () 
		    		logout()
		    		require("app.SummonerUpdateApp").new():run()
		    	end

		    	if device.platform == "android" then
		    		local ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "runOnGLThread", { func })
		    		if not ok then
		    			print(ret)
		    			func()
		    		end
		    	else
		    		func()
		    	end

		    	EventManager:raiseEvent(GameEvents.EventSDKLogoutSucess, {})
		    elseif code == UserActionResultCode.kLogoutFail then
		    	printInfo("AnySDK logout fail! %s", msg)

		    	EventManager:raiseEvent(GameEvents.EventSDKLogoutFail, {})
		    elseif code == UserActionResultCode.kAccountSwitchCancel then
		    	EventManager:raiseEvent(GameEvents.EventSDKAccountSwitchCancel, {})
		    elseif code == UserActionResultCode.kAccountSwitchFail then
		    	printInfo("AnySDK account switch fail! %s", msg)

		    	EventManager:raiseEvent(GameEvents.EventSDKAccountSwitchFail, {})
		    end
		end
		user_plugin:setActionListener(onActionListener)
	end

	local iap_plugin = AnySdkManager.getIapPlugin()
	if iap_plugin then 
		local function onResult( code, msg, info )
		    if code == PayResultCode.kPaySuccess then
		        EventManager:raiseEvent(GameEvents.EventSDKPaySuccess)
		    elseif code == PayResultCode.kPayFail then 
		    	printInfo("AnySDK pay fail! %s", msg)
		    elseif code == PayResultCode.kPayNetworkError then
		    	printInfo("AnySDK pay network error! %s", msg)
		    elseif code == PayResultCode.kPayProductionInforIncomplete then
		    	printInfo("AnySDK pay product information incomplete! %s", msg)
		    elseif code == PayResultCode.kPayInitSuccess then
		    	initPayPluginSuccess = true
		    elseif code == PayResultCode.kPayInitFail then
		    	printInfo("AnySDK pay init fail! %s", msg)
		    	initPayPluginSuccess = false
		    elseif code == PayResultCode.kPayNowPaying then
		    	AnySdkManager.resetPayState()
		    end

		    EventManager:raiseEvent(GameEvents.EventSDKPayResult)
		end
		iap_plugin:setResultListener(onResult)
	end
end

function AnySdkManager.unloadAllPlugins()
	if not AgentManager then return end

	local agent = AgentManager:getInstance()
	agent:unloadAllPlugins()
end

function AnySdkManager.login()
	if AnySdkManager.IsUserPluginInitSuccess then
		local user_plugin = AnySdkManager.getUserPlugin()
		if user_plugin then
			user_plugin:login()
		end
	else
		printInfo("AnySDK: Error! You have to init the AnySDK success when you call its login function")
	end
end

function AnySdkManager.isLogined()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		return user_plugin:isLogined()
	end
end

function AnySdkManager.getUserID()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		return user_plugin:getUserID()
	end
end

function AnySdkManager.logout()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("logout") then
		    user_plugin:callFuncWithParam("logout")
		else
			print("AnySDK: Not support logout")
		end
	end
end

-- 进入平台中心
function AnySdkManager.enterPlatform()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("enterPlatform") then
		    user_plugin:callFuncWithParam("enterPlatform")
		else
			print("AnySDK: Not support enterPlatform")
		end
	end
end

-- 显示悬浮窗口
function AnySdkManager.showToolBar(place)
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("showToolBar")  then
		    local param1 = PluginParam:create(place or ToolBarPlace.kToolBarTopLeft)
		    user_plugin:callFuncWithParam("showToolBar", param1)
		else
			print("AnySDK: Not support showToolBar")
		end
	end
end

function AnySdkManager.hideToolBar()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("hideToolBar")  then
		    user_plugin:callFuncWithParam("hideToolBar")
		else
			print("AnySDK: Not support hideToolBar")
		end
	end
end

function AnySdkManager.accountSwitch()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("accountSwitch") then
		    user_plugin:callFuncWithParam("accountSwitch")
		else
			print("AnySDK: Not support accountSwitch")
		end
	end
end

-- 注意：部分渠道SDK要求必须显示渠道的退出界面，例如在返回键或游戏退出按钮调用此接口。
function AnySdkManager.exit()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then 
		if user_plugin:isFunctionSupported("exit") then
		    user_plugin:callFuncWithParam("exit")
		else
			print("AnySDK: Not support exit")
		end
	end
end

-- 游戏暂停时调用该函数（目前好像除了iOS百度91，没有别的SDK有这个了）。
function AnySdkManager.pause()
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if user_plugin:isFunctionSupported("pause") then
		    user_plugin:callFuncWithParam("pause")
		else
			print("AnySDK: Not support pause")
		end
	end
end

function AnySdkManager.isSupport(method)
	local user_plugin = AnySdkManager.getUserPlugin()
	if user_plugin then
		if  user_plugin:isFunctionSupported(method) then
		    return true
		else
			return false
		end
	end
end

function AnySdkManager.getChannelId()
	if not AgentManager then return end

	local agent = AgentManager:getInstance()
	return tonumber(agent:getChannelId())
end

---------------
-- IAP
---------------

--[[
注意：调用支付函数时需要传入的一些玩家信息参数(如角色名称，ID，等级)都是渠道强制需求(如UC,小米)，
并非AnySDK收集所用，如果开发者不填或者填假数据都会导致渠道上架无法通过。

local info = {
    Product_Id="1", 
    Product_Price="1", 
    Product_Name="10金币",  
    Product_Count="1",
    Coin_Name="金币",
    Coin_Rate="10",  
    Role_Id="1001",  
    Role_Name="张三",
    Role_Grade="50",
    Role_Balance="1",
    Vip_Level="1",
    Party_Name="无",
    Server_Id="1",
    Server_Name="服务器1"
}
因有些SDK不支持浮点数，Product_Price请传入整数。
]]
function AnySdkManager.payForProduct( productInfo )
	local iap_plugin = AnySdkManager.getIapPlugin()
	if iap_plugin then
		dump(productInfo, "ProductInfo")
		iap_plugin:payForProduct(productInfo)
	end
end

-- 注意：调用payForProduct后立即调用getOrderId的话是获取不到该次支付的订单号的，
-- 因为此时客户端还没收到服务端返回的订单号，请在收到支付回调后调用getOrderId。
function AnySdkManager.getOrderId()
	local iap_plugin = AnySdkManager.getIapPlugin()
	if iap_plugin then
		return iap_plugin:getOrderId()
	end
end

-- 支付过程中若SDK没有回调结果，就认为支付正在进行中，再次调用支付的时候会回调kPayNowPaying，可以调用该函数重置支付状态。
function AnySdkManager.resetPayState()
	ProtocolIAP:resetPayState()
end

return AnySdkManager