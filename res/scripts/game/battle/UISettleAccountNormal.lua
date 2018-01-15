
--[[
	常规结算, 普通关卡, 精英关卡, 副本关卡游戏结束后会使用该结算界面
]]

local UISettleAccountNormal = class("UISettleAccountNormal", function()
	return require("common.UIView").new()
end)

local scheduler = require("framework.scheduler")
local PropTips = require("game.comm.PropTips")

--获得一个物品结算格式
--resultData = {stageId = 101, showLayer = "WinLayer", star = 3, star2Reason = 1, star3Reason = 2, exp = 100, gold = 300, 
--				rewardCountType = "Single", realItems = {{}, {}}, autoItem = {}}
--获得多个物品结算格式
--resultData = {stageId = 101, showLayer = "WinLayer", star = 3, star2Reason = 1, star3Reason = 2, exp = 100, gold = 300, 
--				rewardCountType = "Multiple", realItems = {{}, {}}}
--失败界面只有一个
--resultData = {showLayer = "LoseLayer"}
local ItemCount = 6

function UISettleAccountNormal:ctor()
	--配表文字
	local okText = CommonHelper.getUIString(500)

	--胜利界面节点
	self.winNode = getResManager():getCsbNode(ResConfig.UISettleAccountNormal.Csb2.win)
	self.winNodeAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.win)
	self.winNode:runAction(self.winNodeAct)

	self.star = 0
	self.starAct = {}
	for i = 1, 3 do
		local starNode = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/GetStar" .. i)
		self.starAct[i] = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.getStar)
		starNode:runAction(self.starAct[i])
	end

	self.starText = {}
	for i = 1, 3 do
		self.starText[i] = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/StarText_"..i)	
	end
	--物品栏
	self.autoShow = false
	self.itemIndex = 0
	self.realIndex = 0
	self.tickingItemAct = nil
	self.awardItems = {}
	self.awardItemActs = {}
	self.mListView = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/AwardListView")
	for i = 1, ItemCount do
		self.awardItems[i] = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/AwardListView/Button_"..i.."/AwardItem")
		self.awardItemActs[i] = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.awardItem)
		self.awardItems[i]:runAction(self.awardItemActs[i])
        self.awardItemActs[i]:play("Normal", false)
	end

	self.winOkBtn = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/ConfirmButtom")
	self.winOkBtnSub = CsbTools.getChildFromPath(self.winNode, "FightWinEffect/ConfirmButtom/ConfirmButtom")
	self.winOkBtnAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.okBtn)
	self.winOkBtnSub:runAction(self.winOkBtnAct)
	self.winOkBtn:setVisible(false)
	CsbTools.getChildFromPath(self.winOkBtnSub, "NameLabel"):setString(okText)

	--失败界面节点
	self.loseNode = getResManager():getCsbNode(ResConfig.UISettleAccountNormal.Csb2.fail)
	self.loseNodeAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.fail)
	self.loseNode:runAction(self.loseNodeAct)
	self.tipTex = CsbTools.getChildFromPath(self.loseNode, "MainPanel/TipTex_2")
	self.tipTex:setString("")
	self.loseOkBtn = CsbTools.getChildFromPath(self.loseNode, "MainPanel/ConfirmButtom")
	self.loseOkBtnSub = CsbTools.getChildFromPath(self.loseNode, "MainPanel/ConfirmButtom/ConfirmButtom")
	self.loseOkBtnAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.okBtn)
	self.loseOkBtnSub:runAction(self.loseOkBtnAct)
	CsbTools.getChildFromPath(self.loseOkBtnSub, "NameLabel"):setString(okText)


	--金袋节点
	self.goldNode = getResManager():getCsbNode(ResConfig.UISettleAccountNormal.Csb2.awardGold)
	self.goldNodeAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.awardGold)
	self.goldNode:runAction(self.goldNodeAct)
	self.goldNode:setVisible(false)	
	self.goldOkBtn = CsbTools.getChildFromPath(self.goldNode, "MainPanel/ConfirmButtom")
	self.goldOkBtnSub = CsbTools.getChildFromPath(self.goldNode, "MainPanel/ConfirmButtom/ConfirmButtom")
	self.goldOkBtnAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.okBtn)
	self.goldOkBtnSub:runAction(self.goldOkBtnAct)
	CsbTools.getChildFromPath(self.goldOkBtnSub, "NameLabel"):setString(okText)

	--召唤师奖励节点
	self.sumNode = getResManager():getCsbNode(ResConfig.UISettleAccountNormal.Csb2.awardSum)
	self.sumNodeAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.awardSum)
	self.sumNode:runAction(self.sumNodeAct)
	self.sumNode:setVisible(false)
	self.sumShowNode = CsbTools.getChildFromPath(self.sumNode, "BuyEffect/HeroNode")
	self.sumShowName = CsbTools.getChildFromPath(self.sumNode, "BuyEffect/InfoPanel/SummonerName")
	self.sumInfoLabel = CsbTools.getChildFromPath(self.sumNode, "BuyEffect/InfoPanel/InfoLabel")
	self.sumOkBtn = CsbTools.getChildFromPath(self.sumNode, "BuyEffect/ConfirmButtom")
	self.sumOkBtnSub = CsbTools.getChildFromPath(self.sumNode, "BuyEffect/ConfirmButtom/ConfirmButtom")
	self.sumOkBtnAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountNormal.Csb2.okBtn)
	self.sumOkBtnSub:runAction(self.sumOkBtnAct)
	CsbTools.getChildFromPath(self.sumOkBtnSub, "NameLabel"):setString(okText)

	--添加的主界面上
	self:addChild(self.winNode)
	self:addChild(self.loseNode)
	self:addChild(self.goldNode)
	self:addChild(self.sumNode)

	--点击监听
	self.winOkBtn:addTouchEventListener(handler(self, self.winOkButtonDown))
	self.loseOkBtn:addTouchEventListener(handler(self, self.loseOkButtonDown))
	self.goldOkBtn:addTouchEventListener(handler(self, self.goldOkButtonDown))
	self.sumOkBtn:addTouchEventListener(handler(self, self.sumOkButtonDown))

	self:setNodeEventEnabled(true) -- 开启调用onExit()
     --适配
	CommonHelper.layoutNode(self.winNode)
    CommonHelper.layoutNode(self.loseNode)
    CommonHelper.layoutNode(self.sumNode)
    --CommonHelper.layoutNode(self.heroNode)
