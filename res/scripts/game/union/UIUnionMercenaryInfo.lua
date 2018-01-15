--[[
		佣兵信息界面
--]]

local UIUnionMercenaryInfo = class("UIUnionMercenaryInfo", require("common.UIView"))
local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()
local UIUnionMercenaryEquipInfo = require("game.union.UIUnionMercenaryEquipInfo")
local AnimationClick= require("game.comm.AnimationClick")
local RichLabel     = require("richlabel.RichLabel")
local csbFile       = ResConfig.UIUnionMercenaryInfo.Csb2
local eqItemFile    = "ui_new/g_gamehall/c_collection/EqItem.csb"
local featureFile   = "ui_new/g_gamehall/c_card/FeaturesItem.csb"
local eqPartStatus  = {noEqDress = 1, ownEqDress = 2, noEqReplace = 3, ownEqReplace = 4, ownEqNoReplace = 5}
local attribute     = {hp = 114, pAttack = 106, mAttack = 107, pGuard = 108, mGuard = 109, miss = 207}
local jobLanIDs 	= {[1] = 521, [2] = 524, [3] = 522, [4] = 523, [5] = 525, [6] = 520}
local uiTypeLanIDs 	= {frag = 11, mercenary = 2040}
local rareAni 		= {[1] = "None", [3] = "Blue", [4] = "Voilet", [5] = "Golden"}

function UIUnionMercenaryInfo:ctor()
	-- 初始化UI
	self.rootPath 	= csbFile.heroInfo
	self.root 		= getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)
	self.curDyId 	= 0 	-- 当前显示的佣兵动态ID
	self.curOrder	= 0

	-- 返回按钮
	local backBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, handler(self, self.backBtnCallBack))

	-- 装备显示界面
	self.eqInfoCsb = CsbTools.getChildFromPath(self.root, "MainPanel/EquipInfo")
	CommonHelper.layoutNode(self.eqInfoCsb)
	self.UIUnionMercenaryEquipInfo = UIUnionMercenaryEquipInfo.new(self.eqInfoCsb)
	self.eqInfoSize = CsbTools.getChildFromPath(self.eqInfoCsb, "EqInfoPanel"):getBoundingBox()

	-- 屏蔽层
	self.mask 		= CsbTools.getChildFromPath(self.root, "MainPanel/MaskPanel")
	self.mask:addClickEventListener(handler(self, self.maskCallBack))

	-- 切换英雄按钮
	local toPreBtn	= CsbTools.getChildFromPath(self.root, "LeftButton")
	local toNextBtn	= CsbTools.getChildFromPath(self.root, "RightButton")
	toPreBtn:setTag(10001)
	toNextBtn:setTag(10002)
	CsbTools.initButton(toPreBtn, handler(self, self.headAndBackCallBack))
	CsbTools.initButton(toNextBtn, handler(self, self.headAndBackCallBack))

	------------------英雄总览界面左面板----------------
	local leftPanel = CsbTools.getChildFromPath(self.root, "MainPanel/LeftPanel")

	-- 英雄文字介绍相关(描述, 名称, 职业, 种族)
	self.heroDescLab	= CsbTools.getChildFromPath(leftPanel, "IntroText")
	self.heroNameLab	= CsbTools.getChildFromPath(leftPanel, "NameLabel")
	self.heroJobLab		= CsbTools.getChildFromPath(leftPanel, "Profesion")
	self.heroRaceImg	= CsbTools.getChildFromPath(leftPanel, "JobImage")

	-- 英雄星级
	self.starCsb 	= CsbTools.getChildFromPath(leftPanel, "HeroStar")

	-- 英雄骨骼动画
	local aniClickLayout= CsbTools.getChildFromPath(leftPanel, "HeroPanel")
	self.heroAniNode	= CsbTools.getChildFromPath(aniClickLayout, "HeroNode")
	self.animationClick = AnimationClick.new()
	self.originX, self.originY = self.heroAniNode:getPosition()
	aniClickLayout:setTouchEnabled(true)
	aniClickLayout:addClickEventListener(handler(self, self.aniClickCallBack))

	-- 6件装备
	for i=1,6 do
		self["eqBtn_" .. i]	= CsbTools.getChildFromPath(leftPanel, "EqButton" .. i)
		self["eqCsb_" .. i]	= CsbTools.getChildFromPath(self["eqBtn_" .. i], "EqItem")
		local bgImg 		= CsbTools.getChildFromPath(self["eqCsb_" .. i], "EqItemPanel/EqBgImage")
		
		CsbTools.replaceSprite(bgImg, getIconSettingConfItem().EqIcon[i])
		self["eqBtn_" .. i]:setTag(i)
		CsbTools.initButton(self["eqBtn_" .. i], handler(self, self.eqBtnCallBack), nil, nil, "EqItem")		
	end
	self.autoWearBtn	= CsbTools.getChildFromPath(leftPanel, "AutoWearButton")
	self.autoWearBtn:setVisible(false)

	-- 品质特效
	self.rareCsb = CsbTools.getChildFromPath(leftPanel, "LevelAura")
	
	------------------英雄总览界面右侧面板----------------
	local rightPanel = CsbTools.getChildFromPath(self.root, "MainPanel/RightPanel")

	-- 英雄等级
	self.heroLvLab	= CsbTools.getChildFromPath(rightPanel, "LevelFontLabel")
	self.heroMaxLvLab= CsbTools.getChildFromPath(rightPanel, "Level")

	--佣兵标志
	-- 界面类型 (未获得, 隐藏, 佣兵)
	self.uiTypeLab 	= CsbTools.getChildFromPath(rightPanel, "MercenaryLogo")

	-- 英雄经验
	self.expLab		= CsbTools.getChildFromPath(rightPanel, "ExpNum")
	self.expBar		= CsbTools.getChildFromPath(rightPanel, "ExpLoadingBar")
	self.expBgImg	= CsbTools.getChildFromPath(rightPanel, "LoadingBarBg")

	-- 英雄星级, 升星按钮
	self.fragPanel 	= CsbTools.getChildFromPath(rightPanel, "CardPanel")
	self.fragLab	= CsbTools.getChildFromPath(self.fragPanel, "CardCount")
	self.heroFragImg= CsbTools.getChildFromPath(self.fragPanel, "HeroImage")
	self.heroFragImg:setTouchEnabled(false)
	--CsbTools.initButton(self.fragPanel, handler(self, self.fragCallBack))


	-- 10个属性 5个存在加成的属性
	local lanID = {417, 416, 418, 419, 427, 420, 428, 421, 422, 423}
	for i=1, 10 do
		self["attriNameLab_" .. i]	= CsbTools.getChildFromPath(rightPanel, "Attri_" .. i)
		self["attriLab_" .. i]		= CsbTools.getChildFromPath(rightPanel, "Attri_" .. i .. "_0")
		self["attriNameLab_" .. i]:setString(CommonHelper.getUIString(lanID[i]))
	end
	for i=1, 5 do
		self["attriAddLab_" .. i]	= CsbTools.getChildFromPath(rightPanel, "AttriAdd_" .. i)
	end

	-- 技能cbs节点
	self.skillPanel	= CsbTools.getChildFromPath(rightPanel, "SkillPanel")
	self.skillLabPanel	= CsbTools.getChildFromPath(self.skillPanel, "Image_bg4")
	self.skillNodeInfo = {}
	for i=1, 4 do
		self.skillNodeInfo[i] = {}
		self.skillNodeInfo[i].btn = CsbTools.getChildFromPath(self.skillPanel, "SkillButton_" .. i)
		self.skillNodeInfo[i].csb = CsbTools.getChildFromPath(self.skillNodeInfo[i].btn, "SkillItem")
		CsbTools.initButton(self.skillNodeInfo[i].btn, handler(self, self.skillCallBack), nil, nil, "SkillItem")
	end

	-- 技能名称, 等级, 消耗描述, 技能描述, 技能升级按钮
	self.skillNameLab	= CsbTools.getChildFromPath(self.skillLabPanel, "SkillName")
	self.skillCostLab1	= CsbTools.getChildFromPath(self.skillLabPanel, "ReTime")
	self.skillCostLab2 = CsbTools.getChildFromPath(self.skillLabPanel, "RePower")
	self.skillDescLab	= CsbTools.getChildFromPath(self.skillLabPanel, "SkillIntro")

	-- 天赋, 升级, 升星, 获取路径 按钮
	self.giftBtn = CsbTools.getChildFromPath(rightPanel, "GiftButton")
	self.upStarBtn 	= CsbTools.getChildFromPath(rightPanel, "UpStarButton")
	self.upLvBtn	= CsbTools.getChildFromPath(rightPanel, "UpLevelButton")
	self.getPathBtn = CsbTools.getChildFromPath(rightPanel, "GetPathButton")

	self.giftBtn:setVisible(false)
	self.upStarBtn:setVisible(false)
	self.upLvBtn:setVisible(false)
	self.getPathBtn:setVisible(false)
