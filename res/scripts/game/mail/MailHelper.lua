--[[
	邮件的一些枚举
	通过邮件ID和类型 获取邮件key
	获取邮件模型
	设置邮件模型
--]]

MailHelper = {}

local MailModel = getGameModel():getMailModel()
MailHelper.validSce = 2592000

MailHelper.Type = {normal = 0, web = 1}

-- 通过邮件ID 和 类型 获取邮件的 key 值
function MailHelper.getMailKey(mailID, mailType)
	if mailType == MailHelper.Type.web then
		return -100 - mailID
	else
		return mailID
	end
end

-- 通过key值, 获取邮件的ID 和 类型
function MailHelper.getMailIDType(mailKey)
	if mailKey >= 0 then
		return mailKey, MailHelper.Type.normal
	else
		return 100 - mailKey, MailHelper.Type.web
	end
end

--[[
{
	[mailKey] = {
		isGetContent,
		mailID,
		mailType,
		mailConfID,
		sendTimeStamp,
		title,
		sender,
		content,
		vecItem = {
			[1] = {
				id,
				num
			}
		}
	},
	...
}
]]
-- 获取邮件数据 (获取完成后删除过期邮件)
function MailHelper.getMailsData()
	local mailsData = MailModel:getMails()

	-- 清除超时邮件
	local overTimeMailIDs = {}
	for k,v in pairs(mailsData) do
		if v.sendTimeStamp + MailHelper.validSce < getGameModel():getNow() then
			table.insert(overTimeMailIDs, k)
		end
	end
	for _,v in ipairs(overTimeMailIDs) do
		local mailKey = MailHelper.getMailKey(mailsData[v].mailID, mailsData[v].mailType)
		MailModel:removeMail(mailKey)
		mailsData[v] = nil
	end

	return mailsData
end

-- 获取邮件数据
function MailHelper.getMailData(mailKey)
	return MailModel:getMail(mailKey)
end

--[[
mailData = {
	isGetContent,
	mailID,
	mailType,
	mailConfID,
	sendTimeStamp,
	title,
	sender,
	content,
	vecItem = {
		[1] = {
			id,
			num
		}
	}
}
]]
-- 添加邮件
function MailHelper.addMail(mailData)
	if type(mailData) == "table" then
		MailModel:addMail(mailData)
        -- 添加红点数
        RedPointHelper.addCount(RedPointHelper.System.Mail, 1)
	end
end

-- 设置邮件 (获取到邮件类容和道具的时候可以调用)
function MailHelper.setMail(mailData)
	if type(mailData) == "table" then
		MailModel:setMail(mailData)
	end
end

-- 删除邮件
function MailHelper.delMail(mailKey)
	MailModel:removeMail(mailKey)
end

-- 过滤普通邮件数量
function MailHelper.filterMail(mailsData)
	-- 先排序
	local mailsKey = {}
	for k,_ in pairs(mailsData) do
		table.insert(mailsKey, k)
	end

	local function sortMail(key1, key2)
		if mailsData[key1].sendTimeStamp  > mailsData[key2].sendTimeStamp then
			return true
		elseif mailsData[key1].sendTimeStamp  == mailsData[key2].sendTimeStamp then
			if mailsData[key1].mailID > mailsData[key2].mailID then
				return true
			end
		end
		return false
	end

	table.sort(mailsKey, sortMail)

	-- 过滤邮件, 普通邮件是否超过50封
	local overstepKeys = {}
	local normalMailCount = 0
	for _, v in ipairs(mailsKey) do
		if mailsData[v].mailType == MailHelper.Type.normal then
			normalMailCount = normalMailCount + 1
			if normalMailCount > 50 then
				table.insert(overstepKeys, v)
			end
		end
	end
	-- 删除50封以后的邮件
	for _,v in ipairs(overstepKeys) do
		local mailKey = MailHelper.getMailKey(mailsData[v].mailID, mailsData[v].mailType)
		MailModel:removeMail(mailKey)
		mailsData[v] = nil		
	end	
end