--[[
	UIManager用于管理UI，依赖于C++导出的ResManager
	1.打开界面，根据配置自动加载界面、调用初始化、播放打开动画、适配分辨率、隐藏其他界面、屏蔽下方界面点击
	2.关闭界面，根据配置自动关闭界面、播放关闭动画、恢复其他界面
	3.切换界面，同打开界面，但是是将当前栈顶的界面进行切换，而不是压入一个新的
	4.界面Cache缓存
	5.Debug模式，自动重载

	-- 异步打开模式待开发

	2015-10-30 by 宝爷

    1.新增UI回调
    2.新增UI栈保存与恢复
    3.优化UICahce规则
    4.分离具体配置项

    2016-2-25 by 宝爷
]]
if UIManager ~= nil then
    return UIManager
end

UIManager = {}

-- UI table为UI界面列表，需要自行将需要使用UIManager管理的界面添加到此table中
-- key为界面的名字字符串，如UIShop，value为整数id。id不可以重复
-- 界面UI需要继承于UIView
UIManager.UI = {}

-- UIConf table 为每个界面的配置，key为界面的名字字符串，value为具体的配置table
-- 以下为一条示例配置
-- UIHall = { openAni = "Open", closeAni = "Close", cache = true, preventTouch = false, resolutionNode = "root", showType = "addition", quickClose = false},
-- showType 配置对应界面的显示类型，有以下3种类型
--      默认为single只显示当前栈顶界面 + 背景
--      addition 叠加模式，ui栈中所有界面顺序显示
--      fullScreen则只显示当前界面
-- openAni 配置对应csb打开动画名，如配置了该项会在打开该界面时自动播放该csb动画的Open动画
-- closeAni 配置对应csb关闭动画名，如配置了该项会在关闭该界面时自动播放该csb动画的Close动画
-- cache 配置为true时，界面会被缓存，且不会被重复创建，直到调用了clearCache
-- preventTouch 配置为true时，当前界面下方的界面不可点击，除非关闭当前界面
-- resolutionNode 配置为分辨率自适应节点字符串，self为自身，root为界面设定的root节点，其他字符串表示指定的子节点，为空时不考虑自适应
-- path 配置为界面脚本路径，当path为空时默认使用UIManager.Root
-- quickClose 点击空白处可以直接关闭界面
UIManager.UIConf = {}

-- Debug模式（开启则会自动重加载脚本）
UIManager.DebugModel = false --true

-- 背景UI（有若干层UI是作为背景UI，而不受切换等影响）
UIManager.BackGroundUI = 1
UIManager.Root = "ui/"

-- 是否保存了UI
UIManager.isSaveUI = false
-- 是否正在关闭UI
UIManager.isClosing = false
-- 是否正在打开UI
UIManager.isOpening = false
-- 是否正在重建UI
UIManager.isBuilding = false

-- UI界面缓存（key为uiid，value为uiview节点）
UIManager.UICache = {}
-- UI界面栈（{uiid + 界面节点对象 + 初始化参数}数组）
UIManager.UIStack = {}
-- UI界面栈缓存，用于场景切换后恢复界面
UIManager.UIStackCache = {}
-- UI待打开列表
UIManager.UIOpenQueue = {}

UIManager.uiOpenBeforeDelegate = nil
UIManager.uiOpenDelegate = nil
UIManager.uiCloseDelegate = nil

function UIManager.init()
    -- 建立一个UIName的Map
    UIManager.UIName = {}
    for k,v in pairs(UIManager.UI) do
        UIManager.UIName[v] = k
    end
end

-- 清理界面缓存
function UIManager.clearCache()
	for _,v in pairs(UIManager.UICache) do
		v:cleanup()
		v:release()
	end
	UIManager.UICache = {}
end

-- 根据界面模式刷新所有界面
-- 默认为single只显示当前栈顶界面 + 背景
-- addition则显示所有界面
-- fullScreen则只显示当前界面
local function updateUI(mode)
	-- 根据showType决定遍历
	local beginIndex = UIManager.BackGroundUI + 1
	local endIndex = #UIManager.UIStack - 1
	if mode == "addition" then
		-- 叠加模式不隐藏
		return
	elseif mode == "fullScreen" then
		-- 全屏模式全部隐藏
		beginIndex = 1
	end
	--print("beginIndex " .. beginIndex .. " endIndex " .. endIndex)
	if beginIndex > endIndex then
		return
	end

	for idx = beginIndex, endIndex do
		print("updateUI hide ui " .. idx)
        local view = UIManager.UIStack[idx].UIView
        if view then
            view:setVisible(false)
        end
	end
