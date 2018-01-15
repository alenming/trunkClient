-- 主命令
MainProtocol = {}
MainProtocol.Login = 1
MainProtocol.User = 2
MainProtocol.Summoner = 3
MainProtocol.Hero = 4
MainProtocol.Bag = 5
MainProtocol.Stage = 6
MainProtocol.Pvp = 7
MainProtocol.Battle = 8
MainProtocol.Team = 9
MainProtocol.Task = 10
MainProtocol.Achievement = 11
MainProtocol.Guide = 12
MainProtocol.Union = 13
MainProtocol.Mail = 14
MainProtocol.Instance = 15
MainProtocol.GoldTest = 16
MainProtocol.HeroTest = 17
MainProtocol.TowerTest = 18
MainProtocol.UnionTask = 19
MainProtocol.PvpMatch = 20
MainProtocol.PvpChest = 21
MainProtocol.Shop = 22
MainProtocol.Rank = 23
MainProtocol.OperateActive = 24
MainProtocol.ErrorCode = 25
MainProtocol.Pay = 26
MainProtocol.Expedition = 27
MainProtocol.Notice = 28
MainProtocol.Chat = 29
MainProtocol.Look = 30

-- 12点刷新协议
CommonProtocol = {}
CommonProtocol.RefreshCS = 11  -- 主协议用MainProtocol.Login

-- 登录协议
LoginProtocol = {}
LoginProtocol.LoginCheck = 1

LoginProtocol.LoginCheckTestCS = 1
LoginProtocol.LoginCheckPfCS = 2
LoginProtocol.LoginCheckGuestCS = 3
LoginProtocol.LoginCheckBindGuestCS = 4
LoginProtocol.LoginExistUserCS = 5
LoginProtocol.LoginCS = 6
LoginProtocol.LoginUnionCS = 7
LoginProtocol.LoginReconnectCS = 8
LoginProtocol.LoginUserInfoCS = 9
LoginProtocol.LoginGuideInfoCS = 10
LoginProtocol.LoginFresh = 11
LoginProtocol.LoginChatCS = 12

LoginProtocol.LoginCheckSC = 101
LoginProtocol.LoginNewGuestSC = 102
LoginProtocol.LoginFinishSC = 103
LoginProtocol.LoginSC = 104
LoginProtocol.UserModelSC = 105
LoginProtocol.BagModelSC = 106
LoginProtocol.EquipModelSC = 107
LoginProtocol.SummonerModelSC = 108
LoginProtocol.HeroModelSC = 109
LoginProtocol.StageModelSC = 110
LoginProtocol.TeamModelSC = 111
LoginProtocol.TaskModelSC = 112
LoginProtocol.AchieveModelSC = 113
LoginProtocol.GuideModelSC = 114
LoginProtocol.UnionModelSC = 115
LoginProtocol.MailModelSC = 116
LoginProtocol.InstanceModelSC = 117
LoginProtocol.GoldTestModelSC = 118
LoginProtocol.HeroTestModelSC = 119
LoginProtocol.TowerTestModelSC = 120
LoginProtocol.PvpModelSC = 121
LoginProtocol.ShopModelSC = 122
LoginProtocol.OperateActiveModelSC = 123
LoginProtocol.BanSC = 124
LoginProtocol.RechangeSC = 125
LoginProtocol.TickSC = 126
LoginProtocol.HeadSC = 127
LoginProtocol.UnionShopSC = 128
LoginProtocol.SevenCrazySC = 129
LoginProtocol.PvpChestModelSC = 130
LoginProtocol.LoginChatSC = 131
LoginProtocol.LoginBlueGemSC = 132

-- 用户协议
UserProtocol = {}
UserProtocol.BuyCS = 1
UserProtocol.RenameCS = 2
UserProtocol.ChangeHeadIconCS = 3
UserProtocol.SignCS = 4
UserProtocol.GiftCS = 5
UserProtocol.FirstChargeCS = 6
UserProtocol.GrowthFundCS = 7
UserProtocol.UserModifyPSCS = 8
UserProtocol.BuySC = 101
UserProtocol.RenameSC = 102
UserProtocol.ChangeHeadIconSC = 103
UserProtocol.SignSC = 104
UserProtocol.GiftSC = 105
UserProtocol.FirstChargeSC = 106
UserProtocol.GrowthFundSC = 107
UserProtocol.UserModifyPSSC = 108

-- 召唤师协议
SummonerProtocol = {}
SummonerProtocol.BuyCS = 1
SummonerProtocol.BuySC = 101