end

function UISettleAccountNormal:onOpen(_, resultData)
	self.loseNode:setVisible(false)
	self.winNode:setVisible(false)
	-- 道具点击提示
	self.propTips = PropTips.new()
    --先将星星置为无
    for i = 1, 3 do
		self.starAct[i]:play("NoGet", false)
	end
	--设置zorder
	self:setGlobalZOrder(5)
	self:setLocalZOrder(5)

	if resultData.showLayer == "WinLayer" then
        self.star = resultData.star
		--设置星星的显示文字
		self:setStarReason(resultData.stageId, 
            resultData.star2Reason,	resultData.star3Reason)
		if resultData.rewardCountType == "Single" then
			--显示一个
			--设置真实物品
			self:setRandomItemInfo(resultData.realItems[1], resultData.PNDropId)
		else
			--显示多个物品
			for i = 1, #resultData.realItems do
				self:insertItemInfo(resultData.realItems[i])
			end
			
			self.mListView:setTouchEnabled(false)
            self.mListView:setContentSize(#resultData.realItems*100,self.mListView:getContentSize().height)
		end
		--显示胜利界面
		self:showWinLayer()
	else
		--显示失败界面
		self:showLoseLayer()
	end
end

function UISettleAccountNormal:onClose()
	if self.sumShowNode then
		self.sumShowNode:removeAllChildren()
	end
end

function UISettleAccountNormal:onExit()
	if self.updateFunc then
		scheduler.unscheduleGlobal(self.updateFunc)
	end
end

function UISettleAccountNormal:onTop()
    -- 注:暂时处理
	EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
end

function UISettleAccountNormal:setStarReason(stageId, star2Reason, star3Reason)
	local stageConf = getStageConfItem(stageId)
	if stageConf == nil then
		print(string.format("stageId=%d config is nil!!!",stageId))
	end

	--通关成功星级1, 设置星星1底下的文字
	self.starText[1]:setString(BattleHelper.getStarReason())
    -- 第三颗星星满足,而第二颗不满足
    if 0 == star2Reason and 0 ~= star3Reason then
        self.starText[2]:setString(BattleHelper.getStarReason(stageConf.WinStar2, stageConf.WinStar2Param))
        self.starText[3]:setString(BattleHelper.getStarReason(stageConf.WinStar1, stageConf.WinStar1Param))
    else
        self.starText[2]:setString(BattleHelper.getStarReason(stageConf.WinStar1, stageConf.WinStar1Param))
        self.starText[3]:setString(BattleHelper.getStarReason(stageConf.WinStar2, stageConf.WinStar2Param))
    end
end

--设置物品栏信息 itemInfo = {id, count}
function UISettleAccountNormal:insertItemInfo(itemInfo)
	--递增物品格
	self.realIndex = self.realIndex + 1
    UIAwardHelper.setAllItemOfConf(self.awardItems[self.realIndex], getPropConfItem(itemInfo.id), itemInfo.num)
    local touchNode = CsbTools.getChildFromPath(self.awardItems[self.realIndex], "MainPanel")
    self.propTips:addPropTips(touchNode, getPropConfItem(itemInfo.id))

    --是否播放立即使用动画
    local itemConf = getPropConfItem(itemInfo.id)
    if not itemConf then
        print(">>>error<<<: getPropConfItem is nil, id", itemInfo.id)
        return
    end

    if itemConf.Type == UIAwardHelper.ItemType.HeroCard 
        or itemConf.Type == UIAwardHelper.ItemType.SummonerCard then
        self:setAutoInfo(itemInfo)
    end
end

--设置随机物品位置并显示真实物品
function UISettleAccountNormal:setRandomItemInfo(itemInfo, PNDropId)
	--随机真实物品位置[1~5]
	local seed = 1
	seed = seed * os.time()
	math.randomseed(seed)
	self.realIndex = math.random(5)
    -- 设置物品
    local node = self.awardItems[self.realIndex]
	UIAwardHelper.setAllItemOfConf(node, getPropConfItem(itemInfo.id), itemInfo.num)

	local touchNode = CsbTools.getChildFromPath(node, "MainPanel")
    self.propTips:addPropTips(touchNode, getPropConfItem(itemInfo.id))

	--记录真实物品id, 用于伪随机个数限制
	self.realItemId = itemInfo.id
    --设置伪随机的物品
	self:setPNItem(PNDropId)
    --是否播放立即使用动画
    local itemConf = getPropConfItem(itemInfo.id)
    if itemConf.Type == UIAwardHelper.ItemType.HeroCard 
        or itemConf.Type == UIAwardHelper.ItemType.SummonerCard then
        self:setAutoInfo(itemInfo)
    end
    print("UISettleAccountNormal:setRandomItemInfo end")
end

--随机4个显示物品
function UISettleAccountNormal:setPNItem(dropId)
	--掉落的配置表
	local dropConf = getDropPropItem(dropId)
	--随机下标值, 下标值合法就存起来, 按照策划案, 一个下标只能出现2次
	--选中的下标值存储于randIndexs中
	local total = {}
	local record = {}
	local randIndexs = {}
	--构造record 记录数据
	for i =1, #dropConf.DropIDs do
		--print("dropConf.DropIDs i, DropID", i, dropConf.DropIDs[i].DropID)
		table.insert(total, i)
		if self.realItemId == dropConf.DropIDs[i].DropID then
			record[i] = 1
		else
			record[i] = 0
		end
	end
	--数量最大或者随4个
	local seed = os.time()
	local max = #total
	while #total > 0 and #randIndexs < 4 do
		seed = seed*os.time()
		math.randomseed(seed)
		local rand = math.random(max)
		if record[rand] < 2 then
			table.insert(randIndexs, rand)
			record[rand] = record[rand] + 1
		else
			table.remove(total, rand)
		end
	end
	--总数量小于4, 打印log
	if #randIndexs < 4 then
		print("in ItemDrop config, rand items less than 4. please check dropId:", dropId)
	end
	--设置随到的4个物品信息
	local index = 0
	for _, v in pairs(randIndexs) do
		local dropItem = dropConf.DropIDs[v]
		index = index + 1
		--下标为真实物品的下标, 则跳到下一个
		if index == self.realIndex then index = index + 1 end
        --设置物品id, 默认为1
		UIAwardHelper.setAllItemOfConf(self.awardItems[index], getPropConfItem(dropItem.DropID), 1)

		local touchNode = CsbTools.getChildFromPath(self.awardItems[index], "MainPanel")
    	self.propTips:addPropTips(touchNode, getPropConfItem(dropItem.DropID))
	end
end

--立即使用物品 autoInfo = {id, count}
function UISettleAccountNormal:setAutoInfo(autoInfo)
	--设置自动打开的界面信息, 可能为英雄卡, 召唤师
	self.autoShow = true
	self.autoInfo = {}
	self.autoInfo.id = autoInfo.id
	self.autoInfo.count = autoInfo.num
end

function UISettleAccountNormal:showWinLayer()
    print("UISettleAccountNormal:showWinLayer")
	--打开胜利界面动画
	self.winNode:setVisible(true)
	self.winNodeAct:play("Open", false)
	self.winNodeAct:setFrameEventCallFunc(handler(self, self.openFinish))
end

--打开动作结束后回调
function UISettleAccountNormal:openFinish(frame)
	--播放物品跳动动作
	--为物品跳动动作设置计时
	local eventName = frame:getEvent()
	--显示星星
	if eventName == "Star1" then
		if self.star>=1 then
			self.starAct[1]:play("Get", false)
		end
	elseif eventName == "Star2" then
		if self.star>=2 then
			self.starAct[2]:play("Get", false)
		end
	elseif eventName == "Star3" then
		if self.star>=3 then
			self.starAct[3]:play("Get", false)
		end
	elseif eventName == "OpenEnd" then
        if self.isSingle then
            --单个显示, 跑马灯
            self.updateFunc = scheduler.scheduleGlobal(function(dt) 
			    self.itemIndex = self.itemIndex + 1
			    if self.itemIndex >5 then
				    self.itemIndex = 1
				    self.lastLoop = true
			    end

			    if self.tickingItemAct then
				    self.tickingItemAct:play("Normal", true)
			    end
			    self.tickingItemAct = self.awardItemActs[self.itemIndex]
			    self.tickingItemAct:play("On", true)

			    -- 跳动结束
			    if self.lastLoop and (self.realIndex == self.itemIndex) then
				    self.tickingItemAct:play("Choose", false)
				    scheduler.unscheduleGlobal(self.updateFunc)
				    self.updateFunc = nil

				    self:showAutoItemLayer()
                    if not self.autoShow then
                        EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
                    end

                    self.winOkBtn:setVisible(true)
			    end
		    end, 0.3)
        else
            --多个显示
            for i = 1, #self.awardItems do
                self.awardItemActs[i]:play("Normal", true)
            end

            self:showAutoItemLayer()
            if not self.autoShow then
                EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
            end
            self.winOkBtn:setVisible(true)
        end

	end
end

--播放物品跳动动作
function UISettleAccountNormal:showAutoItemLayer()
	--1.检查是否有立即使用物品
	if self.autoShow then
		--2.播放立即使用物品界面
        local autoItemConf = getPropConfItem(self.autoInfo.id)
        if autoItemConf.Type == UIAwardHelper.ItemType.HeroCard then
            --1) 获得新英雄卡
            local confId = autoItemConf.TypeParam[1]
            local star = autoItemConf.TypeParam[2]
            local heroLv = autoItemConf.TypeParam[3] or 1
            self:autoHeroCardShow(confId, star, heroLv)
        elseif autoItemConf.Type == UIAwardHelper.ItemType.SummonerCard then
            --2) 召唤师
            local confId = autoItemConf.TypeParam[1]
			self:autoSummonerShow(confId)
        else
            --
        end
	end
