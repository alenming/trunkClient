--[==[
热更新主界面: 
    创建热更新界面
    热更新处理(成功, 失败, 文件比较大, 大版本更新)
    热更新完成转到sdk登陆处理
注意事项: 
    该lua再次启动才能生效, 最好不要热更新, 避免出错后无法挽回
    此界面不能包含除热更新和游戏登陆的其他lua, 并且只有热更新完成后才开始包含游戏登陆的lua
    , 从而保证除了UpdateScene.lua不能热更新,其他lua都能进行热更新
]==]
local UpdateScene = class("UpdateScene", function()
    return display.newScene("UpdateScene")
end)
local scheduler = require("framework.scheduler")
require("game.update.updateHelper")

local manifestPath = "project.manifest"
local tempManifestPath = "project.manifest.temp"
local storagePath = cc.FileUtils:getInstance():getWritablePath() .. "summonerUpdate"

cc.EventAssetsManagerEx =
{
    EventCode = 
    {
        ERROR_NO_LOCAL_MANIFEST = 0,
        ERROR_DOWNLOAD_MANIFEST = 1,
        ERROR_PARSE_MANIFEST = 2,
        NEW_VERSION_FOUND = 3,
        ALREADY_UP_TO_DATE = 4,
        UPDATE_PROGRESSION = 5,
        ASSET_UPDATED = 6,
        ERROR_UPDATING = 7,
        UPDATE_FINISHED = 8,
        UPDATE_FAILED = 9,
        ERROR_DECOMPRESS = 10
    },
}

cc.AssetsManagerExStatic =
{
    VERSION_ID  = "@version",
    MANIFEST_ID = "@manifest",
}

local updateType = {
    null                = 0,
    checkUpdate         = 1, -- 检测热更新
    updateSizeOut       = 2, -- 弹出提示, 更新包比较大
    updateManifestFail  = 3, -- 弹出提示, 更新manifest失败
    updateFileFail      = 4, -- 弹出提示, 更新失败
    updateBigVersion    = 5, -- 弹出提示, 大版本更新
    enterMark           = 6, -- 进入商店
    updateFile          = 7, -- 正在更新文件
    updateFinish        = 8, -- 更新完成
    updateSkip          = 9, -- 更新跳过
    cancelSizeOut       = 10,-- 放弃大包更新
    cancelManifestFail  = 11,-- 放弃重试更新
    cancelFileFail      = 12,-- 放弃重试更新
    cancelBigVersion    = 13,-- 放弃大版本更新
    cancelEnterMark     = 14,-- 取消进入商店
    gameInit            = 15,-- 游戏初始化
    enterSDK            = 16,-- 进入sdk
}   

