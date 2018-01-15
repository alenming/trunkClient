local gameModel = getGameModel()
local pvpModel = gameModel:getPvpModel()

local UIArenaRule = class("UIArenaRule", function () 
	return require("common.UIView").new()
end)

function UIArenaRule:init()
	self.rootPath = ResConfig.UIArena.Csb2.arenaRule
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    CommonHelper.layoutNode(self.root) -- 自适应

    self.closeBtn = CsbTools.getChildFromPath(self.root, "MainPanel/Button_Close")
    CsbTools.initButton(self.closeBtn, function ()
        UIManager.close()
    end)

    -- 规则标题
    CsbTools.getChildFromPath(self.root, "MainPanel/RuleFontLabel")
        :setString(CommonHelper.getUIString(1032))

   	self:setRank()

    self:setRuleContent(CommonHelper.getUIString(1710))
end

-- 排名
function UIArenaRule:setRank()
	local pvpInfo = pvpModel:getPvpInfo()

	local historyRank = CsbTools.getChildFromPath(self.root, "MainPanel/Num1")
	historyRank:setString(pvpInfo.HistoryRank)

	local currentRank = CsbTools.getChildFromPath(self.root, "MainPanel/Num2")	
	currentRank:setString(pvpInfo.Rank)
end

-- 规则内容
function UIArenaRule:setRuleContent(ruleConent)
    local scroll = CsbTools.getChildFromPath(self.root, "MainPanel/ScrollView")
    scroll:setScrollBarEnabled(false)
    local descLab = CsbTools.getChildFromPath(scroll, "RuleIntroText")
    local fontName = descLab:getFontName()
    local fontSize = descLab:getFontSize()
    local fontColor = descLab:getTextColor()
    scroll:removeAllChildren()
    
    local scrollSize = scroll:getContentSize()
    local labSize = cc.size(scrollSize.width - 10, scrollSize.height - 10)
    local offsetX = 5
    local offsetY = 5
    
    local newDescLab = cc.Label:createWithTTF(ruleConent, fontName, fontSize)
    newDescLab:setTextColor(fontColor)
    newDescLab:setClipMarginEnabled(false)
    newDescLab:setAnchorPoint(cc.p(0,1))
    newDescLab:setMaxLineWidth(labSize.width)
    newDescLab:setVerticalAlignment(1)
    scroll:addChild(newDescLab)
    
    local newDescSize = newDescLab:getContentSize()
    local innerSize = scrollSize
    if innerSize.height < newDescSize.height + 2*offsetY then
        innerSize.height = newDescSize.height + 2*offsetY
    end
    newDescLab:setPosition(cc.p(offsetX, innerSize.height - offsetY))
    
    scroll:setInnerContainerSize(innerSize)
end


return UIArenaRule