--[[
	公会成员协助管理，主要实现以下内容
	1. 显示成员列表信息:
		名字, 等级, 职务, 累计贡献, 入会时长, 上次登录
	2. 权限的操作:
		任命, 移交, 撤任, 踢出, 取消职务
	3. 退出公会功能
--]]

local UnionMemberViewHelper = class("UnionMemberViewHelper")

require("game.union.UnionHelper")

local csbFile = ResConfig.UIUnionHall.Csb2

local unionModel = getGameModel():getUnionModel()

local sortType	= {posMax = 1, lvMax = 2, contribMax = 3, todayContribMax = 4, loginStamp = 5 }
-- 权限语言包
local funcTypeLan = {
	[UnionHelper.FuncType.Kick] = 931,
	[UnionHelper.FuncType.Appoint] = 926,
	[UnionHelper.FuncType.Transfer] = 927,
	[UnionHelper.FuncType.Relieve] = 932,
	[UnionHelper.FuncType.Resign] = 2015,	
}

function UnionMemberViewHelper:ctor(uiUnionHall, csb)
	self.uiUnionHall = uiUnionHall
	self.root = csb
	
	-- 缓存公会成员列表
	self.items = {}
	self.itemsCache = {}

	-- 排序类型
	self.preSortType = nil
	self.sortType = sortType.posMax

	-- 成员名文字
	local memberLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/Name")
	memberLab:setString(CommonHelper.getUIString(1975))

	-- 等级文字
	local lvNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/Level")
	lvNameLab:setTag(sortType.lvMax)
	lvNameLab:setTouchEnabled(true)
	lvNameLab:addClickEventListener(handler(self, self.sortTypeCallBack))
	-- 职务文字
	local posNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/Job")
	posNameLab:setTag(sortType.posMax)
	posNameLab:setTouchEnabled(true)
	posNameLab:addClickEventListener(handler(self, self.sortTypeCallBack))
	-- 累计贡献文字
	local contribNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/Total")
	contribNameLab:setTag(sortType.contribMax)
	contribNameLab:setTouchEnabled(true)
	contribNameLab:addClickEventListener(handler(self, self.sortTypeCallBack))
	-- 今日贡献文字
	local todayContribNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/Today")
	todayContribNameLab:setTag(sortType.todayContribMax)
	todayContribNameLab:setTouchEnabled(true)
	todayContribNameLab:addClickEventListener(handler(self, self.sortTypeCallBack))
	-- 登陆时间文字
	local loginStampNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/LastLogin")
	loginStampNameLab:setTag(sortType.loginStamp)
	loginStampNameLab:setTouchEnabled(true)
	loginStampNameLab:addClickEventListener(handler(self, self.sortTypeCallBack))

	-- 退会按钮
	self.exitBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/ExitButton")
	CsbTools.initButton(self.exitBtn, handler(self, self.exitBtnCallBack), nil, nil, "Text")
	-- 问号按钮
	self.questionBtn = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/QuestionButton")
	CsbTools.initButton(self.questionBtn, handler(self, self.questionBtnCallBack), nil, nil, nil)

	-- 滚动列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/MembersPanel/ScrollView")
	self.scroll:removeAllChildren()
    self.scroll:setScrollBarEnabled(false)
	-- 单个成员列表的大小
	local itemCsb 	= getResManager():getCsbNode(csbFile.allItem)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel"):getContentSize()
    itemCsb:cleanup()

	-- 权限操作ui
	self.funcCsb = CsbTools.getChildFromPath(self.root, "MainPanel/ChairmanButton")
	self.funcCsb:setVisible(false)

	self.funcBgPanel = CsbTools.getChildFromPath(self.funcCsb, "MaskPanel")
	self.funcBgPanel:addClickEventListener(function()
		self.funcCsb:setVisible(false)
	end)

	self.funcPanel = CsbTools.getChildFromPath(self.funcCsb, "ButtonPanel")
	self.funcList = CsbTools.getChildFromPath(self.funcCsb, "ButtonListView")
	for i=1, 3 do
		self["funcBtn_" .. i] = CsbTools.getChildFromPath(self.funcList, "Button_" .. i)
		self["funcLab_" .. i] = CsbTools.getChildFromPath(self["funcBtn_" .. i], "Text")
		self["funcBtn_" .. i]:addClickEventListener(handler(self, self.funcCallback))
	end
	self.itemHeight = 70
