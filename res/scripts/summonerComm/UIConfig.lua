local UIManager = require("common.UIManager")

-- UI界面列表
UIManager.UI = {
    UIHall = 1,                 -- 大厅界面
    UISummonerList = 2,         -- 召唤师列表界面
    UIHeroCardBag = 3,          -- 英雄卡包界面
    UISummonerInfo = 4,         -- 召唤师信息界面
    UIHeroInfo = 5,             -- 英雄总览界面
    UIBag = 6,                  -- 背包界面
    UIDrawCard = 7,             -- 抽卡界面
    UIChatBag = 8,              -- 聊天道具背包界面
    UIHallBG = 9,               -- 大厅背景界面
    UIChallenge = 10,           -- 关卡挑战界面
    UITeam = 11,                -- 队伍选择界面
    UILookHeroInfo = 12,        -- 查看英雄信息界面
    UIReplayInfo = 13,          -- 查看回放战斗双方信息
    UIMap = 14,                 -- 地图界面
    UIPropQuickTo = 15,         -- 道具快速前往
    UITaskAchieve = 16,         -- 任务成就界面
    UIAward = 17,               -- 奖励界面
    UISweep = 18,               -- 扫荡
    UISettleAccountNormal = 19, -- 结算界面
    UIUnionList = 20,           -- 公会列表界面
    UIUnionCreate = 21,         -- 公会创建界面
    UIUnion = 22,               -- 公会主界面
    UICopyChoose = 23,          -- 活动副本
    UICopyDifficulty = 24,      -- 活动难度
    UICopyStrategy = 25,        -- 活动策略
    UIGoldTest = 26,            -- 金币试炼
    UIGoldTestChest = 27,       -- 金币试炼宝箱
    UIHeroTestChoose = 28,      -- 英雄试炼选择
    UIHeroTestDifficulty = 29,  -- 英雄试炼难度
    UIHeroTestInfo = 30,        -- 英雄难度详情
    UIMail = 31,                -- 邮件
    UITowerTest = 32,           -- 爬塔试炼主界面          
    UITowerTestDifficulty = 33, -- 爬塔试炼难度
    UITowerTestBuff = 34,       -- 爬塔试炼Buff
    UITowerTestChest = 35,      -- 爬塔试炼宝箱
    UITowerTestRank = 36,       -- 爬塔试炼排行榜
    UIUnionHall = 37,           -- 公会大厅
    UIUnionReEmblem = 38,       -- 更改会徽界面
    UIUnionReName = 39,         -- 更改公会名界面
    UIUnionReNotice = 40,       -- 更改公会公告界面
    UIAuditSet = 41,            -- 审核设置界面
    UIInstanceEntry = 43,       -- 副本试炼入口界面
    UIGoldTestWin = 44,         -- 金币结算胜利界面
    UIHeroTestWin = 45,         -- 英雄结算胜利界面
    UITowerTestWin = 46,        -- 爬塔结算胜利界面
    UIReplayAccount = 47,       -- 竞技场回放结算界面
    UIArena = 48,               -- 竞技场主界面
    UIArenaAccount = 49,        -- 竞技场结算界面
    UIArenaTask = 50,           -- 竞技场任务界面
    UIArenaMatch = 51,          -- 竞技场匹配界面
    UIHeroUpgradeLv = 52,       -- 英雄升级界面
    UIHeroUpgradeStar = 53,     -- 英雄升星界面
    UIHeroTalent = 54,          -- 英雄天赋界面
    UIShop = 55,                -- 商店界面
    UIShopBuyMeterial = 56,     -- 商店材料购买界面
    UIShopRefresh = 57,         -- 商店刷新提示界面
    UIEquipBag = 58,            -- 装备背包界面
    UISummonerUpgrade = 60,     -- 召唤师升级界面
    UIGold = 61,                -- 金币购买(点金)界面
    UIReconnect = 63,           -- 重连界面
    UIBagSale = 64,             -- 背包物品出售界面
    UIBagUse = 65,              -- 背包物品使用界面
    UIBagUnlock = 66,           -- 背包解锁提示界面
    UILogin = 67,               -- 登录界面
    UIServerList = 68,          -- 服务器选择界面
    UIDialogBox = 69,           -- 二次确认框
    UIShowCard = 70,            -- 抽一张卡片或关卡掉卡片界面
    UIChapterAward = 71,        -- 章节奖励界面
    UIEnergy = 72,              -- 体力购买界面
    UIShowSummoner = 73,        -- 召唤师显示界面
    UIShowAll = 74,             -- 显示所有物品
    UIRank = 75,                -- 排行榜界面
    UITowerRankDesc = 76,       -- 爬塔排行榜说明
    UIChat = 79,                -- 聊天界面
    UIChatSetting = 80,         -- 聊天设置界面
    UIUserSetting = 81,         -- 玩家设置界面
    UIOperateActive = 82,       -- 运营活动界面
    UIChallengeBuy = 83,        -- 精英关卡次数购买提示界面
    UILoginSDK = 85,            -- 渠道登陆界面
    UISignIn = 86,              -- 签到界面
    UIShopBuyHero = 87,         -- 商店召唤师、卡牌购买界面
    UIShopBuyEquip = 88,        -- 商店装备购买界面
    UIShowEquip = 89,           -- 装备信息显示界面
    UIHeadSetting = 90,         -- 头像更换界面
    UINameSetting = 91,         -- 名称修改界面
    UIPackageRedeem = 92,       -- 礼包兑换界面
    UIDrawCardTen = 93,         -- 十次抽卡界面
    UINameIntitle = 94,         -- 首次改名界面
    UINoticeActivity = 95,      -- 活动公告界面
    UIHeroQuickTo = 96,         -- 英雄快速前往
    UISummonerBuyTips = 97,     -- 召唤师购买提示界面
    UIFirstRecharge = 98,       -- 新手福利界面
    UISettleAccountLose = 99,   -- 失败结算

    --公会相关
    UIUnionMercenaryInfo = 100, -- 佣兵详细信息界面
    UIUnionHeroCard = 101,      -- 佣兵派遣界面调用的卡包界面.跟原来的不同
    UIUnionMercenary = 102,     -- 佣兵主界面
    UIUnionMercenaryYes = 103,  -- 召回确认界面
    UIUnionMercenaryRule = 104, --佣兵问号
    UIExpeditionWorld = 105,    -- 公会远征世界地图
    UIExpeditionAreaSet = 106,  -- 公会远征区域设置界面
    UIExpeditionArea = 107,     -- 公会远征区域地图
    UIExpeditionChallenge = 108,-- 公会远征挑战界面
    UIExpeditionWin = 109,      -- 公会远征结算界面
    UIExpeditionRanking = 110,  -- 公会远征伤害排行榜
    UIExpeditionDiary = 111,    -- 公会远征先驱者日记
    UIExpeditionDiaryIslandIntro = 112, -- 公会远征先驱者日记区域介绍
    UIUnionMercenaryTip = 113,  -- 公会VIP召回提示
    UIExpeditionEnemyIntro = 114,
    UIExpeditionHelpTips = 115, -- 公会远征助战提示界面
    UITowerTestRule = 116,      -- 爬塔试炼规则说明界面

    UIReplayChannel = 130,      -- 对战回放频道
    UIShareDialog = 131,        -- 分享弹框

    -- 装备打造
    UIEquipMake = 200,           -- 先占着200,怕前面的人没数字用了
    UIEquipMakeQuestion = 201,   -- 问号
    UIEquipMakeView = 202,       -- 预览
    UIEquipMakeTip = 203,        -- 分解确认
    --七日活动
    UISevenCrazy = 204,
    UISevenCrazyView = 205,
    -- 背包装备稀有出售
    UIBagTip = 206,
    UIBlueGem = 207,            -- 蓝钻特权活动
    UICommonHall = 208,         -- 所有用户活动(QQ大厅)

    UIPushSetPanel = 300,        -- 推送设置界面
    UIArenaRule = 301,
    UIArenaLevelUnlock = 302,   -- 竞技场T级界面
    UIArenaLevel = 303,         -- 竞技场段位升级降级界面

    UILoginAccountInput = 400,  -- 登录时的账号输入界面
    UILoginTips = 401,          -- 登录结果的提示界面
    UIInputPassword = 402,      -- 设置密码界面
    -------------------------------------------------------
    UIBattleLayer = 1000,       -- 战斗UI
}

