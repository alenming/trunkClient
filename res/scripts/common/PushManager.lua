require "common.CommonHelper"

PushManager = class("PushManager")

local SEC_OF_DAY = 24 * 60 * 60

function PushManager:ctor()
	local key1 = self:getPushManagerOnOffKey()
	self.mOn = cc.UserDefault:getInstance():getBoolForKey(key1, true)
	print("PushManager:ctor, on="..tostring(self.mOn))

	local key2 = self:getRegisterTimeKey()
	local savedRTime = cc.UserDefault:getInstance():getIntegerForKey(key2)
	if savedRTime and savedRTime > 0 then
		self.mRegisterTime = savedRTime
	end
	local date = os.date("*t", savedRTime)
	print("PushManager:ctor, key="..key2..", date="..
		date.year.."-"..date.month.."-"..date.day.." "..date.hour..":"..date.min)
end

function PushManager:getInstance()
	if not gPushManager then
		gPushManager = PushManager.new()
	end
	return gPushManager
end

function PushManager:setOn(on)
	self.mOn = on

	local key = self:getPushManagerOnOffKey()
	cc.UserDefault:getInstance():setBoolForKey(key, self.mOn)
end

function PushManager:isOn()
	return self.mOn
end

-- 设置注册时间戳
function PushManager:setRegisterTime(time)
	self.mRegisterTime = time
	local key = self:getRegisterTimeKey()
    cc.UserDefault:getInstance():setIntegerForKey(key, time)

    local date = os.date("*t", time)
    print("PushManager:setRegisterTime, key="..key..", time="..time..", date=" ..
    	date.year.."-"..date.month.."-"..date.day.." "..date.hour..":"..date.min)
end

-- @return 从注册当天算起的第几天
function PushManager:getDayNo()
	if not self.mRegisterTime then return 0 end

	local now = os.time()
	local passedSec = now - self.mRegisterTime

	if passedSec < 0 then
		return 0
	end

	local registerDate = os.date("*t", self.mRegisterTime)
	local passedSecOfRegisterDay = CommonHelper.passedSecOfDay(
		registerDate.hour, registerDate.min, registerDate.sec
	)
	local restSecOfRegisterDay = SEC_OF_DAY - passedSecOfRegisterDay

	return 1 + math.ceil((passedSec - restSecOfRegisterDay) / SEC_OF_DAY)
end

-- 检测推送消息
function PushManager:checkPush()
	if not self.mOn then 
		print("PushManager:checkPush, PushManager is off")
		return 
	end

	local today = self:getDayNo()
	print("PushManager:checkPush, today="..tostring(today))
	if today == 0 then return end

	local ids = getAllPushIds()
	for _, id in ipairs(ids) do
		local item = getPushItem(id)
		if not self:isPushItemEnd(item) and self:isConditionFully(item) then
			local pushTime = self:getPushTime(item)
			if pushTime then
				local message = getPushLanConfItem(item.Push_LanID)
				local repeating = self:isRepeat(item) and 1 or 0

				print("push "..id)
				if device.platform == "android" then
					local ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "startPushService", { 
						id, tostring(pushTime), message or "no message", repeating, item.Push_Range
					}, "(ILjava/lang/String;Ljava/lang/String;ILjava/lang/String;)V")
					if not ok then
						printError(ret)
					end
				elseif device.platform == "ios" then
					local ok, ret = luaoc.callStaticMethod("PushService", "addNotification", { 
						triggerTime = tostring(pushTime), 
						content = message or "no message", 
						repeating = tostring(repeating),
						interval = tostring(item.Push_Range)	-- 重复推送间隔天数
					})
					if not ok then
						printError(ret)
					end
				end
			end
		end
	end
end

-- 清除所有推送消息
function PushManager:clearPush()
	if not self.mRegisterTime then return end

	if device.platform == "android" then
		local ids = getAllPushIds()
		for _, id in pairs(ids) do
			local ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "stopPushService", { 
				id
			}, "(I)V")
			if not ok then
				printError(ret)
			end
		end
	elseif device.platform == "ios" then
		local ok, ret = luaoc.callStaticMethod("PushService", "removeAllNotifications")
		if not ok then
			printError(ret)
		end
	end
end

function PushManager:isPushItemEnd(item)
	local today = self:getDayNo()
	if item.Push_StopTime < 0 or item.Push_StopTime > today then 
		return false 
	end

	return true
end

function PushManager:isRepeat(item)
	return item.Push_StopTime < 0
end

function PushManager:getPushTime(item)
	local now = os.time()
	local today = self:getDayNo()
	local passedSecOfToday = CommonHelper.passedSecOfDay(now)
	local restSecOfToday = SEC_OF_DAY - passedSecOfToday
	local passedSecOfPushDay = CommonHelper.passedSecOfDay(item.Push_Time, 0, 0)
	local todayPushTime = now + passedSecOfPushDay - passedSecOfToday
	local function nDaysLaterPushTime(n) 	-- n >= 1
		return now + restSecOfToday + (n - 1) * SEC_OF_DAY + passedSecOfPushDay
	end

	local pushTime
	if item.Push_Condition == 3 then		-- 一天未登录
		if today < item.Push_StartTime then
			pushTime = nDaysLaterPushTime(item.Push_StartTime - today)
		elseif today > item.Push_StartTime then
			pushTime = nDaysLaterPushTime(1)
		end
	elseif item.Push_Condition == 4 then 	-- 两天未登录
		if today + 1 < item.Push_StartTime then
			pushTime = nDaysLaterPushTime(item.Push_StartTime - today)
		else
			pushTime = nDaysLaterPushTime(2)
		end
	else
		if today < item.Push_StartTime then
			pushTime = nDaysLaterPushTime(item.Push_StartTime - today)
		else
			if passedSecOfPushDay > passedSecOfToday then
				pushTime = todayPushTime
			else
				pushTime = nDaysLaterPushTime(1)
			end
		end
	end

	return pushTime
end

function PushManager:isConditionFully(item)
	---[[
	local cond = item.Push_Condition
	if cond == 2 then		-- 有竞技场任务没完成
		local unfinishArenaTaskNum = self:getUnfinishTaskNum()
		print("PushManager:isConditionFully, unfinish arena task number "..unfinishArenaTaskNum)
		return unfinishArenaTaskNum > 0
	end
	--]]
	return true
end

function PushManager:getUnfinishTaskNum()
--	local gameModel = getGameModel()
--    local pvpModel = gameModel:getPvpModel()
--    local pvpTaskModel = gameModel:getPvpTaskModel()
--    local info = pvpModel:getPvpInfo()
--    local num = 0
--    for _, id in pairs(pvpTaskModel.taskIds) do
--    	local cfg = getArenaTask(id)
--    	if cfg then
--    		local needCount = cfg.Complete_Times
--    		local count = 0
--	        if cfg.PVPTask_Type == 0 then
--	            count = info.DayBattleCount
--	        elseif cfg.PVPTask_Type == 1 then
--	            count = info.DayWin
--	        elseif cfg.RewardType == 2 then
--	            count = info.DayMaxContinusWinTimes
--	        end

--	        if count < needCount then
--	            num = num + 1
--	        end
--    	end
--    end
--    return num
    return 0
end

function PushManager:getRegisterTimeKey()
	return "RegisterTime"
end

function PushManager:getPushManagerOnOffKey()
	return "PushManagerOnOff"
end

function gCheckPush()
	print("gCheckPush")
	PushManager:getInstance():checkPush()
end

function gClearPush()
	print("gClearPush")
	PushManager:getInstance():clearPush()
end

return PushManager