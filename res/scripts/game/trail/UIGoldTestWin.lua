--[[
金币试炼结算界面
]]

local UIGoldTestWin = class("UIGoldTestWin", function()
    return require("common.UIView").new()
end)

function UIGoldTestWin:ctor()
    self.rootPath = ResConfig.UIGoldTestWin.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local confirmBtn = getChild(self.root, "MainPanel/ConfirmButtom")
    local confirmBtnCallBack = function()
        -- 释放房间资源
        finishBattle()
	    -- 加载大厅场景
	    if SceneManager.PrevScene then
		    SceneManager.loadScene(SceneManager.PrevScene)
	    else
		    SceneManager.loadScene(SceneManager.Scene.SceneHall)
	    end
    end
    CsbTools.initButton(confirmBtn, confirmBtnCallBack
        , CommonHelper.getUIString(500), "ConfirmButtom/ButtomName", "ConfirmButtom")
end

function UIGoldTestWin:init(hurt, hurtaward, levelaward)
	self:setGlobalZOrder(5)
	self:setLocalZOrder(5)

    local totalGold = hurtaward + levelaward;
    getChild(self.root, "MainPanel/AwardSumLabel"):setString(tostring(totalGold))
    getChild(self.root, "MainPanel/HurtSumLabel"):setString(tostring(hurt))
    getChild(self.root, "MainPanel/HurtAwardLabel"):setString(tostring(hurtaward))
    getChild(self.root, "MainPanel/LevelAddLabel"):setString(tostring(levelaward))

    -- 设置模型数据
    local goldTestModel = getGameModel():getGoldTestModel()
    goldTestModel:addCount(1) -- 挑战次数+1
    goldTestModel:addDamage(hurt) -- 添加伤害

    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, totalGold)
end

return UIGoldTestWin