-- UI配置
UIManager.UIConf = {
    -- 登录界面
    UILogin = { path = "game/login/", --[[openAni = "Open",]] closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 登录时的账号输入界面
    UILoginAccountInput = { path = "game/login/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 登录结果的提示界面
    UILoginTips = { path = "game/login/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 服务器选择界面
    UIServerList = { path = "game/login/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 大厅界面
    UIHall = { path = "game/hall/", --[[openAni = "Open",]] closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 召唤师列表界面
    UISummonerList = { path = "game/summoner/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 召唤师信息界面
    UISummonerInfo = { path = "game/summoner/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 召唤师购买提示界面
    UISummonerBuyTips = { path = "game/summoner/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 召唤师升级界面   
    UISummonerUpgrade = {path = "game/summoner/", --[[openAni = "Open",]] closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 召唤师显示界面
    UIShowSummoner = {path = "game/summoner/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 英雄卡包界面
    UIHeroCardBag = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 英雄信息界面
    UIHeroInfo = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 背包界面
    UIBag = { path = "game/bag/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 背包物品出售界面
    UIBagSale = { path = "game/bag/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 背包物品使用界面
    UIBagUse = { path = "game/bag/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 背包装备稀有出售
    UIBagTip = { path = "game/bag/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 背包解锁提示界面
    UIBagUnlock = { path = "game/bag/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 抽卡界面
    UIDrawCard = { path = "game/drawCard/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 装备选择界面
    UIEquipBox = { path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 地图界面
    UIMap = { path = "game/world/", openAni = nil, closeAni = nil, cache = true, preventTouch = true, resolutionNode = "MainPanel", showType = "addition"},
    -- 章节奖励界面
    UIChapterAward = { path = "game/world/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 关卡挑战界面
    UIChallenge = { path = "game/world/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 队伍选择界面
    UITeam = { path = "game/world/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 精英关卡次数购买提示界面
    UIChallengeBuy = {path = "game/world/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 扫荡界面
    UISweep = {path = "game/world/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 快速前往
    UIPropQuickTo = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 任务成就
    UITaskAchieve = {path = "game/taskAndAchieve/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 奖励界面
    UIAward = {path = "game/comm/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 结算界面
    UISettleAccountNormal = {path = "game/battle/", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 结算失败界面
    UISettleAccountLose = {path = "game/battle/", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 公会列表
    UIUnionList =  {path = "game/union/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 公会创建界面
    UIUnionCreate =  {path = "game/union/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会主界面
    UIUnion = {path = "game/union/", openAni = nil, closeAni = nil, cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 活动副本
    UICopyChoose = {path = "game/trial", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 活动难度
    UICopyDifficulty = {path = "game/trial/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 活动策略
    UICopyStrategy = {path = "game/trial/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 金币试炼
    UIGoldTest = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 金币试炼宝箱
    UIGoldTestChest = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 英雄试炼选择
    UIHeroTestChoose = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 英雄试炼难度
    UIHeroTestDifficulty = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 英雄难度详情
    UIHeroTestInfo = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 邮件
    UIMail = {path = "game/mail/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 爬塔试炼难度
    UITowerTestDifficulty = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 爬塔试炼Buff
    UITowerTestBuff = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 爬塔试炼宝箱
    UITowerTestChest = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 爬塔试炼排行榜
    UITowerTestRank = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 爬塔试炼主界面
    UITowerTest = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 爬塔试炼规则说明界面
    UITowerTestRule = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "fullScreen", quickClose = true},
    -- 对战频道界面
    UIReplayChannel = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 分享弹框
    UIShareDialog = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "fullScreen", quickClose = true},
    -- 公会大厅
    UIUnionHall = {path = "game/union/hall/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 更改会徽界面
    UIUnionReEmblem = {path = "game/union/hall/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会改名界面
    UIUnionReName = {path = "game/union/hall/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会改公告界面
    UIUnionReNotice = {path = "game/union/hall/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 审核设置界面
    UIAuditSet = {path = "game/union/hall/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 副本试炼入口
    UIInstanceEntry = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 金币试炼结算界面
    UIGoldTestWin = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 英雄试炼结算界面
    UIHeroTestWin = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 爬塔试炼结算界面
    UITowerTestWin = {path = "game/trail/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 竞技场主界面
    UIArena = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen"},
    -- 竞技场结算界面
    UIArenaAccount = {path = "game/pvp/", --[[openAni = "Open", closeAni = "Close",]] cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 竞技场任务界面
    UIArenaTask = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 竞技场匹配界面
    UIArenaMatch = {path = "game/pvp/", --[[openAni = "Open", closeAni = "Close",]] cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 竞技场重连界面
    UIReconnect = {path = "game/pvp/", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 竞技场规则界面
    UIArenaRule = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 竞技场T级界面
    UIArenaLevelUnlock = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 竞技场段位升级降级界面
    UIArenaLevel = {path = "game/pvp/", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 英雄升级界面
    UIHeroUpgradeLv = {path = "game/hero/", openAni = "Open", --[[closeAni = "Close",]] cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 英雄升星界面
    UIHeroUpgradeStar = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},  
    -- 英雄天赋界面   
    UIHeroTalent = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},          
    -- 商店界面
    UIShop = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 商店材料购买界面
    UIShopBuyMeterial = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 商店召唤师、卡牌购买界面
    UIShopBuyHero = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 商店装备购买界面
    UIShopBuyEquip = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 装备信息显示界面
    UIShowEquip  = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 商店刷新提示界面
    UIShopRefresh = {path = "game/shop/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 装备背包界面
    UIEquipBag = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},  
    -- 金币购买界面   
    UIGold = {path = "game/hall/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 二次确认框
    UIDialogBox = {path = "game/comm/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 卡片显示界面
    UIShowCard = {path = "game/drawCard/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 体力购买界面   
    UIEnergy = {path = "game/hall/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 显示所有物品
    UIShowAll = {path = "game/comm/", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 排行榜界面
    UIRank = {path = "game/rank/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 爬塔排行榜说明
    UITowerRankDesc = {path = "game/rank/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "fullScreen", quickClose = true},
    -- 聊天界面
    UIChat = {path = "game/chat/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 聊天设置界面
    UIChatSetting = {path = "game/chat/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 玩家设置界面
    UIUserSetting = {path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 头像更换界面
    UIHeadSetting = {path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 名称修改界面
    UINameSetting = {path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 礼包兑换界面
    UIPackageRedeem  = {path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 首次改名界面
    UINameIntitle  = {path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 运营活动界面
    UIOperateActive = {path = "game/operateActive/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 新手福利界面
    UIFirstRecharge = {path = "game/operateActive/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 登陆测试界面
    UILoginSDK  = {path = "game/login/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 签到界面
    UISignIn  = {path = "game/signIn/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 十次抽卡界面
    UIDrawCardTen = {path = "game/drawCard/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 活动公告界面
    UINoticeActivity = {path = "game/notice/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 英雄快速前往界面
    UIHeroQuickTo = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 佣兵详细信息界面
    UIUnionMercenaryInfo = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 佣兵总界面
    UIUnionMercenary = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    --佣兵派遣调用的卡包界面
    UIUnionHeroCard = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    --佣兵召回确认界面
    UIUnionMercenaryYes = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 佣兵问号
    UIUnionMercenaryRule = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 佣兵VIP召回提示
    UIUnionMercenaryTip = {path = "game/union/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 公会远征世界地图
    UIExpeditionWorld = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 公会远征区域设置界面
    UIExpeditionAreaSet = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会远征区域地图
    UIExpeditionArea = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 公会远征挑战界面
    UIExpeditionChallenge = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 公会远征结算界面
    UIExpeditionWin = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 公会远征伤害排行榜
    UIExpeditionRanking = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会远征先驱者日记
    UIExpeditionDiary = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 公会远征先驱者日记区域介绍
    UIExpeditionDiaryIslandIntro = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 公会远征先驱者日志的人物详细介绍
    UIExpeditionEnemyIntro = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 公会远征助战提示界面
    UIExpeditionHelpTips = {path = "game/union/expedition/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    --装备打造主界面
    UIEquipMake = {path = "game/equipMake/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    --装备打造问号
    UIEquipMakeQuestion = {path = "game/equipMake/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    --装备打造预览
    UIEquipMakeView = {path = "game/equipMake/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    --装备打造分解确认
    UIEquipMakeTip = {path = "game/equipMake/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    --七日活动
    UISevenCrazy = {path = "game/sevenCrazy/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 七日活动预览
    UISevenCrazyView = {path = "game/sevenCrazy/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 蓝钻特权活动
    UIBlueGem = {path = "game/blueGem/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 所有用户(QQ大厅)
    UICommonHall = {path = "game/blueGem/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition", quickClose = true},
    -- 大厅背景界面
    UIHallBG = { path = "game/hall/", --[[openAni = "Open",]] closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 推送设置界面
    UIPushSetPanel = { path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 设置密码界面
    UIInputPassword = { path = "game/userSetting/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 聊天道具背包界面
    UIChatBag = {path = "game/chat/", openAni = "Open", closeAni = "Close", cache = false, preventTouch = true, resolutionNode = "root", showType = "addition"},
    -- 查看英雄信息界面
    UILookHeroInfo = {path = "game/hero/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
    -- 查看回放战斗双方信息
    UIReplayInfo = {path = "game/chat/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single", quickClose = true},
    -- 竞技场回放结算界面
    UIReplayAccount = {path = "game/pvp/", openAni = "Open", closeAni = "Close", cache = true, preventTouch = true, resolutionNode = "root", showType = "single"},
}