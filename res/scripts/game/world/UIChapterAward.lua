--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-21 15:16
** 版  本:	1.0
** 描  述:  章节奖励界面
** 应  用:
********************************************************************/
--]]
local PropTips = require("game.comm.PropTips")

local UIChapterAward = class("UIChapterAward", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIChapterAward:ctor()
    --加载
    self.rootPath = ResConfig.UIChapterAward.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local closeBtn = getChild(self.root, "MainPanel/CloseButton")
    CsbTools.initButton(closeBtn, handler(self, self.onClick))

    self.prevBtn = getChild(self.root, "MainPanel/LeftButton")
    CsbTools.initButton(self.prevBtn, handler(self, self.onClick))

    self.nextBtn = getChild(self.root, "MainPanel/RightButton")
    CsbTools.initButton(self.nextBtn, handler(self, self.onClick))

    self.awardState = getChild(self.root, "MainPanel/StageAwardState")
    self.confirmBtn = getChild(self.awardState, "ConfirmButtom/ConfirmButtom")
    getChild(self.confirmBtn, "NameLabel"):setString(getUILanConfItem(79))

    local confirmBtn = getChild(self.awardState, "ConfirmButtom")
    CsbTools.initButton(confirmBtn, handler(self, self.onClick))
end

-- 当界面被创建时回调
-- 只初始化一次
function UIChapterAward:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIChapterAward:onOpen(openerUIID, chapterId, callback)
    self.propTips = PropTips.new()

    self.chapterId = chapterId
    self.callback = callback

    self:show()
end

-- 每次界面Open动画播放完毕时回调
function UIChapterAward:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIChapterAward:onClose()
    self.propTips:removePropAllTips()
    self.propTips = nil
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIChapterAward:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIChapterAward:onClick(obj)
    local btnName = obj:getName()
    if "CloseButton" == btnName then
        UIManager.close()
    elseif "LeftButton" == btnName then
        local conf = getChapterConfItem(self.chapterId)
        if conf.PrevID > 0 then
            self.chapterId = conf.PrevID
            self:show()
        end
    elseif "RightButton" == btnName then
        local conf = getChapterConfItem(self.chapterId)
        if conf.NextID > 0 then
            self.chapterId = conf.NextID
            self:show()
        end
    elseif "ConfirmButtom" == btnName then
        CommonHelper.playCsbAnimate(self.confirmBtn, ResConfig.UIChapterAward.Csb2.confirmBtn, "OnAnimation", false, function()
            self:sendChapterAwardCmd()
        end)
    end
end

-- 显示左右选择按钮
function UIChapterAward:showArrowBtn()
    local conf = getChapterConfItem(self.chapterId)
    local userLV = getGameModel():getUserModel():getUserLevel()

    local prevFlag = false
    local prevConf = getChapterConfItem(conf.PrevID)
    if prevConf then
        local prevState = getGameModel():getStageModel():getChapterState(conf.PrevID)
        local prevLevel = prevConf.UnlockLevel
        prevFlag = prevState > StageHelper.ChapterState.CS_LOCK and userLV >= prevLevel
    end
    self.prevBtn:setVisible(prevFlag)

    local nextFlag = false
    local nextConf = getChapterConfItem(conf.NextID)
    if nextConf then
        local nextState = getGameModel():getStageModel():getChapterState(conf.NextID)
        local nextLevel = nextConf.UnlockLevel
        nextFlag = nextState > StageHelper.ChapterState.CS_LOCK and userLV >= nextLevel
    end
    self.nextBtn:setVisible(nextFlag)
end

-- 显示奖励物品
function UIChapterAward:showAward()
    local scrollView = getChild(self.root, "MainPanel/AwardScrollView")
    scrollView:removeAllChildren()
    scrollView:setScrollBarEnabled(false)
    scrollView:setInnerContainerSize(scrollView:getContentSize())

    local conf = getChapterConfItem(self.chapterId)
    for i, award in pairs(conf.FullStarAward) do
        local allItem = getResManager():cloneCsbNode(ResConfig.UIChapterAward.Csb2.awardItem)
        local pX = 100 + (i - 1) * 100
        allItem:setPosition(pX, 48)
        scrollView:addChild(allItem)

        local propConf = getPropConfItem(award.ID)
        if propConf then
            -- 道具图标
            UIAwardHelper.setAllItemOfConf(allItem, propConf, award.num)
            -- 道具tips
            local touchPanel = getChild(allItem, "MainPanel")
            self.propTips:addPropTips(touchPanel, propConf)
        end
    end
end

-- 显示其他信息
function UIChapterAward:showInfo()
    local conf = getChapterConfItem(self.chapterId)
    getChild(self.root, "MainPanel/StageNum"):setString(string.format(getUILanConfItem(78), conf.MapID))
    getChild(self.root, "MainPanel/StageName"):setString(getStageLanConfItem(conf.Name))
    --
    local star = StageHelper.getChapterStar(self.chapterId)
    getChild(self.root, "MainPanel/StarNum"):setString(tostring(star) .. "/" .. tostring(conf.FullStar))
    --
    local state = StageHelper.getChapterState(self.chapterId)
    CommonHelper.playCsbAnimate(self.awardState, ResConfig.UIMap.Csb2.awardstate, state == StageHelper.ChapterState.CS_REWARD and "Received" or "UnReceive", false)
    self.awardState:setVisible(star == conf.FullStar and true or false)
end

-- 刷新显示
function UIChapterAward:show()
    self:showArrowBtn()
    self:showAward()
    self:showInfo()
end

-- 发送领取奖励请求
function UIChapterAward:sendChapterAwardCmd()
    local state = StageHelper.getChapterState(self.chapterId)
    if state == StageHelper.ChapterState.CS_REWARD then
        return
    end
    local star = StageHelper.getChapterStar(self.chapterId)
    local conf = getChapterConfItem(self.chapterId)
    if star < conf.FullStar then
        return
    end

    local buffData = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.ChapterAwardCS)
    buffData:writeInt(self.chapterId)
    NetHelper.requestWithTimeOut(buffData,
        NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.ChapterAwardSC),
        handler(self, self.acceptChapterAwardCmd))
end

-- 接收领取奖励请求
function UIChapterAward:acceptChapterAwardCmd(mainCmd, subCmd, buffData)
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
    CommonHelper.playCsbAnimate(self.awardState, ResConfig.UIMap.Csb2.awardstate, "Received", false)
    getGameModel():getStageModel():setChapterState(self.chapterId, StageHelper.ChapterState.CS_REWARD)

    if self.callback and "function" == type(self.callback) then
        self.callback()
    end

    RedPointHelper.addCount(RedPointHelper.System.WorldMap, -1)

    UIManager.open(UIManager.UI.UIAward, awardData)
end

return UIChapterAward