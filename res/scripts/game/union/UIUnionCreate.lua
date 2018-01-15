--[[
	公会创建界面，主要实现以下内容
	1. 公会创建
--]]

local UIUnionCreate = class("UIUnionCreate", function ()
	return require("common.UIView").new()
end)

require("game.union.UnionHelper")

function UIUnionCreate:ctor()
	self.rootPath = ResConfig.UIUnionCreate.Csb2.create
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.createCost = getUnionConfItem().CostCoin
	-- 创建公会消耗tips
	local createTipLab = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/GoldNum")
	createTipLab:setString(self.createCost)

	-- 取消创建按钮
	local cancelBtn = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/CancelButton")
	CsbTools.initButton(cancelBtn, function()
		UIManager.close()
	end, CommonHelper.getUIString(501), "CancelButton/Text", "Text", "Text")

	-- 确认创建按钮
	self.confirmBtn = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/ConfrimButton")
	CsbTools.initButton(self.confirmBtn, handler(self, self.confirmBtnCallBack), 
		CommonHelper.getUIString(500), "ConfrimButton/Text", "Text",  "Text")

	-- 公会名
	self.unionNameField = CsbTools.getChildFromPath(self.root, "BuyEnergyPanel/TextField_1")
	self.unionNameField:setPlaceHolderColor(cc.c4b(240,240,240, 50))
end

function UIUnionCreate:onOpen()
	self.unionNameField:setString("")
	-- 创建回调监听
	local cmdUnionCreate = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionCreateSC)
	self.unionCreateHandler = handler(self, self.onUnionCreate)
	NetHelper.setResponeHandler(cmdUnionCreate, self.unionCreateHandler)

	self.confirmBtn:setTouchEnabled(true)
end

function UIUnionCreate:onClose()
	self.unionNameField:didNotSelectSelf()
	-- 删除创建回调监听
	local cmdUnionCreate = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionCreateSC)
	NetHelper.removeResponeHandler(cmdUnionCreate, self.unionCreateHandler)
end

function UIUnionCreate:confirmBtnCallBack(obj)
	-- 判断金币是否足够
	local userGold = getGameModel():getUserModel():getGold()
	local costGold = getUnionConfItem().CostCoin
	if userGold < costGold then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(572))
		return
	end

	-- 判断是否在冷却时间内
	local applyStamp = getGameModel():getUnionModel():getApplyStamp()
	local sec = applyStamp - getGameModel():getNow()
	if sec > 0 then
		local hour = math.floor(sec/3600)
		local min = math.ceil((sec%3600)/60)
		local tipStr = string.format(CommonHelper.getUIString(306), hour, min)
		CsbTools.addTipsToRunningScene(tipStr)
		return
	end

	-- 获取公会名
	local unionName = self.unionNameField:getString()

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

	-- 都满足请求创建公会
	self.confirmBtn:setTouchEnabled(false)
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionCreateCS)
	buffer:writeCharArray(unionName, 20)
	NetHelper.request(buffer)
end

function UIUnionCreate:onUnionCreate(mainCmd, subCmd, data)
	self.unionNameField:didNotSelectSelf()
	self.confirmBtn:setTouchEnabled(true)

	local result = data:readChar()
	if result == 1 then
		local unionID = data:readInt()
		local unionName = self.unionNameField:getString()

		-- 修改模型
		ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -self.createCost)
		local unionModel = getGameModel():getUnionModel()
		unionModel:setHasUnion(1)
		unionModel:setUnionID(unionID)
		unionModel:setUnionName(unionName)
		unionModel:setPos(UnionHelper.pos.Chairman)

		-- 广播通知
		EventManager:raiseEvent(GameEvents.EventOwnUnion, {})
        RedPointHelper.updateUnion()
        ChatHelper.joinRoom(ChatHelper.ChatMode.UNION, unionModel:getUnionID())

		-- 进入公会场景
		SceneManager.loadScene(SceneManager.Scene.SceneUnion)
	else
		local errorCode = data:readInt()
		CsbTools.addTipsToRunningScene(UnionHelper.getErrorCodeStr(errorCode))
	end
end

return UIUnionCreate