end

function UIUnionMercenaryInfo:onOpen(_, curDyId)
	self.curDyId = curDyId
	-- 从公会佣兵那里得到所有卡牌idList
	self.idList = UnionMercenaryModel:getUnionMercenaryList()

	self.mask:setTouchEnabled(false)
	self.addAniFinish = true 	-- 加载骨骼动画完成

	self:showUIInfo(self.curDyId)
end

function UIUnionMercenaryInfo:onClose()
	self.heroAniNode:removeAllChildren()
	self:closeUpdate()
end

function UIUnionMercenaryInfo:onTop(preUIID, args)
	local heroModel = UnionMercenaryModel:getCurMercenaryInfo(self.curDyId)
	local heroConf = getSoldierConfItem(heroModel.heroId, heroModel.heroStar)
    
    if preUIID == UIManager.UI.UIHeroTalent then
		-- 重新显示英雄天赋信息
		self:initTalentInfo(heroModel)
	elseif preUIID == UIManager.UI.UIEquipBag then
		self.mask:setTouchEnabled(false)
		CommonHelper.playCsbAnimate(self.root, self.rootPath, "Normal", false, nil, true)
	elseif preUIID == UIManager.UI.UIHeroQuickTo then
		self:initHeroStarInfo(heroModel, heroConf)
	end
end

-------------------- 按钮回调 ----------------------
function UIUnionMercenaryInfo:backBtnCallBack(ref)
	UIManager.close()
end

-- 点击到屏蔽层, 取消屏蔽, 取消装备显示
function UIUnionMercenaryInfo:maskCallBack(ref)
	self.mask:setTouchEnabled(false)
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
end

