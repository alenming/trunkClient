--[[
	审核设置界面界面
	1. 设置限制等级
	2. 设置自动通过
--]]

local UIAuditSet = class("UIAuditSet", function ()
	return require("common.UIView").new()
end)

require("common.WidgetExtend")
require("game.union.UnionHelper")

-- csb文件
local csbFile = ResConfig.UIAuditSet.Csb2

local unionModel = getGameModel():getUnionModel()

function UIAuditSet:ctor()
	self.rootPath = csbFile.auditSet
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.limitLvLab = CsbTools.getChildFromPath(self.root, "MainPanel/Num")
	self.reduceBtn = CsbTools.getChildFromPath(self.root, "MainPanel/DelButton")
	self.addBtn = CsbTools.getChildFromPath(self.root, "MainPanel/AddButton")
	self.autoAuditBtn = CsbTools.getChildFromPath(self.root, "MainPanel/SwitchButton")
	self.cancelBtn = CsbTools.getChildFromPath(self.root, "MainPanel/CancelButton")
	self.confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
	self.autoAuditCsb = CsbTools.getChildFromPath(self.autoAuditBtn, "SoundSwitch")

	WidgetExtend.extendHold(self.reduceBtn)
    self.reduceBtn:addHoldCallbackEX(0.1, 0, handler(self, self.reduceBtnCallBack))
    CsbTools.initButton(self.reduceBtn, handler(self, self.reduceBtnCallBack))

	WidgetExtend.extendHold(self.addBtn)
    self.addBtn:addHoldCallbackEX(0.1, 0, handler(self, self.addBtnCallBack))
    CsbTools.initButton(self.addBtn, handler(self, self.addBtnCallBack))

    CsbTools.initButton(self.autoAuditBtn, handler(self, self.autoAuditBtnCallBack), nil, nil, "SoundSwitch")
    CsbTools.initButton(self.cancelBtn, handler(self, self.cancelBtnCallBack), nil, nil, "ButtonName")
    CsbTools.initButton(self.confirmBtn, handler(self, self.confirmBtnCallBack), nil, nil, "ButtonName")
end

function UIAuditSet:onOpen()
	-- 服务器回调监听
	local cmdAuditSet = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionSetAuditSC)
	self.auditSetHandler = handler(self, self.onAuditSet)
	NetHelper.setResponeHandler(cmdAuditSet, self.auditSetHandler)

	self.limitLv = unionModel:getLimitLv()
	self.autoAudit = unionModel:getIsAutoAudit()

	self.limitLvLab:setString(self.limitLv)
	if self.autoAudit == 1 then
		CommonHelper.playCsbAnimation(self.autoAuditCsb, "CloseToOpen", false, nil)
	else
		CommonHelper.playCsbAnimation(self.autoAuditCsb, "OpenToClose", false, nil)
	end
end

function UIAuditSet:onClose()
	-- 取消监听
	local cmdAuditSet = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionSetAuditSC)
	NetHelper.removeResponeHandler(cmdAuditSet, self.auditSetHandler)
end

function UIAuditSet:reduceBtnCallBack(obj)
	if self.limitLv > 1 then
		self.limitLv = self.limitLv - 1
		self.limitLvLab:setString(self.limitLv)
	end
end

function UIAuditSet:addBtnCallBack(obj)
	if self.limitLv < 99 then
		self.limitLv = self.limitLv + 1
		self.limitLvLab:setString(self.limitLv)
	end
end

function UIAuditSet:autoAuditBtnCallBack(obj)
	if self.autoAudit == 1 then
		self.autoAudit = 0
		CommonHelper.playCsbAnimation(self.autoAuditCsb, "OpenToClose", false, nil)
	else
		self.autoAudit = 1
		CommonHelper.playCsbAnimation(self.autoAuditCsb, "CloseToOpen", false, nil)
	end
end

function UIAuditSet:cancelBtnCallBack(obj)
	UIManager.close()
end

function UIAuditSet:confirmBtnCallBack(obj)
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionSetAudit)
	buffer:writeInt(self.limitLv)
	buffer:writeInt(self.autoAudit)
	NetHelper.request(buffer)

	print("self.limitLv, self.autoAudit2", self.limitLv, self.autoAudit)
end

function UIAuditSet:onAuditSet(mainCmd, subCmd, data)
	local result = data:readChar()
	if result == UnionHelper.UnionErrorCode.Success then
		self.limitLv = data:readInt()
		self.autoAudit = data:readInt()
		print("self.limitLv, self.autoAudit3", self.limitLv, self.autoAudit)
		--修改模型
		unionModel:setLimitLv(self.limitLv)
		unionModel:setIsAutoAudit(self.autoAudit)

		UIManager.close()
	else
		CsbTools.addTipsToRunningScene(UnionHelper.getErrorCodeStr(result))
	end
end

return UIAuditSet