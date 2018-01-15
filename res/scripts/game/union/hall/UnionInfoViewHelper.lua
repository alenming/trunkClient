--[[
	公会信息协助管理，主要实现以下内容
	1. 显示公会基本信息 : 
		id, 名字, 会长, 等级, 声望, 人数, 排行, 公告, 会徽, 在线成员, 状态
	2. 修改会徽, 名字, 公告
--]]

local UnionInfoViewHelper = class("UnionInfoViewHelper")

require("game.union.UnionHelper")

local csbFile = ResConfig.UIUnionHall.Csb2

local unionModel = getGameModel():getUnionModel()

function UnionInfoViewHelper:ctor(uiUnionHall, csb)
	self.uiUnionHall = uiUnionHall
	self.root = csb

	-- 缓存公会在线成员列表
	self.items = {}
	self.itemsCache = {}

	-- 文字: 公会ID
	self.unionIDWordLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GuildTitle")
	self.unionIDWordLab:setString(CommonHelper.getUIString(2036))
	-- 公会ID
	self.unionIDLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GuildNum")
	-- 公会名
	self.unionNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GuildName")
    -- 会长身份
    self.chairTencentLogo = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/TencentLogo")
	-- 会长名
	self.chairmanNameLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/PlayerName")
	-- 公会等级
	self.unionLvLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/LvText")
	-- 公会声望
	self.reputationLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/LoadingBarNum")
	-- 公会人数
	self.memberCountLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/NumTex")
	-- 公会排行
	self.unionRankLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/RankingNum")
	-- 公告
	self.noticeLab = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BoardIntroText")
	-- 在线人数
	self.onlineCount = CsbTools.getChildFromPath(self.root, "MainPanel/OnlinePanel/OnlineNum")
	-- 公会状态
	self.unionStateLab = CsbTools.getChildFromPath(self.root, "MainPanel/OnlinePanel/StateText")

	if unionModel:getUnionNotice() == "" then
		self.noticeLab:setString(CommonHelper.getUIString(1980))
	else
		self.noticeLab:setString(unionModel:getUnionNotice())
	end

	-- 声望进度
	self.reputationBar = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/LoadingBar")

	-- 会徽面板
	self.emblemPanel = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/GuildLogoItem/Logo")
	self.emblemPanel:addClickEventListener(handler(self, self.emblemImgCallBack))
	self.emblemPanel:setTouchEnabled(true)

	-- 会徽sprite
	self.emblemSpr = CsbTools.getChildFromPath(self.emblemPanel, "Logo")

	-- 改名按钮
	self.reNameBtn = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/NameEditButton")
	CsbTools.initButton(self.reNameBtn, handler(self, self.reNameBtnCallBack), nil, nil, nil)
	-- 问号按钮
	self.questionBtn = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BoxButton")
	CsbTools.initButton(self.questionBtn, handler(self, self.questionBtnCallBack), nil, nil, nil)
	-- 该公告按钮
	self.reNoticeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/InfoPanel/BoardEditButton")
	CsbTools.initButton(self.reNoticeBtn, handler(self, self.reNoticeBtnCallBack), nil, nil, nil)

	-- 滚动列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/OnlinePanel/ScrollView")
	self.scroll:removeAllChildren()
    self.scroll:setScrollBarEnabled(false)

	-- 单个成员列表的大小
	local itemCsb 	= getResManager():getCsbNode(csbFile.onlineItem)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel"):getContentSize()
end

function UnionInfoViewHelper:onOpen()
	-- 是否将界面刷新出来过
	self.hasRfresh = false

	-- 服务器回调监听
	local cmdUnionInfo = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionInfoSC)
	self.unionInfoHandler = handler(self, self.onUnionInfo)
	NetHelper.setResponeHandler(cmdUnionInfo, self.unionInfoHandler)

	-- 监听通知
	self.funcEventHandler = handler(self, self.funcEventCallBack)
	EventManager:addEventListener(GameEvents.EventUnionFunc, self.funcEventHandler)

	self:refreshUI()
end

function UnionInfoViewHelper:onClose()
	-- 取消监听
	local cmdUnionInfo = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionInfoSC)	
	NetHelper.removeResponeHandler(cmdUnionInfo, self.unionInfoHandler)

	EventManager:removeEventListener(GameEvents.EventUnionFunc, self.funcEventHandler)
end

function UnionInfoViewHelper:onTop(uiID)
	if uiID == UIManager.UI.UIUnionReEmblem then
		local emblemConf = getUnionBadgeConfItem()
		CsbTools.replaceSprite(self.emblemSpr, emblemConf[unionModel:getEmblem()])

	elseif uiID == UIManager.UI.UIUnionReName then

		self.unionNameLab:setString(unionModel:getUnionName())

	elseif uiID == UIManager.UI.UIUnionReNotice then
		if unionModel:getUnionNotice() == "" then
			self.noticeLab:setString(CommonHelper.getUIString(1980))
		else
			self.noticeLab:setString(unionModel:getUnionNotice())
		end
	end
