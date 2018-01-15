--[[
	公会列表界面，主要实现以下内容
	1. 显示公会列表
	2. 申请公会
	3. 查找公会
	4. 创建公会
--]]

local UIUnionList = class("UIUnionList", function ()
	return require("common.UIView").new()
end)

require("game.union.UnionHelper")

local csbFile	= ResConfig.UIUnionList.Csb2
local unionModel = getGameModel():getUnionModel()

function UIUnionList:ctor()
	self.rootPath 	= csbFile.list
	self.root 		= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function()
		UIManager.close()
	end)

	-- 创建公会按钮
	local createBtn = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/Button_SetGuild")
	CsbTools.initButton(createBtn, handler(self, self.createBtnCallBack), CommonHelper.getUIString(340), 
		"Button_Green/ButtomName", "Button_Green")

	-- 搜索按钮
	self.searchBtn = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/SearchButton")
	CsbTools.initButton(self.searchBtn, handler(self, self.searchBtnCallBack))

	-- 取消搜索按钮
	self.unSearchBtn = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/ReturnButton")
	CsbTools.initButton(self.unSearchBtn, handler(self, self.unSearchBtnCallBack))

	-- 不显示满员公会复选框
	self.checkBox = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/CheckBox_1")
	self.checkBox:setTouchEnabled(true)
	self.checkBox:addEventListener(handler(self, self.notFullCallBack))

	-- 申请个数
	self.applyNumLab = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/NumTex")

	-- 搜索文本
	self.searchTextFiled = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/SearchNameTexField")
	self.searchTextFiled:setPlaceHolder(CommonHelper.getUIString(907))
	self.searchTextFiled:addEventListener(function (ref, type)
		if ref:getString() == "" then
			self.searchBtn:getVirtualRenderer():setState(1)
			self.searchBtn:setTouchEnabled(false)
		else
			self.searchBtn:getVirtualRenderer():setState(0)
			self.searchBtn:setTouchEnabled(true)
		end
	end)

	-- 滚动列表
	self.list = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/GuildListView")
	self.list:addScrollViewEventListener(handler(self, self.listEventCallBack))
	self.list:removeAllChildren()
	self.list:setItemsMargin(5)
	self.list:setBounceEnabled(false)
    self.list:setScrollBarEnabled(false)
	local item = getResManager():getCsbNode(csbFile.item)
	self.itemSize = CsbTools.getChildFromPath(item, "GuildBarPanel"):getContentSize()
	self.listSize = self.list:getContentSize()
end

function UIUnionList:onOpen()
	self.notFull = true			-- 默认显示不满员公会
	self.isSearch = false		-- 非搜索状态
	self.nextRequestListTime = 0-- 再次请求公会列表数据的时间戳
	-- 搜索间隔内可以使用间隔内的搜索次数
	self.requestSearchTime = 0	-- 请求搜索公会时间戳
	self.searchIntervalTime = 60-- 搜索间隔
	self.searchCount = 10		-- 间隔内的搜索次数
	self.curSearchCount = 0		-- 当前使用的搜索次数
	-- 公会列表信息
	self.searchUnionList = {}
	self.fullUnionList = {}
	self.notFullUnionList = {}
	-- 公会申请信息
	self.applyInfo = unionModel:getApplyInfo()
	-- 后端数据全部取完
	self.fullUnionListOver = false
	self.notFullUnionListOver = false

	self.checkBox:setSelected(self.notFull)
	self:clearSearchFiled()
	self.unSearchBtn:setVisible(false)
	self.list:removeAllChildren()

	self:analysisApplyInfo()

	self.applyNumLab:setString(unionModel:getApplyCount() .. "/" .. getUnionConfItem().ApplyCount)

	-- 服务器回调监听
	local cmdUnionApply = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionApplySC)
	local cmdUnionList = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionUnionListOutSC)
	local cmdUnionSearch = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionSearchSC)
	self.unionApplyHandler = handler(self, self.onUnionApply)
	self.unionListHandler = handler(self, self.onUnionList)
	self.unionSearchHandler = handler(self, self.onUnionSearch)
	NetHelper.setResponeHandler(cmdUnionApply, self.unionApplyHandler)
	NetHelper.setResponeHandler(cmdUnionList, self.unionListHandler)
	NetHelper.setResponeHandler(cmdUnionSearch, self.unionSearchHandler)

	self:autoSendRequest()
end

function UIUnionList:onClose()
	self.searchTextFiled:didNotSelectSelf()
	self.list:removeAllChildren()

	-- 取消监听
	local cmdUnionApply = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionApplySC)
	local cmdUnionList = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionUnionListOutSC)
	local cmdUnionSearch = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionSearchSC)
	NetHelper.removeResponeHandler(cmdUnionApply, self.unionApplyHandler)
	NetHelper.removeResponeHandler(cmdUnionList, self.unionListHandler)
	NetHelper.removeResponeHandler(cmdUnionSearch, self.unionSearchHandler)
