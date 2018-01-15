--[[
金币试炼奖励宝箱界面

]]

require("game.comm.UIAwardHelper")

local UIGoldTestChest = class("UIGoldTestChest", function()
    return require("common.UIView").new()
end)

local ChestCount = 20 -- 宝箱个数,美术资源
local OpenChestCount = 2 -- 能打开的宝箱数量大于2显示一键领取
local GoldTestChestUILanguage = {RewardChest = 1003, CantReward = 1004, OneKey = 579}
local ChestStatus = { }

function UIGoldTestChest:ctor()
end

function UIGoldTestChest:init()
    self.rootPath = ResConfig.UIGoldTestChest.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local callBack = function(obj)
        obj:setTouchEnabled(false)
        UIManager.close()
    end

    self.back = getChild(self.root, "BackButton")
    self.close = getChild(self.root, "MainPanel/CloseButton")
    CsbTools.initButton(self.back, callBack)
    CsbTools.initButton(self.close, callBack)

    local view = getChild(self.root, "MainPanel/AwardScrollView")
    local view_size = view:getContentSize()
    view:setInnerContainerSize(cc.size(view_size.width * 3, view_size.height))
    view:scrollToLeft(0.05, false)
--    view:addTouchEventListener(function(obj, event)  end)

    self.chestStatus = {}
    
    for i = 1, ChestCount do
        local btn = getChild(view, "AwardBox_" .. i)
        btn:setTag(i)
        btn:setVisible(i <= #getGoldTestChestItemList() and true or false) -- 美术资源给20个,多余的隐藏
        CsbTools.initButton(btn, handler(self, self.touchChestCallBack))
    end

    self.oneKey = getChild(self.root, "MainPanel/FightButton")
    local oneKeyCallBack = function()
        local bufferData = NetHelper.createBufferData(MainProtocol.GoldTest, GoldTestProtocol.ChestStateCS)
	    bufferData:writeInt(0) -- 一键领取发送0
	    NetHelper.request(bufferData)
    end
    CsbTools.initButton(self.oneKey, oneKeyCallBack
        , CommonHelper.getUIString(GoldTestChestUILanguage.OneKey), "Button_Green/ButtomName", "Button_Green")

    local view = getChild(self.root, "MainPanel/AwardScrollView")
    view:setScrollBarEnabled(false)
    local list = getGoldTestChestItemList()
    
    self.chestAct = {}
    for _, v in pairs(list) do
        local conf = getGoldTestChestConfItem(v)
        local chest = getChild(view, "AwardBox_" .. v .. "/AwardBox/AwardBoxPanel")
        getChild(chest, "NumLabel"):setString(tostring(conf.Damage))
        getChild(chest, "StateLabel"):setVisible(false)
        getChild(chest, "ChestBox/ChestBoxPanel/RedTipPoint"):setVisible(false)

        self.chestAct[v] = cc.CSLoader:createTimeline(ResConfig.UIGoldTestChest.Csb2.chest)
        chest:runAction(self.chestAct[v])
    end
end

function UIGoldTestChest:onOpen(fromUIID)
    self.back:setTouchEnabled(true)
    self.close:setTouchEnabled(true)
    local model = getGameModel():getGoldTestModel()

    local hit = getChild(self.root, "MainPanel/HitSumFontLabel")
    hit:setString(tostring(model:getDamage()))

    -- 领取宝箱网络回调
    local respCmd = NetHelper.makeCommand(MainProtocol.GoldTest, GoldTestProtocol.ChestStateSC)
    self.onGetChestHandler = handler(self, self.onResponeGetChest)
	NetHelper.setResponeHandler(respCmd, self.onGetChestHandler)

    self:displayChestStatus()
end

function UIGoldTestChest:displayChestStatus()
    local model = getGameModel():getGoldTestModel()

    local rewardCount = 0
    local canOpenCount = 0

    local list = getGoldTestChestItemList()
    for _, v in pairs(list) do
        local conf = getGoldTestChestConfItem(v)
        if model:getDamage() >= conf.Damage then
            rewardCount = v
        end

        --Open(可领取)  Over(已领取) Close(未达标)
        local n = "Close"
        local l = false
        local s = model:getState(v)
        if s < 0 then
            n = "Close"
        elseif s == 0 then
            n = "Open"
            l = true
            canOpenCount = canOpenCount + 1;
        else
            n = "Over"
        end

        if not self.chestStatus[v] or self.chestStatus[v] ~= n then
            self.chestStatus[v] = n
            -- 状态不一样的时候播放动画
            if self.chestAct[v] then
                self.chestAct[v]:play(n, l)
            end
        end
    end

    -- 能开启的宝箱大于2个显示一键领取
    self.oneKey:setVisible(canOpenCount >= OpenChestCount)
    -- 进度条
    getChild(self.root, "MainPanel/AwardScrollView/LoadingBar_1"):setPercent(rewardCount / ChestCount * 100)
end

function UIGoldTestChest:touchChestCallBack(obj)
    print("touch chest :", obj:getTag())
    obj.soundId = nil
    local s = getGameModel():getGoldTestModel():getState(obj:getTag())
    if s < 0 then
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(GoldTestChestUILanguage.CantReward)):addTo(self)
    elseif s > 0 then
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(GoldTestChestUILanguage.RewardChest)):addTo(self)
    else
        local box = getChild(obj, "AwardBox")
        CommonHelper.playCsbAnimate(box, ResConfig.UIGoldTestChest.Csb2.box, "On", false, function ()
            -- 发送领取的宝箱
            local bufferData = NetHelper.createBufferData(MainProtocol.GoldTest, GoldTestProtocol.ChestStateCS)
            bufferData:writeInt(obj:getTag())
            NetHelper.request(bufferData)
        end)
    end
end

function UIGoldTestChest:onResponeGetChest(mainCmd, subCmd, bufferData)
    local reward = bufferData:readInt()
    local flag = bufferData:readInt()

    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, reward)
    getGameModel():getGoldTestModel():setGoldTestFlag(flag)
    -- 只有金币,特殊处理下
    local awardData = {}
    local dropInfo = {}
	dropInfo.id = UIAwardHelper.ResourceID.Gold
	dropInfo.num = reward
	UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)

    -- 显示奖励
	UIManager.open(UIManager.UI.UIAward, awardData)
    -- 刷新状态
    self:displayChestStatus()
end

function UIGoldTestChest:onClose()
    local respCmd = NetHelper.makeCommand(MainProtocol.GoldTest, GoldTestProtocol.ChestStateSC)
	NetHelper.removeResponeHandler(respCmd, self.onGetChestHandler)
end

return UIGoldTestChest
