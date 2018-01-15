--[[
	二次提示确认框，主要实现以下内容
	1. 弹出二次确认框
	2. 确认取消回调通知
--]]

local UIDialogBox = class("UIDialogBox", require("common.UIView"))

function UIDialogBox:ctor()
	self.rootPath 	= ResConfig.UIDialogBox.Csb2.dialog
	self.root 		= getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

    self.root:setLocalZOrder(10)
end

--[[
args = {
	title 		= 标题,
	msg 		= 确认内容
	confirmFun 	= 确认框显示确认回调
	cancelFun	= 确认框取消回调
}
--]]
function UIDialogBox:onOpen(openerUIID, args)
	local titleStr 	= args.title or CommonHelper.getUIString(605)
	local msgStr 	= args.msg or "msg is nil"
	local confirmFun= args.confirmFun
	local cancelFun	= args.cancelFun

	local titleLab = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/BarNameLabel")
	local msgLab 	= CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel1")
	local confirmBtn = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
	local cancelBtn = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")

	titleLab:setString(titleStr)
	msgLab:setString(msgStr)

	CsbTools.initButton(confirmBtn, function()
		if type(confirmFun) == "function" then
			confirmFun()
		end
		UIManager.close()
	end, CommonHelper.getUIString(args.rightLanId or 500), "Button_Confrim/Text", "Text")

	CsbTools.initButton(cancelBtn, function()
		if type(cancelFun) == "function" then
			cancelFun()
		end
		UIManager.close()
	end, CommonHelper.getUIString(args.leftLanId or 501), "Button_Cancel/Text", "Text")

end

return UIDialogBox