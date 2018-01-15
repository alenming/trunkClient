require"model.ModelConst"

-- 公会模型
local UnionModel = class("UnionModel")

function UnionModel:ctor()
	self.mHasUnion = false		-- 是否拥有公会

	self:resetOwnUnionInfo()	-- 重置有公会的数据 
	self:resetNoUnionInfo()		-- 重置没有公会的数据
end

-- 重置有公会的数据
function UnionModel:resetOwnUnionInfo()
	-- 拥有公会的数据
	--[[
	self.unionInfo.onlineMembersInfo = {
		[1] = {
			userID 		成员ID
			lv 			成员等级
			pos 		成员职位
			userName 	成员名
		}
	}

	self.unionInfo.membersInfo = {
		[1] = {
			userID 			成员ID
			totalContrib 	成员累计贡献度 (从加入公会算起)
			pos 			成员职位
			userLv 			成员等级
			todayLiveness 	成员今日活跃度
			lastLoginTime 	成员最后登录时间戳
			userName 		成员名
		}
	}

	self.unionInfo.auditList = {
		[1] = {
			userID 		待审核玩家ID
			userLv 		待审核玩家等级
			userName	待审核玩家名
		}
	}
	--]]	
	self.OwnUnionInfo = {
		unionID = 0,					-- 公会id
		todayStageLiveness = 0,			-- 今日关卡活跃度(自己)
		todayPvpLiveness = 0,			-- 今日pvp活跃度(自己)
		totalContrib = 0,				-- 累计贡献(自己 从进入公会开始算)
		unionLiveness = 0,				-- 公会活跃度
		unionLv = 1,					-- 公会等级
		originUnionLv = 1,				-- 公会今日原始等级
		welfareTag = 0,					-- 福利领取标识(2进制表是, 1表示领取了)
        chairIdentity = 0,              -- 会长身份
		pos = 0,						-- 职位 (自己)		
		hasAudit = 0,					-- 是否有审核数据 (1是, 0否)
		hasExpiditionReward = 0,		-- 是否有远征奖励
		unionName = "",					-- 公会名
		unionNotice = "",				-- 公告

		unionRank = 0,					-- 公会排行
		reputation = 0,					-- 公会声望
		limitLv = 0,					-- 公会申请限制等级
		emblem = 0,						-- 公会会徽ID
		isAutoAudit = 0,				-- 是否自动审核(1是, 0否)
		dangerousDay = 0,				-- 不活跃天数
		chairmanName = "",				-- 会长名

		onlineMembersCount = 0,			-- 在线成员人数
		membersCount = 0,				-- 成员数
		onlineMembersInfo = {},			-- 公会在线成员列表
		membersInfo = {},				-- 公会成员列表	
		auditList = {},					-- 审核列表
	}
end

-- 重置没有公会的数据
function UnionModel:resetNoUnionInfo()
	-- 没有公会时的数据
	--[[
	self.noUnionInfo.applyInfo = {
		[1] = {
			applyTime 		审核结束时间
			unionID 		审核公会ID
		}
	}
	--]]
	self.noUnionInfo = {
		applyCount = 0,			-- 已申请的次数
		applyStamp = 0,			-- 可以申请的时间戳
		applyInfo = {},			-- 已申请的数据
	}
end

function UnionModel:init(buffData)
	self:resetOwnUnionInfo()	-- 重置有公会的数据 
	self:resetNoUnionInfo()		-- 重置没有公会的数据
	local hasUnion = buffData:readChar()
	if hasUnion == 0 then
		self.mHasUnion = false
		local count = buffData:readChar()
		self.noUnionInfo.applyCount = buffData:readInt()
		self.noUnionInfo.applyStamp = buffData:readInt()
		for i=1, count do
			local applyTime = buffData:readInt()
			local unionID = buffData:readInt()
			table.insert(self.noUnionInfo.applyInfo, {
					applyTime = applyTime,
					unionID = unionID,
			})
		end

	else
		self:readOwnUnionBuffData(buffData)
	end

	return true
