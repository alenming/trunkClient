--[[
	道具浮动tips显示
	使用方法: 
		1. UI打开创建对象
			local PropTips = require("game.comm.PropTips")
			self.propTips = PropTips.new()
		2. 将需要点击弹出提示的节点添加提示
			self.propTips:addPropTips(touchNode, propConf)
		3. UI关闭的时候将tips移除
			self.propTips:removePropAllTips()
			self.propTips = nil

    优化帧率: 由原先的一个对象有多个propTips节点,改成只有固定的一个propTips节点
--]]

local PropTips = class("PropTips")

local TempTag = 1258000
local tempName = "propTipParentNode"

function PropTips:ctor()
	self.tipsPath = ResConfig.Common.Csb2.propTips

    self:autoAddTipsNode()    

	-- self.tipsInfo = {touchNode = propConf, ...}
	self.tipsInfo = {}
end

function PropTips:addPropTips(touchNode, propConf, offset)
    if touchNode == nil then 
        print("PropTips touchNode is nil") 
        return 
    end
 
    self.tipsInfo[touchNode] = propConf
    
    self:autoAddTipsNode()
    self:setTouchInfo(touchNode, offset)
end

function PropTips:setTouchInfo(touchNode, offset)
    offset = offset or cc.p(0,0)
    touchNode:setTouchEnabled(true)
    touchNode:setSwallowTouches(false)

    touchNode:addTouchEventListener(function(obj, touchType)
        if self.tipsInfo[obj] == nil then
            return
        end

        if touchType == 0 then
            self:setTipsInfo(self.tipsInfo[obj])

            local porpTipsPos = self:countDisplayPos(obj, offset)
            self.tipsNode:setPosition(porpTipsPos)
            self.tipsNode:setVisible(true)
            CommonHelper.playCsbAnimation(self.tipsNode, "Appear", false, nil)

        elseif touchType == 1 then
            local porpTipsPos = self:countDisplayPos(obj, offset)
            self.tipsNode:setPosition(porpTipsPos)

        elseif touchType == 2 or touchType == 3 then
            -- 释放, 取消
            CommonHelper.playCsbAnimation(self.tipsNode, "Hide", false, nil)
        end
    end)
end

-- 如果存在则不创建, 不存在则创建
function PropTips:autoAddTipsNode()
    if self.tipsNode ~= nil then
        return
    end

    -- 增加中间节点, 避免关闭游戏时候的崩溃
    -- 关闭游戏时,会遍历删除场景节点,而场景节点可能会调用 propTips:removePropAllTips()将场景节点的propTips删除
    local tempNode = display.getRunningScene():getChildByTag(TempTag)
    if tempNode == nil or tempNode:getName() ~= tempName then
        tempNode = cc.Node:create()
        tempNode:setName(tempName)
        tempNode:setTag(TempTag)
        display.getRunningScene():addChild(tempNode, 9999)
    end

    self.tipsNode = getResManager():cloneCsbNode(self.tipsPath)
    tempNode:addChild(self.tipsNode, 10)
    self.tipsNode:setVisible(false)

    -- 设置提示信息
    self.propCsb   = CsbTools.getChildFromPath(self.tipsNode, "TipPanel/AllItem")
    self.nameLab   = CsbTools.getChildFromPath(self.tipsNode, "TipPanel/NameLabel")
    self.ownLab    = CsbTools.getChildFromPath(self.tipsNode, "TipPanel/Text_3")
    self.descLab   = CsbTools.getChildFromPath(self.tipsNode, "TipPanel/InfoLabel")

    local tipPanel = CsbTools.getChildFromPath(self.tipsNode, "TipPanel")
    self.tipSize = tipPanel:getContentSize()
end

