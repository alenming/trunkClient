local UIMailListHelper = class("UIMailListHelper")
require("game.mail.MailHelper")

local mailFile = "ui_new/g_gamehall/m_mail/MailPanel.csb"
local unReadBtnFile = "ui_new/g_gamehall/m_mail/UnReadButton.csb"
local readBtnFile = "ui_new/g_gamehall/m_mail/ReadButton.csb"
local autoGetBtnFile = "ui_new/p_public/Button_Green.csb"
local tipFile = "ui_new/g_gamehall/t_task/TaskRedTipPoint.csb"

function UIMailListHelper:ctor(uiMail, mailData)
	self.uiMail = uiMail
	self.mailData = mailData

	-- 显示出来的邮件
	self.items = {}
	-- 缓存不显示的邮件，在需要的时候调用
	self.itemsCache = {}

    local node = getResManager():getCsbNode(ResConfig.UIMail.Csb2.mailItem)
	self.itemSize = CsbTools.getChildFromPath(node, "MailBarPanel"):getContentSize()
    node:cleanup()
	self.root = CsbTools.getChildFromPath(self.uiMail.root, "MainPanel/MailPanel")

	-- 标题
	CsbTools.getChildFromPath(self.root, "MailPanel/BarImage1/BitmapFontLabel_5")
		:setString(CommonHelper.getUIString(401))

	-- 一键领取按钮
	self.autoGetBtn = CsbTools.getChildFromPath(self.root, "MailPanel/Button_OneKeyGet")
	CsbTools.initButton(self.autoGetBtn, handler(self, self.autoGetBtnCallBack), 
		CommonHelper.getUIString(579), "Button_Green/ButtomName", "Button_Green")

	-- 没有邮件提示
	CsbTools.getChildFromPath(self.root, "MailPanel/NoMailTipImage/TipsText")
		:setString(CommonHelper.getUIString(407))
	
	-- scrollView
	self.scroll = CsbTools.getChildFromPath(self.root, "MailPanel/MailScrollView")
	self.scroll:setScrollBarEnabled(false)
	self.scroll:removeAllChildren()
end

function UIMailListHelper:onOpen()
	self:reloadScroll()
end

function UIMailListHelper:onClose()
	self:cacheItems()
end

function UIMailListHelper:cacheItems()
	for _, item in ipairs(self.items) do
		item:setVisible(false)
		table.insert(self.itemsCache, item)
	end
	self.items = {}
end

-- 获取邮件模型数据
function UIMailListHelper:reGetMailsData()
    -- 获取邮件模型数据 并排序
	self.mailsData = MailHelper.getMailsData() or {}
	
	self.mailsKey = {}
	for k, _ in pairs(self.mailsData) do
		table.insert(self.mailsKey, k)
	end
	-- 排序邮件
	local function sortMail(key1, key2)
		if self.mailsData[key1].sendTimeStamp  > self.mailsData[key2].sendTimeStamp then
			return true
		elseif self.mailsData[key1].sendTimeStamp  == self.mailsData[key2].sendTimeStamp then
			if self.mailsData[key1].mailID > self.mailsData[key2].mailID then
				return true
			end
		end
		return false
	end

	table.sort(self.mailsKey, sortMail)
end

function UIMailListHelper:refreshMailData(mailKey)
	local mailInfo = MailHelper.getMailData(mailKey)
	if mailInfo then
		self.mailsData[mailKey] = mailInfo
	end
end