end

function UnionMemberViewHelper:onOpen()
	-- 是否将界面刷新出来过
	self.hasRfresh = false

	-- 服务器回调监听
	local cmdExitUnion = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionExitSC)
	self.exitUnionHandler = handler(self, self.onExitUnion)
	NetHelper.setResponeHandler(cmdExitUnion, self.exitUnionHandler)

	local cmdUnionMember = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMembersSC)
	self.unionMemberHandler = handler(self, self.onUnionMember)
	NetHelper.setResponeHandler(cmdUnionMember, self.unionMemberHandler)

	local cmdUnionFunc = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionFunctionSC)
	self.unionFuncHandler = handler(self, self.onUnionFunc)
	NetHelper.setResponeHandler(cmdUnionFunc, self.unionFuncHandler)

	-- 监听通知
	self.funcEventHandler = handler(self, self.funcEventCallBack)
	EventManager:addEventListener(GameEvents.EventUnionFunc, self.funcEventHandler)

	self.membersInfo = unionModel:getMembersInfo()
	self.sortType = sortType.posMax

	self:sortMembersInfo()
	self:refreshUI()
end

function UnionMemberViewHelper:onClose()
	-- 取消监听
	local cmdExitUnion = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionExitSC)
	NetHelper.removeResponeHandler(cmdExitUnion, self.exitUnionHandler)

	local cmdUnionMember = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMembersSC)
	NetHelper.removeResponeHandler(cmdUnionMember, self.unionMemberHandler)

	local cmdUnionFunc = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionFunctionSC)
	NetHelper.removeResponeHandler(cmdUnionFunc, self.unionFuncHandler)

	EventManager:removeEventListener(GameEvents.EventUnionFunc, self.funcEventHandler)
end

function UnionMemberViewHelper:onTop(uiID)
end

function UnionMemberViewHelper:setVisible(visiable)
	self.root:setVisible(visiable)

	if visiable == true then
		if UnionHelper.reGetStamp.unionMemberInfo <= getGameModel():getNow() then
			-- 发包未收到数据时, 默认6秒可以再次发包获取数据
			UnionHelper.reGetStamp.unionMemberInfo = getGameModel():getNow() + 6
			-- 请求成员数据
			local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMembersCS)
			buffer:writeInt(unionModel:getUnionID())
			NetHelper.request(buffer)
		else
			if not self.hasRfresh or self.preSortType ~= self.sortType then
				self:refreshUI()
			end
		end
	end
end

function UnionMemberViewHelper:resetDataValidity()
	UnionHelper.reGetStamp.unionMemberInfo = 0
end

function UnionMemberViewHelper:resetHasRefresh()
	self.hasRfresh = false
end

function UnionMemberViewHelper:cacheItems()
	for _,v in ipairs(self.items) do
		v:setTag(-100 - v:getTag())
		v:setVisible(false)
		table.insert(self.itemsCache, v)
	end
	self.items = {}
end

