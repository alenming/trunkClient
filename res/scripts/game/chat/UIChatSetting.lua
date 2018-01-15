--[[
聊天设置
1、等级设置:屏蔽低于某级的玩家信息
2、显示设置:大厅界面显示某个模式的聊天
]]

local UIChatSetting = class("UIChatSetting", function()
    return require("common.UIView").new()
end)
local tabBtnFile = "ui_new/g_gamehall/b_bag/AllButton2.csb"

local UILanguage = {cancel = 501, confrim = 500, setCondition = 441, setLvTips = 442
    , showCondition = 443, showTips = 444, worldMode = 445, unionMode = 446, chooseModeTips = 449}
local FuncBtn = {LvButton = {lang = 26}, DisButton = {lang = 447}}
local MIN_LV_LIMIT = 1 -- 最低等级1

function UIChatSetting:ctor()

end

function UIChatSetting:init()
    self.rootPath = ResConfig.UIChatSetting.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self:initUI()
end

function UIChatSetting:onOpen(fromUI, ...)
    -- 默认打开为设置等级
    self:funcBtnCallBack(self.firstBtn)
end

function UIChatSetting:initUI()
    -- 功能按钮切换
    for k, v in pairs(FuncBtn) do
        local obj = CsbTools.getChildFromPath(self.root, "MainPanel/"..k)
        CsbTools.getChildFromPath(obj, "AllButton/RedTipPoint"):setVisible(false)
        CsbTools.initButton(obj, handler(self, self.funcBtnCallBack)
            , CommonHelper.getUIString(v.lang), "AllButton/ButtonPanel/NameLabel", "AllButton")
        local act = cc.CSLoader:createTimeline(ResConfig.UIChatSetting.Csb2.allBtn)
        obj:runAction(act)

        if "LvButton" == k then
            self.firstBtn = obj
        end
    end

    self.panelZOrder = CsbTools.getChildFromPath(self.root, "MainPanel/SettingPanel"):getLocalZOrder()
    -- 设置显示
    self:initDisplaySetPanel()
    -- 设置等级
    self:initLvSetPanel()
end

function UIChatSetting:initLvSetPanel()
    self.lvSetting = CsbTools.getChildFromPath(self.root, "MainPanel/SettingPanel/LvSetting")
    CsbTools.initButton(CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/BackButton")
        , function() UIManager.close() end, CommonHelper.getUIString(UILanguage.cancel)
        , "BackButton/Text", "Text", "Text")
    CsbTools.initButton(CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/ConfrimButton")
        , handler(self, self.lvSetCallBack), CommonHelper.getUIString(UILanguage.confrim)
        , "ConfrimButton/Text", "Text", "Text")
    -- 限制等级lb
    self.limitLvLb = CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/LvNumText")
    self.limitLv = ChatHelper.getLimitLv()
    self.limitLvLb:setString(self.limitLv)
    -- "+-"回调
    CsbTools.initButton(CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/AddButton"), handler(self, self.changeLvCallBack))
    CsbTools.initButton(CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/DelButton"), handler(self, self.changeLvCallBack))
    -- 语言包文本
    CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/TitleText"):setString(CommonHelper.getUIString(UILanguage.setCondition))
    CsbTools.getChildFromPath(self.lvSetting, "GuildPanel/TipsText"):setString(CommonHelper.getUIString(UILanguage.setLvTips))
end

function UIChatSetting:initDisplaySetPanel()
    self.disSetting = CsbTools.getChildFromPath(self.root, "MainPanel/SettingPanel/DisSetting")
    CsbTools.initButton(CsbTools.getChildFromPath(self.disSetting, "GuildPanel/BackButton")
        , function() UIManager.close() end, CommonHelper.getUIString(UILanguage.cancel)
        , "BackButton/Text", "Text", "Text")
    CsbTools.initButton(CsbTools.getChildFromPath(self.disSetting, "GuildPanel/ConfrimButton")
        , handler(self, self.diaplaySetCallBack), CommonHelper.getUIString(UILanguage.confrim)
        , "ConfrimButton/Text", "Text", "Text")
    -- 复选框
    self.worldCheckBox = CsbTools.getChildFromPath(self.disSetting, "GuildPanel/CheckBox_1")
    self.unionCheckBox = CsbTools.getChildFromPath(self.disSetting, "GuildPanel/CheckBox_2")

    CsbTools.initButton(self.worldCheckBox)
    CsbTools.initButton(self.unionCheckBox)

    self.chatMode = ChatHelper.getChatMode() -- 世界模式*10+公会模式
    self.worldCheckBox:setSelected(math.floor(self.chatMode/10) == 1)
    self.unionCheckBox:setSelected(math.floor(self.chatMode%10) == 1)
    
    -- 语言包文本
    CsbTools.getChildFromPath(self.disSetting, "GuildPanel/TitleText"):setString(CommonHelper.getUIString(UILanguage.showCondition))
    CsbTools.getChildFromPath(self.disSetting, "GuildPanel/TipsText"):setString(CommonHelper.getUIString(UILanguage.showTips))
    CsbTools.getChildFromPath(self.disSetting, "GuildPanel/WorldText"):setString(CommonHelper.getUIString(UILanguage.worldMode))
    CsbTools.getChildFromPath(self.disSetting, "GuildPanel/GuildText"):setString(CommonHelper.getUIString(UILanguage.unionMode))
end

function UIChatSetting:funcBtnCallBack(obj)
    if "DisButton" == obj:getName() then
        self.lvSetting:setVisible(false)
        self.disSetting:setVisible(true)
    else
        self.lvSetting:setVisible(true)
        self.disSetting:setVisible(false)
    end

    if self.preBtn == obj then
        return
    end

    if self.preBtn then
        self.preBtn:setLocalZOrder(self.panelZOrder - 1)
        --CommonHelper.playCsbAnimation(self.preBtn, "Normal", false, nil)
        CommonHelper.playCsbAnimate(self.preBtn, tabBtnFile, "Normal", false, nil, true)
    end

    self.preBtn = obj
    obj:setLocalZOrder(self.panelZOrder + 1)
    --CommonHelper.playCsbAnimation(obj, "On", false, nil)
    CommonHelper.playCsbAnimate(self.preBtn, tabBtnFile, "On", false, nil, true)
end

function UIChatSetting:diaplaySetCallBack(obj)
    obj.soundId = nil
    if not self.worldCheckBox:isSelected() and not self.unionCheckBox:isSelected() then
        CsbTools.createDefaultTip(CommonHelper.getUIString(UILanguage.chooseModeTips)):addTo(self)
        obj.soundId = MusicManager.commonSound.fail
        return
    end

    self.chatMode = (self.worldCheckBox:isSelected() and 10 or 0)
        + (self.unionCheckBox:isSelected() and 1 or 0)
    ChatHelper.setChatMode(self.chatMode)
    UIManager.close()
end

function UIChatSetting:lvSetCallBack(obj)
    ChatHelper.setLimitLv(self.limitLv)
    UIManager.close()
end

function UIChatSetting:changeLvCallBack(obj)
    if "AddButton" == obj:getName() then
        if self.limitLv >= getUserMaxLevel() then
            return
        end

        self.limitLv = self.limitLv + 1
    else
        if self.limitLv <= MIN_LV_LIMIT then
            return
        end

        self.limitLv = self.limitLv - 1
    end

    self.limitLvLb:setString(self.limitLv)
end

return UIChatSetting