-- 英雄协议
HeroProtocol = {}
HeroProtocol.BuyCardCS = 1
HeroProtocol.GenCS = 2
HeroProtocol.UpgradeCS = 3
HeroProtocol.UpStarCS = 4
HeroProtocol.EquipCS = 5
HeroProtocol.ActivaeTalentCS = 6
HeroProtocol.BuyCardSC = 101
HeroProtocol.GenSC = 102
HeroProtocol.UpgradeSC = 103
HeroProtocol.UpStarSC = 104
HeroProtocol.EquipSC = 105
HeroProtocol.ActivaeTalentSC = 106

-- 背包协议
BagProtocol = {}
BagProtocol.SaleCS = 1
BagProtocol.UnlockCS = 2
BagProtocol.UseCS = 3
BagProtocol.makeEquipCS =  4          -- 装备打造
BagProtocol.breakEquipCS = 5          -- 装备分解

BagProtocol.SaleSC = 101
BagProtocol.UnlockSC = 102
BagProtocol.UseSC = 103
BagProtocol.AddSC = 104
BagProtocol.makeEquipSC = 105           -- 装备打造
BagProtocol.breakEquipSC = 106          -- 装备分解

-- 关卡协议
StageProtocol = {}
StageProtocol.ChangeCS = 1
StageProtocol.FinishCS = 2
StageProtocol.SweepCS = 3
StageProtocol.StrategyCS = 4
StageProtocol.ChapterAwardCS = 5
StageProtocol.BuyTimesCS = 6
StageProtocol.BuyChapterCS = 7
StageProtocol.ChangeSC = 101
StageProtocol.FinishSC = 102
StageProtocol.SweepSC = 103
StageProtocol.StrategySC = 104
StageProtocol.ChapterAwardSC = 105
StageProtocol.BuyTimesSC = 106
StageProtocol.BuyChapterSC = 107

-- 副本协议
InstanceProtocol = {}
InstanceProtocol.ChallengeCS = 1
InstanceProtocol.FinishCS = 2
InstanceProtocol.BuyTimesCS = 3
InstanceProtocol.ChallengeSC = 101
InstanceProtocol.FinishSC = 102
InstanceProtocol.BuyTimesSC = 103

--pvp宝箱协议 主命令PvpChset
PvpChestProtocol = {}
PvpChestProtocol.RefreshChestCS = 1
PvpChestProtocol.BuyChestCS = 2
PvpChestProtocol.OpenChestCS = 3
PvpChestProtocol.OpenChestAtOnceCS = 4
PvpChestProtocol.RefreshChestSC = 101
PvpChestProtocol.BuyChestSC = 102
PvpChestProtocol.OpenChestSC = 103
PvpChestProtocol.OpenChestAtOnceSC = 104

--pvp匹配协议 主命令PvpMatch
PvpMatchProtocol = {}
PvpMatchProtocol.MatchCS = 1
PvpMatchProtocol.CancelCS = 2
PvpMatchProtocol.MatchSC = 101
PvpMatchProtocol.RematchSC = 102
PvpMatchProtocol.MatchSuccessSC = 103
PvpMatchProtocol.CancelSC = 104

--pvp战斗协议 主命令Pvp
PvpProtocol = {}
PvpProtocol.EnterRoomCS = 1
PvpProtocol.LoadingCS = 2
PvpProtocol.ReadyCS = 3
PvpProtocol.ReconnectCS = 4
PvpProtocol.ReconnectRoomDataCS = 5
PvpProtocol.EnterRobotRoomCS = 6
PvpProtocol.FinishRobotRoomCS = 7

PvpProtocol.EnterRoomSC = 101
PvpProtocol.PrepareSC = 102
PvpProtocol.LoadingSC = 103
PvpProtocol.ReadySC = 104
PvpProtocol.IdleTimeSC = 105
PvpProtocol.StartSC = 106
PvpProtocol.EndSC = 107
PvpProtocol.ResultSC = 108
PvpProtocol.ReconnectSC = 109
PvpProtocol.ReconnectRoomDataSC = 110
PvpProtocol.OppReconnectSC = 111
PvpProtocol.OppDisconnectSC = 112
PvpProtocol.RobotRoomDataSC = 113

-- 战斗协议
BattleProtocol = {}
BattleProtocol.PvpCommandCS = 1
BattleProtocol.PvpEndCS = 2
BattleProtocol.PvpUpdateCS = 3
BattleProtocol.PvpCommandSC = 101
BattleProtocol.PvpEndSC = 102
BattleProtocol.PvpUpdateSC = 103

-- 组队协议
TeamProtocol = {}
TeamProtocol.SetTeamCS = 1
TeamProtocol.SetTeamSC = 101