end

--英雄获得界面播放
function UISettleAccountNormal:autoHeroCardShow(confId, heroStar, heroLv)
	UIManager.open(UIManager.UI.UIShowCard, 2, {cardId = confId, star = heroStar, heroLv = heroLv})
end

--召唤师获得界面播放
function UISettleAccountNormal:autoSummonerShow(confId)
	--print("=============autoSummonerShow!!!!", confId)
	local sumConf = getHeroConfItem(confId)
	if sumConf then
		--设置召唤师节点信息
		AnimatePool.createAnimate(sumConf.Common.AnimationID, function(animation) 
		    self.sumShowNode:addChild(animation)
		end)
		--召唤师名字
		self.sumShowName:setString(getHSLanConfItem(sumConf.Common.Name) or confId)
		--召唤师介绍
		self.sumInfoLabel:setString(getHSLanConfItem(sumConf.Common.Desc) or confId)
		--召唤师节点显示
		self.sumNode:setVisible(true)
		self.sumNodeAct:play("Open", false)
	end
end

--金币获得界面播放
function UISettleAccountNormal:autoGoldShow(gold)
	--print("=================gold", gold)
	self.goldNode:setVisible(true)
	self.goldNodeAct:play("Open", false)
	--弹出浮动文字, 显示金袋有多少钱
	local tipLabel = require("game.comm.PopTip").new({
		text = gold, 
		font = "../fonts/msyh.ttf",
		animate = 1,
		x = display.cx,
		y = display.cy,
		size = 48, 
		color = cc.c3b(255, 255, 0),
		align = cc.ui.TEXT_ALIGN_CENTER,
		valign= cc.ui.TEXT_VALIGN_CENTER,
		dimensions = cc.size(display.cx, display.cy)
		})
	self:addChild(tipLabel)
