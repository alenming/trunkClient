--[[
    查看英雄信息
--]]

local UILookHeroInfo = class("UILookHeroInfo", require("common.UIView"))

local AnimationClick= require("game.comm.AnimationClick")
local UIEquipViewHelper = require("game.hero.UIEquipViewHelper")

local csbFile 		= ResConfig.UILookHeroInfo.Csb2
local eqItemFile 	= "ui_new/g_gamehall/c_collection/EqItem.csb"
local attribute 	= {hp = 114, pAttack = 106, mAttack = 107, pGuard = 108, mGuard = 109, miss = 207}
local jobLanIDs 	= {[1] = 521, [2] = 524, [3] = 522, [4] = 523, [5] = 525, [6] = 520}
local uiTypeLanIDs 	= {frag = 395, mercenary = 2040}
local rareAni 		= {[1] = "None", [3] = "Blue", [4] = "Voilet", [5] = "Golden"}

function UILookHeroInfo:ctor()
	-- 初始化UI
	self.rootPath = csbFile.heroInfo
	self.root = getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, handler(self, self.backBtnCallBack))

	-- 装备显示界面
	self.eqInfoCsb = CsbTools.getChildFromPath(self.root, "MainPanel/EquipInfo")
    self.equipInfoCsb = CsbTools.getChildFromPath(self.eqInfoCsb, "EqInfoPanel/EquipInfo")
	self.eqInfoSize = CsbTools.getChildFromPath(self.eqInfoCsb, "EqInfoPanel"):getBoundingBox()
    local effectBtnCsb = CsbTools.getChildFromPath(self.eqInfoCsb, "FileNode_2")
    CsbTools.getChildFromPath(effectBtnCsb, "WearButton"):setVisible(false)
	CsbTools.getChildFromPath(effectBtnCsb, "ChangeButton"):setVisible(false)

	-- 屏蔽层
	self.mask = CsbTools.getChildFromPath(self.root, "MainPanel/MaskPanel")
	self.mask:addClickEventListener(handler(self, self.maskCallBack))

	-- 切换英雄按钮
	CsbTools.getChildFromPath(self.root, "LeftButton"):setVisible(false)
	CsbTools.getChildFromPath(self.root, "RightButton"):setVisible(false)

	------------------英雄总览界面左面板----------------
	local leftPanel = CsbTools.getChildFromPath(self.root, "MainPanel/LeftPanel")

	-- 英雄文字介绍相关(描述, 名称, 职业, 种族)
	self.heroDescLab = CsbTools.getChildFromPath(leftPanel, "IntroText")
	self.heroNameLab = CsbTools.getChildFromPath(leftPanel, "NameLabel")
	self.heroJobLab = CsbTools.getChildFromPath(leftPanel, "Profesion")
	self.heroRaceImg = CsbTools.getChildFromPath(leftPanel, "JobImage")
	-- 英雄星级
	self.starCsb = CsbTools.getChildFromPath(leftPanel, "HeroStar")
	-- 英雄骨骼动画
	local aniClickLayout = CsbTools.getChildFromPath(leftPanel, "HeroPanel")
	self.heroAniNode = CsbTools.getChildFromPath(aniClickLayout, "HeroNode")
	self.animationClick = AnimationClick.new()
	self.originX, self.originY = self.heroAniNode:getPosition()
	aniClickLayout:setTouchEnabled(true)
	aniClickLayout:addClickEventListener(handler(self, self.aniClickCallBack))
	-- 6件装备
	for i = 1, 6 do
		self["eqBtn_" .. i]	= CsbTools.getChildFromPath(leftPanel, "EqButton" .. i)
		self["eqCsb_" .. i]	= CsbTools.getChildFromPath(self["eqBtn_" .. i], "EqItem")
		local bgImg = CsbTools.getChildFromPath(self["eqCsb_" .. i], "EqItemPanel/EqBgImage")
		
		CsbTools.replaceSprite(bgImg, getIconSettingConfItem().EqIcon[i])
		self["eqBtn_" .. i]:setTag(i)
		CsbTools.initButton(self["eqBtn_" .. i], handler(self, self.eqBtnCallBack), nil, nil, "EqItem")
	end
	
    CsbTools.getChildFromPath(leftPanel, "AutoWearButton"):setVisible(false)
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
    self.uiTypeLab:setVisible(false)
	CsbTools.getChildFromPath(rightPanel, "CardPanel"):setVisible(false)

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
	CsbTools.initButton(self.giftBtn, handler(self, self.giftBtnCallBack))
	self.upStarBtn 	= CsbTools.getChildFromPath(rightPanel, "UpStarButton"):setVisible(false)
	self.upLvBtn	= CsbTools.getChildFromPath(rightPanel, "UpLevelButton"):setVisible(false)
	self.getPathBtn = CsbTools.getChildFromPath(rightPanel, "GetPathButton"):setVisible(false)
	-- 天赋红点节点
	CsbTools.getChildFromPath(self.giftBtn, "RedTipPoint"):setVisible(false)
