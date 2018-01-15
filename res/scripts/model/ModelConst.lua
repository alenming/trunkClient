-- 装备部件类型
EquipPartType = {
    WEAPON 			= 1,					-- 武器
    HEADWEAR 		= 2,					-- 头饰
    CLOTH			= 3,					-- 衣服
    SHOES			= 4,					-- 鞋子
    ACCESSORY		= 5,					-- 饰品
    TREASURE		= 6,					-- 宝具
}

-- 章节状态
EChapterState = {
	ECS_LOCK = 0,							-- 未解锁
	ECS_UNLOCK = 1,							-- 已解锁
	ECS_FINISH = 2,							-- 已完成
	ECS_REWARD = 3,							-- 已领取
}

-- 关卡状态
ELevelState = {
	ESS_HIDE = 0,							-- 未显示
	ESS_LOCK = 1,							-- 未解锁
	ESS_UNLOCK = 2,							-- 已解锁
	ESS_ONE = 3,							-- 一星
	ESS_TWO = 4,							-- 二星
	ESS_TRI = 5,							-- 三星
}

-- 天赋状态
ETalentStatus = {
    ETS_LOCK = 0,            				-- 未解锁
    ETS_UNLOCK = 1,          				-- 解锁
    ETS_UNACTIVE = 2,        				-- 未激活
    ETS_ACTIVE = 3,          				-- 激活
}

-- 队伍类型
ETeamType = {
    ETT_PASE = 0,        					-- 通关队伍
    ETT_SPORTE = 1,       					-- 竞技队伍
}

-- 任务状态(状态类任务,由前端计算)
ETaskStatus = {
	 ETASK_UNATIVE = -1,          			-- 未激活(等级未到)
	 ETASK_ACTIVE = 0,                		-- 激活状态
	 ETASK_FINISH = 1,                		-- 完成(可领取)
	 ETASK_GET = 2,                   		-- 已经领取
}

-- 成就状态
EAchieveStatus = {
	 EACHIEVE_STATUS_UNACTIVE = -1,			-- 未激活
	 EACHIEVE_STATUS_ACTIVE = 0,	       	-- 激活
	 EACHIEVE_STATUS_FINISH = 1,       		-- 完成
	 EACHIEVE_STATUS_GET = 2, 		        -- 领取
}

-- 邮件类型
EMailType = {
	MAIL_TYPE_NORMAL = 0,           		-- 普通邮件(活动、背包不足)
    MAIL_TYPE_WEB = 1,              		-- GM邮件(手动填写标题、内容等)
}

-- 公会邮件TIPS
EMailTipsType = {
    MAIL_TIPS_NON = 0,                      
    MAIL_TIPS_NOPASS = 1,                  	-- 公会申请不通过
    MAIL_TIPS_KICK = 2,                    	-- 公会踢出
    MAIL_TIPS_APPOINT = 3,                 	-- 任命
    MAIL_TIPS_RELIEVE = 4,                 	-- 撤职
    MAIL_TIPS_PASS = 5,                    	-- 公会申请通过
}

-- pvp匹配类型
MatchType = {
    MATCH_FAIRPVP = 0,						-- 公平竞技
    MATCH_CPN = 1,							-- 锦标赛
}

-- pvp房间类型
EPvpRoomType = {
    PVPROOMTYPE_NONE = 0,
    PVPROOMTYPE_PVP = 1,				 	-- pvp房间		
    PVPROOMTYPE_ROBOT = 2,					-- 机器人房间
    PVPROOMTYPE_CHAMPIONSHIP = 3,			-- 锦标赛房间
}

-- 运营活动类型
ActiveType = {
    TYPE_NONE = 0,
    TYPE_SHOP = 1,
    TYPE_DROP = 2,
    TYPE_TASK = 3,
    TYPE_CARD = 4,  -- 月卡
    TYPE_EXCHANGE = 5, --兑换活动
}

-- 月卡状态
MonthCardState = {
    STATE_NONE      = 0,    -- 提示他去购买
    STATE_FINISH    = 1,    -- 已经结束
    STATE_RECEIVED  = 2,    -- 已经领取
    STATE_REWARD    = 3,    -- 可以领取
}

-- 七日活动类型
SevenCrazyType = {
    TYPE_NONE = 0,
    TYPE_EVERY_DAY = 1,
    TYPE_GROUP_UP = 2,
    TYPE_SALE_BAG = 3,
}

-- 商店类型
ShopType = {
    None        = 0,
    GoldShop        = 1,    -- 金币商店
    MysteryShop     = 2,    -- 神秘商店
    --TowerShop     = 3,    -- 爬塔试炼商店
    UnionShop       = 3,    -- 公会商店
    DiamondShop     = 4,    -- 钻石商店(充值)
}