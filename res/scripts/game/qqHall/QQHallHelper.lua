QQHallHelper = {}

local json = require("game.update.json")

-- 解析蓝钻类型, 返回: 是否是蓝钻, 是否是年费, 是否是超级
function QQHallHelper:getBDInfo(BDType)	
	local BDTypeBit = bit.tobits(BDType)
	return BDTypeBit[1] or 0, BDTypeBit[2] or 0, BDTypeBit[3] or 0
end

-- 合并信息
function QQHallHelper:getBDType(isBlue, isYear, isSuper)
	isBlue = isBlue and 1 or 0
	isYear = isYear and 2 or 0
	isSuper = isSuper and 4 or 0

	return isBlue + isYear + isSuper
end

QQHallHelper.requestType = {
	common = "http://tencentlog.com/stat/report.php",					-- 通用
	login = "http://tencentlog.com/stat/report_login.php",				-- 登陆
	register = "http://tencentlog.com/stat/report_register.php",		-- 注册
	beInvite = "http://tencentlog.com/stat/report_accept.php",			-- 被邀请
	invite = "http://tencentlog.com/stat/report_invite.php",			-- 邀请
	pay = "http://tencentlog.com/stat/report_consume.php",				-- 支付
	recharge = "http://tencentlog.com/stat/report_recharge.php",		-- 充值
	quit = "http://tencentlog.com/stat/report_quit.php",				-- 退出
	online = "http://tencentlog.com/stat/report_online.php",			-- 在线
}

function QQHallHelper.getNessaryInfo()
	return "appid=1105897582&svrip=" .. ServerConfig[gServerID].Ip .. 
		"&domain=10&opuid=" .. (getGameModel():getUserModel():getUserID() or 0) ..	
		"&opopenid=" .. getCmdLine().ID .. 
		"&worldid=" .. gServerID
end

gLuoPanRequestHttpCallBack = nil

function QQHallHelper.onReadyStateChanged(code, data)
    if code == 200 then
    	local output = json.decode(data)
        table.foreach(output,function(i, v) print ("requestHttp: ", i, v) end)

        if output.ret == "0" or output.ret == 0 then
            print("send sucess")
        else
            print("send fail", url)
        end
    else
    	print("code, data:", code, data)
    end
end

--[[
	requestType: 上报类型
	...: 补充内容

	appid, svrip, domain, [version], opuid, opopenid, worldid 必填字段会自动补上, 所以不用填写
	其他字段需要自己传过来
]]
function QQHallHelper.requestHttp(url, ...)
	if not gIsQQHall then
		return 
	end

	if type(url) ~= "string" then
		return
	end

	-- 处理rul
	url = url .. "?" .. QQHallHelper.getNessaryInfo()

	for _, v in ipairs({ ... }) do
		url = url .. "&" .. v
	end

	gLuoPanRequestHttpCallBack = QQHallHelper.onReadyStateChanged

	requestHttpWithCallback(url, "", "gLuoPanRequestHttpCallBack")
end