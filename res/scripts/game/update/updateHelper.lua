--[[
热更新一些方法, 抽取出来:
	1. 检测是否大版本
	2. 跳转商店
	3. 提取更新大小
注意事项:
	热更新无效
]]

updateHelper = {}

local json = require("game.update.json")

-- 清空本地缓存
function updateHelper.autoClearCache(localManifestPath, cacheManifestPath, storagePath)
	local localManifestData = cc.FileUtils:getInstance():getStringFromFile(localManifestPath)
	local cacheManifestData = cc.FileUtils:getInstance():getStringFromFile(cacheManifestPath)
	storagePath = cc.FileUtils:getInstance():fullPathForFilename(storagePath)
	if localManifestData == "" or cacheManifestData == "" then
		dump(localManifestData, "本地Manifest")
		dump(cacheManifestData, "缓存Manifest")
		cc.FileUtils:getInstance():removeDirectory(storagePath .. "/")
		return
	end

	-- 将manifest转化为table
	local localManifestInfo = json.decode(localManifestData) or {}
	local cacheManifestInfo = json.decode(cacheManifestData) or {}

	local localBuildTime = tonumber(localManifestInfo.buildTime or 0) or 0
	local cacheBuildTime = tonumber(cacheManifestInfo.buildTime or -1) or 0
	if localBuildTime > cacheBuildTime then
		cc.FileUtils:getInstance():removeDirectory(storagePath .. "/")
	end
end

-- 获取当前更新的信息
-- {isBigVersion = false, size = 100, isWifi = false, maintain = {startTime = 0, endTime = 0, message = ""}}
function updateHelper.getUpdateInfo(newManifestPath, curManifestPath)
	local info = {isBigVersion = false, size = 1, isWifi = false}

	-- 获取manifest的路径
	local newManifestPath = cc.FileUtils:getInstance():getStringFromFile(newManifestPath)
	local curManifestPath = cc.FileUtils:getInstance():getStringFromFile(curManifestPath)
	if newManifestPath == "" or curManifestPath == "" then
		print("newManifestPath or curManifestPath is nil", newManifestPath, curManifestPath)
		return info
	end

	-- 将manifest转化为table
	local newManifestInfo = json.decode(newManifestPath) or {}
	local curManifestInfo = json.decode(curManifestPath) or {}
	--dump(newManifestInfo, "服务器Manifest")
	--dump(curManifestInfo, "本地Manifest")
	if newManifestInfo.version == nil or curManifestInfo.version == nil then
		print("newManifestPath.version or curManifestInfo.version is nil", 
			newManifestInfo.version, curManifestInfo.version)
		return info
	end

	-- 获取维护信息
	if newManifestInfo.maintain ~= nil then
		info.maintain = {}
		info.maintain.startTime = newManifestInfo.maintain.startTime or 0
		info.maintain.endTime = newManifestInfo.maintain.endTime or 0
		info.maintain.message = newManifestInfo.maintain.message or ""
	end

	-- 获取manifest的本地版本和最新版本
	local newVersion = string.split(newManifestInfo.version, ".")
	local curVersion = string.split(curManifestInfo.version, ".")
	if newVersion[1] == nil or curVersion[1] == nil then
		print("newVersion or curVersion is nil", newVersion, curVersion)
		return info
	end

	-- 判断是否是大版本更新, 是的话不用计算更新包大小
	if newVersion[1] > curVersion[1] then
		info.isBigVersion = true
		return info
	end

	if newManifestInfo.assets == nil then
		print("newManifestInfo.assets")
		return info
	end
	if curManifestInfo.assets == nil then
		curManifestInfo.assets = {}
	end

	-- 计算更新文件
	for assetID, assetInfo in pairs(newManifestInfo.assets) do
		print("assetID, assetInfo", assetID, assetInfo, assetInfo.size)
		if (curManifestInfo.assets[assetID]) then
			if(assetInfo.md5 ~= curManifestInfo.assets[assetID].md5) then
				info.size = info.size + (assetInfo.size or 0)/1024
			end
		else
			info.size = info.size + (assetInfo.size or 0)/1024
		end
	end

	-- 判断wifi
	if device.platform == "android" then
		local ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "isWifiConnected", 
            {}, "()Z")

        if ok and ret then
            info.isWifi = true
        end

	elseif device.platform == "ios" then
		local ok, ret = luaoc.callStaticMethod("LuaCallOC", "IsEnableWIFI")
    	if ok and ret then
            info.isWifi = true
        end
	end

	return info
end

-- 获取渠道ID
--[[
1. sdk不初始化不能获取渠道id
2. sdk初始化了, 有些会发送事件, 有些不发送
3. sdk初始化后可以立即获取渠道号
]]
function updateHelper.getChannelId()
	if device.platform ~= "android" and device.platform ~= "ios" then
		return -1
	end

	local SdkManager = require("common.sdkmanager.SdkManager")
	if not EventManager then
   		require("summonerComm.GameEvents")
    	EventManager = require("common.EventManager").new()
    	SdkManager.init()
    end

    return SdkManager.getChannelId()
end

