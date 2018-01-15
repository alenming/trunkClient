--[[
	初始化 EqInfo.csb 节点的所有信息
--]]

local UIEquipViewHelper = {}

local eqItemFile 	= "ui_new/g_gamehall/c_collection/EqItem.csb"

local function setEqAttriLab(lab, attriID, attriValue)
    attriID = attriID or 0
    attriValue = attriValue or 0

	local value = attriValue >= 0 and "+" .. attriValue or "-" .. attriValue
	local str = CommonHelper.getRoleAttributeString(attriID) or "nil %d"
	lab:setString(string.format(str, value))
end

function UIEquipViewHelper:setCsbInfo(csb, heroDyID, eqDyID, listHeight)
	if eqDyID == nil then
		csb:setVisible(false)
		return
	else
		csb:setVisible(true)
	end

	self.csb 		= csb
	self.heroDyID	= heroDyID
	self.eqDyID 	= eqDyID
	self.listHeight = listHeight or 341

	-- 模型和配表信息
	local cardBagModel 	= getGameModel():getHeroCardBagModel()
	if heroDyID == nil then
		self.heroModel		= nil
	else
		self.heroModel		= cardBagModel:getHeroCard(heroDyID)
	end
	self.eqModel 		= getGameModel():getEquipModel()
	self.eqInfo 		= self.eqModel:getEquipInfo(eqDyID)
	--CsbTools.printValue(self.eqInfo, "eqinfo")
	if not self.eqInfo then
		return
	end

	local eqConfID 		= self.eqModel:getEquipConfId(eqDyID)
	print("装备配置表ID", eqConfID)
	self.eqConf 		= getEquipmentConfItem(eqConfID)
	self.propConf 		= getPropConfItem(eqConfID)
	self.baseAttriCout	= self.eqInfo.nMainPropNum

	-- 初始化上部分显示
	self:initHeadInfo(csb)
	-- 初始化可变区域显示
	self:initDyBodyInfo()
end

function UIEquipViewHelper:setCsbByEquipInfo(csb, equipInfo, listHeight)
    if type(equipInfo) ~= "table" then
		csb:setVisible(false)
		return
	else
		csb:setVisible(true)
	end

	self.csb = csb
	self.listHeight = listHeight or 341
	self.eqInfo = equipInfo
	self.eqConf = getEquipmentConfItem(self.eqInfo.confId)
	self.propConf = getPropConfItem(self.eqInfo.confId)
	self.baseAttriCout = self.eqInfo.nMainPropNum

	-- 初始化上部分显示
	self:initHeadInfo()
	-- 初始化可变区域显示
	self:initDyBodyInfo()
end

function UIEquipViewHelper:initHeadInfo()
    -- 装备图标
    local eqCsb 	= CsbTools.getChildFromPath(self.csb, "EqItem")
    UIAwardHelper.setPropItemOfConf(eqCsb, self.propConf, 0)

    -- 装备介绍Label
    local eqNameLab	= CsbTools.getChildFromPath(self.csb, "Name")
    local eqLvLab 	= CsbTools.getChildFromPath(self.csb, "Lv")
    local eqJobLab 	= CsbTools.getChildFromPath(self.csb, "Job")
    local eqPartLab = CsbTools.getChildFromPath(self.csb, "Body")
    -- 文字
    local eqNameStr	= CommonHelper.getPropString(self.propConf.Name)
    local eqLvStr 	= string.format(CommonHelper.getUIString(195), self.eqConf.Level)
    local eqJobStr 	= CommonHelper.getUIString(196)
    local jobLanID 	= {521, 524, 522, 523, 525, 520}
    for _, job in ipairs(self.eqConf.Vocation) do
        eqJobStr = eqJobStr .. CommonHelper.getUIString(jobLanID[job]) .. " "
    end
    local partLanID = {612, 613, 614, 615, 616, 617}
    eqPartLab:setString(CommonHelper.getUIString(partLanID[self.eqConf.Parts]))
    local vecC3b = getItemLevelSettingItem(self.propConf.Quality).Color
    -- 设置显示内容
    eqNameLab:setString(eqNameStr)
    eqLvLab:setString(eqLvStr)
    eqJobLab:setString(eqJobStr)
    eqNameLab:setTextColor(cc.c3b(vecC3b[1] or 204, vecC3b[2] or 102, vecC3b[3] or 51))	
