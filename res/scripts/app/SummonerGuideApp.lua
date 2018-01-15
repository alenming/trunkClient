--[[require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")
require("common.Protocol")
require("common.NetHelper")
require("game.comm.CsbTools")
require("common.ModelHelper")
require("common.CommonHelper")
require("common.IconHelper")
require("common.UserDatas")
require("game.comm.GlobalListen")
require("Helper")
require("summonerComm.GameEvents")
require("summonerComm.UIConfig")
require("summonerComm.SceneConfig")
require("game.taskAndAchieve.TaskManage")
require("game.taskAndAchieve.AchieveManage")
require("game.taskAndAchieve.ConditionProcess")
require("common.AnimatePool")
require("game.comm.UIAwardHelper")
require("game.comm.RedPointHelper")

local UIManager = require("common.UIManager")
local SceneManager = require("common.SceneManager")
local SummonerApp = class("SummonerApp", cc.mvc.AppBase)
EventManager = require("common.EventManager").new() -- 全局事件监听管理器

if table.unpack == nil then
    table.unpack = unpack
end

function SummonerApp:ctor()
    SummonerApp.super.ctor(self) 
    UIManager.init()
    SceneManager.init()
    TaskManage.init()
    AchieveManage:init()
end

function SummonerApp:run()
    UserDatas.init()
    RedPointHelper.init()
    ModelHelper.init()
    GlobalListen.init()

    --引导监听
    local GuideManager = require("guide.GuideManager")
    GuideManager.init()

    -- 根据配置表构造第一关的战斗包
    local conf = getGuideBattleConfItem()
    local bufferData = newBufferData()
    bufferData:writeInt(conf.StageId) -- 关卡ID
    bufferData:writeInt(1) -- 关卡等级
    bufferData:writeInt(8) -- 房间对战类型
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- 扩展字段
    bufferData:writeInt(0) -- BUFF数量
    bufferData:writeInt(1) -- 房间内的玩家数量
    -- 玩家属性
    bufferData:writeInt(1) -- 玩家id
    bufferData:writeInt(conf.HeroLv) -- 玩家等级
    bufferData:writeInt(1) -- 玩家阵营
    bufferData:writeInt(0) -- OuterBonus数量
    bufferData:writeInt(#conf.Soliders) -- 玩家士兵个数
    bufferData:writeInt(0) -- 佣兵数量
    local playerName = "player"
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
        bufferData:writeInt(1) -- 天赋
        bufferData:writeInt(1) -- 技能等级1
        bufferData:writeInt(1) -- 技能等级2
        bufferData:writeInt(0) -- 装备个数
    end

    bufferData:resetOffset()
    -- 打开房间
    openAndinitRoom(bufferData)
    deleteBufferData(bufferData)

    -- 加载大厅界面资源
    local SceneManager = require("common.SceneManager")
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
end

return SummonerApp]]