--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

TimeHelper = {}

--整形时间转为结构体时间
function TimeHelper.toTimeS(time)
    local Y = os.date("%Y", time)
    local m = os.date("%m", time)
    local d = os.date("%d", time)
    local w = os.date("%w", time) 
    local H = os.date("%H", time)
    local M = os.date("%M", time)
    local S = os.date("%S", time)
    return {year = Y, 
            month = m, 
            day = d, 
            wday = w, 
            hour = H, 
            min = M, 
            sec = S}
end

--结构体时间转为整形时间
function TimeHelper.toTimeN(tb)
    local cur = TimeHelper.toTimeS(os.time())
    return os.time({year = tb.year or cur.year, 
                    month = tb.month or cur.month,
                    day = tb.day or cur.day,
                    hour = tb.hour or cur.hour,
                    min = tb.min or cur.min,
                    sec = tb.sec or cur.sec})
end

--时间间隔，单位最大为小时
function TimeHelper.gapTimeS(delta)
    local h = math.modf(delta / 3600)
    local m = math.modf((delta - h * 3600) / 60)
    local s = math.modf(delta - h * 3600 - m * 60)
    return {hour = h, min = m, sec = s}
end

--计算剩余时间, 单位最大为天
function TimeHelper.restTime(_time)
    local cur = os.time()
    local delta = _time - cur

    local d = math.modf(delta / 86400)
    local h = math.modf((delta - d * 86400) / 3600)
    local m = math.modf((delta - d * 86400 - h * 3600) / 60)
    local s = math.modf(delta - d * 86400 - h * 3600 - m * 60)
    return {day = d, hour = h, min = m, sec = s}
end

--循环函数
function TimeHelper.resetUpdate(time)	
    
end

-- 返回某个时间戳到周几几时几分的时间戳 wDay周1~7
function TimeHelper.getWNextTimeStamp(curTime, min, hour, wday)	
    return getWNextTimeStamp(curTime, min, hour, wday)
end

function TimeHelper.isSameDay(time1, time2)
    return (os.date("%Y", time1) == os.date("%Y", time2) and 
            os.date("%m", time1) == os.date("%m", time2) and
            os.date("%d", time1) == os.date("%d", time2))
end

return TimeHelper

--endregion
