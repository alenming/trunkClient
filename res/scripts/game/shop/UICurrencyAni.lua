--[[
	货币飞行，主要实现以下内容
	1. 金币飞行动画

	使用方法:
		创建传入参数 添加金币的UI, 金币起始位置, 终止位置, 金币数目, 回调通知
		回调通知会在第一个金币达到指定终点位置后通知 到达金币百分比
	注意!!!!!!:
		当界面关闭的时候请调用 close
		使用一次, new一次, close一次
--]]

local UICurrencyAni 	= class("UICurrencyAni")

package.loaded["game.shop.uiCurrencyAniViewHelper"] = nil
local uiCurrencyAniViewHelper 	= require("game.shop.uiCurrencyAniViewHelper")
 
function UICurrencyAni:ctor(ui, resourceID, starPos, endPos, num, uiCallFunc)
	self.uiCallFunc = uiCallFunc

	self:countInfo(resourceID, starPos, endPos, num)
	self:starBirth(ui)
end

function UICurrencyAni:close()
	for i=#self.viewHelpers, 1, -1 do
		self.viewHelpers[i]:stop()
		self.viewHelpers[i] = nil
	end
end

--[[
生成数据
self.info = {
	ResourceID 		= (资源类型)
	resID			= (资源id)
	tag				= (标记),
	birthPos		= (出生坐标),
	endPos			= (终点坐标),
	birthAngle		= (出生朝向方向),
	birthTime		= (出生时间点),
	toEndwaitTime 	= (等待时间),
	toEndSpeed		= (移动到终点的起始速度)
	toEndAcc		= (移动到终点的加速度)
	status 			= (状态),
}
--]]
function UICurrencyAni:countInfo(resourceID, starPos, endPos, num)
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))	-- 随机种子
	
	-- resourceID = 1				-- (强制修改显示类型)1 金币 2 钻石

	local birthDelyD 	= 0.3	-- 出生延时
	local birthTimeD	= 0.2	-- 全部金币出生时间
	local waitTimeD		= 0.3	-- 爆炸到点后开始移动的等待时间
	local waitTimeAddD 	= 0.025 -- 爆炸到点后开始移动的等待增加时间
	local nodeNumD 		= 10	-- 金币默认最大最(超出rang范围的显示个数)
	-- 增加金币, 对应显示金币个数
	-- {100, 10}代表 增加100以下的金币, 显示金币个数是10个
	local rang = {
		{0, 0},
		{500, 5}, 
		{1000, 10},
		{2000, 20},
		{5000, 50},
		{10000, 60},
	}
	for _, info in ipairs(rang) do
		if num > info[1] then
			nodeNumD = info[2]
		else
			break
		end
	end
	local birthRadiusD	= 10 + nodeNumD	-- 出生半径


	self.info	= {}

	for i=1, nodeNumD do
		-- 生成数据
		local angle		= math.random(1, 360)
		local radius	= math.random(0, birthRadiusD)
		local birthPosX	= starPos.x + radius*math.cos(math.rad(angle))
		local birthPosY	= starPos.y + radius*math.sin(math.rad(angle))

		self.info[#self.info + 1] = {
			resourceID 		= resourceID,
			resID			= math.random(1, 3),
			tag				= i,
			birthPos		= cc.p(birthPosX, birthPosY),
			endPos			= endPos,
			birthAngle		= math.random(1, 360),
			birthTime		= birthTimeD*(i/nodeNumD) + birthDelyD,
			toEndwaitTime 	= waitTimeD + waitTimeAddD*i,
			toEndSpeed		= 300,
			toEndAcc		= 800,
			status 			= uiCurrencyAniViewHelper.status.birth,
		}
	end
end

function UICurrencyAni:starBirth(ui)
	self.viewHelpers = {}
	self.arrivCount = 0
	for _, info in ipairs(self.info) do
		self.viewHelpers[#self.viewHelpers + 1] = uiCurrencyAniViewHelper.new(
			ui, info, handler(self, self.arriveCallFunc))
	end
end

function UICurrencyAni:arriveCallFunc(args)
	self.arrivCount = self.arrivCount + 1
	if type(self.uiCallFunc) == "function" then
		self.uiCallFunc(self.arrivCount/#self.info)
	end
end

return UICurrencyAni