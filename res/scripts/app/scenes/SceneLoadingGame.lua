--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-07-29 14:31
** 版  本:	1.0
** 描  述:  游戏中资源加载提示界面
** 应  用:
********************************************************************/
--]]

local SceneGameLoading = class("SceneGameLoading", function()
    return display.newScene("SceneGameLoading")
end)

function SceneGameLoading:ctor(resloader, finishCallback)
    if resloader == nil then
        print("resloader is nil !")
        return
    end

    self:setNodeEventEnabled(true)

    self.resloader = resloader
    self.finishCallbackFun = finishCallback

    self:createMainLayer()

    resloader.LoadingCallback = handler(self, self.loadCallBack)
    resloader.LoadFinishCallback = handler(self, self.finishCallback)
    httpAnchor(6001)
end

function SceneGameLoading:onEnter()
    math.randomseed(os.time())
    local ran = math.random(getLoadingTipsCount())
    local str = getLoadingTipsConfItem(math.max(1, ran))
    self.LoadingTips:setString(str)
end

function SceneGameLoading:createMainLayer()
    -- 创建一个层
    self.mainLayer = display.newLayer()
    self:addChild(self.mainLayer)

    -- 创建csb节点
    local csbNode = cc.CSLoader:createNode("ui_new/l_loading/Loading.csb")
    self.mainLayer:addChild(csbNode)
    local csbAct = cc.CSLoader:createTimeline("ui_new/l_loading/Loading.csb")
    csbNode:runAction(csbAct)
    csbAct:play("Normal", true)

    -- 自适应分辨率
    local winSize = display.size
    csbNode:setContentSize(winSize.width, winSize.height)
    ccui.Helper:doLayout(csbNode)

    self.LoadingBar = getChild(csbNode, "MainPanel/UpdateLoading/LoadingBar")
    self.LoadingBar:setPercent(0)
    self.LoadingNum = getChild(csbNode, "MainPanel/UpdateLoading/LoadingNum")
    self.LoadingNum:setString("0")
    self.LoadingTips = getChild(csbNode, "MainPanel/UpdateLoading/LoadingTips")
end

function SceneGameLoading:loadCallBack(allResCount, loadResCount, curResName, isSuccess)
    if isSuccess then
        local percent = allResCount / loadResCount
        self.LoadingBar:setPercent(percent * 100)
        self.LoadingNum:setString(string.format("%d%%", math.min(percent*100, 100)))

        -- print("LoadRes success", curResName)
    else
        print("LoadRes fail !!", curResName)
        httpAnchor(6002, curResName)
    end
end

function SceneGameLoading:finishCallback()
    if type(self.finishCallback) == "function" then
        print("SceneGameLoading.finishCallback")
        self.finishCallbackFun()
    end
    self:removeFromParent()
    httpAnchor(6003)
end

return SceneGameLoading