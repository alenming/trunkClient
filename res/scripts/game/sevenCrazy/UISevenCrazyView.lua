--[[
	UIEquipMake 装备打造界面

]]

-- csb文件
local csbFile = ResConfig.UISevenCrazy.Csb2

local SevenCrazyModel = getGameModel():getSevenCrazyModel()
local PropTips = require("game.comm.PropTips")
local UISevenCrazyView = class("UISevenCrazyView", function()
		return require("common.UIView").new()
	end)

local nameId = {1283,1284,1285}

function UISevenCrazyView:ctor()
	self.rootPath	= csbFile.view
	self.root   	= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- --退出按钮
    self.mTouchPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
   

	self.mScrollView = CsbTools.getChildFromPath(self.root, "MainPanel/OperatePanel/TaskScrollView")
	self.mScrollView:setScrollBarEnabled(false)
	self.mScrollView:removeAllChildren()

	self.mGoldInfo = CsbTools.getChildFromPath(self.root, "GoldInfo/GoldPanel/GoldCountLabel")
	self.mGemInfo = CsbTools.getChildFromPath(self.root, "GemInfo/GemPanel/GemCountLabel")

	self.mTaskItemSize = {width = 515, height= 180}


end

function UISevenCrazyView:onOpen(preId,day)
	self.mDay = day

    self.propTips = PropTips.new()
 	self:initUI()
 	self:initCommonUI()
 	
end

function UISevenCrazyView:onClose()
	if self.propTips then
        self.propTips:removePropAllTips()
        self.propTips = nil
    end
end

function UISevenCrazyView:onTop()
end

--------------- 界面初始化----------------------
function UISevenCrazyView:initUI()
	local toDayData = SevenCrazyModel:getSevenDayConfByDay(self.mDay)

	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5
	local hang = 3
	local innerSize = self.mScrollView:getContentSize()

	local h = offsetY + hang*self.mTaskItemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end
    if self.mScrollView:getInnerContainerSize().height ~= innerSize.height then
	    self.mScrollView:setInnerContainerSize(innerSize)
    end  
	self.mScrollView:removeAllChildren()

	for i=1,3 do
		local data = toDayData["ForeGoods"..i]
		local itemCsb = getResManager():cloneCsbNode(csbFile.AwardItem)

		self:initItem(itemCsb, data, i)
		local posX = offsetX + self.mTaskItemSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mTaskItemSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX,posY))
		self.mScrollView:addChild(itemCsb)
	end
end


function UISevenCrazyView:initItem(csbItem, info, index)

	local title = CsbTools.getChildFromPath(csbItem, "Panel_1/LogoText")
	dump(info)
	title:setString(CommonHelper.getUIString(nameId[index]))
	for i=1,4 do
		local item = CsbTools.getChildFromPath(csbItem, "Panel_1/AllItem_"..i)
		local text = CsbTools.getChildFromPath(csbItem, "Panel_1/Name_"..i)
		if i>#info then
			item:setVisible(false)
			text:setVisible(false)
		else
			item:setVisible(true)
			text:setVisible(true)
			print("info[i]", i, info[i])
			local propConf = getPropConfItem(info[i])
			dump(propConf)
			if propConf.Type == 3 or propConf.Type == 4 then
				text:setString(CommonHelper.getHSString(propConf.Name))
			else
				text:setString(CommonHelper.getPropString(propConf.Name))
			end
			
	        if propConf then
	            UIAwardHelper.setAllItemOfConf(item, propConf, 0)
	            local touchPanel = getChild(item, "MainPanel")
	        	self.propTips:addPropTips(touchPanel, propConf)
	        end
		end
	end
end

function UISevenCrazyView:onOpenAniOver()
	CsbTools.initButton(self.mTouchPanel , handler(self, self.backBtnCallBack))
end


function UISevenCrazyView:initCommonUI()
	local gold   = getGameModel():getUserModel():getGold()
	local gem = getGameModel():getUserModel():getDiamond()

	self.mGoldInfo:setString(gold)
	self.mGemInfo:setString(gem)
end

-- 返回
function UISevenCrazyView:backBtnCallBack(ref)
	UIManager.close()
end



return UISevenCrazyView