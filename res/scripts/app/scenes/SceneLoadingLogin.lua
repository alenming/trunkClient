--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-07-29 11:31
** 版  本:	1.0
** 描  述:  登录资源加载提示界面
** 应  用:
********************************************************************/
--]]

local SceneLoginLoading = class("SceneLoginLoading", function()
    return display.newScene("SceneLoginLoading")
end)

function SceneLoginLoading:ctor(resloader, finishCallback)
    if resloader == nil then
        print("resloader is nil !")
        return
    end

    self.resloader = resloader
    self.finishCallbackFun = finishCallback

    self:createMainLayer()

    resloader.LoadingCallback = handler(self, self.loadCallBack)
    resloader.LoadFinishCallback = handler(self, self.finishCallback)
    httpAnchor(6001)
end

function SceneLoginLoading:createMainLayer()
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

    math.randomseed(os.time())
    local ran = math.random(getLoadingTipsCount())
    local str = getLoadingTipsConfItem(math.max(1, ran))
    local loadingTips = getChild(csbNode, "MainPanel/UpdateLoading/LoadingTips")
    loadingTips:setString(str)
end

function SceneLoginLoading:loadCallBack(allResCount, loadResCount, curResName, isSuccess)
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

function SceneLoginLoading:finishCallback()
    if type(self.finishCallback) == "function" then
        print("SceneLoginLoading.finishCallback")
        self.finishCallbackFun()
    end
    self:removeFromParent()
    httpAnchor(6003)
end

return SceneLoginLoading