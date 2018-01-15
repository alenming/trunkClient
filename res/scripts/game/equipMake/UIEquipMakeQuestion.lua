--[[
	UIEquipMake 装备打造界面

]]

-- csb文件
local csbFile = ResConfig.UIEquipMake.Csb2
local AttriBar = "ui_new/g_gamehall/b_bag/AttriBar.csb"

local equipMakeModel = getGameModel():getEquipMakeModel()

local UIEquipMakeQuestion = class("UIEquipMakeQuestion", function()
		return require("common.UIView").new()
	end)

function UIEquipMakeQuestion:ctor()
	self.rootPath	= csbFile.QuestionPanel
	self.root   	= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- 关闭按钮
    local touchPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    CsbTools.initButton(touchPanel, handler(self, self.onClick))

    self.mText = CsbTools.getChildFromPath(self.root, "MainPanel/TipLabel")
    self.mSize = CsbTools.getChildFromPath(self.root, "MainPanel/BarImage"):getContentSize()
    self.fontName = self.mText:getFontName()
    self.fontSize = self.mText:getFontSize()
    self.fontColor = self.mText:getTextColor()
    self:initUI()
end

function UIEquipMakeQuestion:onOpen()

end

function UIEquipMakeQuestion:onClose()
end

function UIEquipMakeQuestion:onTop()
end

--------------- 界面初始化----------------------
function UIEquipMakeQuestion:initUI()
	self.mText:setVisible(false)

    local labSize = cc.size(self.mSize.width - 10, self.mSize.height - 10)
    
    local newDescLab = cc.Label:createWithTTF(CommonHelper.getUIString(1248), self.fontName, self.fontSize)
    newDescLab:setTextColor(self.fontColor)
    newDescLab:setClipMarginEnabled(false)
    --newDescLab:setAnchorPoint(cc.p(0,1))
    newDescLab:setMaxLineWidth(labSize.width)
    newDescLab:setVerticalAlignment(1)

    newDescLab:setPosition(self.mText:getPosition())

    CsbTools.getChildFromPath(self.root, "MainPanel"):addChild(newDescLab)
end

function UIEquipMakeQuestion:onClick(obj)
    local name = obj:getName()
    if "MainPanel" == name then
        UIManager.close()
    end
end



return UIEquipMakeQuestion