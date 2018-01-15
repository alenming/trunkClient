--[[
	-- 获取排行榜数据的时候, 自动判断是否直接使用本地保存数据还是重新从服务器获取数据
	注意事项:
		没有获取到, 记得在界面关闭的时候调用RankData.clearCallFunc(type, uiID) 将回调清除
		获取到了数据, 可以清除回调, 也可以不清除回调
--]]

RankData = {}

-- 排行榜类型
RankData.rankType = {
	arena = 0,		-- 竞技
	summoner = 1,	-- 召唤师
	union = 2,		-- 公会
	tower = 3,		-- 爬塔
    champion = 4,   -- 锦标赛
}

RankData.rankTypeName = {}
for k,v in pairs(RankData.rankType) do
	RankData.rankTypeName[v] = k
end

function RankData.init()
	-- 排行榜下次获取时间戳
	RankData.regetTimestamp = {
		[RankData.rankType.arena] = 0,
		[RankData.rankType.summoner] = 0,
		[RankData.rankType.union] = 0,
		[RankData.rankType.tower] = 0,
	    [RankData.rankType.champion] = 0,
	}

	-- 排行榜数据
	RankData.data = {
		[RankData.rankType.arena] = {},
		[RankData.rankType.summoner] = {},
		[RankData.rankType.union] = {},
		[RankData.rankType.tower] = {},
		[RankData.rankType.champion] = {},
	}

	-- 请求数据回调函数
	RankData.callBackFunc = {
		[RankData.rankType.arena] = {},
		[RankData.rankType.summoner] = {},
		[RankData.rankType.union] = {},
		[RankData.rankType.tower] = {},
		[RankData.rankType.champion] = {},
	}
end

-- 获取排行榜数据(这里并不会返回数据, 数据通过调用dataCallBack回调给界面)
function RankData.getRankData(rankType, uiID, dataCallBack)
	if type(uiID) == "number" and type(dataCallBack) == "function" 
		and RankData.rankTypeName[rankType] ~= nil then
		RankData.callBackFunc[rankType][uiID] = dataCallBack
	end

	local time = getGameModel():getNow()
	if RankData.regetTimestamp[rankType] > time then
		RankData.sendRankData(rankType)
	else
		-- 请求服务器数据
		local bufferData = NetHelper.createBufferData(MainProtocol.Rank, RankProtocol.RankInfoCS)
		bufferData:writeInt(rankType)

        NetHelper.requestWithTimeOut(bufferData, 
            NetHelper.makeCommand(MainProtocol.Rank, RankProtocol.RankInfoSC), 
            RankData.onRankInfo) 
	end
end

-- 清除需要回去数据的界面回调函数
function RankData.clearCallFunc(rankType, uiID)
	if RankData.callBackFunc[rankType] ~= nil and RankData.callBackFunc[rankType][uiID] ~= nil then
		RankData.callBackFunc[rankType][uiID] = nil
	end
end

-- 清除需要回去数据的界面回调函数
function RankData:clearUIAllCallFunc(uiID)
	for name, rankType in pairs(RankData.rankType) do
		RankData.clearCallFunc(rankType, uiID)
	end
end

-- 返回数据给需要获取数据的界面
function RankData.sendRankData(rankType)
	for uiID, callBack in pairs(RankData.callBackFunc[rankType]) do
        local rankInfo = {}
        for k1, v1 in pairs(RankData.data[rankType]) do
        	rankInfo[k1] = {}
        	for k2, v2 in pairs(v1) do
        		rankInfo[k1][k2] = v2
        	end
        end
		callBack(rankInfo, rankType)
	end
	RankData.callBackFunc[rankType] = {}
end

