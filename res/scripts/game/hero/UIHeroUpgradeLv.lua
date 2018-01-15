--[[
英雄升级面板
]]

local ScrollViewExtend = require("common.ScrollViewExtend").new()
local scheduler = require("framework.scheduler")  
local UIHeroUpgradeLv = class("UIHeroUpgradeLv", function ()
	return require("common.UIView").new()
end)

local UILanguage = {materialPreview = 158, getExp = 142, upgarde = 506, needExp = 116
    , fullLv = 115, fullMaterialTips = 145, heroLockTips = 167, materialLvTips = 162, unEnoughGold = 572
    , fullLevel = 595, limitFullLv = 177, starFullLv = 175, userFullLv = 176
    , summonerFullLv = 213, starFullLv2 = 214, lv = 512, heroLv = 528 }
-- 经验加成提示语言包
local ExpTipsLang = {[0] = {147}, [1] = {148, 151}, [2] = {149, 152}, [3] = {150, 153}}

local MaterialMax = 6
local UpgradeLimitLv = 15 -- 关联玩家等级
local DefaultCount = 9

function UIHeroUpgradeLv:ctor()
    self.UICsb = ResConfig.UIHeroUpgradeLv.Csb2
    self.rootPath = self.UICsb.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)
    self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
	self.root:runAction(self.rootAct)

    self:initUI()
    self:createMaterialItem() -- 创建物品格子
end

function UIHeroUpgradeLv:initUI()
    CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/TitleLabel")
        :setString(CommonHelper.getUIString(UILanguage.materialPreview))
    self.expTips = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/ExpTips")

    self.backBtn = CsbTools.getChildFromPath(self.root, "CloseButton")
    CsbTools.initButton(self.backBtn, function (obj)
        obj:setTouchEnabled(false)
        UIManager.close()
    end)

    CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/TipButton"):addTouchEventListener(function (obj, type)
        if 0 == type then
            self.rootAct:play("TipInfoOpen", false)
        elseif 2 == type or 3 == type then
            self.rootAct:play("TipInfoClose", false)
        end
    end)

    CsbTools.getChildFromPath(self.root, "TipInfoPanel/TipInfoText")
        :setString(CommonHelper.getUIString(160))

    self.upgradeGoldPanel = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/pub_gold_3")
    self.ownExpPanel = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/Tips2")
    self.upgardeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/pub_gold_3/UpLevelConfirmButton")
    CsbTools.initButton(self.upgardeBtn, handler(self, self.upgradeCallBack)
        , CommonHelper.getUIString(UILanguage.upgarde), "UpLevelConfirmButton/Text", "Text", "Text")

    self.Lb = {}
    self.Lb.gold = CsbTools.getChildFromPath(self.root, "MoneyPanel/MoneyPanel/GoldCountLabel")
    self.Lb.diamond = CsbTools.getChildFromPath(self.root, "MoneyPanel/MoneyPanel/GemCountLabel")
    self.Lb.heroLv = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/Tips1")
    self.Lb.expSum = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/Tips2/GetExpSum")
    self.Lb.goldNum = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/pub_gold_3/GoldNum")
    self.Lb.expNum = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/ExpNum")
    self.Lb.upLvTips_1 = CsbTools.getChildFromPath(self.root, "UpLvPanel/EffectPanel/UpLvText")
    self.Lb.upLvTips_2 = CsbTools.getChildFromPath(self.root, "UpLvPanel/EffectPanel/UpLvText_2")

    -- 选择的材料(最多6个)
    self.uiMaterials = {}
    for i = 1, 6 do
        self.uiMaterials[i] = {}
        local btn = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/MeterialBarButton"..i)
        local obj = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/MeterialBarButton"..i.."/MeterialAll")
        btn:setTag(i)
        CsbTools.initButton(btn, handler(self, self.clickMaterialItem))
        local act = cc.CSLoader:createTimeline(self.UICsb.materialItem)
        btn:runAction(act)

        if not self.clickSound then
            self.clickSound = getButtonEffectPath(btn:getName())
        end

        self.uiMaterials[i].btn = btn
        self.uiMaterials[i].act = act
        self.uiMaterials[i].obj = obj
    end

    self.upLvMaterials = {}
    for k = 1, 6 do
        self.upLvMaterials[k] = {}
        self.upLvMaterials[k].obj = CsbTools.getChildFromPath(self.root, "UpLvPanel/MeterialAll_"..k)
        self.upLvMaterials[k].act = cc.CSLoader:createTimeline(self.UICsb.materialItem)
        self.upLvMaterials[k].obj:runAction(self.upLvMaterials[k].act)
    end

    self.expBar = CsbTools.getChildFromPath(self.root, "MainPanel/MeterialPanel/ExpLoadingBar")