function UnionMemberViewHelper:refreshUI(isForce)
	if not self.root:isVisible() then
		return
	end
	self.funcCsb:setVisible(false)

	if self.membersInfo then
		self.hasRfresh = true
		self.preSortType = self.sortType
		self:cacheItems()

		local innerSize = self.scroll:getContentSize()
		local height = (self.itemSize.height + 2) * (#self.membersInfo)
		if height > innerSize.height then
			innerSize.height = height
			self.scroll:setInnerContainerSize(innerSize)
		end

		for i,v in ipairs(self.membersInfo) do
			self:addItem(v, cc.p(self.itemSize.width / 2, innerSize.height - (i - 0.5) * (self.itemSize.height + 2)))
		end
	end
end

function UnionMemberViewHelper:addItem(info, pos)
	local item = nil
	if #self.itemsCache ~= 0 then
		item = self.itemsCache[#self.itemsCache]
		table.remove(self.itemsCache, #self.itemsCache)
		item:setVisible(true)
	else
		item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.itemSize)
		CsbTools.initButton(item, handler(self, self.itemClickCallBack))
		self.scroll:addChild(item)

		local itemCsb = getResManager():cloneCsbNode(csbFile.allItem)
		itemCsb:setTag(10086)
		itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
		item:addChild(itemCsb)
	end

	table.insert(self.items, item)

	local itemCsb = item:getChildByTag(10086)

	local nameLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Name")
	local lvLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Level")
	local posLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Job")
	local totalContribLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Total")
	local todayLivenessLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Today")
	local lastLoginTimeLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Date")
    local tencentLogo = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/TencentLogo")

	item:setPosition(pos)
	item:setTag(info.userID)
	nameLab:setString(info.userName)
	lvLab:setString(info.userLv)
	posLab:setString(CommonHelper.getUIString(UnionHelper.posLan[info.pos]))
	totalContribLab:setString(info.totalContrib)
	todayLivenessLab:setString(info.todayLiveness)
    CommonHelper.showBlueDiamond(tencentLogo, CommonHelper.getIdentity(info.identity))

	local interval = getGameModel():getNow() - info.lastLoginTime
	if interval < 3600 then
		lastLoginTimeLab:setString(string.format(CommonHelper.getUIString(2017), math.floor(interval/60)))
	elseif interval < 86400 then
		lastLoginTimeLab:setString(string.format(CommonHelper.getUIString(2016), math.floor(interval/3600)))
	else
		lastLoginTimeLab:setString(string.format(CommonHelper.getUIString(2018), math.floor(interval/86400)))
	end

	-- 播放动画
	if info.userID == getGameModel():getUserModel():getUserID() then
		CommonHelper.playCsbAnimate(itemCsb, csbFile.allItem, "Self", false, nil, true)
	else
		CommonHelper.playCsbAnimate(itemCsb, csbFile.allItem, "Normal", false, nil, true)
	end
end

-- 获取操作功能面板信息
function UnionMemberViewHelper:getFunc(aimUserID)
	local func = {}

	local myPos = unionModel:getPos()
	local aimPos = UnionHelper.pos.Non
	local viceChairmanCount = 0
	for _,v in ipairs(self.membersInfo) do
		if v.userID == aimUserID then
			aimPos =  v.pos
		end
		if v.pos == UnionHelper.pos.ViceChairman then
			viceChairmanCount = viceChairmanCount + 1
		end
	end

	if myPos == UnionHelper.pos.Chairman then
		if aimPos == UnionHelper.pos.Normal then
			-- 会长点击普通成员 (显示任命,权限移交,踢出, 如果副会长任命名额已满,任命按钮置灰)
			local unionLvConf = getUnionLevelConfItem(unionModel:getUnionLv())
			local isGray = (unionLvConf.ViceChairmanNum or 0) <= viceChairmanCount and true or false
			func = {
				[1] = {operator = UnionHelper.FuncType.Appoint, isGray = isGray},
				[2] = {operator = UnionHelper.FuncType.Transfer, isGray = false},
				[3] = {operator = UnionHelper.FuncType.Kick, isGray = false}
			}

		elseif aimPos == UnionHelper.pos.ViceChairman then
			-- 会长点击副会长成员信息条,显示 撤销任命,权限移交,踢出
			func = {
				[1] = {operator = UnionHelper.FuncType.Relieve, isGray = false},
				[2] = {operator = UnionHelper.FuncType.Transfer, isGray = false},
				[3] = {operator = UnionHelper.FuncType.Kick, isGray = false}
			}
		end

	elseif myPos == UnionHelper.pos.ViceChairman then
		if aimPos == UnionHelper.pos.Normal then
			-- 点击普通成员信息条, 显示 踢出
			func = {
				[1] = {operator = UnionHelper.FuncType.Kick, isGray = false}
			}
		elseif aimPos == UnionHelper.pos.ViceChairman then
			if aimUserID == getGameModel():getUserModel():getUserID() then
				-- 点击自己 显示 取消职务
				func = {
					[1] = {operator = UnionHelper.FuncType.Resign, isGray = false}
				}
			else
				-- 点击其他副会长 踢出按钮置灰
				func = {
					[1] = {operator = UnionHelper.FuncType.Kick, isGray = true}
				}
			end

		elseif aimPos == UnionHelper.pos.Chairman then
			-- 点击会长 踢出按钮置灰
			func = {
				[1] = {operator = UnionHelper.FuncType.Kick, isGray = true}
			}
		end
	end

	return func
end

function UnionMemberViewHelper:sortMembersInfo()
	-- 职务排序: 职务 > 等级 > ID
	local function sortByPos(info1, info2)
		if info1.pos > info2.pos then
			return true
		elseif info1.pos == info2.pos then
			if info1.userLv > info2.userLv then
				return true
			elseif info1.userLv == info2.userLv then
				if info1.userID < info2.userID then
					return true
				end
			end
		end
		return false
	end

	-- 等级排序: 等级 > 职务 > ID
	local function sortByLv(info1, info2)
		if info1.userLv > info2.userLv then
			return true
		elseif info1.userLv == info2.userLv then
			if info1.pos > info2.pos then
				return true
			elseif info1.pos == info2.pos then
				if info1.userID < info2.userID then
					return true
				end
			end
		end
		return false
	end

	-- 累积贡献排序: 累积贡献 > 职务 > 等级 > ID
	local function sortByContrib(info1, info2)
		if info1.totalContrib > info2.totalContrib then
			return true
		elseif info1.totalContrib == info2.totalContrib then
			if info1.pos > info2.pos then
				return true
			elseif info1.pos == info2.pos then
				if info1.userLv < info2.userLv then
					return true
				elseif info1.userLv == info2.userLv then
					if info1.userID < info2.userID then
						return true
					end
				end
			end
		end
		return false
	end

	-- 今日贡献排序: 今日贡献 > 职务 > 等级 > ID
	local function sortByTodayContrib(info1, info2)
		if info1.todayLiveness > info2.todayLiveness then
			return true
		elseif info1.todayLiveness == info2.todayLiveness then
			if info1.pos > info2.pos then
				return true
			elseif info1.pos == info2.pos then
				if info1.userLv < info2.userLv then
					return true
				elseif info1.userLv == info2.userLv then
					if info1.userID < info2.userID then
						return true
					end
				end
			end
		end
		return false
	end

	--录时间排序: 上次登录时间（由大到小）
	local function sortLoginStamp(info1, info2)
		if info1.lastLoginTime > info2.lastLoginTime then
			return true
		elseif info1.lastLoginTime == info2.lastLoginTime then
			if info1.pos > info2.pos then
				return true
			elseif info1.pos == info2.pos then
				if info1.userLv < info2.userLv then
					return true
				elseif info1.userLv == info2.userLv then
					if info1.userID < info2.userID then
						return true
					end
				end
			end
		end
		return false
	end

	local func = {
		[sortType.posMax]	= sortByPos,
		[sortType.lvMax]	= sortByLv,
		[sortType.contribMax]	= sortByContrib,
		[sortType.todayContribMax] = sortByTodayContrib,
		[sortType.loginStamp]	= sortLoginStamp,
	}

	-- 排序
	table.sort(self.membersInfo, func[self.sortType])
end

function UnionMemberViewHelper:sortTypeCallBack(obj)
	self.sortType = obj:getTag()

	self:sortMembersInfo()
	self:refreshUI()
end

function UnionMemberViewHelper:exitBtnCallBack(obj)
	obj.soundId = nil
	-- 如果是会长, 点击提示: 您是会长, 会中还有其它成员时无法退出公会
	-- 如果是副会长, 弹出确认框: "退出公会后24小时内无法加入任何一个公会. 您确定退出公会?". 如果确定,取消副会长职务后退出公会
	-- 如果是普通成员, 弹出确认框: "退出公会后24小时内无法加入任何一个公会. 您确定退出公会?". 如果确定, 退出公会.
	if unionModel:getPos() == UnionHelper.pos.Chairman and #self.membersInfo > 1 then
		obj.soundId = MusicManager.commonSound.fail
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(2003))
		return
	end

	-- 弹出二次确认框
	local args = {}
	args.msg = CommonHelper.getUIString(2004)
	args.confirmFun = function ()		
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionExitCS)
		NetHelper.request(buffer)
	end
	args.cancelFun = function ()
	end
	UIManager.open(UIManager.UI.UIDialogBox, args)
