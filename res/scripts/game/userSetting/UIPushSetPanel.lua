require("common.PushManager")

local UIPushSetPanel = class("UIPushSetPanel", function ()
	return require("common.UIView").new()
end)

function UIPushSetPanel:ctor()

end

function UIPushSetPanel:init()
	self.rootPath = ResConfig.UIPushSetPanel.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mPushSetPanel = CsbTools.getChildFromPath(self.root, "PushSetPanel")

	self.mTipLabel = CsbTools.getChildFromPath(self.mPushSetPanel, "TipLabel1")
	self.mTipLabel:setString(getUILanConfItem(37))

	self.mTipLabel0 = CsbTools.getChildFromPath(self.mPushSetPanel, "TipLabel1_0")
	self.mTipLabel0:setVisible(false)

	self.mCloseButton0 = CsbTools.getChildFromPath(self.mPushSetPanel, "CloseButton_0")
    CsbTools.initButton(self.mCloseButton0, handler(self, self.onClick))

    self.mOpenButton = CsbTools.getChildFromPath(self.mPushSetPanel, "OpenButton")
    CsbTools.initButton(self.mOpenButton, handler(self, self.onClick))

    self.mOnOffButton = CsbTools.getChildFromPath(self.mOpenButton, "OnOffButton")
    self.mImgOn = CsbTools.getChildFromPath(self.mOnOffButton, "Image_On")
    self.mImgOff = CsbTools.getChildFromPath(self.mOnOffButton, "Image_Off")

    self.mOn = PushManager:getInstance():isOn()
   	self.mImgOn:setVisible(self.mOn)
   	self.mImgOff:setVisible(not self.mOn)
end

function UIPushSetPanel:onOpen()

end

function UIPushSetPanel:onClick(obj)
	local name = obj:getName()
	if name == "CloseButton_0" then
		UIManager.close()
	elseif name == "OpenButton" then
		self:setOn(not self.mOn)
	end
end

function UIPushSetPanel:setOn(on)
	self.mOn = on

	self.mImgOn:setVisible(on)
	self.mImgOff:setVisible(not on)

	PushManager:getInstance():setOn(on)
end

return UIPushSetPanel