--[[
    玩家信息设置界面
1、(改名字、换头像、声音等等)设置查看
]]

local userModel = getGameModel():getUserModel()
local unionModel = getGameModel():getUnionModel()

local UIUserSetting = class("UIUserSetting", function ()
	return require("common.UIView").new()
end)

local UserDefaultData = { MusicSwitch = "Music_Switch", SoundSwitch = "Sound_Switch" }
local LimitLv = 15

function UIUserSetting:ctor()
end

function UIUserSetting:onTop(preUIID, ...)
    if preUIID == UIManager.UI.UIHeadSetting then
        self.redPoint:setVisible(false)
    end
end

function UIUserSetting:init()
    self.rootPath = ResConfig.UIUserSetting.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- ui文本
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Sever"):setString(CommonHelper.getUIString(1646))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Lv"):setString(CommonHelper.getUIString(1647))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Exp"):setString(CommonHelper.getUIString(1648))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Club"):setString(CommonHelper.getUIString(1649))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/HeroLv"):setString(CommonHelper.getUIString(1650))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Sound"):setString(CommonHelper.getUIString(1651))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/Music"):setString(CommonHelper.getUIString(1652))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/VipTips"):setString(CommonHelper.getUIString(1717))

    -- 按钮文本
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/ChangeHeadButton/ButtonName"):setString(CommonHelper.getUIString(35))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/TeamButton/ButtonName"):setString(CommonHelper.getUIString(1667))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/PushButton/ButtonName"):setString(CommonHelper.getUIString(37))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/PackageButton/ButtonName"):setString(CommonHelper.getUIString(38))
    CsbTools.getChildFromPath(self.root, "InfoSetPanel/HelpButton/ButtonName"):setString(CommonHelper.getUIString(1668))

    -- 服务器名称
    local serverConfig = ServerConfig[gServerID]
    if serverConfig then
        CsbTools.getChildFromPath(self.root, "InfoSetPanel/SeverName"):setString(serverConfig.Name)
    end
    -- 头像、名称、ID、等级、经验、公会、英雄等级上限、月卡剩余天数
    self.heroImage  = CsbTools.getChildFromPath(self.root, "InfoSetPanel/HeroImage")
    self.nameLabel  = CsbTools.getChildFromPath(self.root, "InfoSetPanel/UName")
    self.idLable    = CsbTools.getChildFromPath(self.root, "InfoSetPanel/IDLabel")
    self.levelLabel = CsbTools.getChildFromPath(self.root, "InfoSetPanel/LvLabel")
    self.experLable = CsbTools.getChildFromPath(self.root, "InfoSetPanel/ExpLabel")
    self.experBar   = CsbTools.getChildFromPath(self.root, "InfoSetPanel/ExpLoadingBar")
    self.clubLabel  = CsbTools.getChildFromPath(self.root, "InfoSetPanel/ClubLabel")
    self.heroLvLb   = CsbTools.getChildFromPath(self.root, "InfoSetPanel/LvNum")
    self.redPoint   = CsbTools.getChildFromPath(self.root, "InfoSetPanel/ChangeHeadButton/RedTipPoint")
    self.vipDays    = CsbTools.getChildFromPath(self.root, "InfoSetPanel/VipDays")
    self.tencentLogo = CsbTools.getChildFromPath(self.root, "InfoSetPanel/TencentLogo")

	-- 关闭按钮
    local btnClose = CsbTools.getChildFromPath(self.root, "InfoSetPanel/CloseButton")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 更换头像按钮
    local btnChangeHead = CsbTools.getChildFromPath(self.root, "InfoSetPanel/ChangeHeadButton")
    CsbTools.initButton(btnChangeHead, handler(self, self.onClick), nil, nil, "ButtonName")
    -- 修改名称按钮
    local btnWritName = CsbTools.getChildFromPath(self.root, "InfoSetPanel/Button_WritName")
    CsbTools.initButton(btnWritName, handler(self, self.onClick))
    -- 队伍设置按钮
    local btnSetting = CsbTools.getChildFromPath(self.root, "InfoSetPanel/TeamButton")
    CsbTools.initButton(btnSetting, handler(self, self.onClick))
    -- 推送设置按钮
    local btnPush = CsbTools.getChildFromPath(self.root, "InfoSetPanel/PushButton")
    CsbTools.initButton(btnPush, handler(self, self.onClick))
    btnPush:setVisible(device.platform ~= "windows")
    -- 礼包兑换按钮
    local btnPackage = CsbTools.getChildFromPath(self.root, "InfoSetPanel/PackageButton")
    CsbTools.initButton(btnPackage, handler(self, self.onClick))
    -- 帮助中心按钮
    local btnHelp = CsbTools.getChildFromPath(self.root, "InfoSetPanel/HelpButton")
    CsbTools.initButton(btnHelp, handler(self, self.onClick))

    -- 音效按钮
    local btnMusic = CsbTools.getChildFromPath(self.root, "InfoSetPanel/MusicButton")
    CsbTools.initButton(btnMusic, handler(self, self.onClick))
    -- 音效状态
    local MusicNode = CsbTools.getChildFromPath(btnMusic, "SoundSwitch")
    if cc.UserDefault:getInstance():getBoolForKey(UserDefaultData.MusicSwitch, true) then
        CommonHelper.playCsbAnimate(MusicNode, ResConfig.UIUserSetting.Csb2.SoundSwitch, "CloseToOpen", false)
    else
        CommonHelper.playCsbAnimate(MusicNode, ResConfig.UIUserSetting.Csb2.SoundSwitch, "OpenToClose", false)
    end
    -- 音乐按钮
    local btnSound = CsbTools.getChildFromPath(self.root, "InfoSetPanel/SoundButton")
    CsbTools.initButton(btnSound, handler(self, self.onClick))
    -- 音乐状态
    local SoundNode = CsbTools.getChildFromPath(btnSound, "SoundSwitch")
    if cc.UserDefault:getInstance():getBoolForKey(UserDefaultData.SoundSwitch, true) then
        CommonHelper.playCsbAnimate(SoundNode, ResConfig.UIUserSetting.Csb2.SoundSwitch, "CloseToOpen", false)
    else
        CommonHelper.playCsbAnimate(SoundNode, ResConfig.UIUserSetting.Csb2.SoundSwitch, "OpenToClose", false)
    end
