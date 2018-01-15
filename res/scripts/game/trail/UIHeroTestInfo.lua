--[[
英雄试炼规则和boss介绍界面
]]

require("game.comm.UIAwardHelper")

local UIHeroTestInfo = class("UIHeroTestInfo", function()
    return require("common.UIView").new()
end)

local PropTips = require("game.comm.PropTips")

local UILanguage = {BeginBattle = 88, RuleIntroduce = 1032, PassReward = 1033
    , BossIntroduce = 1034, FinishedChallenge = 1002, Rule = 1018}

function UIHeroTestInfo:ctor()
end

function UIHeroTestInfo:init()
    self.rootPath = ResConfig.UIHeroTestInfo.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    CsbTools.initButton(back, function()
        UIManager.close()
    end)

    CsbTools.initButton(getChild(self.root, "MainPanel/ChallengeButton"), handler(self, self.fightHeroTest)
        , CommonHelper.getUIString(UILanguage.BeginBattle), "Button_Orange/ButtomName", "Button_Orange")

    getChild(self.root, "MainPanel/RuleText"):setString(getUILanConfItem(UILanguage.RuleIntroduce))
    getChild(self.root, "MainPanel/AwradText"):setString(getUILanConfItem(UILanguage.PassReward))
    getChild(self.root, "MainPanel/RuleIntroText"):setString(getUILanConfItem(UILanguage.Rule))
end

function UIHeroTestInfo:onOpen(fromUIID, id, lv)
    -- 道具点击提示
    self.propTips = PropTips.new()

    self.id = id
    self.lv = lv
    local conf = getHeroTestConfItem(id)
    if not conf then
        return
    end

    local boss = getBossConfItem(getStageConfItem(conf.Diff[lv].DiffID).Boss)
    print("UIHeroTestInfo:Boss:", boss.Common.ClassID, boss.Common.HeadIcon)
    getChild(self.root, "MainPanel/BossImage"):loadTexture(boss.Common.HeadIcon, 1)
    getChild(self.root, "MainPanel/BossText"):setString(getBMCLanConfItem(boss.Common.Name)) 
    getChild(self.root, "MainPanel/BossIntroText"):setString(getBMCLanConfItem(boss.Common.Desc))

    for i = 1, 3 do
        local award = getChild(self.root, "MainPanel/AwardItem_" .. i)
        local k = conf.Diff[lv].Pick[i]
        if k then
            UIAwardHelper.setAllItemOfConf(award, getPropConfItem(k), 0)
        else
            award:setVisible(false)
        end
    end

    for i=1, 3 do
        local confID = conf.Diff[lv].Pick[i]
        if confID ~= nil then
            local propConf = getPropConfItem(confID)
            if propConf then
                local touchNode = getChild(self.root, "MainPanel/AwardItem_" .. i .. "/MainPanel")
                self.propTips:addPropTips(touchNode, propConf)
            end
        end
    end
end

function UIHeroTestInfo:onClose()
    self.propTips:removePropAllTips()
    self.propTips = nil
end

function UIHeroTestInfo:fightHeroTest(obj)
    UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
        BattleHelper.requestHeroTest(summonerId, heroIds, self.id, self.lv, mercenaryId)
    end)
end

return UIHeroTestInfo
