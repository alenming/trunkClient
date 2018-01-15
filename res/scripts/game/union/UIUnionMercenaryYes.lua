--[[
	请求可否召回的提示
--]]

local UIUnionMercenaryYes = class("UIUnionMercenaryYes", function ()
	return require("common.UIView").new()
end)

-- csb文件
local csbFile = ResConfig.UIUnionMercenary.Csb2


function UIUnionMercenaryYes:ctor()
	self.rootPath = csbFile.UIUnionMercenaryYes
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mNo = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
	CsbTools.initButton(self.mNo, handler(self, self.BtnCallbackNo), nil, nil, "Text")

	self.mYes = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
	CsbTools.initButton(self.mYes, handler(self, self.BtnCallBackYes), nil, nil, "Text")

	self.mTips = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TipLabel1")
	self.mTips:setString(CommonHelper.getUIString(1992))
end

function UIUnionMercenaryYes:onOpen(preId,tag, callback)
	self.mCallback = callback
	self.mTag = tag
end

function UIUnionMercenaryYes:onClose()
	
end

function UIUnionMercenaryYes:BtnCallBackYes(obj)
	self.mCallback(self.mTag)
	UIManager.close()
end

function UIUnionMercenaryYes:BtnCallbackNo(obj)
	UIManager.close()
end

return UIUnionMercenaryYes