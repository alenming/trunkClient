--[[
	英雄总览界面，主要实现以下内容
	1. 显示英雄描述信息(名称, 种族, 职业, 描述)
	2. 显示英雄骨骼动画, 点击能播放动画
	3. 显示英雄装备, 点击显示装备具体信息, 提供装备更换, 穿戴功能
	4. 实现一键穿装
	5. 显示英雄特性, 点击弹出具体描述
	6. 显示英雄等级相关(等级, 当前星级最高等级, 经验, 当前等级最高经验), 点击升级按钮进入升级界面
	7. 显示英雄升星相关(星级, 英雄最高星级), 点击升星进入升星界面, 按钮是否隐藏
	8. 显示英雄部分属性, 及装备加成
	9. 显示技能相关(技能图标, 等级, 描述, 消耗描述), 点击切换技能文字描述
	10. 显示天赋相关(天赋动态图标), 点击进入天赋界面
--]]

local UIHeroInfo = class("UIHeroInfo", require("common.UIView"))

local AnimationClick= require("game.comm.AnimationClick")
local UIEquipInfo 	= require("game.hero.UIEquipInfo")

local csbFile 		= ResConfig.UIHeroInfo.Csb2
local eqItemFile 	= "ui_new/g_gamehall/c_collection/EqItem.csb"
local featureFile 	= "ui_new/g_gamehall/c_card/FeaturesItem.csb"
local talentFile 	= "ui_new/g_gamehall/c_card/GiftItem.csb"
local skillFile 	= "ui_new/g_gamehall/c_card/SkillItem.csb"

local eqPartStatus	= {noEqDress = 1, ownEqDress = 2, noEqReplace = 3, ownEqReplace = 4, ownEqNoReplace = 5}
local attribute 	= {hp = 114, pAttack = 106, mAttack = 107, pGuard = 108, mGuard = 109, miss = 207}
local jobLanIDs 	= {[1] = 521, [2] = 524, [3] = 522, [4] = 523, [5] = 525, [6] = 520}
local uiTypeLanIDs 	= {frag = 395, mercenary = 2040}
local rareAni 		= {[1] = "None", [3] = "Blue", [4] = "Voilet", [5] = "Golden"}

-- 计算出英雄class属性和增加的属性
function queryAttribute(heroId)
	local gameModel = getGameModel()
	local heroCard = gameModel:getHeroCardBagModel():getHeroCard(heroId)

	local heroLv = 1
	local heroStar = 1
	local equips = {}
	local effects = {}
	if heroCard and heroCard:getStar() ~= 0 then
		heroLv = heroCard:getLevel()
		heroStar = heroCard:getStar()
		equips = heroCard:getEquips()
	end

	-- 获取装备属性
	local effects = {}
	local eqModel = gameModel:getEquipModel()
	for part, eqDyId in pairs(equips) do
		if eqDyId ~= 0 then
			local eqInfo = eqModel:getEquipInfo(eqDyId)
			if eqInfo then
				local soldierEquip = {}
				soldierEquip.confId = eqInfo.confId
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
	end
	return queryHeroAttribute(heroId, heroLv, heroStar, effects)
end

