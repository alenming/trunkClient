--------------------------------------------------
--名称:UIMap
--描述:世界地图
--日期:2016年2月24日
--作者:Azure
--尚志重构于2017/2/23
--------------------------------------------------
local UIMap = class("UIMap", function()
    return require("common.UIView").new()
end)

--图层层级
local LayerOrder = 
{
    LO_SKY      = 1,      --天空层
    LO_MAP      = 2,      --地图层
    LO_UI       = 3,      --UI层
    LO_Btn      = 4,      --按钮层
}

--章节夹角
local ANGLE = 18.3

--地图半径
local RADIUS = 2500.0

function UIMap:ctor()
    
end

function UIMap:init()
    self.rootPath = ResConfig.UIMap.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self.root:setLocalZOrder(LayerOrder.LO_UI)
    self.root:setContentSize(display.width, display.height)
    ccui.Helper:doLayout(self.root)
    self:addChild(self.root)

    self.mainPanel = CsbTools.getChildFromPath(self.root, "MainPanel")

    self.titleChapter = CsbTools.getChildFromPath(self.mainPanel, "MapNameLabel")   -- 第几章
    self.titleName = CsbTools.getChildFromPath(self.mainPanel, "MapNameLabel_2")    -- 章节名字

    self.loadingChestPanel = CsbTools.getChildFromPath(self.root, "LoadingChest")
    self.chestController = require("game.world.ChestController").new()
    self.chestController:setTarget(self.loadingChestPanel)

    -- 返回按钮
    self.backBtn = getChild(self.root, "BackButton")
    self.backBtn:setLocalZOrder(LayerOrder.LO_Btn)
    CsbTools.initButton(self.backBtn, function()
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end)

    self.leftButton  = getChild(self.root, "LeftButton")
    CsbTools.initButton(self.leftButton,  handler(self, self.leftButtonCallBack))

    self.rightButton = getChild(self.root, "RightButton")
    CsbTools.initButton(self.rightButton, handler(self, self.rightButtonCallBack))

    -- 拖拽
    self:initMainPanel()
end

function UIMap:onOpen()
    -- 云
    CommonHelper.playCsbAnimate(self.root, self.rootPath, "animation", true)

    -- 进入的章节ID 
    self.curChapterID = StageHelper.CurChapter
    if StageHelper.QuickStageId then
        self.curChapterID = StageHelper.getChapterByStage(StageHelper.QuickStageId)
        StageHelper.QuickStageId = nil
    end

    self:initEarth()

    self:updateSky()
    self:updateTitle()
    self:updateChests()
    self:updateMapSector()

    self:updateBackgroundMusic()
end

function UIMap:onClose()
    self.chestController:removeNetworkListener()
end

-- 初始化地球
function UIMap:initEarth()
    self.Earth = cc.Node:create()
    self.Earth:setLocalZOrder(LayerOrder.LO_MAP)
    self.Earth:setPosition(cc.p(0.5 * display.width, -RADIUS))
    self.Earth:setRotation((1 - self.curChapterID) * ANGLE)
    self.Earth:setName("Earth")
    self:addChild(self.Earth)

    local chapterType = StageHelper.getChapterType(self.curChapterID)
    local maxChapterID = StageHelper.getCurrentChapter(chapterType)
    local allChapterIds = getChapterItemList()
    if allChapterIds[maxChapterID + 1] then -- 还有下一章
        maxChapterID = maxChapterID + 1
    end
    for i = 1, maxChapterID do
        self:addMapSector(i)
    end
end

-- 添加一个章节扇区
function UIMap:addMapSector(chapterId)
    if not self.sectors then
        self.sectors = {}
    end

    local sector = require("game.world.UIMapSector").new()
    sector:updateChapter(chapterId)
    sector:setAnchorPoint(cc.p(0.5, -RADIUS / display.height))
    sector:setPosition(cc.p(0 , 0))
    sector:setRotation((chapterId - 1) * ANGLE)
    self.Earth:addChild(sector)

    self.sectors[chapterId] = sector
end