--前后切换英雄回调
function UIUnionMercenaryInfo:headAndBackCallBack(ref)
	if table.maxn(self.idList) == 1 then
		return
	end

	local order = 1
	local tag = ref:getTag()
	if tag == 10001 then
		for i = 1, #self.idList do
			if self.idList[i] == self.curDyId then
				order = i
				break
			end
		end

		if order == 1 then
				order = #self.idList
		else
				order = order - 1
		end
	elseif tag == 10002 then
		for i = 1, #self.idList do
			if self.idList[i] == self.curDyId then
				order = i
				break
			end
		end

		if order == #self.idList then
				order = 1
		else
				order = order + 1
		end
	end

	local nowDyid = self.idList[order]
   	self.curOrder = order
   	print("信息是否已经存在本地了nowDyid self.curOrder", nowDyid, self.curOrder)
   	if UnionMercenaryModel:getCurMercenaryInfo(nowDyid) then
   		print("已经存在本地,直拉刷新界面")
   		self:toNextBtnCallBack()	
        return
   	end
	print("本地没有数据 开始发送讲拉取佣兵详细信息协议 nowDyid, self.curOrder", nowDyid, self.curOrder)

    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryGetCS)
    bufferData:writeInt(nowDyid)
   	NetHelper.request(buffData)

end

-- 切换到下一个英雄
function UIUnionMercenaryInfo:toNextBtnCallBack()
	if self.mask:isTouchEnabled() then
		self.mask:setTouchEnabled(false)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
	else
		-- 重新显示
		self:showUIInfo(self.idList[self.curOrder])	
        EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIUnionMercenaryInfo)	
	end
end

-- 装备框点击回调
function UIUnionMercenaryInfo:eqBtnCallBack(ref)
	local eqPart = ref:getTag()
	local heroModel = UnionMercenaryModel:getCurMercenaryInfo(self.curDyId)
	local confId = heroModel.equips[eqPart]

	if confId ~= 0 then
		print("heroModel.dyId, confId, 1, heroModel.heroId",heroModel.dyId, confId, 1, heroModel.heroId)
		self.UIUnionMercenaryEquipInfo:setUIInfo(heroModel.dyId, confId, 1, heroModel.heroId)
		self.mask:setTouchEnabled(true)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOn", false, function()end, true)
        -- 移动该装备的右侧
        local wPos1 = ref:convertToWorldSpace(cc.p(0,0))
        local wPos2 = self.eqInfoCsb:convertToWorldSpace(cc.p(0,0))
        local pos2  = self.eqInfoCsb:getPosition()
        local posX 	= pos2 - (wPos2.x - wPos1.x) + (self.eqInfoSize.width/2 + ref:getBoundingBox().width)
        self.eqInfoCsb:setPositionX(posX)
	end
end


-- 技能点击回调
function UIUnionMercenaryInfo:skillCallBack(ref)
	local skillID = ref:getTag()
	if value ~= 0 then
		local skillConf = getSkillConfItem(skillID)
		self:reShowSkillLab(skillConf)

		for i=1, 4 do
			if ref ~= self.skillNodeInfo[i].btn then
				CommonHelper.playCsbAnimation(self.skillNodeInfo[i].csb, "Normal", false, nil)
			else
				CommonHelper.playCsbAnimation(self.skillNodeInfo[i].csb, "On", false, nil)
			end
		end
	end
end

-- 重新显示技能介绍文本
function UIUnionMercenaryInfo:reShowSkillLab(skillConf)
	if skillConf then
		self.skillLabPanel:setVisible(true)
		self.skillNameLab:setString(CommonHelper.getHSSkillString(skillConf.Name))
		local costStr1 = (skillConf.CostDesc1 ~= 0) and CommonHelper.getHSSkillString(skillConf.CostDesc1) or ""
		local costStr2 = (skillConf.CostDesc2 ~= 0) and CommonHelper.getHSSkillString(skillConf.CostDesc2) or ""
		self.skillCostLab1:setString(costStr1)
		self.skillCostLab2:setString(costStr2)
        self.skillDescLab:setString(CommonHelper.getHSSkillString(skillConf.Desc))
        -- 设置位置
		local costLab2PosX 	= self.skillCostLab2:getPositionX()
		local costLab2Width = self.skillCostLab2:getContentSize().width
		self.skillCostLab1:setPositionX(costLab2PosX - costLab2Width - 5)
	else
		self.skillLabPanel:setVisible(false)
	end
end

-- 创建骨骼动画回调
function UIUnionMercenaryInfo:createAniCallBack(animation, id)
	self.addAniFinish = true
	if animation and id == self.showAnimationID then
		self.heroAniNode:removeAllChildren()
		self.heroAniNode:addChild(animation)
		self.animationClick:setAnimationNode(animation)

		local heroModel = UnionMercenaryModel:getCurMercenaryInfo(self.curDyId)
	    CommonHelper.setRoleZoom(heroModel.heroId, animation, self.heroAniNode, self.originX, self.originY)
	end
end

-- 骨骼动画点击播放随机动作
function UIUnionMercenaryInfo:aniClickCallBack(touch, event)
	self.animationClick:playRandomAnimation()
end

