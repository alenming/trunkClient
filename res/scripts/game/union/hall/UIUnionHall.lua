--[[
	公会大厅界面，主要实现以下内容
	1. 显示公会列表
	2. 申请公会
	3. 查找公会
	4. 创建公会
--]]

local UIUnionHall = class("UIUnionHall", function ()
	return require("common.UIView").new()
end)

local csbFile = ResConfig.UIUnionHall.Csb2
local tabBtnFile = "ui_new/g_gamehall/b_bag/AllButton2.csb"

-- 右侧标签
-- 按钮路径, csb路径, class名, 按钮语言包
local tabInfo = {
	unionInfo = {"InfoButton", "Guild_InfoPanel", "UnionInfoViewHelper", 1973, redIndex = 10},
	unionMember = {"MembersButton", "Guild_MembersPanel", "UnionMemberViewHelper", 1975, redIndex = 11},
	unionWelfare = {"AwardButton", "Guild_WealPanel", "UnionWelfareViewHelper", 1974, redIndex = 0},
	unionAudit = {"ReviewButton", "Guild_NewReview", "UnionAuditViewHelper", 1976, redIndex = 1},
}

function UIUnionHall:ctor()
	self.rootPath = csbFile.hall
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)
	
	self.showPart = nil

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function()
		UIManager.close()
	end)

    self.redPoints = {}
	-- 公会侧边栏按钮, 及对应的csb
	for k,v in pairs(tabInfo) do
		-- 侧边栏按钮
		self[k .. "Btn"] = CsbTools.getChildFromPath(self.root, "MainPanel/" .. v[1])
		CsbTools.initButton(self[k .. "Btn"], handler(self, self.tabBtnCallBack), 
			CommonHelper.getUIString(v[4]), "AllButton/ButtonPanel/NameLabel", "AllButton")

		-- 按钮对应的csb
		self[k .. "Csb"] = CsbTools.getChildFromPath(self.root, "MainPanel/" .. v[2])
        self[k .. "Csb"]:setTag(v.redIndex)

		-- 对象csb的界面协助者
		self[k .. "ViewHelper"] = require("game.union.hall." .. v[3]).new(self, self[k .. "Csb"])
		self[k .. "ViewHelper"]:setVisible(false)

        self.redPoints[v.redIndex] = CsbTools.getChildFromPath(self.root, "MainPanel/" .. v[1].."/AllButton/RedTipPoint")
        self.redPoints[v.redIndex]:setVisible(false)
	end
end

function UIUnionHall:onOpen(uiID)
	for k,v in pairs(tabInfo) do
		self[k .. "ViewHelper"]:onOpen(uiID)

        self:showRedPoint(v.redIndex)
	end

	self:judgeAuditBtn()

	self:changeShowPart("unionInfo")

	-- 监听通知
	self.funcEventHandler = handler(self, self.funcEventCallBack)
	EventManager:addEventListener(GameEvents.EventUnionFunc, self.funcEventHandler)
end

function UIUnionHall:onClose(uiID)
	for k,v in pairs(tabInfo) do		
		self[k .. "ViewHelper"]:onClose(uiID)
	end

	-- 取消监听
	EventManager:removeEventListener(GameEvents.EventUnionFunc, self.funcHandler)
end

function UIUnionHall:onTop(uiID)
	for k,v in pairs(tabInfo) do		
		self[k .. "ViewHelper"]:onTop(uiID)
	end
end

function UIUnionHall:judgeAuditBtn()
	-- 判断权限, 是否隐藏审核按钮
	local pos = getGameModel():getUnionModel():getPos()

	if pos >= UnionHelper.pos.ViceChairman then
		self["unionAudit" .. "Btn"]:setVisible(true)
	else
		self["unionAudit" .. "Btn"]:setVisible(false)
	end
end

-- 有审核数据通过, 下次显示公会信息界面, 公会成员界面需要刷新
function UIUnionHall:agreeAudit()
	self["unionInfo" .. "ViewHelper"]:resetDataValidity()
	self["unionMember" .. "ViewHelper"]:resetDataValidity()
end

-- 设置界面下次打开需要重新刷新 part 为 tabInfo的key
function UIUnionHall:resetHasRefresh(part)
	if self[part .. "ViewHelper"] then
		self[part .. "ViewHelper"]:resetHasRefresh()
	end
end

function UIUnionHall:tabBtnCallBack(obj)
	local name = obj:getName()
	-- 找出当前点击的部位
	local part = nil
	for k,v in pairs(tabInfo) do
		if v[1] == name then
			part = k
			break
		end
	end

	self:changeShowPart(part)
end

function UIUnionHall:funcEventCallBack(eventName, params)
	if params.funcType == UnionHelper.FuncType.Appoint or 
		params.funcType == UnionHelper.FuncType.Transfer or
		params.funcType == UnionHelper.FuncType.Relieve then

		-- 判断权限, 是否隐藏审核按钮
		self:judgeAuditBtn()

		local pos = getGameModel():getUnionModel():getPos()
		if pos < UnionHelper.pos.ViceChairman then
			if self.showPart == "unionAudit" then
				self:changeShowPart("unionInfo")
			end
		end
	end
end

function UIUnionHall:changeShowPart(part)
	if part and part ~= self.showPart then
		if self.showPart ~= nil then
			self[self.showPart .. "ViewHelper"]:setVisible(false)
			self[self.showPart .. "Btn"]:setLocalZOrder(-10)		
			CommonHelper.playCsbAnimate(self[self.showPart .. "Btn"], tabBtnFile, "Normal", false, nil, true)
		end

		self.showPart = part
		self[self.showPart .. "ViewHelper"]:setVisible(true)
		self[self.showPart .. "Btn"]:setLocalZOrder(10)			
		CommonHelper.playCsbAnimate(self[self.showPart .. "Btn"], tabBtnFile, "On", false, nil, true)

		self:showRedPoint(tabInfo[part].redIndex)
	end
end

function UIUnionHall:showRedPoint(redIndex)
    self.redPoints[redIndex]:setVisible(RedPointHelper.getUnionSubRedPoint(redIndex))
end

return UIUnionHall