end

function UnionModel:readOwnUnionBuffData(buffData)
	self.mHasUnion = true
	self.OwnUnionInfo.unionID = buffData:readInt()
	buffData:readInt()
	self.OwnUnionInfo.todayStageLiveness = 0
	self.OwnUnionInfo.todayPvpLiveness = buffData:readInt()
	self.OwnUnionInfo.totalContrib = buffData:readInt()
	self.OwnUnionInfo.unionLiveness = buffData:readInt()
	self.OwnUnionInfo.originUnionLv = buffData:readInt()
	self.OwnUnionInfo.unionLv = buffData:readInt()
	self.OwnUnionInfo.welfareTag = buffData:readInt()
    self.OwnUnionInfo.emblem = buffData:readInt()
	self.OwnUnionInfo.pos = buffData:readChar()
	self.OwnUnionInfo.hasAudit = buffData:readChar()
	self.OwnUnionInfo.hasExpiditionReward = buffData:readChar()
	local exFinishTime = buffData:readInt()
	local exRestFinishTime = buffData:readInt()
	local exModel = getGameModel():getExpeditionModel()
	exModel:setWarEndTime(exFinishTime)
	exModel:setRestEndTime(exRestFinishTime)
	self.OwnUnionInfo.unionName = buffData:readCharArray(20)
	self.OwnUnionInfo.unionNotice = buffData:readCharArray(128)
end

function UnionModel:getHasUnion()
	return self.mHasUnion
end

function UnionModel:setHasUnion(hasUnion)
	if hasUnion == false or hasUnion == 0 then
		self.mHasUnion = false
		self:resetOwnUnionInfo()
	else
		self.mHasUnion = true
		self:resetNoUnionInfo()
	end
end

function UnionModel:getUnionID()
	return self.OwnUnionInfo.unionID
end

function UnionModel:setUnionID(id)
	self.OwnUnionInfo.unionID = id
end

function UnionModel:getChairIdentity()
	return self.OwnUnionInfo.chairIdentity
end

function UnionModel:setChairIdentity(identity)
	self.OwnUnionInfo.chairIdentity = identity
end

function UnionModel:getTodayStageLiveness()
	return self.OwnUnionInfo.todayStageLiveness
end

function UnionModel:setTodayStageLiveness(liveness)
	--self.OwnUnionInfo.unionLiveness = self.OwnUnionInfo.unionLiveness + 
	--	(liveness - self.OwnUnionInfo.todayStageLiveness)
	--self.OwnUnionInfo.todayStageLiveness = liveness
	--
	--self:modifMemberInfo(nil, "todayLiveness", self.OwnUnionInfo.todayPvpLiveness + liveness)
end

function UnionModel:addStageLiveness(energy)
	--if self.mHasUnion and self.OwnUnionInfo.todayStageLiveness < 50 then
	--	if self.OwnUnionInfo.todayStageLiveness + energy <= 50 then
	--		self:setTodayStageLiveness(self.OwnUnionInfo.todayStageLiveness + energy)
	--	else
	--		self:setTodayStageLiveness(50)
	--	end
	--end
end

function UnionModel:getTodayPvpLiveness()
	return self.OwnUnionInfo.todayPvpLiveness
end

function UnionModel:setTodayPvpLiveness(liveness)
	self.OwnUnionInfo.unionLiveness = self.OwnUnionInfo.unionLiveness + 
		(liveness - self.OwnUnionInfo.todayPvpLiveness)
	self.OwnUnionInfo.todayPvpLiveness = liveness

	self:modifMemberInfo(nil, "todayLiveness", self.OwnUnionInfo.todayStageLiveness + liveness)
end

function UnionModel:addPVPLiveness(liveness)
	if self.mHasUnion and self.OwnUnionInfo.todayPvpLiveness < 100 then
		if self.OwnUnionInfo.todayPvpLiveness + liveness <= 100 then
			self:setTodayPvpLiveness(self.OwnUnionInfo.todayPvpLiveness + liveness)
		else
			self:setTodayPvpLiveness(100)
		end
	end
