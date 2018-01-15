--[[
    GameEvent定义了游戏中的所有事件，并声明了事件对应会传入的参数
	事件触发时会将参数封装到table中，table中各个字段的含义如下【如无特殊申明，均为整数】：
    heroId          - 英雄唯一ID
    heroIds         - 英雄唯一ID数组
    summonerId      - 召唤师ID
    skillId         - 技能ID
    equipId         - 装备唯一ID
    preLevel        - 升级前等级
    itemId          - 道具ID
    itemCount       - 道具数量
    currencyType    - 货币类型 1Gold, 2Diamond 3PvpCoin 4TowerCoin 5Energy 6UnionContrib 7Exp
    currencyCount   - 货币数量
    goldCount       - 金币数
    drawCardType    - 抽卡类型，1单抽 2十连抽 
    taskId          - 任务ID
    taskType        - 任务类型 1任务 2成就 3公会个人任务 4公会团队任务 ...
    chapterId       - 章节ID
    stageId         - 关卡ID
    stageDifficulty - 关卡难度
    battleResult    - 战斗结果，0失败，123表示胜利的星级
    UIId            - 当前界面UI ID
    prevUIId        - 上一个界面UI ID
    rechargeCount   - 充值数
    shopType        - 商店类型
    funcType        - 操作类型
    quality         - 品质

	2016-3-18 by 宝爷
]]

