--[[
体力购买界面
]]

local UIEnergy = class("UIEnergy", function()
    return require("common.UIView").new()
end)

function UIEnergy:ctor()
end

function UIEnergy:init()
    self.UICsb = ResConfig.Common.Csb2
    self.rootPath = ResConfig.Common.Csb2.buyEnergyPanel
    self.root = getResManager():getCsbNode(self.UICsb.buyEnergyPanel)
    self:addChild(self.root)

    CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipsText_2"):setString(CommonHelper.getUIString(2123))
    
    self:initEnergyPanel()
end

function UIEnergy:onOpen(fromUIID, ...)
    -- 监听刷新货币
    self.updateHandler = handler(self, self.updateCallBack)
    EventManager:addEventListener(GameEvents.EventReceiveCurrency, self.updateHandler)

    local userModel = getGameModel():getUserModel()
    self.buyEnergyTimes = userModel:getBuyEnergyTimes()
    self.showGoldCount = userModel:getEnergy()
    self.energyEnergyLb:setString(userModel:getEnergy().."/"..userModel:getMaxEnergy())

    self:showBuyEnergyPanelInfo(self.buyEnergyTimes)
    self:updateCallBack()
end

function UIEnergy:onClose()
    EventManager:removeEventListener(GameEvents.EventReceiveCurrency, self.updateHandler)
end

function UIEnergy:onTop()
    self:showBuyEnergyPanelInfo(self.buyEnergyTimes)
end

-- 体力界面相关
function UIEnergy:initEnergyPanel()
	local buyEnergyConfrimCallBack = function (obj)
        obj.soundId = nil
        -- 次数判断
        if self.buyEnergyTimes >= #getIncreasePayItemList() then
            obj.soundId = MusicManager.commonSound.confirm
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(370))
            return
        end

        -- 货币判断
        local payConfItem = getIncreasePayConfItem(self.buyEnergyTimes + 1)
        if not payConfItem then
            return
        end

--        if getGameModel():getUserModel():getDiamond() < payConfItem.EnergyCost[1] then
--            obj.soundId = MusicManager.commonSound.fail
--            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
--            return
--        end
        CommonHelper.checkConsumeCallback(2, payConfItem.EnergyCost[1], function ()
            local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.BuyCS)
            buffData:writeInt(0)
            buffData:writeInt(1)
            -- 发送购买体力消息
            NetHelper.requestWithTimeOut(buffData, 
                NetHelper.makeCommand(MainProtocol.User, UserProtocol.BuySC), 
                handler(self, self.onResponeBuyEnergy))
        end)
	end

    self.buyButton = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BuyButton/BuyButton")
    CsbTools.initButton(self.buyButton, buyEnergyConfrimCallBack, "", "ButtomName", "Node")
    
    -- 购买体力界面
    CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BarText"):setString(CommonHelper.getUIString(52)) -- 购买体力
    CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel3"):setString(CommonHelper.getUIString(624))
    self.energyLb = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/EnergySum")
	self.gemSumLb = CsbTools.getChildFromPath(self.buyButton, "Node/ButtonName")
    self.buyEnergyTimesLb = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TimesUse")
    self.totalTimesLb = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TimesConut")
    self.totalTimesLb:setString("/" .. #getIncreasePayItemList())

    self.assretPanel = CsbTools.getChildFromPath(self.root, "AssretPanel")
    self.energyCoinLb = CsbTools.getChildFromPath(self.root, "AssretPanel/AssetPanel/GoldCountLabel")
    self.energyDiamondLb = CsbTools.getChildFromPath(self.root, "AssretPanel/AssetPanel/GemCountLabel")
    self.energyEnergyLb = CsbTools.getChildFromPath(self.root, "AssretPanel/AssetPanel/PowerLabel")
    self.confirmLb = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton/ButtonName")
end

function UIEnergy:onResponeBuyEnergy(mainCmd, subCmd, data)
    if MainProtocol.User == mainCmd and UserProtocol.BuySC == subCmd then
        local attrType = data:readInt()
        local addCount = data:readInt()
        local result = data:readInt()
        local extend = data:readInt()

        if 0 == result then
            print("buy Energy fail!!!")
            return
        end

        if 0 == attrType then -- 体力
            self.buyEnergyTimes = self.buyEnergyTimes + 1
            getGameModel():getUserModel():setBuyEnergyTimes(self.buyEnergyTimes)
		    self:showBuyEnergyPanelInfo(self.buyEnergyTimes)

            local payConfItem = getIncreasePayConfItem(self.buyEnergyTimes)
            ModelHelper.addCurrency(UIAwardHelper.ResourceID.Energy, addCount)
            ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -payConfItem.EnergyCost[1])
        
            -- 体力获得动画
            local UIItemAnimation = require("game.hall.UIItemAnimation").new(addCount, extend, self, 
                "ui_new/g_gamehall/g_gpub/BuyEnergy.csb", function(addCount)
                    self.showGoldCount = self.showGoldCount + addCount
                    self.energyEnergyLb:setString(math.ceil(self.showGoldCount).."/"..getGameModel():getUserModel():getMaxEnergy())
                    CommonHelper.playCsbAnimation(self.assretPanel, "AddEnergry", false, nil)
                end)
            MusicManager.playSoundEffect(58)
        end
    end
end

function UIEnergy:showBuyEnergyPanelInfo(buyEnergyTimes)
	self.buyEnergyTimesLb:setString(buyEnergyTimes)
    local payConfItem = nil
    if buyEnergyTimes >= #getIncreasePayItemList() then
        payConfItem = getIncreasePayConfItem(#getIncreasePayItemList()) 
        CommonHelper.playCsbAnimate(self.buyButton, "ui_new/g_gamehall/g_gpub/BuyButton.csb", "Cant", nil, true)
        self.gemSumLb:setString(CommonHelper.getUIString(390))
    else
        payConfItem = getIncreasePayConfItem(buyEnergyTimes + 1)
        CommonHelper.playCsbAnimate(self.buyButton, "ui_new/g_gamehall/g_gpub/BuyButton.csb", "Can", nil, true)

        self.gemSumLb:setString(payConfItem.EnergyCost[1])
        if payConfItem.EnergyCost[1] > getGameModel():getUserModel():getDiamond() then
            self.gemSumLb:setColor(cc.c3b(255, 0, 0))
        else
            self.gemSumLb:setColor(cc.c3b(255, 255, 255))
        end
    end

    self.energyLb:setString(payConfItem.EnergyCost[2])
end

function UIEnergy:updateCallBack()
    local userModel = getGameModel():getUserModel()
    self.energyCoinLb:setString(userModel:getGold())
    self.energyDiamondLb:setString(userModel:getDiamond())
end

return UIEnergy