end

function UnionMemberViewHelper:questionBtnCallBack(obj)
	UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2014))
end

function UnionMemberViewHelper:itemClickCallBack(obj)
	local aimUserID = obj:getTag()
print("aimUserID ", aimUserID)
	local func = self:getFunc(aimUserID)
	if #func == 0 then
		return 
	end

	-- 保存给发包的地方使用
	self.aimUserID = aimUserID

	local panelSize = self.funcList:getContentSize()
	panelSize.height = self.itemHeight * #func

	self.funcPanel:setContentSize(panelSize)
	self.funcList:setContentSize(panelSize)
	self.funcCsb:setVisible(true)

	local memberPos = obj:convertToWorldSpace(cc.p(0, 0))
	local csbPos = cc.p(self.funcCsb:getPositionX(), memberPos.y + self.itemSize.height/2)
	self.funcCsb:setPosition(csbPos)

	if csbPos.y - panelSize.height < 0 then
		self.funcCsb:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.MoveTo:create(0.2, cc.p(csbPos.x, panelSize.height))))
	elseif csbPos.y > display.height then
		self.funcCsb:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.MoveTo:create(0.2, cc.p(csbPos.x, display.height))))
	end

	for i=1, 3 do
		self["funcBtn_" .. i]:setTag(-99)
		self["funcBtn_" .. i]:setTouchEnabled(false)
		self["funcBtn_" .. i]:setBright(false)
	end

	for i, v in ipairs(func) do
		self["funcBtn_" .. i]:setTag(v.operator)
		self["funcLab_" .. i]:setString(CommonHelper.getUIString(funcTypeLan[v.operator]))
		self["funcBtn_" .. i]:setTouchEnabled(not v.isGray)
		self["funcBtn_" .. i]:setBright(not v.isGray)
	end
