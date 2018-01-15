--[[
召唤师显示界面
]]

local UIShowSummoner = class("UIShowSummoner", function()
    return require("common.UIView").new()
end)

local UILanguage = {confirm = 500}

function UIShowSummoner:ctor()
end

function UIShowSummoner:init()
    self.rootPath = ResConfig.UIShowSummoner.Csb2.showSummoner
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    self:initUI()
end

function UIShowSummoner:initUI()
    self:setGlobalZOrder(10)
	self:setLocalZOrder(10)

    CsbTools.initButton(CsbTools.getChildFromPath(self.root, "BuyEffect/ConfirmButtom")
        , function () UIManager.close() end, CommonHelper.getUIString(UILanguage.confirm)
        , "ConfirmButtom/NameLabel", "ConfirmButtom")

    self.summonerName = CsbTools.getChildFromPath(self.root, "BuyEffect/InfoPanel/SummonerName")
    self.infoLabel = CsbTools.getChildFromPath(self.root, "BuyEffect/InfoPanel/InfoLabel")
    self.titleLb = CsbTools.getChildFromPath(self.root, "BuyEffect/BuyFontLabel")
    self.heroNode = CsbTools.getChildFromPath(self.root, "BuyEffect/HeroNode")
end

function UIShowSummoner:onOpen(fromUIID, summonerID)
    local conf = getHeroConfItem(summonerID)
    if not conf then
        print("can't find summoner in conf", summonerID)
        return
    end

    self.summonerName:setString(getHSLanConfItem(conf.Common.Name))
    self.infoLabel:setString(getHSLanConfItem(conf.Common.Desc))
    --self.titleLb:setString(CommonHelper.getUIString(title))
    -- 播放该召唤师声音
    MusicManager.playSoundEffect(summonerID)

    AnimatePool.createAnimate(conf.Common.AnimationID, function(animation)
        if animation and self.heroNode then
            self.heroNode:removeAllChildren()
            self.heroNode:addChild(animation)
        end
    end)
end

function UIShowSummoner:onClose()
    if self.heroNode then
        self.heroNode:removeAllChildren()
    end
end

return UIShowSummoner
