--[[
	SceneManager用于管理【召唤师联盟】场景
	

	2015-11-01 by 宝爷
]]
local ResConfig = require("common.ResConfig")
local UIManager = require("common.UIManager")
local ResLoader = require("common.ResLoader")
local scheduler = require("framework.scheduler")
--require("scenes.SceneTest")

SceneManager = SceneManager or {}

SceneManager.CurScene = nil
SceneManager.PrevScene = nil
SceneManager.ChangeSceneDelegate = nil

function SceneManager.init()
	-- 建立一个SceneName的Map
	SceneManager.SceneName = {}
	for k,v in pairs(SceneManager.Scene) do
		SceneManager.SceneName[v] = k
	end
end

-- 切换场景（不带资源加载和清理）
function SceneManager.changeScene(sceneId, ...)
	SceneManager.PrevScene = SceneManager.CurScene
	SceneManager.CurScene = sceneId
	print("SceneManager.changeScene " .. SceneManager.CurScene .. " prev " .. (SceneManager.PrevScene or "nil"))

	if sceneId == SceneManager.Scene.SceneBattle then
		-- 切换C++场景
		enterBattleScene()
    elseif sceneId == SceneManager.Scene.SceneReplayBattle then
        enterReplayBattleScene()
	else
		-- 切换Lua场景
		app:enterScene(SceneManager.SceneName[sceneId], ...)
	end
end

-- 将正常资源 如Csb2 = {main = "..."} 或 Tex = {"..."} 添加到目标table里面
function SceneManager.addResToFormat(sourResType, sourRes, destRes)
	if destRes[sourResType] then
		if sourResType == "Spine" then
			for resName, resPath in pairs(sourRes) do
				destRes[sourResType][resName] = resPath
			end
		else
			for resName, resPath in pairs(sourRes) do
				destRes[sourResType][resPath] = resName
			end
		end
	else
		print("sourRes is not format res", sourResType)
	end
end

-- 将UI = {}资源转换成规范格式
function SceneManager.formatUIRes(sourRes, destRes)
	for _, uiName in pairs(sourRes) do
		local uiRes = ResConfig[uiName]
		SceneManager.formatAllRes(uiRes, destRes)
	end
end

-- 将Func = {}资源转换成规范格式
function SceneManager.formatFuncRes(sourRes, destRes)
	for _, funName  in pairs(sourRes) do
		print("formatFuncRes " .. funName)
		local fun = ResConfig[funName]
		if type(fun) == "function" then
			local uiRes = fun()			
			print("uiRes"..type(uiRes))
			SceneManager.formatAllRes(uiRes, destRes)
			print("uiRes"..type(uiRes).."finish")			
		end
	end
end

-- 将所有不同种类资源转换成规范格式
function SceneManager.formatAllRes(sourRes, destRes)
	for resType, values in pairs(sourRes) do
		if resType == "UI" then
			SceneManager.formatUIRes(values, destRes)
		elseif resType == "Func" then
			SceneManager.formatFuncRes(values, destRes)
		else
			SceneManager.addResToFormat(resType, values, destRes)
		end
	end
end

function SceneManager.getFormatRes(sourRes)
	destRes = {
		Csb2 = {},
		Tex = {},
		Spine = {},
		Armature = {},
		Music = {},
		Cache = {}
	}

	SceneManager.formatAllRes(sourRes, destRes)

	return destRes
end

local function cacheFormatRes(formatRes)
	for uiType, paths in pairs(formatRes) do
		if uiType == "Cache" then
			for resType, _ in pairs(paths) do
				getResManager():cacheResInt(resType)
				print("===========Cache Cache", resType)
			end			
		elseif uiType == "Spine" then
			for name, path in pairs(paths) do
				getResManager():cacheResStr(name)
				print("============Cache Spine", name, path)
            end
		else
			for path, _ in pairs(paths) do
				getResManager():cacheResStr(path)
				print("============Cache Other", path)
            end
		end		
	end