-- 重新显示邮件列表
function UIMailListHelper:reloadScroll()
    self:reGetMailsData()
	self:cacheItems()

	local innerSize = self.scroll:getContentSize()
	if self.itemSize.height * #self.mailsKey > innerSize.height then
		innerSize.height = self.itemSize.height * #self.mailsKey
	end
	self.scroll:setInnerContainerSize(innerSize)

	-- 有无邮件显示
	CommonHelper.playCsbAnimate(self.root, mailFile, 
		#self.mailsKey == 0 and "NoMail" or "Mail", false, nil, true)
	-- 隐藏显示一键领取按钮
	self.autoGetBtn:setVisible(#self.mailsKey ~= 0)

	for i, v in ipairs(self.mailsKey) do
		self:addItem(self.mailsData[v], cc.p(self.itemSize.width/2 + 8,
			innerSize.height - (i - 0.5)* self.itemSize.height))
	end
end

function UIMailListHelper:rePlaceScroll()
	local innerSize = self.scroll:getContentSize()
	if self.itemSize.height * #self.mailsKey > innerSize.height then
		innerSize.height = self.itemSize.height * #self.mailsKey
	end
	self.scroll:setInnerContainerSize(innerSize)

	-- 有无邮件显示
	CommonHelper.playCsbAnimate(self.root, mailFile, 
		#self.mailsKey == 0 and "NoMail" or "Mail", false, nil, true)
	-- 隐藏显示一键领取按钮
	self.autoGetBtn:setVisible(#self.mailsKey ~= 0)

	for i, v in ipairs(self.mailsKey) do
		local item = self.scroll:getChildByTag(v)
		if item then
			item:setPosition(self.itemSize.width/2 + 8, innerSize.height - (i - 0.5)* self.itemSize.height)
		end
	end
end

-- 添加单个邮件
function UIMailListHelper:addItem(info, pos)
	local item = nil
	if #self.itemsCache ~= 0 then
		item = self.itemsCache[1]
		table.remove(self.itemsCache, 1)
		item:setVisible(true)
	else
		item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.itemSize)
		item:addClickEventListener(handler(self, self.itemCallBack))
		self.scroll:addChild(item)
		local itemCsb = getResManager():cloneCsbNode(ResConfig.UIMail.Csb2.mailItem)
		itemCsb:setTag(100100100)
		itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
		item:addChild(itemCsb)
	end

	local mailKey = MailHelper.getMailKey(info.mailID, info.mailType)

	table.insert(self.items, item)

	item:setPosition(pos)
	item:setTag(mailKey)
	
	local itemCsb = item:getChildByTag(100100100)

	-- 主题
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/MainText"):setString(CommonHelper.getUIString(402))
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/MailTitleText"):setString(info.title)

	-- 来自
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/FromText"):setString(CommonHelper.getUIString(403))
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/FromNameText"):setString(info.sender)

	-- 发送时间, 剩余时间
	local lifeDays = math.ceil((info.sendTimeStamp + MailHelper.validSce - getGameModel():getNow())/86400)
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/Date"):setString(os.date("%y-%m-%d", info.sendTimeStamp))
	CsbTools.getChildFromPath(itemCsb, "MailBarPanel/DayNum"):setString(string.format(CommonHelper.getUIString(404), lifeDays))

	return item
end

-- 删除邮件
function UIMailListHelper:delMails(mailsKey)
	for _, key1 in ipairs(mailsKey) do
		for i, key2 in ipairs(self.mailsKey) do
			if key1 == key2 then
				table.remove(self.mailsKey, i)
				break
			end
		end
		for i, item in ipairs(self.items) do
			if item:getTag() == key1 then
				table.remove(self.items, i)
				item:removeFromParent()
			end
		end
	end
    self:rePlaceScroll()
end

-- 一键领取邮件
function UIMailListHelper:autoGetBtnCallBack()
	if #self.mailsKey == 0 then return end

	-- 发包(接受服务器返回是在 UIMailInfoHelper.lua)
	local bufferData = NetHelper.createBufferData(MainProtocol.Mail, MailProtocol.GetMailGoodsCS)
	local normalKeys = {}
	local webKeys = {}

	for _, v in ipairs(self.mailsKey) do
		if self.mailsData[v].mailType == MailHelper.Type.normal then
			table.insert(normalKeys, self.mailsData[v].mailID)
		else
			table.insert(webKeys, self.mailsData[v].mailID)
		end
	end

	bufferData:writeChar(#normalKeys)
	bufferData:writeChar(#webKeys)
	for _,v in ipairs(normalKeys) do
		bufferData:writeInt(v)
	end
	for _,v in ipairs(webKeys) do
		bufferData:writeInt(v)
	end
	NetHelper.request(bufferData)
end

function UIMailListHelper:itemCallBack(obj)
	-- 点击效果
    CommonHelper.playCsbAnimate(obj, ResConfig.UIMail.Csb2.mailItem, "On", false, function ()
        CommonHelper.playCsbAnimate(obj, ResConfig.UIMail.Csb2.mailItem, "Normal", false, nil, true)
    end, true)

    local mailInfo = self.mailsData[obj:getTag()]
    if not mailInfo then
    	print("error mailID", obj:getTag())
    	return 
    end

    -- log 输出
    CsbTools.printValue(mailInfo)

    if mailInfo.isGetContent then
    	local mailKey = MailHelper.getMailKey(mailInfo.mailID, mailInfo.mailType)
    	self.uiMail:uiMailInfoShow(mailKey)
    else
    	local bufferData = NetHelper.createBufferData(MainProtocol.Mail, MailProtocol.ReadMailCS)
        bufferData:writeInt(mailInfo.mailType)
		bufferData:writeInt(mailInfo.mailID)
		NetHelper.request(bufferData)
    end
end

function UIMailListHelper:setIsShow(isShow)
	self.root:setVisible(isShow)
end

function UIMailListHelper:getIsShow()
	return self.root:getVisible()
end

return UIMailListHelper