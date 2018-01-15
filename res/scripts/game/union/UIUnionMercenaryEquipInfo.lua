--[[
	单个装备信息显示界面，主要实现以下内容
	1. 显示装备图标, 名称, 等级限制, 职业, 属性, 特殊效果, 介绍
--]]

local UIUnionMercenaryEquipInfo = class("UIUnionMercenaryEquipInfo")

local UIUnionEquipVH = require("game.union.UIUnionEquipVH")

local effectBtnFile = "ui_new/g_gamehall/c_card/EquipButton.csb"
-- 界面作用 1.卸装和更换 2.装备 3.更换
local effects = {unfixAndReplace = 1, dress = 2, replace = 3}

function UIUnionMercenaryEquipInfo:ctor(csb)
	-- 初始化UI
	local mask = CsbTools.getChildFromPath(csb, "EqInfoPanel")
	mask:setTouchEnabled(true)

	self.infoCsb 		= CsbTools.getChildFromPath(csb, "EqInfoPanel/EquipInfo")

	-- 屏蔽
	self.effectBtnCsb	= CsbTools.getChildFromPath(csb, "FileNode_2")
	local unfixBtn		= CsbTools.getChildFromPath(self.effectBtnCsb, "WearButton")
	local changeBtn 	= CsbTools.getChildFromPath(self.effectBtnCsb, "ChangeButton")
	self.changeBtnLab 	= CsbTools.getChildFromPath(changeBtn, "ButtonName")
end

function UIUnionMercenaryEquipInfo:setUIInfo(dyId, confId, effectType, heorId)	
	self.dyId	= dyId
	self.confId		= confId
	self.effectType	= effectType
	-- 切换动画, 替换文字
	local info = {[effects.unfixAndReplace] = {590, "Two"}, [effects.dress] = {504, "Change"}, [effects.replace] = {590, "Change"}}
	self.changeBtnLab:setString(CommonHelper.getUIString(info[1][1]))
	CommonHelper.playCsbAnimate(self.effectBtnCsb, effectBtnFile, info[1][2], false, nil, true)
	self.effectBtnCsb:setVisible(false)

	local eqConf = getEquipmentConfItem(confId)
	-- 算出部位
	if not eqConf then 
		print("not this confId", confId) 
	end
	
	self.eqPart		= eqConf.Parts
	local EquipData = {}
	EquipData.isMercenary  = true 		--为true为佣兵
	EquipData.place =  self.eqPart 	 	--装备的位置
	EquipData.dyId = dyId
	UIUnionEquipVH:setCsbInfo(self.infoCsb, heorId, confId, 340, EquipData)
end


return UIUnionMercenaryEquipInfo