-- 服务器数据回调
function RankData.onRankInfo(mainCmd, subCmd, data)
	local rankType = data:readInt()
	local count = data:readInt()
	local selfIndex = data:readInt()

	if rankType == RankData.rankType.arena or rankType == RankData.rankType.champion then
		RankData.regetTimestamp[rankType] = getGameModel():getNow() + 300
		RankData.data[rankType] = {}
		RankData.data[rankType].selfInfo = {
			score = getGameModel():getPvpModel():getScore(rankType == RankData.rankType.arena and 0 or 1),
			index = selfIndex,
		}
		for i=1, count do
            RankData.data[rankType][i] = {}
			RankData.data[rankType][i].index = data:readInt()
			RankData.data[rankType][i].headID = data:readInt()
			RankData.data[rankType][i].heroName = data:readCharArray(32)
			RankData.data[rankType][i].unionName = data:readCharArray(32)
			RankData.data[rankType][i].score = data:readInt()
			RankData.data[rankType][i].userLevel = data:readInt()
			RankData.data[rankType][i].BDType = data:readChar()
			RankData.data[rankType][i].BDLv = data:readChar()
			RankData.data[rankType][i].isSelf = (selfIndex == i)
		end

	elseif rankType == RankData.rankType.summoner then
		RankData.regetTimestamp[rankType] = getGameModel():getNow() + 300
		RankData.data[rankType] = {}
		RankData.data[rankType].selfInfo = {
			userLevel = getGameModel():getUserModel():getUserLevel(),
			index = selfIndex,
		}
		for i=1, count do
            RankData.data[rankType][i] = {} 
			RankData.data[rankType][i].index = data:readInt()
			RankData.data[rankType][i].headID = data:readInt()
			RankData.data[rankType][i].heroName = data:readCharArray(32)
			RankData.data[rankType][i].unionName = data:readCharArray(32)
			RankData.data[rankType][i].userLevel = data:readInt()			
			RankData.data[rankType][i].BDType = data:readChar()
			RankData.data[rankType][i].BDLv = data:readChar()
			RankData.data[rankType][i].isSelf = (selfIndex == i)
		end

	elseif rankType == RankData.rankType.union then
		RankData.regetTimestamp[rankType] = getGameModel():getNow() + 300
		RankData.data[rankType] = {}
		RankData.data[rankType].selfInfo = {
			unionName = getGameModel():getUnionModel():getUnionName(),
			index = selfIndex,
		}
		for i=1, count do
            RankData.data[rankType][i] = {}
			RankData.data[rankType][i].index = data:readInt()
			RankData.data[rankType][i].unionName = data:readCharArray(32)
			RankData.data[rankType][i].emblemID	= data:readInt()
			RankData.data[rankType][i].unionMembersCount = data:readInt()
			RankData.data[rankType][i].unionLevel = data:readInt()
			RankData.data[rankType][i].isSelf = (selfIndex == i)
		end

	elseif rankType == RankData.rankType.tower then
		RankData.regetTimestamp[rankType] = getGameModel():getNow() + 300
		RankData.data[rankType] = {}
		RankData.data[rankType].selfInfo = {
			maxFloor = getGameModel():getTowerTestModel():getTowerTestFloor() - 1,
			index = selfIndex,
		}
		for i=1, count do
            RankData.data[rankType][i] = {}
			RankData.data[rankType][i].index = data:readInt()
			RankData.data[rankType][i].headID = data:readInt()
			RankData.data[rankType][i].heroName = data:readCharArray(32)
			RankData.data[rankType][i].maxFloor = data:readInt()
			RankData.data[rankType][i].score = data:readInt()
			RankData.data[rankType][i].userLevel = data:readInt()
			RankData.data[rankType][i].BDType = data:readChar()
			RankData.data[rankType][i].BDLv = data:readChar()
			RankData.data[rankType][i].isSelf = (selfIndex == i)
			RankData.data[rankType][i].unionName = data:readCharArray(32)

		end

	end

	RankData.sendRankData(rankType)
end

-- 获取自己的排名数据
function RankData.getSelfRank(rankType, oldRank)
    local rankDatas = RankData.data[rankType]

    if rankDatas then
        for _, data in pairs(rankDatas) do
            if data.isSelf then
                return data.index
            end
        end
    end

    return oldRank
end