end

function UnionModel:getTotalContribution()
	return self.OwnUnionInfo.totalContrib
end

function UnionModel:setTotalContribution(tatalContribution)
	self.OwnUnionInfo.totalContrib = tatalContribution

	self:modifMemberInfo(nil, "totalContrib", tatalContribution)
end

function UnionModel:getUnionLiveness()
	return self.OwnUnionInfo.unionLiveness
end

function UnionModel:setUnionLiveness(liveness)
	self.OwnUnionInfo.unionLiveness = liveness
end

function UnionModel:getUnionLv()
	return self.OwnUnionInfo.unionLv
end

function UnionModel:setUnionLv(lv)
	self.OwnUnionInfo.unionLv = lv
end

function UnionModel:getOriginUnionLv()
	return self.OwnUnionInfo.originUnionLv
end

function UnionModel:setOriginUnionLv(lv)
	self.OwnUnionInfo.originUnionLv = lv
end

function UnionModel:getWelfareTag()
	return self.OwnUnionInfo.welfareTag
end

function UnionModel:setWelfareTag(tag)
	self.OwnUnionInfo.welfareTag = tag
end

function UnionModel:getPos()
	return self.OwnUnionInfo.pos
end

function UnionModel:setPos(pos)
	self.OwnUnionInfo.pos = pos

	self:modifOnlineMemberInfo(nil, "pos", pos)
	self:modifMemberInfo(nil, "pos", pos)
end

function UnionModel:getHasAudit()
	return self.OwnUnionInfo.hasAudit
end

function UnionModel:setHasAudit(hasAudit)
	self.OwnUnionInfo.hasAudit = hasAudit
end

function UnionModel:getHasExpiditionReward()
	return self.OwnUnionInfo.hasExpiditionReward
end

function UnionModel:setHasExpiditionReward(hasExpiditionReward)
	self.OwnUnionInfo.hasExpiditionReward = hasExpiditionReward
end

function UnionModel:getUnionName()
	return self.OwnUnionInfo.unionName
end

function UnionModel:setUnionName(unionName)
	self.OwnUnionInfo.unionName = unionName
end

function UnionModel:getUnionNotice()
	return self.OwnUnionInfo.unionNotice
end

function UnionModel:setUnionNotice(notice)
	self.OwnUnionInfo.unionNotice = notice
end

function UnionModel:getUnionRank()
	return self.OwnUnionInfo.unionRank
end

function UnionModel:setUnionRank(rank)
	self.OwnUnionInfo.unionRank = rank
end

function UnionModel:getReputation()	
	return self.OwnUnionInfo.reputation
end

function UnionModel:setReputation(reputation)
	self.OwnUnionInfo.reputation = reputation
end

function UnionModel:getLimitLv()	
	return self.OwnUnionInfo.limitLv
end

function UnionModel:setLimitLv(limitLv)
	self.OwnUnionInfo.limitLv = limitLv
end

function UnionModel:getEmblem()	
	return self.OwnUnionInfo.emblem
end

function UnionModel:setEmblem(emblem)
	self.OwnUnionInfo.emblem = emblem
end

function UnionModel:getIsAutoAudit()	
	return self.OwnUnionInfo.isAutoAudit
end

function UnionModel:setIsAutoAudit(isAutoAudit)
	self.OwnUnionInfo.isAutoAudit = isAutoAudit
end

function UnionModel:getDangerousDay()	
	return self.OwnUnionInfo.dangerousDay
end

function UnionModel:setDangerousDay(dangerousDay)
	self.OwnUnionInfo.dangerousDay = dangerousDay
end

function UnionModel:getChairmanName()	
	return self.OwnUnionInfo.chairmanName
end

function UnionModel:setChairmanName(chairmanName)
	self.OwnUnionInfo.chairmanName = chairmanName
end

function UnionModel:getOnlineMembersCount()
	return self.OwnUnionInfo.onlineMembersCount