end

function UILookHeroInfo:onOpen(_, heroInfo)
    if type(heroInfo) ~= "table" then
        return
    end

	self.heroInfo = heroInfo
	self.mask:setTouchEnabled(false)
	self.addAniFinish = true

	self:showUIInfo()
end

function UILookHeroInfo:onClose()
	self.heroAniNode:removeAllChildren()
end

-------------------- 按钮回调 ----------------------
function UILookHeroInfo:backBtnCallBack(ref)
	UIManager.close()
end

-- 点击到屏蔽层, 取消屏蔽, 取消装备显示
function UILookHeroInfo:maskCallBack(ref)
	self.mask:setTouchEnabled(false)
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOff", false, nil, true)
end

-- 装备框点击回调
function UILookHeroInfo:eqBtnCallBack(ref)
	local eqPart = ref:getTag()
    local equipInfo = self.heroInfo.equips[eqPart]
	if equipInfo then
        UIEquipViewHelper:setCsbByEquipInfo(self.equipInfoCsb, equipInfo, 340)
		self.mask:setTouchEnabled(true)
        CommonHelper.playCsbAnimate(self.root, self.rootPath, "TipsOn", false, nil, true)
        -- 移动该装备的右侧
        local wPos1 = ref:convertToWorldSpace(cc.p(0,0))
        local wPos2 = self.eqInfoCsb:convertToWorldSpace(cc.p(0,0))
        local pos2  = self.eqInfoCsb:getPosition()
        local posX 	= pos2 - (wPos2.x - wPos1.x) + (self.eqInfoSize.width/2 + ref:getBoundingBox().width)
        self.eqInfoCsb:setPositionX(posX)
	end
end

-- 天赋点击回调
function UILookHeroInfo:giftBtnCallBack(ref)
	if self.addAniFinish then
		UIManager.open(UIManager.UI.UIHeroTalent, nil, self.heroInfo)
	end
end

-- 技能点击回调
function UILookHeroInfo:skillCallBack(ref)
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
function UILookHeroInfo:createAniCallBack(animation, id)
	self.addAniFinish = true
	if animation and id == self.showAnimationID then
		self.heroAniNode:removeAllChildren()
		self.heroAniNode:addChild(animation)
		self.animationClick:setAnimationNode(animation)

	    CommonHelper.setRoleZoom(self.heroID, animation, self.heroAniNode, self.originX, self.originY)
	end

end

-- 骨骼动画点击播放随机动作
function UILookHeroInfo:aniClickCallBack(touch, event)
	self.animationClick:playRandomAnimation()
end

------------------- 界面显示 -----------------------
-- 显示英雄信息界面信息
function UILookHeroInfo:showUIInfo()
	local heroConf = getSoldierConfItem(self.heroInfo.heroID, self.heroInfo.heroStar)
	if heroConf == nil then 
		print("heroConf is nil", self.heroInfo.heroID, self.heroInfo.heroStar)
        return
	end

	-- 重新显示英雄文字信息
	self:reShowHeroInfo(heroConf)
	-- 重新显示英雄装备信息
	self:reShowEqsInfo()
	-- 重新显示英雄等级信息
	self:initHeroLvInfo()
	-- 重新显示英雄星级信息
	self:initHeroStarInfo(heroConf)
	-- 重新显示英雄部分属性信息
	self:initAttrisInfo(heroConf)
	-- 重新显示英雄技能信息
	self:initSkillInfo(heroConf)
	-- 重新显示装备信息
	self:initEqSkillInfo(heroConf)
end

