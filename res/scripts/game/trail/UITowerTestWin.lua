-------------------------------------------------
--名称:UITowerTestWin
--描述:爬塔试炼胜利界面
--日期:2016年3月11日
--作者:Azure
--------------------------------------------------


local UITowerTestWin = class("UITowerTestWin", function()
    return require("common.UIView").new()
end)
require("game.comm.UIAwardHelper")
require("game.comm.TowerTestHelper")

--构造
function UITowerTestWin:ctor()
    
end

--初始化
function UITowerTestWin:init(resultData)
    --加载
    self.rootPath = ResConfig.UITowerTestWin.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    --ZOrder
    self:setGlobalZOrder(5)
    self:setLocalZOrder(5)

    -- 按钮
    local ok = getChild(self.root, "FightWinEffect/ConfirmButtom")
    ok:addClickEventListener(function()
        CommonHelper.playCsbAnimate(getChild(ok, "ConfirmButtom"), ResConfig.UITowerTestChest.Csb2.ok, "OnAnimation", false)
        -- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
        -- 释放房间资源
        finishBattle()
        -- 加载大厅场景
        if SceneManager.PrevScene then
            SceneManager.loadScene(SceneManager.PrevScene)
        else
            SceneManager.loadScene(SceneManager.Scene.SceneHall)
        end
    end)
    
    --获取多星条件
    local floorConf = getTowerFloorConfItem(resultData.floor)


    --爬塔试炼结算
    local model = getGameModel():getTowerTestModel()
    model:setTowerTestFloor(model:getTowerTestFloor() + 1)
    
    --宝箱物品
    local awardData = {}
    UIAwardHelper.formatAwardData(awardData, "exp", resultData.exp)
    UIAwardHelper.formatAwardData(awardData, "gold", resultData.gold)
    UIAwardHelper.formatAwardData(awardData, "diamond", resultData.diamond)
    UIAwardHelper.formatAwardData(awardData, "pvpCoin", resultData.pvpCoin)
    UIAwardHelper.formatAwardData(awardData, "towerCoin", resultData.towerCoin)
    UIAwardHelper.formatAwardData(awardData, "guildContrib", resultData.guildContrib)
    if next(resultData.Prop) ~= nil then
        model:setTowerTestEvent(2)                      --宝箱事件
        --model:setTowerTestParam(1)                      --宝箱次数
        for k,v in pairs(resultData.Prop) do
            UIAwardHelper.formatAwardData(awardData, "dropInfo", v)
        end
    else
        model:setTowerTestEvent(1)
       -- model:setTowerTestParam(-1)
    end

    TowerTestHelper:setAwardData(awardData)

end

--打开
function UITowerTestWin:onOpen()

end

return UITowerTestWin

--endregion
