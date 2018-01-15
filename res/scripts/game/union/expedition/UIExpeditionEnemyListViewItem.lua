local scheduler = require("framework.scheduler")

local UIExpeditionEnemyListViewItem = class("UIExpeditionEnemyListViewItem", function () 
	return require("common.UIView").new()
end)

function UIExpeditionEnemyListViewItem:ctor()
	self.mUnionModel = getGameModel():getUnionModel()

	self.rootPath = ResConfig.UIExpeditionDiaryIslandIntro.Csb2.item
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    self.mHeroPanel = CsbTools.getChildFromPath(self.root, "HeroPanel")
    self.mLvImg = CsbTools.getChildFromPath(self.mHeroPanel, "Level")
    self.mName = CsbTools.getChildFromPath(self.mHeroPanel, "Name")
    self.mBossImg = CsbTools.getChildFromPath(self.mHeroPanel, "BossImage")
    self.mBossBg = CsbTools.getChildFromPath(self.mHeroPanel, "Image_Bg")
    self.mTips = CsbTools.getChildFromPath(self.mHeroPanel, "Tips")
    self.mRandIcon = CsbTools.getChildFromPath(self.mHeroPanel, "RandomIcon")

    self:setContentSize(self.mHeroPanel:getContentSize())

    self.mHeroPanel:setTouchEnabled(true)
end

function UIExpeditionEnemyListViewItem:setRoleCfg(roleCfg)
	-- 设置危险度
	local letterLv = CommonHelper.numberLv2letterLv(roleCfg.RoleEvaluate)
    self.mLvImg:setSpriteFrame(string.format("latter_%s.png", letterLv))

    -- 设置背景图
    if #roleCfg.RoleBg > 0 then
        self.mBossBg:loadTexture(roleCfg.RoleBg, 1)
    end

    local uLv = self.mUnionModel:getUnionLv()
    local cfgExpdMap = getExpeditionMapConf(roleCfg.RoleMapID)
    if uLv < cfgExpdMap.unlockLv then	-- 公会等级不够
    	self.mName:setVisible(false)
    	self.mTips:setVisible(true)
    	self.mRandIcon:setVisible(true)

    	-- 设置tips
        self.mTips:setString(string.format(getUILanConfItem(1905), cfgExpdMap.unlockLv))
    else
    	self.mName:setVisible(true)
    	self.mTips:setVisible(false)
    	self.mRandIcon:setVisible(false)

	    -- 设置名字
	    self.mName:setString(getStageLanConfItem(roleCfg.RoleName))

	    -- 设置人物图像
        if type(roleCfg.RolePic) == "string" and #roleCfg.RolePic > 0 then
            self.mBossImg:setSpriteFrame(roleCfg.RolePic)
        end
	end
end

function UIExpeditionEnemyListViewItem:setClickCallback(callback)
	self.mHeroPanel:addClickEventListener(callback)
end

return UIExpeditionEnemyListViewItem