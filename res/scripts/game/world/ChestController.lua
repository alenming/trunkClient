------------------------------
-- 名称：ChestController
-- 描述：世界地图界面的宝箱层控制器
-- 日期：2017/2/23
-- 作者：尚志
------------------------------

local scheduler = require("framework.scheduler")

local ChestController = class("ChestController")

local LONG_CLICK_TIME = 0.2

function ChestController:ctor()

end

function ChestController:setTarget(target)
	self.target = target

	self.starNum = CsbTools.getChildFromPath(self.target, "StarNum")             -- 星星数
    self.starLoadingBar = CsbTools.getChildFromPath(self.target, "LoadingBar")   -- 星星进度条

	self.chests = {}
	for i = 1, 3 do
		local chest = CsbTools.getChildFromPath(self.target, "Chest"..i)
		self.chests[i] = chest

		self:addTouchListener(chest, i)

		local button = CsbTools.getChildFromPath(chest, "ChestButton")
        CsbTools.initButton(button, function () 
            self:sendChapterAwardCmd(i)
        end)
	end

	self:addNetworkListener()
end

function ChestController:setChapter(chapterId)
	self.chapterId = chapterId
	return self
end

function ChestController:addNetworkListener()
	local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.ChapterAwardSC)
    self.acceptChapterAwardCmdHandler = handler(self, self.acceptChapterAwardCmd)
    NetHelper.setResponeHandler(cmd, self.acceptChapterAwardCmdHandler)
end

function ChestController:removeNetworkListener()
	local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.ChapterAwardSC)
    NetHelper.removeResponeHandler(cmd, self.acceptChapterAwardCmdHandler)
end

-- 添加宝箱触摸监听
function ChestController:addTouchListener(chest, index)
	if not self.longClickChestHandler then
		self.longClickChestHandler = {}
	end

	local button = CsbTools.getChildFromPath(chest, "ChestButton")
	button:addTouchEventListener(function(_, event)
        if 0 == event then
            self.longClickChestHandler[index] = scheduler.scheduleGlobal(function()
                self:removeChestTouchListener(index)
                self:showChestInfo(index)
            end, LONG_CLICK_TIME)
        else
            self:removeChestTouchListener(index)
            self:closeChestInfo(index)
        end
    end)
end

-- 移除宝箱触摸监听
function ChestController:removeChestTouchListener(index)
    if self.longClickChestHandler then
        if self.longClickChestHandler[index] then
            scheduler.unscheduleGlobal(self.longClickChestHandler[index])
            self.longClickChestHandler[index] = nil
        end
    end
end

-- 弹出宝箱信息
function ChestController:showChestInfo(index)
    local chest = self.chests[index]

    local tipsPanel = CsbTools.getChildFromPath(chest, "TipPanel")
    tipsPanel:setVisible(true)

    local awardScrollView = CsbTools.getChildFromPath(tipsPanel, "AwardScrollView")
    awardScrollView:removeAllChildren()

    local boxData = getChapterBoxData(self.chapterId)
    local oneBox = boxData[index]
    local posX = 35
    for _, info in pairs(oneBox.StarAward) do
        local id = info.ID or 0
        local num = info.num or 0
        if id > 0 and num > 0 then
            local item = getResManager():cloneCsbNode(ResConfig.UIChapterAward.Csb2.awardItem)
            item:setPosition(posX, 40)
            item:setScale(0.8)
            item:setVisible(true)
            awardScrollView:addChild(item)

            local propConf = getPropConfItem(id)
            local touchPanel = getChild(item, "MainPanel")
            UIAwardHelper.setAllItemOfConf(item, propConf, num)

            posX = posX + touchPanel:getContentSize().width * 0.8
        end
    end
end

-- 关闭宝箱信息
function ChestController:closeChestInfo(index)
    local chest = self.chests[index]

    local tipsPanel = CsbTools.getChildFromPath(chest, "TipPanel")
    tipsPanel:setVisible(false)
end

-- 发送领取奖励请求
function ChestController:sendChapterAwardCmd(tag)
    local state = StageHelper.getChapterState(self.chapterId)
    if state == StageHelper.ChapterState.CS_REWARD then
        return
    end

    local buffData = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.ChapterAwardCS)
    bufferData:writeInt(self.chapterId)
    bufferData:writeChar(tag)
    NetHelper.request(buffData)

    self.mCurChestTag = tag
end

-- 接收领取奖励请求
function ChestController:acceptChapterAwardCmd(mainCmd, subCmd, buffData)
    local chapterID = buffData:readInt()
    local count = buffData:readInt()

    -- 显示奖励
    local awardData = {}
    local newPropInfo = {}
    for i = 1, count do
        newPropInfo.id = buffData:readInt()
        newPropInfo.num = buffData:readInt()
        UIAwardHelper.formatAwardData(awardData, "dropInfo", newPropInfo)
    end

    getGameModel():getStageModel():setChapterBoxState(chapterID, self.mCurChestTag)

    UIManager.open(UIManager.UI.UIAward, awardData)

    self:updateChests()
end

-- 更新宝箱
function ChestController:updateChests(chapterId)
	self.chapterId = chapterId or self.chapterId

    local boxData = getChapterBoxData(self.chapterId)

    local starCount = StageHelper.getChapterStar(self.chapterId)
    local maxCount = boxData[3].star
    self.starNum:setString(starCount .. "/" .. maxCount)
    self.starLoadingBar:setPercent(starCount / maxCount * 100)

    local chapterState = StageHelper.getChapterBoxState(self.chapterId)
    for i = 1, 3 do
        local chest = self.chests[i]
        CsbTools.getChildFromPath(chest, "StarNum"):setString(boxData[i].star)

        local button = CsbTools.getChildFromPath(chest, "ChestButton")
        local animateNode = CsbTools.getChildFromPath(button, "Chest")
        animateNode:stopAllActions()
        if starCount < boxData[i].star then     -- 宝箱关闭
            button:setTouchEnabled(true)
            CommonHelper.playCsbAnimate(animateNode, ResConfig.UIMap.Csb2.chest, "Close", false)
        else
            if chapterState[i] then             -- 宝箱打开
                button:setTouchEnabled(false)
                CommonHelper.playCsbAnimate(animateNode, ResConfig.UIMap.Csb2.chest, "Open", false)
            else
                button:setTouchEnabled(true)    -- 宝箱准备打开啦！
                CommonHelper.playCsbAnimate(animateNode, ResConfig.UIMap.Csb2.chest, "CloseLight", true)
            end
        end
    end
end

return ChestController