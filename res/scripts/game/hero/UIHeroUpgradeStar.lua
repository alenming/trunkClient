--[[
英雄升星面板
]]

local UIHeroUpgradeStar = class("UIHeroUpgradeStar", function ()
	return require("common.UIView").new()
end)

local csbFile       = ResConfig.UIHeroUpgradeStar.Csb2

function UIHeroUpgradeStar:ctor()
    self.rootPath = csbFile.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
    self.root:runAction(self.rootAct)
    self.rootAct:play("Normal", false)

    self.curStarLab = CsbTools.getChildFromPath(self.root, "MainPanel/StarNum_F")
    self.nextStarLab = CsbTools.getChildFromPath(self.root, "MainPanel/StarNum_B")

    local attriNameID = {417, 416, 418, 419, 427, 420, 428, 421, 422, 423}
    local attriPanel = CsbTools.getChildFromPath(self.root, "MainPanel/AttriBg")
    for i=1, 10 do
        self["attriNameLab_" .. i]  = CsbTools.getChildFromPath(attriPanel, "Attri_" .. i)
        self["attriLab_" .. i]      = CsbTools.getChildFromPath(attriPanel, "Attri_" .. i .. "_0")
        self["attriNameLab_" .. i]:setString(CommonHelper.getUIString(attriNameID[i]))
    end
    for i=1, 5 do
        self["attriAddLab_" .. i]   = CsbTools.getChildFromPath(attriPanel, "AttriAdd_" .. i)
    end

    self.heroFrameImg = CsbTools.getChildFromPath(self.root, "MainPanel/BarImage")
    self.heroIconImg = CsbTools.getChildFromPath(self.root, "MainPanel/HeroImage")
    self.fragCountLab = CsbTools.getChildFromPath(self.root, "MainPanel/CardNum")
    self.goldCountLab = CsbTools.getChildFromPath(self.root, "MainPanel/GoldNum")
    self.defaultColor = self.fragCountLab:getTextColor()

    self.upStarBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
    self.upStarBtnCsb = CsbTools.getChildFromPath(self.upStarBtn, "Button_Orange")

    CsbTools.initButton(self.upStarBtn, handler(self, self.upStarBtnCallBack), 
        CommonHelper.getUIString(507), "Button_Orange/ButtomName", "Button_Orange")

    self.heroFrameImg:setTouchEnabled(true)
    self.heroFrameImg:addClickEventListener(function()
        if not self.heroID then return end
        local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
        if not heroModel then return end
        UIManager.open(UIManager.UI.UIHeroQuickTo, heroModel:getID(), heroModel:getStar())
    end)

    local closeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/Button_Close")
    CsbTools.initButton(closeBtn, function()
        UIManager:close()
    end)

    -- 升星特效
    self.effectNode = getResManager():getCsbNode(csbFile.effect)
    self:addChild(self.effectNode)
    self.effectNode:setVisible(false)
    self.effectNodeAct = cc.CSLoader:createTimeline(csbFile.effect)
    self.effectNode:runAction(self.effectNodeAct)
    CommonHelper.layoutNode(self.effectNode) -- 自适应

    -- 特效骨骼动画节点
    self.effectAniNode = CsbTools.getChildFromPath(self.effectNode, "MainPanel/Panel_1/HeroArmatureNode1")
    self.originX, self.originY = self.effectAniNode:getPosition()
    
    CsbTools.getChildFromPath(self.effectNode, "MainPanel/GiftPanel"):setVisible(false)
    -- 特效确认按钮
    local effectConfirmBtn = CsbTools.getChildFromPath(self.effectNode, "MainPanel/ConfirmButton")
    CsbTools.initButton(effectConfirmBtn, function ()
        UIManager.close()
    end, CommonHelper.getUIString(500), "Button_Green/ButtomName", "Button_Green")
end

function UIHeroUpgradeStar:onOpen(_, heroID, uiCallFunc)
    self.heroID = heroID
    self.uiCallFunc = uiCallFunc
    self.costGold = 0
    -- 监听升星回调
    local upgradeStarCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.UpStarSC)
    self.sendUpgardeHanlder = handler(self, self.onResponseUpgradeStar)
    NetHelper.setResponeHandler(upgradeStarCmd, self.sendUpgardeHanlder)

    self:refreshUI(heroID)
end

function UIHeroUpgradeStar:onClose(_, newLv)
    local upgradeStarCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.UpStarSC)
    NetHelper.removeResponeHandler(upgradeStarCmd, self.sendUpgardeHanlder)    
end