end

function UnionModel:setOnlineMembersCount(count)
	self.OwnUnionInfo.onlineMembersCount = count
end

function UnionModel:getMembersCount()
	return self.OwnUnionInfo.membersCount
end

function UnionModel:setMembersCount(count)
	self.OwnUnionInfo.membersCount = count
end

function UnionModel:getOnlineMembersInfo()
	return clone(self.OwnUnionInfo.onlineMembersInfo)
end

function UnionModel:setOnlineMembersInfo(listInfo)
	if type(listInfo) ~= "table" then
		return
	end

	self.OwnUnionInfo.onlineMembersInfo = clone(listInfo)

	self.OwnUnionInfo.onlineMembersCount = #listInfo
	self:modifMineInfoByOnlineMemberInfo()
end

function UnionModel:getMembersInfo()
	return clone(self.OwnUnionInfo.membersInfo)
end

function UnionModel:setMembersInfo(listInfo)
	if type(listInfo) ~= "table" then
		return
	end

	self.OwnUnionInfo.membersInfo = clone(listInfo)

	self.OwnUnionInfo.membersCount = #listInfo
	self:modifMineInfoByMemberInfo()
end

function UnionModel:getAuditList()
	return clone(self.OwnUnionInfo.auditList)
end

function UnionModel:setAuditList(listInfo)
	if type(listInfo) ~= "table" then
		return
	end

	self.OwnUnionInfo.auditList = clone(listInfo)
end

-- 修改在线成员列表某个userid的某个key的value (默认userID 为自己)
function UnionModel:modifOnlineMemberInfo(userID, key, value)
	if type(key) ~= "string" or value == nil then
		return 
	end

	if userID == 0 or userID == nil then
		userID = getGameModel():getUserModel():getUserID()
	end

	for _, v in ipairs(self.OwnUnionInfo.onlineMembersInfo) do
		if v.userID == userID then
			if v[key] ~= nil then
				v[key] = value
			end
			break
		end
	end
end

-- 修改成员列表某个userid的某个key的value (默认userID 为自己)
function UnionModel:modifMemberInfo(userID, key, value)
	if type(key) ~= "string" or value == nil then
		return 
	end
	
	if userID == 0 or userID == nil then
		userID = getGameModel():getUserModel():getUserID()
	end

	for _, v in ipairs(self.OwnUnionInfo.membersInfo) do
		if v.userID == userID then
			if v[key] ~= nil then
				v[key] = value
			end
			break
		end
	end
end

-- 根据在线成员列表数据, 修改自己的数据
function UnionModel:modifMineInfoByOnlineMemberInfo()
	local userID = getGameModel():getUserModel():getUserID()
	for _, v in ipairs(self.OwnUnionInfo.onlineMembersInfo) do
		if v.userID == userID then
			self.OwnUnionInfo.pos = v.pos
			break
		end
	end
end

-- 根据成员列表数据, 修改自己的数据
function UnionModel:modifMineInfoByMemberInfo()
	local userID = getGameModel():getUserModel():getUserID()
	for _, v in ipairs(self.OwnUnionInfo.membersInfo) do
		if v.userID == userID then
			self.OwnUnionInfo.totalContrib = v.totalContrib
			self.OwnUnionInfo.pos = v.pos
			break
		end
	end
end

function UnionModel:getApplyCount()
	return self.noUnionInfo.applyCount
end

function UnionModel:setApplyCount(count)
	self.noUnionInfo.applyCount = count
end

function UnionModel:getApplyStamp()
	return self.noUnionInfo.applyStamp
end

function UnionModel:setApplyStamp(stamp)
	self.noUnionInfo.applyStamp = stamp
end

function UnionModel:getApplyInfo()
	return clone(self.noUnionInfo.applyInfo)
end

function UnionModel:setApplyInfo(listInfo)
	if type(listInfo) ~= "table" then
		return
	end

	self.noUnionInfo.applyInfo = clone(listInfo)
end

return UnionModel