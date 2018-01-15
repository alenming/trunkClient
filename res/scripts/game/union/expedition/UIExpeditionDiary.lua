--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征先驱者日记
** 应  用:
********************************************************************/
--]]
local scheduler = require("framework.scheduler")  

local UIExpeditionDiary = class("UIExpeditionDiary", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIExpeditionDiary:ctor()
    local gameModel = getGameModel()
    self.mUnionModel = gameModel:getUnionModel()
    self.mUserModel = gameModel:getUserModel()
end

-- 当界面被创建时回调
-- 只初始化一次
function UIExpeditionDiary:init(...)
    -- 加载
    self.rootPath = ResConfig.UIExpeditionDiary.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.mMainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    self.mIslandPanel = CsbTools.getChildFromPath(self.mMainPanel, "IslandPanel")

    self.mEnergInfo = CsbTools.getChildFromPath(self.root, "EnergInfo")
    self.mGemInfo = CsbTools.getChildFromPath(self.root, "GemInfo")
    self.mGoldInfo = CsbTools.getChildFromPath(self.root, "GoldInfo")
    self.mTime = CsbTools.getChildFromPath(self.root, "Time")

    -- 退出按钮
    self.mBackButton = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(self.mBackButton, handler(self, self.onClick))

    self:setArea()
end

function UIExpeditionDiary:initTime()
    self.mTime:setString(os.date("%H:%M"))
    self.mSchedulerHandler = scheduler.scheduleGlobal(function()
        self.mTime:setString(os.date("%H:%M"))
    end, 1)
end

function UIExpeditionDiary:setArea()
    local uLv = self.mUnionModel:getUnionLv()
    local cfgExpd = getExpeditionConf()
    for i = 1, #cfgExpd do
        local cfg = cfgExpd[i]
        local uLvFloor = cfg.Expedition_Level
        local islandButton = CsbTools.getChildFromPath(self.mIslandPanel, "Island_"..i)
        islandButton:setEnabled(true)
        islandButton:setBright(uLv >= uLvFloor)
        -- 监听区域点击事件
        CsbTools.initButton(islandButton, function (obj)
            obj.soundId = nil
            if uLv < uLvFloor then  -- 该区域未开启
                CsbTools.addTipsToRunningScene(string.format(CommonHelper.getUIString(1905), uLvFloor))
                obj.soundId = MusicManager.commonSound.fail
            else
                UIManager.open(UIManager.UI.UIExpeditionDiaryIslandIntro, i)
            end
        end)
    end 
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIExpeditionDiary:onOpen(openerUIID, ...)
    self:updateGold()
    self:updateDiamond()
    self:initTime()
end

-- 每次界面Open动画播放完毕时回调
function UIExpeditionDiary:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIExpeditionDiary:onClose()
    scheduler.unscheduleGlobal(self.mSchedulerHandler)
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIExpeditionDiary:onTop(preUIID, ...)
end

-- 当前界面点击事件回调
function UIExpeditionDiary:onClick(obj)
    local objName = obj:getName()
    if objName == "BackButton" then             -- 返回
        UIManager.close()
    end
end

function UIExpeditionDiary:updateGold()
    local gold = self.mUserModel:getGold()
    local label = CsbTools.getChildFromPath(self.mGoldInfo, "GoldPanel/GoldCountLabel")
    label:setString(gold)
end

function UIExpeditionDiary:updateDiamond()
    local diamond = self.mUserModel:getDiamond()
    local label = CsbTools.getChildFromPath(self.mGemInfo, "GemPanel/GemCountLabel")
    label:setString(diamond)
end

return UIExpeditionDiary