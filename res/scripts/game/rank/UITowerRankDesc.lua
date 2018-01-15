--[[
	爬塔排行版描述
--]]

local UITowerRankDesc = class("UITowerRankDesc", require("common.UIView"))

function UITowerRankDesc:ctor()
	self.rootPath = ResConfig.UITowerRankDesc.Csb2.desc
	self.root = getResManager():cloneCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function()
		UIManager.close()
	end)
	-- 确定按钮
	local confirmBtn = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/Button_Confirm")
	CsbTools.initButton(confirmBtn, function()
		UIManager.close()
	end)
	CsbTools.initButton(confirmBtn
		, function()
			UIManager.close()
		end
		, CommonHelper.getUIString(500), "Button_Green/ButtomName", "Button_Green")

	local titleLab = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/BarImage1/TitleText")
	local scroll = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/NoticeScrollView")
	local descLab = CsbTools.getChildFromPath(scroll, "TipText_1")
	local fontName = descLab:getFontName()
	local fontSize = descLab:getFontSize()
	local fontColor = descLab:getTextColor()
	scroll:removeAllChildren()

	local scrollSize = scroll:getContentSize()
	local labSize = cc.size(scrollSize.width - 10, scrollSize.height - 10)
	local offsetX = 5
	local offsetY = 5

	local newDescLab = cc.Label:createWithTTF(
		CommonHelper.getUIString(1376),
		fontName,
		fontSize)
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
	titleLab:setString(CommonHelper.getUIString(1375))
end

return UITowerRankDesc