--[[
	公会主界面
	1. 显示公会建筑物
--]]

local UIUnionReName = class("UIUnionReName", function ()
	return require("common.UIView").new()
end)

-- csb文件
local csbFile = ResConfig.UIUnionReName.Csb2

local unionModel = getGameModel():getUnionModel()

function UIUnionReName:ctor()
	self.rootPath = csbFile.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	local mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
	mainPanel:addClickEventListener(function()
		UIManager.close()
	end)

	-- 公会名文本
	self.nameField = CsbTools.getChildFromPath(self.root, "MainPanel/InputField")
	self.nameField:setPlaceHolder(CommonHelper.getUIString(1981))
	self.nameField:setPlaceHolderColor(cc.c4b(240,240,240, 50))

	-- 确认按钮
	self.confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
	CsbTools.initButton(self.confirmBtn, handler(self, self.confirmBtnCallBack), 
		"" .. getUnionConfItem().ChangeNameCost, "PriceNum", "PriceNum")

	-- 提示文字
	local tipsLab = CsbTools.getChildFromPath(self.root, "MainPanel/TipsText_2")
	tipsLab:setString(string.format(CommonHelper.getUIString(1670), getUnionConfItem().ChangeNameCost))
end

function UIUnionReName:onOpen()
	self.nameField:setString("")
	self.confirmBtn:setTouchEnabled(true)

	-- 服务器回调监听
	local cmdReName = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionNameSC)
	self.reNameHandler = handler(self, self.onReName)
	NetHelper.setResponeHandler(cmdReName, self.reNameHandler)
end

function UIUnionReName:onClose()
	self.nameField:didNotSelectSelf()
	-- 取消监听
	local cmdReName = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionNameSC)
	NetHelper.removeResponeHandler(cmdReName, self.reNameHandler)
end

function UIUnionReName:confirmBtnCallBack(obj)
	self.nameField:didNotSelectSelf()

	-- 判断钻石是否足够
	local userDiamond = getGameModel():getUserModel():getDiamond()
	local costDiamond = getUnionConfItem().ChangeNameCost
	if userDiamond < costDiamond then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
		return
	end

	-- 获取公会名
	local unionName = self.nameField:getString()

	-- 判断长度是否符合
	local length = CsbTools.stringWidth(unionName)
	if length > 12 then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(304))
		return
	end

	-- 判断公会名是否合法
	local newUnionName = FilterSensitive.FilterStr(unionName)
	if unionName == "" or newUnionName ~= unionName then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(305))
		return
	end

	-- 判断是否重名
	if unionName == unionModel:getUnionName() then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(953))
		return
	end

	-- 都满足请求创建公会
	self.confirmBtn:setTouchEnabled(false)
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionNameCS)
	buffer:writeCharArray(unionName, 20)
	NetHelper.request(buffer)
end

function UIUnionReName:onReName(mainCmd, subCmd, data)
	self.confirmBtn:setTouchEnabled(true)

	local result = data:readChar()	
	if result == 1 then
		-- 设置模型
		local unionName = self.nameField:getString()
		unionModel:setUnionName(unionName)
		ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -getUnionConfItem().ChangeNameCost)

		-- 关闭界面
		UIManager.close()
		
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
	end
end

return UIUnionReName