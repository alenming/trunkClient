--[[
	辅助实现 快速前往英雄, 快速前往道具共同的功能: 初始化快速前往滚动列表
--]]

local UIQuickToHelper = {}

local resCsb = ResConfig.UIHeroQuickTo.Csb2
local stageIconFile = "ui_new/g_gamehall/c_collection/StageBar.csb"
local UILanguage = {touchGo = 157, lock = 164, needPass = 165}
local stageStatus = {hide = 0, lock = 1, unlock = 2, one = 3, two = 4, tri = 5}

-- 获取item大小 -----------------
local stageItemCsb = getResManager():getCsbNode(resCsb.stageItem)
local stageItemSize = CsbTools.getChildFromPath(stageItemCsb, "BarImage"):getContentSize()
local shopItemCsb = getResManager():getCsbNode(resCsb.shopItem)
local shopItemSize = CsbTools.getChildFromPath(shopItemCsb, "BarImage"):getContentSize()

function UIQuickToHelper:reloadScroll(scroll, quickToData)
	--CsbTools.printValue(quickToData, "快速前往数据")
	self.scroll = scroll
	self.quickToInfo = self:formatQuickToData(quickToData)
	self.scroll:removeAllChildren()

	dump(self.quickToInfo)

	local height = (stageItemSize.height + 5) * (#self.quickToInfo.stage)
					+ (shopItemSize.height + 5) * (#self.quickToInfo.other)

	local innerSize = self.scroll:getContentSize()
	if innerSize.height < height then
		innerSize.height = height
	end
	self.scroll:setInnerContainerSize(innerSize)

	local curHeight = 0
	local order = 0

	for _,info in ipairs(self.quickToInfo.other) do
		order = order + 1
		curHeight = curHeight + shopItemSize.height + 5
		local pos = cc.p(0, innerSize.height - curHeight)
		self:addOtherItem(info, pos, order)
	end
	for _, info in ipairs(self.quickToInfo.stage) do
		order = order + 1
		curHeight = curHeight + stageItemSize.height + 5
		local pos = cc.p(0, innerSize.height - curHeight)
		self:addStageItem(info, pos, order)
	end
end

function UIQuickToHelper:formatQuickToData(quickToData)
	-- 获取快速前往关卡的信息 -----------------
	local quickToInfo = {
		stage = {},
		other = {},
	}

	if type(quickToData) == "table" then
		for _,info in ipairs(quickToData) do
			if info[1] == UIManager.UI.UIChallenge then
				if info[2] ~= nil and info[3] ~= nil then
					table.insert(quickToInfo.stage, info)
				end
			elseif info[1] == UIManager.UI.UIShop then
				if info[2] ~= nil then
					table.insert(quickToInfo.other, info)
				end
			elseif info[1] == UIManager.UI.UIDrawCard or
				info[1] == UIManager.UI.UIArena or
				info[1] == UIManager.UI.UICopyChoose or 
				info[1] == UIManager.UI.UIGoldTest or
				info[1] == UIManager.UI.UITowerTest then
				table.insert(quickToInfo.other, info)
			end
		end
	end

	-- 添加排序比重
	for i, info in ipairs(quickToInfo.stage) do
		info.order = i

		-- 关卡状态
		info.type = stageStatus.hide
		if info[3] < 10000 then
			info.type = getGameModel():getStageModel():getComonStageState(info[3])
		else
			info.type = getGameModel():getStageModel():getEliteStageState(info[3])
		end		
	end

	local weight = {
		[stageStatus.tri] = 5, 
		[stageStatus.two] = 5, 
		[stageStatus.one] = 5, 
		[stageStatus.unlock] = 4, 
		[stageStatus.lock] = 3, 
		[stageStatus.hide] = 2, 
	}
	function stageSort(info1, info2)
		if weight[info1.type] > weight[info2.type] then
			return true
		elseif weight[info1.type] == weight[info2.type] then
			if info1.type == stageStatus.tri
				or info1.type == stageStatus.two
				or info1.type == stageStatus.one then
								
				if info2.order > info1.order then
					return true
				end
			else
				if info2.order < info1.order then
					return true
				end
			end
		end
		return false
	end

	table.sort(quickToInfo.stage, stageSort)

	return quickToInfo
end

function UIQuickToHelper:addOtherItem(quickInfo, pos, tag)
	-- 添加item到scroll
	local child = ccui.Button:create()
	child:setScale9Enabled(true)
    child:setContentSize(shopItemSize)
    child:setName("GoToButton")
    CsbTools.initButton(child, handler(self, self.itemCallBack))
	child:setAnchorPoint(cc.p(0, 0))
    self.scroll:addChild(child)

    local csb = getResManager():cloneCsbNode(resCsb.shopItem)
	csb:setPosition(cc.p(shopItemSize.width/2, shopItemSize.height/2))
	child:addChild(csb)

	-- 设置显示属性
	child:setPosition(pos)
	child:setTag(tag)

	local nameLab = CsbTools.getChildFromPath(csb, "StageName")
	local tipsLab = CsbTools.getChildFromPath(csb, "Text_1")
	local descLab = CsbTools.getChildFromPath(csb, "TipsText")
	local iconImg = CsbTools.getChildFromPath(csb, "Image_2")

	if quickInfo[1] == UIManager.UI.UIShop then
		self:initShopItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	elseif quickInfo[1] == UIManager.UI.UIDrawCard then
		self:initDrawCardItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	elseif quickInfo[1] == UIManager.UI.UIArena then
		self:initArenaItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	elseif quickInfo[1] == UIManager.UI.UICopyChoose then
		self:initCopyChooseItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	elseif quickInfo[1] == UIManager.UI.UIGoldTest then
		self:initGoldTestItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	elseif quickInfo[1] == UIManager.UI.UITowerTest then
		self:initTowerTestItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	end
end

function UIQuickToHelper:addStageItem(quickInfo, pos, tag)
	-- 添加item到scroll
	local child = ccui.Button:create()
	child:setScale9Enabled(true)
    child:setContentSize(stageItemSize)
    child:setName("GoToButton")
    CsbTools.initButton(child, handler(self, self.itemCallBack))	
	child:setAnchorPoint(cc.p(0, 0))
    self.scroll:addChild(child)

	local csb = getResManager():cloneCsbNode(resCsb.stageItem)
	csb:setPosition(cc.p(stageItemSize.width/2, stageItemSize.height/2))
	child:addChild(csb)

	-- 设置显示属性
	child:setPosition(pos)
	child:setTag(tag)

	local chaterLab = CsbTools.getChildFromPath(csb, "StageChaterLabel")
	local nameLab = CsbTools.getChildFromPath(csb, "StageName")
	local stageImg = CsbTools.getChildFromPath(csb, "StageBar/StageBarPanel/StageImage")
	local frameImg = CsbTools.getChildFromPath(csb, "StageBar/StageBarPanel/BarImage")
	local tipsLab = CsbTools.getChildFromPath(csb, "Text_1")

	self:initStageItem(quickInfo, chaterLab, nameLab, stageImg, frameImg, tipsLab)	
end

function UIQuickToHelper:initShopItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	local lanID = {
		[ShopType.MysteryShop] = {1300, 157, 1308},
		[ShopType.GoldShop] = {1301, 157, 1309},
		[ShopType.None] = {1302, 157, 1310},
		[ShopType.DiamondShop] = {1303, 157, 1311},
		[ShopType.UnionShop] = {2042, 157, 1312},
	}
	local shopData = getShopConfData()
	for shopID, info in pairs(lanID) do
		if shopData[shopID] then
			info[4] = shopData[shopID].strShopIcon
		end
	end
	
	if lanID[quickInfo[2]] then
		nameLab:setString(CommonHelper.getUIString(lanID[quickInfo[2]][1]))
		tipsLab:setString(CommonHelper.getUIString(lanID[quickInfo[2]][2]))
		descLab:setString(CommonHelper.getUIString(lanID[quickInfo[2]][3]))
		CsbTools.replaceImg(iconImg, lanID[quickInfo[2]][4] or "ui_pnb_storegold.png")
	end
end

function UIQuickToHelper:initDrawCardItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	nameLab:setString(CommonHelper.getUIString(388))
	tipsLab:setString(CommonHelper.getUIString(157))
	descLab:setString(CommonHelper.getUIString(1313))
	CsbTools.replaceImg(iconImg, "icon_button_drawcard.png")
end

function UIQuickToHelper:initArenaItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	nameLab:setString(CommonHelper.getUIString(1314))
	tipsLab:setString(CommonHelper.getUIString(157))
	descLab:setString(CommonHelper.getUIString(1315))
	CsbTools.replaceImg(iconImg, "icon_button_ArenaQuick.png")
end

function UIQuickToHelper:initCopyChooseItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	nameLab:setString(CommonHelper.getUIString(388))
	tipsLab:setString(CommonHelper.getUIString(157))
	descLab:setString(CommonHelper.getUIString(1313))
	CsbTools.replaceImg(iconImg, "icon_button_drawcard.png")
end

function UIQuickToHelper:initGoldTestItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	nameLab:setString(CommonHelper.getUIString(388))
	tipsLab:setString(CommonHelper.getUIString(157))
	descLab:setString(CommonHelper.getUIString(1313))
	CsbTools.replaceImg(iconImg, "icon_button_drawcard.png")
end

function UIQuickToHelper:initTowerTestItem(quickInfo, nameLab, tipsLab, descLab, iconImg)
	nameLab:setString(CommonHelper.getUIString(388))
	tipsLab:setString(CommonHelper.getUIString(157))
	descLab:setString(CommonHelper.getUIString(1313))
	CsbTools.replaceImg(iconImg, "icon_button_drawcard.png")
end

function UIQuickToHelper:initStageItem(quickInfo, chaterLab, nameLab, stageImg, frameImg, tipsLab)
	local chapterConf = getChapterConfItem(quickInfo[2])
	if chapterConf == nil then		
        chaterLab:setString(string.format("chapter %d not find", quickInfo[2]))
		return 
	end

    local stageInfo = chapterConf.Stages[quickInfo[3]]
    if not stageInfo then
        print("no stage in chapter", quickInfo[3], quickInfo[2])
        nameLab:setString(string.format("chapter %d not find stage %d", quickInfo[2], quickInfo[3]))
        return
    end

	if quickInfo[2] > 100 then
		chaterLab:setString(string.format(CommonHelper.getUIString(348), quickInfo[2]-100))
	else
		chaterLab:setString(string.format(CommonHelper.getUIString(78), quickInfo[2]))
	end
	nameLab:setString(CommonHelper.getStageString(stageInfo.Name))
	
	CsbTools.replaceImg(stageImg, stageInfo.Thumbnail)

	if quickInfo.type == stageStatus.one or quickInfo.type == stageStatus.two or quickInfo.type == stageStatus.tri then
		tipsLab:setString(CommonHelper.getUIString(UILanguage.touchGo))
		CommonHelper.removeGray(stageImg)
		CommonHelper.removeGray(frameImg)

	elseif quickInfo.type == stageStatus.unlock then
		tipsLab:setString(CommonHelper.getUIString(UILanguage.needPass))
		CommonHelper.removeGray(stageImg)
		CommonHelper.removeGray(frameImg)

	elseif quickInfo.type == stageStatus.lock then
		local myLv = getGameModel():getUserModel():getUserLevel()
		if myLv >= chapterConf.UnlockLevel then
			tipsLab:setString(CommonHelper.getUIString(UILanguage.needPass))
		else
			tipsLab:setString(string.format(CommonHelper.getUIString(UILanguage.lock), chapterConf.UnlockLevel))
		end
		CommonHelper.applyGray(stageImg)
		CommonHelper.applyGray(frameImg)

	elseif quickInfo.type == stageStatus.hide then
		tipsLab:setString(CommonHelper.getUIString(UILanguage.needPass))
		CommonHelper.applyGray(stageImg)
		CommonHelper.applyGray(frameImg)
	end
end

function UIQuickToHelper:itemCallBack(obj)
	local order = obj:getTag()
    obj.soundId = nil

	local quickInfo = nil
    if order > #self.quickToInfo.other then
    	order = order - #self.quickToInfo.other
    elseif not quickInfo then
    	quickInfo = self.quickToInfo.other[order]
    end

    if order > #self.quickToInfo.stage then
    	order = order - #self.quickToInfo.stage
    elseif not quickInfo then
    	quickInfo = self.quickToInfo.stage[order]
    end

    if not quickInfo then
    	return
    end

    if quickInfo.type == stageStatus.one or 
		quickInfo.type == stageStatus.two or 
		quickInfo.type == stageStatus.tri or
		quickInfo.type == stageStatus.unlock or 
		quickInfo[1] == UIManager.UI.UIShop or
		quickInfo[1] == UIManager.UI.UIDrawCard or
		quickInfo[1] == UIManager.UI.UIArena or
		quickInfo[1] == UIManager.UI.UICopyChoose or 
		quickInfo[1] == UIManager.UI.UIGoldTest or
		quickInfo[1] == UIManager.UI.UITowerTest then
		UIManager.open(table.unpack(quickInfo))
	else
		obj.soundId = MusicManager.commonSound.fail
	end
end

return UIQuickToHelper