end

function UIUserSetting:onOpen(openerUIID, ...)
    self.UserInfo = {}
    self.UserInfo.headIconID = userModel:getHeadID() -- 头像
    self.UserInfo.touchHeadIconID = self.UserInfo.headIconID
	self.UserInfo.changeNameFree = userModel:getChangeNameFree() -- 0免费
    self.UserInfo.userLv = userModel:getUserLevel()

    self.userLevelConfItem = getUserLevelSettingConfItem(userModel:getUserLevel())
    if nil == self.userLevelConfItem then
        print("Error: UIUserSetting:onOpen, self.userLevelConfItem==nil, userLv", userModel:getUserLevel())
        return
    end

    self.HeadIconItem = getSystemHeadIconItem()
    if nil == self.HeadIconItem then
        print("Error: UIUserSetting:onOpen, self.HeadIconItem==nil")
        return
    end
    -- 蓝钻显示
    CommonHelper.showBlueDiamond(self.tencentLogo, nil, nil, self.nameLabel)
    self:showRedPoint()
    self.heroImage:loadTexture(self.HeadIconItem[userModel:getHeadID()].IconName, 1)
    self.nameLabel:setString(userModel:getUserName())
    self.idLable:setString(userModel:getUserID())
    self.levelLabel:setString(userModel:getUserLevel())
    self.experLable:setString(userModel:getUserExp() .. "/" .. self.userLevelConfItem.Exp)
    self.experBar:setPercent(userModel:getUserExp() / self.userLevelConfItem.Exp * 100)
    self.clubLabel:setString(unionModel:getUnionName())
    self.heroLvLb:setString(userModel:getUserLevel() <= LimitLv and LimitLv or userModel:getUserLevel())
    -- 月卡剩余天数
    local days = math.ceil((getGameModel():getUserModel():getMonthCardStamp() - getGameModel():getNow())/86400)
    if days < 0 then
	    days = 0
    end
    self.vipDays:setString(days)
end

function UIUserSetting:onClose()

end

function UIUserSetting:onClick(obj)
    local name = obj:getName()
    if "CloseButton" == name then
        UIManager.close()
    elseif "ChangeHeadButton" == name then
        UIManager.open(UIManager.UI.UIHeadSetting, handler(self, self.setUserHead))
    elseif "Button_WritName" == name then
        UIManager.open(UIManager.UI.UINameSetting, handler(self, self.setUserName))
    elseif "TeamButton" == name then
        UIManager.open(UIManager.UI.UITeam, function ()
            EventManager:raiseEvent(GameEvents.EventUpdateTeam)
        end, 3)
    elseif "PushButton" == name then
        UIManager.open(UIManager.UI.UIPushSetPanel)
    elseif "PackageButton" == name then
        UIManager.open(UIManager.UI.UIPackageRedeem)
    elseif "HelpButton" == name then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(11))
    elseif "MusicButton" == name then
        local node = CsbTools.getChildFromPath(obj, "SoundSwitch")
        local b = cc.UserDefault:getInstance():getBoolForKey(UserDefaultData.MusicSwitch, true)
        if b then
            CommonHelper.playCsbAnimate(node, ResConfig.UIUserSetting.Csb2.SoundSwitch, "OpenToClose", false)
        else
            CommonHelper.playCsbAnimate(node, ResConfig.UIUserSetting.Csb2.SoundSwitch, "CloseToOpen", false)
        end

        MusicManager.setOpenMusic(not b)
        cc.UserDefault:getInstance():setBoolForKey(UserDefaultData.MusicSwitch, not b)
    elseif "SoundButton" == name then
        local node = CsbTools.getChildFromPath(obj, "SoundSwitch")
        local b = cc.UserDefault:getInstance():getBoolForKey(UserDefaultData.SoundSwitch, true)
        if b then
            CommonHelper.playCsbAnimate(node, ResConfig.UIUserSetting.Csb2.SoundSwitch, "OpenToClose", false)
        else
            CommonHelper.playCsbAnimate(node, ResConfig.UIUserSetting.Csb2.SoundSwitch, "CloseToOpen", false)
        end

        MusicManager.setOpenEffect(not b)
        cc.UserDefault:getInstance():setBoolForKey(UserDefaultData.SoundSwitch, not b)
    end
end

function UIUserSetting:setUserHead()
    self.heroImage:loadTexture(self.HeadIconItem[userModel:getHeadID()].IconName, 1)
end

function UIUserSetting:setUserName()
    self.nameLabel:setString(userModel:getUserName())
end

function UIUserSetting:showRedPoint()
    self.redPoint:setVisible(RedPointHelper.getSystemRedPoint(RedPointHelper.System.HeadUnlock))
end

return UIUserSetting