end

function UISettleAccountNormal:showLoseLayer()
    print("UISettleAccountNormal:showLoseLayer")
	self.loseNode:setVisible(true)
	self.loseNodeAct:play("Open", false)
end

--胜利界面"确定"按钮回调
function UISettleAccountNormal:winOkButtonDown(obj, touchType)
	if touchType == 0 then --开始点击
		self.winOkBtnAct:play("OnAnimation", false)
	elseif touchType == 2 then --结束点击
		self.winOkBtnAct:play("Normal", false)
		--跳转到世界地图或者大厅
		self:backToScene()
	elseif touchType == 3 then --取消点击
		self.winOkBtnAct:play("Normal", false)
	end
end

--失败界面"确定"按钮回调
function UISettleAccountNormal:loseOkButtonDown(obj, touchType)
	if touchType == 0 then --开始点击
		self.loseOkBtnAct:play("OnAnimation", false)
	elseif touchType == 2 then --结束点击
		self.loseOkBtnAct:play("Normal", false)
		--跳转到世界地图或者大厅
		self:backToScene()
	elseif touchType == 3 then --取消点击
		self.loseOkBtnAct:play("Normal", false)
	end
end

--金袋界面"确定"按钮回调
function UISettleAccountNormal:goldOkButtonDown(obj, touchType)
	if touchType == 0 then --开始点击
		self.goldOkBtnAct:play("OnAnimation", false)
	elseif touchType == 2 then --结束点击
		self.goldOkBtnAct:play("Normal", false)
		self.goldNode:setVisible(false)
	elseif touchType == 3 then --取消点击
		self.goldOkBtnAct:play("Normal", false)
	end
end

--召唤师界面"确定"按钮回调
function UISettleAccountNormal:sumOkButtonDown(obj, touchType)
	if touchType == 0 then --开始点击
		self.sumOkBtnAct:play("OnAnimation", false)
	elseif touchType == 2 then --结束点击
		self.sumOkBtnAct:play("Normal", false)
		self.sumNode:setVisible(false)
	elseif touchType == 3 then --取消点击
		self.sumOkBtnAct:play("Normal", false)
	end
end

function UISettleAccountNormal:backToScene()	
	self.propTips:removePropAllTips()
	self.propTips = nil
	
	-- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
    -- 释放房间资源
    finishBattle()
	-- 加载大厅场景
	if SceneManager.PrevScene then
		SceneManager.loadScene(SceneManager.PrevScene)
	else
		SceneManager.loadScene(SceneManager.Scene.SceneHall)
	end
end

return UISettleAccountNormal
