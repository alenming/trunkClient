--[[
英雄试炼结算界面
]]

local UIHeroTestWin = class("UIHeroTestWin", function()
    return require("common.UIView").new()
end)
local PropTips = require("game.comm.PropTips")

local StarCount = 3 -- 星星总数
local Padding = {Left = 10, Buttom = 10} -- 物品距离
local ItemSize = 75 -- 大小75*75

function UIHeroTestWin:ctor()
     -- 道具点击提示
    self.propTips = PropTips.new()

    self.rootPath = ResConfig.UIHeroTestWin.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self.rootAct = cc.CSLoader:createTimeline(ResConfig.UIHeroTestWin.Csb2.main)
	self.root:runAction(self.rootAct)
    self:addChild(self.root)

    self.rootAct:play("Open", false)
	self.rootAct:setFrameEventCallFunc(handler(self, self.openFinish))

    self.awardView = getChild(self.root, "FightWinEffect/AwardScrollView")

    local confirmBtn = getChild(self.root, "FightWinEffect/ConfirmButtom")
    local confirmBtnCallBack = function()
        self.propTips:removePropAllTips()
        self.propTips = nil

        -- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
        finishBattle()
	    -- 加载大厅场景
	    if SceneManager.PrevScene then
		    SceneManager.loadScene(SceneManager.PrevScene)
	    else
		    SceneManager.loadScene(SceneManager.Scene.SceneHall)
	    end
    end
    CsbTools.initButton(confirmBtn, confirmBtnCallBack
        , CommonHelper.getUIString(500), "ConfirmButtom/ButtomName", "ConfirmButtom")
end

function UIHeroTestWin:init()
    self:setGlobalZOrder(5)
	self:setLocalZOrder(5)

    self.starAct = {}
	for i = 1, StarCount do
		local starNode = CsbTools.getChildFromPath(self.root, "FightWinEffect/GetStar" .. i)
		self.starAct[i] = cc.CSLoader:createTimeline(ResConfig.UIHeroTestWin.Csb2.star)
		starNode:runAction(self.starAct[i])
	end

    self.starText = {}
    self.starText[1] = CsbTools.getChildFromPath(self.root, "FightWinEffect/StageOverLabel")	
    self.starText[2] = CsbTools.getChildFromPath(self.root, "FightWinEffect/UseTimeLabel")	
    self.starText[3] = CsbTools.getChildFromPath(self.root, "FightWinEffect/SummonerLifeLabel")	
end

function UIHeroTestWin:onOpen(fromUIID, resultData)
    for i = 1, StarCount do
		self.starAct[i]:play("NoGet", false)
	end

    -- 显示信息
    self.star = resultData.star
    getChild(self.root, "FightWinEffect/StageOverLabel"):setString(BattleHelper.getStarReason())
    -- 第三颗星星满足,而第二颗不满足
    self:setStarReason(resultData.stageId, resultData.star2Reason, resultData.star3Reason)

    getChild(self.root, "FightWinEffect/LvLabel"):setString(getGameModel():getUserModel():getUserLevel())
    getChild(self.root, "FightWinEffect/ExpLabel"):setString(resultData.Exp)
    getChild(self.root, "FightWinEffect/GoldLabel"):setString(resultData.Gold)

    -- 显示道具
    self.awardView:removeAllChildren()
    -- 道具少的时候居中
    local offsetX = (self.awardView:getContentSize().width
        - #resultData.realItems * (ItemSize + Padding.Left) - Padding.Left)/2
    offsetX = offsetX > 0 and offsetX or 0

    for j = 1, #resultData.realItems do
        local awardNode = getResManager():cloneCsbNode(ResConfig.UIHeroTestWin.Csb2.awardItem)
        awardNode:setPosition(offsetX + ItemSize * (j - 0.5) + Padding.Left * j, ItemSize/2 + Padding.Buttom)
        self.awardView:addChild(awardNode)

        UIAwardHelper.setAllItemOfConf(awardNode, getPropConfItem(resultData.realItems[j].id), resultData.realItems[j].num)

        local touchNode = CsbTools.getChildFromPath(awardNode, "MainPanel")
        self.propTips:addPropTips(touchNode, getPropConfItem(resultData.realItems[j].id))
    end
end

function UIHeroTestWin:setStarReason(stageId, star2Reason, star3Reason)
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

function UIHeroTestWin:openFinish(frame)
    local eventName = frame:getEvent()
    --print("eventName", eventName)
	--显示星星
	if eventName == "Star1" then
		if self.star >= 1 then
			self.starAct[1]:play("Get", false)
		end
	elseif eventName == "Star2" then
		if self.star >= 2 then
			self.starAct[2]:play("Get", false)
		end
	elseif eventName == "Star3" then
		if self.star >= 3 then
			self.starAct[3]:play("Get", false)
		end
    end
end

return UIHeroTestWin
