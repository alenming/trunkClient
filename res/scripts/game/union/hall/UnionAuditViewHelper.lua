--[[
	公会审核协助管理，主要实现以下内容
	1. 显示审核列表信息:
		名称, 等级, 
	2. 通过, 拒绝功能
--]]

local UnionAuditViewHelper = class("UnionAuditViewHelper")

require("game.union.UnionHelper")

local csbFile = ResConfig.UIUnionHall.Csb2

local unionModel = getGameModel():getUnionModel()

function UnionAuditViewHelper:ctor(uiUnionHall, csb)
	self.uiUnionHall = uiUnionHall
	self.root = csb

	-- 缓存公会成员列表
	self.items = {}
	self.itemsCache = {}

	-- 审核设置按钮
	self.auditSetBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/SetButton")
	-- 全部拒绝按钮
	self.allUnAgreeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/AllRejectButton")
	-- 全部接受按钮
	self.allAgreeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/AllAdpotButton")

	CsbTools.initButton(self.auditSetBtn, handler(self, self.auditSetCallBack), nil, nil, "Text")
	CsbTools.initButton(self.allUnAgreeBtn, handler(self, self.allUnAgreeCallBack), nil, nil, "Text")
	CsbTools.initButton(self.allAgreeBtn, handler(self, self.allAgreeCallBack), nil, nil, "Text")
	self.allUnAgreeBtn:setVisible(false)
	self.allAgreeBtn:setVisible(false)

	-- 滚动列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/ScrollView")
	self.scroll:removeAllChildren()
    self.scroll:setScrollBarEnabled(false)
	-- 单个成员列表的大小
	local itemCsb 	= getResManager():getCsbNode(csbFile.auditItem)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel"):getContentSize()
    itemCsb:cleanup()
end

function UnionAuditViewHelper:onOpen()
	-- 是否将界面刷新出来过
	self.hasRfresh = false

	-- 服务器回调监听
	local cmdAuditList = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionAuditListSC)
	self.auditListHandler = handler(self, self.onAuditList)
	NetHelper.setResponeHandler(cmdAuditList, self.auditListHandler)

	local cmdAudit = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionAuditSC)
	self.auditHandler = handler(self, self.onAudit)
	NetHelper.setResponeHandler(cmdAudit, self.auditHandler)

	self.auditList = unionModel:getAuditList()

	self:refreshUI()
end

function UnionAuditViewHelper:onClose()
	-- 取消监听
	local cmdAuditList = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionAuditListSC)
	NetHelper.removeResponeHandler(cmdAuditList, self.auditListHandler)

	local cmdAudit = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionAuditSC)
	NetHelper.removeResponeHandler(cmdAudit, self.auditHandler)
end

function UnionAuditViewHelper:onTop(uiID)

end

function UnionAuditViewHelper:setVisible(visiable)
	self.root:setVisible(visiable)

	if visiable == true then
		if UnionHelper.reGetStamp.unionAuditList <= getGameModel():getNow() then
			-- 发包未收到数据时, 默认6秒可以再次发包获取数据
			UnionHelper.reGetStamp.unionAuditList = getGameModel():getNow() + 6
			-- 请求审核数据
			local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionAuditListCS)
			NetHelper.request(buffer)
		else
			if not self.hasRfresh or self.preSortType ~= self.sortType then
				self:refreshUI()
			end			
		end
	end
end

function UnionAuditViewHelper:cacheItems()
	for i,v in ipairs(self.items) do
		v:setVisible(false)
		v:setTag(-1000 - v:getTag())
		table.insert(self.itemsCache, v)
	end
	self.items = {}
end