end

function UnionMemberViewHelper:funcCallback(obj)
	local funcType = obj:getTag()
	local aimUserID = self.aimUserID
	if funcType < -1 then
		return 
	end

	local aimIndex = 0
	for i,v in ipairs(self.membersInfo) do
		if v.userID == aimUserID then
			aimIndex = i
			break
		end
	end
	if aimIndex == 0 then
		print("not find this member ", aimUserID)
		return 
	end

	-- 弹出二次确认框
	local args = {}

	if funcType == UnionHelper.FuncType.Kick then
		args.msg = string.format(CommonHelper.getUIString(315), self.membersInfo[aimIndex].userName)
	elseif funcType == UnionHelper.FuncType.Appoint then
		args.msg = string.format(CommonHelper.getUIString(310), self.membersInfo[aimIndex].userName)
	elseif funcType == UnionHelper.FuncType.Transfer then
		args.msg = string.format(CommonHelper.getUIString(314), 
			CommonHelper.getUIString(UnionHelper.posLan[unionModel:getPos()]))
	elseif funcType == UnionHelper.FuncType.Relieve then
		args.msg = string.format(CommonHelper.getUIString(967), self.membersInfo[aimIndex].userName, 
			CommonHelper.getUIString(UnionHelper.posLan[self.membersInfo[aimIndex].pos]))
	elseif funcType == UnionHelper.FuncType.Resign then
		args.msg = CommonHelper.getUIString(2020)
	end

	args.confirmFun = function ()		
		local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionFunctionCS)
		buffer:writeChar(funcType)
		buffer:writeInt(aimUserID)
		NetHelper.request(buffer)
	end

	args.cancelFun = function ()
	end

	UIManager.open(UIManager.UI.UIDialogBox, args)
end

function UnionMemberViewHelper:funcEventCallBack(eventName, params)
	if params.funcType == UnionHelper.FuncType.Appoint or 
		params.funcType == UnionHelper.FuncType.Transfer or
		params.funcType == UnionHelper.FuncType.Relieve  then

		self.hasRfresh = false
		self.membersInfo = unionModel:getMembersInfo()
		self:sortMembersInfo()
		self:refreshUI()
	end
end

function UnionMemberViewHelper:onExitUnion(mainCmd, subCmd, data)
	local stamp = data:readInt()
	if stamp > 0 then
        -- 退出公会清空公会商店数据
        local shopModel = getGameModel():getShopModel()
        shopModel:clearUnionShopData()

        ChatHelper.quitRoom(ChatHelper.ChatMode.UNION, getGameModel():getUnionModel():getUnionID())
		unionModel:setHasUnion(false)
		unionModel:setApplyStamp(stamp)
		SceneManager.loadScene(SceneManager.Scene.SceneHall)

        RedPointHelper.updateUnion()
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(959))
	end