------------------- 界面显示 -----------------------
-- 显示英雄信息界面信息
function UIUnionMercenaryInfo:showUIInfo(dyId)
	self.curDyId = dyId

	local heroModel = UnionMercenaryModel:getCurMercenaryInfo(self.curDyId)

	if heroModel == nil then 
		return 
	end
	local heroConf = getSoldierConfItem(heroModel.heroId, heroModel.heroStar)
	if heroConf == nil then 
		print("heroConf is nil", heroModel.heroId, heroModel.heroStar) 
		return
	end

	-- 重新显示英雄文字信息
	self:reShowHeroInfo(heroConf)
	-- 重新显示英雄装备信息
	self:reShowEqsInfo(heroModel)
	-- 重新显示英雄等级信息
	self:initHeroLvInfo(heroModel)
	-- 重新显示英雄星级信息
	self:initHeroStarInfo(heroModel, heroConf)
	-- 重新显示英雄部分属性信息
	self:initAttrisInfo(self.curDyId, heroConf)
	-- 重新显示英雄技能信息
	self:initSkillInfo(heroConf)
	-- 重新显示装备节能
	self:initEqSkillInfo(heroModel, heroConf)
end

-- 重新显示英雄信息
function UIUnionMercenaryInfo:reShowHeroInfo(heroConf)
	self.heroNameLab:setString(CommonHelper.getHSString(heroConf.Common.Name))
	self.heroDescLab:setString(CommonHelper.getHSString(heroConf.Common.Desc))
	self.heroJobLab:setString(CommonHelper.getUIString(jobLanIDs[heroConf.Common.Vocation]) or "")
	CsbTools.replaceImg(self.heroRaceImg, IconHelper.getRaceIcon(heroConf.Common.Race))	
	CommonHelper.playCsbAnimation(self.rareCsb, rareAni[heroConf.Rare], true)

	self.addAniFinish = false
	self.showAnimationID = heroConf.Common.AnimationID
	self.animationClick:setAnimationResID(heroConf.Common.AnimationID)
	self.heroAniNode:removeAllChildren()
	self.animationClick:setAnimationNode(nil)

	AnimatePool.createAnimate(heroConf.Common.AnimationID, handler(self, self.createAniCallBack))
end

-- 重新显示装备信息
function UIUnionMercenaryInfo:reShowEqsInfo(heroModel)
    -- 英雄身上的装备
	local heroEqs = {}
	local allEquips = heroModel.oneHeroEquips
	for x=1, #allEquips do
		local confId = allEquips[x].confId
        if confId ~= 0 then
		    --local eqConfID = getGameModel():getEquipModel():getMercenaryeEquipConfId(confId)
		    local propConf = getPropConfItem(confId)
            if propConf == nil then
            	print("error !!! not find propConf about eq--",	confId) 
            	break
            end		    
			local eqConf = getEquipmentConfItem(confId)
            if eqConf == nil then
            	print("error !!! not find eqConf about eq--", confId)
            	break
            end
			heroEqs[eqConf.Parts] = {}
			--heroEqs[eqConf.Parts].dyID	= confId
			heroEqs[eqConf.Parts].confID= confId
            heroEqs[eqConf.Parts].propConf = propConf
			heroEqs[eqConf.Parts].lv 	= eqConf.Level
			heroEqs[eqConf.Parts].quality 	= propConf.Quality

			self["eqBtn_" .. x]:setTouchEnabled(true)
        else
        	-- 有装备,无装备,点击没有效果
			self["eqBtn_" .. x]:setTouchEnabled(false)
        end
	end

	-- 判断装备状态
	self.status = {}
	for i=1, 6 do
		if heroEqs[i] == nil then
			self.status[i] = eqPartStatus.noEqDress
		else
			self.status[i] = eqPartStatus.ownEqNoReplace
		end
	end

	for i=1, 6 do
		self:reShowEqPart(i, heroEqs[i] and heroEqs[i].propConf or nil , self.status[i])
	end

	EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIUnionMercenaryInfo)
end

-- 重新显示某个装备图标
function UIUnionMercenaryInfo:reShowEqPart(part, propConf, status)
	status = status or eqPartStatus.noEqReplace

	if part <=0 or part > 6 then print("eq part is error") return end

	local eqCsb = self["eqCsb_" .. part]
	if propConf ~= nil then
		local eqFrameImg= CsbTools.getChildFromPath(eqCsb, "EqItemPanel/BgImage")
		local eqImg 	= CsbTools.getChildFromPath(eqCsb, "EqItemPanel/EqImage")
		CsbTools.replaceImg(eqFrameImg, getItemLevelSettingItem(propConf.Quality).ItemFrame)
		CsbTools.replaceImg(eqImg, propConf.Icon)
	else
		local eqFrameImg= CsbTools.getChildFromPath(eqCsb, "EqItemPanel/BgImage")
		CsbTools.replaceImg(eqFrameImg, getItemLevelSettingItem(1).ItemFrame)
	end

	if status == eqPartStatus.noEqDress then
		CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "No", false, nil, true)
	elseif status == eqPartStatus.ownEqDress then
		CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "Yes", false, nil, true)
	elseif status == eqPartStatus.noEqReplace then
		CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "Normal", false, nil, true)
	elseif status == eqPartStatus.ownEqReplace then
		CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "Replace", false, nil, true)
	elseif status == eqPartStatus.ownEqNoReplace then
		CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "Normal", false, nil, true)
	end
end

