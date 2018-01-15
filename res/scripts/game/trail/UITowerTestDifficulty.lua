-------------------------------------------------
--名称:UITowerTestDifficulty
--描述:爬塔试炼难度选择
--日期:2016年3月11日
--作者:Azure
--------------------------------------------------

local UITowerTestDifficulty = class("UITowerTestDifficulty", function()
    return require("common.UIView").new()
end)

--构造
function UITowerTestDifficulty:ctor()

end

--初始
function UITowerTestDifficulty:init()
    --加载
    self.rootPath = ResConfig.UITowerTestDifficulty.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    --关闭
    local back = getChild(self.root, "BackButton")
    CsbTools.initButton(back, function()
        UIManager.close()
    end)

    --挑战
    for i = 1, 3 do
        local btn = getChild(self.root, "MainPanel/MovePanel/ChooseButton_" .. i)
        CsbTools.initButton(btn, function()
            UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
                BattleHelper.requestTowerTest(summonerId, heroIds, i, mercenaryId)
            end) 
        end, getUILanConfItem(82), "Button_Orange/ButtomName", "Button_Orange")
    end
end

--打开
function UITowerTestDifficulty:onOpen()
    --配置
    local cur = getGameModel():getTowerTestModel():getTowerTestFloor()
    local conf = getTowerFloorConfItem(cur)

    --显示等级
    local userLv = getGameModel():getUserModel():getUserLevel()
    local function toLevel(diff)
        local lv = userLv + diff.EXLevel
        return math.min(math.max(lv, diff.BasicLevel), diff.MaxLevel)
    end
    
    --难度
    local icon = {[1] = "climbtower_bg_simple.png", 
                  [2] = "climbtower_bg_common.png", 
                  [3] = "climbtower_bg_diffcult.png"}
    for i = 1, 3 do
        local stageID = conf.StageID[i]
        local bossID = getStageConfItem(stageID).Boss
        local boss = getBossConfItem(bossID)
        local item = getChild(self.root, "MainPanel/MovePanel/ChooseDiffcultItem_" .. i) 
        getChild(item, "DiffcultPanel/DiffcultName"):setString(getBMCLanConfItem(boss.Common.Name))
        getChild(item, "DiffcultPanel/LevelNum"):setString(toLevel(conf.Diff[i]))
        getChild(item, "DiffcultPanel/Diffcult"):setString(getUILanConfItem(364 + i))
        getChild(item, "DiffcultPanel/PointsNum"):setString(conf.Diff[i].Reward)
        getChild(item, "DiffcultPanel/GemNum"):setString("* " .. conf.Diff[i].ExtraStar)
        getChild(item, "DiffcultPanel/DiffcultImage"):loadTexture(icon[i], 1)
        if not conf.Diff[i].ExtraStar or conf.Diff[i].ExtraStar <= 0 then
            getChild(item, "DiffcultPanel/GemAdd"):setVisible(false)
            getChild(item, "DiffcultPanel/GemNum"):setVisible(false)
            getChild(item, "DiffcultPanel/StarImage"):setVisible(false)
        else
            getChild(item, "DiffcultPanel/GemAdd"):setVisible(true)
            getChild(item, "DiffcultPanel/GemNum"):setVisible(true)
            getChild(item, "DiffcultPanel/StarImage"):setVisible(true)
        end

        --动画
        local heroNode = getChild(item, "DiffcultPanel/HeroPanel/HeroNode")
        AnimatePool.createAnimate(boss.Common.AnimationID, function(animation)
            if animation and heroNode then
                heroNode:removeAllChildren()
                heroNode:addChild(animation)
            end
        end)
    end
end

function UITowerTestDifficulty:onClose()
    for i = 1, 3 do
        local item = getChild(self.root, "MainPanel/MovePanel/ChooseDiffcultItem_" .. i)
        local heroNode = getChild(item, "DiffcultPanel/HeroPanel/HeroNode")
        if heroNode then
            heroNode:removeAllChildren()
        end
    end    
end

return UITowerTestDifficulty

--endregion
