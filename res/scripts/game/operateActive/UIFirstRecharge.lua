--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-11-08 1:10
** 版  本:	1.0
** 描  述:  首充奖励
** 应  用:
********************************************************************/
--]]

local userModel = getGameModel():getUserModel()

local PropTips = require("game.comm.PropTips")

local UIFirstRecharge = class("UIFirstRecharge", function()
    return require("common.UIView").new()
end)

function UIFirstRecharge:ctor()
    self.rootPath = ResConfig.UIFirstRecharge.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local closeBtn = getChild(self.root, "MainPanel/CloseButton")   -- 关闭按钮
    CsbTools.initButton(closeBtn, handler(self, self.onClick))
    local backBtn = getChild(self.root, "BackButton")   -- 关闭按钮
    CsbTools.initButton(backBtn, handler(self, self.onClick))
end

-- 当界面被创建时回调
-- 只初始化一次
function UIFirstRecharge:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIFirstRecharge:onOpen(openerUIID, ...)
    self.propTips = PropTips.new()

    self.firstPayData = GetFirstPayData()
    if not self.firstPayData then
        return
    end

    -- 奖励状态(0：未领取, 1：已领取)
    self.firstPayFlag = userModel:getFirstPayFlag()
    self:setMoneyPanel()
    self:initFirstCharge()
end

-- 每次界面Open动画播放完毕时回调
function UIFirstRecharge:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIFirstRecharge:onClose()
    self.propTips:removePropAllTips()
    self.propTips = nil
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIFirstRecharge:onTop(preUIID, ...)
    local flag = userModel:getFirstPayFlag()

    -- 首充状态有变
    if self.firstPayFlag ~= flag then
        self.firstPayFlag = flag
        --
        if 1 == flag then
            RedPointHelper.addBoonRed()
        else
            RedPointHelper.addCount(RedPointHelper.System.Boon, -1)
        end
    end

    self:setMoneyPanel()
    self:initFirstCharge()
end

-- 当前界面按钮点击回调
function UIFirstRecharge:onClick(obj)
    local btnName = obj:getName()
    if "BackButton" == btnName then
        UIManager.close()
    elseif "CloseButton" == btnName then
        UIManager.close()
    end
end

-- 设置货币面板
function UIFirstRecharge:setMoneyPanel()
    local goldCountLabel    = getChild(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
    local gemCountLabel     = getChild(self.root, "GemInfo/GemPanel/GemCountLabel")
    goldCountLabel:setString(tostring(userModel:getGold()))
    gemCountLabel:setString(tostring(userModel:getDiamond()))
end

-- 初始化首充面板
function UIFirstRecharge:initFirstCharge()
    local goodsID = self.firstPayData.GoodsID
    local goodsNum = self.firstPayData.GoodsNum
    -- 初始化首充奖励
    for i = 1, 4 do
        local id = goodsID[i] or 0
        local num = goodsNum[i] or 0
        local propConf = getPropConfItem(id)
        if propConf then
            -- 道具图片
            local allItem = getChild(self.root, "MainPanel/AllItem_" .. i)
            UIAwardHelper.setAllItemOfConf(allItem, propConf, num)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        else
            getChild(self.root, "MainPanel/AllItem_" .. i):setVisible(false)
        end
    end

    local node = getChild(self.root, "MainPanel/ButtonState")
    local vipPayment = getGameModel():getUserModel():getPayment()
    if vipPayment and vipPayment > 0 then
        if 0 == self.firstPayFlag then
            CommonHelper.playCsbAnimation(node, "Green", false, nil)
        else
            CommonHelper.playCsbAnimation(node, "Grey", false, nil)
        end
    else
        CommonHelper.playCsbAnimation(node, "Orange", false, nil)
    end

    local function onClick(obj)
        local btnName = obj:getName()
        -- 充值
        if "Button_Orange" == btnName then
            UIManager.open(UIManager.UI.UIShop, ShopType.DiamondShop)
        -- 领奖
        elseif "Button_Green" == btnName then
            self:sendFirstChargeCmd()
        end
    end
    local chargeBtn = getChild(node, "Button_Orange")
    CsbTools.initButton(chargeBtn, onClick)
    local chargeText = getChild(chargeBtn, "Text")
    chargeText:setString(CommonHelper.getUIString(23))
    local getBtn = getChild(node, "Button_Green")
    CsbTools.initButton(getBtn, onClick)
    local getText = getChild(getBtn, "Text")
    getText:setString(CommonHelper.getUIString(329))
    getChild(node, "Button_Grey/Text"):setString(CommonHelper.getUIString(503))
end

-- 发送领取首充奖励请求
function UIFirstRecharge:sendFirstChargeCmd()
    local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.FirstChargeCS)
    NetHelper.requestWithTimeOut(buffData,
        NetHelper.makeCommand(MainProtocol.User, UserProtocol.FirstChargeSC),
        handler(self, self.acceptFirstChargeCmd))
end

-- 接收领取首充奖励请求
function UIFirstRecharge:acceptFirstChargeCmd(mainCmd, subCmd, buffData)
    local flag = buffData:readInt()
    userModel:setFirstPayFlag(flag)
    self.firstPayFlag = flag
    self:initFirstCharge()

    -- 显示奖励
    local goodsID = self.firstPayData.GoodsID
    local goodsNum = self.firstPayData.GoodsNum
    local awardData = {}
    local dropInfo = {}
    for i = 1, 4 do
        local id = goodsID[i]
        if not id or id <= 0 then
            break
        end
        local num = goodsNum[i]
        if not num or num <= 0 then
            break
        end
        dropInfo.id = id
        dropInfo.num = num
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end
    if awardData and #awardData > 0 then
        UIManager.open(UIManager.UI.UIAward, awardData)
    end
end


return UIFirstRecharge