-- 重新显示英雄信息
function UILookHeroInfo:reShowHeroInfo(heroConf)
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
function UILookHeroInfo:reShowEqsInfo()
    for part = 1, 6 do
        local eqCsb = self["eqCsb_" .. part]

        local equipInfo = self.heroInfo.equips[part]
		if equipInfo then
            local propConf = getPropConfItem(equipInfo.confId)
	        if propConf ~= nil then
		        local eqFrameImg = CsbTools.getChildFromPath(eqCsb, "EqItemPanel/BgImage")
		        local eqImg = CsbTools.getChildFromPath(eqCsb, "EqItemPanel/EqImage")
		        CsbTools.replaceImg(eqFrameImg, getItemLevelSettingItem(propConf.Quality).ItemFrame)
		        CsbTools.replaceImg(eqImg, propConf.Icon)
	        else
		        local eqFrameImg= CsbTools.getChildFromPath(eqCsb, "EqItemPanel/BgImage")
		        CsbTools.replaceImg(eqFrameImg, getItemLevelSettingItem(1).ItemFrame)
	        end

		    CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "Normal", false, nil, true)
	    else
		    CommonHelper.playCsbAnimate(eqCsb, eqItemFile, "No", false, nil, true)
	    end
	end
end

-- 根据模型初始化英雄等级相关信息
function UILookHeroInfo:initHeroLvInfo()
	local starLvConf = getSoldierStarSettingConfItem(self.heroInfo.heroStar)
	local upStarConf = getSoldierUpRateConfItem(self.heroInfo.heroID)	
	if upStarConf == nil then 
		print("SoldierUpRate is nil", self.heroID) 
        return
	end

	local maxStarLvConf = getSoldierStarSettingConfItem(upStarConf.TopStar)
	self.heroLvLab:setString(self.heroInfo.heroLv)
	self.heroMaxLvLab:setString("/" .. starLvConf.TopLevel)
	local upLvExp = self.heroInfo.heroExp

	local lvConf = getSoldierLevelSettingConfItem(self.heroInfo.heroLv + 1)
	if not lvConf then
		print("lvConf is nil", heroLv + 1)
    else
        upLvExp = lvConf.Exp
	end

    self.expLab:setString(self.heroInfo.heroExp .. "/" .. upLvExp)
    self.expBar:setPercent(self.heroInfo.heroExp/upLvExp*100)
end

-- 根据模型初始化英雄星级相关信息
function UILookHeroInfo:initHeroStarInfo(heroConf)
	local upStarConf = getSoldierUpRateConfItem(self.heroInfo.heroID)
	if upStarConf == nil then 
		print("SoldierUpRate is nil", self.heroInfo.heroID)
		return
	end

	for i = 1, 7 do
		local emptyStarNode = CsbTools.getChildFromPath(self.starCsb, "award_star_null_" .. i)
		local fullStarNode = CsbTools.getChildFromPath(emptyStarNode, "award_star_full")
		emptyStarNode:setVisible(upStarConf.TopStar >= i and true or false)
		fullStarNode:setVisible(self.heroInfo.heroStar >= i and true or false)
	end
end

-- 根据模型初始化属性相关信息
function UILookHeroInfo:initAttrisInfo(heroConf)
	self.baseAttri, self.addAttri = queryHeroAttribute(self.heroInfo.heroID, 
        self.heroInfo.heroLv, 
        self.heroInfo.heroStar, 
        {})

	self:reShowAttri(self.baseAttri, self.addAttri, heroConf)
end

-- 根据具体值设置属性显示的数值
function UILookHeroInfo:reShowAttri(baseAttri, addAttri, heroConf)
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
function UILookHeroInfo:countAttriSub(preBaseAttri, preAddAttri, curBaseAttri, curAddAttri)
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

function UILookHeroInfo:attriToStr(id, value)	
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

function UILookHeroInfo:setAttriLab(lab, value, suffix)
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
function UILookHeroInfo:setAddAttriLab(lab, value, suffix)
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

-- 根据模型和配表 ,初始化技能信息
function UILookHeroInfo:initSkillInfo(heroConf)
	local skills = heroConf.Common.Skill
	for i = 1, 3 do
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

function UILookHeroInfo:initEqSkillInfo(heroConf)
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
            return
		end

		-- 判断是否激活装备技能
		self.skillNodeInfo[4].btn:setVisible(self:checkActiveEqSkill(heroConf))
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

function UILookHeroInfo:checkActiveEqSkill(heroConf)
	local isActive = false
	local eqSkillConf = getEquipSkillConfig(self.heroInfo.heroID)
	if not eqSkillConf then
		print("error eqSkillConf is nil ", self.heroInfo.heroID)
        return
	end

	local heroEqsConfID = {}
	local eqsDyID = {}
	for _, eqDyID in pairs(eqsDyID) do
        if eqDyID ~= 0 then
		    local eqConfID = 0
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
function UILookHeroInfo:initSkillNode(csb, id, isGray)
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
function UILookHeroInfo:reShowSkillLab(skillConf)
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

return UILookHeroInfo