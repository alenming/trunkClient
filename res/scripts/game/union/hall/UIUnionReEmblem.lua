--[[
	公会主界面
	1. 显示公会建筑物
--]]

local UIUnionReEmblem = class("UIUnionReEmblem", function ()
	return require("common.UIView").new()
end)

-- csb文件
local csbFile = ResConfig.UIUnionReEmblem.Csb2

local unionModel = getGameModel():getUnionModel()

function UIUnionReEmblem:ctor()
	self.rootPath = csbFile.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 是否将界面刷新出来过, 有的话可以不用再次设置scroll
	self.hasRfresh = false

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function ()
		UIManager.close()
	end)

	-- 滚动列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/GuildPanel/LogoScrollView")
	self.scroll:removeAllChildren()
    self.scroll:setScrollBarEnabled(false)

	-- 单个成员列表的大小
	local itemCsb 	= getResManager():getCsbNode(csbFile.emblem)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb, "Logo"):getContentSize()
    itemCsb:cleanup()

	-- 一次性添加会徽到滚动列表	
	local emblemConf = getUnionBadgeConfItem()
	-- 计算会徽个数
	local emblemCount = 0
	for k, v in pairs(emblemConf) do
		emblemCount = emblemCount + 1
	end

	-- 计算innerSize
	local innerSize = self.scroll:getContentSize()
	local height = math.ceil(emblemCount/7) * (self.itemSize.height + 2)
	if height > innerSize.height then
		innerSize.height = height
	end
	self.scroll:setInnerContainerSize(innerSize)
	
	local hang = 1
	local lie = 1
	for id, imgFile in pairs(emblemConf) do
		if hang > 7 then
			hang = 1
			lie = lie + 1
		end

		local posX = (hang - 0.5) * (self.itemSize.width + 2)
		local posY = innerSize.height - (lie - 0.5) * (self.itemSize.height + 2)
		self:addItem(id, imgFile, cc.p(posX, posY))

		hang = hang + 1
	end
end

function UIUnionReEmblem:onOpen()
	local unionEmblem = unionModel:getEmblem()

	-- 服务器回调监听
	local cmdEmblem = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionEmblemSC)
	self.emblemHandler = handler(self, self.onEmblem)
	NetHelper.setResponeHandler(cmdEmblem, self.emblemHandler)

	if self.hasRfresh then
		return
	end

	if unionEmblem ~= 0 then		
		self.hasRfresh = true
	end
end

function UIUnionReEmblem:onClose()
	-- 取消监听
	local cmdEmblem = NetHelper.makeCommand(MainProtocol.Union, UnionProtocol.UnionEmblemSC)	
	NetHelper.removeResponeHandler(cmdEmblem, self.emblemHandler)
end

function UIUnionReEmblem:addItem(id, imgFile, pos)
	item = ccui.Button:create()
	item:setTouchEnabled(true)
	item:setScale9Enabled(true)
	item:setContentSize(self.itemSize)
	CsbTools.initButton(item, handler(self, self.emblemCallBack))
	self.scroll:addChild(item)

	local itemCsb 	= getResManager():cloneCsbNode(csbFile.emblem)
	itemCsb:setTag(10086)
	itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
	item:addChild(itemCsb)

	local emblemSpr = CsbTools.getChildFromPath(itemCsb, "Logo/Logo")
	CsbTools.getChildFromPath(itemCsb, "Logo"):setTouchEnabled(false)

	item:setTag(id)
	CsbTools.replaceSprite(emblemSpr, imgFile)
	item:setPosition(pos)
end

function UIUnionReEmblem:emblemCallBack(obj)
	local emblemID = obj:getTag()

	local unionEmblem = unionModel:getEmblem()
	if unionEmblem ~= 0 then
		if unionEmblem ~= emblemID then
			-- 设置会徽
			local buffer = NetHelper.createBufferData(MainProtocol.Union, UnionProtocol.UnionEmblemCS)
			buffer:writeInt(emblemID)
			NetHelper.request(buffer)
		end
	end
end

function UIUnionReEmblem:onEmblem(mainCmd, subCmd, data)
	local emblemID = data:readInt()

	print("emblemID", emblemID)
	if emblemID > 0 then
		-- 修改模型
		unionModel:setEmblem(emblemID)
		
		-- 关闭界面
		UIManager.close()
	else
		CsbTools.addTipsToRunningScene(CommonHelper.getUIString(966))
	end
end

return UIUnionReEmblem