local scheduler = require("framework.scheduler")

local gameModel = getGameModel()
local userModel = gameModel:getUserModel()
local pvpModel = gameModel:getPvpModel()
local pvpChestModel = gameModel:getPvpChestModel()

local UIArena = class("UIArena", function ()
	return require("common.UIView").new()
end)

------------ UIView override begin -------------

function UIArena:init()
    self.rootPath = ResConfig.UIArena.Csb2.arenaNew
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.background = CsbTools.getChildFromPath(self.root, "Background")

    self.maskPanel = CsbTools.getChildFromPath(self.root, "MaskPanel")
    self.maskPanel:addClickEventListener(handler(self, self.clickMaskPanelCallback))

    self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")

    self.summonerBg = CsbTools.getChildFromPath(self.background, "SummonerBg")

    self.moneyPanel = CsbTools.getChildFromPath(self.mainPanel, "MoneyPanel")
    self.goldCountLabel = CsbTools.getChildFromPath(self.moneyPanel, "MoneyPanel/GoldCountLabel")
    self.gemCountLabel = CsbTools.getChildFromPath(self.moneyPanel, "MoneyPanel/GemCountLabel")

    self.chestPanel = CsbTools.getChildFromPath(self.mainPanel, "ChestPanel")

    self.tipsText = CsbTools.getChildFromPath(self.chestPanel, "TipsText")
    --self.tipsText:setString("")

    self.userBar = CsbTools.getChildFromPath(self.mainPanel, "UserBar")
    self.tLevelButton = CsbTools.getChildFromPath(self.userBar, "TLevelButton")
    CsbTools.initButton(self.tLevelButton, handler(self, self.onTLevel))
    self.userName = CsbTools.getChildFromPath(self.userBar, "Name")
    self.userRank = CsbTools.getChildFromPath(self.userBar, "RankingNum")
    self.level = CsbTools.getChildFromPath(self.tLevelButton, "Level")
    self.expLoadingBar = CsbTools.getChildFromPath(self.userBar, "ExpLoadingBar")
    self.expLoadingNum = CsbTools.getChildFromPath(self.userBar, "LoadingNum")

    ---------- Button ----------

    self.backButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(self.backButton, handler(self, self.clickBackButtonCallback))

    self.matchingButton = CsbTools.getChildFromPath(self.mainPanel, "MatchingButton")
    CsbTools.initButton(self.matchingButton, handler(self, self.clickMatchingButtonCallback))

    self.rankingButton = CsbTools.getChildFromPath(self.mainPanel, "RankingButton")
    CsbTools.initButton(self.rankingButton, handler(self, self.clickRankingButtonCallback))

    self.trialButton = CsbTools.getChildFromPath(self.mainPanel, "TrialButton")
    CsbTools.initButton(self.trialButton, handler(self, self.clickTrialButtonCallback))
    CsbTools.getChildFromPath(self.trialButton, 
        "RankingButton/ButtonPanel/NameText"):setString(getUILanConfItem(2176))
    CsbTools.getChildFromPath(self.trialButton, 
        "RankingButton/ButtonPanel/ButtonImage"):loadTexture("icon_Trial.png", 1)

    self.replayButton = CsbTools.getChildFromPath(self.mainPanel, "ReplayButton")
    CsbTools.initButton(self.replayButton, handler(self, self.clickReplayButtonCallback))
    CsbTools.getChildFromPath(self.replayButton, 
        "RankingButton/ButtonPanel/NameText"):setString(getUILanConfItem(2177))
    CsbTools.getChildFromPath(self.replayButton, 
        "RankingButton/ButtonPanel/ButtonImage"):loadTexture("button_playback.png", 1)

    self.questionButton = CsbTools.getChildFromPath(self.mainPanel, "QuestionButton")
    CsbTools.initButton(self.questionButton, handler(self, self.clickQuestionButtonCallback))

    self.chestButtons = {}
    self.chestButtonActions = {}
    self.chestButtonTips = {}
    for i = 1, 5 do
        self.chestButtons[i] = CsbTools.getChildFromPath(self.chestPanel, "ChestButton_" .. i)
        CsbTools.initButton(self.chestButtons[i], handler(self, self.clickChestButtonCallback))

        self.chestButtonActions[i] = cc.CSLoader:createTimeline(ResConfig.UIArena.Csb2.chestNew)
        self.chestButtonActions[i]:play("Add", false)
        local chestBoxBar = CsbTools.getChildFromPath(self.chestButtons[i], "ChestBoxBar")
        chestBoxBar:runAction(self.chestButtonActions[i])

        self.chestButtonTips[i] = getChild(chestBoxBar, "TipsBar")

        CsbTools.getChildFromPath(chestBoxBar, "ChestPanel"):setTouchEnabled(false)
        CsbTools.getChildFromPath(chestBoxBar, "ChestPanel/CutPanel"):setTouchEnabled(false)
    end
