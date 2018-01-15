local UserModel = require"model.UserModel"
local BagModel = require"model.BagModel"
local EquipModel = require"model.EquipModel"
local HeroCardBagModel = require"model.HeroCardBagModel"
local SummonersModel = require"model.SummonersModel"
local StageModel = require"model.StageModel"
local TeamModel = require"model.TeamModel"
local TaskModel = require"model.TaskModel"
local AchieveModel = require"model.AchieveModel"
local GuideModel = require"model.GuideModel"
local UnionModel = require"model.UnionModel"
local MailModel = require"model.MailModel"
local GoldTestModel = require"model.GoldTestModel"
local HeroTestModel = require"model.HeroTestModel"
local TowerTestModel = require"model.TowerTestModel"
local PvpModel = require"model.PvpModel"
local ShopModel = require"model.ShopModel"
local OperateActiveModel = require"model.OperateActiveModel"
local HeadModel = require"model.HeadModel"
local SevenCrazyModel = require"model.SevenCrazyModel"
local NoticesModel = require("model.NoticesModel")
local EquipMakeModel = require("model.EquipMakeModel")
local PvpChestModel = require("model.PvpChestModel")
local BlueGemModel = require("model.BlueGemModel")

-- 公会佣兵模型,放在这里管理,只创建不初始化,进入佣兵时才初始化
-- 公会模型没有移到Lua下,先在gamemodel下
local UnionMercenaryModel = require"model.UnionMercenaryModel"
local ExpeditionModel = require"model.ExpeditionModel"

local GameModel = class("GameModel")

local _getGameModel = getGameModel
function getGameModel()
	return GameModel:getInstance()
end

local _initModelData = initModelData
function initModelData(subCmd, buffData)
	getGameModel():init(subCmd, buffData)
end

function GameModel:ctor()
	self.mUserModel = UserModel.new()
	self.mBagModel = BagModel.new()
	self.mEquipModel = EquipModel.new()
	self.mHeroCardBagModel = HeroCardBagModel.new()
	self.mSummonersModel = SummonersModel.new()
	self.mStageModel = StageModel.new()
	self.mTeamModel = TeamModel.new()
	self.mTaskModel = TaskModel.new()
	self.mAchieveModel = AchieveModel.new()
	self.mGuideModel = GuideModel.new()
	self.mUnionModel = UnionModel.new()
	self.mMailModel = MailModel.new()
	self.mGoldTestModel = GoldTestModel.new()
	self.mHeroTestModel = HeroTestModel.new()
	self.mTowerTestModel = TowerTestModel.new()
	self.mPvpModel = PvpModel.new()
	self.mShopModel = ShopModel.new()
	self.mOperateActiveModel = OperateActiveModel.new()
	self.mHeadModel = HeadModel.new()
	self.mUnionMercenaryModel = UnionMercenaryModel.new()
	self.mExpeditionModel = ExpeditionModel.new()
	self.mEquipMakeModel = EquipMakeModel.new()
	self.mSevenCrazyModel = SevenCrazyModel.new()
    self.mNoticesModel = NoticesModel.new()
    self.mPvpChestModel = PvpChestModel.new()
    self.mBlueGemModel = BlueGemModel.new()

    self.mLoginServerTime = os.time()
    self.mLoginClientTime = os.time()
end

