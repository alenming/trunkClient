local UIInputPassword = class("UIInputPassword", function () 
	return require("common.UIView").new()
end)

function UIInputPassword:ctor()
	self.rootPath = ResConfig.UIInputPassword.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")

	self.codeInputTextField = CsbTools.getChildFromPath(self.mainPanel, "CodeInputField")
	self.codeInputTextField:setPasswordEnabled(true)
	self.codeInputTextField:setPasswordStyleText("*")

	self.codeInputAgainTextField = CsbTools.getChildFromPath(self.mainPanel, "CodeInputField_0")
	self.codeInputAgainTextField:setPasswordEnabled(true)
	self.codeInputAgainTextField:setPasswordStyleText("*")

	self.cancelButton = CsbTools.getChildFromPath(self.mainPanel, "CancelButton")
	CsbTools.initButton(self.cancelButton, function ()
		UIManager.close()
	end)

	self.sureButton = CsbTools.getChildFromPath(self.mainPanel, "ConfrimButton")
	CsbTools.initButton(self.sureButton, function ()
		local firstCode = self.codeInputTextField:getString()
		local secondCode = self.codeInputAgainTextField:getString()

		if #firstCode == 0 then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2157))
			return
		elseif #firstCode < 6 then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2159))
			return
		end

		if #secondCode == 0 then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2158))
			return
		elseif firstCode ~= secondCode then
			CsbTools.addTipsToRunningScene(getUILanConfItem(2161))
			return 
		end

		print(firstCode)

		local bufferData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.UserModifyPSCS)
        bufferData:writeInt(1)  -- 渠道id
        bufferData:writeCharArray(cryptoMd5(firstCode), 32)
        NetHelper.request(bufferData)
	end)
end

function UIInputPassword:onOpen()
	self.codeInputTextField:setString("")
	self.codeInputAgainTextField:setString("")

	local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.UserModifyPSSC)
	self.userModifyPSSCHandler = function (_, _, buffData) 
    	local flag = buffData:readInt()
    	print(flag)
    	if flag == 1 then
    		CsbTools.addTipsToRunningScene(getUILanConfItem(2160))
    		UIManager.close()
    	end
    end
    NetHelper.setResponeHandler(cmd, self.userModifyPSSCHandler)
end

function UIInputPassword:onClose()
	if self.userModifyPSSCHandler then
		local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.UserModifyPSSC)
        NetHelper.removeResponeHandler(cmd, self.userModifyPSSCHandler)
        self.userModifyPSSCHandler = nil
	end
end

return UIInputPassword