end

function UnionMemberViewHelper:onUnionMember(mainCmd, subCmd, data)
	-- 收到数据, 设置再次获取数据的时间戳为5分钟后
	UnionHelper.reGetStamp.unionMemberInfo = getGameModel():getNow() + 300

	self.membersInfo = {}

	local count = data:readInt()
	for i=1, count do
		self.membersInfo[i] = {}
		self.membersInfo[i].userID = data:readInt()
		self.membersInfo[i].totalContrib = data:readInt()
		self.membersInfo[i].pos = data:readChar()
        self.membersInfo[i].identity = data:readInt()
		self.membersInfo[i].userLv = data:readInt()
		self.membersInfo[i].todayLiveness = data:readInt()
		self.membersInfo[i].lastLoginTime = data:readInt()
		self.membersInfo[i].userName = data:readCharArray(20)
	end

	self:sortMembersInfo()
	unionModel:setMembersInfo(self.membersInfo)

	self.hasRfresh = false
	self:refreshUI()
end

function UnionMemberViewHelper:onUnionFunc(mainCmd, subCmd, data)
	self.funcCsb:setVisible(false)

	local result = data:readChar()
	if result == 1 then
		local funcType = data:readChar()
		local userID = data:readInt()

		local myIndex = 0
		local aimIndex = 0
		local myOnlineIndex = 0
		local aimOnlineIndex = 0
		local myUserID = getGameModel():getUserModel():getUserID()
		local onlineMembersInfo = unionModel:getOnlineMembersInfo()
		for i,v in ipairs(self.membersInfo) do
			if v.userID == myUserID then
				myIndex = i
            end
			if v.userID == userID then
				aimIndex = i
			end
		end
		for i,v in ipairs(onlineMembersInfo) do
			if v.userID == myUserID then
				myOnlineIndex = i
            end
			if v.userID == userID then
				aimOnlineIndex = i
			end
		end

		if myIndex == 0 or aimIndex == 0 then
			return
		end

		--修改模型
		if funcType == UnionHelper.FuncType.Kick then
			table.remove(self.membersInfo, aimIndex)

			if aimOnlineIndex ~= 0 then
				table.remove(onlineMembersInfo, aimOnlineIndex)
			end			

		elseif funcType == UnionHelper.FuncType.Appoint then
			self.membersInfo[aimIndex].pos = UnionHelper.pos.ViceChairman
			if aimOnlineIndex ~= 0 then
				onlineMembersInfo[aimOnlineIndex].pos = UnionHelper.pos.ViceChairman
			end

		elseif funcType == UnionHelper.FuncType.Transfer then
            local myPrePos = unionModel:getPos()
			self.membersInfo[aimIndex].pos = myPrePos
			self.membersInfo[myIndex].pos = UnionHelper.pos.Normal

			if aimOnlineIndex ~= 0 then
				onlineMembersInfo[aimOnlineIndex].pos = myPrePos
			end
			if myOnlineIndex ~= 0 then
				onlineMembersInfo[myOnlineIndex].pos = UnionHelper.pos.Normal
			end

		elseif funcType == UnionHelper.FuncType.Relieve then
			self.membersInfo[aimIndex].pos = UnionHelper.pos.Normal
			if aimOnlineIndex ~= 0 then
				onlineMembersInfo[aimOnlineIndex].pos = UnionHelper.pos.Normal
			end

		elseif funcType == UnionHelper.FuncType.Resign then
			self.membersInfo[myIndex].pos = UnionHelper.pos.Normal
			if myOnlineIndex ~= 0 then
				onlineMembersInfo[myOnlineIndex].pos = UnionHelper.pos.Normal
			end
		end

		unionModel:setOnlineMembersInfo(onlineMembersInfo)
		unionModel:setMembersInfo(self.membersInfo)

		-- 修改显示
		self:sortMembersInfo()
		self:refreshUI()
		self.uiUnionHall:judgeAuditBtn()
		self.uiUnionHall:resetHasRefresh("unionInfo")
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
	end
end

return UnionMemberViewHelper