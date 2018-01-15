--[[
竞技场回放结算界面
]]

local UIReplayAccount = class("UIReplayAccount", function ()
	return require("common.UIView").new()
end)

function UIReplayAccount:ctor()
    self:setGlobalZOrder(5)
	self:setLocalZOrder(5)

    self.rootPath = ResConfig.UIReplayAccount.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    
    -- 获取左右双方的ui节点
    self.leftUserUI = self:getUserUINode(true)
    self.rightUserUI = self:getUserUINode(false)

    -- 返回和重播按钮
    local backBtn = CsbTools.getChildFromPath(self.root, "MainPanel/CloseButton")
    CsbTools.initButton(backBtn, handler(self, self.backCallBack), CommonHelper.getUIString(2172))
    local replayBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ReplayButton")
    CsbTools.initButton(replayBtn, handler(self, self.replayCallBack), CommonHelper.getUIString(2177))
end

function UIReplayAccount:onOpen(fromUI, resultData)
    
    self:setUserUINodeData(true)
    self:setUserUINodeData(false)
end

function UIReplayAccount:onClose()
    
end

function UIReplayAccount:getUserUINode(isLeft)
    local s = isLeft and "L" or "R"
    local resultBar = CsbTools.getChildFromPath(self.root, "MainPanel/RepalyPanel/ResultBar_"..s)
    local userPanel = CsbTools.getChildFromPath(self.root, "MainPanel/RepalyPanel/UserPanel_"..s)

    local userUINode = {}
    userUINode.summoner = CsbTools.getChildFromPath(resultBar, "Summoner")
    userUINode.winOrFail = CsbTools.getChildFromPath(resultBar, "WinOrFailed")

    userUINode.userName = CsbTools.getChildFromPath(userPanel, "UserName")
    userUINode.unionName = CsbTools.getChildFromPath(userPanel, "GuildName")
    --CsbTools.getChildFromPath(userPanel, "Image_Level")
    userUINode.head = CsbTools.getChildFromPath(userPanel, "Image_Icon")
    userUINode.lv = CsbTools.getChildFromPath(userPanel, "Level")

    return userUINode
end

function UIReplayAccount:setUserUINodeData(isLeft, resultData)
    local userUINode = isLeft and self.leftUserUI or self.rightUserUI
    userUINode.userName:setString("user")
    userUINode.unionName:setString("union")
    --userUINode.head:setTexture()
    userUINode.lv:setString("hll")
    userUINode.summoner:removeAllChildren()

--    local summonerCsbPath = "ui_new/g_gamehall/r_replay/Summoner/"..SummonerId.."_"..(isLeft and "L" or "R")..".csb"
--    local summonerCsb = getResManager():getCsbNode(summonerCsbPath)
--    userUINode.summoner:addChild(summonerCsb)
    --userUINode.winOrFail:setTexture()
end

function UIReplayAccount:backCallBack(obj)
    -- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
    finishBattle()
	-- 如果不是从登录场景进入, 就进入上个场景, 否则加载大厅场景
	if SceneManager.PrevScene ~= nil and SceneManager.PrevScene ~= SceneManager.Scene.SceneLogin then
	    SceneManager.loadScene(SceneManager.PrevScene)
	else
	    SceneManager.loadScene(SceneManager.Scene.SceneHall)
	end 
end

function UIReplayAccount:replayCallBack(obj)
    replayAgain()
    UIManager.close()
end

return UIReplayAccount