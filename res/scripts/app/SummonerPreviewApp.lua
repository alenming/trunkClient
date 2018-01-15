require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")
require("common.Protocol")
require("common.NetHelper")
require("game.comm.CsbTools")
require("common.ModelHelper")
require("common.CommonHelper")
require("common.IconHelper")
require("game.comm.GlobalListen")
require("Helper")
require("summonerComm.UIConfig")
require("summonerComm.SceneConfig")

local UIManager = require("common.UIManager")
local SceneManager = require("common.SceneManager")

if table.unpack == nil then
    table.unpack = unpack
end

local SummonerPreviewApp = class("SummonerPreviewApp", cc.mvc.AppBase)

function SummonerPreviewApp:ctor()
    SummonerPreviewApp.super.ctor(self) 
    UIManager.init()
    SceneManager.init()
end

function SummonerPreviewApp:run()
    -- 关卡数据
    local stageId   = 1
    local stageLv   = 1
    local bufferData = newBufferData()
    bufferData:writeInt(stageId)        -- 关卡ID
    bufferData:writeInt(stageLv)        -- 关卡等级
    bufferData:writeInt(1)              -- 对战类型
    bufferData:writeInt(0)              -- 扩展字段
    bufferData:writeInt(0)              -- 扩展字段
    bufferData:writeInt(0)              -- 战斗内buff字段
    bufferData:writeInt(1)              -- 玩家数量
    
    -- 玩家属性
    local userId    = -1
    local userLv    = 1
    local cardCount = 7
    local userName = "Player"
    bufferData:writeInt(userId)         -- 玩家id
    bufferData:writeInt(userLv)         -- 玩家等级
    bufferData:writeInt(1)              -- 玩家阵营
    bufferData:writeInt(0)              -- buff数量
    bufferData:writeInt(cardCount)      -- 士兵个数
    bufferData:writeInt(0)              -- 佣兵数量
    bufferData:writeInt(0)              -- 玩家身份显示(蓝钻)
    bufferData:writeString(userName)    --
    for i = string.len(userName) + 2, 32 do
        bufferData:writeChar(0)
    end

    -- 召唤师
    local heroId = cc.UserDefault:getInstance():getIntegerForKey("myhero", 1000);
    bufferData:writeInt(heroId)

    -- 士兵列表
    for i=1, cardCount do
        local cardIdStr     = "mysolider" .. i
        local cardStarStr   = "star" .. i
        local cardTalentStr = "talent" .. i
        local cardLevelStr  = "level" .. i
        local cardId        = cc.UserDefault:getInstance():getIntegerForKey(cardIdStr, 10200)
        local cardStar      = cc.UserDefault:getInstance():getIntegerForKey(cardStarStr, 2)
        local cardTalent    = cc.UserDefault:getInstance():getIntegerForKey(cardTalentStr, 2)
        local cardLevel     = cc.UserDefault:getInstance():getIntegerForKey(cardLevelStr, 1)
        bufferData:writeInt(cardId)     -- 士兵id
        bufferData:writeInt(cardLevel)  -- 士兵等级
        bufferData:writeInt(cardStar)   -- 士兵星级
        bufferData:writeInt(0)          -- 士兵经验

        for j = 1, 8 do
            bufferData:writeChar(0)     -- 天赋
        end

        bufferData:writeInt(0)          -- 装备个数
    end
    
    bufferData:resetOffset()
    -- 打开房间
    openAndinitRoom(bufferData)
    deleteBufferData(bufferData)
    initUserId(userId)
    -- 加载大厅界面资源
    local SceneManager = require("common.SceneManager")
    SceneManager.loadScene(SceneManager.Scene.SceneBattle)
end

return SummonerPreviewApp