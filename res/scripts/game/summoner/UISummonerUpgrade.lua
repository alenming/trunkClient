--[[
召唤师升级界面
]]

local UISummonerUpgrade = class("UISummonerUpgrade", function()
    return require("common.UIView").new()
end)

local UILanguage = {lv = 212, summonerHP = 211, confirm = 500, heroLv = 241, newFunc = 2300, backHall = 2301}

function UISummonerUpgrade:ctor()
end

function UISummonerUpgrade:init()
    self.rootPath = "ui_new/g_gamehall/s_sommoner/UpLv_Summoner.csb"
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    self:initUI()
end

function UISummonerUpgrade:initUI()
    self:setGlobalZOrder(10)
	self:setLocalZOrder(10)

    -- 按钮
    self.confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfirmButtom")
    self.backHallBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ReturnButton")
    CsbTools.initButton(self.confirmBtn, function () UIManager.close() end)
    CsbTools.initButton(self.backHallBtn, handler(self, self.backHallBtnCallBack), CommonHelper.getUIString(UILanguage.backHall))

    -- 滚动列表
    self.scroll = CsbTools.getChildFromPath(self.root, "ScrollView")
    self.scroll:setScrollBarEnabled(false)
    -- 升级信息节点
    self.upLvLayout = CsbTools.getChildFromPath(self.scroll, "UpLvPanel")
    -- 解锁显示的容器节点
    self.unlockLayout = CsbTools.getChildFromPath(self.scroll, "UnlockPanel")

    -- 写死的文本
    CsbTools.getChildFromPath(self.upLvLayout, "Tips1")
        :setString(CommonHelper.getUIString(UILanguage.lv))
    CsbTools.getChildFromPath(self.upLvLayout, "Tips2")
        :setString(CommonHelper.getUIString(UILanguage.summonerHP))
    CsbTools.getChildFromPath(self.upLvLayout, "LvFullTips")
        :setString(CommonHelper.getUIString(UILanguage.heroLv))
    CsbTools.getChildFromPath(self.unlockLayout, "TalkText")
        :setString(CommonHelper.getUIString(UILanguage.newFunc))

    -- 待修改的文本节点
    self.oldLvLb = CsbTools.getChildFromPath(self.upLvLayout, "Level_F")
    self.newLvLb = CsbTools.getChildFromPath(self.upLvLayout, "Level_B")
    self.oldLvHpLb = CsbTools.getChildFromPath(self.upLvLayout, "HP_F")
    self.newLvHpLb = CsbTools.getChildFromPath(self.upLvLayout, "HP_B")
    self.curHeroLvLb = CsbTools.getChildFromPath(self.upLvLayout, "Lv1")
    self.maxHeroLvLb = CsbTools.getChildFromPath(self.upLvLayout, "Lv2")
    -- 待修改的解锁节点
    self.unlockNode = CsbTools.getChildFromPath(self.unlockLayout, "Node")
    -- 等级上限提升箭头
    self.lvTopChangeImg = CsbTools.getChildFromPath(self.upLvLayout, "ArrowImage_3")
end

function UISummonerUpgrade:onOpen(fromUIID, oldLv, curLv)
    self.scroll:jumpToTop()
    CommonHelper.playCsbAnimation(self.root, "Open", false, function()
        self.scroll:scrollToBottom(2, true)
    end)

    self.oldLvLb:setString(oldLv)
    self.newLvLb:setString(curLv)
    self.oldLvHpLb:setString(getUserLevelSettingConfItem(oldLv).SummonerHP)
    self.newLvHpLb:setString(getUserLevelSettingConfItem(curLv).SummonerHP)

    local limitLv = 15
    if curLv > limitLv then
        self.curHeroLvLb:setString(oldLv < limitLv and limitLv or oldLv)
        self.maxHeroLvLb:setString(curLv)
        self.maxHeroLvLb:setOpacity(255)
        self.lvTopChangeImg:setOpacity(255)
    else
        self.curHeroLvLb:setString(limitLv)
        self.maxHeroLvLb:setOpacity(0)
        self.lvTopChangeImg:setOpacity(0)
    end

    -- 计算新功能
    local summonerLvConf = getSummonerLvUpConfig()
    local newFuncConf = {}
    for lv, info in pairs(summonerLvConf) do
        if oldLv < lv and curLv >= lv then
            for i=1,3 do
                if info["Name" .. i] and info["Name" .. i] ~= 0 and 
                    info["Picture" .. i] and info["Picture" .. i] ~= "" then
                    table.insert(newFuncConf, {name = info["Name" .. i], img = info["Picture" .. i]})
                end
            end
        end
    end

    local upLvLayoutHeight = self.upLvLayout:getContentSize().height
    local unlockLayoutHeight = self.unlockLayout:getContentSize().height
    local innerSize = self.scroll:getContentSize()

    if #newFuncConf == 0 then
        self.unlockLayout:setVisible(false)
        self.backHallBtn:setOpacity(0)
        self.backHallBtn:setTouchEnabled(false)
        innerSize.height = upLvLayoutHeight
    else
        self.unlockLayout:setVisible(true)
        self.backHallBtn:setOpacity(255)
        self.backHallBtn:setTouchEnabled(true)
        innerSize.height = upLvLayoutHeight + unlockLayoutHeight
    end
    self.scroll:setInnerContainerSize(innerSize)
    self.upLvLayout:setPositionY(innerSize.height - upLvLayoutHeight/2)
    self.unlockLayout:setPositionY(innerSize.height - upLvLayoutHeight - unlockLayoutHeight/2)

    self.unlockNode:removeAllChildren()
    for i, info in ipairs(newFuncConf) do
        local item = getResManager():cloneCsbNode("ui_new/g_guide/UnlockItem.csb")
        local layout = CsbTools.getChildFromPath(item, "MainPanel")
        local headNode = CsbTools.getChildFromPath(layout, "Head")
        local descLab = CsbTools.getChildFromPath(layout, "TitleText")
        item:setPosition(cc.p((#newFuncConf/2 - i + 0.5)*layout:getContentSize().width ,0))
        descLab:setString(CommonHelper.getUIString(info.name))
        headNode:addChild(getResManager():cloneCsbNode(info.img))
        self.unlockNode:addChild(item)
    end
end

function UISummonerUpgrade:onClose()

end

function UISummonerUpgrade:backHallBtnCallBack()
    if SceneManager.CurScene == SceneManager.Scene.SceneHall then
        UIManager.closeToUI(UIManager.UI.UIHall)
    else
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end
end

return UISummonerUpgrade
