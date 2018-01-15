--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-09-7 12:20
** 版  本:	1.0
** 描  述:  召唤师购买提示界面
** 应  用:
********************************************************************/
--]]

local UISummonerBuyTips = class("UISummonerBuyTips", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UISummonerBuyTips:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UISummonerBuyTips:init(...)
    --加载界面
    self.rootPath = ResConfig.UISummonerBuyTips.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 语言包相关
    getChild(self.root, "TipsPanel/TitleText"):setString(getUILanConfItem(281))
    getChild(self.root, "TipsPanel/TipsText"):setString(getUILanConfItem(282))
    getChild(self.root, "TipsPanel/Text_1_0"):setString(getUILanConfItem(283))
    getChild(self.root, "TipsPanel/UnlockButton/ButtonText"):setString(getUILanConfItem(500))

    -- 关闭按钮
    local btnClose = getChild(self.root, "TipsPanel/Button_Close")
    CsbTools.initButton(btnClose, handler(self, self.onClick), nil, nil, "ButtonText")

    -- 确定按钮
    local btnConfirm = getChild(self.root, "TipsPanel/UnlockButton")
    CsbTools.initButton(btnConfirm, handler(self, self.onClick), nil, nil, "ButtonText")
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UISummonerBuyTips:onOpen(openerUIID, summonerID, callback)
    self.summonerID = summonerID
    self.callback = callback

    self.summonerConf = getSaleSummonerConfItem(self.summonerID)

    self:setSummonerBuyInfo()
end

-- 每次界面Open动画播放完毕时回调
function UISummonerBuyTips:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UISummonerBuyTips:onClose()
    self.summonerID = nil
    self.callback = nil
    self.summonerConf = nil

    if self.buySummonerHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Summoner, SummonerProtocol.BuySC)
        NetHelper.removeResponeHandler(cmd, self.buySummonerHandler)
        self.buySummonerHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UISummonerBuyTips:onTop(preUIID, ...)

end

-- 当前界面按钮点击事件
function UISummonerBuyTips:onClick(obj)
    local objName = obj:getName()
    if "Button_Close" == objName then
        UIManager.close()
    elseif "UnlockButton" == objName then
        obj.soundId = nil
        -- 判断vip是否达到
        if self.summonerConf ~= nil then
            -- 判断是否有足够的货币购买召唤师
            if self.summonerConf.Type == 2 then
                local userGold = getGameModel():getUserModel():getGold()
                if userGold >= self.summonerConf.Num then
                    self:sendBuySummonerCmd()
                else
                    obj.soundId = MusicManager.commonSound.fail
                    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(572))
                end
            elseif self.summonerConf.Type == 1 then
                local userDiamond = getGameModel():getUserModel():getDiamond()
                if userDiamond >= self.summonerConf.Num then
                    self:sendBuySummonerCmd()
                else
                    obj.soundId = MusicManager.commonSound.fail
                    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
                end
            end
        else
            print("self.summonerConf is nil")
        end
    end
end

-- 设置召唤师购买信息
function UISummonerBuyTips:setSummonerBuyInfo()
    local heroConf = getHeroConfItem(self.summonerID)

    -- 召唤师头像
    local summonerHead = getChild(self.root, "TipsPanel/FileNode_1")
    CommonHelper.playCsbAnimate(summonerHead, "ui_new/g_gamehall/b_bag/HeroItem.csb", "Summoner", false, nil, true)
    local iconImg = getChild(summonerHead, "Item/Icon")
	local frameImg = getChild(summonerHead, "Item/Level")
	CsbTools.replaceImg(iconImg, heroConf.Common.HeadIcon)
	CsbTools.replaceImg(frameImg, IconHelper.getSoldierHeadFrame(5))
    -- 召唤师名称
    local summonerName = getChild(self.root, "TipsPanel/NameText")
    summonerName:setString(getHSLanConfItem(heroConf.Common.Name))
    -- 召唤师价格
    local summonerPrice = getChild(self.root, "TipsPanel/PriceLabel")
    summonerPrice:setString(self.summonerConf.Num)
    -- 召唤师购买货币类型
    local coinImage = getChild(self.root, "TipsPanel/Image_bg/pub_gem_15")
    if self.summonerConf.Type == 1 then
        coinImage:setSpriteFrame("pub_gem.png")
    elseif self.summonerConf.Type == 2 then
        coinImage:setSpriteFrame("pub_gold.png")
    end
end

-- 发送购买召唤师请求
function UISummonerBuyTips:sendBuySummonerCmd()
    -- 注册购买召唤师命令
    local cmd = NetHelper.makeCommand(MainProtocol.Summoner, SummonerProtocol.BuySC)
    self.buySummonerHandler = handler(self, self.acceptBuySummonerCmd)
    NetHelper.setResponeHandler(cmd, self.buySummonerHandler)

    -- 发送命令
    local buffData = NetHelper.createBufferData(MainProtocol.Summoner, SummonerProtocol.BuyCS)
    buffData:writeInt(self.summonerID)
    NetHelper.request(buffData)
end

-- 接收购买召唤师请求
function UISummonerBuyTips:acceptBuySummonerCmd(mainCmd, subCmd, buffData)
    -- 注销购买召唤师请求
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.buySummonerHandler)
    self.buySummonerHandler = nil

    local tp = buffData:readInt()   -- 货币类型
    local num = buffData:readInt()  -- 货币数量

    -- 扣除消费
    if tp == 1 then
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -num)
    elseif tp == 2 then
        ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -num)
    end
    -- 添加召唤师
    ModelHelper.AddSummoner(self.summonerID)
    -- 添加头像
    if self.summonerConf then
        ModelHelper.addHead(self.summonerConf.HeadID)
    end

    if self.callback and "function" == type(self.callback) then
        self.callback()
    end

    -- 显示召唤师
    UIManager.replace(UIManager.UI.UIShowSummoner, self.summonerID)
end

return UISummonerBuyTips