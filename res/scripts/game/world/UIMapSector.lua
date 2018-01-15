------------------------------
-- 名称：UIMapSector
-- 描述：世界地图界面的章节地图扇区
-- 日期：2017/2/23
-- 作者：尚志
------------------------------

local UIMapSector = class("UIMapSector", function () 
	return require("common.UIView").new()
end)

--获取关卡类型
local function getStageType(stageID)
    if stageID % 2 == 1 then
        return "StageOnece"
    else
        return "StageElite"
    end
end

local function resPath(str)
    for _, v in pairs(ResConfig.UIMap.Csb2) do
        if string.find(v, str) then
            return v
        end
    end
end

function UIMapSector:updateChapter(chapterId)
	if not chapterId or chapterId <= 0 then return end

	if chapterId ~= self.chapterId then
		self.chapterId = chapterId
	    self.rootPath = "ui_new/w_worldmap/map/Map_" .. chapterId .. ".csb"
	    getResManager():addPreloadRes(self.rootPath, function(_, success)
	        if success then
	            local mapNode = getResManager():cloneCsbNode(self.rootPath)
	            mapNode:setContentSize(display.width, display.height)
	            ccui.Helper:doLayout(mapNode)

	            if self.root then
	            	self.root:removeFromParent(true)
	            end
	            self:addChild(mapNode)
	            self.root = mapNode

	            self:initNodes()
	            self:addClickListener()

	            self:updateStages()
                if StageHelper.getCurrentChapter(StageHelper.getChapterType(chapterId)) < chapterId then
                    self:addMapLock()
                end
	        end
	    end)
	    getResManager():startResAsyn()
	else
		self:updateStages()
	end
end

function UIMapSector:initNodes()
	self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
	self.commonPanel = CsbTools.getChildFromPath(self.mainPanel, "Common")
end

function UIMapSector:addClickListener()
	for _, child in pairs(self.commonPanel:getChildren()) do
		local stageID = tonumber(child:getName())
		child:addClickEventListener(function()
            self:challenge(stageID)
        end)
        local tp = getStageType(stageID)
        local board = CsbTools.getChildFromPath(child, tp .."/StageInfoBar/StageImage")
        if board then
            board:setTouchEnabled(true)
            board:addClickEventListener(function()
                if child == nil or type(child._curWarpClickCallbackEx) ~= "function" then
                    self:challenge(stageID)
                else
                    child._curWarpClickCallbackEx()
                end
            end)
        end
	end
end

-- 选择挑战
function UIMapSector:challenge(stageID)
	if self.chapterId ~= StageHelper.getChapterByStage(stageID) then
        return
    end

    local s = StageHelper.getStageState(self.chapterId, stageID)
    if s <= StageHelper.StageState.SS_LOCK then
        return
    elseif s > StageHelper.StageState.SS_UNLOCK then
        if (stageID % 100) % 3 ~= 0 then
            return
        end
    end
    UIManager.open(UIManager.UI.UIChallenge, self.chapterId, stageID)
end

-- 更新关卡
function UIMapSector:updateStages()
    local conf = getChapterConfItem(self.chapterId)
    if nil == conf then
        return
    end

    --显示公告板
    local function showBoard(node, id, star)
        local board = CsbTools.getChildFromPath(node, "StageInfoBar")
        if board then
            local s = conf.Stages[id]
            if nil == s then
                return
            end
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(s.Thumbnail)
            getChild(board, "StageImage"):loadTexture(frame and s.Thumbnail or "", 1)
            getChild(board, "Image_Bar"):loadTexture("stagemap_bar.png", 1)
            getChild(board, "StageNameLabel"):setString(getStageLanConfItem(s.Name))
            CommonHelper.playCsbAnimate(board, ResConfig.UIMap.Csb2.board, star, false)
        end
    end

    self.root:stopAllActions()
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "Onece", true)

    -- 刷新关卡显示
    for _, child in pairs(self.commonPanel:getChildren()) do
        child:setVisible(true)
        local stageID = tonumber(child:getName()) 
        local tp = getStageType(stageID)
        local spot = CsbTools.getChildFromPath(child, tp)
        spot:stopAllActions()
        local s = StageHelper.getStageState(self.chapterId, stageID)
        if s == StageHelper.StageState.SS_HIDE then
            child:setVisible(false)
        elseif s == StageHelper.StageState.SS_LOCK then
            CommonHelper.playCsbAnimate(spot, resPath(tp), "Lock", false)
        elseif s == StageHelper.StageState.SS_UNLOCK then
            CommonHelper.playCsbAnimate(spot, resPath(tp), "On", true)
            showBoard(spot, stageID, "Star0")
        elseif s == StageHelper.StageState.SS_ONE or s == StageHelper.StageState.SS_TWO or s == StageHelper.StageState.SS_TRI then
            CommonHelper.playCsbAnimate(spot, resPath(tp), "Over", false)
            if s == StageHelper.StageState.SS_ONE then
                showBoard(spot, stageID, "Star1")
            elseif s == StageHelper.StageState.SS_TWO then
                showBoard(spot, stageID, "Star2")
            elseif s == StageHelper.StageState.SS_TRI then
                showBoard(spot, stageID, "Star3")
            end
        end         
    end
end

-- 添加地图未解锁界面
function UIMapSector:addMapLock()
    if not self.mapLock then
        self.mapLock = require("game.world.UIMapLock").new()
        self.root:addChild(self.mapLock)
    end
end

function UIMapSector:setMapLockChestButtonVisible(visible)
    if self.mapLock then
        self.mapLock:setChestButtonVisible(visible)
    end
end

return UIMapSector