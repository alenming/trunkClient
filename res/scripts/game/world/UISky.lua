------------------------------
-- 名称：UISky
-- 描述：世界地图界面的天空层
-- 日期：2017/2/22
-- 作者：尚志
------------------------------

local UISky = class("UISky", function ()
	return require("common.UIView").new()
end)

local FADEOUT_TIME = 0.25  -- 天空的淡出时间

function UISky:init()
	
end

-- 设置章节，应该在切换章节时调用。
function UISky:setChapter(chapterId)
	self.rootPath = "ui_new/w_worldmap/map/Sky_" .. chapterId .. ".csb"

	if self.root then
		local nextRoot = self:createCsbNode(-1)
		self:addChild(nextRoot)

		self.root:stopAllActions()
        self.root:runAction(cc.Sequence:create(
        	cc.FadeOut:create(FADEOUT_TIME),
        	cc.CallFunc:create(function() 
        		nextRoot:setLocalZOrder(0)
        		self.root:removeFromParent(true)
        		self.root = nextRoot
        	end)
        ))
	else
		self.root = self:createCsbNode()
		self:addChild(self.root)
	end
end

-- 创建天空层的csb节点，并设置大小、ZOrder等。
function UISky:createCsbNode(zOrder)
	zOrder = zOrder or 0

	local node = cc.CSLoader:createNode(self.rootPath)
	if node then
		node:setContentSize(display.width, display.height)
		node:setLocalZOrder(zOrder)
		ccui.Helper:doLayout(node)

		return node
	else
		print("create CSB node " .. self.rootPath .. " failed")
	end
end

return UISky