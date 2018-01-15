--[[
	UIEquipMake 装备打造界面

]]

-- csb文件
local csbFile = ResConfig.UIEquipMake.Csb2

local equipMakeModel = getGameModel():getEquipMakeModel()

local quality = {1252,1253,1254,1255,1256}

local UIEquipMakeView = class("UIEquipMakeView", function()
		return require("common.UIView").new()
	end)

function UIEquipMakeView:ctor()
	self.rootPath	= csbFile.ViewPanel
	self.root   	= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)


	-- 退出按钮
	self.mBackButton = CsbTools.getChildFromPath(self.root, "MainPanel/CloseButton")
	CsbTools.initButton(self.mBackButton, handler(self, self.backBtnCallBack), nil, nil, "mBackButton")

	self.mName 		= CsbTools.getChildFromPath(self.root, "MainPanel/Name")
	self.mLevel   	= CsbTools.getChildFromPath(self.root, "MainPanel/Level")
	self.mJob 		= CsbTools.getChildFromPath(self.root, "MainPanel/Job")
	self.mPropItemIcon = CsbTools.getChildFromPath(self.root, "MainPanel/PropItem/Item/icon")
	self.mPropItemNum =  CsbTools.getChildFromPath(self.root, "MainPanel/PropItem/Item/Num")
	self.mPropItemNum:setVisible(false)

	self.mLow 		= CsbTools.getChildFromPath(self.root, "MainPanel/Low")
	self.mHigh   	= CsbTools.getChildFromPath(self.root, "MainPanel/High")
	self.mAttriScrollView 		= CsbTools.getChildFromPath(self.root, "MainPanel/AttriScrollView")
	self.mAttriScrollView:setScrollBarEnabled(false)
	self.mAttriBar = CsbTools.getChildFromPath(self.root, "MainPanel/AttriScrollView/AttriBar/AttriBar")
	self.mPropBarSize = self.mAttriBar:getContentSize()

end

function UIEquipMakeView:onOpen(preId, equipInfo, isQuality)
	self.mIsQuality = isQuality
 	self:initUI(equipInfo)
end

function UIEquipMakeView:onClose()
end

function UIEquipMakeView:onTop()
end

--------------- 界面初始化----------------------
function UIEquipMakeView:initUI(equipInfo)
	self.mName:setString(equipInfo.name)
	self.mLevel:setString(equipInfo.level)
	self.mJob:setString(equipInfo.job)

	CsbTools.replaceImg(self.mPropItemIcon, equipInfo.equipData.Item_Icon)

	self.mHead,self.mTail,self.mMinId,self.mMaxId = self:getEquipQualityByIndex(equipInfo.equipData)
	print("self.mHead,self.mTail,self.mMinId,self.mMaxId ",self.mHead,self.mTail,self.mMinId,self.mMaxId )

	self.mLow:setString(CommonHelper.getUIString(600).."("..CommonHelper.getUIString(quality[self.mHead])..")")

	self.mHigh:setString(CommonHelper.getUIString(599).."("..CommonHelper.getUIString(quality[self.mTail])..")")


	self:initLeftScrollView()
end


-- 初始化装备选择的scrollView
function UIEquipMakeView:initLeftScrollView()
	
	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5

	self.mMinNormalCount =getEquipBaseAttriteCount(self.mMinId)
	self.mMinRandCount = getEquipRandAttriteCount(self.mMinId)

	self.mMaxNormalCount =getEquipBaseAttriteCount(self.mMaxId)
	self.mMaxRandCount = getEquipRandAttriteCount(self.mMaxId)


	local hang = self.mMaxNormalCount+self.mMaxRandCount+1

	local innerSize = self.mAttriScrollView:getContentSize()

	local h = offsetY + hang*self.mPropBarSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mAttriScrollView:getInnerContainerSize().height ~= innerSize.height then
	    self.mAttriScrollView:setInnerContainerSize(innerSize)
    end  

	self.mAttriScrollView:removeAllChildren()
	local isBool = false
	local j = 0
	for i=1,hang do
		j = j + 1
		local itemCsb = getResManager():cloneCsbNode(csbFile.AttriBar)

		local posX = offsetX + self.mPropBarSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mPropBarSize.height - (i - 1)*intervalY
		itemCsb:setPosition(cc.p(posX, posY))

		self.mAttriScrollView:addChild(itemCsb)	

		if not isBool and i>self.mMaxNormalCount then --特殊处理
			isBool = true
			self:initAttriItemSpecial(itemCsb)
			j = 0
		else
			self:initAttriItem(itemCsb, j, isBool)			
		end
	end
	self.mAttriScrollView:jumpToTop()
