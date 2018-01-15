-------------------------------------------------
--名称:UITowerTest
--描述:爬塔试炼主界面
--日期:2016年3月11日
--作者:Azure
--------------------------------------------------

local towerTestModel = getGameModel():getTowerTestModel()

local UITowerTest = class("UITowerTest", function()
    return require("common.UIView").new()
end)
require("game.comm.UIAwardHelper")

local towerSound = {climbUp = 25, treasure = 38, flyIn = 30}

--构造
function UITowerTest:ctor()
    
end

--初始化
function UITowerTest:init()
    --加载
    self.rootPath = ResConfig.UITowerTest.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 界面动画
    self.rootAction = cc.CSLoader:createTimeline(self.rootPath)
    self.root:runAction(self.rootAction)
    self.rootAction:setFrameEventCallFunc(handler(self, self.OnAnimationFrameEvent))

    -- 掉灰动画
    local dropSoil = getChild(self.root, "DropSoil")
    dropSoil:setVisible(false)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_Particle.ExportJson") 
    self.soilArmature = ccs.Armature:create("ClimbTower_Particle") 
    self.soilArmature:setPosition(dropSoil:getPosition())
    self.soilArmature:setLocalZOrder(dropSoil:getLocalZOrder())
    self.root:addChild(self.soilArmature)

    --退出
    local back = getChild(self.root, "BackButton")
    CsbTools.initButton(back, function()
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end)

    --排行榜
    local rank = getChild(self.root, "StoneWallPanel/StoneWall/RankingButton")
    CsbTools.initButton(rank, function()
        UIManager.open(UIManager.UI.UITowerTestRank)
    end)

    --规则
    local info = getChild(self.root, "StoneWallPanel/StoneWall/QuestionButton")
    CsbTools.initButton(info, function()
        UIManager.open(UIManager.UI.UITowerTestRule, CommonHelper.getUIString(1042))
    end)

    --开始迎战
    local attack = getChild(self.root, "StoneWallPanel/StoneWall/DownButtonBar/StartTowerButton")
    CsbTools.initButton(attack, function()
        self:start()
    end)

    --对战
    local vs = getChild(self.root, "MainPanel/BasePanel/ClimbTownVSIcon/VSPanel")

    CsbTools.initButton(vs,  function()
        UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
            BattleHelper.requestTowerTest(summonerId, heroIds, 1, mercenaryId)
        end) 
    end)

    --抽栏
    self.downButtonBar = getChild(self.root, "StoneWallPanel/StoneWall/DownButtonBar")
    self.chest = getChild(self.root, "MainPanel/ClimbTower_Chest")
    self.effectBall = getChild(self.root, "MainPanel/ClimbTower_EffectBall")
    self.touchPanel = getChild(self.root, "TouchPanel")

    towerTestModel:setTowerTestCrystal(getTowerSetting().FirstCrystal)
end

--打开
function UITowerTest:onOpen()
    self.downButtonBar:setVisible(false)
    self.chest:setVisible(false)
    self.effectBall:setVisible(false)

    self.summonerNode = getChild(self.root, "MainPanel/BasePanel/SummonerPanel/SummonerNode")
    self.enemyNode = getChild(self.root, "MainPanel/BasePanel/EnemyPanel/EnemuNode")

    self.floorList = getTowerFloorItemList()
    self.floor = towerTestModel:getTowerTestFloor()

    self:res()
end

--每次界面Open动画播放完毕时回调
function UITowerTest:onOpenAniOver()
    self:event()
end

--关闭
function UITowerTest:onClose()
    if self.summonerNode then
        self.summonerNode:removeAllChildren()
        self.summonerNode = nil
    end
	if self.enemyNode then
        self.enemyNode:removeAllChildren()
        self.enemyNode = nil
    end
end

--置顶
function UITowerTest:onTop(preUIID, ret)
    if preUIID == UIManager.UI.UIAward then
        self:climb()
    end
end

--爬楼
function UITowerTest:climb()

    --到顶了
    if self.floor > #self.floorList then
        -- 楼层
        getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(#self.floorList))
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1029))
        self.touchPanel:setTouchEnabled(false)
        return
    end
    getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(self.floor)
    self.chest:setVisible(false)
    self.effectBall:setVisible(false)
    self.rootAction:play("ClimbTower", false)
    MusicManager.playSoundEffect(towerSound.climbUp)
    self.touchPanel:setTouchEnabled(false)
end