--分割字符串
local function split_str(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- 递归获取节点
local function getChildByPath(node, path)
    local list = split_str(path, "/")
    local ret = node
    for k, v in pairs(list) do
        if not ret then 
            return nil
        end
        ret = ret:getChildByName(v)
    end
    return ret
end

function UpdateScene:ctor()
    updateHelper.autoClearCache(manifestPath, storagePath.."/"..manifestPath, storagePath, storagePath)
    -- 创建热更新界面
    self.loginCsb = cc.CSLoader:createNode("ui_new/l_login/LoadingBg.csb")
    self:addChild(self.loginCsb, 0)
    -- csb动画
    local loginCsbAct = cc.CSLoader:createTimeline("ui_new/l_login/LoadingBg.csb")
    self.loginCsb:runAction(loginCsbAct)
    -- 播放csb动画, 先播放Begin 然后循环播放Loop
    loginCsbAct:play("Begin", false)
    loginCsbAct:setFrameEventCallFunc(function()
        loginCsbAct:clearFrameEventCallFunc()
        loginCsbAct:play("Loop", true)
    end)

    -- 自适应分辨率
    self.loginCsb:setContentSize(display.width, display.height)
    ccui.Helper:doLayout(self.loginCsb)

    -- 进度条相关面板
    self.barLayout = getChildByPath(self.loginCsb, "MainPanel/UpdateLoading")
    -- 进度条
    self.loadingBar = getChildByPath(self.barLayout, "LoadingBar")
    -- 进度条提示
    self.tipsLab = getChildByPath(self.barLayout, "LoadingTips")
    -- 进度条进度
    self.barLab = getChildByPath(self.barLayout, "LoadingNum")
    -- 登陆面板
    self.loginLayout = getChildByPath(self.loginCsb, "MainPanel/OnlineMode") 
    -- 注册点击监听
    self.barLayout:setTouchEnabled(true)
    self.barLayout:addClickEventListener(handler(self, self.uiClickCallback))
    -- 初始化界面
    self.loginLayout:setVisible(false)
    self.loadingBarWidth = self.loadingBar:getContentSize().width
    self.loadingBar:setPercent(0)
    self.barLab:setString("0%")
    self.tipsLab:setString("检测更新")

    -- 创建显示版本号的label
    self.versionLab = cc.Label:createWithSystemFont("", "", 16)
    self:addChild(self.versionLab, 3)
    self.versionLab:setPosition(0, display.height)
    self.versionLab:setAnchorPoint(0, 1)

    -- 记录上个点的时间和下载百分比以及总下载量, 用来计算网速
    self.recordTime = os.clock()
    self.recordPercent = 0
    self.totalDownloadSize = 1
    self.netSpeed = 0

    -- 判断网速为0的时间戳
    self.recordEventTime = os.clock()

    -- 加载背景音乐资源
    local musicBanks = {"music/Master Bank.strings.bank", "music/Master Bank.bank", "music/Login.bank"}
    for _, bankFile in ipairs(musicBanks) do
        getFMODAudioEngine():loadBank(bankFile)
    end
    
    if gHasInitGlobalData then
        self.tipsLab:setString("游戏载入中")
        self:setBarInfo(100)
        self:openEnterGameView()

    else
        ---[==[ 
        if device.platform == "android" then
            self.tipsLab:setString("初始化游戏配置")
            self:openEnterGameView()
        else
        --]==]
            self.updateState = updateType.null
            self:checkUpdate()
        end
    end

    if not self.schedulerHandler then
        self.schedulerHandler = scheduler.scheduleGlobal(handler(self, self.update), 1)
    end

    -- 开启调用onExit()
    self:setNodeEventEnabled(true)
end

function UpdateScene:onEnter()
    httpAnchor(1001)
    -- 播放声音
    getFMODAudioEngine():playMusic("event:/Music/newlogin")
end

function UpdateScene:onExit()
    if self.updateOverViewHelper then
        self.updateOverViewHelper:close()
    end

    if self.am then
        self.am:release()
        self.am = nil
    end

    if self.schedulerHandler then
        scheduler.unscheduleGlobal(self.schedulerHandler)
        self.schedulerHandler = nil
    end
end

-- 开始热更新流程
function UpdateScene:checkUpdate()
    self.am = cc.AssetsManagerEx:create(manifestPath, storagePath)
    self.am:retain()
    self:reShowVersion()

    if not self.am:getLocalManifest():isLoaded() then
        self.tipsLab:setString("Fail to update assets, step skipped.")
        self.updateState = updateType.updateSkip
        self:openEnterGameView()

    else
        self.listener = cc.EventListenerAssetsManagerEx:create(self.am, handler(self, self.onUpdateEvent))
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.listener, 1)
        self.updateState = updateType.checkUpdate
        self.am:checkUpdate()
    end
end