function UnionAuditViewHelper:refreshUI()
	if not self.root:isVisible() then
		return
	end

	if self.auditList then
		self.hasRfresh = true
		self:cacheItems()

		self.allUnAgreeBtn:setVisible(#self.auditList > 0 and true or false)
		self.allAgreeBtn:setVisible(#self.auditList > 0 and true or false)

		local innerSize = self.scroll:getContentSize()
		local height = (self.itemSize.height + 2) * (#self.auditList)
		if height > innerSize.height then
			innerSize.height = height
			self.scroll:setInnerContainerSize(innerSize)
		end

		for i,v in ipairs(self.auditList) do
			self:addItem(v, cc.p(self.itemSize.width / 2, innerSize.height - (i - 0.5) * (self.itemSize.height + 2)))
		end
	end
end

function UnionAuditViewHelper:resetDataValidity()
	UnionHelper.reGetStamp.unionAuditList = 0
end

function UnionAuditViewHelper:resetHasRefresh()
	self.hasRfresh = false
end

function UnionAuditViewHelper:addItem(info, pos)
	local itemCsb = nil
	if #self.itemsCache ~= 0 then
		itemCsb = self.itemsCache[#self.itemsCache]
		table.remove(self.itemsCache, #self.itemsCache)
		itemCsb:setVisible(true)
	else
		itemCsb 	= getResManager():cloneCsbNode(csbFile.auditItem)
		self.scroll:addChild(itemCsb)
		local agreeBtn = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/AdpotButton")
		local unAgreeBtn = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/RejectButton")
		CsbTools.initButton(agreeBtn, handler(self, self.agreeBtnCallBack))
		CsbTools.initButton(unAgreeBtn, handler(self, self.unAgreeBtnCallBack))
	end

	table.insert(self.items, itemCsb)

	local agreeBtn = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/AdpotButton")
	local unAgreeBtn = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/RejectButton")
	local nameLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Name")
	local idLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Num")
	local lvLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Level")
    local tencentLogo = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/TencentLogo")

	nameLab:setString(info.userName)
	idLab:setString(info.userID)
	lvLab:setString(info.userLv)
    CommonHelper.showBlueDiamond(tencentLogo, CommonHelper.getIdentity(info.identity))

	itemCsb:setPosition(pos)
	itemCsb:setTag(info.userID)
	agreeBtn:setTag(info.userID)
	unAgreeBtn:setTag(info.userID)
end

function UnionAuditViewHelper:agreeBtnCallBack(obj)
	local userID = obj:getTag()
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionAuditCS)
	buffer:writeChar(1)
	buffer:writeChar(1)
	buffer:writeInt(userID)
	NetHelper.request(buffer)
end

function UnionAuditViewHelper:unAgreeBtnCallBack(obj)
	local userID = obj:getTag()
	local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionAuditCS)
	buffer:writeChar(0)
	buffer:writeChar(1)
	buffer:writeInt(userID)
	NetHelper.request(buffer)
end

function UnionAuditViewHelper:auditSetCallBack(obj)
	UIManager.open(UIManager.UI.UIAuditSet)
end

function UnionAuditViewHelper:allUnAgreeCallBack(obj)
	if #self.auditList > 0 then
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionAuditCS)
		buffer:writeChar(0)
		buffer:writeChar(#self.auditList)
		for i,v in ipairs(self.auditList) do
			buffer:writeInt(v.userID)
		end
		NetHelper.request(buffer)
	end
end

function UnionAuditViewHelper:allAgreeCallBack(obj)
	if #self.auditList > 0 then
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionAuditCS)
		buffer:writeChar(1)
		buffer:writeChar(#self.auditList)
		for i,v in ipairs(self.auditList) do
			buffer:writeInt(v.userID)
		end
		NetHelper.request(buffer)
	end
end

function UnionAuditViewHelper:onAuditList(mainCmd, subCmd, data)
	-- 收到数据, 设置再次获取数据的时间戳为5分钟后
	UnionHelper.reGetStamp.unionAuditList = getGameModel():getNow() + 300

	self.auditList = {}
	local count = data:readChar()
	for i=1, count do
		self.auditList[i] = {}
		self.auditList[i].userID = data:readInt()
		self.auditList[i].userLv = data:readInt()
        self.auditList[i].identity = data:readInt()
		self.auditList[i].userName = data:readCharArray(20)
	end

	unionModel:setAuditList(self.auditList)
    RedPointHelper.setCount(RedPointHelper.System.Union, 
        #self.auditList > 0 and 1 or nil, RedPointHelper.UnionSystem.Audit)

	CsbTools.printValue(self.auditList, "onAuditList")
	self:refreshUI()
end

function UnionAuditViewHelper:onAudit(mainCmd, subCmd, data)
	local result = data:readChar()

	local agreeIDs = {}
	local unAgreeIDs = {}
	local agreeCount = data:readChar()
	local unAgreeCount = data:readChar()

	for i=1, agreeCount do
		agreeIDs[i] = data:readInt()
	end
	for i=1, unAgreeCount do
		unAgreeIDs[i] = data:readInt()
	end

	-- 修改UI显示
	for _, id in ipairs(agreeIDs) do
		local findIndex = nil
		for i, info in ipairs(self.auditList) do
			if info.userID == id then
				findIndex = i
				break
			end
		end
		if findIndex then
			table.remove(self.auditList, findIndex)
		else
			print("!!!1 not find auditInfo", id)
		end
	end

	for _, id in ipairs(unAgreeIDs) do
		local findIndex = nil
		for i, info in ipairs(self.auditList) do
			if info.userID == id then
				findIndex = i
				break
			end
		end
		if findIndex then
			table.remove(self.auditList, findIndex)
		else
			print("!!!2 not find auditInfo", id)
		end		
	end
	unionModel:setAuditList(self.auditList)
	self.hasRfresh = false
	self:refreshUI()
	-- 设置公会信息界面, 公会成员界面需要刷新
	self.uiUnionHall:agreeAudit()

	if #self.auditList <= 0 then
        RedPointHelper.addCount(RedPointHelper.System.Union, -1, RedPointHelper.UnionSystem.Audit)
        self.uiUnionHall:showRedPoint(self.root:getTag())
    end
    
	if result ~= UnionHelper.UnionErrorCode.Success and result ~= UnionHelper.UnionErrorCode.PassAudit and 
		result ~= UnionHelper.UnionErrorCode.RefuseAudit then

		CsbTools.addTipsToRunningScene(UnionHelper.getErrorCodeStr(result))
	end
end

return UnionAuditViewHelper