-- 根据模型初始化英雄等级相关信息
function UIUnionMercenaryInfo:initHeroLvInfo(heroModel)
	local heroLv = 1
	local heroStar = 1
	local heroExp = 0
	if heroModel then
		heroLv = heroModel.heroLv
		heroStar = heroModel.heroStar
		heroExp = heroModel.heroExp
	end

	local starLvConf = getSoldierStarSettingConfItem(heroStar)
	local upStarConf = getSoldierUpRateConfItem(heroModel.heroId)	
	if upStarConf == nil then 
		print("SoldierUpRate is nil", heroModel.heroId) 
	end
	local maxStarLvConf = getSoldierStarSettingConfItem(upStarConf.TopStar)

	self.heroLvLab:setString(heroLv)
	self.heroMaxLvLab:setString("/" .. starLvConf.TopLevel)

	local lvConf = getSoldierLevelSettingConfItem(heroLv + 1)
	if not lvConf then
		print("lvConf is nil", heroLv + 1)
	end
	local upLvExp = lvConf.Exp

	-- 等级是否达到召唤师最高等级
	local userLv = getGameModel():getUserModel():getUserLevel()
	local maxLv = starLvConf.TopLevel
	if userLv < 15 then
		maxLv = (maxLv >= 15) and 15 or maxLv
	else
		maxLv = (maxLv >= userLv) and userLv or maxLv
	end
	if maxLv == heroLv then
		self.expLab:setString(CommonHelper.getUIString(213))
	else
		self.expLab:setString(heroExp .. "/" .. upLvExp)
	end
	
	self.expBar:setPercent(heroExp/upLvExp*100)

	local isVisible = heroLv ~= maxStarLvConf.TopLevel
	self.expLab:setVisible(isVisible)
	self.expBar:setVisible(isVisible)
	self.expBgImg:setVisible(isVisible)

	-- 保留当前的等级和经验, 升级滚动使用
	self.rollPreLv = heroLv
	self.rollPreExp = heroExp
end

-- 根据模型初始化英雄星级相关信息
function UIUnionMercenaryInfo:initHeroStarInfo(heroModel, heroConf)
	local curStar = 1
	if heroModel then
		curStar = heroModel.heroStar
	end
	curStar = curStar == 0 and 1 or curStar

	local upStarConf = getSoldierUpRateConfItem(heroModel.heroId)
	if upStarConf == nil then 
		print("SoldierUpRate is nil", heroModel.heroId)
		return
	end
	local maxStar = upStarConf.TopStar

	for i=1, 7 do
		local emptyStarNode = CsbTools.getChildFromPath(self.starCsb, "award_star_null_" .. i)
		local fullStarNode = CsbTools.getChildFromPath(emptyStarNode, "award_star_full")
		emptyStarNode:setVisible(maxStar >= i and true or false)
		fullStarNode:setVisible(curStar >= i and true or false)
	end

	self.uiTypeLab:setString(CommonHelper.getUIString(uiTypeLanIDs["mercenary"]))

	-- 判断是否隐藏升星按钮	
	self.upStarBtn:setVisible(false)
	self.fragPanel:setVisible(false)

end

-- 根据模型初始化属性相关信息
function UIUnionMercenaryInfo:initAttrisInfo(dyId, heroConf)
	self.baseAttri, self.addAttri = self:queryAttribute(dyId)

	self:reShowAttri(self.baseAttri, self.addAttri, heroConf)
end

function UIUnionMercenaryInfo:initEqSkillInfo(heroModel, heroConf)
	local exitSkill = false
	local skills = heroConf.Common.Skill
	for i=1, 3 do
		if skills[i] ~= 0 then
			exitSkill = true
			break
		end
	end

	self.skillPanel:setVisible(true)
	self.skillNodeInfo[4].btn:setTag(skills[4])
	if skills[4] ~= 0 then
		self.skillNodeInfo[4].btn:setVisible(true)
		local skillConf = getSkillConfItem(skills[4])
		if not skillConf then 
			print("skillConf is nil, skillID: ", skills[4])
		else
			-- 判断是否激活装备技能
			local isActive = self:checkActiveEqSkill(heroModel.heroId, heroModel, heroConf)
			if not exitSkill then
				self:initSkillNode(self.skillNodeInfo[4].csb, skills[4], not isActive)
				self:reShowSkillLab(skillConf)				
				CommonHelper.playCsbAnimation(self.skillNodeInfo[4].csb, "On", false, nil)
			else
				self:initSkillNode(self.skillNodeInfo[4].csb, skills[4], not isActive)
				CommonHelper.playCsbAnimation(self.skillNodeInfo[4].csb, "Normal", false, nil)
			end
		end
	else
		self.skillNodeInfo[4].btn:setVisible(false)
		if not exitSkill then
			self.skillPanel:setVisible(false)
		end
	end
end


function UIUnionMercenaryInfo:checkActiveEqSkill(heroID, heroModel, heroConf)
	local isActive = false

	if not heroModel or heroModel.heroStar == 0 then
		return isActive
	end

	local eqSkillConf = getEquipSkillConfig(heroID)
	if not eqSkillConf then
		print("error eqSkillConf is nil ", heroID)
		return isActive
	end

	local heroEqsConfID = {}
	local eqsDyID = heroModel.oneHeroEquips
	for _, info in pairs(eqsDyID) do
        if info.confId~= 0 then
		    local eqConfID = getGameModel():getEquipModel():getEquipConfId(info.confId)
		    heroEqsConfID[eqConfID] = true
        end
	end

	for _, eqs in ipairs(eqSkillConf) do
		isActive = true
		for _,eqID in ipairs(eqs) do
			if not heroEqsConfID[eqID] then
				isActive = false
				break
			end
		end
		if isActive then
			return isActive
		end
	end

	return isActive