function UIHeroInfo:ctor()
	-- 初始化UI
	self.rootPath 	= csbFile.heroInfo
	self.root 		= getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn 	= CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, handler(self, self.backBtnCallBack))

	-- 装备显示界面
	self.eqInfoCsb = CsbTools.getChildFromPath(self.root, "MainPanel/EquipInfo")
	CommonHelper.layoutNode(self.eqInfoCsb)
	self.UIEquipInfo = UIEquipInfo.new(self.eqInfoCsb)
	self.eqInfoSize = CsbTools.getChildFromPath(self.eqInfoCsb, "EqInfoPanel"):getBoundingBox()

	-- 屏蔽层
	self.mask 		= CsbTools.getChildFromPath(self.root, "MainPanel/MaskPanel")
	self.mask:addClickEventListener(handler(self, self.maskCallBack))

	-- 切换英雄按钮
	local toPreBtn	= CsbTools.getChildFromPath(self.root, "LeftButton")
	local toNextBtn	= CsbTools.getChildFromPath(self.root, "RightButton")
	CsbTools.initButton(toPreBtn, handler(self, self.toPreBtnCallBack))
	CsbTools.initButton(toNextBtn, handler(self, self.toNextBtnCallBack))

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

	-- 6件装备, 一键穿装
	for i=1,6 do
		self["eqBtn_" .. i]	= CsbTools.getChildFromPath(leftPanel, "EqButton" .. i)
		self["eqCsb_" .. i]	= CsbTools.getChildFromPath(self["eqBtn_" .. i], "EqItem")
		local bgImg 		= CsbTools.getChildFromPath(self["eqCsb_" .. i], "EqItemPanel/EqBgImage")
		
		CsbTools.replaceSprite(bgImg, getIconSettingConfItem().EqIcon[i])
		self["eqBtn_" .. i]:setTag(i)
		CsbTools.initButton(self["eqBtn_" .. i], handler(self, self.eqBtnCallBack), nil, nil, "EqItem")
	end
	self.autoWearBtn	= CsbTools.getChildFromPath(leftPanel, "AutoWearButton")
	CsbTools.initButton(self.autoWearBtn, handler(self, self.autoWearCallBack), CommonHelper.getUIString(183), 
		"Button_Green/ButtomName", "Button_Green")

	-- 品质特效
	self.rareCsb = CsbTools.getChildFromPath(leftPanel, "LevelAura")

	------------------英雄总览界面右侧面板----------------
	local rightPanel = CsbTools.getChildFromPath(self.root, "MainPanel/RightPanel")

	-- 英雄等级
	self.heroLvLab	= CsbTools.getChildFromPath(rightPanel, "LevelFontLabel")
	self.heroMaxLvLab= CsbTools.getChildFromPath(rightPanel, "Level")

	-- 英雄经验
	self.expLab		= CsbTools.getChildFromPath(rightPanel, "ExpNum")
	self.expBar		= CsbTools.getChildFromPath(rightPanel, "ExpLoadingBar")
	self.expBgImg	= CsbTools.getChildFromPath(rightPanel, "LoadingBarBg")

	-- 界面类型 (未获得, 隐藏, 佣兵)
	self.uiTypeLab 	= CsbTools.getChildFromPath(rightPanel, "MercenaryLogo")
	-- 英雄星级
	self.fragPanel 	= CsbTools.getChildFromPath(rightPanel, "CardPanel")
	self.fragLab	= CsbTools.getChildFromPath(self.fragPanel, "CardCount")
	self.heroFragImg= CsbTools.getChildFromPath(self.fragPanel, "HeroImage")
	CsbTools.initButton(self.fragPanel, handler(self, self.fragCallBack))

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
	CsbTools.initButton(self.giftBtn, handler(self, self.giftBtnCallBack))
	CsbTools.initButton(self.upStarBtn, handler(self, self.upStarCallBack))
	CsbTools.initButton(self.upLvBtn, handler(self, self.upLvCallBack))
	CsbTools.initButton(self.getPathBtn, handler(self, self.fragCallBack))
	-- 天赋红点节点
	self.giftRedNode = CsbTools.getChildFromPath(self.giftBtn, "RedTipPoint")
	self.upStarRedNode = CsbTools.getChildFromPath(self.upStarBtn, "RedTipPoint")
end

function UIHeroInfo:onOpen(_, heroID, idList)
	self.heroID 	= heroID 	-- 当前显示的英雄动态ID
	self.idList		= clone(idList)
	self.mask:setTouchEnabled(false)
	self.addAniFinish = true 	-- 加载骨骼动画完成

	-- 服务器消息监听
	-- 穿装 (卸装)回调监听
	local cmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.EquipSC)
	self.wearEqHandler = handler(self, self.onWearEq)
	NetHelper.setResponeHandler(cmd, self.wearEqHandler)

	self:showUIInfo(heroID)
end

function UIHeroInfo:onClose()
	local cmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.EquipSC)
	NetHelper.removeResponeHandler(cmd, self.wearEqHandler)

	self.heroAniNode:removeAllChildren()

	self:closeUpdate()
	
	return self.heroID
end

function UIHeroInfo:onTop(preUIID, args)
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
	local heroConf = getSoldierConfItem(self.heroID, heroModel and heroModel:getStar() or 1)
    
    if preUIID == UIManager.UI.UIHeroTalent then
		-- 重新刷新天赋红点
		self:refreshGiftRedPoint(heroModel)
	elseif preUIID == UIManager.UI.UIEquipBag then
		self.mask:setTouchEnabled(false)
		CommonHelper.playCsbAnimate(self.root, self.rootPath, "Normal", false, nil, true)
	elseif preUIID == UIManager.UI.UIHeroQuickTo then
		self:initHeroStarInfo(heroModel, heroConf)
	end
end

-------------------- 按钮回调 ----------------------
function UIHeroInfo:backBtnCallBack(ref)
	UIManager.close()
end

-- 点击到屏蔽层, 取消屏蔽, 取消装备显示
function UIHeroInfo:maskCallBack(ref)
	self.mask:setTouchEnabled(false)
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
end

-- 切换到前一个英雄
function UIHeroInfo:toPreBtnCallBack(ref)
	if self.mask:isTouchEnabled() then
		self.mask:setTouchEnabled(false)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
	else
		self:closeUpdate()
		-- 取出上一个英雄ID
		local order = 1
		for i, id in ipairs(self.idList) do
			if id == self.heroID then
				order = i
				break
			end
		end
		if order == 1 then
			order = #self.idList
		else
			order = order - 1
		end

		-- 重新显示
		self:showUIInfo(self.idList[order])	
        
        EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIHeroInfo)	
	end
