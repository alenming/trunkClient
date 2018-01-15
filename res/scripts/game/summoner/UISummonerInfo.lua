--------------------------------------------------
--名称:UISummonerInfo
--简介:召唤师信息
--日期:20151105
--作者:Azure
--------------------------------------------------
local AnimationClick = require("game.comm.AnimationClick")
local UISummonerInfo = class("UISummonerInfo", function()
    return require("common.UIView").new()
end)

--构造函数
function UISummonerInfo:ctor()
    self.animationClick = AnimationClick.new()
end

--初始化
function UISummonerInfo:init()
    --加载界面
    self.rootPath = ResConfig.UISummonerInfo.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    
    -- 屏蔽层
    self.MaskPanel = CommonHelper.getChild(self.root, "MaskPanel")

    self.mainPanel = CommonHelper.getChild(self.root, "MainPanel")
    self.introPanel = CommonHelper.getChild(self.mainPanel, "IntroPanel")

    self.summonerName = CommonHelper.getChild(self.introPanel, "Name")
    self.summonerStory = CommonHelper.getChild(self.introPanel, "Story")
    CommonHelper.getChild(self.introPanel, "Identity"):setVisible(false)
    CommonHelper.getChild(self.introPanel, "SkillIntro"):setVisible(false)

    --返回事件
    local backBtn = CommonHelper.getChild(self.root, "BackButton")
    CsbTools.initButton(backBtn, function()
        UIManager.close()
    end)

    --向左事件
    local leftBtn = CommonHelper.getChild(self.root, "LeftButton")
    leftBtn:addTouchEventListener(function(obj, event)
        if event == 0 then
            if obj.soundId then
                MusicManager.playSoundEffect(obj.soundId)
            else
                MusicManager.playSoundEffect(obj:getName())
            end

            self.MaskPanel:setVisible(true)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
                self.MaskPanel:setVisible(false)
            end)))

            if self.index <= 1 then
                self.index = self.index + #self.sumData
            end
            self.index = self.index - 1
            self:setSummonerData()
        end
    end)

    --向右事件
    local rightBtn = CommonHelper.getChild(self.root, "RightButton")
    rightBtn:addTouchEventListener(function(obj, event)
        if event == 0 then
            if obj.soundId then
                MusicManager.playSoundEffect(obj.soundId)
            else
                MusicManager.playSoundEffect(obj:getName())
            end

            self.MaskPanel:setVisible(true)
            self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
                self.MaskPanel:setVisible(false)
            end)))

            if self.index >= #self.sumData then
                self.index = self.index - #self.sumData
            end
            self.index = self.index + 1
            self:setSummonerData()
        end
    end)

    --故事事件
    local storyBtn = CommonHelper.getChild(self.mainPanel, "StoryButton")
    CsbTools.initButton(storyBtn, function(obj)
        self.MaskPanel:setVisible(true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()self.MaskPanel:setVisible(false)end)))
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(11)) end , nil, nil, "ButtomName")
    CommonHelper.getChild(storyBtn, "ButtomName"):setString(getUILanConfItem(588))

    -- 获取提示
    self.getTips = CommonHelper.getChild(self.mainPanel, "GetTips")

    --购买事件
    self.buyBtn =  CommonHelper.getChild(self.mainPanel, "BuyButton/BuyButton")
    self.goldNum = CommonHelper.getChild(self.buyBtn, "Node/ButtonName")
    CsbTools.initButton(self.buyBtn, function(obj)
        self.MaskPanel:setVisible(true)

        CommonHelper.checkConsumeCallback(2, self.confSum.Num, function ()
            UIManager.open(UIManager.UI.UISummonerBuyTips, self.curSum.sumID, handler(self, self.buyCallback))
        end)
    end, nil, nil , "Node")

    -- 上阵按钮
    self.gotoButton = CommonHelper.getChild(self.mainPanel, "GotoButton")
    CsbTools.initButton(self.gotoButton, function(obj)
        self.MaskPanel:setVisible(true)
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.CallFunc:create(function()
            self.MaskPanel:setVisible(false)
        end)))

        self.teamSummonerId = self.curSum.sumID
        self:setSummonerData()
        TeamHelper.setTeamSummoner(self.teamSummonerId)
        EventManager:raiseEvent(GameEvents.EventUpdateTeam)

        local name = getHSLanConfItem(self.confHero.Common.Name)
        CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(2062), name))
    end, nil, nil, "ButtomName")

    --技能事件
    CommonHelper.getChild(self.introPanel, "Gift"):setString(getUILanConfItem(174))
    CommonHelper.getChild(self.introPanel, "Skill"):setString(getUILanConfItem(505))
    self.summonerSkill = {}
    for i = 1, 4 do
        local skill = {}
        skill.skillBtn = CommonHelper.getChild(self.introPanel, "SkillButton_" .. i)
        skill.image = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/SkillImage")
        skill.Name  = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillNameLabel")
        skill.infoLabel = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillInfoLabel")
        --infoLabel:setVisible(false)
        skill.Cd = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/CoolingTime")
        CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillAttackLabel"):setVisible(false)

        local skillItem = CommonHelper.getChild(skill.skillBtn, "SkillItem")
        CommonHelper.getChild(skillItem, "SkillItem"):setSwallowTouches(false)
        local skillTip = CommonHelper.getChild(skillItem, "SkillItem/TipPanel")
        skillTip:setSwallowTouches(false)
        skillTip:setAnchorPoint(cc.p(0, 0))
        skillTip:setPosition(cc.p(0, 85))

        self.summonerSkill[i] = skill
        skill.skillBtn:addTouchEventListener(function(obj, event)
            if 0 == event then
                CommonHelper.playCsbAnimate(skillItem, ResConfig.UISummonerList.Csb2.item, "On", false)
            elseif 2 == event or 3 == event then
                CommonHelper.playCsbAnimate(skillItem, ResConfig.UISummonerList.Csb2.item, "Normal", false)
            end
        end)
    end

    -- 召唤师点击
    local summonerPanel = CommonHelper.getChild(self.mainPanel, "SummonerPanel")
    summonerPanel:addClickEventListener(function()
        if self.animationClick then
            self.animationClick:playRandomAnimation()
        end
    end)
    self.summonerNode = CommonHelper.getChild(self.mainPanel, "SummonerPanel/SummonerNode")