GameEvents = GameEvents or {
    -- 系统级别事件
    EventNetConnectSuccess = -100,  -- 网络连接成功
    EventNetConnectFailed = -101,   -- 网络连接失败
    EventNetDisconnect = -102,      -- 网络断开
    EventNetReconnect = -103,       -- 网络重新连接
    EventNetReconnectFinish = -104, -- 网络重新连接完成

    -- C++层触发的事件
    EventBattleStart = 1,           -- 进入战斗，stageId关卡ID
    EventCustom = 2,                -- 自定义消息ID
    EventHeroButtonClick = 3,       -- 英雄按钮点击触发
    EventSkillButtonClick = 4,      -- 技能按钮点击触发
    EventCrystalButtonClick = 5,    -- 水晶按钮点击触发
    EventSkillPointClick = 6,       -- 技能选点释放
	EventBossHpDown = 7,			-- 敌方没有士兵
	EventBossDie = 8,				-- BOSS死亡，参数为关卡ID
	EventBossDoSkill = 9,		    -- 巫妖释放亡灵大军
	EventHeroDoSkill = 10,		    -- 莱奥变身
	EventBossDie = 11,		        -- 巫妖死亡
	EventBossDie1 = 12,		        -- 105BOSS死亡
	EventBossDie2 = 13,		        -- 106BOSS死亡
	EventBossDie3 = 14,		        -- 108BOSS死亡
    EventSkillCDReady = 15,         -- 参数 skillid
    EventCrystalReady = 16,         -- 水晶可升级事件

    EventChatMessage = 30,          -- 聊天事件
    EventChatConnect = 31,          -- 聊天服务器连接
    EventChatDisconnect = 32,       -- 聊天服务器断开
    EventChatClickLook = 33,        -- 点击查看聊天的物品(英雄/装备)

    EventSDKPaySuccess = 41,        -- 付费成功
    EventSDKPayFail = 42,           -- 付费失败
    EventSDKInitSucess = 43,        -- sdk初始化成功
    EventSDKInitFail = 44,          -- sdk初始化失败
    EventSDKLoginSucess = 45,       -- sdk登陆成功
    EventSDKLoginNetError = 46,     -- sdk登陆网络错误
    EventSDKLoginCancel = 47,       -- sdk登陆取消
    EventSDKLoginFail = 48,         -- sdk登录失败
    EventSDKLogoutSucess = 49,      -- 登出成功
    EventSDKLogoutFail = 50,        -- 登出失败
    EventSDKAccountSwitchCancel = 51,-- 切换帐号取消
    EventSDKAccountSwitchFail = 52, -- 切换帐号失败
    EventSDKPayResult = 53,         -- sdk支付结果

    -- Lua层触发的事件
    -- 关卡相关
    EventStageOver = 101,           -- 关卡结束, chapterId, stageId, battleResult
    EventHeroTestStageOver = 102,   -- 英雄试炼结束, stageId, stageDifficulty, battleResult
    EventGoldTestStageOver = 103,   -- 金币试炼结束, stageId, battleResult = 1
    EventTowerTestStageOver = 104,  -- 爬塔试炼结束, stageId, stageDifficulty, battleResult
    EventFBTestStageOver = 105,     -- 副本试炼结束, stageId, stageDifficulty, battleResult
    EventPVPOver = 106,             -- pvp结束 battleResult
    
    EventBattleOver = 108,          -- 战斗结束 battleResult

    -- 使用相关
    EventDrawCard = 201,            -- 抽卡, drawCardType, heroIds
    EventUseItem = 202,             -- 使用道具, itemId, itemCount

    -- 出售相关
    EventSaleItem = 301,            -- 出售道具, itemId, itemCount

    -- 购买相关
    EventTouchGloden = 404,         -- 点金
    EventShopBuy = 402 ,            -- 商店购买商品 shopType, count

    -- 得到相关
    EventReceiveCurrency = 501,     -- 获得货币, currencyType, currencyCount
    EventReceiveEquip = 502,        -- 获得装备 equipId
    EventReceiveItem = 503,         -- 获得道具 itemId, itemCount
    EventReceiveHero = 504,         -- 获得英雄 heroId
    EventReceiveSummoner = 505,     -- 获得召唤师 summonerId
    EventReceiveHead = 506,         -- 获得头像 headId
    EventEquipMake = 507,           -- 装备打造 quality

    -- 英雄相关
    EventDressEquip = 601,          -- 英雄穿装备, heroId, equipId
    EventHeroUpgradeLevel = 603,    -- 英雄升级, heroId, preLevel
    EventHeroUpgradeStar = 604,     -- 英雄升星, heroId
    EventHeroUpgradeSkill = 605,    -- 英雄技能升级, heroId, skillId
    EventPlayerUpgradeLevel = 606,  -- 玩家升级 preLevel
    EventUnDressEquip = 607,        -- 英雄卸载装备, heroId
    EventSetTalent = 608,           -- 英雄设置天赋, heroId
  
    -- 其他
    EventOpenUI = 701,              -- 界面切换管理, UIId, prevUIId
    EventFinishTask = 702,          -- 完成后领取任务奖励, taskId, taskType
    EventButtonClick = 703,         -- 按钮被点击，新手引导的高亮按钮被点击会自动触发此消息
    EventCloseUI = 704,             -- 关闭界面触发消息, UIId
    EventRecharge = 705,            -- 充值 rechargeCount
    EventBuyMonthCard = 706,        -- 购买月卡
    EventOwnUnion = 707,            -- 拥有公会
    EventOpenUIBefore = 708,        -- 界面打开(动画)之前
    EventChangeScene = 709,         -- 切换场景
    EventUserUpgradeUI = 710,       -- 玩家升级界面
    EventUIRefresh  = 711,          -- UI刷新, (协助新手引导再次隐藏或显示UI)
    EventTimeCall  = 712,           -- 到达时间戳
    EventGotoHall = 713,            -- 玩家打开了大厅界面
    EventLoginResult = 714,         -- 登录结果
    
    -- 刷新界面信息相关
    EventUpdateGold = 801,
    EventUpdateDiamond = 802,
    EventUpdateMainBtnRed = 803,
    EventUpdatePvpChest = 804,
    EventUpdateLvExp = 805,

    EventUpdateTaskRead = 807,
    EventUpdateTeam = 808,

    -- 红点
    EventAddRedPoint = 851,        -- 增加减少红点 systemId, count, id(废弃,为不影响其他版本,暂时留着)
    EventSeeActivity = 852,        -- 查看活动 activityId
    EventOperateActiveUpdate = 853,-- 活动数据更新 activityId

    EventSevenCrazyUpdate = 854,   -- 七日活动数据更新

    -- 公会相关
    EventUnionFunc = 901,           -- 公会权限操作 funcType
    EventDispatchMercenary = 902,   -- 派遣佣兵
    EventUseMercenary = 903,        -- 使用佣兵 count
    EventOtherDispatchMercenary = 904,-- 别人派遣佣兵
    EventOtherRecallMercenary = 905,-- 别人召回佣兵

    -- 公会远征相关
    EventExpeditionMapSet = 1001,   -- 公会远征目标设定
    EventExpeditionStagePass = 1002,-- 公会远征关卡通过
    EventExpeditionStart = 1003,    -- 公会远征开始
    EventExpeditionWin = 1004,      -- 公会远征胜利
    EventExpeditionFail = 1005,     -- 公会远征失败
    EventExpeditionAwardFlag = 1006,-- 公会远征奖励标识
    
    -- 公会商店
    EventUnionShopBuy = 1101,       -- 公会商店购买
    EventUnionShopFresh = 1102,     -- 公会商店刷新
}

return GameEvents