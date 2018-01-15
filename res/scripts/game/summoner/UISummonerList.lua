--------------------------------------------------
--名称:UISummonerList
--简介:召唤师列表
--日期:20160408
--作者:Azure
--------------------------------------------------
local UISummonerList = class("UISummonerList", function()
    return require("common.UIView").new()
end)

local CardButtonSound = "CardButton"

--构造函数
function UISummonerList:ctor()
    
end

--初始化
function UISummonerList:init()
    self.rootPath = ResConfig.UISummonerList.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 屏蔽层
    self.MaskPanel = CommonHelper.getChild(self.root, "MaskPanel")

    --关闭事件
    local close = CommonHelper.getChild(self.root, "MainPanel/BackButton")
    CsbTools.initButton(close, function()
        UIManager.close()
    end)

    -- 初始化背景层
    self:initBgPanel()
    -- 初始化信息层
    self:initInfoPanel()
    -- 初始化滚动层
    self:initRotatePanel()
end

--打开界面
function UISummonerList:onOpen()
    self.MaskPanel:setVisible(true)
    self.mIsRun = false
    self.heroTexture = nil
    self.heroImg = nil
    --
    --重置Z轴
    for i = 1, 40 do
        self.sumCard[i].cardPanel:setLocalZOrder(i)
    end

    self:initSummonerData()
    self:initRotateData()
    self:setSummonerNum()
    self:setRotatePanel()
    self:showCard()

    -- 解决滑动过程中退出界面导致的卡牌显示问题
    self:setMideCardState(false)
end

-- 每次界面Open动画播放完毕时回调
function UISummonerList:onOpenAniOver()
    -- self.bgPanel:setTouchEnabled(true)
    self.MaskPanel:setVisible(false)
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UISummonerList:onClose()
    if self.heroTexture then
        self.bgNode1:removeAllChildren()
        self.bgNode2:removeAllChildren()
        cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(self.heroTexture)
        cc.Director:getInstance():getTextureCache():removeUnusedTextures()
        self.heroTexture = nil
        self.heroImg = nil
    end
    -- 解决滑动过程中退出界面导致的卡牌显示问题
    self:setMideCardState(true)
    self.rotaPanel:setRotation(0)
end

-- 顶置界面
function UISummonerList:onTop(pre, ret)
    self.MaskPanel:setVisible(false)
end

-- 初始化背景层
function UISummonerList:initBgPanel()
    self.bgPanel = CommonHelper.getChild(self.root, "Background")
    self.bgNode1 = CommonHelper.getChild(self.bgPanel, "HeroBg1")
    self.bgNode1:removeAllChildren()
    self.bgNode2 = CommonHelper.getChild(self.bgPanel, "HeroBg2")
    self.bgNode2:removeAllChildren()

    self.leftButton  = CommonHelper.getChild(self.root, "MainPanel/LeftButton")
    self.rightButton = CommonHelper.getChild(self.root, "MainPanel/RightButton")

    self.leftButton:addTouchEventListener(handler(self, self.leftButtonCallBack))
    self.rightButton:addTouchEventListener(handler(self, self.rightButtonCallBack))

    -- 背景触摸事件
    local beginPos = nil
    local curPos = nil
    self.bgPanel:addTouchEventListener(function(obj, event)
        if event == 0 then
            beginPos = obj:getTouchBeganPosition()
            curPos = beginPos
            self:setMideCardState(true)
        elseif event == 1 then
            local movePos = obj:getTouchMovePosition()
            local delta = 81 * (movePos.x - curPos.x) / display.width
            self.rotateAngle = self.rotateAngle + delta
            self.rotaPanel:setRotation(self.rotateAngle)
            curPos = movePos
        elseif event == 2 or event == 3 then
            local endPos = obj:getTouchMovePosition()
            local dir = endPos.x - beginPos.x
            if dir > 0 then
                local delta = self.rotateAngle - math.floor(self.rotateAngle / 9) * 9
                if delta > 2 then
                    self.rotateAngle = math.ceil(self.rotateAngle / 9) * 9
                else
                    self.rotateAngle = math.floor(self.rotateAngle / 9) * 9
                end
            elseif dir < 0 then
                local delta = self.rotateAngle - math.ceil(self.rotateAngle / 9) * 9
                if delta < -2 then
                    self.rotateAngle = math.floor(self.rotateAngle / 9) * 9
                else
                    self.rotateAngle = math.ceil(self.rotateAngle / 9) * 9
                end
            end

            self.bgPanel:setTouchEnabled(false)
            local rotateTo = cc.RotateTo:create(0.2, math.mod(self.rotateAngle, 360))
            local callback = cc.CallFunc:create(function()
                local oldSumID = self.sumData[self.midSumCardIndex].sumID
                --
                self.midIndex = 5 - math.floor(self.rotateAngle / 9)  -- 正中间的节点ID
                if self.midIndex <= 0 then
                    self.midIndex = math.mod(self.midIndex, 40) + 40
                else
                    self.midIndex = math.mod(self.midIndex - 1, 40) + 1
                end
                self.midSumCardIndex  = self.sumIndex[self.midIndex]   -- 正中间的节点的数据ID

                local newSumID = self.sumData[self.midSumCardIndex].sumID
                if newSumID ~= oldSumID then
                    MusicManager.playSoundEffect(CardButtonSound)
                    self:showCard()
                end
                --
                self:setMideCardState(false)
                self.bgPanel:setTouchEnabled(true)
            end)
            self.rotaPanel:runAction(cc.Sequence:create(rotateTo, callback))
        end
    end)
