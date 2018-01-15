--[[
	AnimationClick 用于播放点击骨骼播放骨骼动画
	2016-2-14

	使用说明:
	ctor函数 和 setAnimationInfo函数 里面都可以初始化动画信息(资源ID和动画节点)
	在调用 playRandomAnimation 之前需要将动画的信息设置进去, 每当资源ID或动画节点改变后都要重新设置动画信息
	调用 playRandomAnimation 会随机播放一个与前一个动作列表不相同的动作列表

	local AnimationClick = require("game.comm.AnimationClick")
	self.animationClick = AnimationClick.new()

	self.animationClick:setAnimationResID(resID)
	self.animationClick:setAnimationNode(animation)

	self.animationClick:playRandomAnimation()
]]

local AnimationClick = class("AnimationClick")

function AnimationClick:ctor(resID, animateNode)
	self:setAnimationInfo(resID, animateNode)
end

function AnimationClick:setAnimationInfo(resID, animateNode)
	self:setAnimationResID(resID)
	self:setAnimationNode(animateNode)
end

function AnimationClick:setAnimationResID(resID)
	self.resID = resID				-- 动画资源id    
	self.standAct = "Stand1"	    -- 默认播放动作
	self.playAct = self.standAct    -- 正在播放的动作

	if resID ~= nil then
		-- 播放的动画名
		local animationPlayOrderConf = getConfAnimationPlayOrderItem(resID)
		if animationPlayOrderConf == nil then
			print("***** Animation_LabelCombination.csv  缺少resID: " .. resID)
		else
			self.vecActs = animationPlayOrderConf.vecAnimations
		end
		-- 动画资源信息
		self.resPath = getResPathInfoByID(resID)			
	else
		self.vecActs = nil		-- 播放的动画名
		self.resPath = nil		-- 动画资源信息
	end
end

function AnimationClick:setAnimationNode(animateNode)
	self.animateNode = animateNode	-- 动画节点
	self.playIndex = 1				-- 播放序列
	self.actIndex = 1				-- 播放序列里面的第几个动画    
	self.standAct = "Stand1"	    -- 默认播放动作
	self.playAct = self.standAct    -- 正在播放的动作

	-- 添加监听
	if animateNode ~= nil then
		if animateNode:getName() == "armature" then
		 	animateNode:getAnimation():setMovementEventCallFunc(handler(self, self.AnimationCallBack))
		elseif animateNode:getName() == "spine" then
			animateNode:registerSpineEventHandler(handler(self, self.SpineCallBack), 2)
		end
	end
end

function AnimationClick:playRandomAnimation()
	if self.animateNode == nil then
		print("请设置资源ID和动画节点, 可以通过调用 AnimationClick:setAnimationInfo(resID, animateNode) 函数")
		return
	end
	if self.vecActs == nil then
		print("请配置资源ID的动画" .. self.resID)
		return
	end

	-- 算出随机播放的动画名
	local randomMax = #self.vecActs - 1
	local randomIndex = math.random(1, randomMax)
	if randomIndex >= self.playIndex then
		self.playIndex = randomIndex + 1
	else
		self.playIndex = randomIndex
	end
	self.actIndex = 1
	self.playAct = self.vecActs[self.playIndex][self.actIndex] or self.standAct

	-- 播放动画
	if self.animateNode:getName() == "armature" then
		self.animateNode:getAnimation():play(self.playAct)
	elseif self.animateNode:getName() == "spine" then
		self.animateNode:setToSetupPose()  -- 去掉残影
		local entry = self.animateNode:setAnimation(0, self.playAct, true)
        if entry then
            self.animateNode:animationStateApply()
        end
	end
end

function AnimationClick:getNextActName()
	local actName = self.standAct
	-- 判断动作是不是播放完
	self.actIndex = self.actIndex + 1
	if self.vecActs ~= nil and self.vecActs[self.playIndex] ~= nil and self.vecActs[self.playIndex][self.actIndex] ~= nil and 
		self.actIndex <= #self.vecActs[self.playIndex] then
		-- 没播放完成, 播放下一个动作
		actName = self.vecActs[self.playIndex][self.actIndex]		
	end
	return actName
end

function AnimationClick:AnimationCallBack(armatureBack, movementType, movementID)
	if movementType == ccs.MovementEventType.loopComplete then
		if self.standAct ~= movementID then
			self.playAct = getNextActName()
			armatureBack:getAnimation():play(self.playAct)	
		end
	end
end

function AnimationClick:SpineCallBack(event)
	if self.playAct ~= self.standAct then
		self.playAct = self:getNextActName()
		if self.playAct == self.standAct then
			self.animateNode:setToSetupPose()  -- 去掉残影
		end

		local entry = self.animateNode:setAnimation(0, self.playAct, true)	
        if entry then
            self.animateNode:animationStateApply()
        end	
	end
end

return AnimationClick