function UIHeroUpgradeStar:refreshUI(heroID)
    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroID)
    if not heroModel then print("not find hero id ", heroID) end
    local upStarConf = getSoldierUpRateConfItem(heroID)
    if not upStarConf then print("upStarConf is nil about id ", heroID) end

    local curLv = heroModel:getLevel()
    local curStar = heroModel:getStar()
    local curFrag = heroModel:getFrag()
    local nextStar = curStar + 1
    if upStarConf.TopStar <= curStar then
        nextStar = curStar
    end

    local curSoldierConf = getSoldierConfItem(heroID, curStar)
    local nextSoldierConf = getSoldierConfItem(heroID, nextStar)
    if not(curSoldierConf and nextSoldierConf) then 
        print("soldierConf or nextSoldierConf is nil about id star", heroID, curStar, nextStar) 
    end

    -- 星级
    self.curStarLab:setString(curStar)
    self.nextStarLab:setString(nextStar)

    self.effectNode:setVisible(false)
    -- 骨骼动画
    self.curAni = nil
    self.nextAni = nil
    self.effectAniNode:removeAllChildren()
    AnimatePool.createAnimate(curSoldierConf.Common.AnimationID, handler(self, self.createCurEffectAnimationCallBack))
    AnimatePool.createAnimate(nextSoldierConf.Common.AnimationID, handler(self, self.createNextEffectAnimationCallBack))

    function setAddAttribute(lab, value, suffix)
        if value == 0 then
            lab:setString("")
        else
            if value > 0 then
                lab:setTextColor(cc.c3b(255, 34, 0))
                lab:setString("+" .. value .. (suffix or ""))
            else
                lab:setTextColor(cc.c3b(79, 24, 0))
                lab:setString(value .. (suffix or ""))
            end
        end
    end
    -- 生命
    local curHP = curSoldierConf.Common.HP + curSoldierConf.Common.HPGrowUp*(curLv - 1)
    local nextHP = nextSoldierConf.Common.HP + nextSoldierConf.Common.HPGrowUp*(curLv - 1)
    self.attriLab_1:setString(curHP)
    setAddAttribute(self.attriAddLab_1, nextHP - curHP)

    -- 物攻, 魔攻
    if curSoldierConf.Common.PAttack ~= 0 then
        local curPAttack = curSoldierConf.Common.PAttack + curSoldierConf.Common.PAttackGrowUp*(curLv - 1)
        local nextPAttack = nextSoldierConf.Common.PAttack + nextSoldierConf.Common.PAttackGrowUp*(curLv - 1)
        self.attriLab_2:setString(curPAttack)
        setAddAttribute(self.attriAddLab_2, nextPAttack - curPAttack)
        self.attriNameLab_2:setString(CommonHelper.getUIString(416))
    else
        local curMAttack = curSoldierConf.Common.MAttack + curSoldierConf.Common.MAttackGrowUp*(curLv - 1)
        local nextMAttack = nextSoldierConf.Common.MAttack + nextSoldierConf.Common.MAttackGrowUp*(curLv - 1)
        self.attriLab_2:setString(curMAttack)
        setAddAttribute(self.attriAddLab_2, nextMAttack - curMAttack)
        self.attriNameLab_2:setString(CommonHelper.getUIString(424))
    end

    -- 护甲
    local curPGrow = curSoldierConf.Common.PGuard + curSoldierConf.Common.PGuardGrowUp*(curLv - 1)
    local nextPGrow = nextSoldierConf.Common.PGuard + nextSoldierConf.Common.PGuardGrowUp*(curLv - 1)
    self.attriLab_3:setString(curPGrow)
    setAddAttribute(self.attriAddLab_3, nextPGrow - curPGrow)

    -- 魔抗  
    local curMGrow = curSoldierConf.Common.MGuard + curSoldierConf.Common.MGuardGrowUp*(curLv - 1)
    local nextMGrow = nextSoldierConf.Common.MGuard + nextSoldierConf.Common.MGuardGrowUp*(curLv - 1)
    self.attriLab_4:setString(curMGrow)
    setAddAttribute(self.attriAddLab_4, nextMGrow - curMGrow)

    -- 闪避  
    self.attriLab_5:setString(curSoldierConf.Common.Miss .. "%")
    setAddAttribute(self.attriAddLab_5, nextSoldierConf.Common.Miss - curSoldierConf.Common.Miss, "%")

    -- 攻击范围
    local rangeLanID = {564, 565, 566, 567}
    self.attriLab_6:setString(CommonHelper.getUIString(rangeLanID[curSoldierConf.Common.AttackDistance] or 564))

    -- 攻击速度
    local speedLanID = {559, 560, 561, 562, 563}
    local AttactSpeedRange = {0, 30, 55, 80, 105}
    local range = 1
    for j=#AttactSpeedRange, 1, -1 do
        if curSoldierConf.Common.AttackSpeed > AttactSpeedRange[j] then
            range = j
            break
        end
    end
    self.attriLab_7:setString(CommonHelper.getUIString(speedLanID[range]))

    -- 移动速度
    local speedRange = {0, 40, 80, 120, 160}
    range = 1
    for j=#speedRange, 1, -1 do
        if curSoldierConf.Common.Speed > speedRange[j] then
            range = j
            break
        end
    end
    self.attriLab_8:setString(CommonHelper.getUIString(speedLanID[range]))

    -- 水晶消耗
    self.attriLab_9:setString(curSoldierConf.Cost)

    -- 冷却时间
    self.attriLab_10:setString(string.format("%0.1f", curSoldierConf.CD))

    -- 材料
    local defaultStar = upStarConf.DefaultStar
    local defaultSoldierConf = getSoldierConfItem(heroID, defaultStar)
    if not defaultSoldierConf then print("defaultSoldierConf is nil ", heroID, defaultStar) end
    local defaultSoldierStarConf = getSoldierStarSettingConfItem(defaultStar)
    local nextSoldierStarConf = getSoldierStarSettingConfItem(nextStar)
    if not (defaultSoldierStarConf and nextSoldierConf) then 
        print("defaultSoldierStarConf or nextSoldierConf is nil ", heroId, defaultStar, curStar) 
    end
    self.costGold = nextSoldierStarConf.UpStarCost
    CsbTools.replaceImg(self.heroFrameImg, defaultSoldierStarConf.HeadboxRes)
    CsbTools.replaceImg(self.heroIconImg, defaultSoldierConf.Common.HeadIcon)
    self.fragCountLab:setString("X " .. nextSoldierStarConf.UpStarCount)
    self.goldCountLab:setString("X " .. nextSoldierStarConf.UpStarCost)

    local fragEnough = curFrag >= nextSoldierStarConf.UpStarCount
    local goldEnough = getGameModel():getUserModel():getGold() >= nextSoldierStarConf.UpStarCost

    self.upStarBtn:setBright(fragEnough and goldEnough)
    self.upStarBtn:setTouchEnabled(fragEnough and goldEnough)
    self.fragCountLab:setTextColor(fragEnough and self.defaultColor or display.COLOR_RED)
    self.goldCountLab:setTextColor(goldEnough and self.defaultColor or display.COLOR_RED)
