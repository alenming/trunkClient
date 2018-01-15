--[[
    ResLoader用于异步加载资源，基于C++的ResManager
    1.传入要加载的资源（包括不释放的资源），准备预加载
    2.开启预加载，先cache要加载的资源，保证不被误删，再根据isCleanup决定是否进行一次清除
        如果执行清除，同时对引擎的缓存进行清理，最后开始异步加载
    3.可设置加载完成，以及进度更新的回调

    2015-10-30 by 宝爷
]]

ResLoader = {}

-- 预加载资源列表（集合） key为资源名，value为true or string or table
-- value为string表示该资源包含了辅助资源（需要同时指定多个文件方可加载）：如Spine的json+atlas
-- value为true则调用getResManager:addPreloadRes 将key传入
-- value为string则调用getResManager:addPreloadRes 将key、value一同传入
-- value为"Armature" string则调用getResManager:addPreloadArmature 将key传入
-- value为table表示该资源包含了复杂的辅助资源（暂无此类资源）
ResLoader.Res = {}
-- 加载进度回调, 参数为：
-- 资源总量、当前加载量、当前加载的资源名、是否成功
ResLoader.LoadingCallback = nil
-- 加载结束回调, 无参数
ResLoader.LoadFinishCallback = nil
-- 预加载的总量
ResLoader.AllCount = 0
-- 当前加载完成的量
ResLoader.CurrentCount = 0

-- 传入资源或资源列表
function ResLoader.addPreloadRes(ress)
    -- 合并到ResLoader.Res中
    if type(ress) == "table" then
    	for k,v in pairs(ress) do
    		ResLoader.Res[k] = v
    	end
   	elseif type(ress) == "string" then
   		ResLoader.Res[ress] = true
    end
end

function ResLoader.startLoadResAsyn()
	ResLoader.AllCount = 0
	ResLoader.CurrentCount = 0
	for k,v in pairs(ResLoader.Res) do
		if v == true then
			if getResManager():addPreloadRes(k, ResLoader.onLoading) then
				ResLoader.AllCount = ResLoader.AllCount + 1
			end
		elseif v == "Armature" then
			if getResManager():addPreloadArmature(k, ResLoader.onLoading) then
				ResLoader.AllCount = ResLoader.AllCount + 1
			end
		elseif type(v) == "string" then
			if getResManager():addPreloadRes(k, v, ResLoader.onLoading) then
				ResLoader.AllCount = ResLoader.AllCount + 1
			end
		else
			print("Res Type is error !!!", v)
		end
	end
    
    print("Resloader allcount is " .. ResLoader.AllCount)
	if ResLoader.AllCount < 1 then
		ResLoader.onFinish()
		return true
	end

	getResManager():setFinishCallback(ResLoader.onFinish)
	getResManager():startResAsyn()

    -- 最后执行清空
    ResLoader.Res = {}
    return true
end

function ResLoader.onLoading(resName, success)
	if not success then
		print(resName .. " Load Failed")
	end
	ResLoader.CurrentCount = ResLoader.CurrentCount + 1
	if type(ResLoader.LoadingCallback) == "function" then
		ResLoader.LoadingCallback(ResLoader.CurrentCount, ResLoader.AllCount, resName, success)
	end
end

function ResLoader.onFinish()
    print("ResLoader.onFinish()")
    getResManager():setFinishCallback(nil)
	if type(ResLoader.LoadFinishCallback) == "function" then
		ResLoader.LoadFinishCallback()
        ResLoader.LoadFinishCallback = nil
        ResLoader.LoadingCallback = nil
	end
end

return ResLoader