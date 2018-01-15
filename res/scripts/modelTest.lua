--model test

function dumpTable(t)
	for k,v in pairs(t) do
        if "boolean" == type(v) then
            if v then
                print(k .. ' ' .. 'true')
            else
                print(k .. ' ' .. 'false')
            end
        elseif 'table' == type(v) then
            print('========insideTable1=====' .. ' ' .. k)
            dumpTable(v)
            print('========insideTable2=====' .. ' ' .. k)
        else
            print(k .. ' ' .. v)
        end
	end
end
function dumpTableKey(t)
	
	print('==================================')
	if t then
		for k,v in pairs(t) do
			print(k)
		end
	end
	print('==================================')
end

function userModel()
	print("\n----------------usermodel-------------------------")
	local user = newUserModel()
	dumpTableKey(getmetatable(user))
	user:setUserID(1)
	user:setHeadID(101)
	user:setGold(800)
	user:setUserLevel(3)
	user:setDiamond(1000)
	user:setEnergy(30)
	user:setUserName("sum")
	print(user:getUserID())
	print(user:getHeadID())
	print(user:getGold())
	print(user:getUserLevel())
	print(user:getDiamond())
	print(user:getEnergy())
	print(user:getDiamond())
	print(user:getUserName())
	--deleteUserModel()
	print("------------------usermodel-------------------------\n")
end

function bagModel()
	print("\n----------------bagmodel-------------------------")
	local bag = newBagModel()
	print(bag:extra(20))
	print(bag:addItem(1001,3001))
	print(bag:addItem(1002,3002))
	print(bag:addItem(10001, 5))
	print(bag:addItem(10002, 8))
	dumpTable(bag:getItems())
	print(bag:removeItem(10001))
	print(bag:hasItem(10001))
	dumpTable(bag:getItems())
	--deleteBagModel()
	print("------------------bagmodel-------------------------\n")
end

function  summonersModel()
	print("\n----------------summonersmodel-------------------------")
	local sum = newSummonersModel()
	print(sum:addSummoner(1001))
	print(sum:addSummoner(1002))
	print(sum:getSummonerCount())
	dumpTable(sum:getSummoners())
	print(sum:hasSummoner(1001))
	--deleteSummonersModel()
	print("------------------summonersmodel-------------------------\n")
end

function  herocardModel()
	print("\n----------------herocardmodel-------------------------")
	local hero = newHeroCardModel()
	hero:setLevel(2)
	hero:setExp(10000)
	hero:setStar(5)
	print(hero:getCardID())
	print(hero:getLevel())
	print(hero:getExp())
	print(hero:getStar())
	print(hero:addEquip(1001))
	print(hero:addEquip(1002))
	dumpTable(hero:getEquips())
	print(hero:removeEquip(1001))
	print(hero:clearEquips())
	print(hero:addSkill(101))
	print(hero:addSkill(102))
	print(hero:upgradeSkill(101))
	print(hero:getSkillLevel(101))
	dumpTable(hero:getSkills())
	--deleteHeroCardModel()
	print("------------------herocardmodel-------------------------\n")
end

function  herocardbagModel()
	print("\n----------------herocardbagmodel-------------------------")
	local bag = newHeroCardBagModel()
        print(bag:addHeroCard(101, 10001))
	print(bag:addHeroCard(102, 10002))
	print(bag:removeHeroCard(102))
	dumpTable(bag:getHeroCards())
	local model = bag:getHeroCard(101)
	print(model)
	--deletelevelModel()
	print("------------------herocardbagsmodel-------------------------\n")
end

function  stageModel()
	print("\n----------------stagemodel-------------------------")
	local level = newStageModel()
	dumpTable(level:getStageStates())
	dumpTable(level:getChapterStates())
	--deletestageModel()
	print("------------------stagesmodel-------------------------\n")
end

function gameModel()
	print("\n----------------gamemodel-------------------------")
	game = getGameModel();
	print("getGameModel");	
	dumpTableKey(getmetatable(game))
	--game:init()
	local room = game:openRoom();
	print("openRoom");
	dumpTableKey(getmetatable(game))
	print('dump room')
	dumpTableKey(getmetatable(room))
	--dumpTable(room)
	local rm = game:getRoom()
	dumpTableKey(getmetatable(rm))
	print("getRoom");
	--dumpTable(rm)
	game:closeRoom()
	print("closeRoom");
	local user = game:getUserModel()
	dumpTableKey(getmetatable(user))
	print("getUserModel");	
	--dumpTable(user)
	local bag = game:getBagModel()
	dumpTableKey(getmetatable(bag))
	print("getBagModel");
	--dumpTable(bag)
	local herocardbag = game:getHeroCardBagModel()
	dumpTableKey(getmetatable(herocardbag))
	print("getHeroCardBagModel");
	--dumpTable(herocardbag)
	local summoner = game:getSummonersModel()
	dumpTableKey(getmetatable(summoner))
	print("getSummonersModel");
	--dumpTable(summoner)
	local stage = game:getStageModel()
	dumpTableKey(getmetatable(stage))
	print("getStageModel");
	--dumpTable(stage)
	print(game:getNow())
	print(game:getLoginServerTime())
	print(game:getLoginClientTime())
	print(game:setFreePickResetTime(12345))
	print(game:getFreePickResetTime())
	print(game:setFreePickCardTime(54321))
	print(game:getFreePickCardTime())
	print("------------------gamesmodel-------------------------\n")
end

--userModel()
--bagModel()
--summonersModel()
--herocardModel()
--herocardbagModel()
--stageModel()
gameModel()