end

function UISummonerList:rightButtonCallBack(obj, event)

    if self.mIsRun  then
        return
    end

    if event == 0 then
        self:setMideCardState(true)
        self.bgPanel:setTouchEnabled(false)
    elseif event == 1 then

    elseif event == 3 then
        self:setMideCardState(false)
    elseif event == 2 then
        self:setMideCardState(true)
        self.mIsRun = true
        local delta =  9 
        self.rotateAngle = self.rotateAngle + delta

        local rotateTo = cc.RotateTo:create(0.2,  math.mod(self.rotateAngle, 360))
        local callback = cc.CallFunc:create(function()
            local oldSumID = self.sumData[self.midSumCardIndex].sumID
            --
            self.midIndex = 5 - math.floor(self.rotateAngle / 9)  -- 正中间的节点ID
            if self.midIndex <= 0 then
                self.midIndex = math.mod(self.midIndex, 40) + 40
            else
                self.midIndex = math.mod(self.midIndex - 1, 40) + 1
            end
            self.midSumCardIndex  = self.sumIndex[self.midIndex]  -- 正中间的节点的数据ID

            local newSumID = self.sumData[self.midSumCardIndex].sumID
            if newSumID ~= oldSumID then
                MusicManager.playSoundEffect(CardButtonSound)
                self:showCard()
            end

            self:setMideCardState(false)
        end)

        self.rotaPanel:runAction(cc.Sequence:create(rotateTo, callback, cc.DelayTime:create(0.3), cc.CallFunc:create(function()
            self.bgPanel:setTouchEnabled(true)
            self.mIsRun = false
        end)))
    end
end

