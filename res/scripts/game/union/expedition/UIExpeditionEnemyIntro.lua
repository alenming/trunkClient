local scheduler = require("framework.scheduler")  

local UIExpeditionEnemyIntro = class("UIExpeditionEnemyIntro", function ()
	return require("common.UIView").new()
end)

function UIExpeditionEnemyIntro:ctor()
	self.mExpeditionModel = getGameModel():getExpeditionModel()
    self.mUserModel = getGameModel():getUserModel()
end

function UIExpeditionEnemyIntro:init()
    self.rootPath = ResConfig.UIExpeditionEnemyIntro.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.mMainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    self.mMapPanel = CsbTools.getChildFromPath(self.mMainPanel, "MapPanel")
    self.mTitleText = CsbTools.getChildFromPath(self.mMapPanel, "TitleText")
    self.mLvImg = CsbTools.getChildFromPath(self.mMapPanel, "LevelImage")
    self.mIntroText = CsbTools.getChildFromPath(self.mMapPanel, "IntroText")
    self.mHpText = CsbTools.getChildFromPath(self.mMapPanel, "LoadingNum")
    self.mHeroNode = CsbTools.getChildFromPath(self.mMapPanel, "HeroNode")
    self.mCoinNum = CsbTools.getChildFromPath(self.mMapPanel, "CoinNum")

    self.mEnergInfo = CsbTools.getChildFromPath(self.root, "EnergInfo")
    self.mGemInfo = CsbTools.getChildFromPath(self.root, "GemInfo")
    self.mGoldInfo = CsbTools.getChildFromPath(self.root, "GoldInfo")
    self.mTime = CsbTools.getChildFromPath(self.root, "Time")

    -- 退出按钮
    self.mBackButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(self.mBackButton, handler(self, self.onClick))

    self.mRightButton = CsbTools.getChildFromPath(self.root, "RightButton")
    CsbTools.initButton(self.mRightButton, handler(self, self.onClick))

    self.mLeftButton = CsbTools.getChildFromPath(self.root, "LeftButton")
    CsbTools.initButton(self.mLeftButton, handler(self, self.onClick))
end

function UIExpeditionEnemyIntro:initTime()
    self.mTime:setString(os.date("%H:%M"))
    self.mSchedulerHandler = scheduler.scheduleGlobal(function()
        self.mTime:setString(os.date("%H:%M"))
    end, 1)
end

function UIExpeditionEnemyIntro:onOpen(_, areaId, roleIndex)
    self:updateGold()
    self:updateDiamond()
    self:setRole(areaId, roleIndex)

    self:initTime()
end

function UIExpeditionEnemyIntro:onClose()
	-- 移除道具的提示框
	for i, tips in pairs(self.mPropTips) do
		tips:removePropAllTips()
		self.mPropTips[i] = nil
	end

    scheduler.unscheduleGlobal(self.mSchedulerHandler)
end

function UIExpeditionEnemyIntro:onClick(obj)
	local name = obj:getName()
	if name == "BackButton" then
		UIManager.close()
    elseif name == "RightButton" then
        local cfgExpdBook = getExpeditionBookItem(self.mAreaId)
        if cfgExpdBook.Role[self.mRoleIndex + 1] then
            self:setRole(self.mRoleIndex + 1)
        end
    elseif name == "LeftButton" then
        local cfgExpdBook = getExpeditionBookItem(self.mAreaId)
        if cfgExpdBook.Role[self.mRoleIndex - 1] then
            self:setRole(self.mRoleIndex - 1)
        end
	end
end