end

local function addFormatCsb2(res)
	if type(res) == "table" then
		for path, name in pairs(res) do
			print("==========addCsb2", path)
			ResLoader.addPreloadRes(path)
		end
	end
end

local function addFormatTex(res)
	if type(res) == "table" then
		for path, name in pairs(res) do
			print("==========addTex", path)
			ResLoader.addPreloadRes(path)
		end
	end
end

local function addFormatSpine(res)
	if type(res) == "table" then
		for name, path in pairs(res) do
			print("==========addSpine", name, path)
			ResLoader.addPreloadRes({[name] = path})
		end
	end
end

local function addFormatArmature(res)
	if type(res) == "table" then
		for path, name in pairs(res) do
			print("==========addArmature", path)
			ResLoader.addPreloadRes({[path] = "Armature"})			
		end
	end
end

local function addFormatMusic(res)
	if type(res) == "table" then
		for path, name in pairs(res) do
			print("==========addMusic", path)
			ResLoader.addPreloadRes(path)
		end
	end
end

local function addFormatedRes(res)
	addFormatCsb2(res.Csb2)
	addFormatTex(res.Tex)
	addFormatSpine(res.Spine)
	addFormatArmature(res.Armature)
	addFormatMusic(res.Music)
end

function SceneManager.addAllPreloadRes(sceneId)
    -- 对当前场景需要缓存的资源进行Cache
	local cacheCache = SceneManager.getFormatRes(ResConfig.Cache)
	cacheFormatRes(cacheCache)
	
	local commonRes = SceneManager.getFormatRes(ResConfig.Common)
	cacheFormatRes(commonRes)
	
	ResConfig.Cache = {}

	-- 对下个场景需要加载的资源进行Cache
	local res = SceneManager.getFormatRes(ResConfig[SceneManager.SceneName[sceneId]])
	cacheFormatRes(res)

	-- 创建加载器
	addFormatCsb2(res.Csb2)
	addFormatTex(res.Tex)
	addFormatSpine(res.Spine)
	addFormatArmature(res.Armature)
	addFormatMusic(res.Music)
end