end
-- 根据具体值设置属性显示的数值
function UIUnionMercenaryInfo:reShowAttri(baseAttri, addAttri, heroConf)
-- 生命
	self:setAttriLab(self["attriLab_1"], baseAttri[attribute.hp])
	self:setAddAttriLab(self["attriAddLab_1"], addAttri[attribute.hp])

	-- 物理攻击 / 魔法攻击
	if baseAttri[attribute.pAttack] >= baseAttri[attribute.mAttack] then
		self["attriNameLab_2"]:setString(CommonHelper.getUIString(416))
		self:setAttriLab(self["attriLab_2"], baseAttri[attribute.pAttack])
		self:setAddAttriLab(self["attriAddLab_2"], addAttri[attribute.pAttack])
	else
		self["attriNameLab_2"]:setString(CommonHelper.getUIString(424))
		self:setAttriLab(self["attriLab_2"], baseAttri[attribute.mAttack])
		self:setAddAttriLab(self["attriAddLab_2"], addAttri[attribute.mAttack])
	end

	-- 护甲
	self:setAttriLab(self["attriLab_3"], baseAttri[attribute.pGuard])
	self:setAddAttriLab(self["attriAddLab_3"], addAttri[attribute.pGuard])

	-- 魔抗
	self:setAttriLab(self["attriLab_4"], baseAttri[attribute.mGuard])
	self:setAddAttriLab(self["attriAddLab_4"], addAttri[attribute.mGuard])

	-- 闪避
	self:setAttriLab(self["attriLab_5"], baseAttri[attribute.miss], "%")
	self:setAddAttriLab(self["attriAddLab_5"], addAttri[attribute.miss], "%")

	-- 攻击范围
	local rangeLanID = {564, 565, 566, 567}
	self["attriLab_6"]:setString(CommonHelper.getUIString(rangeLanID[heroConf.Common.AttackDistance] or 564))

	-- 攻击速度
	local speedLanID = {559, 560, 561, 562, 563}
	local AttactSpeedRange = {0, 30, 55, 80, 105}
	local range = 1
	for j=#AttactSpeedRange, 1, -1 do
		if baseAttri[112] > AttactSpeedRange[j] then
			range = j
			break
		end
	end
	self["attriLab_7"]:setString(CommonHelper.getUIString(speedLanID[range]))

	-- 移动速度
	local speedRange = {0, 40, 80, 120, 160}
	range = 1
	for j=#speedRange, 1, -1 do
		if baseAttri[113] > speedRange[j] then
			range = j
			break
		end
	end
	self["attriLab_8"]:setString(CommonHelper.getUIString(speedLanID[range]))

	-- 水晶消耗
	self:setAttriLab(self["attriLab_9"], heroConf.Cost)

	-- 冷却时间
	self:setAttriLab(self["attriLab_10"], heroConf.CD)
end

-- 计算前一个状态和当前状态的属性差值
function UIUnionMercenaryInfo:countAttriSub(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)
	local subAttrisInfo = {}
	for k, v in pairs(preBaseAttri) do
		local preValue = v + (preAddAttri[k] or 0)
		local curValue = (curBaseAttri[k] or 0) + (curAddAttri[k] or 0)
		local subValue = curValue - preValue
		if subValue ~= 0 then
			subAttrisInfo[#subAttrisInfo + 1] = {attriID = k, attriValue = subValue}
		end
	end
	return subAttrisInfo
end

-- 浮动显示属性差值
function UIUnionMercenaryInfo:showAttriChange(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)
	self.subAttrisInfo = self:countAttriSub(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)

	self:setTipsUpdateIsOpen(true)
	self.tipsOrder = 0	-- 显示第几个加成
end

function UIUnionMercenaryInfo:attriToStr(value)
	local str = ""
	if value > 0 then
		str = "+" .. value
	elseif value == 0 then
		str = "" .. value
	else
		str = value
	end
	return str
end

function UIUnionMercenaryInfo:setAttriLab(lab, value, suffix)
	value = value or 0

	local valueStr = ""
	if math.floor(value) < value then
		valueStr = string.format("%0.1f", value)
	else
		valueStr = "" .. value
	end

	lab:setString(valueStr .. (suffix or ""))
end

-- 根据属性正负确定显示的字符串
function UIUnionMercenaryInfo:setAddAttriLab(lab, value, suffix)
	value = value or 0

	local valueStr = ""
	if math.floor(value) < value then
		valueStr = string.format("%0.1f", value)
	else
		valueStr = "" .. value
	end

	if value == 0 then
        lab:setString("")
    else
        if value > 0 then
            lab:setTextColor(cc.c3b(255, 34, 0))
            lab:setString("+" .. valueStr .. (suffix or ""))
        else
            lab:setTextColor(cc.c3b(79, 24, 0))
            lab:setString(valueStr .. (suffix or ""))
        end
    end
end

-- 关闭计时器
function UIUnionMercenaryInfo:closeUpdate()
	self:setTipsUpdateIsOpen(false)
	self:setRollUpdateIsOpen(false)
end

-- 打开属性差值浮动文字提示(装备)
function UIUnionMercenaryInfo:setTipsUpdateIsOpen(isOpen)
	if isOpen and self.tipsSchedulerID == nil then
		self.tipsSchedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.tipsUpdate), 0.4, false)
	elseif (not isOpen) and self.tipsSchedulerID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.tipsSchedulerID)
		self.tipsSchedulerID = nil
	end