end

function UIHeroUpgradeLv:createMaterialItem()
    local csb   = getResManager():getCsbNode(self.UICsb.materialItem)
    local itemSize = CsbTools.getChildFromPath(csb, "MainPanel"):getContentSize()
    csb:cleanup()

    self.view = CsbTools.getChildFromPath(self.root, "MainPanel/BagPanel/AllScrollView")
    -- 所有可以参与升级的材料
    self.count = self:getUpgradeMaterialCount()
    self.count = self.count > DefaultCount and self.count or DefaultCount

    local tabParam = 
    {
        rowCellCount    = 9,                  -- 每行节点个数
        defaultCount    = DefaultCount,       -- 初始节点个数
        maxCellCount    = self.count,         -- 最大节点个数
        csbName         = self.UICsb.materialItem,      -- 节点的CSB名称
        --cellName        = "",                         -- 节点触摸层的名称
        cellSize        = itemSize,                     -- 节点触摸层的大小
        uiScrollView    = self.view,                    -- 滚动区域
        distanceX       = 3,                            -- 节点X轴间距
        distanceY       = 1,                            -- 节点Y轴间距
        offsetX         = 2,                            -- 第一列的偏移
        offsetY         = 15,                            -- 第一行的偏移
        setCellDataCallback = function(node, i) self:setItemData(node, i) end,          -- 设置节点数据回调函数
    }
    ScrollViewExtend:init(tabParam)
    ScrollViewExtend:create()
end

function UIHeroUpgradeLv:onOpen(fromUI, heroID, uiCallFunc)
    local count = self:getUpgradeMaterialCount()
    if count > self.count then
        ScrollViewExtend:extendItem(count - self.count)
        self.count = count
    end

    self.uiCallFunc = uiCallFunc
    self.upgardeBtn:setTouchEnabled(true)
    self.backBtn:setTouchEnabled(true)
    self.root:setVisible(true)
    self.canTouch = true

    self.heroID = heroID
    self:initTopPanel()
    self:initMaterialPanel()

    self.schedulerHandler = scheduler.scheduleGlobal(handler(self, self.timeUpdate), 0.03)
    -- 监听升级回调
    local upgradeLvCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.UpgradeSC)
    self.sendUpgardeHanlder = handler(self, self.onResponseUpgradeLv)
    NetHelper.setResponeHandler(upgradeLvCmd, self.sendUpgardeHanlder)
end

function UIHeroUpgradeLv:setItemData(itemCsb, i)
    itemCsb:setTag(i)
    local node = self:showItemData(itemCsb, self.allMaterial[i], true)
    if node then
        local starInnerPos  = cc.p(0, 0)

        node:setTag(i)
        node:setTouchEnabled(true)
        node:setSwallowTouches(false)
        -- 添加点击监听
	    node:addTouchEventListener(function(obj, event)
            if not self.canTouch then
                return
            end

		    if event == 0 then
			    self.canClick = true
			    starInnerPos = self.view:getInnerContainerPosition()
		    elseif event == 1 then
			    local innerPos = self.view:getInnerContainerPosition()
			    if cc.pGetDistance(starInnerPos, innerPos) > 5 then
				    self.canClick = false
			    end
		    elseif event == 2 then
			    if self.canClick then
                    MusicManager.playEffect(self.clickSound)

				    self:chooseMaterialItem(obj)
			    end
		    end
	    end)
    end