end

-- 切换到下一个英雄
function UIHeroInfo:toNextBtnCallBack(ref)
	if self.mask:isTouchEnabled() then
		self.mask:setTouchEnabled(false)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
	else
		self:closeUpdate()
		-- 取出下一个英雄ID
		local order = 1
		for i, id in ipairs(self.idList) do
			if id == self.heroID then
				order = i
				break
			end
		end
		if order == #self.idList then
			order = 1
		else
			order = order + 1
		end

		-- 重新显示
		self:showUIInfo(self.idList[order])

        EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIHeroInfo)
	end
end

-- 装备框点击回调
function UIHeroInfo:eqBtnCallBack(ref)
	local eqPart = ref:getTag()
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
	if not heroModel or heroModel:getStar() == 0 then
		return
	end

	local clickEqDyID = heroModel:getEquip(eqPart)
	if clickEqDyID ~= 0 and clickEqDyID ~= nil then
		self.UIEquipInfo:setUIInfo(self.heroID, clickEqDyID, 1, handler(self, self.uiEqInfoCallFunc))
		self.mask:setTouchEnabled(true)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOn", false, function()
        	-- 新手引导需要
        	EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIHeroInfo)
        end, true)
        -- 移动该装备的右侧
        local wPos1 = ref:convertToWorldSpace(cc.p(0,0))
        local wPos2 = self.eqInfoCsb:convertToWorldSpace(cc.p(0,0))
        local pos2  = self.eqInfoCsb:getPosition()
        local posX 	= pos2 - (wPos2.x - wPos1.x) + (self.eqInfoSize.width/2 + ref:getBoundingBox().width)
        self.eqInfoCsb:setPositionX(posX)
	else
		self:closeUpdate()
		if self.addAniFinish then
			UIManager.open(UIManager.UI.UIEquipBag, self.heroID, eqPart, handler(self, self.uiEqInfoCallFunc))
		end
	end
end