end

-- 播放动画
local function playAnimate(uiview, ani, fun)
	-- 获取uiView的csb根节点以及csb路径
	local csb = uiview:getRoot()
	local csbPath = uiview:getRootPath()
	if csb == nil or type(csbPath)~= "string" then
		if type(fun) == "function" then
			fun()
		end
		return
	end

	-- 执行播放动画的公共方法
	CommonHelper.playCsbAnimate(csb, csbPath, ani, false, fun)
end

-- 添加防触摸层
local function preventTouch()
    local layer = ccui.Layout:create()
    layer:setName("preventTouch")
    layer:setContentSize(display.width, display.height)
    layer:setTouchEnabled(true)
    layer:setSwallowTouches(true)
    display.getRunningScene():addChild(layer)
    return layer
end

-- 自适应分辨率
local function adaptResolution(uiNode, conf)
    if type(conf.resolutionNode) == "string" then
        local winSize = display.size
        if conf.resolutionNode == "self" then
            uiNode:setContentSize(winSize.width, winSize.height)
            ccui.Helper:doLayout(uiNode)
        elseif conf.resolutionNode == "root" and uiNode:getRoot() then
            local root = uiNode:getRoot()
            root:setContentSize(winSize.width, winSize.height)
            ccui.Helper:doLayout(root)          
        else
            local child = CommonHelper.getChild(uiNode, conf.resolutionNode)
            if child then
                print("do layout " .. conf.resolutionNode)
                child:setContentSize(winSize.width, winSize.height)
                ccui.Helper:doLayout(child)
            end
        end
    end
end