-- 任务协议
TaskProtocol = {}
TaskProtocol.TaskFinishCS = 1
TaskProtocol.TaskAwardCS = 2
TaskProtocol.TaskFinishSC = 101
TaskProtocol.TaskAwardSC = 102

-- 成就协议
AchievementProtocol = {}
AchievementProtocol.FinishCS = 1
AchievementProtocol.GainCS = 2
AchievementProtocol.FinishSC = 101
AchievementProtocol.GainSC = 102

-- 引导协议
GuideProtocol = {}
GuideProtocol.RecordCS = 1
GuideProtocol.RecordSC = 101

-- 工会协议
UnionProtocol = {}
UnionProtocol.UnionInfoCS = 1			-- 玩家所在公会信息
UnionProtocol.UnionMembersCS = 2		-- 玩家所在公会所有成员
UnionProtocol.UnionCreateCS = 3			-- 创建公会
UnionProtocol.UnionApplyCS = 4			-- 申请加入公会
UnionProtocol.UnionExitCS = 5			-- 退会
UnionProtocol.UnionLogListCS = 6		-- 玩家所在公会事件列表
UnionProtocol.UnionAuditListCS = 7		-- 玩家所在公会审核列表
UnionProtocol.UnionAuditCS = 8			-- 审核信息
UnionProtocol.UnionFunctionCS = 9		-- 公会相关操作(踢出、撤任、权利移交等)
UnionProtocol.UnionUnionListOutCS = 10	-- 公会列表(拥有公会,公会中请求列表)
UnionProtocol.UnionSearchCS = 11		-- 搜索公会
UnionProtocol.UnionEmblemCS = 12		-- 设置会徽
UnionProtocol.UnionNameCS = 13			-- 更改公会名
UnionProtocol.UnionNoticeCS = 14		-- 更改公告
UnionProtocol.UnionWelfareCS = 15		-- 福利领取
UnionProtocol.UnionSetAudit = 16		-- 设置审核
UnionProtocol.UnionMercenaryInfoCS =17 	-- 请求佣兵信息
UnionProtocol.UnionMercenarySendCS =18 	-- 自己主动派遣佣兵
UnionProtocol.UnionMercenaryCallCS =19 	-- 自己主动召回
UnionProtocol.UnionMercenaryGetCS =20	-- 请求佣兵详细信息

UnionProtocol.UnionInfoSC = 101			-- 回发玩家所在公会信息
UnionProtocol.UnionMembersSC = 102		-- 回发玩家所在公会所有成员
UnionProtocol.UnionCreateSC = 103		-- 回发创建公会
UnionProtocol.UnionApplySC = 104		-- 回发申请加入公会
UnionProtocol.UnionExitSC = 105			-- 回发退会
UnionProtocol.UnionLogListSC = 106		-- 回发玩家所在公会事件列表
UnionProtocol.UnionAuditListSC = 107	-- 回发玩家所在公会审核列表
UnionProtocol.UnionAuditSC = 108		-- 回发审核信息
UnionProtocol.UnionFunctionSC = 109		-- 回发公会相关操作(踢出、撤任、权利移交等)
UnionProtocol.UnionUnionListOutSC = 110	-- 回发公会列表(没有公会,请求公会列表)
UnionProtocol.UnionSearchSC = 111		-- 回发搜索公会
UnionProtocol.UnionEmblemSC = 112		-- 回发设置会徽
UnionProtocol.UnionNameSC = 113			-- 回发公会改名
UnionProtocol.UnionNoticeSC = 114		-- 回发更改公告
UnionProtocol.UnionWelfareSC = 115		-- 回发福利领取
UnionProtocol.UnionSetAuditSC = 116		-- 回发设置审核
UnionProtocol.UnionBeAuditSC = 117		-- 被审核者应答
UnionProtocol.UnionBeFunctionSC = 118	-- 被操作这应答

UnionProtocol.UnionMercenaryInfoSC = 119-- 接收佣兵信息
UnionProtocol.UnionMessageSC = 120	    -- 接收公会提示信息
UnionProtocol.UnionMercenaryCallSC = 122-- 接收主动召回,121听说服务器那边有人用了
UnionProtocol.UnionMercenaryGetSC = 123 -- 接收佣兵详细信息

--我也不知道为啥要这样子写在这里
-- 公会佣兵相关
-- UnionMercenaryProtocol = {}
-- UnionMercenaryProtocol.applyMercenaryInfoCS = 0				-- 获取佣兵信息
-- UnionMercenaryProtocol.sendCS = 1							-- 派遣
-- UnionMercenaryProtocol.callBackCS = 2						-- 召回
-- UnionMercenaryProtocol.requstMercenaryInfoCS = 3			-- 拉取佣兵详细信息