function UISummonerList:leftButtonCallBack(obj, event)
    if self.mIsRun  then
        return
    end
    if event == 0 then
        self:setMideCardState(true)
        self.bgPanel:setTouchEnabled(false)
    elseif event == 1 then

    elseif event == 3 then
        self:setMideCardState(false)
    elseif event == 2  then
        self:setMideCardState(true)
        self.mIsRun = true

        local delta = -9 
        self.rotateAngle = self.rotateAngle + delta
        self.rotaPanel:stopAllActions()
        
        local rotateTo = cc.RotateTo:create(0.2,  math.mod(self.rotateAngle, 360))
        local callback = cc.CallFunc:create(function()
            local oldSumID = self.sumData[self.midSumCardIndex].sumID
            --
            self.midIndex = 5 - math.floor(self.rotateAngle / 9)  -- 正中间的节点ID
            if self.midIndex <= 0 then
                self.midIndex = math.mod(self.midIndex, 40) + 40
            else
                self.midIndex = math.mod(self.midIndex - 1, 40) + 1
            end
            self.midSumCardIndex  = self.sumIndex[self.midIndex]   -- 正中间的节点的数据ID

            local newSumID = self.sumData[self.midSumCardIndex].sumID
            if newSumID ~= oldSumID then
                MusicManager.playSoundEffect(CardButtonSound)
                self:showCard()
            end

            self:setMideCardState(false)
        end)
        self.rotaPanel:runAction(cc.Sequence:create(rotateTo, callback, cc.DelayTime:create(0.3), cc.CallFunc:create(function()
                self.bgPanel:setTouchEnabled(true)
                self.mIsRun = false
        end)))
    end
end

-- 初始化信息层
function UISummonerList:initInfoPanel()
    self.Infopanel = CommonHelper.getChild(self.root, "MainPanel/Infopanel")
    self.summonerSkill = {}
    for i = 1, 3 do
        local skill = {}
        skill.skillBtn = CommonHelper.getChild(self.root, "MainPanel/Infopanel/SkillButton" .. i)
        skill.image = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/SkillImage")
        skill.Name  = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillNameLabel")
        skill.infoLabel = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillInfoLabel")
        skill.Cd = CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/CoolingTime")
        CommonHelper.getChild(skill.skillBtn, "SkillItem/SkillItem/TipPanel/SkillAttackLabel"):setVisible(false)
        
        local skillItem = CommonHelper.getChild(skill.skillBtn, "SkillItem")
        CommonHelper.getChild(skillItem, "SkillItem"):setSwallowTouches(false)
        local skillTip = CommonHelper.getChild(skillItem, "SkillItem/TipPanel")
        skillTip:setSwallowTouches(false)

        self.summonerSkill[i] = skill

        skill.skillBtn:addTouchEventListener(function(obj, event)
            if event == 0 then
                CommonHelper.playCsbAnimate(skillItem, ResConfig.UISummonerList.Csb2.item, "On", false)
            elseif event == 2 or event == 3 then
                CommonHelper.playCsbAnimate(skillItem, ResConfig.UISummonerList.Csb2.item, "Normal", false)
            end
        end)
    end
end

-- 初始化滚动层
function UISummonerList:initRotatePanel()
    self.rotaPanel  = CommonHelper.getChild(self.root, "MainPanel/RotaPanel")
    self.sumCard    = {}
    for i = 1, 40 do
        local card = {}
        card.id = i
        card.cardPanel = CommonHelper.getChild(self.rotaPanel, "RotePanel_" .. i)
        card.cardPanel:setLocalZOrder(i)
        card.localZorder = i
        card.cardPanel:setSwallowTouches(false)
        card.cardBtn   = CommonHelper.getChild(card.cardPanel, "CardButton")
        card.cardBtn:setSwallowTouches(false)
        card.cardNode  = CommonHelper.getChild(self.rotaPanel, "RotePanel_" .. i .. "/CardButton/SummonerCard")
        CommonHelper.getChild(card.cardNode, "SummonerCard"):setSwallowTouches(false)
        CommonHelper.getChild(card.cardNode, "SummonerCard/SummonerImageGrey"):setSwallowTouches(false)
        card.cardBtn:addTouchEventListener(function(obj, event)
            if event == 2 or event == 3 then
                local endPos = obj:getTouchEndPosition()
                local beginPos = obj:getTouchBeganPosition()
                if cc.pGetDistance(beginPos, endPos) > 32 then
                    return
                end
                local index = self.sumIndex[i]
                MusicManager.playSoundEffect(CardButtonSound)
                UIManager.open(UIManager.UI.UISummonerInfo, self.sumData, index, handler(self, self.onOpen))
            end
        end)
        self.sumCard[card.id] = card
    end
