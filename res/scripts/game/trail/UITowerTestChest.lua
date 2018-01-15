-------------------------------------------------
--名称:UITowerTestChest
--描述:爬塔试炼宝箱界面
--日期:2016年3月11日
--作者:Azure
--------------------------------------------------
require("game.comm.TowerTestHelper")

local UITowerTestChest= class("UITowerTestChest", function()
    return require("common.UIView").new()
end)

--构造
function UITowerTestChest:ctor()

end

--初始
function UITowerTestChest:init()
    --加载
    self.rootPath = ResConfig.UITowerTestChest.Csb2.found
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    --领取
    local start = getChild(self.root, "MainPanel/OpenButtom")
    CsbTools.initButton(start, handler(self, self.onClick), getUILanConfItem(79), "Button_Green/ButtomName", "Button_Green")
end

--打开
function UITowerTestChest:onOpen()
    --刷新钻石和金币显示
    local gemLabel   = getChild(self.root, "MainPanel/Gem/GemLabel")
    local coinLabel  = getChild(self.root, "MainPanel/Coin/CoinLabel")
    local haveGold = getGameModel():getUserModel():getGold()
    local haveGem = getGameModel():getUserModel():getDiamond()
    coinLabel:setString(haveGold)
    gemLabel:setString(haveGem)
end

--关闭
function UITowerTestChest:onClose()

end

function UITowerTestChest:onClick(obj)
    local btnName = obj:getName()
    if "OpenButtom" == btnName then
        local awardData = TowerTestHelper:getAwardData()
        TowerTestHelper:resetAwardData()
        UIManager.replace(UIManager.UI.UIAward, awardData)
    end
end

return UITowerTestChest