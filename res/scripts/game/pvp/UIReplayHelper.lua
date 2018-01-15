--[[
	战斗回放的一些公用用方法，主要实现以下内容
	1. 初始化英雄或召唤师头像图标
--]]

UIReplayHelper = {}

-- 传入HeadItem.csb节点, id, 等级, 星级(召唤师不用传, 英雄需要传)
function UIReplayHelper.setReplayIconNode(node, id, lv, star)
	if nil == node then
		print("setReplayIconItem node is nil")
		return
	end
	if nil == id or nil == lv then
		node:setVisible(false)
		return
	else
		node:setVisible(true)
	end

	local starLab = CsbTools.getChildFromPath(node, "HeadPanel/StarNum")
	local lvLab = CsbTools.getChildFromPath(node, "HeadPanel/HeroLevel")
	local costLab = CsbTools.getChildFromPath(node, "HeadPanel/GemNum")
	local bordImg = CsbTools.getChildFromPath(node, "HeadPanel/BarImage")
	local bgImg = CsbTools.getChildFromPath(node, "HeadPanel/HeadBg")
	local iconImg = CsbTools.getChildFromPath(node, "HeadPanel/HeadImage")

	if nil == starLab or nil == lvLab or nil == costLab or nil == bordImg or nil == iconImg then
		print("some node is not exist", starLab, lvLab, costLab, bordImg, iconImg)
		return
	end

	if nil == star then
		CommonHelper.playCsbAnimation(node, "Summoner", false)
		local summonerConf = getHeroConfItem(id)
		if not summonerConf then
			print("summonerconf is nil id: ", id)
			return
		end

		lvLab:setString(lv or 1)
		CsbTools.replaceImg(bordImg, IconHelper.getSoldierHeadFrame(5))
		CsbTools.replaceSprite(bgImg, IconHelper.getSoldierHeadBg(5))
		CsbTools.replaceImg(iconImg, summonerConf.Common.HeadIcon)

	else
		CommonHelper.playCsbAnimation(node, "Hero", false)

		local heroConf = getSoldierConfItem(id, star)
		if not heroConf then
			print("heroConf is nil id, star: ", id, star)
			return
		end

		starLab:setString(star)
		lvLab:setString(lv)
		costLab:setString(heroConf.Cost)
		CsbTools.replaceImg(bordImg, IconHelper.getSoldierHeadFrame(heroConf.Rare))
		CsbTools.replaceSprite(bgImg, IconHelper.getSoldierHeadBg(heroConf.Rare))
		CsbTools.replaceImg(iconImg, heroConf.Common.HeadIcon)
	end
end

-- 初始化对战信息csb(回放信息csb基本和这个一样可以共用)
function UIReplayHelper.setReplayNode(node, info)
---------------------------------begin--------------------------------------------------------
	local function randomOne(...)
		local randInfo = {...}
		return randInfo[math.random(1, #randInfo)]
	end

	info = {
		watchTime = math.random(1, 1000000),
		issueTime = math.random(1487714870, 1487814870),
		leftTeam = {
			userName = string.format("leftUserName%d", math.random(1, 10000)),
			unionName = string.format("leftUnionName%d", math.random(1, 10000)),
			rank = math.random(1, 100),
			summoner = {
				id = randomOne(1000, 1100, 1200, 1300, 1400, 1500, 1600),
				lv = math.random(1, 50)
			},
			heros = {}
		},
		rightTeam = {
			userName = string.format("rightUserName%d", math.random(1, 10000)),
			unionName = string.format("rightUnionName%d", math.random(1, 10000)),
			rank = math.random(1, 100),
			summoner = {
				id = randomOne(1000, 1100, 1200, 1300, 1400, 1500, 1600),
				lv = math.random(1, 50)
			},
			heros = {}
		}
	}

	for i=1,7 do
		math.randomseed(os.time()*(i+100))
		info.leftTeam.heros[i] = {
			id = randomOne(10000,10200,10300,10400,10500,10600,10700,10900,11000,11100,12000,20000,20500,20900,
					30000,30100,30300,30400,30500,30600,30700,30800,30900,31000,31100,40000,40100,40200,40300,40400,
					40500,40600,40700,40800,40900,41000),
			lv = math.random(1, 50),
			star = math.random(1, 7),
		}

		if math.random(1, 100) > 95 then
			break
		end
	end

	for i=1,7 do
		math.randomseed(os.time()*(i+200))
		info.rightTeam.heros[i] = {
			id = randomOne(10000,10200,10300,10400,10500,10600,10700,10900,11000,11100,12000,20000,20500,20900,
					30000,30100,30300,30400,30500,30600,30700,30800,30900,31000,31100,40000,40100,40200,40300,40400,
					40500,40600,40700,40800,40900,41000),
			lv = math.random(1, 50),
			star = math.random(1, 7),
		}

		if math.random(1, 100) > 90 then
			break
		end
	end
--------------------------------------end---------------------------------------------------

	for i=1, 2 do
		local s = i == 1 and "L" or "R"
		local temaInfo = (i == 1 and info.leftTeam or info.rightTeam)
		CsbTools.getChildFromPath(node, "Name_" .. s):setString(temaInfo.userName)
		CsbTools.getChildFromPath(node, "GuildName_" .. s):setString(temaInfo.unionName)
		CsbTools.getChildFromPath(node, "RankNum_" .. s):setVisible(temaInfo.rank <= 50)
		CsbTools.getChildFromPath(node, "RankNum_" .. s):setString(temaInfo.rank)		
		UIReplayHelper.setReplayIconNode(
			CsbTools.getChildFromPath(node, "User_" .. s .. "/SumonerHead"), 
			temaInfo.summoner.id, temaInfo.summoner.lv)
		for j=1, 7 do
			local iconNode = CsbTools.getChildFromPath(node, "User_" .. s .. "/HeroHead_" .. j)
			if temaInfo.heros[j] == nil then
				iconNode:setVisible(false)
			else
				iconNode:setVisible(true)
				UIReplayHelper.setReplayIconNode(iconNode, temaInfo.heros[j].id, temaInfo.heros[j].lv, temaInfo.heros[j].star)
			end			
		end
	end
	CsbTools.getChildFromPath(node, "Tips"):setString(string.format("观看%d次", info.watchTime))
	local interval = getGameModel():getNow() - info.issueTime
	local h = math.floor(interval/3600)
	local m = math.ceil((interval-3600*h)/60)
	CsbTools.getChildFromPath(node, "Time"):setString(string.format("%d小时%d分钟前", h, m))
end