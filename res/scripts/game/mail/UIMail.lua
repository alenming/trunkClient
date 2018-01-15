--[[
	邮件界面，主要实现以下内容
	1. 邮件主界面 
--]]

local UIMail = class("UIMail", function ()
	return require("common.UIView").new()
end)

require("game.mail.MailHelper")

function UIMail:ctor()
	self.rootPath = ResConfig.UIMail.Csb2.mailPanel
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(backBtn, function()
        if self.UIMailInfoHelper and self.UIMailInfoHelper:getIsShow() then            
		    self.UIMailInfoHelper:setIsShow(false)
        else
            UIManager.close()
        end
	end)

	-- 邮件界面协助管理类
	self.UIMailListHelper = require("game.mail.UIMailListHelper").new(self)
	self.UIMailInfoHelper = require("game.mail.UIMailInfoHelper").new(self)
end

function UIMail:onOpen()
	self.UIMailListHelper:onOpen()
	self.UIMailInfoHelper:onOpen()

	-- 注册监听
	local readMailCmd = NetHelper.makeCommand(MainProtocol.Mail, MailProtocol.ReadMailSC)
	self.readMailHandler = handler(self, self.onReadMail)
	NetHelper.setResponeHandler(readMailCmd, self.readMailHandler)

	local getMailGoodsCmd = NetHelper.makeCommand(MainProtocol.Mail, MailProtocol.GetMailGoodsSC)
	self.getMailGoodsHandler = handler(self, self.onGetMailGoods)
	NetHelper.setResponeHandler(getMailGoodsCmd, self.getMailGoodsHandler)
end

function UIMail:onClose()
	local readMailCmd = NetHelper.makeCommand(MainProtocol.Mail, MailProtocol.ReadMailSC)
	NetHelper.removeResponeHandler(readMailCmd, self.readMailHandler)

	local getMailGoodsCmd = NetHelper.makeCommand(MainProtocol.Mail, MailProtocol.GetMailGoodsSC)
	NetHelper.removeResponeHandler(getMailGoodsCmd, self.getMailGoodsHandler)
	
	self.UIMailListHelper:onClose()
	self.UIMailInfoHelper:onClose()	
end

function UIMail:uiMailListDel(delMailsKey)
	self.UIMailListHelper:delMails(delMailsKey)
end

function UIMail:uiMailListRefreshMailData(mailKey)
	self.UIMailListHelper:refreshMailData(mailKey)
end

function UIMail:uiMailInfoShow(mailKey)
	self.UIMailInfoHelper:reShow(mailKey)
end

function UIMail:setMailInfoReceived()
	self.UIMailInfoHelper:setReceived()
end

function UIMail:onReadMail(mainCmd, subCmd, data)
	local mailType = data:readInt()
    local mailID = data:readInt()
    local propCount = data:readInt()
	local contentLen = data:readInt()
    local propInfo = {}
    for i=1, propCount do
    	propInfo[i] = {}
	    propInfo[i].id = data:readInt()
	    propInfo[i].num = data:readInt()
	end
	local mailContent = data:readCharArray(contentLen) or ""

	local mailKey = MailHelper.getMailKey(mailID, mailType)

	-- 修改模型数据
	local mailInfo = MailHelper.getMailData(mailKey)
	if not mailInfo then
		print("mailInfo nil, mailKey ", mailKey)
		return 
	end	

    mailInfo.isGetContent = true
	mailInfo.vecItem = propInfo
    if #propInfo == 0 then
        RedPointHelper.addCount(RedPointHelper.System.Mail, -1)
    end

	if mailInfo.mailConfID == 0 then
		mailInfo.content = mailContent
	end
	CsbTools.printValue(mailInfo, "mailInfo")

	MailHelper.setMail(mailInfo)
    self:uiMailInfoShow(mailKey)
    self:uiMailListRefreshMailData(mailKey)
end

function UIMail:onGetMailGoods(mainCmd, subCmd, data)
	local normalMailCount = data:readChar()
	local webMailCount = data:readChar()
	local propCount = data:readChar()
	local normalMailIDs = {}
	local webMailIDs = {}
	for i = 1, normalMailCount do
		table.insert(normalMailIDs, data:readInt())
	end

	for j = 1, webMailCount do
		table.insert(webMailIDs, data:readInt())
	end

	-- 所有的邮件key
	local mailsKey = {}

    -- 构造table, 显示奖励
	local awardData = {}
    local dropInfo = {}
	for i=1, propCount do
	    dropInfo.id = data:readInt()
	    dropInfo.num = data:readInt()
	    UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
	end

	-- 修改模型
	for _,v in ipairs(normalMailIDs) do
		local mailKey = MailHelper.getMailKey(v, MailHelper.Type.normal)
		MailHelper.delMail(mailKey)
		table.insert(mailsKey, mailKey)
	end
	for _,v in ipairs(webMailIDs) do
		local mailKey = MailHelper.getMailKey(v, MailHelper.Type.web)	
		MailHelper.delMail(mailKey)
		table.insert(mailsKey, mailKey)
	end

	if propCount ~= 0 then
        -- 显示奖励
	    UIManager.open(UIManager.UI.UIAward, awardData)
	end

	self:uiMailListDel(mailsKey)

	if #mailsKey >= 1 then
		self:setMailInfoReceived()

        RedPointHelper.addCount(RedPointHelper.System.Mail, -#mailsKey)
    else
    	CsbTools.addTipsToRunningScene(CommonHelper.getUIString(400))
	end
end

return UIMail