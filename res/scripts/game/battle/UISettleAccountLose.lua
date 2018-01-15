--[[
结算失败界面
]]

local UISettleAccountLose = class("UISettleAccountLose", function()
	return require("common.UIView").new()
end)

function UISettleAccountLose:ctor()
	--配表文字
	local okText = CommonHelper.getUIString(500)
	--失败界面节点
	self.loseNode = getResManager():getCsbNode(ResConfig.UISettleAccountLose.Csb2.fail)
	self.loseNodeAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountLose.Csb2.fail)
	self.loseNode:runAction(self.loseNodeAct)
	self.tipTex = CsbTools.getChildFromPath(self.loseNode, "MainPanel/TipTex")
	self.loseOkBtn = CsbTools.getChildFromPath(self.loseNode, "MainPanel/ConfirmButtom")
	self.loseOkBtnSub = CsbTools.getChildFromPath(self.loseNode, "MainPanel/ConfirmButtom/ConfirmButtom")
	self.loseOkBtnAct = cc.CSLoader:createTimeline(ResConfig.UISettleAccountLose.Csb2.okBtn)
	self.loseOkBtnSub:runAction(self.loseOkBtnAct)
	CsbTools.getChildFromPath(self.loseOkBtnSub, "NameLabel"):setString(okText)

    self.loseOkBtn:addTouchEventListener(handler(self, self.loseOkButtonDown))
    self:addChild(self.loseNode)

    self:setGlobalZOrder(5)
	self:setLocalZOrder(5)
    CommonHelper.layoutNode(self.loseNode)
end

function UISettleAccountLose:onOpen()
	self.loseNode:setVisible(true)
	self.loseNodeAct:play("Open", false)
end

function UISettleAccountLose:onClose()

end

--失败界面"确定"按钮回调
function UISettleAccountLose:loseOkButtonDown(obj, touchType)
	if touchType == 0 then --开始点击
		self.loseOkBtnAct:play("OnAnimation", false)
	elseif touchType == 2 then --结束点击
		self.loseOkBtnAct:play("Normal", false)
		--跳转到世界地图或者大厅
		self:backToScene()
	elseif touchType == 3 then --取消点击
		self.loseOkBtnAct:play("Normal", false)
	end
end

function UISettleAccountLose:backToScene()	
	-- 战斗结束后可以弹出结算界面，最后再离开游戏，注意清理C++战斗层，以避免内存泄露
    -- 释放房间资源
    finishBattle()
	-- 加载大厅场景
	if SceneManager.PrevScene then
		SceneManager.loadScene(SceneManager.PrevScene)
	else
		SceneManager.loadScene(SceneManager.Scene.SceneHall)
	end
end

return UISettleAccountLose
