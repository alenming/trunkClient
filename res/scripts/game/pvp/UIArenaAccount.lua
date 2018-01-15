--[[
竞技场结算界面(失败、胜利界面)
]]

local PropTips = require("game.comm.PropTips")
local UIArenaAccount = class("UIArenaAccount", function ()
	return require("common.UIView").new()
end)

local ArenaAccountLanguage = {
    historyRank = 830, 
    curRank = 831, 
    confirm = 500, 
    breakHistoryRank = 837, 
    rewardSendMail = 838,
    rankBreak = 843,
    historyNewRank = 844,
    gradingCount = 1902,
    gradingFinish = 1903,
    gradingIntegral = 1904,
    aiWinTips = 636,
}

function UIArenaAccount:ctor()
    self.propTips = PropTips.new()
end

function UIArenaAccount:init(resultData)
    -- 谁来解释一下为什么要设置 ZOrder ？
    --self:setGlobalZOrder(5)
	--self:setLocalZOrder(5)
    self.UICsb = ResConfig.UIArenaAccount.Csb2

    self.resultData = resultData
    if 1 == resultData.battleResult then
        self.rootPath = self.UICsb.arenaWin
        self.root = getResManager():getCsbNode(self.rootPath)
        self:addChild(self.root)
        self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
        self.root:runAction(self.rootAct)

        self:showWin(resultData)
    elseif 0 == resultData.battleResult then
        self.rootPath = self.UICsb.arenaFailure
        self.root = getResManager():getCsbNode(self.rootPath)
        self:addChild(self.root)
        self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
        self.root:runAction(self.rootAct)

        self:showLose(resultData)
    else
        self.rootPath = self.UICsb.arenaDogfall
        self.root = getResManager():getCsbNode(self.rootPath)
        self:addChild(self.root)
        self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
        self.root:runAction(self.rootAct)

        self:showDraw(resultData)
    end

    -- common
    local confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfirmButtom")
    CsbTools.initButton(confirmBtn, handler(self, self.clickCallBack), 
        CommonHelper.getUIString(ArenaAccountLanguage.confirm), "ConfirmButtom/NameLabel", "ConfirmButtom")

    if 1 == resultData.pvpType or 0 == resultData.pvpType then
        self.shareBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ShareButton")    
        self.applyBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ApplyRankButton")
        self.shareLab = CsbTools.getChildFromPath(self.shareBtn, "Text")
        self.applyLab = CsbTools.getChildFromPath(self.applyBtn, "Text")
        CsbTools.initButton(self.shareBtn, handler(self, self.shareBtnCallBack))
        CsbTools.initButton(self.applyBtn, handler(self, self.relayBtnCallBack))

        local shareConf = getPVPShareConfig()
        local uploadConf = getPVPUploadConfig()
        local shareValidCount = shareConf.BattleShareCount - 1
        local applyValidCount = uploadConf.ApplyCount - 0
        self.shareLab:setString(string.format(CommonHelper.getUIString(2182), shareValidCount))
        self.applyLab:setString(string.format(CommonHelper.getUIString(2183), applyValidCount))
        if getGameModel():getUnionModel():getHasUnion() then
            self.shareBtn:setTouchEnabled(true)
            self.shareBtn:setBright(true)
        else
            self.shareBtn:setTouchEnabled(false)
            self.shareBtn:setBright(false)
        end
        
        if resultData.rankNow <= getPVPUploadConfig().ApplyRank and applyValidCount > 0 then
            self.applyBtn:setVisible(true)
        else
            self.applyBtn:setVisible(false)
        end
    end

    print("rankinfo", resultData.rankDV, resultData.integralDV, resultData.integral, resultData.historyRank, resultData.rankNow, resultData.pvpType)
end

--显示成功
function UIArenaAccount:showWin(resultData)
    local listView = CsbTools.getChildFromPath(self.root, "MainPanel/AwardListView")
    if -1 == resultData.pvpType then
        self:hideRankPanel()
        local aiWinTips = CsbTools.getChildFromPath(self.root, "MainPanel/AIWinTips")
        aiWinTips:setVisible(true)
        aiWinTips:setString(CommonHelper.getUIString(ArenaAccountLanguage.aiWinTips))
        self.rootAct:play("Open", false)
        listView:setContentSize(0, listView:getContentSize().height)
        return
    elseif 1 == resultData.pvpType then
        self:showChampionGrading(resultData.extend, resultData.integral)
        if not resultData.isShow then
            self:hideRankPanel()
            self.rootAct:play("Open", false)
            return
        end
    end

    self.rootAct:play("Open", false)

    CsbTools.getChildFromPath(self.root, "MainPanel/HistoryRankingPanel/HistoryTipsBar/Tips1")
        :setString(CommonHelper.getUIString(ArenaAccountLanguage.rankBreak))
    CsbTools.getChildFromPath(self.root, "MainPanel/HistoryRankingPanel/HistoryTipsBar/Tips2")
        :setString(CommonHelper.getUIString(ArenaAccountLanguage.historyNewRank))
    CsbTools.getChildFromPath(self.root, "MainPanel/HistoryRankingPanel/RankingTips")
        :setString(CommonHelper.getUIString(ArenaAccountLanguage.curRank))
    -- 竞技排名
    CsbTools.getChildFromPath(self.root, "MainPanel/HistoryRankingPanel/CoinNum"):setString(resultData.rankNow)
    -- 竞技积分
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/CoinNum"):setString(resultData.integral)
    -- 增加积分
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/AddNum"):setString("+" .. math.abs(resultData.integralDV))

    -- 显示相关数值信息
    local arenaRankItem = getArenaRankItem(resultData.integral)
    if arenaRankItem then
        --CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/GuildIcon"):loadTexture(arenaRankItem.GNPic, 1)
    end

    local itemCount = #resultData.dropInfo
    local resourceCount = 6
    for i = 1, resourceCount do
        local item = CsbTools.getChildFromPath(self.root, "MainPanel/AwardListView/Button_"..i.."/AwardItem")
        if i > itemCount then
            item:setVisible(false)
        else
            local propConfItem = getPropConfItem(resultData.dropInfo[i].id)
            UIAwardHelper.setAllItemOfConf(item, 
                propConfItem, 
                resultData.dropInfo[i].num)

            local touchNode = CsbTools.getChildFromPath(item, "MainPanel")
    	    self.propTips:addPropTips(touchNode, propConfItem)
        end
    end

    listView:setContentSize(itemCount*100, listView:getContentSize().height)

    EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
