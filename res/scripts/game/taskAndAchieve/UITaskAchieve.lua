 --[[
	任务成就界面，主要实现以下内容
	1. 显示任务信息, 显示成就信息
	2. 管理任务类, 管理成就类
	3. 显示金币, 钻石, 体力, 时间
--]]
local UITaskAchieve = class("UITaskAchieve", require("common.UIView"))
require("game.comm.UIAwardHelper")

local buttonFile = "ui_new/g_gamehall/t_task/TaskTabButton.csb"
local taskRedTipFile = "ui_new/g_gamehall/t_task/TaskRedTipPoint.csb"

function UITaskAchieve:ctor()
	self.shorPart = nil -- 显示的部位(task, achieve)
	self.schedulerID = nil	-- 时间显示

	self.csb = ResConfig.UITaskAchieve.Csb2

	self.rootPath = self.csb.taskAchieve
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.taskTipNode = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/TaskButton1/TaskTabButton/TaskRedTipPoint")
	self.achieveTipNode = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/AchieveButton/TaskTabButton/TaskRedTipPoint")
	self.taskCsb = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/TaskItem")
	self.achieveCsb	= CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/AchieveItem")

	-- 按钮
	self.taskBtn = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/TaskButton1")
	self.achieveBtn = CsbTools.getChildFromPath(self.root, "MainPanel/TaskPanel/AchieveButton")
	CsbTools.initButton(self.taskBtn, handler(self, self.taskBtnCallBack), CommonHelper.getUIString(13), "TaskTabButton/NameLabel", "TaskTabButton")
	CsbTools.initButton(self.achieveBtn, handler(self, self.achieveBtnCallBack), CommonHelper.getUIString(50), "TaskTabButton/NameLabel", "TaskTabButton")

	self.backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(self.backBtn, function (obj)
        obj:setTouchEnabled(false)
		UIManager.close()
	end)

	-- label
	self.goldLab = CsbTools.getChildFromPath(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
	self.gemLab = CsbTools.getChildFromPath(self.root, "GemInfo/GemPanel/GemCountLabel")
	self.timeLab = CsbTools.getChildFromPath(self.root, "Time")
	self.taskTipNumLab = CsbTools.getChildFromPath(self.taskTipNode, "RedPoint/TipNum")
	self.achieveTipNumLab = CsbTools.getChildFromPath(self.achieveTipNode, "RedPoint/TipNum")
	self.taskTipNumLab:setString("")
	self.achieveTipNumLab:setString("")	

	-- 成就,任务 界面处理
	self.taskViewHelper = require("game.taskAndAchieve.TaskViewHelper").new(self, self.taskCsb)
	self.achieveViewHelper = require("game.taskAndAchieve.AchieveViewHelper").new(self, self.achieveCsb)

	self:setNodeEventEnabled(true)
end

function UITaskAchieve:onOpen(preUIID, part)
    self.backBtn:setTouchEnabled(true)
	part = part or "task"
	 -- 初始化金币 砖石, 体力 时间显示
    self.userModel = getGameModel():getUserModel()

	self.goldLab:setString(self.userModel:getGold())
	self.gemLab:setString(self.userModel:getDiamond())
	self.timeLab:setString(os.date("%H:%M", getGameModel():getNow()))

	-- 刷新事件回调
     self.updateGoldHandler = handler(self, self.updateGoldCallBack)
     EventManager:addEventListener(GameEvents.EventUpdateGold, self.updateGoldHandler)
     self.updateDiamondHandler = handler(self, self.updateDiamondCallBack)
     EventManager:addEventListener(GameEvents.EventUpdateDiamond, self.updateDiamondHandler)

    -- 界面管理界面初始化
	self.taskViewHelper:onOpen(preUIID, part)
	self.achieveViewHelper:onOpen(preUIID, part)
	self:changeDisplay(part)

	if self.schedulerID == nil then
		self.schedulerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.timeUpdate), 1, false)
	end

end

function UITaskAchieve:onTop(preUIID, ...)
	CommonHelper.playCsbAnimate(self.root, self.rootPath, "Normal", false, nil, true)
end