end

-- 打开
function UISummonerInfo:onOpen(_, sumData, index, callback)
    self.MaskPanel:setVisible(false)

    self.sumData    = sumData
    self.index      = index
    self.callback   = callback

    self.teamSummonerId = TeamHelper.getTeamInfo()

    self:setSummonerData()
    -- 查看召唤师去掉红点
    RedPointHelper.addCount(RedPointHelper.System.Summoner, nil, self.curSum.sumID)
end

-- 关闭
function UISummonerInfo:onClose()
    self.sumData = nil
    self.index = nil
    self.callback = nil

    if self.summonerNode then
        self.summonerNode:removeAllChildren()
    end
    if self.animationClick then
        self.animationClick:setAnimationNode(nil)
    end
end

function UISummonerInfo:onTop(pre, ...)
    self.MaskPanel:setVisible(false)
end

-- 召唤师信息
function UISummonerInfo:setSummonerData()
    self.curSum = self.sumData[self.index]
    self.confSum = getSaleSummonerConfItem(self.curSum.sumID)
    self.confHero = getHeroConfItem(self.curSum.sumID)
    -- 播放该召唤师声音
    MusicManager.playSoundEffect(self.curSum.sumID)
    --
    if self.confHero and self.confHero.Common and self.confHero.PlayerSkill then
        -- 名称、故事
        self.summonerName:setString(getHSLanConfItem(self.confHero.Common.Name))
        self.summonerStory:setString(getHSLanConfItem(self.confHero.Common.Desc))
        -- 已经购买
        if self.curSum and self.curSum.isBuy then
            self.buyBtn:setVisible(false)
            self.getTips:setVisible(false)
            -- 已经上阵
            local text = CommonHelper.getChild(self.gotoButton, "ButtomName")
            if self.teamSummonerId == self.curSum.sumID then
                text:setString(getUILanConfItem(2061))
                --text:enableOutline(cc.c4b(127, 127, 127, 255), 2)
                self.gotoButton:setTouchEnabled(false)
                self.gotoButton:setBright(false)
            else
                text:setString(getUILanConfItem(2060))
               -- text:enableOutline(cc.c4b(17, 104, 0, 255), 2)
                self.gotoButton:setTouchEnabled(true)
                self.gotoButton:setBright(true)
            end
            self.gotoButton:setVisible(true)
        else
            self.gotoButton:setVisible(false)
            --
            if self.confSum then
                if self.confSum.Type == 1 then
                    self.buyBtn:setVisible(true)
                    self.getTips:setVisible(false)
                    self.goldNum:setString(self.confSum.Num)
                    if self.confSum.Num <= getGameModel():getUserModel():getDiamond() then
                        self.goldNum:setColor(cc.c3b(255, 255, 255))
                    else
                        self.goldNum:setColor(cc.c3b(178, 0, 0))
                    end
                elseif self.confSum.Type == 2 then
                    self.buyBtn:setVisible(false)
                    self.getTips:setVisible(true)
                    self.getTips:setString(getUILanConfItem(self.confSum.Num))
                end
            end
        end
        -- 技能
        for i, skill in pairs(self.summonerSkill) do
            local skillID = i == 4 and self.confHero.Common.Skill[1] or self.confHero.PlayerSkill[i]
            skill.skillBtn:setVisible(skillID ~= nil)
            local confSkill = getSkillConfItem(skillID)
            if confSkill then
                CsbTools.replaceImg(skill.image, confSkill.IconName)
                skill.Name:setString(getHSSkillLanConfItem(confSkill.Name))
                skill.infoLabel:setString(getHSSkillLanConfItem(confSkill.Desc))
                skill.Cd:setString(confSkill.CostDesc1~=0 and getHSSkillLanConfItem(confSkill.CostDesc1) or "")
            else
                print("error skillConf is nil", skillID)
            end
        end
        -- 模型动画
        self.animationClick:setAnimationResID(self.confHero.Common.AnimationID)
        AnimatePool.createAnimate(self.confHero.Common.AnimationID, function(animation)
            if animation then
                if self.summonerNode then
                    self.summonerNode:removeAllChildren()
                    self.summonerNode:addChild(animation)
                end
                if self.animationClick then
                    self.animationClick:setAnimationNode(animation)
                end
            end
        end)
    end
end

-- 召唤师购买成功回调
function UISummonerInfo:buyCallback()
    self.curSum.isBuy = true
    self:setSummonerData()

    if self.callback and "function" == type(self.callback) then
        self.callback()
    end
end

return UISummonerInfo