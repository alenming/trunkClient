--[[
英雄试炼具体的试炼(选择难度)界面
]]

local UIHeroTestDifficulty = class("UIHeroTestDifficulty", function()
    return require("common.UIView").new()
end)

local HeroTestUILanguage = {RaceAddition = 1006, Difficult = 1030, RemainCount = 1031, NoEnoughLv = 1000, NoEnoughCount = 1002}
local Vocation = {Soldier = 1, Assassin = 2, Shoot = 3, Magic = 4, Support = 5}
-- 1、ID条件 2、角色类型 3、星级条件 4、水晶条件 5、种族 6、性别 7、职业 8、攻击方式
local AdditionObj = {RoleID = 1, RoleType = 2, StarLv = 3, Crystal = 4, Race = 5, Sex = 6, Vocation = 7, Attack = 8} --加成对象
local VocationLanguage = {521, 524, 522, 523, 525, 520} -- Vocation 
local DifficultLvImage = {"herotrial_diffcult_I.png", "herotrial_diffcult_II.png"
        , "herotrial_diffcult_III.png", "herotrial_diffcult_IV.png", "herotrial_diffcult_V.png"}

-- 通过加成ID查找加成表中哪个职业加成和加成属性
local function getOutBonusAdditionInfo(bonusID)
    local additionInfo = {vocation = 0, enhaces = {}}
    local outBonusItem = getConfOutterBonusItem(bonusID)
    if outBonusItem then
        for _, enhaceConditions in pairs(outBonusItem.EnhanceConditions) do
            if enhaceConditions.Type == AdditionObj.Vocation and #enhaceConditions.Param > 0 then
               additionInfo.vocation = enhaceConditions.Param[1]
               break
            end
        end

        -- 转换为相应的文本
        for _, enhaces in pairs(outBonusItem.Enhances) do
            table.insert(additionInfo.enhaces
                , string.format(getUILanConfItem(enhaces.EffectLanID), enhaces.Param))
        end
    end

    return additionInfo
end

function UIHeroTestDifficulty:ctor()
end

function UIHeroTestDifficulty:init()
    self.rootPath = ResConfig.UIHeroTestDifficulty.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    CsbTools.initButton(back, function()
        UIManager.close()
    end)

    self.challengeCount = 0

    local view = getChild(self.root, "MainPanel/DifulcultScrollView")
    view:setScrollBarEnabled(false)
    for j = 1, #DifficultLvImage do
        local btn = getChild(view, "DiffcultBar_" .. j)
        btn:setTag(j)
        CsbTools.initButton(btn, handler(self, self.touchDifficultBar))

        -- 图标+难度文字一样
        local bar = getChild(view, "DiffcultBar_" .. j .. "/DiffcultBar")
        local icon = getChild(bar, "MainPanel/DiffcultLvIcon")
        getChild(icon, "DiffcultLvIcon/DiffcultLv"):setString(string.format(getUILanConfItem(HeroTestUILanguage.Difficult), j))
        getChild(icon, "DiffcultLvIcon/LvImage"):loadTexture(DifficultLvImage[j], 1)
    end
end

function UIHeroTestDifficulty:onOpen(fromUIID, heroTestID)
    print("fromUIID: ", fromUIID, "heroTestID: ", heroTestID)
    self.id = heroTestID
    local conf = getHeroTestConfItem(heroTestID)
    if not conf then
        print("getHeroTestConfItem is nil!", heroTestID)
        return 
    end

    local outBonusItem = getConfOutterBonusItem(conf.Occupation)
    if not outBonusItem then
        print("getConfOutterBonusItem is nil!", conf.Occupation)
        return
    end
    
    self.challengeCount = getGameModel():getHeroTestModel():getHeroTestCount(self.id)

    local view = getChild(self.root, "MainPanel/DifulcultScrollView")
    local place = getChild(view, "HeroTrialPlace/TrialBar")
    getChild(place, "MainPanel/NameText"):setString(getUILanConfItem(conf.Desc))
    getChild(place, "MainPanel/RedTipPoint"):setVisible(false)
    getChild(place, "MainPanel/HeroImage"):loadTexture(conf.Pic, 1)
    getChild(place, "MainPanel/TipText"):setString(
        getUILanConfItem(HeroTestUILanguage.RemainCount)..(conf.Times - self.challengeCount)) -- 今日剩余挑战次数
    
    local additionInfo = getOutBonusAdditionInfo(conf.Occupation)
    
    -- XX系英雄加成
    local additionDesc = string.format(getUILanConfItem(HeroTestUILanguage.RaceAddition)
            , getUILanConfItem(VocationLanguage[additionInfo.vocation]))

    local userLv = getGameModel():getUserModel():getUserLevel()
    for j = 1, #conf.Diff do
        local bar = getChild(view, "DiffcultBar_" .. j .. "/DiffcultBar")
        getChild(bar, "MainPanel/TipAdd"):setString(additionDesc)
        getChild(bar, "MainPanel/TipLv"):setString(tostring(conf.Diff[j].UnlockLevel or 1))
        -- 属性加成
        self:additionInfo(bar, additionInfo.enhaces)

        local b = (userLv < conf.Diff[j].UnlockLevel)
        getChild(bar, "MainPanel/TipLv"):setColor(b and cc.c3b(255,0,0) or cc.c3b(0,255,0))
        if b then
            CommonHelper.playCsbAnimate(getChild(bar, "MainPanel/DiffcultLvIcon")
                    , ResConfig.UIHeroTestDifficulty.Csb2.diffcultLvIcon, "UnOpen", false)
        else
            CommonHelper.playCsbAnimate(bar, ResConfig.UIHeroTestDifficulty.Csb2.bar, "Light", false)
        end

        getChild(bar, "MainPanel/RedTipPoint"):setVisible(not b)
    end
end

function UIHeroTestDifficulty:additionInfo(bar, enhaces)
    getChild(bar, "MainPanel/Blood"):setVisible(false)
    getChild(bar, "MainPanel/Attack"):setVisible(false)
    getChild(bar, "MainPanel/Magic"):setVisible(false)
    
    local n = 1
    for _, text in pairs(enhaces) do
        if 1 == n then
            getChild(bar, "MainPanel/Blood"):setVisible(true)
            getChild(bar, "MainPanel/Blood"):setString(text)
        elseif 2 == n then
            getChild(bar, "MainPanel/Attack"):setVisible(true)
            getChild(bar, "MainPanel/Attack"):setString(text)
        else
            getChild(bar, "MainPanel/Magic"):setVisible(true)
            getChild(bar, "MainPanel/Magic"):setString(text)  
        end
    
        n = n + 1
    end
end

function UIHeroTestDifficulty:touchDifficultBar(obj)
    print("touch difficult bar:", obj:getTag())
    obj.soundId = nil
    obj:setTouchEnabled(false)
    local conf = getHeroTestConfItem(self.id)
    local lv = getGameModel():getUserModel():getUserLevel()
    if lv < getHeroTestConfItem(self.id).Diff[obj:getTag()].UnlockLevel then
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(HeroTestUILanguage.NoEnoughLv)):addTo(self)
    elseif conf.Times - self.challengeCount <= 0 then
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(HeroTestUILanguage.NoEnoughCount)):addTo(self)
    else
        CommonHelper.playCsbAnimate(getChild(obj, "DiffcultBar"), ResConfig.UIHeroTestDifficulty.Csb2.bar, "On", false, function ()
            UIManager.open(UIManager.UI.UIHeroTestInfo, self.id, obj:getTag())
            obj:setTouchEnabled(true)
        end)
    end
end

return UIHeroTestDifficulty