function UITaskAchieve:onExit()
	self.taskViewHelper:onClose()
	self.achieveViewHelper:onClose()

	if self.schedulerID then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedulerID)
		self.schedulerID = nil
    end

    EventManager:removeEventListener(GameEvents.EventUpdateGold, self.updateGoldHandler)
    EventManager:removeEventListener(GameEvents.EventUpdateDiamond, self.updateDiamondHandler)
    EventManager:removeEventListener(GameEvents.EventUpdateEnergy, self.uptateEnergyHandler)

	self:changeDisplay("task")
end

function UITaskAchieve:changeDisplay(part)
	local info = {task = {zOrder = {10, -10}, act = {"Normal", "On"}, isShow = {true, false}},
				achieve = {zOrder = {-10, 10}, act = {"On", "Normal"}, isShow = {false, true}}}

	if info[part] == nil then return end
	self.shorPart = part

	self.taskBtn:setLocalZOrder(info[part].zOrder[1])
	self.achieveBtn:setLocalZOrder(info[part].zOrder[2])
	CommonHelper.playCsbAnimate(self.achieveBtn, buttonFile, info[part].act[1], false, nil, true)
	CommonHelper.playCsbAnimate(self.taskBtn, buttonFile, info[part].act[2], false, nil, true)
	self.taskViewHelper:makeVisible(info[part].isShow[1])
	self.achieveViewHelper:makeVisible(info[part].isShow[2])
end

-- 设置红点提示数
function UITaskAchieve:setRedTipsNum(part, num)
	if part == "task" then
		if num == 0 then
			CommonHelper.playCsbAnimate(self.taskTipNode, taskRedTipFile, "Hide", false, nil, true)
		else
			self.taskTipNumLab:setString("" .. num)
			CommonHelper.playCsbAnimate(self.taskTipNode, taskRedTipFile, "Appear", false, nil, true)
		end
	elseif part == "achieve" then
		if num == 0 then
			CommonHelper.playCsbAnimate(self.achieveTipNode, taskRedTipFile, "Hide", false, nil, true)
		else
			self.achieveTipNumLab:setString("" .. num)
			CommonHelper.playCsbAnimate(self.achieveTipNode, taskRedTipFile, "Appear", false, nil, true)
		end
	end
end

function UITaskAchieve:taskBtnCallBack(obj)	
	if self.showPart ~= "task" then
		self:changeDisplay("task")
	end
end

function UITaskAchieve:achieveBtnCallBack(obj)
	if self.showPart ~= "achieve" then
		self:changeDisplay("achieve")
	end
end

function UITaskAchieve:updateGoldCallBack()
	self.goldLab:setString(self.userModel:getGold())
end

function UITaskAchieve:updateDiamondCallBack()
	self.gemLab:setString(self.userModel:getDiamond())
end

function UITaskAchieve:timeUpdate(dt)
	self.timeLab:setString(os.date("%H:%M", getGameModel():getNow()))
end

-- 设置 金币 经验 体力 钻石 信息
function UITaskAchieve:setAwardCsb1(node, type, value)
	local currencyType = {
		exp = "pub_exp.png",
		gold = "pub_gold.png",
		diamond = "pub_gem.png",
		energy = "pub_energy.png",
        flashcard = "icon_flashcard2.png"
	}
	local propIconImg = CsbTools.getChildFromPath(node, "MoneyPanel/AwardImage")
	local propNumLab = CsbTools.getChildFromPath(node, "MoneyPanel/AwardNumLabel")

	propIconImg:ignoreContentAdaptWithSize(true)
	CsbTools.replaceImg(propIconImg, currencyType[type])
	propNumLab:setString("x" .. value)

	local posX = propNumLab:getPositionX()
	return posX + propNumLab:getContentSize().width
end

-- 设置道具信息
function UITaskAchieve:setAwardCsb2(node, id, count)
	local propConf = getPropConfItem(id)
	if propConf == nil then print("propConf nil", id) return end

	local propCsb = CsbTools.getChildFromPath(node, "TaskAwradPanel/Award1")
	local propNumLab = CsbTools.getChildFromPath(node, "TaskAwradPanel/Award1_Num")
	propNumLab:setString("x" .. count)

	UIAwardHelper.setAllItemOfConf(propCsb, propConf, 0)

	local posX = propNumLab:getPositionX()
	return posX + propNumLab:getContentSize().width
end

return UITaskAchieve