end

function UIHeroUpgradeStar:onResponseUpgradeStar(mainCmd, subCmd, data)
    local heroID = data:readInt()
    local newStar = data:readInt()

    if heroID == 0 then print("heroID is 0") return end
    ModelHelper.upgradeHeroStar(heroID, newStar)

    -- 如果该英雄在队伍中刷新大厅骨骼
    if TeamHelper.isExistCurTeam(heroID) then
        EventManager:raiseEvent(GameEvents.EventUpdateTeam)
    end

    -- 播放升星动画、声音
    MusicManager.playSoundEffect(37)
    self.rootAct:play("UpStar", false)
    self.rootAct:setFrameEventCallFunc(function (frame)
        if "UpStarOver" ~= frame:getEvent() then return end
        self.effectNode:setVisible(true)        
        self.effectNodeAct:play("Movie", false)
        if self.curAni then self.curAni:setVisible(true) end
        if self.nextAni then self.nextAni:setVisible(false) end

        self.effectNodeAct:setFrameEventCallFunc(function (effectFrame)
            if "NodeSwitch" == effectFrame:getEvent() then
                if self.curAni then self.curAni:setVisible(false) end
                if self.nextAni then self.nextAni:setVisible(true) end
            end
        end)
    end)

    self.uiCallFunc()
end

function UIHeroUpgradeStar:upStarBtnCallBack(ref)
    CommonHelper.checkConsumeCallback(1, self.costGold, function ()
        ref:setTouchEnabled(false)
        local buffData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.UpStarCS)
        buffData:writeInt(self.heroID)
        NetHelper.request(buffData)
    end)
end

function UIHeroUpgradeStar:createCurEffectAnimationCallBack(animation)
    animation:setVisible(false)
    self.effectAniNode:addChild(animation)
    self.curAni = animation

    CommonHelper.setRoleZoom(self.heroID, animation, self.effectAniNode, self.originX, self.originY)
end

function UIHeroUpgradeStar:createNextEffectAnimationCallBack(animation)
    animation:setVisible(false)
    self.effectAniNode:addChild(animation)
    self.nextAni = animation

    CommonHelper.setRoleZoom(self.heroID, animation, self.effectAniNode, self.originX, self.originY)
end

return UIHeroUpgradeStar