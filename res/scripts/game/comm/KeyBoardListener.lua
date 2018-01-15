require "common.PushManager"

local KeyBoardListener = class("KeyBoardListener")

local tipsFile = "ui_new/g_gamehall/g_gpub/TipPanel.csb"

local isOpenEndTips = false

function KeyBoardListener:ctor()
	function keyboardReleased(keyCode, event)
		if keyCode == 6 then
			if isOpenEndTips then
				self:closeEndTips()
			else				
				self:openEndTips()
			end
		end
    end

	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(keyboardReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, -1)
end

function KeyBoardListener:openEndTips()
	if isOpenEndTips then return end

	isOpenEndTips = true

	if not self.tipsNode and cc.Director:getInstance():getRunningScene() then
		self.tipsNode = cc.CSLoader:createNode(tipsFile)
		cc.Director:getInstance():getRunningScene():addChild(self.tipsNode, 10000000)

		CommonHelper.layoutNode(self.tipsNode)
		
		CsbTools.getChildFromPath(self.tipsNode, "BuyEnergyPanel/BarNameLabel")
			:setString(CommonHelper.getUIString(605))

		CsbTools.getChildFromPath(self.tipsNode, "BuyEnergyPanel/TipLabel1")
			:setString(CommonHelper.getUIString(1500))

		CsbTools.initButton(
			CsbTools.getChildFromPath(self.tipsNode, "BuyEnergyPanel/ConfrimButton")
			, function()
				gCheckPush() -- 检测推送
				closeGame()
			end
			, CommonHelper.getUIString(500), "Button_Confrim/ButtomName", "Button_Confrim")

		CsbTools.initButton(
			CsbTools.getChildFromPath(self.tipsNode, "BuyEnergyPanel/CancelButton")
			, function()
				self:closeEndTips()
			end
			, CommonHelper.getUIString(501), "Button_Cancel/ButtomName", "Button_Cancel")
	end

    if not self.tipsNode then
        return 
    end
    
    if UIManager.isTopUI(UIManager.UI.UINoticeActivity) then
        UIManager.close()
    end

	CommonHelper.playCsbAnimate(self.tipsNode, tipsFile, "Open", false, nil, true)
	self.tipsNode:registerScriptHandler(function(eventType)
		if eventType == "exit" then
			self.tipsNode = nil
			isOpenEndTips = false
		end
	end)
end

function KeyBoardListener:closeEndTips()
	if self.tipsNode then
		isOpenEndTips = false
		CommonHelper.playCsbAnimate(self.tipsNode, self.closeTipsAct, "Close", false, function()
			if not isOpenEndTips and self.tipsNode then
				self.tipsNode:removeFromParent()
				self.tipsNode = nil
				isOpenEndTips = false
			end
		end, true)
    else
        isOpenEndTips = false
	end 
end

return KeyBoardListener