end

-- 判断申请是否过期, 过期则删除
function UIUnionList:analysisApplyInfo()
	for i=#self.applyInfo, 1, -1 do
		if self.applyInfo[i].applyTime < getGameModel():getNow() then
			-- 切换显示
			local csb = self.list:getChildByTag(self.applyInfo[i].unionID)
			--CommonHelper.playCsbAnimation(csb, "Normal", false, nil)
			CommonHelper.playCsbAnimate(csb, csbFile.item, "Normal", false, nil, true)
			
			table.remove(self.applyInfo, i)
			unionModel:setApplyInfo(self.applyInfo)
		end
	end
end

function UIUnionList:getShowUnionList()
	if self.isSearch then
		return self.searchUnionList
	elseif self.notFull then
		return self.notFullUnionList
	else
		return self.fullUnionList
	end
end

-- 自动判断本地是否有还没显示的数据数据, 有的话不发送, 没有的话发送请求
function UIUnionList:autoSendRequest()
	if self.isSearch then
		-- 搜索时, 直接发送搜索协议
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionSearchCS)
		buffer:writeCharArray(self.searchTextFiled:getString(), 20)
		NetHelper.request(buffer)
	else
		-- 非搜索状态, 获取本地列表数据, 有未显示的数据直接使用本地数据
		local data = self:getShowUnionList()
		local itemCount = #(self.list:getItems())
		if #data > itemCount then
			for i = itemCount+1, itemCount + 10 do
				if data[i] then
					self:addItem(data[i])
				end
			end
		else
			self.nextRequestListTime = getGameModel():getNow() + 2
			local isDataOver = self.notFull and self.notFullUnionListOver or self.fullUnionListOver
			if not isDataOver then
				-- 本地没有未显示的数据, 请求服务器数据
				local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionUnionListOutCS)
				buffer:writeChar(self.notFull and 1 or 0)
				buffer:writeChar(10)
				buffer:writeInt(self.notFull and (#self.notFullUnionList + 1) or (#self.fullUnionList + 1))
				NetHelper.request(buffer)
			end
		end
	end
end

-- 将公会信息保存到列表
function UIUnionList:readUnionInfo(saveList, data, index)
	if index == nil then
		index = #saveList + 1
	end
	if saveList[index] == nil then
		saveList[index] = {}
	end
	saveList[index].index = index
	saveList[index].id = data:readInt()
	saveList[index].lv = data:readInt()
	saveList[index].limitLv = data:readInt()
	saveList[index].emblem = data:readInt()
    saveList[index].identity = data:readInt()
	saveList[index].memberCount = data:readChar()
	saveList[index].unionName = data:readCharArray(20)
	saveList[index].chairmanName = data:readCharArray(20)
	saveList[index].notice = data:readCharArray(128)

	CsbTools.printValue(saveList[index], "unionInfo")

	return saveList[index]
end

function UIUnionList:addItem(info, index)
	if self.list:getChildByTag(info.id) ~= nil then
		return
	end

	local item = self:createItem(info)
	if type(index) == "number" then
	 	self.list:insertCustomItem(item, index)
	else
		self.list:pushBackCustomItem(item)
	end
	return item
end

function UIUnionList:createItem(info)
	local item = ccui.Button:create()
	item:setTouchEnabled(true)
	item:setScale9Enabled(true)
    item:setName("GuildChoiceButton")
	local unionLvConf = getUnionLevelConfItem(info.lv)
	if not unionLvConf then
		print("unionLevelConf is nil", info.lv)
	end

    CsbTools.initButton(item, handler(self, self.itemCallBack))
	local csb = getResManager():cloneCsbNode(csbFile.item)

	local layout = CsbTools.getChildFromPath(csb, "GuildBarPanel")
	-- 会徽
	local emblemImg = CsbTools.getChildFromPath(layout, "GuildLogoItem/Logo/Logo")
	-- 公会id
	local unionIdLab = CsbTools.getChildFromPath(layout, "GuildId")
	-- 公会名
	local unionNameLab = CsbTools.getChildFromPath(layout, "GuildName")
	-- 公会等级
	local unionLvLab = CsbTools.getChildFromPath(layout, "LvTex")
	-- 会长名
	local chairmanNameLab = CsbTools.getChildFromPath(layout, "NameTex")
	-- 人数
	local memberCountLab = CsbTools.getChildFromPath(layout, "NumTex")
	-- 公告
	local noticeLab = CsbTools.getChildFromPath(layout, "GuildTipTex")
	-- 等级限制
	local limitLab = CsbTools.getChildFromPath(layout, "ConditionTipTex")
	-- 公会会徽配置
	local emblemConf = getUnionBadgeConfItem()

	-- 设置位置和结构
	item:setContentSize(layout:getContentSize())
	item:setAnchorPoint(cc.p(0.5,0.5))
	item:setTag(info.id)
	item:addChild(csb)
	csb:setTag(10086)
	csb:setPosition(cc.p(layout:getContentSize().width/2, layout:getContentSize().height/2))

	CsbTools.replaceSprite(emblemImg, emblemConf[info.emblem])
	unionIdLab:setString(info.id)
	unionNameLab:setString(info.unionName)
	unionLvLab:setString(info.lv)
	chairmanNameLab:setString(info.chairmanName)
	memberCountLab:setString(info.memberCount .. "/" .. unionLvConf.MemberLimit)
	noticeLab:setString(info.notice)
	limitLab:setString(string.format(CommonHelper.getUIString(341), info.limitLv))
    -- 蓝钻
    CommonHelper.showBlueDiamond(CsbTools.getChildFromPath(layout, "TencentLogo"),
        math.floor(info.identity%10), math.floor(info.identity/10), chairmanNameLab)
	-- 判断是否已申请
	local isApply = false
	for _, v in ipairs(self.applyInfo) do
		if info.id == v.unionID then
			isApply = true
			break
		end
	end
	-- 切换显示
	--CommonHelper.playCsbAnimation(csb, isApply and "Apply" or "Normal", false, nil)
	CommonHelper.playCsbAnimate(csb, csbFile.item, isApply and "Apply" or "Normal", false, nil, true)

	return item
end

function UIUnionList:clearSearchFiled()	
	self.searchTextFiled:setString("")
	self.searchBtn:setTouchEnabled(false)
	self.searchBtn:getVirtualRenderer():setState(1)
end

function UIUnionList:createBtnCallBack(obj)
	UIManager.open(UIManager.UI.UIUnionCreate)
end

function UIUnionList:searchBtnCallBack(obj)
	self.searchTextFiled:didNotSelectSelf()
	local searchStr = self.searchTextFiled:getString()
	if searchStr == "" then
		self.searchBtn:getVirtualRenderer():setState(1)
		return
	else
		self.searchBtn:getVirtualRenderer():setState(0)
	end

	-- 搜索间隔过了, 重置搜索次数
	if self.requestSearchTime + self.searchIntervalTime < getGameModel():getNow() then
		self.requestSearchTime = getGameModel():getNow()
		self.curSearchCount = 0
	end
	if self.curSearchCount >= self.searchCount then
		-- 搜索频繁
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(342))
		return
	end

	self.isSearch = true
	self.curSearchCount = self.curSearchCount + 1
	self.searchBtn:setTouchEnabled(false)
	self.list:removeAllChildren()
	self.list:jumpToLeft()

	self:autoSendRequest()
end

function UIUnionList:unSearchBtnCallBack(obj)
	self.unSearchBtn:setVisible(false)
	self.isSearch = false
	self.list:removeAllChildren()
	self.list:jumpToLeft()
	self:clearSearchFiled()
	self:autoSendRequest()
end

function UIUnionList:notFullCallBack(obj, checkType)
    MusicManager.playSoundEffect(obj:getName())
	if checkType == 0 then
		self.notFull = true
	else
		self.notFull = false
	end
	self.list:removeAllChildren()
	self.isSearch = false
	self.unSearchBtn:setVisible(false)
	self.list:jumpToLeft()
	self:autoSendRequest()
end

function UIUnionList:itemCallBack(obj)
	local unionID = obj:getTag()

	self:analysisApplyInfo()

	-- 已申请的不处理
	for _, v in ipairs(self.applyInfo) do
		if unionID == v.unionID then
			return
		end
	end

	-- 判断次数是否够
	local applyCount = unionModel:getApplyCount()
	local maxApplyCount = getUnionConfItem().ApplyCount
	if applyCount >= maxApplyCount then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(956))
		return
	end

	-- 取出公会数据
	local info = nil
	for _, v in ipairs(self:getShowUnionList()) do
		if v.id == unionID then
			info = v
			break
		end
	end
	-- 判断等级是否够
	local userLv = getGameModel():getUserModel():getUserLevel()
	if info and info.limitLv > userLv then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(947))
		return
	end	

	-- 成员人数是否已满
	local unionLvConf = getUnionLevelConfItem(info.lv)
	if unionLvConf and info.memberCount >= unionLvConf.MemberLimit then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(949))
		return
	end

	-- 判断是否在冷却时间内
	local applyStamp = unionModel:getApplyStamp()
	local sec = applyStamp - getGameModel():getNow()
	if sec > 0 then
		local hour = math.floor(sec/3600)
		local min = math.floor((sec%3600)/60)
		local tipStr = string.format(CommonHelper.getUIString(306), hour, min)
		CsbTools.addTipsToRunningScene(tipStr)
		return
	end

	-- 弹出二次确认框
	local csb = obj:getChildByTag(10086)
	local unionName = CsbTools.getChildFromPath(csb, "GuildBarPanel/GuildName"):getString()
	local args = {}
	args.msg = string.format(CommonHelper.getUIString(isApply and 969 or 968), unionName)
	args.confirmFun = function ()		
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionApplyCS)	
		buffer:writeInt(unionID)
		NetHelper.request(buffer)
		-- 切换动画
		--CommonHelper.playCsbAnimation(csb, "Apply", false, nil)
		CommonHelper.playCsbAnimate(csb, csbFile.item, "Apply", false, nil, true)
	end
	args.cancelFun = function ()
		--CommonHelper.playCsbAnimation(csb, "Normal", false, nil)
		CommonHelper.playCsbAnimate(csb, csbFile.item, "Normal", false, nil, true)
	end
	UIManager.open(UIManager.UI.UIDialogBox, args)