end

function UIHeroUpgradeLv:showItemData(itemNode, itemInfo, showNum)
    if itemInfo and showNum then
        CsbTools.getChildFromPath(itemNode, "MaskImage"):setVisible(itemInfo.num <= 0)
    else
        CsbTools.getChildFromPath(itemNode, "MaskImage"):setVisible(false)
    end

    local propCsb = CsbTools.getChildFromPath(itemNode, "MainPanel/PropItem")
    local touchNode = CsbTools.getChildFromPath(itemNode, "MainPanel")
    if itemInfo then
        propCsb:setVisible(true)

        local propConf = getPropConfItem(itemInfo.ID)
        UIAwardHelper.setPropItemOfConf(propCsb, propConf, 0)

        local numLb = CsbTools.getChildFromPath(propCsb, "Item/Num")
        if numLb then
            numLb:setVisible(showNum and true or false)
            numLb:setString(itemInfo.num)
        end

        CommonHelper.playCsbAnimate(itemNode, self.UICsb.materialItem, "Light", true)

        CsbTools.getChildFromPath(itemNode, "LockImage"):setVisible(itemInfo.isLock and itemInfo.isLock > 0) -- 锁
    else
        propCsb:setVisible(false)
        CommonHelper.playCsbAnimate(itemNode, self.UICsb.materialItem, "Empty", false)
    end

    return touchNode
end

function UIHeroUpgradeLv:initTopPanel()
    local userModel = getGameModel():getUserModel()
    self.Lb.gold:setString(userModel:getGold())
    self.Lb.diamond:setString(userModel:getDiamond())

    self.Lb.expSum:setString(0)
    self.Lb.goldNum:setString(0)

    self.ownExpPanel:setVisible(false)
    self.upgradeGoldPanel:setVisible(false)
    self.heroModel = getGameModel():getHeroCardBagModel():getHeroCard(self.heroID)
    if not self.heroModel then
        print("cann't find heroModel", self.heroID)
        return
    end

    self.curUserLv = userModel:getUserLevel()
    self.lv = self.heroModel:getLevel()
    self.exp = self.heroModel:getExp()
    self.predictLv = self.lv
    self.predictExp = self.exp
    self.heroMaxLv = getSoldierStarSettingConfItem(self.heroModel:getStar()).TopLevel
    self.curLvSetting = getSoldierLevelSettingConfItem(self.lv)
    local nextLvSetting = getSoldierLevelSettingConfItem(self.lv + 1)
    if not self.curLvSetting or not nextLvSetting then
        print("getSoldierLevelSettingConfItem is nil", self.lv)
        return
    end
    
    -- 1、玩家等级15级以前,英雄卡片可以升级到15级
    -- 2、玩家等级或该星级卡片最高级为顶级
    self.curHeroMax = self.heroMaxLv
    if self.curUserLv <= UpgradeLimitLv then
        if self.heroMaxLv > UpgradeLimitLv then
            self.curHeroMax = UpgradeLimitLv
        end
    else
        if self.heroMaxLv >= self.curUserLv then
            self.curHeroMax = self.curUserLv
        end
    end

    self:setLvExp(self.exp, nextLvSetting.Exp, self.lv)
    
    for _, m in pairs(self.uiMaterials) do
        m.act:play("Empty", false)
    end

    self.upgradeCost = 0 -- 升级消耗金币=材料数量*self.upgradeCost
    self.haveExp = 0
    self.materials = {} -- 选择的材料,对应self.uiMaterials
end

function UIHeroUpgradeLv:initMaterialPanel()
    self:sortAllMaterial(self.heroID)
    self:updateItems()