-- 跳转到应用商店
function updateHelper.gotoMark()
	local isSucess = false
	require("game.update.markConf")
	local channelId = updateHelper.getChannelId()
	print("+++++++++++++++++++++ channelId ", channelId)
	if channelId == nil or markConf[channelId] == nil then
		return isSucess
	end

    if device.platform == "android" then
    	local ok, ret

    	if markConf[channelId].funcId == 1 then
    		ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "goToMarket", 
            	{markConf[channelId].markPackName}, "(Ljava/lang/String;)Z")

    	elseif markConf[channelId].funcId == 2 then
    		ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "goToMarketWithActivity", 
            	{markConf[channelId].markPackName, markConf[channelId].markActivity}, "(Ljava/lang/String;Ljava/lang/String;)Z")

    	elseif markConf[channelId].funcId == 3 then
    		ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "goToSamsungappsMarket", 
            	{}, "()Z")

    	elseif markConf[channelId].funcId == 4 then
    		ok, ret = luaj.callStaticMethod(gAndroidPackageNameSlash.."/AppActivity", "goToLeTVStoreDetail", 
            	{}, "()Z")
    	end

        if ok and ret then
            isSucess = true
        end

    elseif device.platform == "ios" then
    	local ok, ret = luaoc.callStaticMethod("LuaCallOC", "gotoAppstore", {address = markConf[channelId].markAddress})
    	if ok and ret then
            isSucess = true
        end
    end

    return isSucess
end

-- 创建维护公告
function updateHelper.sceneAddNotice(content)
	-- 后台不能创建csb
	if gIsBackground then
		return
	end

	local noticeCsb = cc.Director:getInstance():getRunningScene():getChildByName("GAME_MAINTAIN_NOTICE")
	if noticeCsb then
		noticeCsb:setVisible(true)
		return
	end	

	-- 创建热更新界面
    local noticeCsb = cc.CSLoader:createNode("ui_new/g_gamehall/g_gpub/NoticePanel_3.csb")
    cc.Director:getInstance():getRunningScene():addChild(noticeCsb, 1)
    noticeCsb:setName("GAME_MAINTAIN_NOTICE")
    -- csb动画
    local noticeCsbAct = cc.CSLoader:createTimeline("ui_new/l_login/LoadingBg.csb")
    noticeCsb:runAction(noticeCsbAct)
    -- 播放csb动画
    noticeCsbAct:play("Open", false)

    -- 自适应分辨率
    noticeCsb:setContentSize(display.width, display.height)
    ccui.Helper:doLayout(noticeCsb)

    local mainLayout = noticeCsb:getChildByName("MainPanel")
    local noticeLayout = mainLayout:getChildByName("NoticePanel")
    local scroll = noticeLayout:getChildByName("NoticeScrollView")
    local confirmBtn = noticeLayout:getChildByName("ConfirmButton")
    local descLab = scroll:getChildByName("Text")
	local fontName = descLab:getFontName()
	local fontSize = descLab:getFontSize()
	local fontColor = descLab:getTextColor()

	confirmBtn:addClickEventListener(function()
		noticeCsb:removeFromParent()
		--closeGame()
	end)

	scroll:removeAllChildren()
	local scrollSize = scroll:getContentSize()
	local offsetX = 5
	local offsetY = 5
	local labSize = cc.size(scrollSize.width - 2*offsetX, scrollSize.height - 2*offsetY)

	-- 富文本
	local RichLabel = require("richlabel.RichLabel")
	local descRichLab = RichLabel.new{
        fontName = "fonts/msyh.ttf",
        fontSize = fontSize,
        fontColor= fontColor,
        maxWidth = labSize.width,
        lineSpace= 1,
        charSpace= 0,
    }
    descRichLab:setAnchorPoint(cc.p(0,1))
    scroll:addChild(descRichLab)
    descRichLab:setString(content)

    local newDescSize = descRichLab:getSize()
	if scrollSize.height < newDescSize.height + 2*offsetY then
		scrollSize.height = newDescSize.height + 2*offsetY
	end
	descRichLab:setPosition(cc.p(offsetX, scrollSize.height - offsetY))

	scroll:setInnerContainerSize(scrollSize)

	--[[
	-- 非富文本
	local newDescLab = cc.Label:createWithTTF(
		content,
		fontName,
		fontSize)
	newDescLab:setTextColor(fontColor)
	newDescLab:setClipMarginEnabled(false)
	newDescLab:setAnchorPoint(cc.p(0,1))
	newDescLab:setMaxLineWidth(labSize.width)
	newDescLab:setVerticalAlignment(1)
	scroll:addChild(newDescLab)

	local newDescSize = newDescLab:getContentSize()
	local innerSize = scrollSize
	if innerSize.height < newDescSize.height + 2*offsetY then
		innerSize.height = newDescSize.height + 2*offsetY
	end
	newDescLab:setPosition(cc.p(offsetX, innerSize.height - offsetY))

	scroll:setInnerContainerSize(innerSize)
	]]
end

-- 删除维护公告
function updateHelper.sceneRemoveNotice()
	local noticeCsb = cc.Director:getInstance():getRunningScene():getChildByName("GAME_MAINTAIN_NOTICE")
	if noticeCsb then
		noticeCsb:removeFromParent()
	end	
end