function UpdateScene:onUpdateEvent(event)
    self.recordEventTime = os.clock()

    if self.updateState == updateType.updateFinish or 
        self.updateState == updateType.gameInit or
        self.updateState == updateType.enterSDK then
        return
    end

    local eventCode = event:getEventCode()
    local assetId = event:getAssetId()
    local percent = event:getPercent()
    local percentFile = event:getPercentByFile()
    local eventName = event:getEventName()
    local eventMsg = event:getMessage()
    print("eventCode", eventCode)
    print("assetId", assetId)
    print("percent", percent)
    print("percentFile", percentFile)
    print("eventName", eventName)
    print("eventMsg", eventMsg)    
    print("========================================")

    self:setBarInfo(percent)
    if eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
        if self.updateState == updateType.updateFileFail or self.updateState == updateType.updateSizeOut or 
            self.updateState == updateType.updateManifestFail then
            if self.dialogCsb then
                self.dialogCsb:setVisible(false)
            end
        end

        -- 计算网速
        local netSpeed = self.netSpeed
        local time = os.clock()
        if self.recordTime >= time or self.recordPercent >= percent then
            self.recordTime = time
            self.recordPercent = percent
        elseif time - self.recordTime > 1.0 then
            self.netSpeed = self.totalDownloadSize * (percent - self.recordPercent)*0.01 / (time - self.recordTime)
            self.recordTime = time
            self.recordPercent = percent
        end

        if assetId == cc.AssetsManagerExStatic.VERSION_ID then
            self:setBarInfo(0)
            self.tipsLab:setString(string.format("Version file: %0.1f%%", percent))
        elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
            self:setBarInfo(0)
            self.tipsLab:setString(string.format("Manifest file: %0.1f%%", percent))
        else
            self.tipsLab:setString("开始更新: " .. string.format("%0.1f kb/s", self.netSpeed))
        end

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
        if self.updateState == updateType.updateFile then
            return
        end
        self:setBarInfo(0)
        self.tipsLab:setString("发现新版本 " .. assetId)

        -- 获取更新信息
        self.updateInfo = updateHelper.getUpdateInfo(storagePath .. "/" .. tempManifestPath, manifestPath)
        dump(self.updateInfo, "更新信息")
        
        if self.updateInfo.isBigVersion then
            self:popBigVersionDialog()

        else
            self.totalDownloadSize = self.updateInfo.size
            if self.totalDownloadSize >= 1024 and self.updateInfo.isWifi == false then
                self:popUpdateSizeDialog()
            else
                self.recordTime = os.clock()
                self.recordPercent = 0
                -- AssetsManagerEx发完事件后面还有一小段代码, 如果调用了self.am:update() 刚好可以让那段代码顺利执行(坑)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(0), cc.CallFunc:create(function()
                    self.updateState = updateType.updateFile
                    self.am:update()
                end)))
            end
        end        
        httpAnchor(1002)

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
        self.updateState = updateType.updateFinish
        self.tipsLab:setString("已是最新版, 正在载入游戏配置...")

        -- 获取更新信息
        self.updateInfo = updateHelper.getUpdateInfo(storagePath .. "/" .. tempManifestPath, manifestPath)
        dump(self.updateInfo, "更新信息")

        self:reShowVersion()
        self:openEnterGameView()

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED then
        self.tipsLab:setString("正在解压文件...")

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
        self.updateState = updateType.updateFinish
        self.tipsLab:setString("更新完成, 正在载入游戏配置...")
        self:reShowVersion()
        httpAnchor(1004)
        self:openEnterGameView()

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
        self.tipsLab:setString("更新失败,本地目录文件缺失, 请尝试重启游戏或重新下载游戏包\n" .. event:getMessage())
        httpAnchor(1003, eventCode)

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
        self.tipsLab:setString("获取更新目录失败, 请尝试连接网络后重启游戏")
        self:popRetryDialog1()
        httpAnchor(1003, eventCode)

    elseif  eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
        self.tipsLab:setString("更新失败,解析更新目录文件失败, 请尝试重启游戏或重新下载游戏包\n" .. event:getMessage())
        httpAnchor(1003, eventCode)

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
        self.tipsLab:setString("更新资源 " .. assetId.. "失败\n" .. event:getMessage())
        httpAnchor(1003, eventCode)

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
        self.tipsLab:setString("文件更新失败 " .. event:getMessage())        
        self:popRetryDialog2()
        httpAnchor(1003, eventCode)

    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
        self.tipsLab:setString("文件解压失败, 请尝试重启游戏或重新下载游戏包\n" .. event:getMessage())
        httpAnchor(1003, eventCode)
    end
end

function UpdateScene:update(dt)
    local time = os.clock()
    if self.updateState == updateType.updateFile then
        -- 更新文件,4秒没有事件, 将网速显示为0 
        if time > self.recordEventTime + 4 then
            self.tipsLab:setString("开始更新: " .. string.format("%0.1f kb/s", 0))
        end
    end
end

function UpdateScene:setBarInfo(percent)
    self.barLayout:setVisible(true)
    self.loadingBar:setPercent(percent)
    self.barLab:setString(string.format("%0.1f%%", percent))
