--[[
	公会主界面
	1. 显示公会建筑物
--]]

local UIUnionMercenaryRule = class("UIUnionMercenaryRule", function ()
	return require("common.UIView").new()
end)

function UIUnionMercenaryRule:ctor()
	self.rootPath = ResConfig.UIUnionMercenaryRule.Csb2.GeneralRule
	self.root = getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mSv = CsbTools.getChildFromPath(self.root, "MainPanel/TextScrollView")
	local textLabel = CsbTools.getChildFromPath(self.root, "MainPanel/TextScrollView/RuleIntroText")
    self.fontName = textLabel:getFontName()
    self.fontSize = textLabel:getFontSize()
    self.fontColor = textLabel:getTextColor()

	self.mBackBtn = CsbTools.getChildFromPath(self.root, "MainPanel/Button_Close")
	CsbTools.initButton(self.mBackBtn, handler(self, self.backBtnCallback), nil, nil, "mBackBtn")
end

function UIUnionMercenaryRule:initScrollViewText(conent)
    self.mSv:removeAllChildren()
    
    local scrollSize = self.mSv:getContentSize()
    local labSize = cc.size(scrollSize.width - 10, scrollSize.height - 10)
    local offsetX = 5
    local offsetY = 5
    
    local newDescLab = cc.Label:createWithTTF(conent, self.fontName, self.fontSize)
    newDescLab:setTextColor(self.fontColor)
    newDescLab:setClipMarginEnabled(false)
    newDescLab:setAnchorPoint(cc.p(0,1))
    newDescLab:setMaxLineWidth(labSize.width)
    newDescLab:setVerticalAlignment(1)
    self.mSv:addChild(newDescLab)
    
    local newDescSize = newDescLab:getContentSize()
    local innerSize = scrollSize
    if innerSize.height < newDescSize.height + 2*offsetY then
        innerSize.height = newDescSize.height + 2*offsetY
    end
    newDescLab:setPosition(cc.p(offsetX, innerSize.height - offsetY))
    self.mSv:setInnerContainerSize(innerSize)
end

function UIUnionMercenaryRule:onOpen(_, conent)
    self:initScrollViewText(conent)
end

function UIUnionMercenaryRule:onClose()
	
end

function UIUnionMercenaryRule:backBtnCallback(obj)
	UIManager.close()
end

return UIUnionMercenaryRule