end

function UnionInfoViewHelper:setVisible(visiable)
	self.root:setVisible(visiable)

	if visiable == true then
		if UnionHelper.reGetStamp.unionInfo <= getGameModel():getNow() then
			-- 发包未收到数据时, 默认6秒可以再次发包获取数据
			UnionHelper.reGetStamp.unionInfo = getGameModel():getNow() + 6
			-- 请求公会信息数据
			local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionInfoCS)
			NetHelper.request(buffer)
		else
			if not self.hasRfresh then
				self:refreshUI()
			end
		end
	end
end

function UnionInfoViewHelper:cacheItems()
	for i,v in ipairs(self.items) do
		v:setVisible(false)
		table.insert(self.itemsCache, v)
	end
	self.items = {}
end

function UnionInfoViewHelper:refreshUI()
	if not self.root:isVisible() then
		return
	end

	if unionModel:getHasUnion() then
		self.hasRfresh = true

		local unionLvConf = getUnionLevelConfItem(unionModel:getUnionLv())
		if not unionLvConf then
			print("unionLevelConf is nil ", unionModel:getUnionLv())
		end

        -- 蓝钻身份
        CommonHelper.showBlueDiamond(self.chairTencentLogo, math.floor(unionModel:getChairIdentity()%10),
            math.floor(unionModel:getChairIdentity()/10), self.chairmanNameLab)

		self.unionIDLab:setString(unionModel:getUnionID())
		self.unionNameLab:setString(unionModel:getUnionName())
		self.chairmanNameLab:setString(unionModel:getChairmanName())
		self.unionLvLab:setString(unionModel:getUnionLv())
		self.reputationLab:setString(unionModel:getReputation())
		self.memberCountLab:setString(unionModel:getMembersCount() .. "/" .. unionLvConf.MemberLimit)
		self.unionRankLab:setString(unionModel:getUnionRank())
		if unionModel:getUnionNotice() == "" then
			self.noticeLab:setString(CommonHelper.getUIString(1980))
		else
			self.noticeLab:setString(unionModel:getUnionNotice())
		end
		self.onlineCount:setString(unionModel:getOnlineMembersCount())

		if unionModel:getDangerousDay() >= 5 then
			-- 临危
			self.unionStateLab:setString(CommonHelper.getUIString(1982))
		else
			local unionLiveness = unionModel:getUnionLiveness()
			if unionLiveness < unionLvConf.ActiveMin then
				self.unionStateLab:setString(CommonHelper.getUIString(1984))
			elseif unionLiveness < unionLvConf.ActiveReward then
				self.unionStateLab:setString(CommonHelper.getUIString(1985))
			elseif unionLiveness < unionLvConf.ActiveSReward then
				self.unionStateLab:setString(CommonHelper.getUIString(1983))
			else
				self.unionStateLab:setString(CommonHelper.getUIString(1986))
			end
		end

		-- 隐藏显示改名,该公告按钮
		self.reNameBtn:setVisible(unionModel:getPos() >= UnionHelper.pos.Chairman)
		self.reNoticeBtn:setVisible(unionModel:getPos() >= UnionHelper.pos.ViceChairman)
		self.emblemPanel:setTouchEnabled(unionModel:getPos() >= UnionHelper.pos.Chairman)

		self.reputationBar:setPercent(unionModel:getReputation() * 100 / unionLvConf.UpLevelCost)
		
		local emblemConf = getUnionBadgeConfItem()
		CsbTools.replaceSprite(self.emblemSpr, emblemConf[unionModel:getEmblem()])

		self:cacheItems()
		local onlineMembersInfo = unionModel:getOnlineMembersInfo()
		-- 排序
		local function sortByPos(info1, info2)
			if info1.pos > info2.pos then
				return true
			elseif info1.pos == info2.pos then
				if info1.lv > info2.lv then
					return true
				elseif info1.lv == info2.lv then
					if info1.userID < info2.userID then
						return true
					end
				end
			end
			return false
		end
		table.sort(onlineMembersInfo, sortByPos)

		local innerSize = self.scroll:getContentSize()
		local height = (self.itemSize.height + 2) * (#onlineMembersInfo)
		if height > innerSize.height then
			innerSize.height = height
			self.scroll:setInnerContainerSize(innerSize)
		end

		for i,v in ipairs(onlineMembersInfo) do
			self:addItem(v, cc.p(self.itemSize.width/2, innerSize.height - (i - 0.5) * (self.itemSize.height + 2)))
		end
	end
end

function UnionInfoViewHelper:resetDataValidity()
	UnionHelper.reGetStamp.unionInfo = 0
end

function UnionInfoViewHelper:resetHasRefresh()
	self.hasRfresh = false
end

function UnionInfoViewHelper:addItem(info, pos)
CsbTools.printValue(info, "info")
	local itemCsb = nil
	if #self.itemsCache ~= 0 then
		itemCsb = self.itemsCache[#self.itemsCache]
		table.remove(self.itemsCache, #self.itemsCache)
		itemCsb:setVisible(true)
	else
		itemCsb 	= getResManager():cloneCsbNode(csbFile.onlineItem)
		self.scroll:addChild(itemCsb)
	end

	table.insert(self.items, itemCsb)

	local nameLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Name")
	local lvLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Level")
	local posLab = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/Job")
    local identityNode = CsbTools.getChildFromPath(itemCsb, "PlayerBarPanel/TencentLogo")

	itemCsb:setPosition(pos)
	nameLab:setString(info.userName)
	lvLab:setString(info.lv)
	posLab:setString(CommonHelper.getUIString(UnionHelper.posLan[info.pos] or 925))
    -- 身份显示
    CommonHelper.showBlueDiamond(identityNode, CommonHelper.getIdentity(info.identity))

	-- 播放动画
	if info.userID == getGameModel():getUserModel():getUserID() then
		CommonHelper.playCsbAnimate(itemCsb, csbFile.onlineItem, "Self", false, nil, true)
	else
		CommonHelper.playCsbAnimate(itemCsb, csbFile.onlineItem, "Normal", false, nil, true)
	end
end

function UnionInfoViewHelper:emblemImgCallBack(obj)
	UIManager.open(UIManager.UI.UIUnionReEmblem)
end

function UnionInfoViewHelper:reNameBtnCallBack(obj)
	UIManager.open(UIManager.UI.UIUnionReName)
end

function UnionInfoViewHelper:questionBtnCallBack(obj)
	UIManager.open(UIManager.UI.UIUnionMercenaryRule, CommonHelper.getUIString(2012))
end

function UnionInfoViewHelper:reNoticeBtnCallBack()
	UIManager.open(UIManager.UI.UIUnionReNotice)
end

function UnionInfoViewHelper:funcEventCallBack(eventName, params)
	if params.funcType == UnionHelper.FuncType.Appoint or 
		params.funcType == UnionHelper.FuncType.Transfer or
		params.funcType == UnionHelper.FuncType.Relieve  then

		self.hasRfresh = false
		self:refreshUI()
	end
end

function UnionInfoViewHelper:onUnionInfo(mainCmd, subCmd, data)
	-- 收到数据, 设置再次获取数据的时间戳为5分钟后
	UnionHelper.reGetStamp.unionInfo = getGameModel():getNow() + 300

	local unionID = data:readInt()
	local unionLv = data:readInt()
	local liveness = data:readInt()
	local unionRank = data:readInt()
	local reputation = data:readInt()
	local limitLv = data:readInt()
	local emblem = data:readInt()
	local isAutoAudit = data:readInt()
	local dangerousTag = data:readInt()
	local welfareTag = data:readInt()
    local identity = data:readInt()
	local pos = data:readChar()
	local memberCount = data:readChar()
	local onlineMemberCount = data:readChar()
	local unionName = data:readCharArray(20)
	local chairmanName = data:readCharArray(20)
	local notice = data:readCharArray(128)
	local onlineMembersInfo = {}
	for i=1, onlineMemberCount do
		onlineMembersInfo[i] = {}
		onlineMembersInfo[i].userID = data:readInt()
		onlineMembersInfo[i].lv = data:readInt()
        onlineMembersInfo[i].identity = data:readInt()
		onlineMembersInfo[i].pos = data:readChar()
		onlineMembersInfo[i].userName = data:readCharArray(20)
	end

	-- 修改模型
	unionModel:setUnionID(unionID)
	unionModel:setUnionLv(unionLv)
	unionModel:setUnionLiveness(liveness)
	unionModel:setUnionRank(unionRank)
	unionModel:setReputation(reputation)
	unionModel:setLimitLv(limitLv)
	unionModel:setEmblem(emblem)
	unionModel:setIsAutoAudit(isAutoAudit)
	unionModel:setDangerousDay(dangerousTag)
	unionModel:setWelfareTag(welfareTag)
	unionModel:setPos(pos)
	unionModel:setMembersCount(memberCount)
	unionModel:setOnlineMembersCount(onlineMemberCount)
	unionModel:setUnionName(unionName)
	unionModel:setChairmanName(chairmanName)
	unionModel:setUnionNotice(notice)
	unionModel:setOnlineMembersInfo(onlineMembersInfo)
    unionModel:setChairIdentity(identity)

	self.hasRfresh = false
	self:refreshUI()
end

return UnionInfoViewHelper