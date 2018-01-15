require("config")
require("Helper")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")
require("common.CommonHelper")
require("common.ConfigHelper")
require("common.ConfigHelperTest")
require("common.Protocol")
require("common.NetHelper")
require("common.ModelHelper")
require("common.IconHelper")
require("common.MusicManager")
require("common.AnimatePool")
require("common.BattleHelper")
require("common.TeamHelper")
require("common.UserDatas")
require("common.PushManager")
require("common.TimeHelper")
require("common.WidgetExtend")
require("common.PressExtend")
require("model.GameModel")
require("summonerComm.GameEvents")
require("summonerComm.UIConfig")
require("summonerComm.SceneConfig")
require("game.taskAndAchieve.TaskManage")
require("game.taskAndAchieve.AchieveManage")
require("game.taskAndAchieve.ConditionProcess")
require("game.rank.RankData")
require("game.comm.CsbTools")
require("game.comm.GlobalListen")
require("game.comm.UIAwardHelper")
require("game.comm.ConnectionTips")
require("game.comm.UICommHelper")
require("game.comm.FilterSensitive")
require("game.comm.RedPointHelper")
require("game.comm.PlatformModel")
require("game.comm.NetworkTips")
require("game.chat.ChatHelper")
require("game.notice.MarqueeHelper")
require("game.qqHall.QQHallHelper")
require("game.pvp.UIReplayHelper")

local UIManager = require("common.UIManager")
local SceneManager = require("common.SceneManager")
local SummonerApp = class("SummonerApp", cc.mvc.AppBase)
EventManager = require("common.EventManager").new() -- 全局事件监听管理器
KeyBoardListener = require("game.comm.KeyBoardListener").new()  -- 全局键盘监听

if table.unpack == nil then
    table.unpack = unpack
end

function SummonerApp:ctor()
    SummonerApp.super.ctor(self)
    UIManager.init()
    SceneManager.init()
    GlobalListen.init()
    MusicManager.init()
end

function SummonerApp:enterGuideStage()
      -- 根据配置表构造第一关的战斗包
    local conf = getGuideBattleConfItem()
    local bufferData = newBufferData()
    bufferData:writeInt(conf.StageId) -- 关卡ID
    bufferData:writeInt(1) -- 关卡等级
    bufferData:writeInt(8) -- 房间对战类型
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 战斗内buff字段
    bufferData:writeInt(1) -- 房间内的玩家数量

    -- 玩家属性
    bufferData:writeInt(-1) -- 玩家id
    bufferData:writeInt(conf.HeroLv) -- 玩家等级
    bufferData:writeInt(1) -- 玩家阵营
    bufferData:writeInt(0) -- 战斗外BUFF数量
    bufferData:writeInt(#conf.Soliders) -- 玩家士兵个数
    bufferData:writeInt(0) -- 佣兵数量
    bufferData:writeInt(0) -- 玩家身份显示(蓝钻)
    local playerName = "莱奥"
    bufferData:writeString(playerName) -- 玩家名字 32字节
    -- 写入后面额外的字节
    for i = string.len(playerName) + 2, 32 do
        bufferData:writeChar(0)
    end

    -- 召唤师
    bufferData:writeInt(conf.HeroId)

    -- 士兵列表
    for k,v in ipairs(conf.Soliders) do
        bufferData:writeInt(v.SoliderId) -- 士兵id
        bufferData:writeInt(v.SoliderLevel) -- 士兵等级
        bufferData:writeInt(v.SoliderStar) -- 士兵星级
        bufferData:writeInt(0) -- 士兵经验
        for j = 1, 8 do
            bufferData:writeChar(0)     -- 天赋
        end
        bufferData:writeInt(0) -- 装备个数
    end

    bufferData:resetOffset()
    -- 打开房间
    openAndinitRoom(bufferData)
    deleteBufferData(bufferData)

    -- 加载战斗界面资源
    local SceneManager = require("common.SceneManager")
    --SceneManager.CurScene = SceneManager.Scene.SceneWorld
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)

    -- 设置战斗结束回调
    BattleHelper.finishCallback = function()
        finishBattle() 
        UIManager.pushSaveUI(UIManager.UI.UIHallBG)
        UIManager.pushSaveUI(UIManager.UI.UIHall)
        UIManager.pushSaveUI(UIManager.UI.UIArena)
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end
end

function SummonerApp:run()
    -- 登录界面不走SceneManager，因为SceneManager会预加载大量公共资源，导致界面打开延迟
    -- 不走SceneManager并不会导致界面打开异常，因为UIManager的open方法在检测到资源没有加载时，会异步加载资源然后打开界面
    --cc.Director:getInstance():getRunningScene():removeAllChildren()
    --if device.platform == "android" or device.platform == "ios" then
    --    UIManager.open(UIManager.UI.UILoginSDK)
    --else
    --    UIManager.open(UIManager.UI.UILogin)
    --end
    --app:enterScene("SceneLogin")
    SceneManager.loadScene(SceneManager.Scene.SceneLogin)
    --configHelperTest()
end

function SummonerApp:enterGame()
    UserDatas.init()
    ChatHelper.init()
    TaskManage.init()
    AchieveManage:init()
    RedPointHelper.init()
    ModelHelper.init()
    RankData.init()
    NetworkTips.init()
    ConnectionTips.init()
    MarqueeHelper.init()
    --引导监听
    local GuideManager = require("guide.GuideManager")
    GuideManager.init()

    -- 加载大厅界面资源
    local SceneManager = require("common.SceneManager")
    -- 先判断是否首次开启新手引导
    for k,v in pairs(getGameModel():getGuideModel():getActives()) do
        print("=========== Open Guide ============ " .. v)
        if v == 1 and not GlobalCloseGuide then
            self:enterGuideStage()
            return
        end
    end
    local pvpModel = getGameModel():getPvpModel()
    if pvpModel:getPvpInfo().BattleId > 0 then
        --如果pvp模型中的battleid不为0, 切到重连场景
        SceneManager.loadScene(SceneManager.Scene.ScenePvp) 
    else
        --切到普通大厅
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end
    httpAnchor(7001)
end

return SummonerApp