-- 启动时调用多次初始化，根据不同的协议初始化对应的模型
function GameModel:init(subCmd, buffData)
	if subCmd == LoginProtocol.LoginSC then
		self.mLoginServerTime = buffData:readInt()
		self.mLoginClientTime = os.time()
	elseif subCmd == LoginProtocol.UserModelSC then
		self.mUserModel:init(buffData)
        self.mNoticesModel:init()
	elseif subCmd == LoginProtocol.BagModelSC then
		self.mBagModel:init(buffData)
	elseif subCmd == LoginProtocol.EquipModelSC then
		self.mEquipModel:init(buffData)
	elseif subCmd == LoginProtocol.HeroModelSC then
		self.mHeroCardBagModel:init(buffData)
	elseif subCmd == LoginProtocol.SummonerModelSC then
		self.mSummonersModel:init(buffData)
	elseif subCmd == LoginProtocol.StageModelSC then
		self.mStageModel:init(buffData)
	elseif subCmd == LoginProtocol.TeamModelSC then
		self.mTeamModel:init(buffData)
	elseif subCmd == LoginProtocol.TaskModelSC then
		self.mTaskModel:init(buffData)
	elseif subCmd == LoginProtocol.AchieveModelSC then
		self.mAchieveModel:init(buffData)
	elseif subCmd == LoginProtocol.GuideModelSC then
		self.mGuideModel:init(buffData)		
	elseif subCmd == LoginProtocol.UnionModelSC then
		self.mUnionModel:init(buffData)
	elseif subCmd == LoginProtocol.MailModelSC then
		self.mMailModel:init(buffData)
	elseif subCmd == LoginProtocol.GoldTestModelSC then
		self.mGoldTestModel:init(buffData)
	elseif subCmd == LoginProtocol.HeroTestModelSC then
		self.mHeroTestModel:init(buffData)
	elseif subCmd == LoginProtocol.TowerTestModelSC then
		self.mTowerTestModel:init(buffData)
	--elseif subCmd == LoginProtocol.PvpModelSC then
		--self.mPvpModel:init(buffData)
	elseif subCmd == LoginProtocol.ShopModelSC then
		self.mShopModel:init(buffData)
	elseif subCmd == LoginProtocol.OperateActiveModelSC then
		self.mOperateActiveModel:init(buffData)
	elseif subCmd == LoginProtocol.HeadSC then
		self.mHeadModel:init(buffData)
	elseif subCmd == LoginProtocol.UnionShopSC then
		self.mShopModel:initUnionShop(buffData)
	elseif subCmd == LoginProtocol.SevenCrazySC then
		self.mSevenCrazyModel:init(buffData)
    elseif subCmd == LoginProtocol.PvpChestModelSC then
        self.mPvpChestModel:init(buffData)
    elseif subCmd == LoginProtocol.LoginBlueGemSC then
        self.mBlueGemModel:init(buffData)
	else
		_initModelData(buffData)
	end
	return true
end

function GameModel:getInstance()
	if not GameModelInstance then
		GameModelInstance = GameModel.new()
	end
	return GameModelInstance
end

function GameModel:destroy()
	GameModelInstance = nil
end

function GameModel:openRoom()
	return _getGameModel():openRoom()
end

function GameModel:getRoom()
	return _getGameModel():getRoom()
end

function GameModel:closeRoom()
	_getGameModel():closeRoom()
end

-- 获取服务端当前的系统时间（根据相对时间进行计算）
function GameModel:getNow()
	local clientNow = os.time()
	return self.mLoginServerTime + clientNow - self.mLoginClientTime
end

-- 是否为免费抽卡时间
function GameModel:isFreePickCard()
	return self.mUserModel:getFreeHeroTimes() > 0
end

function GameModel:getLoginServerTime()
	return self.mLoginServerTime
end

function GameModel:getLoginClientTime()
	return self.mLoginClientTime
end

function GameModel:getUserModel()  
	return self.mUserModel
end
    
function GameModel:getBagModel() 
	return self.mBagModel
end

function GameModel:getEquipModel() 
	return self.mEquipModel
end
    
function GameModel:getHeroCardBagModel() 
	return self.mHeroCardBagModel
end
    
function GameModel:getSummonersModel() 
	return self.mSummonersModel
end

function GameModel:getStageModel() 
	return self.mStageModel
end

function GameModel:getTeamModel() 
	return self.mTeamModel
end

function GameModel:getTaskModel()
	return self.mTaskModel
end

function GameModel:getAchieveModel() 
	return self.mAchieveModel
end
	
function GameModel:getGuideModel() 
 	return self.mGuideModel
end

function GameModel:getUnionModel()
	return self.mUnionModel
end

function GameModel:getPvpChestModel()
    return self.mPvpChestModel
end

-- 暂时不写
--function GameModel:getUnionModel()
-- 	return _getGameModel():getUnionModel()
--end

-- 暂时不写
function GameModel:getActivityInstanceModel()
	return _getGameModel():getActivityInstanceModel()
end
	
function GameModel:getMailModel() 
	return self.mMailModel
end
	
function GameModel:getGoldTestModel() 
	return self.mGoldTestModel
end
	
function GameModel:getHeroTestModel()
	return self.mHeroTestModel
end
	
function GameModel:getTowerTestModel()
	return self.mTowerTestModel
end
    
function GameModel:getPvpModel()
	return _getGameModel():getPvpModel()
end
    
function GameModel:getShopModel()
	return self.mShopModel
end
    
function GameModel:getOperateActiveModel()
	return self.mOperateActiveModel
end

function GameModel:getSevenCrazyModel()
	return self.mSevenCrazyModel
end

function GameModel:getNoticesModel()
	return self.mNoticesModel
end
   
function GameModel:getHeadModel()
	return self.mHeadModel
end

function GameModel:getUnionMercenaryModel()
	return self.mUnionMercenaryModel
end

function GameModel:getExpeditionModel()
    return self.mExpeditionModel
end
function GameModel:getEquipMakeModel()
	return self.mEquipMakeModel
end

function GameModel:getBlueGemModel()
	return self.mBlueGemModel
end
return GameModel