--[[
	奖励界面，主要实现以下内容
	1. 显示奖励
	注意: 该界面不处理对奖励的模型增加和删除, 请在调用该界面的地方自行处理 (因为可能会有背包满了放入邮件的情况)
	
	参数
	awards = {
			dropInfo = {{id = 1, num = 1}, ...}
	}
--]]

local UIAward = class("UIAward", require("common.UIView"))
local scheduler = require("framework.scheduler")
local PropTips = require("game.comm.PropTips")

local resCsb = ResConfig.UIAward.Csb2
local blinkFile = "ui_new/g_gamehall/t_task/AwardName.csb"
local rotateFile = "ui_new/g_gamehall/t_task/AwardRayLight.csb"

function UIAward:ctor()
    self.items = {}			-- 已存在的item
    self.itemsCache = {}	-- 缓存item

    -- csb节点信息
    self.rootPath = resCsb.award
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 标题
    self.title = CsbTools.getChildFromPath(self.root, "AwardPanel/HDJLFontLabel")

    -- 确认按钮
    self.confirmBtn = CsbTools.getChildFromPath(self.root, "AwardPanel/ConfirmButtom")
    CsbTools.initButton(self.confirmBtn, function ()
        UIManager.close()
    end, CommonHelper.getUIString(500), "ConfirmButtom/NameLabel", "ConfirmButtom")

    -- 滚动列表
    self.scroll = CsbTools.getChildFromPath(self.root, "AwardPanel/AwardScrollView")
    self.scroll:removeAllChildren()
    self.scrollSize = self.scroll:getContentSize()
    local itemCsb = getResManager():getCsbNode(resCsb.item)
    local itemLayout = CsbTools.getChildFromPath(itemCsb, "AwardItemPanel")
    self.itemSize = itemLayout:getContentSize()
    itemCsb:cleanup()

    self:setNodeEventEnabled(true) -- 开启调用onExit()
end

function UIAward:onOpen(preUIID, awards, title)
	self.propTips = PropTips.new()

    self:setTitle(title)
    self:showAward(awards)
end

function UIAward:onExit()
	self.propTips:removePropAllTips()
	self.propTips = nil

	-- 关闭刷新函数
	if self.updateFunc then
		scheduler.unscheduleGlobal(self.updateFunc)
		self.updateFunc = nil
	end

	-- 缓存奖励csb
	for _, itemCsb in pairs(self.items) do
		table.insert(self.itemsCache, itemCsb)
		itemCsb:setVisible(false)
    end
    self.items = {}
end

-- 设置标题
function UIAward:setTitle(title)
    if not title then
        title = CommonHelper.getUIString(1502)
    end
    self.title:setString(title)
end

function UIAward:showAward(awards)
	local hang = math.modf((#awards - 1)/4) + 1
	local innerSize = self.scroll:getContentSize()
	if self.itemSize.height*hang > innerSize.height then
		innerSize.height = self.itemSize.height*hang 
	end

	self.scroll:setInnerContainerSize(innerSize)
	local curCount = 0	-- 当前显示的个数
	self.updateFunc = scheduler.scheduleGlobal(function(dt)
		curCount = curCount + 1
		if curCount <= #awards then
		    local itemInfo = awards[curCount]
		    local row = math.modf((curCount - 1) / 4) + 1
		    local cols = math.modf((curCount - 1) % 4) + 1
		    local posX = self.itemSize.width * cols + 25
		    local posY = innerSize.height - self.itemSize.height*(row - 0.5)
		    self:addItem(itemInfo, cc.p(posX, posY))
		elseif curCount > #awards then
            EventManager:raiseEvent(GameEvents.EventUserUpgradeUI)
			scheduler.unscheduleGlobal(self.updateFunc)
			self.updateFunc = nil
		end
	end, 0.2)
end

function UIAward:resetScrollSize(awards)
	-- 计算奖励个数
	local awardCount = 0
	for type, value in pairs(awards) do
		awardCount = awardCount + #value
	end

	local hang = math.modf((awardCount - 1)/4) + 1
	local innerSize = self.scroll:getContentSize()
	if self.itemSize.height*hang  > innerSize.height then
		innerSize.height = self.itemSize.height*hang 
	end
	self.scroll:setInnerContainerSize(innerSize)

	return innerSize
end

function UIAward:addItem(info, pos)
	-- 创建Csb,并添加
	local itemCsb = nil
	if #self.itemsCache ~= 0 then
		itemCsb = self.itemsCache[1]
		table.remove(self.itemsCache, 1)
		itemCsb:setVisible(true)
	else
		itemCsb = getResManager():cloneCsbNode(resCsb.item)
		self.scroll:addChild(itemCsb)
		local itemLayout = CsbTools.getChildFromPath(itemCsb, "AwardItemPanel")
		itemLayout:setSwallowTouches(false)
	end
	table.insert(self.items, itemCsb)
	itemCsb:setPosition(pos)
	-- Csb节点
	local blinkCsb = CsbTools.getChildFromPath(itemCsb, "AwardItemPanel/AwardName")
	local awardCsb = CsbTools.getChildFromPath(itemCsb, "AwardItemPanel/AwardItem")
	local rotateCsb = CsbTools.getChildFromPath(blinkCsb, "AwardNamePanel/AwardRayLight")
	local awardName = CsbTools.getChildFromPath(blinkCsb, "AwardNamePanel/AwardName")
	local touchNode = CsbTools.getChildFromPath(awardCsb, "MainPanel")

	local propConf = getPropConfItem(info.id)
	if not propConf then return end
	UIAwardHelper.setAllItemOfConf(awardCsb, propConf, info.num)
	self.propTips:addPropTips(touchNode, propConf)

	if propConf.Type == UIAwardHelper.ItemType.HeroCard or
		propConf.Type == UIAwardHelper.ItemType.SummonerCard then
		awardName:setString(CommonHelper.getHSString(propConf.Name))
	else
		awardName:setString(CommonHelper.getPropString(propConf.Name))
	end
	
	-- 播放动画
	CommonHelper.playCsbAnimate(itemCsb, resCsb.item, "Appear", false, nil, true)
	CommonHelper.playCsbAnimate(rotateCsb, rotateFile, "Animation", true, nil, true)
	local actNames = {"Wood", "Green", "Blue", "Voilet", "Golden", "Orange", "White"}
	CommonHelper.playCsbAnimate(blinkCsb, blinkFile, actNames[propConf.Quality], true, nil, true)
	return itemCsb
end

return UIAward