end

--显示失败
function UIArenaAccount:showLose(resultData)
    -- 如果是时间到的时候,显示"对方血量占优"
    local roomModel = getGameModel():getRoom()
    local settleModel = roomModel:getSettleAccount()
    local stageId = roomModel:getStageId()
    local tick = settleModel:getTick()

    local stageConf = getStageConfItem(stageId)
    if stageConf and tick >= stageConf.TimeLimit then
        CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/Tips"):setVisible(true)
    else
        CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/Tips"):setVisible(false)
    end

    if 1 == resultData.pvpType then
        self:showChampionGrading(resultData.extend, resultData.integral)
    end

    if -1 == resultData.pvpType
      or (1 == resultData.pvpType and not resultData.isShow) then
        self:hideRankPanel()
    else
        -- 竞技积分
        CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/CoinNum"):setString(resultData.integral)
        -- 减少积分
        CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/AddNum"):setString("-"..math.abs(resultData.integralDV))
    end

    self.rootAct:play("Open", false)
end

--显示平局
function UIArenaAccount:showDraw(resultData)
    if 1 == resultData.pvpType then
        self:showChampionGrading(resultData.extend, resultData.integral)
    end

    if -1 == resultData.pvpType
      or (1 == resultData.pvpType and not resultData.isShow) then
        self:hideRankPanel()
    else
        -- 积分显示
        CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/CoinNum"):setString(resultData.integral)
        -- 显示相关数值信息
        local arenaRankItem = getArenaRankItem(resultData.integral)
        if arenaRankItem then
            --CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel/GuildIcon"):loadTexture(arenaRankItem.GNPic, 1)
        end
    end
    
    -- 提示平局
    CsbTools.getChildFromPath(self.root, "MainPanel/TimeUpTips"):setString(CommonHelper.getUIString(846))
    self.rootAct:play("Open", false)
end

function UIArenaAccount:clickCallBack(obj)
    self.propTips:removePropAllTips()
	self.propTips = nil
    -- 在清理之前获得重连状态, 清理之后为false
    --local pvpModel = getGameModel():getPvpModel()
    --local isReconnect = pvpModel:isReconnect()
    -- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
    finishBattle()
	-- 如果不是从登录场景进入, 就进入上个场景, 否则加载大厅场景
	if SceneManager.PrevScene ~= nil and SceneManager.PrevScene ~= SceneManager.Scene.SceneLogin then
        --print("prev scene and isReconnect", SceneManager.PrevScene, isReconnect)
	    SceneManager.loadScene(SceneManager.PrevScene)
	else
	    SceneManager.loadScene(SceneManager.Scene.SceneHall)
	end 
end

function UIArenaAccount:shareBtnCallBack(obj)
    self.shareBtn:setTouchEnabled(false)
    self.shareBtn:setBright(true)
    UIManager.open(UIManager.UI.UIShareDialog, obj:getTag(), handler(self, self.shareDialogCallBack))
end

function UIArenaAccount:shareDialogCallBack(battleID, shareSucess, shareDesc)
    print("battleID, shareSucess, shareDesc", battleID, shareSucess, shareDesc)
    if battleID == nil or shareSucess == nil or shareDesc == nil then
        return
    end

    self.shareBtn:setTouchEnabled(not shareSucess)
    self.shareBtn:setBright(not shareSucess)

    if shareSucess then
        CsbTools.addTipsToRunningScene(string.format("成功分享 battleid: %d", battleID))
    else
        CsbTools.addTipsToRunningScene(string.format("取消分享 battleid: %d", battleID))
    end
end

function UIArenaAccount:relayBtnCallBack(obj)
    self.applyBtn:setTouchEnabled(false)
    self.applyBtn:setBright(false)
    print("发送申请上传协议")
end

function UIArenaAccount:hideRankPanel()
    CsbTools.getChildFromPath(self.root, "MainPanel/RankingPanel"):setVisible(false)
end

function UIArenaAccount:showChampionGrading(gradingNum, integral)
    local gradingNumLb = CsbTools.getChildFromPath(self.root, "MainPanel/LevelTips")
    local integralTips = CsbTools.getChildFromPath(self.root, "MainPanel/LevelCoinTips")
    if gradingNum > 0 then
        gradingNumLb:setVisible(true)
        local tips = string.format(CommonHelper.getUIString(ArenaAccountLanguage.gradingCount), gradingNum)
        gradingNumLb:setString(tips)
    elseif gradingNum == 0 then
        gradingNumLb:setVisible(true)
        integralTips:setVisible(true)
        gradingNumLb:setString(CommonHelper.getUIString(ArenaAccountLanguage.gradingFinish))
        local tips = CommonHelper.getUIString(ArenaAccountLanguage.gradingIntegral)
        integralTips:setString(tips .. integral)
    else
        gradingNumLb:setVisible(false)
    end
end

return UIArenaAccount