end

function UIArena:onOpen()
	self:updateGoldAndGem()
	self:updateBackground()
	self:updateRankingInfo()
    self:updateChestButtons()

    self:addNetworkListener()
    self:addGameEventListener()
end

function UIArena:onOpenAniOver()
    -- updateReadyGetChest 要放到 onOpenAniOver 中，因为它要执行 OpenChest 动画，
    -- 就必须在 Open 动画之后。
    self:updateReadyGetChest()
end

function UIArena:onClose()
    self:removeNetworkListener()
    self:removeGameEventListener()

    self:closeWaitTimeSchedule()
end

------------ UIView override end -------------

------------ Button callback begin --------------

function UIArena:clickBackButtonCallback()
	UIManager.close()
end

function UIArena:clickMatchingButtonCallback()
	UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds)
        --发送队伍设置
        BattleHelper.sendTeamSet(ModelHelper.teamType.Arena, summonerId, heroIds)
        --结束后返回竞技场界面
        UIManager.saveToLastUI(UIManager.UI.UIArena)
        
       	pvpModel:setRoomType(1)
        SceneManager.loadScene(SceneManager.Scene.ScenePvp)
    end, 1)
end

function UIArena:clickRankingButtonCallback()
	UIManager.open(UIManager.UI.UIRank, RankData.rankType.arena)
end

function UIArena:clickChestButtonCallback(obj)
    local name = obj:getName()
    local btnTag = tonumber(string.sub(name, -1))

    local chestList = pvpChestModel:getChests()

    if btnTag <= #chestList then
        for i = 1, #chestList do
            local tipsBar = self.chestButtonTips[i]
            if btnTag == i then
                tipsBar:setVisible(true)
                tipsBar:runAction(cc.Sequence:create(
                    cc.DelayTime:create(2.5),
                    cc.CallFunc:create(function () 
                        self.chestButtonTips[btnTag]:setVisible(false)
                    end)
                ))
            else
                tipsBar:stopAllActions()
                tipsBar:setVisible(false)
            end
        end
    else
        CommonHelper.checkConsumeCallback(2, getArenaSetting().Arena_ChestPrice, function ()
            -- 二次提示框
            local params = {}
            params.msg = CommonHelper.getUIString(2140)
            params.confirmFun = function () 
                local buffData = NetHelper.createBufferData(MainProtocol.PvpChest, PvpChestProtocol.BuyChestCS)
                NetHelper.request(buffData)
            end
            params.cancelFun = function () UIManager.close() end

            UIManager.open(UIManager.UI.UIDialogBox, params)
        end, nil, true)
    end
end