-- 打开UI，放入
local function openUI(ui, uiNode, conf, UIInfo, ...)
    if uiNode == nil then
        print("openUI uiid faile ".. ui)
        return
    end

	-- 存入界面栈信息结构
    UIInfo.UIView = uiNode
    uiNode:retain()

    if conf.quickClose then
        local uiBackground = CsbTools.getChildFromPath(uiNode:getRoot(), "Background")
        if uiBackground then
            uiBackground:setTouchEnabled(true)
            uiBackground:setSwallowTouches(true)
            uiBackground:addClickEventListener(function (obj)
                UIManager.close()
            end)
        else
            print("get Background is nil, uiId", ui)
        end
    end

    -- 添加到场景
	display.getRunningScene():addChild(uiNode)
	-- 分辨率适配
	adaptResolution(uiNode, conf)
    -- 刷新其他UI
    updateUI(conf.showType)

    local openCallback = function()
        uiNode:onOpenAniOver()            
        if type(UIManager.uiOpenDelegate) == "function" then
            UIManager.uiOpenDelegate(ui, fromUIID)
        end
    end

    -- 从哪个界面打开的
    local fromUIID = nil
    if #UIManager.UIStack > 1 then
        fromUIID = UIManager.UIStack[#UIManager.UIStack - 1].UIID
    end
    
    -- 打开界面之前回调
    if type(UIManager.uiOpenBeforeDelegate) == "function" then
        UIManager.uiOpenBeforeDelegate(ui, fromUIID)
    end
    print("execute uiNode:onOpen(fromUIID, ...)")
    -- 执行onOpen回调
    uiNode:onOpen(fromUIID, ...)
    -- 执行动画
	if type(conf.openAni) == "string" and not UIManager.isBuilding then
        print("playAnimate")
		playAnimate(uiNode, conf.openAni, openCallback)
    else
        print("openCallback")
        openCallback()
	end
end

-- 预备UI资源
local function prepareUIRes(uiId, conf, finishCallback, loadingCallback)
    local resCfg = ResConfig[UIManager.UIName[uiId]]
    if resCfg == nil then 
        print("resCfg == nil")
        if type(finishCallback) == "function" then
            finishCallback()
        end
        return nil
    end

    local loadRes = {}
    for k,v in pairs(resCfg) do
        if k == "Spine" then
            for resPath, atlasPath in pairs(v) do
                if not getResManager():hasRes(resPath)
                and getResManager():addPreloadRes(resPath, atlasPath, loadingCallback) then
                    loadRes[#loadRes + 1] = resPath
                end
            end
        elseif k == "Armature" then
            for resId, resPath in pairs(v) do
                if not getResManager():hasRes(resPath)
                and getResManager():addPreloadArmature(resPath, loadingCallback) then
                    loadRes[#loadRes + 1] = resPath
                end
            end
        else
            for resId, resPath in pairs(v) do
                if not getResManager():hasRes(resPath)
                and getResManager():addPreloadRes(resPath, loadingCallback) then
                    loadRes[#loadRes + 1] = resPath
                end
            end
        end
    end

    if type(finishCallback) == "function" then
        if #loadRes > 0 then
            getResManager():setFinishCallback(function() 
                getResManager():setFinishCallback(nil)
                finishCallback()
            end)
	        getResManager():startResAsyn()
        else
            print("#loadRes == 0")
            finishCallback()
            return nil
        end
    end
    return loadRes
end

local function getOrCreateUI(uiId, conf, ...)
    print("getOrCreateUI " .. uiId)
    -- 构造路径
    local uiPath = nil
    if type(conf.path) == "string" then
        print(conf.path)
        uiPath = conf.path .. UIManager.UIName[uiId] .. ".lua"
    else
        uiPath = UIManager.Root .. UIManager.UIName[uiId] .. ".lua"
    end

    local uiView = UIManager.UICache[uiId]
    if uiView == nil then
        if UIManager.DebugModel then
            package.loaded[uiPath] = nil
        end
        uiView = require(uiPath).new()
        -- 初始化UI
        uiView:init(...)
        uiView:setName(UIManager.UIName[uiId])
        if conf.cache then
           uiView:retain()
           UIManager.UICache[uiId] = uiView
        end
    end

    return uiView
end

-- 打开界面并添加到界面栈中
function UIManager.open(uiId, ...)
    if UIManager.isOpening or UIManager.isClosing then
        print("a UI is Opening or or UIManager.isClosing")
        -- 插入待打开队列
        UIManager.UIOpenQueue[#UIManager.UIOpenQueue + 1] = { 
            UIID = uiId,
            UIArgs = {...},
        }
        return
    end

    print("UIManager.open " .. uiId .. debug.traceback())
	local conf = UIManager.UIConf[UIManager.UIName[uiId]]
	if nil == conf then
		print("UIManager can't open UI " .. uiId)
		return
	end

    print("ui idx " .. UIManager.getUIIndex(uiId))
    if conf.cache and UIManager.getUIIndex(uiId) ~= -1 then
        -- 重复打开了同一个缓存界面, 直接返回到该界面
        UIManager.closeToUI(uiId, ...)
        return
    end

    -- 先构建界面栈
    local UIInfo = {
        UIID = uiId,
        UIArgs = { ... }
    }
    UIManager.UIStack[#UIManager.UIStack + 1] = UIInfo
    print("UIStack " .. #UIManager.UIStack .. " addChild " .. UIManager.UIName[uiId])

    -- 添加遮罩层, 在关闭时关闭该遮罩层
    if conf.preventTouch then
        UIInfo.preventNode = preventTouch()
        UIInfo.preventNode:retain()
    end

    -- 预加载资源，并在资源加载完成后自动打开界面
    local callback = function()
        print("open Callback " .. debug.traceback())
        if UIInfo.IsClose then
            print("ui has been closed " .. uiId)
            UIManager.isOpening = false
            return
        end
        local uiView = getOrCreateUI(uiId, conf, table.unpack(UIInfo.UIArgs))
	    -- 打开UI，执行配置
	    openUI(uiId, uiView, conf, UIInfo, table.unpack(UIInfo.UIArgs))
        UIManager.isOpening = false
        -- 自动打开下一个待打开的界面
        if #UIManager.UIOpenQueue > 0 then
            local UIQueueInfo = UIManager.UIOpenQueue[1]
            table.remove(UIManager.UIOpenQueue, 1)
            UIManager.open(UIQueueInfo.UIID, table.unpack(UIQueueInfo.UIArgs or {}))
        end
    end

    UIManager.isOpening = true
    UIInfo.ResToClear = prepareUIRes(uiId, conf, callback)
end

function UIManager.openQuiet(uiId, openCallback, ...)
    print("UIManager.openQuiet " .. uiId .. debug.traceback())
	local conf = UIManager.UIConf[UIManager.UIName[uiId]]
	if nil == conf then
		print("UIManager can't open UI " .. uiId)
		return
	end

    print("ui idx " .. UIManager.getUIIndex(uiId))
    if conf.cache and UIManager.getUIIndex(uiId) ~= -1 then
        -- 重复打开了同一个缓存界面
        return
    end

    -- 先构建界面栈
    local UIInfo = {
        UIID = uiId,
        UIArgs = { ... }
    }
    UIManager.UIStack[#UIManager.UIStack + 1] = UIInfo
    print("UIStack " .. #UIManager.UIStack .. " addChild " .. UIManager.UIName[uiId])

    -- 添加遮罩层, 在关闭时关闭该遮罩层
    if conf.preventTouch then
        UIInfo.preventNode = preventTouch()
        UIInfo.preventNode:retain()
    end

    if conf.quickClose then
        local uiBackground = CsbTools.getChildFromPath(uiNode:getRoot(), "Background")
        if uiBackground then
            uiBackground:setTouchEnabled(true)
            uiBackground:setSwallowTouches(true)
            uiBackground:addClickEventListener(function (obj)
                UIManager.close()
            end)
        else
            print("get Background is nil, uiId", ui)
        end
    end

    -- 预加载资源，并在资源加载完成后自动打开界面
    local callback = function()
        print("open Callback " .. debug.traceback())
        if UIInfo.IsClose then
            print("ui has been closed " .. uiId)
            return
        end
        local uiView = getOrCreateUI(uiId, conf, table.unpack(UIInfo.UIArgs))
	    -- 打开UI，执行配置
	    openUI(uiId, uiView, conf, UIInfo, table.unpack(UIInfo.UIArgs))
        if openCallback then
            openCallback()
        else 
            print("openCallback is nil")
        end
    end
    UIInfo.ResToClear = prepareUIRes(uiId, conf, callback)
end

-- 替换栈顶界面
function UIManager.replace(ui, ...)
	UIManager.close()
	UIManager.open(ui, ...)
end

-- 关闭当前界面
function UIManager.close()
	local uiCount = #UIManager.UIStack
	if uiCount < 1 or UIManager.isClosing or UIManager.isOpening then
		return
	end

	-- 关闭当前界面
    local uiInfo = UIManager.UIStack[uiCount]
    uiInfo.IsClose = true
    local uiId = uiInfo.UIID
    local uiView = uiInfo.UIView
    print("close ui " .. uiId .. " ui Name " .. UIManager.UIName[uiId])

	local conf = UIManager.UIConf[UIManager.UIName[uiId]]
    -- 回收遮罩层
    if uiInfo.preventNode ~= nil then
        uiInfo.preventNode:removeFromParent()
        uiInfo.preventNode:release()
        uiInfo.preventNode = nil
    end

    -- 如果当前的界面是全屏模式,将UI栈里面的显示
    if conf.showType == "fullScreen"
      or conf.showType == "single" then
        for idx = 1, uiCount - 1 do
            if UIManager.UIStack[idx].UIView then
                UIManager.UIStack[idx].UIView:setVisible(true)
            end
        end
    end

    -- 清除栈信息
	UIManager.UIStack[uiCount] = nil
    local preViewInfo = nil
    if uiCount - 1 >= 1 then
        preViewInfo = UIManager.UIStack[uiCount - 1]
    end
	print("UIStack " .. #UIManager.UIStack)

	local close = function() 
        UIManager.isClosing = false
	    -- 显示之前的界面
        if preViewInfo and preViewInfo.UIView and UIManager.isTopUI(preViewInfo.UIID) then
            -- 如果之前的界面弹到了最上方（中间有可能打开了其他界面）
		    preViewInfo.UIView:setVisible(true)
		    local prevConf = UIManager.UIConf[UIManager.UIName[preViewInfo.UIID]]
		    -- 刷新其他UI
		    updateUI(prevConf.showType)
            -- 回调onTop
            preViewInfo.UIView:onTop(uiId, uiView:onClose())
        else
            uiView:onClose()
        end

        if type(UIManager.uiCloseDelegate) == "function" then
            UIManager.uiCloseDelegate(uiId)
        end
        if conf.cache then
            uiView:removeFromParent(false)
        else
            uiView:removeFromParent(true)
        end
        -- 调试模式下自动清除UICache
		if UIManager.DebugModel then
            if conf.cache then
                uiView:cleanup()
                uiView:release()
	    		UIManager.UICache[uiId] = nil
            end
		end
		uiView:release()

        if uiInfo.ResToClear and not conf.cache then
            for k, resPath in ipairs(uiInfo.ResToClear) do
                getResManager():removeRes(resPath)
            end
            --cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
            cc.Director:getInstance():getTextureCache():removeUnusedTextures()
        end
        if #UIManager.UIOpenQueue > 0 then
            local UIQueueInfo = UIManager.UIOpenQueue[1]
            table.remove(UIManager.UIOpenQueue, 1)
            UIManager.open(UIQueueInfo.UIID, table.unpack(UIQueueInfo.UIArgs or {}))
        end
	end

    if uiView == nil then
        return
    end
    
    UIManager.isClosing = true

	if type(conf.closeAni) == "string" then
		-- 播放关闭动画
		playAnimate(uiView, conf.closeAni, close)
	else
		close()
	end
end

-- 关闭所有界面
function UIManager.closeAll()
	-- 不播放动画，也不清理缓存
    for k,v in ipairs(UIManager.UIStack) do
        print(" UIManager.closeAll() " .. k .. ", " .. v.UIID)
        local view = v.UIView
        v.IsClose = true
        if view then
            view:onClose()
            view:removeFromParent()
            view:release()
        end
        local preventNode = v.preventNode
        if preventNode ~= nil then
            preventNode:removeFromParent()
            preventNode:release()
        end
	end
    UIManager.UIOpenQueue = {}
    UIManager.isOpening = false
	UIManager.UIStack = {}
    UIManager.isClosing = false
end

-- 连续关闭N个界面，关闭到指定的uiId
function UIManager.closeToUI(uiId, ...)
    local idx = UIManager.getUIIndex(uiId)
    local preUIID = nil
    if idx == -1 then return end
    idx = idx - 1

    for i = #UIManager.UIStack, idx, -1 do
        local uiInfo = UIManager.UIStack[i] or {}
        uiInfo.IsClose = true
        local uiId = uiInfo.UIID
        local uiView = uiInfo.UIView
        local conf = UIManager.UIConf[UIManager.UIName[uiId]]

        if i == idx then
            if uiView then
                uiView:setVisible(true)
                -- 回调onTop
                uiView:onTop(preUIID, nil)
                -- 刷新其他UI
		        updateUI(conf.showType)
            end
        else
            preUIID = uiId     
            -- 回收遮罩层
            if uiInfo.preventNode ~= nil then
                uiInfo.preventNode:removeFromParent()
                uiInfo.preventNode:release()
                uiInfo.preventNode = nil
            end

            if type(UIManager.uiCloseDelegate) == "function" then
                UIManager.uiCloseDelegate(uiId)
            end

            if uiView then
                uiView:onClose()
                if conf.cache then
                    uiView:removeFromParent(false)
                else
                    uiView:removeFromParent(true)
                end
                -- 调试模式下自动清除UICache
		        if UIManager.DebugModel then
                    if conf.cache then
                        uiView:cleanup()
                        uiView:release()
	    		        UIManager.UICache[uiId] = nil
                    end
		        end
		        uiView:release()
            end

            if uiInfo.ResToClear and not conf.cache then
                for k, resPath in ipairs(uiInfo.ResToClear) do
                    getResManager():removeRes(resPath)
                end
                cc.Director:getInstance():getTextureCache():removeUnusedTextures()
            end
                
            -- 清除栈信息
	        UIManager.UIStack[i] = nil
        end
    end
    
    UIManager.UIOpenQueue = {}

    UIManager.open(uiId, ...)
end

function UIManager.isTopUI(uiId)
    if #UIManager.UIStack == 0 then
        return false
    end
    return UIManager.UIStack[#UIManager.UIStack].UIID == uiId
end

function UIManager.getUI(uiId)
    for k,v in ipairs(UIManager.UIStack) do
        if uiId == v.UIID then
            return v.UIView
        end
    end
    return nil
end

function UIManager.getUIIndex(uiId)
    for k,v in ipairs(UIManager.UIStack) do
        if uiId == v.UIID then
            return k
        end
    end
    return -1
end

-- 是否有UI存档
function UIManager.hasSave()
    return UIManager.isSaveUI
end

-- 保存当前UI栈从栈底到栈顶 - popCount的UI信息
function UIManager.saveUI(popCount)
    local count = #UIManager.UIStack - popCount
    if count < 1 then
        print("Save UI Faile, UIStack " .. #UIManager.UIStack .. " popCount " .. popCount)
        return
    end
    UIManager.UIStackCache = {}
    for i = 1, count do
        local info = UIManager.UIStack[i]
        UIManager.UIStackCache[i] = {
            UIID = info.UIID,
            UIArgs = info.UIArgs,
        }
    end
    UIManager.isSaveUI = true
end

function UIManager.popUI(popCount)
    popCount = popCount or 1
    if UIManager.UIStackCache then
        if popCount >= #UIManager.UIStackCache then
            popCount = #UIManager.UIStackCache
        end
        for i=1, popCount do
            table.remove(UIManager.UIStackCache, #UIManager.UIStackCache)
        end
    end
end

-- 保存当前UI栈从栈底到指定UI
function UIManager.saveToLastUI(uiId)
    -- 计算出到指定UI所需弹出的UI界面数量
    local count = #UIManager.UIStack
    local popCount = 0
    for i = count, 1, -1 do
        if UIManager.UIStack[i].UIID == uiId then
            popCount = count - i
            break
        end
    end

    UIManager.saveUI(popCount)
end

function UIManager.buildSaveUI(uiStackCache)
    UIManager.UIStackCache = uiStackCache
    UIManager.isSaveUI = true
end

-- 在保存的UI界面中追加一个界面到最顶部
-- 传入UI，打开类型，界面参数
function UIManager.pushSaveUI(uiId, openType, ...)
    local count = #UIManager.UIStackCache
    UIManager.UIStackCache[count + 1] = {
        UIID = uiId,
        UIArgs = {...},
        OpenType = openType
    }
    UIManager.isSaveUI = true
end

function UIManager.clearSaveUI()
    UIManager.UIStackCache = {}
    UIManager.isSaveUI = false
end

function UIManager.preloadUI(loadingCallback)
    if #UIManager.UIStackCache < 1 then
        return 0
    end
    local resCount = 0
    local loadCount = #UIManager.UIStackCache
    for i = 1, loadCount do
        local info = UIManager.UIStackCache[i]
        local resCache = prepareUIRes(
        info.UIID, UIManager.UIConf[UIManager.UIName[uiId]], nil, loadingCallback)
        if resCache then
            UIManager.UIStackCache[i].ResCache = resCache
            resCount = resCount + #resCache
        end
    end
    return resCount
end

function UIManager.loadUI()
    if #UIManager.UIStackCache < 1 then
        return
    end

    local loadCount = #UIManager.UIStackCache
    -- 先强制关闭所有UI
    UIManager.closeAll();
    
    -- 加载完资源后依次打开界面
    local callback = function ()
        for i = 1, loadCount do
            print("build ui " .. i)
            local info = UIManager.UIStackCache[i]
            UIManager.isBuilding = info.OpenType == nil
            local openCallback = UIManager.openQuiet
            if i == loadCount then
                openCallback = UIManager.open
            end
            if i == loadCount then                
                openCallback(info.UIID, table.unpack(info.UIArgs or {}))
            else            
                openCallback(info.UIID, nil, table.unpack(info.UIArgs or {}))
            end
            UIManager.UIStack[i].ResToClear = UIManager.UIStackCache[i].ResCache
        end
        UIManager.isBuilding = false
        UIManager.UIStackCache = {}
        UIManager.isSaveUI = false
    end
    callback()
end

return UIManager