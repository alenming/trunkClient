--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-11-09 16:18
** 版  本:	1.0
** 描  述:  爬塔试炼规则说明
** 应  用:
********************************************************************/
--]]

local UITowerTestRule = class("UITowerTestRule", function ()
	return require("common.UIView").new()
end)

function UITowerTestRule:ctor()
	self.rootPath = ResConfig.UITowerTestRule.Csb2.main
	self.root = getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

    local backButton = getChild(self.root, "BackButton")
    CsbTools.initButton(backButton, handler(self, self.onClick))

    self.mTitle = getChild(self.root, "MainPanel/MovePanel/TitleFontLabel")

    self.scrollview = getChild(self.root, "MainPanel/MovePanel/RuleIntroScrollView")
    self.scrollview:setScrollBarEnabled(false)
    local textLabel = CsbTools.getChildFromPath(self.scrollview, "RuleIntroText")
    self.fontName = textLabel:getFontName()
    self.fontSize = textLabel:getFontSize()
    self.fontColor = textLabel:getTextColor()
end

function UITowerTestRule:initScrollViewText(conent)
    self.scrollview:removeAllChildren()

    local scrollSize = self.scrollview:getContentSize()
    local labSize = cc.size(scrollSize.width - 10, scrollSize.height - 10)
    local offsetX = 5
    local offsetY = 5
    
    local newDescLab = cc.Label:createWithTTF(conent, self.fontName, self.fontSize)
    newDescLab:setTextColor(self.fontColor)
    newDescLab:setClipMarginEnabled(false)
    newDescLab:setAnchorPoint(cc.p(0,1))
    newDescLab:setMaxLineWidth(labSize.width)
    newDescLab:setVerticalAlignment(1)
    self.scrollview:addChild(newDescLab)
    
    local newDescSize = newDescLab:getContentSize()
    local innerSize = scrollSize
    if innerSize.height < newDescSize.height + 2*offsetY then
        innerSize.height = newDescSize.height + 2*offsetY
    end
    newDescLab:setPosition(cc.p(offsetX, innerSize.height - offsetY))
    self.scrollview:setInnerContainerSize(innerSize)
end

function UITowerTestRule:onOpen(_, conent, titileconent)
    self:initScrollViewText(conent)
    if titileconent then
        self.mTitle:setString(titileconent)
    end
end

function UITowerTestRule:onClose()
	
end

function UITowerTestRule:onClick(obj)
    local btnName = obj:getName()
    if btnName == "BackButton" then             -- 返回
        UIManager.close()
    end
end

function UITowerTestRule:backBtnCallback(obj)
	UIManager.close()
end

return UITowerTestRule