end

function UIHeroUpgradeLv:onClose()
    if self.schedulerHandler then
        scheduler.unscheduleGlobal(self.schedulerHandler)
    end

    local upgradeLvCmd = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.UpgradeSC)
    NetHelper.removeResponeHandler(upgradeLvCmd, self.sendUpgardeHanlder)

    -- 清理材料框
    if #self.materials > 0 then
        self.materials = {}
        self:updateTopPanel()
    end

    self.root:setVisible(false)
end

function UIHeroUpgradeLv:sortAllMaterial(heroId)
    self.allMaterial = {}

    -- 经验书+技能书
    local items = getGameModel():getBagModel():getItems()
    for k, v in pairs(items) do
        if k < 1000000 then
            local itemConf = getPropConfItem(k)
            if itemConf then
                if 5 == itemConf.Type then -- 经验书
                    table.insert(self.allMaterial, {ID = k, type = itemConf.Type, num = v, icon = itemConf.Icon, quality = itemConf.Quality})         
                end
            else
                print("getPropConfItem is nil!!!", k)
            end
        end
    end

    table.sort(self.allMaterial, function (a, b)
        if a.quality > b.quality then
            return true
        elseif a.quality == b.quality then
            return a.ID < b.ID
        end
        return false
    end)
end

function UIHeroUpgradeLv:updateItems()
    self.view:scrollToTop(0.05, false)
    ScrollViewExtend:reloadData()
end

function UIHeroUpgradeLv:upgradeCallBack(obj)
    obj.soundId = nil
    if #self.materials <= 0 then
        print("no material to upgarde!!!")
        obj.soundId = MusicManager.commonSound.fail
        return
    end

    CommonHelper.checkConsumeCallback(1, self.upgradeCost, function ()
        self.canTouch = false
        obj:setTouchEnabled(false)
        local BufferData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.UpgradeCS)
        local item = {}
        for _, info in pairs(self.materials) do
            if 5 == info.type then
                table.insert(item, info.ID)
            end
        end
    
        BufferData:writeInt(self.heroID)
        BufferData:writeInt(#item)
    
        for j = 1, #item do
            BufferData:writeInt(item[j])
        end

	    NetHelper.request(BufferData)
    end)
end

function UIHeroUpgradeLv:timeUpdate(dt)
    self.predictLv, self.predictExp = self:calcPredictHeroLvExp(self.predictLv, self.predictExp, self.haveExp)
    self.haveExp = 0

    if self.lv == self.predictLv and self.predictExp == self.exp then
        return
    end

    local dv = self.predictLv - self.lv
    local nextLvExp = getSoldierLevelSettingConfItem(self.lv + 1).Exp
    -- 升级大于3级进度条播放速度0.1s, 大于等于1小于等于3级0.4s,小于1级1.0s
    if dv > 3 then
        self.exp = self.exp + math.ceil(dt/0.1 * nextLvExp)
    elseif dv >= 1 and dv <= 3 then
        self.exp = self.exp + math.ceil(dt/0.4 * nextLvExp)
    else
        self.exp = self.exp + math.ceil(dt/1.0 * self.predictExp)
    end

    if self.lv >= self.curHeroMax then
        self.exp = 0
        self.lv = self.curHeroMax
    else
        if self.exp >= nextLvExp then
            self.exp = self.exp - nextLvExp
            self.lv = self.lv + 1
        end
    end

    if self.lv > self.predictLv
        or (self.predictLv == self.lv and self.predictExp <= self.exp) then
             self.lv = self.predictLv
             self.exp = self.predictExp
    end

    self:setLvExp(self.exp, nextLvExp, self.lv)
end

