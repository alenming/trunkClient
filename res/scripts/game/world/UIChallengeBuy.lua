--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  精英关卡次数购买提示界面
** 应  用:
********************************************************************/
--]]

local UIChallengeBuy = class("UIChallengeBuy", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIChallengeBuy:ctor()
    self.rootPath = ResConfig.UIChallengeBuy.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    --local cancel = getChild(self.root, "CancelButton")
    local cancel = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
    -- cancel:addClickEventListener(function()
    --     self.chapterID = nil
    --     self.stageID = nil
    --     local node = getChild(cancel, "Button_Cancel")
    --     CommonHelper.playCsbAnimate(node, ResConfig.UIChallenge.Csb2.cancel, "On", false, function()
    --         UIManager.close()
    --     end)
    -- end)
   CsbTools.initButton(cancel, function()
        self.chapterID = nil
        self.stageID = nil
        UIManager.close()
    end, nil, nil, "Text")

   -- local commit = getChild(self.root, "ConfrimButton")
    local commit = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
    -- commit:addClickEventListener(function()
    --     local node = getChild(commit, "Button_Confrim")
    --     CommonHelper.playCsbAnimate(node, ResConfig.UIChallenge.Csb2.commit, "On", false, function()
    --         if getGameModel():getUserModel():getDiamond() < self.buyPrice then
    --             -- 进入充值提示界面
    --             CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
    --         else
    --             self:sendBuyCmd()
    --         end
    --     end)
    -- end)

   CsbTools.initButton(commit, function()
        if getGameModel():getUserModel():getDiamond() < self.buyPrice then
            -- 进入充值提示界面
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
        else
            self:sendBuyCmd()
        end
    end, nil, nil, "Text")

    self.totalCount = #getIncreasePayItemList()
end


-- 当界面被创建时回调
-- 只初始化一次
function UIChallengeBuy:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIChallengeBuy:onOpen(openerUIID, chapterID, stageID)
    self.chapterID = chapterID
    self.stageID = stageID
print("UIChallengeBuy:onOpen -- chapterID ", self.chapterID)
print("UIChallengeBuy:onOpen -- stageID ", self.stageID)
    -- 价格
    self.buyPrice = 0
    local boughtCount = getGameModel():getStageModel():getEliteBuyCount(self.stageID)

    local conf = getIncreasePayConfItem(boughtCount < self.totalCount and (boughtCount + 1) or self.totalCount)
    self.buyPrice = conf.ChallengeCost

    local gem = getChild(self.root, "BuyEnergyPanel/PowerLabel_0")
    gem:setString(self.buyPrice)

    -- 次数
    local tip = getChild(self.root, "BuyEnergyPanel/TipLabel3")
    tip:setString(string.format(getUILanConfItem(393), boughtCount, self.totalCount))
end

-- 每次界面Open动画播放完毕时回调
function UIChallengeBuy:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIChallengeBuy:onClose()
    if self.buyHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.BuyTimesSC)
        NetHelper.removeResponeHandler(cmd, self.buyHandler)
        self.buyHandler = nil
    end

    return self.chapterID, self.stageID
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIChallengeBuy:onTop(preUIID, ...)

end

function UIChallengeBuy:getRoot()
	return self.root
end

function UIChallengeBuy:getRootPath()
	return self.rootPath
end

-- 发送购买请求
function UIChallengeBuy:sendBuyCmd()
    -- 注册购买命令
    local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.BuyTimesSC)
    self.buyHandler = handler(self, self.acceptBuyCmd)
    NetHelper.setResponeHandler(cmd, self.buyHandler)
print("UIChallengeBuy:sendBuyCmd -- chapterID ", self.chapterID)
print("UIChallengeBuy:sendBuyCmd -- stageID ", self.stageID)
    local buffData = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.BuyTimesCS)
    buffData:writeInt(self.chapterID)
    buffData:writeInt(self.stageID)
    NetHelper.request(buffData)
end

-- 接收购买请求
function UIChallengeBuy:acceptBuyCmd(mainCmd, subCmd, buffData)
    -- 注销购买命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.buyHandler)
    self.buyHandler = nil
print("UIChallengeBuy:acceptBuyCmd 1 -- chapterID ", self.chapterID)
print("UIChallengeBuy:acceptBuyCmd 1 -- stageID ", self.stageID)
    local chapterID = buffData:readInt()
    local stageID = buffData:readInt()
    local add = buffData:readInt() --每次购买的挑战次数
print("UIChallengeBuy:acceptBuyCmd 2 -- chapterID ", chapterID)
print("UIChallengeBuy:acceptBuyCmd 2 -- stageID ", stageID)
print("UIChallengeBuy:acceptBuyCmd 2 -- add ", add)
    -- 设置挑战次数和购买次数
    local challengedCount = getGameModel():getStageModel():getEliteChallengeCount(self.stageID)
    getGameModel():getStageModel():setEliteChallengeCount(self.stageID, challengedCount - add)
    local boughtCount = getGameModel():getStageModel():getEliteBuyCount(self.stageID)
    getGameModel():getStageModel():setEliteBuyCount(self.stageID, boughtCount + 1)
    
    -- 扣除钻石
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -self.buyPrice)

    UIManager.close()
end

return UIChallengeBuy