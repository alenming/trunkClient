local uiCurrencyAniViewHelper = class("uiCurrencyAniViewHelper")

local csbFile = ResConfig.Common.Csb2
local GoldEffect = {birth = 8, add = 24}

uiCurrencyAniViewHelper.status 	= {birth = 1, moveToWait = 2, wait = 3, moveToEnd = 4, ended = 5}


function uiCurrencyAniViewHelper:ctor(ui, info, arriveCallFunc)
	self.ui 	= ui
	self.info 	= info
	self.arriveCallFunc = arriveCallFunc

	self:start()
end

function uiCurrencyAniViewHelper:start()
	self.statusTime = 0
	if self.schedulerID == nil then
		self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.update), 0, false)
	end
end

function uiCurrencyAniViewHelper:stop()
	if self.schedulerID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
		self.schedulerID = nil
        if self.node then
		    self.node:removeFromParent()
            self.node = nil
        end
	end
end

function uiCurrencyAniViewHelper:close()
	self:stop()
	self.arriveCallFunc()
end

-- 等待出生-> 出生 -> 移动 -> 等待 -> 移动 -> 到达
function uiCurrencyAniViewHelper:update(dt)
	self.statusTime = self.statusTime + dt

	if self.info.status == uiCurrencyAniViewHelper.status.birth then
		if self.statusTime >= self.info.birthTime then
			local prefixStr = self.info.resourceID == UIAwardHelper.ResourceID.Gold and "gold" or "diamond"
			self.node 		= getResManager():cloneCsbNode(csbFile[prefixStr .. self.info.resID])
			self.nodeAct 	= cc.CSLoader:createTimeline(csbFile[prefixStr .. self.info.resID])
			self.node:runAction(self.nodeAct)
			self.ui:addChild(self.node)
			self.node:setPosition(self.info.birthPos)
			self.node:setTag(self.info.tag)
			--self.node:setScale(0.7)
			self.node:setRotation(self.info.birthAngle)
			self.nodeAct:play("Burst", false)

			self.info.status 	= uiCurrencyAniViewHelper.status.moveToWait
			self.statusTime		= 0

			if self.info.tag == 1 then
                MusicManager.playSoundEffect(GoldEffect.birth)
			end
		end
	elseif self.info.status == uiCurrencyAniViewHelper.status.moveToWait then
		local moveTime = (self.nodeAct:getEndFrame() - self.nodeAct:getStartFrame()) / (60*self.nodeAct:getTimeSpeed())
		if self.statusTime >= moveTime then
			self.nodeAct:play("Waiting", true)

			self.info.status 	= uiCurrencyAniViewHelper.status.wait
			self.statusTime 	= 0
		end
	elseif self.info.status == uiCurrencyAniViewHelper.status.wait then
		if self.statusTime >= self.info.toEndwaitTime then
			self.nodeAct:play("Back", false)

			self.info.status 	= uiCurrencyAniViewHelper.status.moveToEnd
			self.statusTime 	= 0
		end
	elseif self.info.status == uiCurrencyAniViewHelper.status.moveToEnd then
		local moveTolength	= self.info.toEndSpeed*self.statusTime + 0.5*self.info.toEndAcc*self.statusTime*self.statusTime
		local pointLength 	= cc.pGetDistance(self.info.birthPos, self.info.endPos)
		if moveTolength < pointLength then
			local posX = (self.info.endPos.x - self.info.birthPos.x)*moveTolength/pointLength + self.info.birthPos.x
			local posY = (self.info.endPos.y - self.info.birthPos.y)*moveTolength/pointLength + self.info.birthPos.y
			self.node:setPosition(posX, posY)
		else
			self.node:setPosition(self.info.endPos)
			self.info.status = uiCurrencyAniViewHelper.status.ended
		end
	elseif self.info.status == uiCurrencyAniViewHelper.status.ended then
		self:close()
	end
end

return uiCurrencyAniViewHelper