end

-- 初始化召唤师数据
function UISummonerList:initSummonerData()
    local list = getSaleSummonerItemList() or {}
    local sumBought = getGameModel():getSummonersModel():getSummoners() or {}
    self.sumCount   = #list
    self.boughtNum  = #sumBought
    self.sumData    = {}
    for _, v in pairs(list) do
        local temp = {sumID = v, isBuy = false, orderBuy = 0}
        for m, n in pairs(sumBought) do
            if v == n then
                temp.isBuy = true
                temp.orderBuy = m
                break
            end
        end
        table.insert(self.sumData, temp)
    end

    local function compare(a, b)
        if a.isBuy and not b.isBuy then
            return true
        elseif not a.isBuy and b.isBuy then
            return false
        elseif a.isBuy and b.isBuy then
            return a.orderBuy < b.orderBuy
        else
            return a.sumID < b.sumID
        end
    end
    table.sort(self.sumData, compare)
end

-- 设置召唤师数量文本
function UISummonerList:setSummonerNum()
    CommonHelper.getChild(self.root, "MainPanel/SummonerNum"):setString("" .. self.boughtNum .. "/" .. self.sumCount)
end

-- 初始化滚动面板数据
function UISummonerList:initRotateData()
    self.rotateAngle      = 0
    self.midIndex         = 5
    self.midSumCardIndex  = 1

    self.rotaPanel:setRotation(0)
    self.sumIndex = {}
    for i = 1, 40 do
        self.sumIndex[i] = i+(self.sumCount-4)

        if self.sumIndex[i] > self.sumCount then
            self.sumIndex[i] = self.sumIndex[i]%self.sumCount
            self.sumIndex[i] = self.sumIndex[i]==0 and self.sumCount or self.sumIndex[i]
        end
    end
end

-- 设置滚动面板数据
function UISummonerList:setRotatePanel()
    for index, sumcardIndex in ipairs(self.sumIndex) do
        self:setCardInfo(index, sumcardIndex)
    end
end

-- 设置滚动面板节点的数据
function UISummonerList:setCardInfo(index, sumcardIndex)
    local card = self.sumCard[index]
    if nil == card then
        print("setCardInfo  card == nil, index", index)
        return
    end
    local icon  = CommonHelper.getChild(card.cardNode, "SummonerCard/SummonerImage")
    local grey  = CommonHelper.getChild(card.cardNode, "SummonerCard/SummonerImageGrey")
    local edge  = CommonHelper.getChild(card.cardNode, "SummonerCard/EdgeImage")
    local uedge = CommonHelper.getChild(card.cardNode, "SummonerCard/EdgeImage_Grey")
    local blink = CommonHelper.getChild(card.cardNode, "SummonerCard/NewBlink")

    local data = self.sumData[sumcardIndex]
    if nil == data then
        print("setCardInfo  data == nil, sumcardIndex", sumcardIndex)
        return
    end
    local confSum = getSaleSummonerConfItem(data.sumID)
    icon:loadTexture(confSum.Head_Name, 1)
    grey:loadTextures(confSum.Head_Name, confSum.Head_Name, confSum.Head_Name, 1)
    icon:setVisible(data.isBuy)
    grey:setVisible(not data.isBuy)
    edge:setVisible(data.isBuy)
    uedge:setVisible(not data.isBuy)
    blink:setVisible(confSum.NewLabel == 1)

    if index == self.midIndex then
        card.cardPanel:setLocalZOrder(41)
        card.cardNode:setColor(cc.c4b(255,255,255,255))
        CommonHelper.playCsbAnimate(card.cardNode, ResConfig.UISummonerList.Csb2.card, "OnNormal", false)
    else
        card.cardNode:setColor(cc.c4b(128,128,128,128))
        CommonHelper.playCsbAnimate(card.cardNode, ResConfig.UISummonerList.Csb2.card, "Normal", false)
    end
end