function SceneManager.loadScene(sceneId, ...)
	print("SceneManager.loadScene" .. sceneId)

    local scheduleHandle = nil
    local startLoad = function(dt)
        if scheduleHandle then
            scheduler.unscheduleGlobal(scheduleHandle)
        end

        if sceneId ~= SceneManager.Scene.SceneBattle
          and sceneId ~= SceneManager.Scene.SceneReplayBattle
          and UIManager.hasSave() then
            -- 如果从战斗场景回到了之前的场景
            local loadCount = #UIManager.UIStackCache
            ResConfig.Cache.UI = {}
            for i = 1, loadCount do
                ResConfig.Cache.UI[#ResConfig.Cache.UI + 1] = UIManager.UIName[UIManager.UIStackCache[i].UIID]
            end
        end

	    -- 对当前场景需要缓存的资源进行Cache
	    local cacheCache = SceneManager.getFormatRes(ResConfig.Cache)
	    cacheFormatRes(cacheCache)
	
	    local commonRes = SceneManager.getFormatRes(ResConfig.Common)
	    cacheFormatRes(commonRes)
	
	    ResConfig.Cache = {}

	    -- 对下个场景需要加载的资源进行Cache
	    local res = SceneManager.getFormatRes(ResConfig[SceneManager.SceneName[sceneId]])
	    cacheFormatRes(res)

	    -- 清理缓存
	    getResManager():clearRes()

	    -- 创建加载器
        addFormatedRes(cacheCache)
        addFormatedRes(commonRes)
        addFormatedRes(res)

        if type(SceneManager.ChangeSceneDelegate) == "function" then
            SceneManager.ChangeSceneDelegate()
        end
    	ResLoader.startLoadResAsyn()
    end

    -- 先关闭所有UI
	UIManager.closeAll()
	UIManager.clearCache()

    local params = {...}	
    -- 根据配置决定是否切换Loading场景
    -- 如果不切换Loading场景则在加载完成后切换场景
    -- 否则创建Loading场景，并切换到Loading场景，在Loading场景加载完资源后changeScene
    if SceneManager.SceneConfig[SceneManager.SceneName[sceneId]] ~= nil then
        if SceneManager.SceneConfig[SceneManager.SceneName[sceneId]].loadingView then
            -- 切换到loading场景
            local scene = "SceneLoadingLogin"
            if SceneManager.PrevScene then
                scene = "SceneLoadingGame"
            end

            scheduleHandle = scheduler.scheduleGlobal(startLoad, 0)
            app:enterScene(scene, {ResLoader, function ()
                -- 加载完成场景切换
                SceneManager.changeScene(sceneId, params)
            end})
        else
            httpAnchor(6001)
            startLoad()
            ResLoader.LoadFinishCallback = function ()
                httpAnchor(6003)
                -- 加载完成场景切换
                SceneManager.changeScene(sceneId, params)
            end
        end
    else
        print("change to a error scene " .. sceneId)
    end
end

function SceneManager.onlyLoad(sceneId, callFunc, ...)
	print("SceneManager.onlyLoad" .. sceneId)
	local scheduleHandle = nil
    local startLoad = function(dt)
		-- 对当前场景需要缓存的资源进行Cache
		local cacheCache = SceneManager.getFormatRes(ResConfig.Cache)
		cacheFormatRes(cacheCache)
		
		local commonRes = SceneManager.getFormatRes(ResConfig.Common)
		cacheFormatRes(commonRes)
		
		ResConfig.Cache = {}

		-- 对下个场景需要加载的资源进行Cache
		local res = SceneManager.getFormatRes(ResConfig[SceneManager.SceneName[sceneId]])
		cacheFormatRes(res)

	    -- 清理缓存
		getResManager():clearRes()

		-- 创建加载器
	    addFormatedRes(cacheCache)
	    
        -- 优化新手引导关资源加载
        -- 特殊处理, 加载公共资源的音乐
        addFormatMusic(commonRes.Music)
        if sceneId ~= SceneManager.Scene.SceneBattle 
          and sceneId ~= SceneManager.Scene.SceneReplayBattle then
            addFormatedRes(commonRes)
        end
	    addFormatedRes(res)
	    local resCount = UIManager.preloadUI(ResLoader.onLoading)

	    if type(SceneManager.ChangeSceneDelegate) == "function" then
	        SceneManager.ChangeSceneDelegate()
	    end
        
	    ResLoader.startLoadResAsyn()
        scheduler.unscheduleGlobal(scheduleHandle)
	end

    -- 先关闭所有UI
	UIManager.closeAll()
	UIManager.clearCache()

    local params = {...}	
    -- 根据配置决定是否切换Loading场景
    -- 如果不切换Loading场景则在加载完成后切换场景
    -- 否则创建Loading场景，并切换到Loading场景，在Loading场景加载完资源后changeScene
    if SceneManager.SceneConfig[SceneManager.SceneName[sceneId]] ~= nil then
        if SceneManager.SceneConfig[SceneManager.SceneName[sceneId]].loadingView then
        	ResLoader.LoadingCallback = function(allResCount, loadResCount, curResName, isSuccess)
                if not isSuccess then
                    httpAnchor(6002, curResName)
                end
        		if type(callFunc) == "function" then
        			callFunc(allResCount, loadResCount, curResName, isSuccess)
        		end
        	end
            httpAnchor(6001)
    		ResLoader.LoadFinishCallback = function()
                httpAnchor(6003)
        		SceneManager.changeScene(sceneId, params)
        	end
        end
    end

    scheduleHandle = scheduler.scheduleGlobal(startLoad, 0.05)
end

return SceneManager