end

function UpdateScene:reShowVersion()
    if self.am then
        local loaclManifest = self.am:getLocalManifest()
        if loaclManifest then
            self.versionLab:setString("version: " .. loaclManifest:getVersion()) 
        end
    end
end

function UpdateScene:initGlobalData()
    gHasInitGlobalData = true

    -- 包含全局变量
    require("config")
    require("Helper")
    require("common.Protocol")
    require("common.CommonHelper")
    require("common.ConfigHelper")
    require("common.NetHelper")
    require("common.ModelHelper")
    require("common.IconHelper")
    require("common.MusicManager")
    require("common.AnimatePool")
    require("common.BattleHelper")
    require("common.TeamHelper")
    require("common.UserDatas")
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

    --require("common.UIManager")
    --require("common.SceneManager")

    EventManager = require("common.EventManager").new()
    KeyBoardListener = require("game.comm.KeyBoardListener").new()

    if table.unpack == nil then
        table.unpack = unpack
    end

    UIManager.init()
    SceneManager.init()
    GlobalListen.init()
    MusicManager.init()
end

-- 显示登陆界面
function UpdateScene:openEnterGameView()
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
        if self.updateState == updateType.gameInit or 
            self.updateState == updateType.enterSDK then
            return
        end

        if not self.updateInfo then
            -- 获取更新信息
            self.updateInfo = updateHelper.getUpdateInfo(storagePath .. "/" .. tempManifestPath, manifestPath) or {}
            dump(self.updateInfo, "更新信息")
        end

        if not gHasInitGlobalData then
            self.updateState = updateType.gameInit
            initConfig()
            self:initGlobalData()
        end
        self.barLayout:setTouchEnabled(false)
        self.updateState = updateType.enterSDK
        self.updateOverViewHelper = require("app.scenes.UpdateOverViewHelper").new(self.loginCsb, self.updateInfo.maintain)
    end)))
end

-- 添加dialog, 给重试和提示是否更新使用
function UpdateScene:addOnlyDialog(descStr)
    if gIsBackground then
        self:dialogCancelCallBack()
        return
    end

    if not self.dialogCsb then
        -- 创建重试更新提示框
        self.dialogCsb = cc.CSLoader:createNode("ui_new/g_gamehall/g_gpub/TipPanel.csb")
        self:addChild(self.dialogCsb, 2)
        -- csb动画
        self.dialogCsbAct = cc.CSLoader:createTimeline("ui_new/g_gamehall/g_gpub/TipPanel.csb")
        self.dialogCsb:runAction(self.dialogCsbAct)
        -- 自适应分辨率
        self.dialogCsb:setContentSize(display.width, display.height)
        ccui.Helper:doLayout(self.dialogCsb)

        local titleLab = getChildByPath(self.dialogCsb, "BuyEnergyPanel/BarNameLabel")        
        local confirmBtn = getChildByPath(self.dialogCsb, "BuyEnergyPanel/ConfrimButton")
        local cancelBtn = getChildByPath(self.dialogCsb, "BuyEnergyPanel/CancelButton")
        local confirmLab = getChildByPath(confirmBtn, "Text")
        local cancelLab = getChildByPath(cancelBtn, "Text")    

        self.dialogDescLab = getChildByPath(self.dialogCsb, "BuyEnergyPanel/TipLabel1")    

        titleLab:setString("提示")
        confirmLab:setString("确定")
        cancelLab:setString("取消")

        confirmBtn:addClickEventListener(handler(self, self.dialogConfirmCallBack))
        cancelBtn:addClickEventListener(handler(self, self.dialogCancelCallBack))
    end
    self.dialogDescLab:setString(descStr or "")
    self.dialogCsb:setVisible(true)
    self.dialogCsbAct:play("Open", false)
end

-- 弹出是否重试更新(manifest)
function UpdateScene:popRetryDialog1()
    self.updateState = updateType.updateManifestFail
    self:addOnlyDialog("更新失败, 是否重试")
end

-- 弹出是否重试更新(file)
function UpdateScene:popRetryDialog2()
    self.updateState = updateType.updateFileFail
    self:addOnlyDialog("更新失败, 是否重试")