-- 设置滚动面板中间节点的状态
function UISummonerList:setMideCardState(bTouch)
    if bTouch then
        local card = self.sumCard[self.midIndex]
        local color = cc.c4b(128,128,128,128)
        card.cardNode:setColor(color)
        card.cardPanel:setLocalZOrder(card.localZorder)
        card.cardNode:stopAllActions()
        CommonHelper.playCsbAnimate(card.cardNode, ResConfig.UISummonerList.Csb2.card, "Normal", false)
    else
        local card = self.sumCard[self.midIndex]
        local color = cc.c4b(255,255,255,255)
        card.cardNode:setColor(color)
        card.cardPanel:setLocalZOrder(41)
        CommonHelper.playCsbAnimate(card.cardNode, ResConfig.UISummonerList.Csb2.card, "OnNormal", false)
    end
end

-- 初始化界面(背景和技能)
function UISummonerList:showCard()
    --当前卡牌ID
    local sumID = self.sumData[self.midSumCardIndex].sumID
    local confHero = getHeroConfItem(sumID)
    if nil == confHero then
        return
    end
    --名字
    CommonHelper.getChild(self.root, "MainPanel/Infopanel/SummonerName"):setString(getHSLanConfItem(confHero.Common.Name))

    --技能
    for i, skill in pairs(self.summonerSkill) do
        local confSkill = getSkillConfItem(confHero.PlayerSkill[i])
        if confSkill then
            skill.image:loadTexture(confSkill.IconName or "", 1)
            skill.Name:setString(getHSSkillLanConfItem(confSkill.Name))
            skill.infoLabel:setString(getHSSkillLanConfItem(confSkill.Desc))
            skill.Cd:setString(confSkill.CostDesc1~=0 and getHSSkillLanConfItem(confSkill.CostDesc1) or "")
        else
            print("error skillConf is nil", confHero.PlayerSkill[i])
        end
    end

    --背景
    local confSum = getSaleSummonerConfItem(sumID)
    local str = "ui_new/p_public/effect/hero_" .. sumID .. "_Ult/" .. confSum.Bg_Name
    if self.heroImg then
        -- 创建一个备份在后面
        local backup = cc.CSLoader:createNode(str)
        backup:setAnchorPoint(0.5, 0.5)
        backup:setLocalZOrder(0)
        CommonHelper.getChild(backup, "Panel_2"):setSwallowTouches(false)
        self.bgNode1:addChild(backup)
        --先淡隐，后重置
        local fadeOut = cc.FadeOut:create(0.1)
        local callback = cc.CallFunc:create(function()
            -- 删除资源
            if self.heroTexture then
                self.bgNode1:removeAllChildren()
                self.bgNode2:removeAllChildren()
                cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(self.heroTexture)
                cc.Director:getInstance():getTextureCache():removeUnusedTextures()
                self.heroTexture = nil
            end
            self.heroTexture = "ui_new/p_public/effect/hero_" .. sumID .. "_Ult/" .. confSum.Bg_Texture
            --
            self.heroImg = cc.CSLoader:createNode(str)
            self.heroImg:setAnchorPoint(0.5, 0.5)
            self.heroImg:setLocalZOrder(1)
            CommonHelper.getChild(self.heroImg, "Panel_2"):setSwallowTouches(false)
            self.bgNode2:addChild(self.heroImg)
        end)
        --执行切换过程
        self.heroImg:stopAllActions()
        local seq = cc.Sequence:create(fadeOut, callback)
        seq:setTag(10)
        self.heroImg:runAction(seq)
    else
        self.heroTexture = "ui_new/p_public/effect/hero_" .. sumID .. "_Ult/" .. confSum.Bg_Texture
        self.heroImg = cc.CSLoader:createNode(str)
        self.heroImg:setAnchorPoint(0.5, 0.5)
        CommonHelper.getChild(self.heroImg, "Panel_2"):setSwallowTouches(false)
        self.bgNode2:addChild(self.heroImg)
    end
end

return UISummonerList