function PropTips:setTipsInfo(propConf)
	local itemCount = 0
	local nameStr = "unKnow"
	local descStr = "unKonw"

	if propConf.Type == UIAwardHelper.ItemType.HeroCard then
		local hasHero = getGameModel():getHeroCardBagModel():hasHeroCard(propConf.TypeParam[1])
		itemCount = hasHero and 1 or 0
		nameStr = CommonHelper.getHSString(propConf.Name)
		descStr = CommonHelper.getHSString(propConf.Desc)

    elseif propConf.Type == UIAwardHelper.ItemType.Frag then      
        local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(propConf.TypeParam[1])
        itemCount = heroModel and heroModel:getFrag() or 0
        nameStr = CommonHelper.getPropString(propConf.Name)
        descStr = CommonHelper.getPropString(propConf.Desc)

	elseif propConf.Type == UIAwardHelper.ItemType.SummonerCard then
		itemCount = getGameModel():getSummonersModel():hasSummoner(propConf.TypeParam[1] or 0) and 1 or 0
		nameStr = CommonHelper.getHSString(propConf.Name)
		descStr = CommonHelper.getHSString(propConf.Desc)

    elseif propConf.Type == UIAwardHelper.ItemType.Equip then
		local eqConf = getEquipmentConfItem(propConf.ID)
		nameStr = CommonHelper.getPropString(propConf.Name)
		if eqConf then
			local eqLvStr 	= string.format(CommonHelper.getUIString(195), eqConf.Level)
			local eqJobStr 	= CommonHelper.getUIString(196)
			local jobLanID 	= {521, 524, 522, 523, 525, 520}
			for _, job in ipairs(eqConf.Vocation) do
				eqJobStr = eqJobStr .. CommonHelper.getUIString(jobLanID[job]) .. " "
			end
			descStr = eqLvStr .. "\n" .. eqJobStr
		end

		local eqs = getGameModel():getEquipModel():getEquips()
		for _, eqInfo in pairs(eqs) do
			if eqInfo.confId == propConf.ID then
				itemCount = itemCount + 1
			end
		end

    elseif propConf.Type == UIAwardHelper.ItemType.EquipCreat then
		nameStr = CommonHelper.getPropString(propConf.Name)

        local eqConfID = 0
        local eqConf = nil
        local eqCreateID = propConf.TypeParam[1]
        if eqCreateID then
            local eqCreateConf = getEquipPropCreateConfItem(eqCreateID)
            if eqCreateConf then
                eqConfID = eqCreateConf.nEquipID
                eqConf = getEquipmentConfItem(eqConfID)
            end
        end
        if eqConf then
			local eqLvStr 	= string.format(CommonHelper.getUIString(195), eqConf.Level)
			local eqJobStr 	= CommonHelper.getUIString(196)
			local jobLanID 	= {521, 524, 522, 523, 525, 520}
			for _, job in ipairs(eqConf.Vocation) do
				eqJobStr = eqJobStr .. CommonHelper.getUIString(jobLanID[job]) .. " "
			end
			descStr = eqLvStr .. "\n" .. eqJobStr
		end

        local eqs = getGameModel():getEquipModel():getEquips()
		for _, eqInfo in pairs(eqs) do
			if eqInfo.confId == eqConfID then
				itemCount = itemCount + 1
			end
		end

    elseif propConf.Type == UIAwardHelper.ItemType.Head then
        itemCount = getGameModel():getHeadModel():isUnlocked(propConf.TypeParam[1]) and 1 or 0
        nameStr = CommonHelper.getPropString(propConf.Name)
        descStr = CommonHelper.getPropString(propConf.Desc)

	else
		itemCount = getGameModel():getBagModel():getItems()[propConf.ID] or 0
		nameStr = CommonHelper.getPropString(propConf.Name)
		descStr = CommonHelper.getPropString(propConf.Desc)
	end

    self.nameLab:setString(nameStr)
    self.ownLab:setString(string.format(CommonHelper.getUIString(61), itemCount))
    self.descLab:setString(descStr)

    -- 资源类道具隐藏数量
    self.ownLab:setVisible(propConf.Type ~= UIAwardHelper.ItemType.Resource)

    local color = getItemLevelSettingItem(propConf.Quality).Color
    self.nameLab:setTextColor(cc.c3b(color[1], color[2], color[3]))

    UIAwardHelper.setAllItemOfConf(self.propCsb, propConf, 0)
end

function PropTips:countDisplayPos(touchNode, offset)
    local touchSize = touchNode:getContentSize()
    local touchNodePos  = touchNode:convertToWorldSpace(cc.p(0,0))
    local tipsNodePos   = self.tipsNode:convertToWorldSpace(cc.p(0,0))
    local tipsNodePosX, tipsNodePosY = self.tipsNode:getPosition()
    local posX = tipsNodePosX - (tipsNodePos.x - touchNodePos.x) + touchSize.width*0.5 + offset.x
    local posY = tipsNodePosY - (tipsNodePos.y - touchNodePos.y) + touchSize.height + offset.y

    if posX > display.width - self.tipSize.width / 2 then
        posX = display.width - self.tipSize.width / 2
    elseif posX < self.tipSize.width / 2 then
        posX = self.tipSize.width / 2
    end
    if posY > display.height - self.tipSize.height then
        posY = display.height - self.tipSize.height
    end

    return cc.p(posX, posY)
end

function PropTips:removePropAllTips()
	self.tipsInfo = {}
    local tempNode = display.getRunningScene():getChildByTag(TempTag)
    if tempNode ~= nil and tempNode:getName() == tempName then
        tempNode:removeChild(self.tipsNode)
    end
    self.tipsNode = nil
end

function PropTips:removePropTips(touchNode)
    if self.tipsInfo[touchNode] then
	   self.tipsInfo[touchNode] = nil
    end
end

return PropTips