function UIExpeditionEnemyIntro:setRole(areaId, roleIndex)
    self.mAreaId = areaId
    self.mRoleIndex = roleIndex

    local cfgExpdBook = getExpeditionBookItem(self.mAreaId)
    local roleCfg = cfgExpdBook.Role[self.mRoleIndex]

	-- 设置标题
	self.mTitleText:setString(getStageLanConfItem(roleCfg.RoleName))

	-- 设置危险度
	local letterLv = CommonHelper.numberLv2letterLv(roleCfg.RoleEvaluate)
    self.mLvImg:setSpriteFrame(string.format("latter_%s.png", letterLv))

    -- 设置人物介绍
    self.mIntroText:setString(getStageLanConfItem(roleCfg.RoleDesc))

    -- 设置人物所需贡献
    self.mCoinNum:setString(roleCfg.RoleContribut)

    -- 设置人物血量
    local cfgExpdMap = getExpeditionMapConf(roleCfg.RoleMapID)
    local hp = cfgExpdMap.Stages[#cfgExpdMap.Stages].bossHp
    self.mHpText:setString(hp)

    -- 设置人物动画
    local bossCfg = getBossConfItem(roleCfg.RoleId)
    if not bossCfg then
        print("error bossCfg is nil ", roleCfg.RoleId)
    end
    AnimatePool.createAnimate(bossCfg.Common.AnimationID, function (animation) 
        local zoom = getRoleZoom(roleCfg.RoleId)
        animation:setScale(zoom.ZoomNumber)
        self.mHeroNode:addChild(animation)
    end)

    -- 设置技能
    for i = 1, 4 do
    	local item = CsbTools.getChildFromPath(self.mMapPanel, "SkillItem"..i)

    	local skId = roleCfg.RoleSkill[i]
    	if skId then
    		item:setVisible(true)

    		local skItem = CsbTools.getChildFromPath(item, "SkillItem")
    		local tipPanel = CsbTools.getChildFromPath(skItem, "TipPanel")
    		local skImg = CsbTools.getChildFromPath(skItem, "SkillImage")
    		local skCfg = getSkillConfItem(skId)
            if not skCfg then
                print("error skillConf is nil", skId)
            end

    		tipPanel:setVisible(false)
    		-- 监听技能图标触摸事件，显示tips界面
    		skItem:addTouchEventListener(function (_, event)
    			if event == 0 then 		-- began
    				tipPanel:setVisible(true)

    				local originSkNameText = CsbTools.getChildFromPath(tipPanel, "SkillNameLabel")
                    -- 设置技能名字
                    originSkNameText:setString(getHSSkillLanConfItem(skCfg.Name))

    				local originSkDescText = CsbTools.getChildFromPath(tipPanel, "SkillInfoLabel")
                    originSkDescText:setVisible(false)
                    local originSkAttackText = CsbTools.getChildFromPath(tipPanel, "SkillAttackLabel")
                    originSkAttackText:setVisible(false)

    				-- 设置技能描述
                    local skDescRTextName = "SkDescRText"
                    local skDescRText = tipPanel:getChildByName(skDescRTextName)
                    local originSize = originSkDescText:getContentSize()
                    if not skDescRText then
                        skDescRText = createRichText(originSize.width)
                        skDescRText:setName(skDescRTextName)

                        originSkDescText:getParent():addChild(skDescRText)
                    end                    
                    skDescRText:setString(getHSSkillLanConfItem(skCfg.Desc))

                    local originPosX, originPosY = originSkDescText:getPosition()
                    local newPos = cc.p(originPosX - originSize.width / 2, originPosY + originSize.height / 2)
                    skDescRText:setPosition(cc.p(newPos.x, newPos.y - skDescRText:getContentSize().height))

    			elseif event == 2 or event == 3 then -- ended or canceled
    				tipPanel:setVisible(false)
    			end
    		end)

    		-- 设置技能图标
    		skImg:loadTexture(skCfg.IconName, 1)
    	else
    		item:setVisible(false)
    	end
    end

    -- 设置稀有物品
    for i = 1, 3 do
    	local item = CsbTools.getChildFromPath(self.mMapPanel, "AwardItem"..i)
    	local mainPanel = CsbTools.getChildFromPath(item, "MainPanel")
    	local propConf = getPropConfItem(roleCfg.RoleDrop[i])
        UIAwardHelper.setAllItemOfConf(item, propConf)

        if not self.mPropTips then
        	self.mPropTips = {}
        end
        local tips = require("game.comm.PropTips").new()
		table.insert(self.mPropTips, tips)
		tips:addPropTips(mainPanel, propConf)
    end
end

function UIExpeditionEnemyIntro:updateGold()
    local gold = self.mUserModel:getGold()
    local label = CsbTools.getChildFromPath(self.mGoldInfo, "GoldPanel/GoldCountLabel")
    label:setString(gold)
end

function UIExpeditionEnemyIntro:updateDiamond()
    local diamond = self.mUserModel:getDiamond()
    local label = CsbTools.getChildFromPath(self.mGemInfo, "GemPanel/GemCountLabel")
    label:setString(diamond)
end

return UIExpeditionEnemyIntro