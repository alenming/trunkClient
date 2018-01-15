
local UIReconnect = class("UIReconnect", function ()
	return require("common.UIView").new()
end)

--根据状态, 回调对应的方法
local RoomState = {
    "noRoom",         --房间不存在
    "prepareLoad",    --等待玩家进入房间
    "loading",        --加载中
    "idleTime",       --空闲准备时间
    "fighting",       --战斗中
    "gameover"        --游戏结束
}

function UIReconnect:ctor()
    --初始化界面
    --self.rootPath = ResConfig.UIReconnect.Csb2.mainPanel
    --self.root = getResManager():getCsbNode(self.rootPath)
    --self.rootAct = cc.CSLoader:createTimeline(self.rootPath)
    --self.root:runAction(self.rootAct)
    --self:addChild(self.root)
end

function UIReconnect:onOpen()
    --注册网络回调
    local reconnectCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ReconnectSC)
    self.callbackHandler = handler(self, self.onReconnectCallback)
    NetHelper.setResponeHandler(reconnectCmd, self.callbackHandler)
    --发送重连请求
    local pvpModel = getGameModel():getPvpModel()
    local battleId = pvpModel:getPvpInfo().BattleId
    local BufferData = NetHelper.createBufferData(MainProtocol.Pvp, PvpProtocol.ReconnectCS)
    BufferData:writeInt(battleId)
    NetHelper.request(BufferData)
end

function UIReconnect:onClose()
    --取消网络回调
    local reconnectCmd = NetHelper.makeCommand(MainProtocol.Pvp, PvpProtocol.ReconnectSC)
    NetHelper.removeResponeHandler(reconnectCmd, self.callbackHandler)
end 

function UIReconnect:onReconnectCallback(main, sub, data)
    print("UIReconnect callback!!")
    --根据返回的房间状态, 选择对应回调
    local state = data:readInt()
    local roomType = data:readInt()
    getGameModel():getPvpModel():setRoomType(roomType)
    local func = self[RoomState[state]]
    print("call"..RoomState[state] .." ".. state)
    if func then
        func()
    end
end

function UIReconnect:noRoom()
    --设置battleid为0
    local pvpModel = getGameModel():getPvpModel()
    pvpModel:setBattleId(0)
    --切回大厅界面
    SceneManager.loadScene(SceneManager.Scene.SceneHall)
end

function UIReconnect:prepareLoad()
    --切到匹配界面
    UIManager.open(UIManager.UI.UIArenaMatch, 2)
end

function UIReconnect:loading()
    --切到加载界面 
    UIManager.open(UIManager.UI.UIArenaMatch, 3)
end

function UIReconnect:fighting()
     --切到加载界面 
    UIManager.open(UIManager.UI.UIArenaMatch, 4)
end

function UIReconnect:gameover()
    --设置battleid为0
    local pvpModel = getGameModel():getPvpModel()
    pvpModel:setBattleId(0)
    --切回大厅界面
    SceneManager.loadScene(SceneManager.Scene.SceneHall)
end

return UIReconnect
