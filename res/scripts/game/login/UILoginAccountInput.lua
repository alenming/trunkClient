local UILoginAccountInput = class("UILoginAccountInput", function()
    return require("common.UIView").new()
end)

local keyIsRemember = "RememberIDAndKey"
local keyDefaultID = "DefaultID"
local keyDefaultKey = "DefaultKey"

function UILoginAccountInput:ctor()
	self.rootPath = ResConfig.UILoginAccountInput.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")

	self.loginPanel = CsbTools.getChildFromPath(self.mainPanel, "LoginInput")

	self.idTextField = CsbTools.getChildFromPath(self.loginPanel, "IDBar/IDTextField")

	self.keyTextField = CsbTools.getChildFromPath(self.loginPanel, "KeyBar/KeyTextField")
	self.keyTextField:setPasswordEnabled(true)
	self.keyTextField:setPasswordStyleText("*")

	self.rememberCheckBox = CsbTools.getChildFromPath(self.loginPanel, "RecordTips/CheckBox")
	self.rememberCheckBox:addEventListener(function (_, event) 
		cc.UserDefault:getInstance():setBoolForKey(keyIsRemember, event == 0) -- 0 is selected
	end)

	self.loginButton = CsbTools.getChildFromPath(self.loginPanel, "EnterButton")
	CsbTools.initButton(self.loginButton, function () 
		local id = self.idTextField:getString()
		local key = self.keyTextField:getString()

		if #id == 0 then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2165))
			return
		elseif #key == 0 then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2164))
			return
		end

		local BufferData = NetHelper.createBufferData(MainProtocol.Login, LoginProtocol.LoginExistUserCS)
        BufferData:writeInt(1)
        BufferData:writeCharArray(id, 128)
        BufferData:writeCharArray(cryptoMd5(key), 256)
        NetHelper.request(BufferData)

        self.buffID = id
        self.buffKey = key
	end)

	self.tips = CsbTools.getChildFromPath(self.loginPanel, "Tips")
	self.tips:setString("")

	self.eventLoginResultHandler = handler(self, self.onLogin)
	EventManager:addEventListener(GameEvents.EventLoginResult, self.eventLoginResultHandler)
end

function UILoginAccountInput:onOpen()
	local isRemember = cc.UserDefault:getInstance():getBoolForKey(keyIsRemember)
	if isRemember then
		local id = cc.UserDefault:getInstance():getStringForKey(keyDefaultID)
		self.idTextField:setString(id)

		local key = cc.UserDefault:getInstance():getStringForKey(keyDefaultKey)
		self.keyTextField:setString(key)

		self.rememberCheckBox:setSelected(true)
	else
		self.idTextField:setString("")
		self.keyTextField:setString("")
		self.rememberCheckBox:setSelected(false)
	end
end

function UILoginAccountInput:onClose()
	EventManager:removeEventListener(GameEvents.EventLoginResult, self.eventLoginResultHandler)
end

function UILoginAccountInput:onLogin(_, result)
	if result == "fail" then
		CsbTools.addTipsToRunningScene(getUILanConfItem(2164))
	elseif result == "success" then
		if self.rememberCheckBox:isSelected() then
    		cc.UserDefault:getInstance():setStringForKey(keyDefaultID, self.buffID)
    		cc.UserDefault:getInstance():setStringForKey(keyDefaultKey, self.buffKey)
    	end
	end
end

return UILoginAccountInput