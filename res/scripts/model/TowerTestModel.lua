-- 爬塔试炼模型
local TowerTestModel = class("TowerTestModel")

local first  = 6 -- 周六
local second = 7 --周日 

function TowerTestModel:ctor()
	self.mTimes = 0
	self.mTimeStamp = 0
	self.mFloor = 1
	self.mLastBestFloor = 0
	self.mFloorState = 0
	self.mEventParam = 0
	self.mIntegral = 0
	self.mCrystal = 0
	self.mStars = 0
	self.mBuffs = {}
	self.isOpen = true
end

function TowerTestModel:getCurTime()
    local now = getGameModel():getNow()
    local y = tonumber(os.date("%Y", now))
    local w = tonumber(os.date("%w", now))
    local h = tonumber(os.date("%H", now))
    local m = tonumber(os.date("%M", now))
    local s = tonumber(os.date("%S", now))
    local d = tonumber(os.date("%d", now))
    local month = tonumber(os.date("%m", now))
    w = w == 0 and 7 or w

    return {now = now, y = y, w = w, h = h, m = m, s = s, d = d, month = month}
end


function TowerTestModel:init(buffData)
	self.mFloor = buffData:readInt()					-- 当前楼层数

	local now = self:getCurTime()
	if now.w == first or now.w == second then
		self.isOpen = true
	else
		self.isOpen = false
	end
	return true
end

function TowerTestModel:updateUI()
	local now = self:getCurTime()
	if now.w == first or now.w == second then
		self.isOpen = true
	else
		self.isOpen = false
		if SceneManager.CurScene == SceneManager.Scene.SceneTowerTrial then
			SceneManager.loadScene(SceneManager.Scene.SceneHall)
		end
	end
end

function TowerTestModel:getIsOpen()
	return self.isOpen
end

function TowerTestModel:setIsOpen(isOpen)
	self.isOpen = isOpen
end

function TowerTestModel:getTowerTestFloor()
	return self.mFloor
end

function TowerTestModel:setTowerTestFloor(floor)
	self.mFloor = floor
end

-- 获取当前事件(楼层状态)
function TowerTestModel:getTowerTestEvent()
	return self.mFloorState
end

function TowerTestModel:setTowerTestEvent(event)
	self.mFloorState = event
end

function TowerTestModel:getTowerTestParam()
	return self.mEventParam
end

function TowerTestModel:setTowerTestParam(param)
	self.mEventParam = param
end

function TowerTestModel:getTowerTestScore()
	return self.mIntegral
end

function TowerTestModel:setTowerTestScore(score)
	self.mIntegral = score
end

function TowerTestModel:getTowerTestCrystal()
	return self.mCrystal
end

function TowerTestModel:setTowerTestCrystal(crystal)
	self.mCrystal = crystal
end

function TowerTestModel:getMyRankNum()
	return self.mMyRankNum
end

function TowerTestModel:setMyRankNum(MyRankNum)
	self.mMyRankNum = MyRankNum
end

function TowerTestModel:getMyHightNum()
	return self.mMyHightNum
end

function TowerTestModel:setMyHightNum(MyHightNum)
	self.mMyHightNum = MyHightNum
end

function TowerTestModel:getMyRankData()
	return self.mRankData
end


return TowerTestModel