-- 点击被选择的材料
function UIHeroUpgradeLv:clickMaterialItem(obj)
    local itemInfo = self.materials[obj:getTag()]
    if itemInfo then -- 框中材料移除
        self.predictLv, self.predictExp = self:calcPredictHeroLvExp(self.heroModel:getLevel()
            , self.heroModel:getExp(), self.totalExp - itemInfo.exp)
        self.lv = self.predictLv
        self.exp = self.predictExp
        table.remove(self.materials, obj:getTag())
        self:setLvExp(self.exp, getSoldierLevelSettingConfItem(self.predictLv + 1).Exp, self.lv)

        self:modifyItemCount(itemInfo, 1)
        self:updateTopPanel()
    end
end

function UIHeroUpgradeLv:onResponseUpgradeLv(mainCmd, subCmd, data)
    local ret = data:readInt()  
    if 0 == ret then
        print("upgrade lv fail!!!, why???")
        return
    end
      
    local addExp = data:readInt()   
    local multiple = data:readInt() 
    local moneyType = data:readInt() 
    local money = data:readInt() 

    -- 更改模型
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -money)
    ModelHelper.upgradeHeroLv(self.heroID, addExp)
    
    -- 删除材料
    local materialCount = 0
    for _, info in pairs(self.materials) do
        materialCount = materialCount + 1
        if 5 == info.type then
            ModelHelper.useItem(info.ID, 1)
        end
    end

    for index, uiObj in pairs(self.upLvMaterials) do
        if self.materials[index] then -- 有东西
            -- 显示相关道具
            self:showItemData(uiObj.obj, self.materials[index])
        else
            self:showItemData(uiObj.obj, nil)
            -- 置为空格框
            uiObj.act:play("Empty", false)
        end
    end

    -- 经验获得相关语言包
    self.Lb.upLvTips_1:setString(CommonHelper.getUIString(ExpTipsLang[multiple][1]))
    self.Lb.upLvTips_2:setVisible(ExpTipsLang[multiple][2] and true or false)
    self.Lb.upLvTips_2:setString(ExpTipsLang[multiple][2] and CommonHelper.getUIString(ExpTipsLang[multiple][2]) or "")
    self.rootAct:play("UpLv" .. materialCount, false)
    self.rootAct:setFrameEventCallFunc(function (frame)
        if "FlySound" == frame:getEvent() then
            MusicManager.playSoundEffect(MusicManager.commonSound.flyIn)

        elseif "UpSkillSucess" == frame:getEvent() then            
            
        elseif "UpLvEnd" == frame:getEvent() then
            if self.uiCallFunc then
                self.uiCallFunc()
            end
            MusicManager.playSoundEffect(MusicManager.commonSound.heroLvUp)
            self.rootAct:play("UpLvSuccess", false)

        elseif "Finished" == frame:getEvent() then
            self.rootAct:clearFrameEventCallFunc()
            UIManager.close()
        end
    end)
end

function UIHeroUpgradeLv:setLvExp(exp, nextLvExp, lv)
    self.expBar:setPercent(exp * 100.0 / nextLvExp) -- 设置进度
    self.Lb.heroLv:setString(lv .. CommonHelper.getUIString(UILanguage.heroLv))
    local needExp = nextLvExp - exp
    if lv == self.curHeroMax and 0 == exp then
        self.Lb.expNum:setVisible(false)
        if self.curHeroMax == self.heroMaxLv then
            self.expTips:setString(CommonHelper.getUIString(UILanguage.starFullLv2))
        else
            self.expTips:setString(CommonHelper.getUIString(UILanguage.summonerFullLv))
        end
    else
        self.Lb.expNum:setVisible(true)
        self.Lb.expNum:setString(needExp)
        self.expTips:setString(CommonHelper.getUIString(UILanguage.needExp))
    end
end