-- 注册触摸回调
function UIMap:initMainPanel()
    self.mainPanel:setTouchEnabled(true)
    self.mainPanel:setSwallowTouches(false)

    local beginPos = nil

    self.mainPanel:addTouchEventListener(function(obj, event)
        if event == 0 then
            beginPos = obj:getTouchBeganPosition()
        elseif event == 1 then
            local movePos = obj:getTouchMovePosition()
            local delta = (movePos.x - beginPos.x)
            local angle = delta * ANGLE / display.width
            --规范角度，设置角度
            local cur = self.Earth:getRotation()
            local rot = cur + angle
            if rot > 0 then
                rot = 0
            end
            -- 最大角度
            local chapterType = StageHelper.getChapterType(self.curChapterID)
            local chapterID = StageHelper.getCurrentChapter(chapterType)
            local lock = -chapterID * ANGLE -- delta
            if rot < lock then
                rot = lock
            end

            self.Earth:setRotation(rot)
            beginPos = movePos
        elseif event == 2 or event == 3 then
            local cur = self.Earth:getRotation()
            local delta = 0.1 * ANGLE
            local rot = (1 - self.curChapterID) * ANGLE
            if cur < rot - delta then
                self:nextChapter()
            elseif cur > rot + delta then
                self:lastChapter()
            else
                local rotateTo = cc.RotateTo:create(0.3, rot)
                self.Earth:runAction(rotateTo)
            end
        end
    end)
end

function UIMap:leftButtonCallBack()
    if self.curChapterID > 1 then
        self:lastChapter()
    end
end

function UIMap:rightButtonCallBack()
    local chapterType = StageHelper.getChapterType(self.curChapterID)
    if self.curChapterID < StageHelper.getCurrentChapter(chapterType) + 1 then
        self:nextChapter()
    end
end

--------------- 更新UI begin -----------------

-- 更新章节标题
function UIMap:updateTitle()
    local conf = getChapterConfItem(self.curChapterID)
    if nil == conf then
        return
    end
    self.titleChapter:setString(string.format(getUILanConfItem(78), conf.MapID))
    self.titleName:setString(getStageLanConfItem(conf.Name))
end

-- 更新天空层
function UIMap:updateSky()
    if not self.sky then
        self.sky = require("game/world/UISky").new()
        self:addChild(self.sky)
    end
    self.sky:setChapter(self.curChapterID)
end

-- 更新宝箱
function UIMap:updateChests()
    local chapterType = StageHelper.getChapterType(self.curChapterID)
    if self.curChapterID > StageHelper.getCurrentChapter(chapterType) then
        self.loadingChestPanel:setVisible(false)
    else
        self.loadingChestPanel:setVisible(true)
        self.chestController:updateChests(self.curChapterID)
    end
end    

-- 更新地图扇区
function UIMap:updateMapSector()
    local chId = self.curChapterID
    if self.sectors and self.sectors[chId] then
        self.sectors[chId]:updateChapter(chId)

        local chapterType = StageHelper.getChapterType(chId)
        local chapterID = StageHelper.getCurrentChapter(chapterType)
        if chId == chapterID then
            self.sectors[chId + 1]:setMapLockChestButtonVisible(false)
        elseif chId > chapterID then
            self.sectors[chId]:setMapLockChestButtonVisible(true)
        end
    end
end

--------------- 更新UI end -----------------

-- 更新章节背景音乐
function UIMap:updateBackgroundMusic()
    local conf = getChapterConfItem(self.curChapterID)
    local mapConf = getMapConfItem(conf.MapID)
    if mapConf then
        MusicManager.setMusicParam(mapConf.MoodEffect[1], tonumber(mapConf.MoodEffect[2]))
    end
end

--向前翻页
function UIMap:lastChapter()
    local conf = getChapterConfItem(self.curChapterID)
    if nil == conf then
        print("chapterForward conf==nil, self.curChapterID ", self.curChapterID)
        return
    end
    if conf.PrevID == 0 then
        return
    end

    local rot = (2 - self.curChapterID) * ANGLE
    local rotateTo = cc.RotateTo:create(0.3, rot)
    self.Earth:runAction(rotateTo)

    StageHelper.CurChapter = conf.PrevID
    self.curChapterID = StageHelper.CurChapter

    self:updateSky()
    self:updateTitle()
    self:updateChests()
    self:updateMapSector()

    self:updateBackgroundMusic()
    
    MusicManager.playSoundEffect(56)
end

--向后翻页
function UIMap:nextChapter()
    local conf = getChapterConfItem(self.curChapterID)
    if nil == conf then
        print("chapterBackward conf==nil, self.curChapterID ", self.curChapterID)
        return
    end
    if conf.NextID == 0 then
        return
    end

    local rot = -self.curChapterID * ANGLE
    local rotateTo = cc.RotateTo:create(0.3, rot)
    self.Earth:runAction(rotateTo)

    StageHelper.CurChapter = conf.NextID
    self.curChapterID = StageHelper.CurChapter

    self:updateSky()
    self:updateTitle()
    self:updateChests()
    self:updateMapSector()

    self:updateBackgroundMusic()

    MusicManager.playSoundEffect(56)
end

return UIMap