end

function UIUnionList:listEventCallBack(obj, eventType)
	if self.isSearch or self.nextRequestListTime > getGameModel():getNow() then
		return
	end

	if eventType == 4 then		
		local items = self.list:getItems()
		if items and #items ~= 0 then
			if self.list:getInnerContainerSize().width + self.list:getInnerContainerPosition().x < 
				self.listSize.width + self.itemSize.width then

				self:autoSendRequest()
			end
		end
	end
end

function UIUnionList:onUnionApply(mainCmd, subCmd, data)
	local result = data:readChar()
	local unionID = data:readInt()

	if result == UnionHelper.UnionErrorCode.Success then
		-- 修改模型
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(941))

		local auditStamp = getGameModel():getNow() + getUnionConfItem().AuditTime*60
		table.insert(self.applyInfo, {unionID = unionID, applyTime = auditStamp})
		unionModel:setApplyInfo(self.applyInfo)
		unionModel:setApplyCount(unionModel:getApplyCount() + 1)

		self.applyNumLab:setString(unionModel:getApplyCount() .. "/" .. getUnionConfItem().ApplyCount)
		-- 切换显示
		local csb = self.list:getChildByTag(unionID)
		--CommonHelper.playCsbAnimation(csb, "Normal", false, nil)
		CommonHelper.playCsbAnimate(csb, csbFile.item, "Apply", false, nil, true)


	elseif result == UnionHelper.UnionErrorCode.AutoAudit then
		-- 取出公会数据
		local info = nil
		for _, v in ipairs(self:getShowUnionList()) do
			if v.id == unionID then
				info = v
				break
			end
		end
		unionModel:setHasUnion(true)
		unionModel:setUnionID(info.id)
		unionModel:setUnionName(info.unionName)
		-- 进入公会场景
		SceneManager.loadScene(SceneManager.Scene.SceneUnion)

	else
		-- 切换显示
		local csb = self.list:getChildByTag(unionID)
		--CommonHelper.playCsbAnimation(csb, "Normal", false, nil)
		CommonHelper.playCsbAnimate(csb, csbFile.item, "Normal", false, nil, true)
		-- 错误提示
		CsbTools.addTipsToRunningScene(UnionHelper.getErrorCodeStr(result))
	end
end

function UIUnionList:onUnionList(mainCmd, subCmd, data)
	local count = data:readChar()
	if count < 10 then
		if self.notFull then
			self.notFullUnionListOver = true
		else
			self.fullUnionListOver = true
		end
	end

	-- 读取公会数据
	local localListData = self:getShowUnionList()
	for i=1, count do
		self:readUnionInfo(localListData, data)
	end

	-- 添加到listView
	local pos = self.list:getInnerContainerPosition()
	local itemCount = #(self.list:getItems())
	for j=itemCount+1, #localListData do
		self:addItem(localListData[j])
	end

	if #localListData > 10 then
		self.list:doLayout()
		self.list:setInnerContainerPosition(pos)
	end
end

function UIUnionList:onUnionSearch(mainCmd, subCmd, data)
	self.searchBtn:setTouchEnabled(true)
	self.unSearchBtn:setVisible(true)
	self.list:removeAllChildren()
	self.list:jumpToLeft()
	self.searchUnionList = {}

	local count = data:readChar()
	for i=1, count do
		local info = self:readUnionInfo(self.searchUnionList, data)
		self:addItem(info)
	end
	if count == 0 then
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(302))
	end
end

return UIUnionList
