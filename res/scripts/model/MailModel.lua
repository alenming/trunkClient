require"model.ModelConst"

-- 邮件模型
local MailModel = class("MailModel")

function MailModel:ctor()
	self.mMailCount = 0
	self.mMails = {}
end

function MailModel:init(buffData)
	local normalMailCount = buffData:readChar()					-- 普通邮件个数
	local webMailCount = buffData:readChar()					-- web邮件个数
	self.mMailCount = normalMailCount + webMailCount			-- 总邮件数
	self.mMails = {}
	for i = 1, normalMailCount do
		local mailID = buffData:readInt()						-- 邮件ID
		local mailConfID = buffData:readInt()					-- 邮件配置ID
		local sendTimeStamp = buffData:readInt()				-- 发送时间戳
		local title = buffData:readCharArray(32)				-- 邮件标题
		local sender = getUILanConfItem(409)					-- 发送者为系统
		local content = ""

		local mailConf = getMailConfItem(mailConfID)
		if mailConf and mailConfID ~= 0 then
			-- 拼接内容
			local hello = getUILanConfItem(408)
			if mailConfID == 4 or mailConfID == 5 then
				-- 公会邮件特殊处理 ~_~
				content = string.format(hello.."\n\t"..getUILanConfItem(mailConf.Content), title)
			else
				content = hello.."\n\t"..getUILanConfItem(mailConf.Content)
			end

			title = getUILanConfItem(mailConf.Topic)
			sender = getUILanConfItem(mailConf.Sender)
		end

		local key = self:getMailKey(mailID, EMailType.MAIL_TYPE_NORMAL)
		self.mMails[key] = {
			isGetContent = false, 								-- 是否获取内容
			mailID = mailID, 									-- 邮件ID
			mailType = EMailType.MAIL_TYPE_NORMAL, 				-- 邮件类型
			mailConfID = mailConfID, 							-- 邮件配置ID
			sendTimeStamp = sendTimeStamp, 						-- 发送时间戳
			title = title, 										-- 标题
			sender = sender, 									-- 来自
			content = content, 									-- 内容
			vecItem = {}										-- 道具列表
		}
	end

	for i = 1, webMailCount do
		local mailID = buffData:readInt()						-- 邮件ID
		local mailConfID = buffData:readInt()					-- 邮件配置ID
		local sendTimeStamp = buffData:readInt()				-- 发送时间戳
		local title = buffData:readCharArray(32)				-- 邮件标题
		local sender = getUILanConfItem(409)					-- 发送者为系统
		local content = ""

		local mailConf = getMailConfItem(mailConfID)
		if mailConf and mailConfID ~= 0 then
			-- 拼接内容
			local hello = getUILanConfItem(408)
			if mailConfID == 4 or mailConfID == 5 then
				-- 公会邮件特殊处理 ~_~
				content = string.format(hello.."\n\t"..getUILanConfItem(mailConf.Content), title)
			else
				content = hello.."\n\t"..getUILanConfItem(mailConf.Content)
			end

			title = getUILanConfItem(mailConf.Topic)
			sender = getUILanConfItem(mailConf.Sender)
		end

		local key = self:getMailKey(mailID, EMailType.MAIL_TYPE_WEB)
		self.mMails[key] = {
			isGetContent = false, 								-- 是否获取内容
			mailID = mailID, 									-- 邮件ID
			mailType = EMailType.MAIL_TYPE_WEB, 				-- 邮件类型
			mailConfID = mailConfID, 							-- 邮件配置ID
			sendTimeStamp = sendTimeStamp, 						-- 发送时间戳
			title = title, 										-- 标题
			sender = sender, 									-- 来自
			content = content, 									-- 内容
			vecItem = {}										-- 道具列表
		}
	end
	--dump(self.mMails)
	return true
end

function MailModel:getMailKey(mailID, mailType)
	if mailType == EMailType.MAIL_TYPE_WEB then
		return -100 - mailID
	end
	return mailID
end

-- 添加邮件
function MailModel:addMail(info)
	local key = self:getMailKey(info.mailID, info.mailType)
	if self.mMails[key] then
		return false
	end
	self.mMails[key] = info
	self.mMailCount = self.mMailCount + 1
	return true
end

-- 设置邮件
function MailModel:setMail(info)
	local key = self:getMailKey(info.mailID, info.mailType)
	if self.mMails[key] then
		self.mMails[key] = info
		return true
	end
	return false
end
   
-- 删除邮件
function MailModel:removeMail(key)
	if self.mMails[key] then
		self.mMails[key] = nil
		self.mMailCount = self.mMailCount - 1
		return true
	end
	return false
end

-- 获取邮件
function MailModel:getMail(key)
	if self.mMails[key] then
		return self.mMails[key]
	end
end
  
function MailModel:getMails()
	return self.mMails
end

function MailModel:getMailCount()
	return self.mMailCount
end

return MailModel