UnionFuncType = {}
UnionFuncType.Jion = 0		-- 加入
UnionFuncType.Exit = 1		-- 退出
UnionFuncType.Kick = 2		-- 踢出
UnionFuncType.Appoint = 3	-- 任命
UnionFuncType.Assign = 4	-- 分配物品
UnionFuncType.Transfer = 5	-- 权利移交
UnionFuncType.Relieve = 6	-- 撤任
UnionFuncType.dismiss = 7	-- 解散


-- 奖励类型
AwardType = {}
AwardType.Gold = 1
AwardType.Diamond = 2
AwardType.Exp = 3
AwardType.Energy = 4
AwardType.Summoner = 5
AwardType.Hero = 6
AwardType.Equip = 7
AwardType.Item = 8

-- 邮件协议
MailProtocol = {}
MailProtocol.ReadMailCS = 1
MailProtocol.GetMailGoodsCS = 2
MailProtocol.WebMailCS = 3
MailProtocol.ReadMailSC = 101
MailProtocol.GetMailGoodsSC = 102
MailProtocol.WebMailSC = 103
MailProtocol.SendMailSC = 104

-- 公会任务协议
UnionTaskProtocol = {}
UnionTaskProtocol.SingleTaskCS = 1			-- 请求个人任务列表
UnionTaskProtocol.SingleAcceptCS = 2		-- 接收任务
UnionTaskProtocol.SingleChallengeCS = 3		-- 挑战任务关卡
UnionTaskProtocol.SingleFinishCS = 4		-- 完成挑战
UnionTaskProtocol.SingleRewardCS = 5		-- 领取任务奖励
UnionTaskProtocol.TeamInfoCS = 6			-- 请求团队任务信息
UnionTaskProtocol.TeamSetNextTargetCS = 7	-- 设置下个目标的任务
UnionTaskProtocol.TeamRewardCS = 8			-- 领取资源点奖励
UnionTaskProtocol.TeamChallengeCS = 9		-- 挑战团队任务
UnionTaskProtocol.TeamFinishCS = 10			-- 完成团队任务

UnionTaskProtocol.SingleTaskSC = 101		-- 回发个人任务列表
UnionTaskProtocol.SingleAcceptSC = 102		-- 回发接收任务
UnionTaskProtocol.SingleChallengeSC = 103	-- 回发挑战任务关卡
UnionTaskProtocol.SingleFinishSC = 104		-- 回发完成结果
UnionTaskProtocol.SingleRewardSC = 105		-- 回发领取任务奖励
UnionTaskProtocol.TeamInfoSC = 106			-- 回发团队任务信息
UnionTaskProtocol.TeamSetNextTargetSC = 107	-- 回发设置下个目标的任务
UnionTaskProtocol.TeamRewardSC = 108		-- 回发领取资源点奖励
UnionTaskProtocol.TeamChallengeSC = 109		-- 回发挑战团队任务
UnionTaskProtocol.TeamFinishSC = 110		-- 回发完成团队任务

--金币试炼协议
GoldTestProtocol = {}
GoldTestProtocol.BattleCS = 1           --进入金币试炼战斗，无包体
GoldTestProtocol.BattleOverCS = 2       --金币试炼战斗结束，提交总伤害
GoldTestProtocol.ChestStateCS = 3       --改变宝箱状态，要开启的宝箱
GoldTestProtocol.BattleSC = 101         --通用包，进入战斗
GoldTestProtocol.BattleOverSC = 102     --战斗结束，结算奖励金币
GoldTestProtocol.ChestStateSC = 103     --总金币，更新宝箱状态

--英雄试炼协议
HeroTestProtocol = {}
HeroTestProtocol.BattleCS = 1           --进入英雄试炼战斗，包体为难度和副本ID
HeroTestProtocol.BattleOverCS = 2       --英雄试炼结束，无包体
HeroTestProtocol.BattleSC = 101         --开始战斗，无包体
HeroTestProtocol.BattleOverSC = 102     --英雄试炼结束，开始结算，无包体

