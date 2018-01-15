--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-10-12 10:31
** 版  本:	1.0
** 描  述:  公会远征关卡结算界面
** 应  用:
********************************************************************/
--]]

local UIExpeditionWin = class("UIExpeditionWin", function()
	return require("common.UIView").new()
end)


function UIExpeditionWin:ctor()
end

function UIExpeditionWin:init()
    -- 加载
    self.rootPath = ResConfig.UIExpeditionWin.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local confirmButtom = CsbTools.getChildFromPath(self.root, "MainPanel/ConfirmButtom")
    CsbTools.initButton(confirmButtom, handler(self, self.onClick))

    self:setGlobalZOrder(5)
	self:setLocalZOrder(5)
end

function UIExpeditionWin:onOpen(openerUIID, damage)
    local hurtLabel = CsbTools.getChildFromPath(self.root, "MainPanel/HurtSumLabel")
    hurtLabel:setString(damage)

    local expeditionModel = getGameModel():getExpeditionModel()
    local curMapId = expeditionModel:getMapId()
    if curMapId <= 0 then
        UIManager.popUI(1)
    end
end

function UIExpeditionWin:onClose()

end

function UIExpeditionWin:onClick(obj)
    obj:setTouchEnabled(false)
    local btnName = obj:getName()
    if btnName == "ConfirmButtom" then             -- 返回
        local node = CsbTools.getChildFromPath(obj, "ConfirmButtom")
        CommonHelper.playCsbAnimation(node, "OnAnimation", false, function()
            obj:setTouchEnabled(true)
            self:backToScene()
        end)
    end
end

function UIExpeditionWin:backToScene()
    -- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
    -- 释放房间资源
    finishBattle()
    -- 加载大厅场景
    local hasUnion = getGameModel():getUnionModel():getHasUnion()
    if hasUnion then
        -- 有工会进入公会界面
        if SceneManager.PrevScene then
            SceneManager.loadScene(SceneManager.PrevScene)
        else
            SceneManager.loadScene(SceneManager.Scene.SceneUnion)
        end
    else
        -- 没有公会进入主城镇
        SceneManager.loadScene(SceneManager.Scene.SceneHall)
    end
end

return UIExpeditionWin