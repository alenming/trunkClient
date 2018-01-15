--[[
    大厅背景界面
]]

local UIHallBG = class("UIHallBG", function ()
	return require("common.UIView").new()
end)

function UIHallBG:ctor()
end

function UIHallBG:init()
    self.UICsb = ResConfig.UIHallBG.Csb2
	-- 大厅背景主界面
    self.rootPath = self.UICsb.HallBG
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    self.hallBgAct = cc.CSLoader:createTimeline(self.rootPath)
	self.root:runAction(self.hallBgAct)
    self.hallBgAct:play("Normal", false)
end

function UIHallBG:onOpen(fromUIID, ...)
    UIManager.open(UIManager.UI.UIHall) 
end

function UIHallBG:onClose()
    
end

return UIHallBG