end

-- 弹出是否开始更新提示
function UpdateScene:popUpdateSizeDialog()
    self.updateState = updateType.updateSizeOut
    self:addOnlyDialog(string.format("是否立即更新 %dkb 的更新包", math.ceil(self.totalDownloadSize)))
end

function UpdateScene:popBigVersionDialog()
    -- 提前初始化sdk
    updateHelper.getChannelId()

    self.updateState = updateType.updateBigVersion
    self:addOnlyDialog("发现大版本更新, 需要进入应用商店下载更新")
end

function UpdateScene:dialogConfirmCallBack()
    if (not gIsBackground) and self.dialogCsb and self.dialogCsbAct then
        self.dialogCsbAct:pause()
        self.dialogCsbAct:clearFrameEventCallFunc()
        self.dialogCsbAct:play("Close", false)
        self.dialogCsbAct:setFrameEventCallFunc(function()
            if self.updateState ~= updateType.updateSizeOut and self.updateState ~= updateType.updateFileFail and
                self.updateState ~= updateType.updateManifestFail then
                self.dialogCsb:setVisible(false)
            end
        end)
    end

    if self.updateState == updateType.updateFileFail then
        self.updateState = updateType.updateFile
        self.tipsLab:setString("正在为您重试...")
        self.am:downloadFailedAssets()

    elseif self.updateState == updateType.updateManifestFail then
        self.updateState = updateType.checkUpdate
        self.tipsLab:setString("正在为您重试...")
        self.am:checkUpdate()

    elseif self.updateState == updateType.updateSizeOut then
        self.updateState = updateType.updateFile
        self.recordTime = os.clock()
        self.recordPercent = 0
        self.tipsLab:setString("开始更新中...")
        self.am:update()

    elseif self.updateState == updateType.updateBigVersion then
        self.updateState = updateType.enterMark

        if device.platform ~= "android" and device.platform ~= "ios" then
            self.tipsLab:setString("windows系统不支持商店跳转")
            return
        end

        local isSucess = updateHelper.gotoMark()

        if isSucess then
            self.tipsLab:setString("打开应用商店成功, 您可以进入商店内更新游戏, 点击再次激活")
        else
            self.tipsLab:setString("打开应用商店失败, 您可以手动进入应用商店进行更新应用")
        end
    end
end

function UpdateScene:dialogCancelCallBack()
    if (not gIsBackground) and self.dialogCsb and self.dialogCsbAct then
        self.dialogCsbAct:pause()
        self.dialogCsbAct:clearFrameEventCallFunc()
        self.dialogCsbAct:play("Close", false)
        self.dialogCsbAct:setFrameEventCallFunc(function()
            if self.updateState ~= updateType.updateSizeOut and self.updateState ~= updateType.updateFileFail then
                self.dialogCsb:setVisible(false)
            end
        end)
    end

    if self.updateState == updateType.updateFileFail then
        self.updateState = updateType.cancelFileFail
        self.tipsLab:setString("更新失败, 点击再次激活")

    elseif self.updateState == updateType.updateManifestFail then
        self.updateState = updateType.cancelManifestFail
        self.tipsLab:setString("更新失败, 点击再次激活")

    elseif self.updateState == updateType.updateSizeOut then
        self.updateState = updateType.cancelSizeOut
        self.tipsLab:setString("已经取消更新, 点击再次激活")

    elseif self.updateState == updateType.updateBigVersion or
        self.updateState == updateType.enterMark then
        self.updateState = updateType.cancelBigVersion
        self.tipsLab:setString("您也可以手动进入应用商店进行更新应用, 点击再次激活")
    end
end

function UpdateScene:uiClickCallback(obj)
    if self.updateState == updateType.cancelFileFail then
        self:popRetryDialog2()

    elseif self.updateState == updateType.cancelManifestFail then
        self:popRetryDialog1()

    elseif self.updateState == updateType.cancelSizeOut then
        self:popUpdateSizeDialog()

    elseif self.updateState == updateType.cancelBigVersion then
        self:popBigVersionDialog()
    
    elseif self.updateState == updateType.enterMark then
        self:popBigVersionDialog()
    end
end

return UpdateScene