-- 一键穿装点击回调
function UIHeroInfo:autoWearCallBack(ref)
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)

	if not heroModel then
		return
	end

	-- 英雄装备需求
	local heroLv= heroModel:getLevel()
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	local heroJob = heroConf.Common.Vocation

	-- 取出最好的装备{[part] = {dyID, confID, lv, quality}}
	local bestEqs = {}
	local bagItems = getGameModel():getBagModel():getItems()
	for k, _ in pairs(bagItems) do
		-- 筛选出装备
		if k > 1000000 then
			local eqConfID = getGameModel():getEquipModel():getEquipConfId(k)
			if eqConfID ~= nil and eqCondID ~= 0 then
				local eqConf = getEquipmentConfItem(eqConfID)
				local propConf = getPropConfItem(eqConfID)
				if eqConf ~= nil and propConf ~= nil then
					-- 判断等级
					local lvPass = heroLv >= eqConf.Level and true or false
					-- 判断职业
					local jobPass = false
					for _, job in ipairs(eqConf.Vocation) do
						if job == heroJob then
							jobPass = true
							break
						end
					end
					
					if lvPass and jobPass then
						-- 判断是否是最好
						if bestEqs[eqConf.Parts] == nil then
							bestEqs[eqConf.Parts] 		= {}
							bestEqs[eqConf.Parts].dyID	= k
							bestEqs[eqConf.Parts].confID= eqConfID
							bestEqs[eqConf.Parts].lv 	= eqConf.Level
							bestEqs[eqConf.Parts].quality = propConf.Quality
						elseif bestEqs[eqConf.Parts].lv < eqConf.Level or 
							(bestEqs[eqConf.Parts].lv == eqConf.Level and bestEqs[eqConf.Parts].quality < propConf.Quality) then
							bestEqs[eqConf.Parts].dyID	= k
							bestEqs[eqConf.Parts].confID= eqConfID
							bestEqs[eqConf.Parts].lv 	= eqConf.Level
							bestEqs[eqConf.Parts].quality = propConf.Quality
						end
					end
				end
			end
		end
	end

	-- 记录那些部位没穿装备
	local noEqPart = {}
	local heroEqsInfo = heroModel:getEquips()
	for i=1, 6 do
		if heroEqsInfo[i] == 0 or heroEqsInfo[i] == nil then
			noEqPart[i] = true
		else
			noEqPart[i] = false
		end
	end
	-- 筛选出需要穿戴的装备
	local wearEqs = {}
	for i=1, 6 do
		if noEqPart[i] and bestEqs[i] ~= nil then
			wearEqs[#wearEqs + 1] = {
				dyID = bestEqs[i].dyID,
				part = i
			}
		end
	end

	-- 穿装发包
	if #wearEqs ~= 0 then
		local BufferData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.EquipCS)
		BufferData:writeInt(self.heroID)
		BufferData:writeInt(#wearEqs)
		for _, info in ipairs(wearEqs) do
			BufferData:writeInt(info.dyID)
			BufferData:writeInt(info.part)
		end
		NetHelper.request(BufferData)
	end
end

function UIHeroInfo:fragCallBack(ref)
	if not self.heroID or self.heroID == 0 then 
		return 
	end

    UIManager.open(UIManager.UI.UIHeroQuickTo, self.heroID)
end

-- 天赋点击回调
function UIHeroInfo:giftBtnCallBack(ref)
	if self.addAniFinish then
		self:closeUpdate()
		UIManager.open(UIManager.UI.UIHeroTalent, self.heroID)
	end
end

-- 升星点击回调
function UIHeroInfo:upStarCallBack(ref)	
	if self.addAniFinish then
		self:closeUpdate()
		UIManager.open(UIManager.UI.UIHeroUpgradeStar, self.heroID, handler(self, self.uiUpStarFunc))
	end
end

-- 升级按钮点击回调
function UIHeroInfo:upLvCallBack(ref)
	if self.addAniFinish then
		self:closeUpdate()
		UIManager.open(UIManager.UI.UIHeroUpgradeLv, self.heroID, handler(self, self.uiUpLvCallFunc))
	end
end

-- 技能点击回调
function UIHeroInfo:skillCallBack(ref)
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

-- 创建骨骼动画回调
function UIHeroInfo:createAniCallBack(animation, id)
	self.addAniFinish = true
	if animation and id == self.showAnimationID then
		self.heroAniNode:removeAllChildren()
		self.heroAniNode:addChild(animation)
		self.animationClick:setAnimationNode(animation)

	    CommonHelper.setRoleZoom(self.heroID, animation, self.heroAniNode, self.originX, self.originY)
	end

end

-- 骨骼动画点击播放随机动作
function UIHeroInfo:aniClickCallBack(touch, event)
	self.animationClick:playRandomAnimation()
end

-- 装备信息界面修改回调(穿装或卸载)
function UIHeroInfo:uiEqInfoCallFunc(args)
	self.mask:setTouchEnabled(false)
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "Normal", false, nil, true)

	local heroID 	= args.heroID or 0
	local eqPart 	= args.eqPart or 0
	local eqDyID 	= args.eqDyID or 0

	local bufferData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.EquipCS)
	bufferData:writeInt(heroID)
	bufferData:writeInt(1)
	bufferData:writeInt(eqDyID)
	bufferData:writeInt(eqPart)
	NetHelper.request(bufferData)
end

