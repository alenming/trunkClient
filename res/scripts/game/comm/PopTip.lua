----------------------弹出文字提示--------------------
local PopTip = class("PopTip", function()
    return display.newLayer("PopTip")
end)

--[[ 传入参数，支持BMFont和普通Label
- 	params 参数:
-    text: 要显示的文本
-    font: fnt字体文件名或ttf字体名或ttf字体文件名
-	 animate: 动画类型，值为1、2、3...（默认为1）
包含以下动画类型：
	1 停留-移动-淡出效果
	停留delayTime（默认1.5）秒、
	在moveTime（默认0.3）秒中偏移offsetX（默认0）和offsetY（默认60）像素、
	淡出fadeOutTime（默认0.3）、并移除自己
	2 放大-缩小-移动-淡出效果
	在scaleTime1（默认0.2）秒中缩放到scale1（默认1.2）、
	在scaleTime2（默认0.2）秒中缩放到scale2（默认1）、
	在moveTime（默认0.3）秒中偏移offsetX（默认0）和offsetY（默认60）像素、
	淡出fadeOutTime（默认0.3）、并移除自己
----------------------------------------------------------------------
-	BMFont可选参数：
-    align: 文字的水平对齐方式
-    x, y: 坐标
----------------------------------------------------------------------
-	Label可选参数：
-    size: 文字尺寸，因为是 TTF 字体，所以可以任意指定尺寸
-    color: 文字颜色（可选），用 cc.c3b() 指定，默认为白色
-    align: 文字的水平对齐方式（可选）
-    valign: 文字的垂直对齐方式（可选），仅在指定了 dimensions 参数时有效
-    dimensions: 文字显示对象的尺寸（可选），使用 cc.size() 指定
-    x, y: 坐标（可选）
align 和 valign 参数可用的值：
-    cc.ui.TEXT_ALIGN_LEFT 左对齐
-    cc.ui.TEXT_ALIGN_CENTER 水平居中对齐
-    cc.ui.TEXT_ALIGN_RIGHT 右对齐
-    cc.ui.TEXT_VALIGN_TOP 垂直顶部对齐
-    cc.ui.TEXT_VALIGN_CENTER 垂直居中对齐
-    cc.ui.TEXT_VALIGN_BOTTOM 垂直底部对齐
----------------------------------------------------------------------
-	 UILabelType: 1为BMFont、2为TTF，默认自动为2（该字段由PopTip自动填写）
包含以下类型：
- 	  UILabel.LABEL_TYPE_BM = 1
-	  UILabel.LABEL_TYPE_TTF = 2
]]
function PopTip:ctor(params)
    self:setPosition(params.x or 0, params.y or 0)
    params.x = 0
    params.y = 0

	-- 自动识别
	if params and params.font and nil ~= string.find(params.font, "%.fnt") then
		params.UILabelType = UILabel.LABEL_TYPE_BM
	end
	self:removeAllChildren()
	local label = cc.ui.UILabel.new(params)
	label:setAnchorPoint(0.5, 0.5)
	self:addChild(label, 10)
	label:setDimensions(0,0)

    -- 增加黑底
    local labSize = label:getContentSize()
    local bgSprite = ccui.Scale9Sprite:createWithSpriteFrameName("chat_blackbg.png", cc.rect(17, 20, 1, 1))
    bgSprite:setContentSize(cc.size(labSize.width + 10, labSize.height + 10))
    bgSprite:setPosition(labSize.width/2, labSize.height/2)
    label:addChild(bgSprite, -1)

	local animateFunc = "animate1"
	if params.animate then
		animateFunc = "animate" .. params.animate
	end
	if type(PopTip[animateFunc]) == "function" then
		PopTip[animateFunc](self, params)
	end
end

function PopTip.animate1(node, params)
	if nil == params then
		params = {}
	end

	local delayTime = params.delayTime or 1.5
	local moveTime = params.moveTime or 1
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 60
	local fadeOutTime = params.fadeOutTime or 1

	local actWait = cc.DelayTime:create(delayTime)
	local actMove = cc.MoveBy:create(moveTime, cc.p(offsetX, offsetY))
	local actHide = cc.FadeOut:create(fadeOutTime)
	local actRemove = cc.CallFunc:create(function () node:removeFromParent() end)
	node:setCascadeOpacityEnabled(true)
	node:runAction(cc.Sequence:create(actWait, actMove, actRemove))
	node:runAction(cc.Sequence:create(cc.DelayTime:create(delayTime), actHide))
end

function PopTip.animate2(node, params)
	if nil == params then
		params = {}
	end

	local moveTime = params.moveTime or 0.3
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 60
	local fadeOutTime = params.fadeOutTime or 0.3

	local scale1 = params.scale1 or 1.2
	local scaleTime1 = params.scaleTime1 or 0.2
	local scale2 = params.scale2 or 1
	local scaleTime2 = params.scaleTime2 or 0.2

    local posX, posY = node:getPosition()
	node:setPosition(0 + posX, -offsetY + posY)
	node:setScale(0)
	
	local actScale1 = cc.ScaleTo:create(scaleTime1, scale1)
	local actScale2 = cc.ScaleTo:create(scaleTime2, scale2)

	local actMove = cc.MoveBy:create(moveTime, cc.p(offsetX, offsetY))
	local actHide = cc.FadeOut:create(fadeOutTime)
	local actRemove = cc.CallFunc:create(function () node:removeFromParent() end)
	local actSeq = cc.Sequence:create(cc.Spawn:create(actMove, actHide), actRemove)
	node:setCascadeOpacityEnabled(true)
	node:runAction(cc.Sequence:create(actScale1, actScale1, actSeq))
end

return PopTip