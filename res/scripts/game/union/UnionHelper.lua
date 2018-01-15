UnionHelper = {}

-- 公会错误代码
UnionHelper.UnionErrorCode = {
	Faild = 0,			-- 失败
	Success = 1,		-- 成功
	AuditOverTime = 2,	-- 审核时间已过
	OwnUnion = 3,		-- 已经拥有公会
	NoEnoughLv = 4,		-- 等级不够
	NoEnoughMoney = 5,	-- 费用不够
	MemberFull = 6,		-- 公会满员
	ApplyTimestamp = 7,	-- 申请(创建)公会冷却时间没到	
	NameLegal = 8,		-- 公会名不合法(为空)
	NameRepeat = 9,		-- 公会名重复
	UnionNoExist = 10,	-- 公会不存在
	ApplySame = 11,		-- 重复申请公会
	NoApplyCount = 12,	-- 申请次数不足
	NoAuditPower = 13,	-- 无审核权限
	AutoAudit = 14,		-- 自动审核通过
	PassAudit = 15,		-- 通过审核
	RefuseAudit = 16,	-- 拒绝审核
	ViceChairmanFull = 17, -- 副会长上限
	AreadyDo = 18,		-- 已被处理
}

-- 公会错误吗对应语言包(部分)
UnionHelper.errorCodeLan = {
	[UnionHelper.UnionErrorCode.Faild] = 966,
	[UnionHelper.UnionErrorCode.AuditOverTime] = 945,
	[UnionHelper.UnionErrorCode.OwnUnion] = 946,
	[UnionHelper.UnionErrorCode.NoEnoughLv] = 947,
	[UnionHelper.UnionErrorCode.NoEnoughMoney] = 948,
	[UnionHelper.UnionErrorCode.MemberFull] = 949,
	[UnionHelper.UnionErrorCode.ApplyTimestamp] = 950,
	[UnionHelper.UnionErrorCode.NameLegal] = 952,
	[UnionHelper.UnionErrorCode.NameRepeat] = 953,
	[UnionHelper.UnionErrorCode.UnionNoExist] = 954,
	[UnionHelper.UnionErrorCode.ApplySame] = 955,
	[UnionHelper.UnionErrorCode.NoApplyCount] = 956,
	[UnionHelper.UnionErrorCode.NoAuditPower] = 957,
	[UnionHelper.UnionErrorCode.AreadyDo] = 11,
}

-- 公会权限操作类型
UnionHelper.FuncType = {
	Join = 0,		-- 加入
	Exit = 1,		-- 退出
	Kick = 2,		-- 踢出
	Appoint = 3,	-- 任命
	Assign = 4,		-- 分配物品
	Transfer = 5,	-- 权限移交
	Relieve = 6,	-- 撤任
	Resign = 7,		-- 辞职
    Dismiss = 8,    -- 解散
}

UnionHelper.pos = {
	Non = -1,
	Normal = 0,			-- 普通成员
	ViceChairman = 1,	-- 副会长
	Chairman = 2,		-- 会长
}

UnionHelper.posLan = {
	[UnionHelper.pos.Non] = 925,
	[UnionHelper.pos.Normal] = 910,
	[UnionHelper.pos.ViceChairman] = 921,
	[UnionHelper.pos.Chairman] = 920,
}

UnionHelper.welfareType = {
	activeBox = 0,	-- 活跃宝箱
	activeSBox = 1,	-- 超级活跃宝箱
}

-- 下次请求数据的时间戳
UnionHelper.reGetStamp = {
	unionInfo = 0,
	unionMemberInfo = 0,
	unionAuditList = 0,
}

local UnionMercenaryModel = getGameModel():getUnionMercenaryModel()

function UnionHelper.getErrorCodeStr(errorCode)
	if UnionHelper.errorCodeLan[errorCode] then
		return CommonHelper.getUIString(UnionHelper.errorCodeLan[errorCode])
	end
	return  "errorCode " .. errorCode
end

function UnionHelper:sendMercenarysInfoCallBack()
    local cmd = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoSC)
    self.mCallBack = handler(self, self.getMercenarysInfoCallBack)
    NetHelper.setResponeHandler(cmd, self.mCallBack)

    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 开始发送拉取佣兵信息协议")
    local buffData = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionMercenaryInfoCS)
    NetHelper.request(buffData)
end

function UnionHelper:getMercenarysInfoCallBack(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 请求的佣兵主界面信息返回了!!!")

    if UnionMercenaryModel:init(buffData) then
    	print("数据初始化成功!!!!!")
    end

end

-- 派遣佣兵全局监听函数回调
function UnionHelper:sendMercenary(buffData)
	print("UnionHelper:sendMercenary(buffData)")
	local userId = buffData:readInt()
	local tag = buffData:readInt()
	local name = buffData:readCharArray(32)
	local dyId = buffData:readInt()
	local heroId = buffData:readInt()
	local lv = buffData:readInt()
	local star = buffData:readInt()
	
	local myUserId = getGameModel():getUserModel():getUserID()
	
	if myUserId == userId then  --自己召回,走原来的逻辑
		print("tag   is" ,tag)
		local uiView = UIManager.getUI(UIManager.UI.UIUnionMercenary)
		uiView:sendMercenary(dyId, heroId, tag, name, lv, star)
		
		EventManager:raiseEvent(GameEvents.EventDispatchMercenary, {})

	else -- 不是自己召回,判断UI是不是在这个界面 ,在要刷新界面,不在就只做数据处理
		UnionMercenaryModel:insertHeroToMercenaryBag(dyId, heroId, name, lv, star) 		--插入这个英雄到佣兵卡包中

		if UIManager.isTopUI(UIManager.UI.UIUnionMercenary) then -- 在这个界面,还在判定在哪个子界面
			local uiView = UIManager.getUI(UIManager.UI.UIUnionMercenary)
			if uiView.scroll:isVisible() then
				uiView:refreshScrollView()
			else
	     		uiView:refreshScrollView()
			end
		end

		EventManager:raiseEvent(GameEvents.EventOtherDispatchMercenary, {dyId = dyId})
	end
end

-- 召回佣兵全局监听函数回调
function UnionHelper:callMercenary(buffData)
	print("UnionHelper:callMercenary(buffData)")
	local dyId = buffData:readInt()
	local getMoney = buffData:readInt()
	local userId = buffData:readInt()
	local tag = buffData:readInt()

	local myUserId = getGameModel():getUserModel():getUserID()

	if myUserId == userId then  --自己召回,走原来的逻辑
		print("tag   is" ,tag)
		local uiView = UIManager.getUI(UIManager.UI.UIUnionMercenary)
		uiView:callMercenary( dyId, getMoney, tag)

	else -- 不是自己召回,判断UI是不是在这个界面 ,在要刷新界面,不在就只做数据处理
		UnionMercenaryModel:deleteHeroToMercenaryBag(dyId) 		--删除这个英雄从佣兵卡包中

		if UIManager.isTopUI(UIManager.UI.UIUnionMercenary) then -- 在这个界面,还在判定在哪个子界面
			
			local uiView = UIManager.getUI(UIManager.UI.UIUnionMercenary)
			if uiView.scroll:isVisible() then
				uiView:refreshScrollView()
			else
	     		uiView:refreshScrollView()
			end
		end

		EventManager:raiseEvent(GameEvents.EventOtherRecallMercenary, {dyId = dyId})
	end
end