function UIArena:clickTrialButtonCallback()
    UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds)
        --发送队伍设置
        BattleHelper.sendTeamSet(ModelHelper.teamType.Arena, summonerId, heroIds)
        --结束后返回竞技场界面
        UIManager.saveToLastUI(UIManager.UI.UIArena)
        
        local trainings = getArenaTrainings()
        local stageId = trainings[math.random(1, #trainings)] 
        if 0 == stageId then
            -- 0为要随机,在之前的表中随机一个
            stageId = trainings[math.random(1, #trainings - 1)]
        end

        local stageInfo = {}
        stageInfo.stageId = stageId
        stageInfo.stageLv = userModel:getUserLevel()
        stageInfo.battleType = 1 -- 当作章节关卡
        local PvpBattle = require("game.battle.PvpBattle")
        BattleHelper.challengeComputer(summonerId, heroIds, stageInfo, handler(PvpBattle, PvpBattle.onPvpComputerBattleOver))
    end, 1)
end

-- 回放
function UIArena:clickReplayButtonCallback()
    UIManager.open(UIManager.UI.UIReplayChannel)
end

function UIArena:clickQuestionButtonCallback()
    UIManager.open(UIManager.UI.UIArenaRule)
end

function UIArena:onTLevel()
    local tLevel = 1
    local arenaRankItem = getArenaRankItem(pvpModel:getPvpInfo().Score)
    if arenaRankItem then
        tLevel = arenaRankItem.GroupNumber
    end
    UIManager.open(UIManager.UI.UIArenaLevelUnlock, tLevel)
end

------------ Button callback end --------------

------------ Click event listener begin -------------

function UIArena:clickMaskPanelCallback()
    local chestList = pvpChestModel:getChests()
    local buffData = NetHelper.createBufferData(MainProtocol.PvpChest, PvpChestProtocol.OpenChestCS)
    buffData:writeInt(chestList[1])
    NetHelper.request(buffData)
end

------------ Click event listener end -------------

------------ Network listener begin -----------

-- 添加网络监听
function UIArena:addNetworkListener()
    local buyChestCmd = NetHelper.makeCommand(MainProtocol.PvpChest, PvpChestProtocol.BuyChestSC)
    self.onBuyChestHandler = handler(self, self.onBuyChest)
    NetHelper.addResponeHandler(buyChestCmd, self.onBuyChestHandler)

    local openChestCmd = NetHelper.makeCommand(MainProtocol.PvpChest, PvpChestProtocol.OpenChestSC)
    self.onOpenChestHandler = handler(self, self.onOpenChest)
    NetHelper.addResponeHandler(openChestCmd, self.onOpenChestHandler)
end

-- 移除网络监听
function UIArena:removeNetworkListener()
    local buyChestCmd = NetHelper.makeCommand(MainProtocol.PvpChest, PvpChestProtocol.BuyChestSC)
    NetHelper.removeResponeHandler(buyChestCmd, self.onBuyChestHandler)

    local openChestCmd = NetHelper.makeCommand(MainProtocol.PvpChest, PvpChestProtocol.OpenChestSC)
    NetHelper.removeResponeHandler(openChestCmd, self.onOpenChestHandler)
end

-- 监听购买宝箱
function UIArena:onBuyChest(_, _, data)
    local chestId = data:readInt()
    local costDiamond = data:readInt()

    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -costDiamond)

    local pvpInfo = pvpModel:getPvpInfo()
    pvpModel:setDayBuyChestTimes(pvpInfo.DayBuyChestTimes + 1)
    pvpChestModel:addChest(chestId)

    self.isBoughtNewChest = true -- 是否购买了一个新的宝箱，如果是，则那个宝箱要先播放一段特别的动画

    self:updateGoldAndGem()
    self:updateChestButtons()
end

-- 监听打开宝箱
function UIArena:onOpenChest(_, _, data)
    local chestId = data:readInt()
    local count = data:readInt()
    local awardData = {}
    local dropInfo = {}
    for i = 1, count do
        dropInfo.id = data:readInt()
        dropInfo.num = data:readInt()
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end

    if #awardData > 0 then
        UIManager.open(UIManager.UI.UIAward, awardData)
    end

    -- 设置宝箱为不可领取
    pvpModel:setChestStatus(0)

    local pvpInfo = pvpModel:getPvpInfo()
    -- 设置倒计时间
    if pvpInfo.LastChestTime == 0 then
        local now = gameModel:getNow()
        pvpModel:setLastChestTime(now)
    end

    -- 移除宝箱(第一个)
    if not pvpChestModel:popChest(chestId) then
        print(">>>remove pvp chest fail!!! maybe open chest isn't first", chestId)
        return
    end

    RedPointHelper.addCount(RedPointHelper.System.Arena, -1, RedPointHelper.AreanSystem.ArenaChest)
    
    self:updateChestButtons()
    self:updateReadyGetChest()
end

------------ Network listener end -----------

------------ Event listener begin -----------

function UIArena:addGameEventListener()
    self.refreshChestEventHandler = handler(self, self.onRefreshChest)
    EventManager:addEventListener(GameEvents.EventUpdatePvpChest, self.refreshChestEventHandler)
end

function UIArena:removeGameEventListener()
    EventManager:removeEventListener(GameEvents.EventUpdatePvpChest, self.refreshChestEventHandler)
end

-- 刷新宝箱个数
function UIArena:onRefreshChest()
    self:updateChestButtons()
    self:updateReadyGetChest()
end

------------ Event listener end -----------

------------ Update UI begin -------------

-- 刷新金币与钻石
function UIArena:updateGoldAndGem()
	self.goldCountLabel:setString(userModel:getGold())
	self.gemCountLabel:setString(userModel:getDiamond())
end

-- 刷新背景
function UIArena:updateBackground()
	local summonerId = TeamHelper.getTeamInfo()
	local cfgItem = getSaleSummonerConfItem(summonerId)
	if cfgItem then
		local csbName = cfgItem.Bg_Name
		local newBg = getResManager():getCsbNode(
			"ui_new/p_public/effect/hero_" .. summonerId .. "_Ult/" .. csbName
		)
		if newBg then
			local size = self.background:getContentSize()
			newBg:setName("SummonerBg")
			newBg:setPosition(cc.p(size.width / 2, size.height / 2))

			self.background:removeChildByName("SummonerBg")
			self.background:addChild(newBg)

			self.summonerBg = newBg
		end
	end
end

-- 刷新排名信息
function UIArena:updateRankingInfo()
	self.userName:setString(userModel:getUserName())

	local userLevelConfItem = getUserLevelSettingConfItem(userModel:getUserLevel())
	self.expLoadingNum:setString(userModel:getUserExp() .. "/" .. userLevelConfItem.Exp)
    self.expLoadingBar:setPercent(userModel:getUserExp() / userLevelConfItem.Exp * 100)

    print("Arena Score: "..pvpModel:getPvpInfo().Score)
    local arenaRankItem = getArenaRankItem(pvpModel:getPvpInfo().Score)
    if arenaRankItem then
        self.tLevelButton:loadTextureNormal(arenaRankItem.GNPic, 1)
        self.level:setString(CommonHelper.getUIString(arenaRankItem.GroupNumber - 1 + 806) or "")
    end

    -- Which one? pvpModel:getPvpInfo() or RankData.getRankData()
    -- 使用 RankData.getRankData 才能及时更新 
	RankData.getRankData(RankData.rankType.arena, UIManager.UI.UIArena, function (rankInfo) 	
		self.userRank:setString(rankInfo.selfInfo.index)
	end)
	--self.userRank:setString(pvpModel:getPvpInfo().Rank)
end

-- 刷新宝箱
function UIArena:updateChestButtons()
    local chestList = pvpChestModel:getChests()
    local pvpInfo = pvpModel:getPvpInfo()

    for i = 1, 5 do
        if i < #chestList then
            self.chestButtonActions[i]:play("Open", false)
        elseif i == #chestList then
            if self.isBoughtNewChest then  -- 新购买的宝箱
                local animationInfo = self.chestButtonActions[i]:getAnimationInfo("BuyAnima")
                local actionTime = (animationInfo.endIndex - animationInfo.startIndex) / 60

                self.chestButtonActions[i]:play("BuyAnima", false)
                self:runAction(cc.Sequence:create(
                    cc.DelayTime:create(actionTime), 
                    cc.CallFunc:create(function () 
                        self.chestButtonActions[i]:play("Open", false)
                    end)
                ))
                
                self.isBoughtNewChest = false
            else
                self.chestButtonActions[i]:play("Open", false)
            end
        else
            self.chestButtonActions[i]:play("Add", false)
            local arenaSetting = getArenaSetting()
            local priceText = CsbTools.getChildFromPath(self.chestButtons[i], "ChestBoxBar/ChestPanel/GemNum")
            if pvpInfo.DayBuyChestTimes < arenaSetting.Arena_ChestHalfPriceNum then
                priceText:setString(arenaSetting.Arena_ChestPrice / 2)
            else
                priceText:setString(arenaSetting.Arena_ChestPrice)
            end
        end
    end

    self:updateTipsText()
    self:openWaitTimeSchedule()
end

-- 刷新准备领取宝箱
function UIArena:updateReadyGetChest()
    local pvpInfo = pvpModel:getPvpInfo()
    if pvpInfo.ChestStatus > 0 then
        self.maskPanel:setVisible(true)
        CommonHelper.playCsbAnimate(self, self.rootPath, "OpenChest", false)
    else
        self.maskPanel:setVisible(false)
        CommonHelper.playCsbAnimate(self, self.rootPath, "Normal", false)
    end
end

-- 刷新宝箱提示文字
function UIArena:updateTipsText(dt)
    local chestList = pvpChestModel:getChests()
    local arenaSetting = getArenaSetting()
    local pvpInfo = pvpModel:getPvpInfo()

    local restHalfPriceNum = arenaSetting.Arena_ChestHalfPriceNum - pvpInfo.DayBuyChestTimes
    restHalfPriceNum = restHalfPriceNum < 0 and 0 or restHalfPriceNum

    -- 宝箱倒计显示
    local time = pvpInfo.LastChestTime + arenaSetting.Arena_ChestRefresh - gameModel:getNow()
    if time > 0 then
        local hour = math.floor(time / 3600)
        local min = math.floor(time / 60 % 60)
        local second = math.floor(time % 60)

        self.tipsText:setString(string.format(CommonHelper.getUIString(2184), hour, min, second, restHalfPriceNum))
    else
        if #chestList >= 5 then
            -- 定时器倒计关闭
            self:closeWaitTimeSchedule()
            self.tipsText:setString(string.format(CommonHelper.getUIString(2185), restHalfPriceNum))
        else
            if not self.isRequestChest then
                local buffData = NetHelper.createBufferData(MainProtocol.PvpChest, PvpChestProtocol.RefreshChestCS)
                NetHelper.request(buffData)
                self.isRequestChest = true
            else
                self.tipsText:setString("waiting...")
            end
        end
    end
end

------------ Update UI end -------------

function UIArena:openWaitTimeSchedule()
    if not self.waitTimeSchedule then
        self.waitTimeSchedule = scheduler.scheduleGlobal(handler(self, self.updateTipsText), 1)
    end
end

function UIArena:closeWaitTimeSchedule()
    if self.waitTimeSchedule then
        scheduler.unscheduleGlobal(self.waitTimeSchedule)
        self.waitTimeSchedule = nil
    end
end


return UIArena