--资源
function UITowerTest:res()

    --水晶
    local crystal   = towerTestModel:getTowerTestCrystal()
    getChild(self.root, "StoneWallPanel/StoneWall/GemNum_L"):setString(tostring(crystal))

    --更新自身召唤师形象
    local teamId = TeamHelper.getTeamId()
    local summonerID = TeamHelper.getTeamSummoner(teamId)
    local conf = getHeroConfItem(summonerID)
    if conf then
        AnimatePool.createAnimate(conf.Common.AnimationID, function(animation)
            if animation and self.summonerNode then
                self.summonerNode:removeAllChildren()
                self.summonerNode:addChild(animation)
            end
        end)
    end
end

--事件
function UITowerTest:event()
    --事件
    local event = towerTestModel:getTowerTestEvent()
    towerTestModel:setTowerTestEvent(0)
    if 0 == event then
        self.touchPanel:setTouchEnabled(false)
        --到顶了
        if self.floor > #self.floorList then
            -- 楼层
            getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(#self.floorList))
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1029))
            return
        end

        -- 从战斗中胜利回来没有任何掉落
        local param = towerTestModel:getTowerTestParam()
        towerTestModel:setTowerTestParam(0)
        if -1 == param then
            -- 楼层
            getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(self.floor - 1))
            -- 空事件
            local delay = cc.DelayTime:create(1)
            local callbacks = cc.CallFunc:create(function()
                self:climb()
            end)
            self.root:runAction(cc.Sequence:create(delay, callbacks))
        -- 从主城中进来
        else
            -- 楼层
            getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(self.floor))
            --显示抽栏模式
            self.downButtonBar:setVisible(true)
            CommonHelper.playCsbAnimate(self.downButtonBar, ResConfig.UITowerTest.Csb2.bar, "One", false)
        end
        CommonHelper.playCsbAnimation(self.root, "Normal", false)
    elseif 1 == event then
        self.touchPanel:setTouchEnabled(true)
        self:climb()
    elseif 2 == event then
        self.touchPanel:setTouchEnabled(true)
        -- 楼层
        getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(self.floor - 1))
        --宝箱事件
        CommonHelper.playCsbAnimate(self.root, ResConfig.UITowerTest.Csb2.main, "OpenWindow", false, function()
            -- 播放完动画
            if UIManager.isTopUI(UIManager.UI.UITowerTest) then
                self.chest:setVisible(true)
                self.effectBall:setVisible(false)
                CommonHelper.playCsbAnimate(self.chest, ResConfig.UITowerTest.Csb2.chest, "CloseLight", true)
                --
                local delay = cc.DelayTime:create(0.2)
                local callback = cc.CallFunc:create(function()
                    CommonHelper.playCsbAnimate(self.chest, ResConfig.UITowerTest.Csb2.chest, "OpenLight", false, function()
                        local delay = cc.DelayTime:create(0.5)
                        local callback = cc.CallFunc:create(function()
                            UIManager.open(UIManager.UI.UITowerTestChest)
                        end)
                        self.root:runAction(cc.Sequence:create(delay, callback))
                    end)
                end)
                MusicManager.playSoundEffect(towerSound.treasure)
                self.root:runAction(cc.Sequence:create(delay, callback))
            end
        end)
    end
end

--开始
function UITowerTest:start()
    --抽栏
    self.downButtonBar:setVisible(false)

    --配置
    local floorConf = getTowerFloorConfItem(self.floor)
    --方位
    local dir = floorConf.Place == 0 and "EnemyAppear_L" or "EnemuAppear_R"
    self.rootAction:play(dir, false)

    --当前最难关卡boss模型
    local stageID = floorConf.StageID[3]
    local bossID = getStageConfItem(stageID).Boss
    local bossConf = getBossConfItem(bossID)
    AnimatePool.createAnimate(bossConf.Common.AnimationID, function(animation)
        if animation and self.enemyNode then
            animation:setToSetupPose()  -- 去掉残影
            animation:setAnimation(0, "Move1", true)
            self.animation = animation
            --
            self.enemyNode:removeAllChildren()
            self.enemyNode:addChild(animation)
        end
    end) 
end

-- 动画帧事件
function UITowerTest:OnAnimationFrameEvent(frame)
    if nil == frame then
        return
    end

    local eventName = frame:getEvent()
    if eventName == "DropSoil" then
        self.soilArmature:getAnimation():play("DropSoil", -1, 0)
        -- 楼层
        getChild(self.root, "StoneWallPanel/StoneWall/FloorNum"):setString(tostring(self.floor))
    elseif eventName == "End" then
        self:start()
    elseif eventName == "Move1" then

    elseif eventName == "Stand1" then
        if self.animation then
            self.animation:setToSetupPose()  -- 去掉残影
            self.animation:setAnimation(0, "Stand1", true)
        end
    end
end

return UITowerTest