end

-- 浮动文字显示(装备)
function UIUnionMercenaryInfo:tipsUpdate(dt)
	if self.tipsOrder >= #self.subAttrisInfo then
		self:setTipsUpdateIsOpen(false)
		self.subAttrisInfo = {}
		print("浮动提示结束")
	else
		self.tipsOrder 	= self.tipsOrder + 1
		local attriID 	= self.subAttrisInfo[self.tipsOrder].attriID
		local attriValue= self.subAttrisInfo[self.tipsOrder].attriValue

		local str = CommonHelper.getRoleAttributeString(attriID + 10000)
		if str ~= nil and str ~= "" and attriValue ~= 0 then
			local wPos = self.heroAniNode:convertToWorldSpace(cc.p(0,0))

			CsbTools.addTipsToRunningScene(string.format(str, self:attriToStr(attriValue)), {
				animate = 2,
				x = wPos.x,
				y = wPos.y + 90,
				color = attriValue > 0 and cc.c3b(0,255,0) or cc.c3b(255,0,0),
				dimensions = cc.size(display.cx, display.cy)
			})
		else
			self:tipsUpdate(0)
		end
	end
end

-- 打开属性滚动 (升级)
function UIUnionMercenaryInfo:setRollUpdateIsOpen(isOpen)
	if isOpen and self.rollSchedulerID == nil then
		self.rollSchedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.rollUpdtae), 0, false)
	elseif (not isOpen) and self.rollSchedulerID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.rollSchedulerID)
		self.rollSchedulerID = nil		

		-- 重新刷新防止出现数值错误
		local heroModel = UnionMercenaryModel:getCurMercenaryInfo(self.curDyId)
		local heroConf = getSoldierConfItem(heroModel.heroId, heroModel.heroStar)
		-- 重新显示英雄等级信息
		self:initHeroLvInfo(heroModel)
		-- 重新显示英雄部分属性信息
		self:initAttrisInfo(heroModel.dyId, heroConf)
	end
end

-- 属性滚动 (升级)
function UIUnionMercenaryInfo:rollUpdtae(dt)
	self.rollTime = self.rollTime + dt

	if self.rollOrder > #self.rollInfo then
		self:setRollUpdateIsOpen(false)
		self.rollInfo = {}
	else
		local info = self.rollInfo[self.rollOrder]
		if self.rollTime >= info.playTime then
			self.rollTime = info.playTime
		end

		local function countValue(beginValue, finalValue, playTime, allTime)
			local value = beginValue + (finalValue - beginValue)*playTime/allTime
			return math.ceil(value)
		end

		-- 等级, 经验
		self.heroLvLab:setString(info.lv)
		self.expLab:setString(countValue(info.exp, info.finalExp, self.rollTime, info.playTime) .. "/" .. info.needExp)
		self.expBar:setPercent(countValue(info.exp, info.finalExp, self.rollTime, info.playTime)/info.needExp*100)
		-- 生命
		self["attriLab_1"]:setString(countValue(info.hp, info.finalhp, self.rollTime, info.playTime))
		self:setAddAttriLab(self["attriAddLab_1"], countValue(info.addhp, info.finalAddhp, self.rollTime, info.playTime))
		-- 攻击
		if info.pAttack ~= nil and info.pAttack ~= 0 then
			self["attriLab_2"]:setString(countValue(info.pAttack, info.finalpAttack, self.rollTime, info.playTime))
			self:setAddAttriLab(self["attriAddLab_2"], countValue(info.addpAttack, info.finalAddpAttack, self.rollTime, info.playTime))
		else
			self["attriLab_2"]:setString(countValue(info.mAttack, info.finalmAttack, self.rollTime, info.playTime))
			self:setAddAttriLab(self["attriAddLab_2"], countValue(info.addmAttack, info.finalAddmAttack, self.rollTime, info.playTime))
		end		
		-- 护甲
		self["attriLab_3"]:setString(countValue(info.pGuard, info.finalpGuard, self.rollTime, info.playTime))
		self:setAddAttriLab(self["attriAddLab_3"], countValue(info.addpGuard, info.finalAddpGuard, self.rollTime, info.playTime))
		-- 魔抗
		self["attriLab_4"]:setString(countValue(info.mGuard, info.finalmGuard, self.rollTime, info.playTime))
		self:setAddAttriLab(self["attriAddLab_4"], countValue(info.addmGuard, info.finalAddmGuard, self.rollTime, info.playTime))
		-- 闪避
		self["attriLab_5"]:setString(countValue(info.miss, info.finalmiss, self.rollTime, info.playTime) .. "%")
		self:setAddAttriLab(self["attriAddLab_5"], countValue(info.addmiss, info.finalAddmiss, self.rollTime, info.playTime), "%")

		if self.rollTime >= info.playTime then
			self.rollTime = 0
			self.rollOrder = self.rollOrder + 1
		end
		if info.isTopLv then
			self.expLab:setString(CommonHelper.getUIString(213))			
		end
	end