end

function UIEquipViewHelper:initDyBodyInfo()
	-- 重置显示区域大小
	local list		= CsbTools.getChildFromPath(self.csb, "EqInfoListView")
	list:setContentSize(cc.size(list:getContentSize().width, self.listHeight))
	list:jumpToTop()
	list:setScrollBarEnabled(false)

	self:initBaseInfo(list)
	self:initAddInfo(list)
	self:initSuitInfo(list)
	self:initSuitAbilityInfo(list)
	self:initDescInfo(list)

	list:requestDoLayout()
end

function UIEquipViewHelper:initBaseInfo(list)
	local scroll	= CsbTools.getChildFromPath(list, "BasicAttri")
	--local lineImg 	= CsbTools.getChildFromPath(list, "LineImage1")
	local innerSize = scroll:getContentSize()
	local lab 	= {}
	for i=0, 8 do
		lab[i]	= CsbTools.getChildFromPath(scroll, "AddAttri_" .. i)
	end
	lab[0]:setString(CommonHelper.getUIString(197))
	innerSize.height = 0

	local count = 0
	for i=1, 8 do
		if i <= self.baseAttriCout then
			local effectID 		= self.eqInfo.eqEffectIDs[i]
			local effectValue 	= self.eqInfo.eqEffectValues[i]
			if effectID ~= 0 and effectValue ~= 0 then
				count = count + 1
				setEqAttriLab(lab[count], effectID, effectValue)
				innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
			end
		end
	end

	-- if innerSize.height == 0 then
	-- 	lineImg:setVisible(false)
	-- else
	-- 	lineImg:setVisible(true)
	-- end

	scroll:setContentSize(innerSize)
end

function UIEquipViewHelper:initAddInfo(list)
	local scroll	= CsbTools.getChildFromPath(list, "AddAttri")
	--local lineImg 	= CsbTools.getChildFromPath(list, "LineImage2")
	local innerSize = scroll:getContentSize()
	local lab 	= {}
	for i=0, 8 do
		lab[i]	= CsbTools.getChildFromPath(scroll, "AddAttri_" .. i)
	end
	lab[0]:setString(CommonHelper.getUIString(198))
	innerSize.height = 0

	local count = 0
	for i=1, 8 do
		if i > self.baseAttriCout then
			local effectID 		= self.eqInfo.eqEffectIDs[i]
			local effectValue 	= self.eqInfo.eqEffectValues[i]
			if effectID ~= 0 and effectValue ~= 0 then
				count = count + 1
				setEqAttriLab(lab[count], effectID, effectValue)		
				innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
			end
		end
	end

	-- if innerSize.height == 0 then
	-- 	lineImg:setVisible(false)
	-- else
	-- 	lineImg:setVisible(true)
	-- end

	scroll:setContentSize(innerSize)
end

function UIEquipViewHelper:initSuitInfo(list)
	local scroll	= CsbTools.getChildFromPath(list, "SuitEq")
	--local lineImg 	= CsbTools.getChildFromPath(list, "LineImage3")
	local innerSize = scroll:getContentSize()

	local heroEqs = {}
	if self.heroModel ~= nil then
		heroEqs = self.heroModel:getEquips()
	end

	if self.eqConf.Suit ~= 0 then
		-- 套装信息
		local suitConf = getSuitConfItem(self.eqConf.Suit)
		if suitConf == nil then print("suit is nil", self.eqConf.Suit) end	

		local lab 	= {}
		for i=0, 6 do
			lab[i]	= CsbTools.getChildFromPath(scroll, "AddAttri_" .. i)
		end
		lab[0]:setString(CommonHelper.getPropString(suitConf.Name))

		local count = 0
		for i=1,6 do
			if suitConf.Eq[i] ~= nil and suitConf.Eq[i] ~= 0 then
				count = count + 1
				local otherEqConf = getEquipmentConfItem(suitConf.Eq[i])
				if otherEqConf == nil then print("suit eqConf is nil", eqConf.Suit, suitConf.Eq[i]) end
				local propConf 	= getPropConfItem(suitConf.Eq[i])
				if propConf == nil then print("no this eq in prop", eqConf.ID) end

                if self.eqModel then
				    -- 判断是否穿上了该装备
				    local isOwn = false
				    for _, eqDyID in pairs(heroEqs) do
					    local eqConfID = self.eqModel:getEquipConfId(eqDyID)
					    if eqConfID == suitConf.Eq[i] and eqConfID ~= 0 then
						    isOwn = true
						    break
					    end
				    end
                end

				-- 设置该装备显示
				lab[count]:setString(CommonHelper.getPropString(propConf.Name))
				innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
				lab[count]:setTextColor(isOwn and cc.c3b(0, 128, 0) or cc.c3b(127, 127, 127))
			end
		end
	else
		innerSize.height = 0
	end

	-- if innerSize.height == 0 then
	-- 	lineImg:setVisible(false)
	-- else
	-- 	lineImg:setVisible(true)
	-- end

	scroll:setContentSize(innerSize)
