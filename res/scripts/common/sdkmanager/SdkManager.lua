local AnySdkManager = require"common.sdkmanager.anysdk.AnySdkManager"
local json = require("game.update.json")

local SdkManager = {}

SdkManager.SDKType = {
	UNKNOWN              = 0,
	ANYSDK 				= 1,	-- AnySDK
	WEIXIN  			= 2,	-- 微信
	QQHALL				= 3,	-- QQ大厅
}

-- 用户系统
if gIsQQHall then
	SdkManager.TargetUserPlugin = SdkManager.SDKType.QQHALL
elseif hasSDK(SdkManager.SDKType.ANYSDK) then
	SdkManager.TargetUserPlugin = SdkManager.SDKType.ANYSDK
else
	SdkManager.TargetUserPlugin = SdkManager.SDKType.UNKNOWN
end

-- 支付系统
if gIsQQHall then
	SdkManager.TargetPayPlugin = SdkManager.SDKType.QQHALL
elseif hasSDK(SdkManager.SDKType.ANYSDK) then
	SdkManager.TargetPayPlugin = SdkManager.SDKType.ANYSDK
else
	SdkManager.TargetPayPlugin = SdkManager.SDKType.UNKNOWN
end

print("SdkManager target user plugin: " .. SdkManager.TargetUserPlugin)
print("SdkManager target pay plugin: " .. SdkManager.TargetPayPlugin)

function SdkManager.init()
	if SdkManager.TargetUserPlugin == SdkManager.SDKType.ANYSDK or
	   SdkManager.TargetPayPlugin == SdkManager.SDKType.ANYSDK then
	   	AnySdkManager.init()
	else
		EventManager:raiseEvent(GameEvents.EventSDKInitSucess)
	end
end

function SdkManager.login()
	if SdkManager.TargetUserPlugin == SdkManager.SDKType.ANYSDK then
		AnySdkManager.login()
		httpAnchor(3001)
	elseif SdkManager.TargetUserPlugin == SdkManager.SDKType.WEIXIN then
		local ok, ret = luaoc.callStaticMethod("WxApiLuaBridge", "login")
		if ok then 
			httpAnchor(3001)
		else
			print(ret) 
		end
	elseif SdkManager.TargetUserPlugin == SdkManager.SDKType.QQHALL then
		-- body
	else
		print("SdkManager login: unknown target user plugin " .. tostring(SdkManager.TargetUserPlugin))
	end
end

function SdkManager.logout()
	if SdkManager.TargetUserPlugin == SdkManager.SDKType.ANYSDK then
		AnySdkManager.logout()
		httpAnchor(3001)
	else
		print("SdkManager logout: unknown target user plugin " .. tostring(SdkManager.TargetUserPlugin))
	end
end

function SdkManager.switchAccount()
	if SdkManager.TargetUserPlugin == SdkManager.SDKType.ANYSDK then
		if AnySdkManager.isSupport("accountSwitch") then
            AnySdkManager.accountSwitch()
        else
            AnySdkManager.logout()
        end
        httpAnchor(3001)
	else
		print("SdkManager switchAccount: unknown target user plugin " .. tostring(SdkManager.TargetUserPlugin))
	end
end

-- @param product: 商品信息
function SdkManager.payForProduct(product)
	local gameModel = getGameModel()
	local userModel = gameModel:getUserModel()
	local unionModel = gameModel:getUnionModel()
	local serverConfig = ServerConfig[gServerID]

	if SdkManager.TargetPayPlugin == SdkManager.SDKType.ANYSDK then
        local info = {}
        info.Product_Id = tostring(product.nGoodsID)
        info.Product_Name = CommonHelper.getUIString(product.nNameLanID)
        info.Product_Price = tostring(product.nPrice)
        info.Product_Count = "1"
        info.Coin_Name = "钻石"
        info.Coin_Rate = "10"
        info.Role_Id = tostring(userModel:getUserID())
        info.Role_Name = userModel:getUserName()
        info.Role_Grade = tostring(userModel:getUserLevel())
        info.Role_Balance = tostring(userModel:getDiamond())
        info.Vip_Level = tostring(0)
        info.Party_Name = unionModel:getUnionName()
        info.Server_Id = tostring(serverConfig and serverConfig.ServerId or 10003)
        info.Server_Name = serverConfig and serverConfig.Name or "亚洲一服"

        AnySdkManager.payForProduct(info)

	elseif SdkManager.TargetPayPlugin == SdkManager.SDKType.QQHALL then
		local cmdLine = getCmdLine()
		local url = "http://minigame.qq.com/plat/social_hall/app_frame/?appid=1105897582&param=buy" .. product.nGoodsID
		local info = "ID*" .. cmdLine.ID .. 
					",Key*" .. cmdLine.Key .. 
					",PROCPARA*" .. cmdLine.PROCPARA ..
					",URL*" .. url .. 
					",NAME*" .. "buy"

		--print("URL: ", url)
		--print("info", info)
		webDialog(info, false)

	else
		--print("SdkManager payForProduct: unknown target pay plugin " .. tostring(SdkManager.TargetPayPlugin))
		local extra = {
			pid = product.nGoodsID,
			serverid = serverConfig and serverConfig.ServerId or 10003,
			channel = 1,
			sid = 10006,
		}

		local url = "http://mobile-test.gz.1251013877.clb.myqcloud.com/?router=/pay/pay" ..
					"&app_id=" .. 1001 ..
					"&user_id=" .. userModel:getUserID() ..
					"&sp=" .. 3 .. 
					"&num=" .. 1--[[product.nPrice]] .. 
					"&r=" .. CommonHelper.ralnum(6) ..
					"&extra=" .. string.gsub(json.encode(extra), '"', "%%22")
		openURL(url)

		EventManager:raiseEvent(GameEvents.EventSDKPaySuccess)
	end	
end

function SdkManager.openVip()
	if gIsQQHall then
		local cmdLine = getCmdLine()
		local url = "http://minigame.qq.com/plat/social_hall/app_frame/?appid=1105897582&param=openVip"
		local info = "ID*" .. cmdLine.ID .. 
					",Key*" .. cmdLine.Key .. 
					",PROCPARA*" .. cmdLine.PROCPARA ..
					",URL*" .. url .. 
					",NAME*" .. "buy"

		--print("URL: ", url)
		--print("info", info)
		webDialog(info, true)
	end
end

-- 只有接入了AnySDK才能调用这个接口
-- @return AnySDK的渠道编号
function SdkManager.getChannelId()
	if hasSDK(SdkManager.SDKType.ANYSDK) then
    	return AnySdkManager.getChannelId()
    end
end

-- 只有接入了AnySDK才能调用这个接口
function SdkManager.hasAnySdkUserPlugin()
	if hasSDK(SdkManager.SDKType.ANYSDK) then
		return AnySdkManager.hasUserPlugin()
	end
end

return SdkManager