--[[
	UIView UIManager所管理的界面需要继承该类
	定义了init方法，用于重复初始化
	定义了root和rootPath，用于自动播放动画

	2015-11-3 By 宝爷
]]

local UIView = class("UIView", function()
    return display.newLayer("UIView")
end)

-- 当界面被创建时回调
-- 只初始化一次
function UIView:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIView:onOpen(openerUIID, ...)
end

-- 每次界面Open动画播放完毕时回调
function UIView:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIView:onClose()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIView:onTop(preUIID, ...)

end

function UIView:getRoot()
	return self.root
end

function UIView:getRootPath()
	return self.rootPath
end

return UIView