end

-- 根据模型和配表 ,初始化技能信息
function UIUnionMercenaryInfo:initSkillInfo(heroConf)
	local skills = heroConf.Common.Skill
	for i=1, 3 do
		self.skillNodeInfo[i].btn:setTag(skills[i])
		if skills[i] ~= 0 then
			self.skillNodeInfo[i].btn:setVisible(true)
			if i == 1 then
				local skillConf = getSkillConfItem(skills[i])
				if not skillConf then 
					print("skillConf is nil, skillID: ", skills[1])
				else
					self:reShowSkillLab(skillConf)
				end
				self:initSkillNode(self.skillNodeInfo[i].csb, skills[i], false)
				CommonHelper.playCsbAnimation(self.skillNodeInfo[i].csb, "On", false, nil)

			else
				self:initSkillNode(self.skillNodeInfo[i].csb, skills[i], false)
				CommonHelper.playCsbAnimation(self.skillNodeInfo[i].csb, "Normal", false, nil)
			end
		else
			self.skillNodeInfo[i].btn:setVisible(false)
		end
	end
end

-- 根据具体数值初始化某个技能的显示
function UIUnionMercenaryInfo:initSkillNode(csb, id, isGray)
	print("csb, id, isGray" ,csb, id, isGray)

	local iconImg = CsbTools.getChildFromPath(csb, "MainPanel/IconImage")

	if id ~= nil and id ~= 0 then
		csb:setVisible(true)

		local skillConf = getSkillConfItem(id)
		if not skillConf then 
			print("error skillConf is nil skillID", id)
			return 
		end
		CsbTools.replaceImg(iconImg, skillConf.IconName)

	else
		csb:setVisible(false)
	end

	if isGray then
		CommonHelper.applyGray(iconImg)
	else
		CommonHelper.removeGray(iconImg)
	end
end

-- 根据模型初始化天赋信息
function UIUnionMercenaryInfo:initTalentInfo(heroModel)
	if heroModel.heroStar == 1 then
		self.talentPanel:setVisible(false)
	else
		self.talentPanel:setVisible(true)
        --有未解锁的天赋红点提示
        CsbTools.getChildFromPath(self.talentCsb, "MainPanel/RedTipPoint"):setVisible(false)

		local curTalent = heroModel.heroTalent
		if curTalent ~= 0 then
			CommonHelper.playCsbAnimation(self.talentCsb, "Normal", false, nil)
			local heroConf	= getSoldierConfItem(heroModel.heroId, heroModel.heroStar)
			local talentInfo= heroConf.talent[curTalent]
            if talentInfo == nil then print("talent not find", curTalent) return end
			CsbTools.replaceImg(self.talentIconImg, talentInfo.Icon)
		else
			--self.talentPanel:setVisible(false)
			CommonHelper.playCsbAnimation(self.talentCsb, "Null", false, nil)
		end
	end
end

-- 显示装备属性改变差异浮动文字提示
function UIUnionMercenaryInfo:showChangeEqInfo(dyId)
	-- 刷新装备显示
	local heroModel = UnionMercenaryModel:getCurMercenaryInfo(dyId)
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	if heroModel == nil or heroConf == nil then return end
	self:reShowEqsInfo(heroModel)
    
	-- 记录前一个属性
	local preBaseAttri = {}
	local preAddAttri = {}
	for k,v in pairs(self.baseAttri) do
		preBaseAttri[k] = v
	end
	for k,v in pairs(self.addAttri) do
		preAddAttri[k] = v
	end

	self.baseAttri, self.addAttri = self:queryAttribute(heroModel.dyId)

	-- 刷新属性显示
	self:reShowAttri(self.baseAttri, self.addAttri, heroConf)

	-- 显示属性增减
	self:showAttriChange(preBaseAttri, preAddAttri, self.baseAttri, self.addAttri)
end

-- 计算出英雄class属性和增加的属性
function UIUnionMercenaryInfo:queryAttribute(dyId)

	local heroCard =UnionMercenaryModel:getCurMercenaryInfo(dyId)
	if not heroCard then
		print("queryHeroAttribute dyId not find", dyId)
		return
	end

	-- 获取装备
	local equips = heroCard.oneHeroEquips
	if not equips then
		print("getEquips fail")
		return
	end

	-- 获取装备属性
	local effects = {}
	for i=1, 6 do
		local eqInfo = equips[i]
		if eqInfo and eqInfo.confId ~= 0 then
			local soldierEquip = {}
			soldierEquip.confId = eqInfo.confId
			soldierEquip.nDnycEquipID = eqInfo.confId
			soldierEquip.EffectID = {}
			soldierEquip.EffectValue = {}
			for i,v in ipairs(eqInfo.eqEffectIDs) do
				soldierEquip.EffectID[i] = v
			end
			for i,v in ipairs(eqInfo.eqEffectValues) do
				soldierEquip.EffectValue[i] = v
			end
			table.insert(effects, soldierEquip)
		end
	end
	return queryHeroAttribute(heroCard.heroId, heroCard.heroLv, heroCard.heroStar, effects)
end

return UIUnionMercenaryInfo