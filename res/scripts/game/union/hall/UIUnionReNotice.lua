--[[
	公会主界面
	1. 显示公会建筑物
--]]

local UIUnionReNotice = class("UIUnionReNotice", function ()
	return require("common.UIView").new()
end)

-- csb文件
local csbFile = ResConfig.UIUnionReNotice.Csb2

local unionModel = getGameModel():getUnionModel()

function UIUnionReNotice:ctor()
	self.rootPath = csbFile.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	local mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
	mainPanel:addClickEventListener(function()
		UIManager.close()
	end)

	-- 公会名文本
	self.noticeField = CsbTools.getChildFromPath(self.root, "MainPanel/InputField")
	self.noticeField:setPlaceHolder(CommonHelper.getUIString(1980))
	self.noticeField:setPlaceHolderColor(cc.c4b(240,240,240, 50))

	-- 确认按钮
	self.confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
	CsbTools.initButton(self.confirmBtn, handler(self, self.confirmBtnCallBack))
end

function UIUnionReNotice:onOpen()
	self.noticeField:setString("")
	self.confirmBtn:setTouchEnabled(true)

	-- 服务器回调监听
	local cmdReNotice = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionNoticeSC)
	self.reNoticeHandler = handler(self, self.onReNotice)
	NetHelper.setResponeHandler(cmdReNotice, self.reNoticeHandler)
end

function UIUnionReNotice:onClose()
	self.noticeField:didNotSelectSelf()
	-- 取消监听
	local cmdReName = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionNoticeSC)
	NetHelper.removeResponeHandler(cmdReName, self.reNoticeHandler)
end

function UIUnionReNotice:confirmBtnCallBack(obj)
	self.noticeField:didNotSelectSelf()
	-- 获取公告
	local unionNotice = self.noticeField:getString()

	-- 判断长度是否符合
	local length = CsbTools.stringWidth(unionNotice)
	if length > 60 then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(433))
		return
	end

	-- 判断公会名是否合法
	local newUnionName = FilterSensitive.FilterStr(unionNotice)
	if unionNotice == "" or newUnionName ~= unionNotice then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2037))
		return
	end

	-- 都满足发送改公告协议
	self.confirmBtn:setTouchEnabled(false)
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionNoticeCS)
	buffer:writeCharArray(unionNotice, 128)
	NetHelper.request(buffer)
end

function UIUnionReNotice:onReNotice(mainCmd, subCmd, data)
	self.confirmBtn:setTouchEnabled(true)

	local result = data:readChar()
	if result == 1 then
		-- 设置模型
		local notice = self.noticeField:getString()
		unionModel:setUnionNotice(notice)
		
		-- 关闭界面
		UIManager.close()

	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
	end

end

return UIUnionReNotice