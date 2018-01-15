require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")
require("common.PushManager")
require("common.JavaCallback")

-- 是否在后台
gIsBackground = false
-- 是否是大厅版本
gIsQQHall = getCmdLine().Key ~= "" and true or false

function __G__TRACKBACK__(errorMessage)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    print(debug.traceback("", 2))
    print("----------------------------------------")

    -- lua bugly监听
    if device.platform == "android" or device.platform == "ios" then
        buglyReportLuaException(tostring(errorMessage), debug.traceback())
    end
end

-- 打锚点
function httpAnchor(point, args)
    if device.platform == "android" or device.platform == "ios" then
        local deviceModel = cc.UserDefault:getInstance():getStringForKey("DeviceProductModel") or "unknow"
        local deviceId = cc.UserDefault:getInstance():getStringForKey("DeviceIdentifier") or "unknow"
        local url = "http://zhs-rc-linux.fanhougame.com/front/api/step"
        local info = "mobile_name=" .. deviceModel .. "&mobile_id=" .. deviceId .. "&step=" .. point
        if args then
            info = info .. "&info=" .. args
        end
        requestHttp(url, info)
    end
end

function printTrace()
    print(debug.traceback())
end

package.path = package.path .. ";src/"
cc.FileUtils:getInstance():setPopupNotify(false)

if device.platform == "android" or device.platform == "ios" or gIsQQHall then
    require("app.SummonerUpdateApp").new():run()    
else
	initConfig()	
	require("app.SummonerApp").new():run()
end

dump(getCmdLine())

gEnterHallFirst = true

gAndroidPackageName = "com.tencent.tmgp.summoner"
gAndroidPackageNameSlash = string.gsub(gAndroidPackageName, "%.", "/")

gClearPush()

GlobalCloseGuide = false