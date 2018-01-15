--[[
	单个装备信息显示界面，主要实现以下内容
	1. 显示装备图标, 名称, 等级限制, 职业, 属性, 特殊效果, 介绍
--]]

local UIEquipInfo = class("UIEquipInfo")

local UIEquipViewHelper = require("game.hero.UIEquipViewHelper")

local effectBtnFile = "ui_new/g_gamehall/c_card/EquipButton.csb"

-- 界面作用 1.卸装和更换 2.装备 3.更换
local effects 	= {unfixAndReplace = 1, dress = 2, replace = 3}

function UIEquipInfo:ctor(csb)
	-- 初始化UI
	local mask 		= CsbTools.getChildFromPath(csb, "EqInfoPanel")
	mask:setTouchEnabled(true)

	self.infoCsb 		= CsbTools.getChildFromPath(csb, "EqInfoPanel/EquipInfo")

	-- 屏蔽
	self.effectBtnCsb	= CsbTools.getChildFromPath(csb, "FileNode_2")
	local unfixBtn		= CsbTools.getChildFromPath(self.effectBtnCsb, "WearButton")
	local changeBtn 	= CsbTools.getChildFromPath(self.effectBtnCsb, "ChangeButton")
	self.changeBtnLab 	= CsbTools.getChildFromPath(changeBtn, "ButtonName")

	-- 卸下, 更换按钮
	CsbTools.initButton(unfixBtn, handler(self, self.unfixBtnCallBack), 
			CommonHelper.getUIString(589), "ButtonName", "ButtonName")
	CsbTools.initButton(changeBtn, handler(self, self.changeBtnCallBack), 
			CommonHelper.getUIString(590), "ButtonName", "ButtonName")
end

function UIEquipInfo:setUIInfo(heroID, eqDyID, effectType, uiCallFunc)	
	self.heroID	= heroID
	self.eqDyID		= eqDyID
	self.uiCallFunc = uiCallFunc
	self.effectType	= effectType

	-- 切换动画, 替换文字
	local info = {[effects.unfixAndReplace] = {590, "Two"}, [effects.dress] = {504, "Change"}, [effects.replace] = {590, "Change"}}
	self.changeBtnLab:setString(CommonHelper.getUIString(info[effectType][1]))
	CommonHelper.playCsbAnimate(self.effectBtnCsb, effectBtnFile, info[effectType][2], false, nil, true)

	-- 算出部位
	local eqConfID 	= getGameModel():getEquipModel():getEquipConfId(eqDyID)
	if eqConfID == nil and eqConfID ~= 0 then print("not this eqDyID", eqDyID) end
	local eqConf 	= getEquipmentConfItem(eqConfID)
	if eqConf == nil then print("eqConf is nil", eqConfID, heroID, eqDyID, effectType) end
	self.eqPart		= eqConf.Parts	

	UIEquipViewHelper:setCsbInfo(self.infoCsb, heroID, eqDyID, 340)	
end

-- function UIEquipInfo:setPlanPosition(pos)
-- 	local layout = CsbTools.getChildFromPath(self.root, "EqInfoPanel")
-- 	local panelSize = layout:getContentSize()
-- 	pos = cc.p(pos.x, pos.y - panelSize.height/2)
-- 	self:setPosition(pos)

-- 	-- 判断上下限
-- 	local wPos = self:convertToWorldSpace(cc.p(0,0))
-- 	local offsetPos = cc.p(0,0)
-- 	if wPos.x - panelSize.width/2 < 0 then
-- 		offsetPos.x = panelSize.width/2 - wPos.x
-- 	elseif wPos.x + panelSize.width/2 > display.width then
-- 		offsetPos.x = display.widht - (wPos.x + panelSize.width/2)
-- 	end
-- 	if wPos.y + panelSize.height/2 > display.height then
-- 		offsetPos.y = display.height - (wPos.y + panelSize.height/2)
-- 	elseif wPos.y - panelSize.height/2 < 0 then
-- 		offsetPos.y = panelSize.height/2 - wPos.y
-- 	end

-- 	self:runAction(cc.MoveBy:create(0.2, offsetPos))
-- end

function UIEquipInfo:unfixBtnCallBack(args)
	if self.effectType == effects.unfixAndReplace then
		-- 判断背包容量
		local bagCapacity = getGameModel():getBagModel():getItemCount()
		local bagMaxCapacity = getGameModel():getBagModel():getCurCapacity()
		if bagCapacity >= bagMaxCapacity then
			CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1377))
		else
			self.uiCallFunc({heroID = self.heroID, eqPart = self.eqPart, eqDyID = 0})
		end
	end
end

function UIEquipInfo:changeBtnCallBack()
	if self.effectType == effects.unfixAndReplace then
		UIManager.open(UIManager.UI.UIEquipBag, self.heroID, self.eqPart, self.uiCallFunc)
	else
		self.uiCallFunc({heroID = self.heroID, eqPart = self.eqPart, eqDyID = self.eqDyID})
	end
end

return UIEquipInfo