end

function UIEquipViewHelper:initSuitAbilityInfo(list)
	local scroll	= CsbTools.getChildFromPath(list, "EqsEffect")
	--local lineImg 	= CsbTools.getChildFromPath(list, "LineImage4")
	local innerSize = scroll:getContentSize()

	local heroEqs = {}
	if self.heroModel ~= nil then
		heroEqs = self.heroModel:getEquips()
	end
	if self.eqConf.Suit ~= 0 then
		local eqModel 		= getGameModel():getEquipModel()
		-- 套装信息
		local suitConf = getSuitConfItem(self.eqConf.Suit)
		if suitConf == nil then print("suit is nil", self.eqConf.Suit) end

		local descLab 	= {}
		local attriLab 	= {}
		local lanID = {199, 200, 201, 202, 203}
		for i=2, 6 do
			descLab[i]	= CsbTools.getChildFromPath(scroll, "EqsEffect_" .. i)
			attriLab[i]	= CsbTools.getChildFromPath(scroll, "IntroText_" .. i)
			descLab[i]:setString(CommonHelper.getUIString(lanID[i - 1]))
		end

		-- 计算套装数
		local suitNum		= 0
		local allSuitNum 	= 0
		for i=1,6 do
			if suitConf.Eq[i] ~= nil and suitConf.Eq[i] ~= 0 then
				allSuitNum = allSuitNum + 1

				local otherEqConf = getEquipmentConfItem(suitConf.Eq[i])
				if otherEqConf == nil then print("suit eqConf is nil", self.eqConf.Suit, suitConf.Eq[i]) end
				local propConf 	= getPropConfItem(suitConf.Eq[i])
				if propConf == nil then print("no this eq in prop", self.eqConf.ID) end

				-- 判断是否穿上了该装备
				for _, eqDyID in pairs(heroEqs) do
					local eqConfID = eqModel:getEquipConfId(eqDyID)
					if eqConfID == suitConf.Eq[i] and eqCondID ~= 0 then
						suitNum = suitNum + 1
						break
					end
				end
			end
		end

		for i=2, allSuitNum do
			descLab[i]:setTextColor((suitNum >= i) and cc.c3b(255, 13, 0) or cc.c3b(127, 127, 127))
			attriLab[i]:setTextColor((suitNum >= i) and cc.c3b(174, 0, 255) or cc.c3b(127, 127, 127))
			local ability = suitConf.Ability[i]
			if ability ~= nil and ability ~= 0 and ability.EquipEffect.AbilityDesc ~= 0 then
				local abilityStr = CommonHelper.getPropString(ability.EquipEffect.AbilityDesc)
				attriLab[i]:setString(abilityStr)
			else
				attriLab[i]:setString(CommonHelper.getUIString(570))
			end
		end

		innerSize.height = descLab[2]:getPositionY() - attriLab[allSuitNum]:getPositionY() + 11
	else
		innerSize.height = 0
	end
	
	-- if innerSize.height == 0 then
	-- 	lineImg:setVisible(false)
	-- else
	-- 	lineImg:setVisible(true)
	-- end	
	scroll:setContentSize(innerSize)
end

function UIEquipViewHelper:initDescInfo(list)
	local scroll	= CsbTools.getChildFromPath(list, "Intro")
	local innerSize = scroll:getContentSize()
	local lab 		= CsbTools.getChildFromPath(scroll, "IntroText")

	lab:setString(CommonHelper.getPropString(self.propConf.Desc))

	innerSize.height = lab:getContentSize().height
	scroll:setContentSize(innerSize)
end

return UIEquipViewHelper