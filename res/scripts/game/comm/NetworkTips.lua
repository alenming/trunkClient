-- 网络连接提示

NetworkTips = {}
NetworkTips.delayTimeFunc = nil
NetworkTips.timeOutFunc = nil

local scheduler = require("framework.scheduler")

function NetworkTips.init()
    EventManager:addEventListener(GameEvents.EventNetReconnectFinish, NetworkTips.reconnectFinishCallback)
end

function NetworkTips.getNetworkNode()
    local networkNode = display.getRunningScene():getChildByName("NETWORKTIPS")
    local networkAction = nil
    if not networkNode then
        networkNode = getResManager():cloneCsbNode(ResConfig.Common.Csb2.connectTips)
        CommonHelper.layoutNode(networkNode)
        networkAction = cc.CSLoader:createTimeline(ResConfig.Common.Csb2.connectTips)
        networkNode:runAction(networkAction)
        networkNode.networkAction = networkAction
        networkNode:setName("NETWORKTIPS")
        networkNode:setGlobalZOrder(5)
        display.getRunningScene():addChild(networkNode, 5)
    end

    return networkNode, networkNode.networkAction
end

-- 创建提示
function NetworkTips.createTips(delayTime, timeOut, bufferData, s2cCmd, responeCallback)
    NetworkTips.lastBufferData = bufferData
    NetworkTips.s2cCmd = s2cCmd
    NetworkTips.responeCallback = responeCallback
    NetworkTips.showTips(delayTime, timeOut)
end

-- 关闭提示
function NetworkTips.closeTips()
    NetworkTips.removeResponeAndBuffData()

    local networkNode, _ = NetworkTips.getNetworkNode()
    networkNode:setVisible(false)

    if NetworkTips.delayTimeFunc then
        scheduler.unscheduleGlobal(NetworkTips.delayTimeFunc)
        NetworkTips.delayTimeFunc = nil
    end

    if NetworkTips.timeOutFunc then
        scheduler.unscheduleGlobal(NetworkTips.timeOutFunc)
        NetworkTips.timeOutFunc = nil
    end
end

-- 重连成功
function NetworkTips.reconnectFinishCallback()
    -- 还有东西需要发送
    if NetworkTips.lastBufferData then
        request(NetworkTips.lastBufferData)
        NetworkTips.showTips()
    end
end

function NetworkTips.dialogTips()
    local remountFunc = function ()
        NetworkTips.removeResponeAndBuffData()
        -- 现在登出还是存在问题, 所以直接退出游戏
        closeGame()

        --[==[
        logout()
        
		if SceneManager.CurScene == SceneManager.Scene.SceneLogin then
			cc.Director:getInstance():endToLua()
		elseif SceneManager.CurScene == SceneManager.Scene.SceneBattle then
            BattleHelper.finishCallback = nil
            finishBattle()
            UIManager.clearSaveUI()
            SceneManager.loadScene(SceneManager.Scene.SceneLogin)
        else
            UIManager.clearSaveUI()
			SceneManager.loadScene(SceneManager.Scene.SceneLogin)
		end
        ]==]
    end

    -- 重试
    local reTryingFunc = function ()
        EventManager:raiseEvent(GameEvents.EventNetDisconnect, true)
    end

    local params = {}
    params.msg = CommonHelper.getUIString(975)
    params.rightLanId = 2120
    params.confirmFun = reTryingFunc
    params.cancelFun = remountFunc
    UIManager.open(UIManager.UI.UIDialogBox, params)
end

function NetworkTips.showTips(delayTime, timeOut)
    delayTime = delayTime or 1.0
    timeOut = timeOut or 10.0
    
    if NetworkTips.delayTimeFunc then
        scheduler.unscheduleGlobal(NetworkTips.delayTimeFunc)
        NetworkTips.delayTimeFunc = nil
    end

    if NetworkTips.timeOutFunc then
        scheduler.unscheduleGlobal(NetworkTips.timeOutFunc)
        NetworkTips.timeOutFunc = nil
    end

    local networkNode, networkAction = NetworkTips.getNetworkNode()
    networkAction:play("Wait", true)
    networkNode:setVisible(true)

    -- 延迟时间提示
    NetworkTips.delayTimeFunc = scheduler.scheduleGlobal(function(dt) 
        networkAction:play("Normal", true)
        scheduler.unscheduleGlobal(NetworkTips.delayTimeFunc)
        NetworkTips.delayTimeFunc = nil

        -- 超时提示
        NetworkTips.timeOutFunc = scheduler.scheduleGlobal(function(dt) 
            networkNode:setVisible(false)
            scheduler.unscheduleGlobal(NetworkTips.timeOutFunc)
            NetworkTips.timeOutFunc = nil

            NetworkTips.dialogTips()
        end, timeOut)
	end, delayTime)
end

function NetworkTips.removeResponeAndBuffData()
    if NetworkTips.s2cCmd then
        NetHelper.removeResponeHandler(NetworkTips.s2cCmd, NetworkTips.responeCallback)
    end

    NetworkTips.s2cCmd = nil
    NetworkTips.responeCallback = nil

    if NetworkTips.lastBufferData then
        deleteBufferData(NetworkTips.lastBufferData)
        NetworkTips.lastBufferData = nil
    end
end