end

function UIEquipMakeView:initAttriItemSpecial(cardCsb)
	local Attri = CsbTools.getChildFromPath(cardCsb, "AttriBar/Attri")
	local Low = CsbTools.getChildFromPath(cardCsb, "AttriBar/Low")
	local High = CsbTools.getChildFromPath(cardCsb, "AttriBar/High")

	local CountLow = equipMakeModel:getEquipQualityRandCount(self.mHead) --最低品质的全部属性条数
	local CountHi  = equipMakeModel:getEquipQualityRandCount(self.mTail) --最高


	local temp = CountLow - self.mMinNormalCount
	temp = temp >0 and temp or 0
	Attri:setString(CommonHelper.getUIString(430))

	local wu = CommonHelper.getUIString(570)
	local tiao = CommonHelper.getUIString(429)

	Low:setString(temp==0 and wu or CommonHelper.getUIString(1706)..temp..tiao)
	temp = CountHi - self.mMaxNormalCount
	temp = temp >0 and temp or 0
	High:setString(temp==0 and wu or CommonHelper.getUIString(1706)..temp..tiao)
	if not self.mIsQuality  then
		Low:setString(wu) 
	end
		
end

function UIEquipMakeView:initAttriItem(cardCsb, i, isBool)
	local Attri = CsbTools.getChildFromPath(cardCsb, "AttriBar/Attri")
	local Low = CsbTools.getChildFromPath(cardCsb, "AttriBar/Low")
	local High = CsbTools.getChildFromPath(cardCsb, "AttriBar/High")

	local qualityDataMin = getEquipPropCreateConfItem(self.mMinId)
	local qualityDataMax = getEquipPropCreateConfItem(self.mMaxId)

	if not isBool then
		local minNameID  = qualityDataMin.BaseProp[i].nEffectID
		local minData1 = qualityDataMin.BaseProp[i].nMinValue
		local maxData1 = qualityDataMin.BaseProp[i].nMaxValue

		local minData2 = qualityDataMax.BaseProp[i].nMinValue
		local maxData2    = qualityDataMax.BaseProp[i].nMaxValue

		local name = CommonHelper.getRoleAttributeString(minNameID)
		local minString = minData1.."~"..maxData1
		local maxString =minData2.."~"..maxData2

		Attri:setString(string.format(name,"+"))
		Low:setString(minString)
		High:setString(maxString)
	else
		local minNameID  = 0
		local minData1 = 0
		local maxData1    = 0
		local maxNameID  = 0
		local minData2 = 0
		local maxData2 = 0

		if #qualityDataMin.ExtraProp > 0 then
			 minNameID  = qualityDataMin.ExtraProp[i].nEffectID
			 minData1 = qualityDataMin.ExtraProp[i].nMinValue
			 maxData1    = qualityDataMin.ExtraProp[i].nMaxValue
		end

		if #qualityDataMax.ExtraProp > 0 then
			 maxNameID  = qualityDataMax.ExtraProp[i].nEffectID
			 minData2 = qualityDataMax.ExtraProp[i].nMinValue
			 maxData2    = qualityDataMax.ExtraProp[i].nMaxValue
		end

		local minString = minData1.."~"..maxData1
		local maxString =minData2.."~"..maxData2

		local name = CommonHelper.getRoleAttributeString(maxNameID)
		Attri:setString(string.format(name,"+"))

		if minNameID ~=0 then
			Low:setString(minString)
		else
			Low:setString("")
		end

		if  maxNameID~=0 then
			High:setString(maxString)
		else
			High:setString("")
		end
	end
end

-- 返回
function UIEquipMakeView:backBtnCallBack(ref)
	UIManager.close()
end



function UIEquipMakeView:getEquipQualityByIndex(equipData)
	if equipData then
		local head = 1
		local tail = 5
		local minId = 0
		local maxId = 0
		local name = ""
		print("是否为精练", self.mIsQuality )
		if self.mIsQuality then
			name = "_QualityCastWeight"
		else
			name = "_NormalCastWeight"
		end

		for i=1,5 do
			local temp = equipData["Quality"..i..name]
			if temp ~= 0 then
				head = i
				minId = equipData["Quality"..i.."_EqCreatID"]
				if head == 1 then
					
				end
				break
			end
		end

		for i=5,1,-1 do
			local temp = equipData["Quality"..i..name]
			if temp ~= 0 then
				tail = i
				maxId = equipData["Quality"..i.."_EqCreatID"]
				break
			end
		end
		
		return head,tail,minId,maxId

	end
end

return UIEquipMakeView