function UIHeroUpgradeLv:chooseMaterialItem(obj) -- 选择材料
    local itemInfo = self.allMaterial[obj:getTag()]
    if not itemInfo or itemInfo.num <= 0 then
        return
    end
    
    if self.predictLv >= self.curHeroMax then
        if self.curHeroMax == self.curUserLv then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.userFullLv))
        elseif self.curHeroMax == UpgradeLimitLv then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.limitFullLv))
        else
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.starFullLv))
        end

        return
    end

    if #self.materials >= MaterialMax then
        CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(
                UILanguage.fullMaterialTips), MaterialMax))
    else
        local function addMaterial(exp)
            self.haveExp = self.haveExp + exp
            itemInfo.exp = exp
            itemInfo.tag = obj:getTag()
            self:modifyItemCount(itemInfo, -1)
        
            table.insert(self.materials, itemInfo)
            self:updateTopPanel()
        end
    
        -- 计算经验
        local exp = 0
        if 5 == itemInfo.type then
            exp = getPropConfItem(itemInfo.ID).TypeParam[1]
            addMaterial(exp)
        else
            exp = getSoldierLevelSettingConfItem(itemInfo.lv).StarDExp[itemInfo.star]
    
            if itemInfo.isLock > 0 then
                CsbTools.addTipsToRunningScene(CommonHelper.getUIString(UILanguage.heroLockTips))
                return
            elseif itemInfo.lv >= 30 then
                local params = {}
                params.msg = CommonHelper.getUIString(UILanguage.materialLvTips)
                params.confirmFun = function () addMaterial(exp) end
                params.cancelFun = function () print("nothing to do...") end
                UIManager.open(UIManager.UI.UIDialogBox, params)
            else
                addMaterial(exp)
            end
        end
    end
end

function UIHeroUpgradeLv:calcPredictHeroLvExp(curLv, curExp, addExp)
    local predictExp = curExp
    local predictLv = curLv

    if addExp > 0 then
        predictExp = predictExp + addExp
	    for i = curLv, self.heroMaxLv do
		    local nextLvExp = getSoldierLevelSettingConfItem(predictLv + 1).Exp
            if predictLv >= self.curHeroMax then
				predictExp = 0
				predictLv = self.curHeroMax
				break
            end
		    if predictExp - nextLvExp >= 0 then
				predictExp = predictExp - nextLvExp
				predictLv = i + 1
		    else
			    break
		    end
	    end
    end

    return predictLv, predictExp
end

function UIHeroUpgradeLv:updateTopPanel() -- 更新选中的材料
    local hasMaterial = false
    self.totalExp = 0
    for index, uiObj in pairs(self.uiMaterials) do
        if self.materials[index] then -- 有东西
            hasMaterial = true
            self.totalExp = self.totalExp + self.materials[index].exp

            -- 显示相关道具
            self:showItemData(uiObj.obj, self.materials[index])
        else
            self:showItemData(uiObj.obj, nil)
            -- 置为空格框
            uiObj.act:play("Empty", false)
        end
    end

    self.upgradeGoldPanel:setVisible(hasMaterial)
    self.ownExpPanel:setVisible(hasMaterial)

    self.upgradeCost = self.curLvSetting.LvUpCost * #self.materials
    self.Lb.goldNum:setString(self.upgradeCost)
    self.Lb.expSum:setString(self.totalExp)
end

function UIHeroUpgradeLv:modifyItemCount(itemInfo, count)
    itemInfo.num = itemInfo.num + count
    local item = self.view:getChildByTag(itemInfo.tag)
    local numLb = CsbTools.getChildFromPath(item, "MainPanel/PropItem/Item/Num")
    if numLb then
        numLb:setString(itemInfo.num)
    end

    CsbTools.getChildFromPath(item, "MaskImage"):setVisible(itemInfo.num <= 0)
end

function UIHeroUpgradeLv:getUpgradeMaterialCount()
    local count = 0
    local items = getGameModel():getBagModel():getItems()
    for k, v in pairs(items) do
        if k < 1000000 then
            local itemConf = getPropConfItem(k)
            if itemConf then
                if 5 == itemConf.Type then -- 经验书
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

return UIHeroUpgradeLv