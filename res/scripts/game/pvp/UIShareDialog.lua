--[[
	战斗分享到公会弹框界面，主要实现以下内容
	1. 提供玩家输入分享文本
	2. 分享按钮
--]]

local UIShareDialog = class("UIShareDialog", require("common.UIView"))

function UIShareDialog:ctor()
	self.csbFile = ResConfig.UIShareDialog.Csb2
	self.rootPath = self.csbFile.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.descLab = CsbTools.getChildFromPath(self.root, "MainPanel/CinText")
	self.shareBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ShareButton")

	self.descLab:setPlaceHolder(CommonHelper.getUIString(getPVPShareConfig().Desc))
	self.descLab:setPlaceHolderColor(cc.c4b(240,240,240, 100))
	self.descLab:addEventListener(handler(self, self.textFieldCallBack))        

	CsbTools.initButton(self.shareBtn, handler(self, self.shareBtnCallBack))
end

function UIShareDialog:onOpen(_, battleID, callFunc)
	self.battleID = battleID
	self.callFunc = callFunc	
	self.shareResult = false
	self.shareDesc = ""
end

function UIShareDialog:onClose()
	self.descLab:didNotSelectSelf()
	if type(self.callFunc) == "function" then
		self.callFunc(self.battleID, self.shareResult, self.shareDesc)
	end
end

function UIShareDialog:textFieldCallBack(obj, eventType)
	if eventType == 2 then
        local newStr = FilterSensitive.FilterStr(obj:getString())
        if newStr ~= descStr then
        	obj:setString(newStr)
        end
    end
end

function UIShareDialog:shareBtnCallBack(obj)
	self.descLab:didNotSelectSelf()

	local limitLen = getPVPShareConfig().ShareDescLength*2
	local descStr = self.descLab:getString()
	local length = CsbTools.stringWidth(descStr)
	if length > limitLen then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2181))
		return
	end

	self.shareResult = true

	UIManager.close()
end

return UIShareDialog