-- 升级回调(生成滚动属性值)
function UIHeroInfo:uiUpLvCallFunc()
	local preLv = self.rollPreLv or 0
	local preExp = self.rollPreExp or 0
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
	if not heroModel then
		return
	end
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())	
	if heroConf == nil then 
		print("heroConf is nil", heroModel:getID(), heroModel:getStar()) 
	end

	-- 重新显示英雄技能信息
	self:initSkillInfo(heroConf)

	local curLv = heroModel:getLevel()
	local curExp = heroModel:getExp()
    if preLv == curLv and preExp == curExp then
        return
    end

    local starLvConf = getSoldierStarSettingConfItem(heroModel:getStar())
    -- 等级是否达到召唤师最高等级
	local userLv = getGameModel():getUserModel():getUserLevel()
	local maxLv = starLvConf.TopLevel
	if userLv < 15 then
		maxLv = (maxLv >= 15) and 15 or maxLv
	else
		maxLv = (maxLv >= userLv) and userLv or maxLv
	end
	local isTopLv = (maxLv == heroModel:getLevel())

	self.rollPreLv = heroModel:getLevel()
	self.rollPreExp = heroModel:getExp()

	-- 记录升级前属性
	local preAttribute = {}
	for k, v in pairs(attribute) do
		preAttribute[k] = self.baseAttri[v] or 0
		preAttribute["add" .. k] = self.addAttri[v] or 0		
	end
	-- 记录最终的属性
	self.baseAttri, self.addAttri = queryAttribute(self.heroID)
	local curAttribute = {}
	for k, v in pairs(attribute) do
		curAttribute[k] = self.baseAttri[v] or 0
		curAttribute["add" .. k] = self.addAttri[v] or 0		
	end

	local needExp = {}
	local percent = {}
	local allPercent = 0
	-- 升级前等级的经验占比
	local exp = getSoldierLevelSettingConfItem(preLv + 1).Exp
	percent[#percent + 1] = 1 - preExp/exp
	-- 中间占百分比
	for i=preLv + 1, curLv - 1 do
		needExp[#needExp + 1] = getSoldierLevelSettingConfItem(i + 1).Exp
		percent[#percent + 1] = 1
	end
	-- 最终经验占比
	if curLv ~= preLv then
		exp = getSoldierLevelSettingConfItem(curLv + 1).Exp
		percent[#percent + 1] = curExp/exp
	end
	-- 总百分比
	for _,v in ipairs(percent) do
		allPercent = allPercent + v
	end

	-- 滚动属性
	--[[
		self.rollInfo = {
			[1] = {
				lv = 10, exp = 0, finalExp = 100, needExp = 50, playTime = 0.3,

				hp = 100, finalHP = 110, addHp = 0, finalAddHP = 0,
				...
			},
			...
		}
	]]
	self.rollInfo = {}
	local prePercent = 0
	local nextPercent = 0
	for i=preLv, curLv do
		prePercent = prePercent + (percent[i - preLv] or 0)

		local begin = prePercent/allPercent
		local final = (prePercent + percent[i - preLv + 1])/allPercent

		self.rollInfo[#self.rollInfo + 1] = {
			lv = i, 
			exp = (i == preLv) and preExp or 0, 
			finalExp = (i == curLv) and curExp or getSoldierLevelSettingConfItem(i + 1).Exp,
			needExp = getSoldierLevelSettingConfItem(i + 1).Exp,
			playTime = (i == curLv) and 1 or 0.1,			
			isTopLv = false,
		}
		if i == curLv then
			self.rollInfo[#self.rollInfo].isTopLv = isTopLv
		end

		local pre, cur, preAdd, curAdd
		for k, v in pairs(attribute) do
			pre = preAttribute[k] or 0
			cur = curAttribute[k] or 0
			preAdd = preAttribute["add" .. k] or 0
			curAdd = curAttribute["add" .. k] or 0
			self.rollInfo[#self.rollInfo][k] = pre + (cur - pre)*begin
			self.rollInfo[#self.rollInfo]["final" .. k] = pre + (cur - pre)*final
			self.rollInfo[#self.rollInfo]["add" .. k] = preAdd + (curAdd - preAdd)*begin
			self.rollInfo[#self.rollInfo]["finalAdd" .. k] = preAdd + (curAdd - preAdd)*final
		end
	end
	self.rollTime = 0
	self.rollOrder = 1
	self:setRollUpdateIsOpen(true)
    
	self:reShowEqsInfo(heroModel)
end

-- 升星回调
function UIHeroInfo:uiUpStarFunc()
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
	if not heroModel then
		return
	end
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	-- 重新显示英雄文字信息
	self:reShowHeroInfo(heroConf)
	-- 重新显示英雄星级信息
    self:initHeroStarInfo(heroModel, heroConf)
    -- 重新显示英雄部分属性信息
    self:initAttrisInfo(self.heroID, heroConf)
    -- 重新刷新天赋红点
    self:refreshGiftRedPoint(heroModel)
end

------------------- 界面显示 -----------------------
-- 显示英雄信息界面信息
function UIHeroInfo:showUIInfo(heroID)
	self.heroID 	= heroID
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)	

	local heroStar 	= 1
	if heroModel and heroModel:getStar() ~= 0 then
		heroStar = heroModel:getStar()
	end
	local heroConf = getSoldierConfItem(self.heroID, heroStar)
	if heroConf == nil then 
		print("heroConf is nil", self.heroID, heroStar) 
	end

	if heroModel and heroModel:getStar() ~= 0 then
		self.getPathBtn:setVisible(false)
		self.giftBtn:setVisible(true)
		self.upStarBtn:setVisible(true)
		self.upLvBtn:setVisible(true)
	else
		self.getPathBtn:setVisible(true)
		self.giftBtn:setVisible(false)
		self.upStarBtn:setVisible(false)
		self.upLvBtn:setVisible(false)
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
	self:initAttrisInfo(self.heroID, heroConf)
	-- 重新显示英雄技能信息
	self:initSkillInfo(heroConf)
	-- 重新显示装备节能
	self:initEqSkillInfo(heroModel, heroConf)
	-- 重新刷新天赋红点
	self:refreshGiftRedPoint(heroModel)
end

-- 重新显示英雄信息
function UIHeroInfo:reShowHeroInfo(heroConf)
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
function UIHeroInfo:reShowEqsInfo(heroModel)
	if not heroModel or heroModel:getStar() ==0 then
		for i=1, 6 do
			self:reShowEqPart(i, nil , eqPartStatus.noEqDress)
		end
		self.autoWearBtn:setVisible(false)
		EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIHeroInfo)
		return 
	end


    -- 英雄身上的装备
	local heroEqs = {}
	local eqsDyID = heroModel:getEquips()
	for _, eqDyID in pairs(eqsDyID) do
        if eqDyID ~= 0 then
		    local eqConfID = getGameModel():getEquipModel():getEquipConfId(eqDyID)
		    local propConf = getPropConfItem(eqConfID)
            if propConf == nil then print("error !!! not find propConf about eq", eqConfID) end		    
			local eqConf = getEquipmentConfItem(eqConfID)
            if eqConf == nil then print("error !!! not find eqConf about eq", eqConfID) end
			heroEqs[eqConf.Parts] = {}
			heroEqs[eqConf.Parts].dyID	= eqDyID
			heroEqs[eqConf.Parts].confID= eqConfID
            heroEqs[eqConf.Parts].propConf = propConf
			heroEqs[eqConf.Parts].lv 	= eqConf.Level
			heroEqs[eqConf.Parts].quality 	= propConf.Quality
			heroEqs[eqConf.Parts].rank 	= eqConf.Rank
        end
	end

----------------------------------红点提示, 临时本地处理---------------------------------------------------------------
	-- 英雄装备需求
	local heroLv= heroModel:getLevel()
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	local heroJob = heroConf.Common.Vocation

	-- 取出最好的装备{dyID = , confID, lv}
	local bestEqs = {}
	local bagItems = getGameModel():getBagModel():getItems()
	for k, _ in pairs(bagItems) do
		-- 筛选出装备
		if k > 1000000 then
			local eqConfID = getGameModel():getEquipModel():getEquipConfId(k)
			if eqConfID ~= nil and eqCondID ~= 0 then
				local eqConf = getEquipmentConfItem(eqConfID)
				local propConf = getPropConfItem(eqConfID)
				if eqConf ~= nil and propConf ~= nil then
					-- 判断等级
					local lvPass = heroLv >= eqConf.Level and true or false
					-- 判断职业
					local jobPass = false
					for _, job in ipairs(eqConf.Vocation) do
						if job == heroJob then
							jobPass = true
							break
						end
					end
					
					if lvPass and jobPass then
						-- 判断是否是最好
						if bestEqs[eqConf.Parts] == nil then
							bestEqs[eqConf.Parts] 		= {}
							bestEqs[eqConf.Parts].dyID	= k
							bestEqs[eqConf.Parts].confID= eqConfID
							bestEqs[eqConf.Parts].lv 	= eqConf.Level
							bestEqs[eqConf.Parts].quality = propConf.Quality
							bestEqs[eqConf.Parts].rank = eqConf.Rank
						elseif bestEqs[eqConf.Parts].rank < eqConf.Rank then
							bestEqs[eqConf.Parts].dyID	= k
							bestEqs[eqConf.Parts].confID= eqConfID
							bestEqs[eqConf.Parts].lv 	= eqConf.Level
							bestEqs[eqConf.Parts].quality = propConf.Quality
							bestEqs[eqConf.Parts].rank = eqConf.Rank
						end
					end
				end
			end
		end
	end

	-- 判断装备状态
	self.status = {}
	for i=1, 6 do
		if heroEqs[i] == nil then
			if bestEqs[i] == nil then
				-- 没有合适的装备穿戴
				self.status[i] = eqPartStatus.noEqDress
			else
				-- 有合适的装备穿戴
				self.status[i] = eqPartStatus.ownEqDress
			end
		else
			if bestEqs[i] == nil then
				-- 没有更好的装备替换
				self.status[i] = eqPartStatus.noEqReplace
			else
				if bestEqs[i].rank > heroEqs[i].rank then
					-- 有更好的装备替换
					self.status[i] = eqPartStatus.ownEqReplace
				else
					-- 没有更好的装备替换
					self.status[i] = eqPartStatus.ownEqNoReplace
				end
			end
		end
	end
-------------------------------------------------------------------------------------------------
	for i=1, 6 do
		self:reShowEqPart(i, heroEqs[i] and heroEqs[i].propConf or nil , self.status[i])
	end

	-- 是否隐藏一键穿装
	self.autoWearBtn:setVisible(false)
	for k,v in pairs(self.status) do
		if v == eqPartStatus.ownEqDress then
			self.autoWearBtn:setVisible(true)
			break
		end
	end
	EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIHeroInfo)
end

-- 重新显示某个装备信息
function UIHeroInfo:reShowEqPart(part, propConf, status)
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
function UIHeroInfo:initHeroLvInfo(heroModel)
	local heroLv = 1
	local heroStar = 1
	local heroExp = 0
	if heroModel then
		heroLv = heroModel:getLevel()
		heroStar = heroModel:getStar()
		heroExp = heroModel:getExp()
	end

	if heroStar == 0 then
		heroStar = 1
	end

	local starLvConf = getSoldierStarSettingConfItem(heroStar)
	local upStarConf = getSoldierUpRateConfItem(self.heroID)	
	if upStarConf == nil then 
		print("SoldierUpRate is nil", self.heroID) 
	end
	local maxStarLvConf = getSoldierStarSettingConfItem(upStarConf.TopStar)

	self.heroLvLab:setString(heroLv)
	self.heroMaxLvLab:setString("/" .. starLvConf.TopLevel)
	local upLvExp = heroExp

	local lvConf = getSoldierLevelSettingConfItem(heroLv + 1)
	if not lvConf then
		print("lvConf is nil", heroLv + 1)
    else
        upLvExp = lvConf.Exp
	end

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
function UIHeroInfo:initHeroStarInfo(heroModel, heroConf)
	local curStar = 1
	local curFrag = 0
	if heroModel then
		curStar = heroModel:getStar()
		curFrag = heroModel:getFrag()
	end

	if curStar == 0 then
		curStar = 1
	end

	local upStarConf = getSoldierUpRateConfItem(self.heroID)
	if upStarConf == nil then 
		print("SoldierUpRate is nil", self.heroID)
		return
	end
	local maxStar = upStarConf.TopStar

	for i=1, 7 do
		local emptyStarNode = CsbTools.getChildFromPath(self.starCsb, "award_star_null_" .. i)
		local fullStarNode = CsbTools.getChildFromPath(emptyStarNode, "award_star_full")
		emptyStarNode:setVisible(maxStar >= i and true or false)
		fullStarNode:setVisible(curStar >= i and true or false)
	end

	-- 是否是整卡文字
	if heroModel ~= nil and heroModel:getStar() ~= 0 then
		self.uiTypeLab:setString("")
	else
		self.uiTypeLab:setString(CommonHelper.getUIString(uiTypeLanIDs["frag"]))
	end

	-- 判断是否隐藏升星按钮	
	self.upStarRedNode:setVisible(false)
	self.fragPanel:setVisible(false)
	if (curStar < maxStar) and (heroModel and heroModel:getStar() ~= 0) then
		local soldierStarConf = getSoldierStarSettingConfItem(curStar + 1)
		if curFrag >= soldierStarConf.UpStarCount then
			self.upStarRedNode:setVisible(true)
		end
		self.fragPanel:setVisible(true)
		self.fragLab:setString(curFrag .. "/" .. soldierStarConf.UpStarCount)
		CsbTools.replaceImg(self.heroFragImg, heroConf.Common.HeadIcon)
	end
end

-- 根据模型初始化属性相关信息
function UIHeroInfo:initAttrisInfo(heroID, heroConf)
	self.baseAttri, self.addAttri = queryAttribute(heroID)

	self:reShowAttri(self.baseAttri, self.addAttri, heroConf)
end

-- 根据具体值设置属性显示的数值
function UIHeroInfo:reShowAttri(baseAttri, addAttri, heroConf)
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
function UIHeroInfo:countAttriSub(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)
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
function UIHeroInfo:showAttriChange(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)
	self.subAttrisInfo = self:countAttriSub(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)

	self:setTipsUpdateIsOpen(true)
	self.tipsOrder = 0	-- 显示第几个加成
end

function UIHeroInfo:attriToStr(id, value)	
	if id == 203 or id == 204 then
		value = value * 100
	end
	local valueStr = string.format("%0.1f", value)
	local str = ""
	if value > 0 then
		str = "+" .. valueStr
	elseif value == 0 then
		str = "" .. valueStr
	else
		str = valueStr
	end

	if id == 203 or id == 204 then
		str = str .. "%"
	end

	return str
end

function UIHeroInfo:setAttriLab(lab, value, suffix)
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
function UIHeroInfo:setAddAttriLab(lab, value, suffix)
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
function UIHeroInfo:closeUpdate()
	self:setTipsUpdateIsOpen(false)
	self:setRollUpdateIsOpen(false)
end

-- 打开属性差值浮动文字提示(装备)
function UIHeroInfo:setTipsUpdateIsOpen(isOpen)
	if isOpen and self.tipsSchedulerID == nil then
		self.tipsSchedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.tipsUpdate), 0.4, false)
	elseif (not isOpen) and self.tipsSchedulerID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.tipsSchedulerID)
		self.tipsSchedulerID = nil
	end
end

-- 浮动文字显示(装备)
function UIHeroInfo:tipsUpdate(dt)
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

			CsbTools.addTipsToRunningScene(string.format(str, self:attriToStr(attriID, attriValue)), {
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
function UIHeroInfo:setRollUpdateIsOpen(isOpen)
	if isOpen and self.rollSchedulerID == nil then
		self.rollSchedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.rollUpdtae), 0, false)
	elseif (not isOpen) and self.rollSchedulerID ~= nil then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.rollSchedulerID)
		self.rollSchedulerID = nil		

		-- 重新刷新防止出现数值错误
		local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
		local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
		-- 重新显示英雄等级信息
		self:initHeroLvInfo(heroModel)
		-- 重新显示英雄部分属性信息
		self:initAttrisInfo(self.heroID, heroConf)
	end
end

-- 属性滚动 (升级)
function UIHeroInfo:rollUpdtae(dt)
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
		if info.pAttack >= info.mAttack then
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
function UIHeroInfo:initSkillInfo(heroConf)
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

function UIHeroInfo:initEqSkillInfo(heroModel, heroConf)
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
		local skillConf = getSkillConfItem(skills[4])
		if not skillConf then 
			print("skillConf is nil, skillID: ", skills[4])
		end
		-- 判断是否激活装备技能
		local isActive = self:checkActiveEqSkill(self.heroID, heroModel, heroConf)
		self.skillNodeInfo[4].btn:setVisible(isActive)
		if not exitSkill then
			self:initSkillNode(self.skillNodeInfo[4].csb, skills[4], false)
			self:reShowSkillLab(skillConf)				
			CommonHelper.playCsbAnimation(self.skillNodeInfo[4].csb, "On", false, nil)
		else
			self:initSkillNode(self.skillNodeInfo[4].csb, skills[4], false)
			CommonHelper.playCsbAnimation(self.skillNodeInfo[4].csb, "Normal", false, nil)
		end
	else
		self.skillNodeInfo[4].btn:setVisible(false)
		if not exitSkill then
			self.skillPanel:setVisible(false)
		end
	end
end

function UIHeroInfo:checkActiveEqSkill(heroID, heroModel, heroConf)
	local isActive = false

	if not heroModel or heroModel:getStar() == 0 then
		return isActive
	end

	local eqSkillConf = getEquipSkillConfig(heroID)
	if not eqSkillConf then
		print("error eqSkillConf is nil ", heroID)
	end

	local heroEqsConfID = {}
	local eqsDyID = heroModel:getEquips()
	for _, eqDyID in pairs(eqsDyID) do
        if eqDyID ~= 0 then
		    local eqConfID = getGameModel():getEquipModel():getEquipConfId(eqDyID)
		    heroEqsConfID[eqConfID] = true
        end
	end

	for _, eqs in ipairs(eqSkillConf.EquipmentID) do
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

-- 根据具体数值初始化某个技能的显示
function UIHeroInfo:initSkillNode(csb, id, isGray)
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

-- 重新显示技能介绍文本
function UIHeroInfo:reShowSkillLab(skillConf)
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

-- 根据模型显示天赋红点
function UIHeroInfo:refreshGiftRedPoint(heroModel)
	if not heroModel then
		self.giftRedNode:setVisible(false)
		return
	end

	local heroTalent = heroModel:getTalent()
	local heroStar = heroModel:getStar()
	for _,v in ipairs(heroTalent) do
		if v ~= 0 then
			heroStar = heroStar - 1
		end
	end

	self.giftRedNode:setVisible(heroStar > 0)
end

-- 显示装备属性改变差异浮动文字提示
function UIHeroInfo:showChangeEqInfo(heroID)
	-- 刷新装备显示
	local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroID)
	if not heroModel then
		return
	end
	local heroConf = getSoldierConfItem(heroModel:getID(), heroModel:getStar())
	if heroModel == nil or heroConf == nil then return end
	self:reShowEqsInfo(heroModel)
	self:initEqSkillInfo(heroModel, heroConf)
    
	-- 记录前一个属性
	local preBaseAttri = {}
	local preAddAttri = {}
	for k,v in pairs(self.baseAttri) do
		preBaseAttri[k] = v
	end
	for k,v in pairs(self.addAttri) do
		preAddAttri[k] = v
	end

	self.baseAttri, self.addAttri = queryAttribute(heroID)

	-- 刷新属性显示
	self:reShowAttri(self.baseAttri, self.addAttri, heroConf)

	-- 显示属性增减
	self:showAttriChange(preBaseAttri, preAddAttri, self.baseAttri, self.addAttri)
end

-- 穿装 卸装回调
function UIHeroInfo:onWearEq(mainCmd, subCmd, data)
	self:closeUpdate()

	local heroID = data:readInt()
	local eqCount = data:readInt()
	if eqCount == 0 then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
		return
	end

	local isUnload = false
	for i=1, eqCount do
		local eqDyID = data:readInt()
		local eqPart = data:readInt()
		if eqDyID == 0 then
			ModelHelper.heroUndressEq(heroID, eqPart)
			isUnload = true
		else
			ModelHelper.heroDressEq(heroID, eqDyID)
		end
	end

	-- 提示穿戴成功
	if isUnload then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(192))
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(182))
	end

	self:showChangeEqInfo(heroID)
end

return UIHeroInfo