--爬塔试炼协议
TowerTestProtocol = {}
TowerTestProtocol.TowerFightingCS = 1 	            --迎战敌人
TowerTestProtocol.TowerFinishCS = 2 	            --战斗结束
TowerTestProtocol.TowerChoseOuterBonusCS = 3 	    --选择buff
TowerTestProtocol.TowerOpenTreasureCS = 4 	        --打开宝箱
TowerTestProtocol.TowerOneKeyFightingCS = 5 	    --一键爬塔
TowerTestProtocol.TowerFightingSC = 101	            --迎战敌人结果
TowerTestProtocol.TowerFinishSC = 102 	            --战斗结束获得的物品
TowerTestProtocol.TowerChoseOuterBonusSC = 103	    --选择buff
TowerTestProtocol.TowerOpenTreasureSC = 104	        --打开宝箱
TowerTestProtocol.TowerOneKeyFightingSC = 105 	    --一键爬塔

-- 商店协议
ShopProtocol = {}
ShopProtocol.ShopBuyCS = 1          -- 购买商品
ShopProtocol.ShopRefreshCS = 2      -- 刷新商品
ShopProtocol.ShopUnionBuyCS = 3     -- 购买公会商品
ShopProtocol.ShopBuySC = 101        -- 购买商品返回
ShopProtocol.ShopRefreshSC = 102    -- 刷新商品返回
ShopProtocol.ShopUnionBuySC = 103   -- 购买公会商品
ShopProtocol.ShopUnionFreshSC = 104 -- 购买公会商品

-- 排行
RankProtocol = {}
RankProtocol.RankInfoCS = 1			-- 排行榜
RankProtocol.RankInfoSC = 101		-- 排行榜

-- 运营活动协议
OperateActiveProtocol = {}
OperateActiveProtocol.OperateActiveGetCS = 1
OperateActiveProtocol.OperateActiveGetSC = 101
OperateActiveProtocol.OperateActiveTaskUpdateSC = 102

OperateActiveProtocol.OperateActiveExchangeGetCS = 4
OperateActiveProtocol.OperateActiveExchangeGetSC = 105

-- 七日狂欢活动协
SevenCrazyProtocol = {}
SevenCrazyProtocol.SevenCrazyGetCS = 2
SevenCrazyProtocol.SevenCrazyGetSC = 103
SevenCrazyProtocol.SevenCrazyGetUpdateSC = 102


-- 错误码
ErrorCodeProtocol = {}
ErrorCodeProtocol.errorCode = 1

-- 支付
PayProtocol = {}
PayProtocol.payYSDKCS = 1
PayProtocol.payYSDKSC = 101


-- 公会远征
ExpeditionProtocol = {}
ExpeditionProtocol.InfoCS = 1            -- 公会远征信息
ExpeditionProtocol.MapSetCS = 2          -- 公会远征设置
ExpeditionProtocol.StageStartCS = 3      -- 公会远征关卡开始
ExpeditionProtocol.StageFinishCS = 4     -- 公会远征关卡结束
ExpeditionProtocol.RewardGetCS = 5       -- 公会远征奖励领取
ExpeditionProtocol.DamageRankCS = 6      -- 公会远征伤害排行
ExpeditionProtocol.StageInfoCS = 7       -- 公会远征关卡信息

ExpeditionProtocol.InfoSC = 101          -- 公会远征信息下发
ExpeditionProtocol.MapSetSC = 102        -- 公会远征设置
ExpeditionProtocol.StageStartSC = 103    -- 公会远征关卡开始
ExpeditionProtocol.StageFinishSC = 104   -- 公会远征关卡结束
ExpeditionProtocol.StagePassSC = 105     -- 公会远征通过广播
ExpeditionProtocol.RewardGetSC = 106     -- 公会远征奖励领取
ExpeditionProtocol.DamageRankSC = 107    -- 公会远征伤害排行
ExpeditionProtocol.StageInfoSC = 108     -- 公会远征关卡信息
ExpeditionProtocol.RewardFlagSC = 109    -- 公会远征奖励标识

-- 通知信息
NoticeProtocol = {}
NoticeProtocol.NoticeSC = 101            -- 通知信息

-- 聊天信息
ChatProtocol = {}
ChatProtocol.JoinRoomCS = 1              -- 加入房间
ChatProtocol.QuitRoomCS = 2              -- 退出房间
ChatProtocol.SendMessageCS = 3           -- 发送消息

ChatProtocol.ReceiveMoreMessageSC = 101      -- 接受多条消息
ChatProtocol.ReceiveSingleMessageSC = 102    -- 接受单条消息

BlueGemProtocol = {}
BlueGemProtocol.BlueGemGetCS = 3
BlueGemProtocol.BlueGemGetSC = 104
BlueGemProtocol.BlueGemGetUpdateSC = 102

LookProtocol = {}
LookProtocol.LookHeroCS = 1
LookProtocol.LookEquipCS = 2
LookProtocol.LookHeroSC = 101
LookProtocol.LookEquipSC = 102