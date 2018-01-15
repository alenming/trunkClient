--[[
	UIEquipMake 装备打造界面

]]

-- csb文件
local csbFile = ResConfig.UIEquipMake.Csb2
local btnFile = "ui_new/g_gamehall/b_bag/AllButton2.csb"
local downListBufftonFile = "ui_new/g_gamehall/s_smith/DownListButton.csb"
local AllButton = "ui_new/g_gamehall/b_bag/AllButton.csb"
local breakButton = "ui_new/g_gamehall/s_smith/BreakButton.csb"

local MakeItem = "ui_new/g_gamehall/s_smith/MakeItem.csb"
local MakeButton = "ui_new/g_gamehall/s_smith/MakeButton.csb"

local isQuality = cc.UserDefault:getInstance():getBoolForKey("isQuality")

local equipMakeModel = getGameModel():getEquipMakeModel()
local UIEquipMakeRedHelper = require("game.equipMake.UIEquipMakeRedHelper")
local maxCount = 10

local buttonType = {equipMake  = 1,equipBreak = 2}
--以后要拓展就在这里拓展就好了
-- 战斗等职业
local jobType = {[1]=6, [2]=1, [3]=2, [4]=3, [5]=4, [6]=5}
-- 等级
local levelType = {1,2,3}
-- 部位
local partType = {1,2,3,4,5,6}

local levelName = {20,35,50}   --如果以后要拓展,记得去UIEquipBag的part7BtnCallBack函数一起修改,这些都是策划给你的坑

-- 职业的语言包
local jobName = {[1]=1260, [2]=1261, [3]=1262, [4]=1263, [5]=1264, [6]=520}
-- 部位语言包
local partName = {612,613,614,615,616,617}

--打造提示语言包
local makeTipName = {1275,1276,1277,1278,1279,1280}

local Cailiao = {}

local effecMusic = {52, 52, 52, 53, 53}

local animation = {"Open", "Open2", "Open2", "Open3", "Open3"}

local UIEquipMake = class("UIEquipMake", function() return require("common.UIView").new() end)

function UIEquipMake:ctor()
	self.rootPath	= csbFile.SmithShop
	self.root   	= getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	self.mIsLevel = true

	self.mCurJob   = jobType[1]
	self.mCurLevel = levelType[1]
	self.mCurParts = partType[1]
	self.mIsCanSend = true
	self.mMoneyenough = true
	self.isSuccess = true
	self.isIng = true
	self.mWhichCaliao = {}

	--红点
	self.mLevelRed = nil
	self.mJobRedPoint = {}
	self.mLevelRedPoint = {}
	self.mPartsRedPoint = {}
	self.mCurIndex = 1

	self.mCurJobBreak = 1--jobType[1]
	self.mIsJobBreak = true
	self.mSelectedCount = 0  -- 勾选的装备数
	self.mBreakMoney = 0     -- 分解需要的金币

	self.mIsMakeBack = false   --在onTop时判断是不是打造结果返回时用

	self.mImportantEquipCount = 0 --分解时勾选的品质大于三的装备个数当为0时表示没有

	self.mEquipDataIndex = {} -- 打造拿到的装备列表
	self.mRealShowEuips = {}  --分解要展示的装备
	self.mBreakEquip = {}

	-- 退出按钮
	self.mBackButton = CsbTools.getChildFromPath(self.root, "BackButton")
	CsbTools.initButton(self.mBackButton, handler(self, self.backBtnCallBack), nil, nil, "mBackButton")

	self.mForging = CsbTools.getChildFromPath(self.root, "Forging")
	self.mForging:setVisible(false)
	self.mForgingText = CsbTools.getChildFromPath(self.mForging, "MainPanel/TextTips/Text_1")

	self.mForgingBackg = CsbTools.getChildFromPath(self.mForging, "Background")
	 CsbTools.initButton(self.mForgingBackg,  handler(self,  self.backGroudCallback), nil, nil, "mTabMakeButton")

	--  打造分解界面切换
	self.mMakeBreakButton = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_7")
	self.mMakeBreakButtonText = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_7/Node/ButtonText")
	CsbTools.initButton(self.mMakeBreakButton,  handler(self,  self.btnCallBack), CommonHelper.getUIString(1240), self.mMakeBreakButtonText, "self.mMakeBreakButton")
	self.mMakeBreakButton:setTag(buttonType.equipMake)
	self.mMakeIcon = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_7/Node/smith_makeicon")
	self.mBreakIcon = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_7/Node/smith_breakicon")
	-- 打造与分解界面
	self.mMakePanel  = CsbTools.getChildFromPath(self.root, "MainPanel/MakePanel")
	self.mBreakPanel = CsbTools.getChildFromPath(self.root, "MainPanel/BreakPanel")
	self.mMakePanel:setVisible(true)
	self.mBreakPanel:setVisible(false)
	--金币钻石
	self.mDiamond  = CsbTools.getChildFromPath(self.root, "MainPanel/Diamond")
	self.mCoin     = CsbTools.getChildFromPath(self.root, "MainPanel/Coin")

	self.mMakeItem = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/MakeItem")

	-- 打造相关
	--左边
	self.mPropScrollView = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/PropScrollView")
	self.mPropScrollView:setScrollBarEnabled(false)
	self.mLevelList      = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/LevelList")  
	--右边
	self.mPriceNum       = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/PriceNum")    --需要金钱
	self.mPropName       = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/PropName")    --装备名字

	self.mMakeButton     	  = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/MakeButton") 
	self.mMakeButtonOrange    = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/MakeButton/Button_Orange")   --精品装备打造装备打造按钮
	self.mMakeButtonGreen     = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/MakeButton/Button_Green")     --普通装备打造装备打造按钮
	self.mMakeButtonGrey      = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/MakeButton/Button_Grey")       --材料不足

	CsbTools.initButton(self.mMakeButtonOrange,  handler(self,  self.beginEquipMake), nil, nil, "Text")
	CsbTools.initButton(self.mMakeButtonGreen,   handler(self,  self.beginEquipMake), nil, nil, "Text")

	self.mTextOrange           = CsbTools.getChildFromPath(self.mMakeButtonOrange, "Text")				   --装备打造文本
	self.mTextGreen            = CsbTools.getChildFromPath(self.mMakeButtonGreen, "Text")				   --装备打造文本
	self.mTextGrey             = CsbTools.getChildFromPath(self.mMakeButtonGrey, "Text")				   --装备打造文本

	for i=1,5 do
		self["Material_"..i] = {}
	end
	for i=1,5 do
		self["Material_"..i].root = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/Material_"..i)  --材料
		self["Material_"..i].node = CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/PropItem")  
		self["Material_"..i].Num = CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/Num")  --材料数量
		self["Material_"..i].Name = CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/Name")  --材料名字
		self["Material_"..i].MaterialIcon = CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/PropItem/Item/icon")  --材料ICON
		self["Material_"..i].Level = CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/PropItem/Item/Level")  --材料ICON
		CsbTools.getChildFromPath(self["Material_"..i].root, "MaterialItem/PropItem/Item/Num"):setVisible(false) 
		item = ccui.Button:create()
        item:setName("CastMaterialButton")
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setTag(i)
		local itemSize = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/Material_1/MaterialItem"):getContentSize()
		item:setContentSize(itemSize)
		CsbTools.initButton(item, handler(self, self.TouchCallBack))
		self["Material_"..i].root:addChild(item)
	end

	self.mCheckBox 		 = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/CheckBox")  --复选框
	self.mCheckBox:addEventListener(handler(self, self.checkBoxSelectedEvent))
    self.mCheckBox:setSelected(isQuality)

    self.mViewButton = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/ViewButton")  
	CsbTools.initButton(self.mViewButton,  handler(self,  self.viewCallBack), nil, nil, "mViewButton")

	self.mQuestion = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/QuestionButton")
	CsbTools.initButton(self.mQuestion,  handler(self,  self.questionCallBack), nil, nil, "mQuestion")

	self.mArrowIcon2 = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/ArrowIcon2")
	self.mArrowIcon  = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/ArrowIcon/smith_arrow_icon_2")

	self.mMakeTip = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/Tips2")

	self.mPropImage = CsbTools.getChildFromPath(self.mMakePanel, "MainPanel/PropImage")
	self.mOldPositionX,self.mOldPositionY = self.mPropImage:getPosition()
	-- 分解相关
	self.mJobListBreak 		= CsbTools.getChildFromPath(self.mBreakPanel, "MainPanel/LevelList")
	self.mJobListBreak:setLocalZOrder(9999)
	self.mBreakButtonFather = CsbTools.getChildFromPath(self.mBreakPanel, "BreakButton")
	self.mBreakButton = CsbTools.getChildFromPath(self.mBreakPanel, "BreakButton/BreakButton")
	CsbTools.initButton(self.mBreakButton, handler(self, self.beginEquipBreakFrist))
	
	self.mPriceNumBreak			= CsbTools.getChildFromPath(self.mBreakPanel, "MainPanel/PriceNum")
	self.mPropScrollViewBreak 	= CsbTools.getChildFromPath(self.mBreakPanel, "MainPanel/PropScrollView")
	self.mPropScrollViewBreak:setScrollBarEnabled(false)
	self.mPropScrollViewBreak:setDirection(1)
	self.mMaterialScrollView 	= CsbTools.getChildFromPath(self.mBreakPanel, "MainPanel/MaterialScrollView")
	self.mMaterialScrollView:setScrollBarEnabled(false)

	-- 金币银币
	self.hallCoinLb = CsbTools.getChildFromPath(self.root, "Coin/Coin/CoinLabel")
    self.hallDiamondLb = CsbTools.getChildFromPath(self.root, "Diamond/Diamond/PowerLabel_0")

	local buyCoinBtn = CsbTools.getChildFromPath(self.root, "Coin/Coin/CoinButton")
	CsbTools.initButton(buyCoinBtn, function ()
		UIManager.open(UIManager.UI.UIGold)
	end)
	-- 购买钻石+按钮
	local buyDiamondBtn = CsbTools.getChildFromPath(self.root, "Diamond/Diamond/PowerButton_0")
	CsbTools.initButton(buyDiamondBtn, function ()
        UIManager.open(UIManager.UI.UIShop, ShopType.DiamondShop)
	end)

	-- item的size
	local itemCsb 	= getResManager():getCsbNode(csbFile.PropBar)
	self.mPropBarSize	= CsbTools.getChildFromPath(itemCsb, "PropItem"):getContentSize()

	local itemCsb1 	= getResManager():getCsbNode(ResConfig.UIBag.Csb2.item)
	self.itemSize	= CsbTools.getChildFromPath(itemCsb1, "Item"):getContentSize()
    itemCsb:cleanup()
    itemCsb1:cleanup()

	self.cailiaoSize = self.itemSize
end

function UIEquipMake:onOpen(preId,isMainCity, uiData)
	self.mMakeTime = 1
	self.mMaxTime = 1
	self.isSuccess = true
	self.mForging:setVisible(false)
	-- 从主城进来时,职业为战士,等级为角色能穿的最好等级
    local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.makeEquipSC)
    local mCallBack = handler(self, self.makeCallBack)
    NetHelper.setResponeHandler(cmd, mCallBack)

    local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.breakEquipSC)
    local mCallBack = handler(self, self.breakCallBack)
    NetHelper.setResponeHandler(cmd, mCallBack)

    local newUiData = {}
    -- 分析打开这个界面的来源数据
	if isMainCity and uiData==nil then

	 	newUiData.Eq_Vocation = 6
	  	newUiData.Eq_Parts    = 1
	  	local userLevel = getGameModel():getUserModel():getUserLevel()
	  	if userLevel < levelName[2] then
	  		newUiData.Eq_Level = 1
	  	elseif  levelName[2] <= userLevel and userLevel < levelName[3] then
	  		newUiData.Eq_Level = 2
	  	elseif  levelName[3] <= userLevel  then
	  		newUiData.Eq_Level = 3
	  	end
	end
	--红点
	UIEquipMakeRedHelper:abcdefg()

 	self:initUI(uiData==nil and newUiData or uiData)
end

function UIEquipMake:onClose()
	local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.makeEquipCS)
 	NetHelper.removeResponeHandler(cmd,handler(self, self.netCallBack))
end

function UIEquipMake:onTop()
	self:initCommonUI()
	self:initRightUI()
	if self.mIsMakeBack then
		self.mIsMakeBack = false
		--用代码写一个漂亮的动画
		if self.mPropImage then
			print("开始播放程序用代码写的一个非常漂亮的动画")
			self.mPropImage:runAction(cc.Sequence:create(cc.MoveBy:create(0.5,{x=700,y=-30}), cc.CallFunc:create(function()
					self.mPropImage:setVisible(false)
					self.mMakeItem:setVisible(true)
					self.mPropImage:setPosition(cc.p(self.mOldPositionX,self.mOldPositionY))
					self.isSuccess = true
              end)))
		end
	end
end

--[[
	uiData 为了可以在不同的界面跳转到这个界面完成不同的初始化,需要打开的时候传入参数
	uiData.Eq_Vocation 职业 uiData.Eq_Level    等级 uiData.Eq_Parts    部位               ]]
--------------- 界面初始化----------------------
function UIEquipMake:initUI(uiData)
	--显示还原
	self.mMakePanel:setVisible(true)
	self.mBreakPanel:setVisible(false)

   	-- 各种打造状态位还原
	self.mIsLevel = true
	-- 分解状态位还原
	self.mIsJobBreak = true
	self.mCurJobBreak = 1--jobType[2]


	self.mCurJob      = uiData.Eq_Vocation
	self.mCurLevel    = uiData.Eq_Level
	self.mCurParts    = uiData.Eq_Parts


	self.mEquipDataIndex = {}
   	self.mEquipDataIndex = equipMakeModel:getEquipByHead(self.mCurJob, levelName[self.mCurLevel])
	--dump(self.mEquipDataIndex)	
	print("查找出来的数据是这些鬼self.mCurJob, self.mCurLevel, self.mCurParts", self.mCurJob, self.mCurLevel, self.mCurParts)

	--打造界面
	self:initCommonUI()
	self:initLeftUI()
	self:initRightUI()

	--分解界面
	self:initBreakUI()
end

function UIEquipMake:initCommonUI()
    local gold = getGameModel():getUserModel():getGold()
    local gem = getGameModel():getUserModel():getDiamond()
    self.hallCoinLb:setString(gold)
    self.hallDiamondLb:setString(gem)
end

function UIEquipMake:initLeftUI()

	self.mJobRedPoint = {}
	self.mLevelRedPoint = {}

	--  等级选择
	local OrderButton = CsbTools.getChildFromPath(self.mLevelList, "OrderButton")
	local ButtonName = CsbTools.getChildFromPath(self.mLevelList, "OrderButton/ButtonName")
	CsbTools.initButton(OrderButton, handler(self, self.levelListCallBack), "OrderButton")
	ButtonName:setString(levelName[self.mCurLevel]..CommonHelper.getUIString(528))

	self.mLevelRed = CsbTools.getChildFromPath(OrderButton, "RedTipPoint")
	self.mLevelRed:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~= nil)
	-- 等级这个要支持拓展,怕被坑,先写好可拓展逻辑
	local DownListView = CsbTools.getChildFromPath(self.mLevelList, "DownListView")
	self.mLevelListBtn = {}
	local template = DownListView:getItem(0):clone()
	DownListView:removeAllItems()
	DownListView:setContentSize(cc.size(DownListView:getContentSize().width,template:getContentSize().height*#levelType))
	for i=1,#levelType do
		self.mLevelListBtn[i] = template:clone()
		self.mLevelListBtn[i]:setTag(levelType[i])
		CsbTools.initButton(self.mLevelListBtn[i], handler(self, self.levelListSonCallBack), "Button_"..i)
		self.mLevelListBtn[i]:setTitleText(levelName[i]..CommonHelper.getUIString(528))
		DownListView:pushBackCustomItem(self.mLevelListBtn[i])

		self.mLevelRedPoint[i] = CsbTools.getChildFromPath(self.mLevelListBtn[i] , "RedTipPoint")
		self.mLevelRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~=nil and UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob][levelName[i]] ~= nil)
	end

	self.mJobList = {}
	for i=1,#jobType do
		self.mJobList[i] = CsbTools.getChildFromPath(self.root, "MainPanel/TabButton_"..i)
		self.mJobList[i]:setTag(i)
		CsbTools.initButton(self.mJobList[i], handler(self, self.jobListSonCallBack), "Button_"..i)
		local text = CsbTools.getChildFromPath(self.mJobList[i], "AllButton/ButtonPanel/NameLabel")
		text:setString(CommonHelper.getUIString(jobName[jobType[i]]))

		self.mJobRedPoint[i] = CsbTools.getChildFromPath(self.mJobList[i] , "AllButton/RedTipPoint")
		self.mJobRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowJobRed[jobType[i]] ~= nil)
	end

   	for i=1,#jobType  do
   		CommonHelper.playCsbAnimate(self.mJobList[i], AllButton, "Normal", false, nil, true)
   		self.mJobList[i]:setLocalZOrder(i)
   	end

	local temp = 1
	for i=1,#jobType do
		if self.mCurJob == jobType[i] then
			temp = i
			break
		end
	end
	CommonHelper.playCsbAnimate(self.mJobList[temp], AllButton, "On", false, nil, true)

	self.mJobList[temp]:setLocalZOrder(99999)
	self:initLeftScrollView()
end

-- 初始化装备选择的scrollView
function UIEquipMake:initLeftScrollView()
	
	local intervalX = 10
	local intervalY = 10
	local offsetX = 0
	local offsetY = 5
	local hang = #self.mEquipDataIndex

	local innerSize = self.mPropScrollView:getContentSize()

	local h = offsetY + hang*self.mPropBarSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mPropScrollView:getInnerContainerSize().height ~= innerSize.height then
	    self.mPropScrollView:setInnerContainerSize(innerSize)
    end  

	self.mPropScrollView:removeAllChildren()
	self.mPartsRedPoint = {}
	self.mCurIndex = self.mEquipDataIndex[1]
	for i,index in ipairs(self.mEquipDataIndex) do
		local item = nil
		item = ccui.Button:create()
        item:setName("CastEquipmentButton")
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.mPropBarSize)
		CsbTools.initButton(item, handler(self, self.propBarTouchCallBack))
		self.mPropScrollView:addChild(item)
		local itemCsb = getResManager():cloneCsbNode(csbFile.PropBar)
		itemCsb:setPosition(cc.p(self.mPropBarSize.width/2, self.mPropBarSize.height/2))
		itemCsb:setTag(7758258)
		item:addChild(itemCsb)	
		local posX = offsetX + self.mPropBarSize.width/2
		local posY = innerSize.height - offsetY - (i - 0.5)*self.mPropBarSize.height - (i - 1)*intervalY
		item:setPosition(cc.p(posX,posY))
		item:setTag(i)
		self:initPropBar(itemCsb, index, i)
	end

	-- 滚动到哪个位置,选定哪件装备
	-- 选定装备了,右边要初始化
	local percent = self.mCurParts==1 and 0 or (self.mCurParts)/6 * 100 
	self.mPropScrollView:jumpToPercentVertical(percent)
	print("self.mCurParts", self.mCurParts)
	local button = self.mPropScrollView:getChildByTag(self.mCurParts)
	if button then
		local itemCsb = button:getChildByTag(7758258)
		CommonHelper.playCsbAnimate(itemCsb, csbFile.PropBar, "Choose", false, nil, true)
	end
end

function UIEquipMake:initPropBar(cardCsb, index, i)
	local equipData = equipMakeModel:getEquipByIndex(index)
	local PropIcon = CsbTools.getChildFromPath(cardCsb, "PropItem/PropIcon")
	local Name = CsbTools.getChildFromPath(cardCsb, "PropItem/Name")
	local Level = CsbTools.getChildFromPath(cardCsb, "PropItem/Level")
	local Body = CsbTools.getChildFromPath(cardCsb, "PropItem/Body")
	self.mPartsRedPoint[i] = CsbTools.getChildFromPath(cardCsb, "PropItem/RedTipPoint")
	self.mPartsRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowPartsRed[index] ~= nil)

	CsbTools.replaceSprite(PropIcon, equipData.Item_Icon)
	Name:setString(CommonHelper.getPropString(equipData.Item_Name))
	Level:setString(equipData.Eq_Level..CommonHelper.getUIString(528))
	Body:setString(CommonHelper.getUIString(partName[equipData.Eq_Parts]))				
end

function UIEquipMake:initRightUI()
	--初始化右边UI时,要把标志们复原 ,不然就发送不了协议了
	self.mIsCanSend = true
	self.mMoneyenough = true
	self.mWhichCaliao = {}
	self.mMakeMoney = 0
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])

	CommonHelper.playCsbAnimate(self.mMakeItem, MakeItem, "Unknow", false, nil, true)

	local myGold = getGameModel():getUserModel():getGold()
	local needGold = isQuality and equipData.Eq_QualityCastGoldCost or equipData.Eq_NormalCastGoldCost
	self.mPriceNum:setString(needGold)    --需要金钱
    self.mPriceNum:setColor(display.COLOR_WHITE)
	if myGold < needGold then
		self.mPriceNum:setColor(display.COLOR_RED)
		self.mIsCanSend = false
		self.mMoneyenough = false -- 金币不足标志位
	end
	self.mMakeMoney = needGold
	self.mPropName:setString(CommonHelper.getPropString(equipData.Item_Name))    --装备名字
	self.mMakeTip:setString(CommonHelper.getUIString(makeTipName[self.mCurParts]))

	--背包中查找材料数量,没有为0
	--材料一到五
	for i=1,5 do
		local id = equipData["Eq_Synthesis"..i]
		print("i =  id ", i , id)
		if id ==0  then
			self["Material_"..i].root:setVisible(false)
		else
            self["Material_"..i].root:setVisible(true)
			local propConf = getPropConfItem(equipData["Eq_Synthesis"..i])
			local count = getGameModel():getBagModel():getItemCountById(equipData["Eq_Synthesis"..i])
			local needCount = equipData["Eq_Synthesis"..i.."Param"]
			self["Material_"..i].Num:setString(count.."/"..needCount)
			self["Material_"..i].Num:setColor(cc.c3b(167,102,0))

			if count < needCount then
				if i~=5 then
					self.mIsCanSend =  false  --有红色,不让发送
				end
				self["Material_"..i].Num:setColor(display.COLOR_RED)
				table.insert(self.mWhichCaliao,i , i)
			end
			local name = CommonHelper.getPropString(propConf.Name)
			self["Material_"..i].Name:setString(name and name or "")

			UIAwardHelper.setPropItemOfConf(self["Material_"..i].node, propConf, 0)

			-- CsbTools.replaceImg(self["Material_"..i].MaterialIcon, propConf.Icon) --icon
			-- local frame = getItemLevelSettingItem(propConf.Quality).ItemFrame
			-- CsbTools.replaceImg(self["Material_"..i].Level, frame) --底图
		end
	end

	self.mTextOrange:setString(CommonHelper.getUIString(1245))  --显示精品打造
	self.mTextGreen:setString( CommonHelper.getUIString(1244))  --显示普通打造
	self.mTextGrey:setString(CommonHelper.getUIString(137))  	--材料不足

	-- checkBox设置,有本地数据
	self.mArrowIcon2:setVisible(false)--两个箭头
	self.mArrowIcon:setVisible(false)
	if isQuality then  -- 选中
		self.mArrowIcon2:setVisible(true)
		self.mArrowIcon:setVisible(true)
		CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Orange", false, nil, true)
    else                    -- 取消
    	CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Green", false, nil, true)
		self.mArrowIcon2:setVisible(false)
		self.mArrowIcon:setVisible(false)
    end

    -- if not self.mMoneyenough then
    -- 	CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Grey", false, nil, true)
    -- end
end

-- 分解部分API
function UIEquipMake:initBreakUI()
	-- 职业选择
	local OrderButtonB = CsbTools.getChildFromPath(self.mJobListBreak, "OrderButton")
	local ButtonNameB = CsbTools.getChildFromPath(self.mJobListBreak, "OrderButton/ButtonName")
	CsbTools.initButton(OrderButtonB, handler(self, self.jobListCallBackBreak), "OrderButtonB")
	ButtonNameB:setString(self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))

	local DownListViewB = CsbTools.getChildFromPath(self.mJobListBreak, "DownListView")
	local template = DownListViewB:getItem(0):clone()

	DownListViewB:removeAllItems()
	DownListViewB:setContentSize(cc.size(DownListViewB:getContentSize().width,template:getContentSize().height*6))

	self.mLevelListBtnBreak = {}
	for i=1,6 do
		self.mLevelListBtnBreak[i] = template:clone()
		self.mLevelListBtnBreak[i]:setTag(i)
		CsbTools.initButton(self.mLevelListBtnBreak[i], handler(self, self.jobListSonCallBackBreak), "Button_"..i)
		self.mLevelListBtnBreak[i]:setTitleText(i==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[i-1]))
		DownListViewB:pushBackCustomItem(self.mLevelListBtnBreak[i])
	end

	self.mShowEquips = {}
	self.mShowEquips = equipMakeModel:getEquipModelCanBreakEquip()
	self:selectEquip()
	self:initTopScrollViewBreak()
	CommonHelper.playCsbAnimate(self.mBreakButtonFather, breakButton,  self.mSelectedCount > 0 and "Able" or "Disable", false, nil, true)
	--dump(self.mRealShowEuips)
	self:initDowniScrollViewBreak()

end

function UIEquipMake:initTopScrollViewBreak()

	self.mPropScrollViewBreak:removeAllChildren()
	if #self.mRealShowEuips == 0 then
		self.mPropScrollViewBreak:setInnerContainerSize(self.mPropScrollViewBreak:getContentSize())
		return
	end

	local itemPlace = {}
	local hang = 0
	local lie = 8

	for i, info in ipairs(self.mRealShowEuips) do
		if lie == 8 then
			hang = hang + 1
			lie = 1
		else
			lie = lie + 1
		end
		table.insert(itemPlace, {hang = hang, lie = lie})
	end

	local intervalX = 9
	local intervalY = 9
	local offsetX = 6
	local offsetY = 6
	local innerSize = self.mPropScrollViewBreak:getContentSize()
	--算scrollview高的大小
	local hang = itemPlace[#itemPlace].hang

	local h = offsetY + hang*self.itemSize.height + (hang + 1)*intervalY
	if h > innerSize.height then
		innerSize.height = h
	end

    if self.mPropScrollViewBreak:getInnerContainerSize().height ~= innerSize.height then
	    self.mPropScrollViewBreak:setInnerContainerSize(innerSize)
    end      

	for i=1,#itemPlace do
		local item = nil
		item = ccui.Button:create()
		item:setTouchEnabled(true)
		item:setScale9Enabled(true)
		item:setContentSize(self.itemSize)
		CsbTools.initButton(item, handler(self, self.itemCallBack))

		local itemCsb = getResManager():cloneCsbNode(csbFile.PropItem)
		itemCsb:setPosition(cc.p(self.itemSize.width/2, self.itemSize.height/2))
		itemCsb:setTag(7758258)
		self:initTopitem(itemCsb, i)
		item:addChild(itemCsb)	

		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local posX = offsetX + (lie - 0.5)* self.itemSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.itemSize.height - (hang - 1)*intervalY
		item:setPosition(cc.p(posX,posY))
		item:setTag(i)

		self.mPropScrollViewBreak:addChild(item)
	end
end

function UIEquipMake:initTopitem(itemCsb, index)
	local icon = CsbTools.getChildFromPath(itemCsb, "PropItem/Item/icon")
	local level = CsbTools.getChildFromPath(itemCsb, "PropItem/Item/Level")
	local mathLa = CsbTools.getChildFromPath(itemCsb, "PropItem/Item/Num")
	mathLa:setVisible(false)

	if self.mRealShowEuips[index].propConf ~= nil then
		CsbTools.replaceImg(level, getItemLevelSettingItem(self.mRealShowEuips[index].propConf.Quality).ItemFrame)
		CsbTools.replaceImg(icon, self.mRealShowEuips[index].propConf.Icon)
	else
		CsbTools.replaceImg(level, getItemLevelSettingItem(1).ItemFrame)
	end
end

function UIEquipMake:initDowniScrollViewBreak()

	self.mMaterialScrollView:removeAllChildren()

	local size = 0
	for _,_ in pairs(Cailiao) do
		size = size + 1
	end

	if size == 0 then
		self.mMaterialScrollView:setInnerContainerSize(self.mMaterialScrollView:getContentSize())
		return
	end

	local itemPlace = {}
	local hang = 0
	local lie = 8

	for i,id in pairs(self.mXXXX) do
		if id ~=0 then
			if lie == 8 then
				hang = hang + 1
				lie = 1
			else
				lie = lie + 1
			end
			table.insert(itemPlace, {hang = hang, lie = lie, id = id})
		end
	end

	if #itemPlace ==0 then
		return
	end

	local intervalX = 9
	local intervalY = 9
	local offsetX = 6
	local offsetY = 6
	local innerSize = self.mMaterialScrollView:getContentSize()
	--算scrollview宽的大小
	local lie = itemPlace[#itemPlace].lie

	local w = offsetX + lie*self.cailiaoSize.height + (lie + 1)*intervalX
	if w > innerSize.width then
		innerSize.width = w
	end

    if self.mMaterialScrollView:getInnerContainerSize().width ~= innerSize.width then
	    self.mMaterialScrollView:setInnerContainerSize(innerSize)
    end      

	for i=1,#itemPlace do
		local item = nil
		item = ccui.Button:create()
		item:setTouchEnabled(false)
		item:setScale9Enabled(true)
		item:setContentSize(self.cailiaoSize)
		--CsbTools.initButton(item, handler(self, self.itemCallBack))

		local itemCsb = getResManager():cloneCsbNode(ResConfig.UIBag.Csb2.item)--csbFile.MaterialItem)
		itemCsb:setPosition(cc.p(self.cailiaoSize.width/2, self.cailiaoSize.height/2))
		itemCsb:setTag(7758258)
		self:initDownitem(itemCsb, itemPlace[i].id)
		item:addChild(itemCsb)	

		local hang = itemPlace[i].hang
		local lie = itemPlace[i].lie
		local posX = offsetX + (lie - 0.5)* self.cailiaoSize.width + (lie - 1)*intervalX
		local posY = innerSize.height - offsetY - (hang - 0.5)*self.cailiaoSize.height - (hang - 1)*intervalY
		item:setPosition(cc.p(posX,posY))
		item:setTag(i)

		self.mMaterialScrollView:addChild(item)
	end
end

function UIEquipMake:initDownitem(itemCsb, id)

	local icon = CsbTools.getChildFromPath(itemCsb, "Item/icon")
	local mathLa = CsbTools.getChildFromPath(itemCsb, "Item/Num")
	local bg = CsbTools.getChildFromPath(itemCsb, "Item/Level")
	mathLa:setString(Cailiao[id])
	local iconName = getPropConfItem(id)
	CsbTools.replaceImg(icon, iconName.Icon)
	local frame = getItemLevelSettingItem(iconName.Quality).ItemFrame
	CsbTools.replaceImg(bg, frame)
end

function UIEquipMake:itemCallBack(ref)
	local tag = ref:getTag()
	print("tag is", tag)
	local button = self.mPropScrollViewBreak:getChildByTag(tag)
	if button then
		local itemCsb = button:getChildByTag(7758258)
		if itemCsb then
			if not self.mRealShowEuips[tag].isSelected and self.mSelectedCount >= 10 then
				CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1288))
				return
			end

			local SelectImage = CsbTools.getChildFromPath(itemCsb, "SelectImage")
			self.mRealShowEuips[tag].isSelected = not SelectImage:isVisible()
			SelectImage:setVisible(not SelectImage:isVisible())

			self.mBreakMoney = self.mRealShowEuips[tag].isSelected and (self.mBreakMoney + self.mRealShowEuips[tag].breakData.Gold) or 
			(self.mBreakMoney - self.mRealShowEuips[tag].breakData.Gold)
			
			self.mSelectedCount = self.mRealShowEuips[tag].isSelected and (self.mSelectedCount + 1) or (self.mSelectedCount - 1)
			print("self.mSelectedCount", self.mSelectedCount)
			if self.mRealShowEuips[tag].propConf.Quality >2 then  --高品质
				self.mImportantEquipCount = self.mRealShowEuips[tag].isSelected and (self.mImportantEquipCount + 1) or (self.mImportantEquipCount - 1)
			end
			
		end
	end
	local text = CsbTools.getChildFromPath(self.mBreakButton, "PriceNum")
	text:setString(self.mBreakMoney)
	CommonHelper.playCsbAnimate(self.mBreakButtonFather, breakButton,  self.mSelectedCount > 0 and "Able" or "Disable", false, nil, true)

	-- 材料计算
	for i=1,#self.mRealShowEuips[tag].breakData.Decomposit do
		local id = self.mRealShowEuips[tag].breakData.Decomposit[i].Decomposit
		local count = self.mRealShowEuips[tag].breakData.Decomposit[i].DecompositionParam
		print("id,  count", id, count)
		if Cailiao[id] == nil then
			table.insert(Cailiao,id ,count)
		else
			Cailiao[id] = self.mRealShowEuips[tag].isSelected and Cailiao[id] + count or Cailiao[id] - count
			if Cailiao[id] == 0 then
				Cailiao[id] = nil
			end
		end
	end
	print("可以得到的材料是下面这堆垃圾")
	--dump(Cailiao)
	self:reSortBrekCailiao()
	--dump(Cailiao)
	self:initDowniScrollViewBreak()
end

-- 重新塞选 以职业
function UIEquipMake:selectEquip()
	self.mSelectedCount = 0
	self.mBreakMoney = 0
	self.mImportantEquipCount = 0
	self.mRealShowEuips = {}
	Cailiao = {}
	local function job1()
		print("job1选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
			if #info.breakData.Vocation~=0 then
				for i=1, #info.breakData.Vocation do
					if info.breakData.Vocation[i]==1 then
						table.insert(self.mRealShowEuips, info)
						break
					end
				end
			end
		end
	end

	local function job2()
		print("job2选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
			if #info.breakData.Vocation~=0 then
				for i=1, #info.breakData.Vocation do
					if info.breakData.Vocation[i]==2 then
						table.insert(self.mRealShowEuips, info)
						break
					end
				end
			end
		end
	end

	local function job3()
		print("job3选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
			if #info.breakData.Vocation~=0 then
				for i=1, #info.breakData.Vocation do
					if info.breakData.Vocation[i]==3 then
						table.insert(self.mRealShowEuips, info)
						break
					end
				end
			end
		end
	end

	local function job4()
		print("job4选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
			if #info.breakData.Vocation~=0 then
				for i=1, #info.breakData.Vocation do
					if info.breakData.Vocation[i]==4 then
						table.insert(self.mRealShowEuips, info)
						break
					end
				end
			end
		end
	end

	local function job5()
		print("job5选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
			if #info.breakData.Vocation~=0 then
				for i=1, #info.breakData.Vocation do
					if info.breakData.Vocation[i]==5 then
						table.insert(self.mRealShowEuips, info)
						break
					end
				end
			end
		end
	end

	local function job6()
		for _,info in pairs(self.mShowEquips) do
			info.isSelected = false
		end
		print("job6选择的是",self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
		self.mRealShowEuips = self.mShowEquips
	end

	local func = {job1,job2,job3,job4,job5,job6}
	func[self.mCurJobBreak==1 and 6 or self.mCurJobBreak-1]()

	self:reSortEquip()
end

-- 可分解的装备排序
function UIEquipMake:reSortEquip()
	-- local function sortIDByLv(info1, info2)
	-- 	if info1.breakData.Level < info2.breakData.Level then
	-- 		return true
	-- 	elseif info1.breakData.Level == info2.breakData.Level then
	-- 		if info1.propConf.Quality < info2.propConf.Quality then
	-- 			return true
	-- 		elseif info1.propConf.Quality == info2.propConf.Quality then
	-- 			if info1.breakData.Parts < info2.breakData.Parts then
	-- 				return true
	-- 			elseif info1.breakData.Parts == info2.breakData.Parts then
	-- 				if info1.equipId < info2.equipId then
	-- 					return true
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- 	return false
	-- end

	local function sortIDByLv(info1, info2)
		if info1.propConf.Quality < info2.propConf.Quality then
			return true
		elseif info1.propConf.Quality == info2.propConf.Quality then
			if info1.breakData.Level < info2.breakData.Level then
				return true
			elseif info1.breakData.Level == info2.breakData.Level then
				if info1.breakData.Parts < info2.breakData.Parts then
					return true
				elseif info1.breakData.Parts == info2.breakData.Parts then
					if info1.equipId < info2.equipId then
						return true
					end
				end
			end
		end
		return false
	end

	table.sort(self.mRealShowEuips, sortIDByLv)	
end

-- 分解可获得材料的排序
function UIEquipMake:reSortBrekCailiao()
	local function sortIDByQuality(id1, id2)

		local info1 = getPropConfItem(id1)
		local info2 = getPropConfItem(id2)
		if info1.Quality > info2.Quality then
			return true
		elseif info1.Quality == info2.Quality then
			if Cailiao[id1] > Cailiao[id2] then
				return true
			end
		end
		return false
	end

	self.mXXXX = {}
	for i,_ in pairs(Cailiao) do
		table.insert(self.mXXXX, i)
	end
	table.sort(self.mXXXX, sortIDByQuality)	
	--dump(self.mXXXX)
end

-- 分解点击职业框
function UIEquipMake:jobListCallBackBreak(ref)
	print("职业选择")
	if self.mIsJobBreak then
		self.mIsJobBreak = false
		CommonHelper.playCsbAnimate(self.mJobListBreak, downListBufftonFile, "On", false, nil, true)
	else
		self.mIsJobBreak  = true
		CommonHelper.playCsbAnimate(self.mJobListBreak, downListBufftonFile, "Normal", false, nil, true)
	end
end

-- 分解点击职业框的子界面,什么职业等
function UIEquipMake:jobListSonCallBackBreak(ref)
	local ButtonName = CsbTools.getChildFromPath(self.mJobListBreak, "OrderButton/ButtonName")
	local tag = ref:getTag()
	self:jobListCallBackBreak(nil)
	self.mCurJobBreak = tag
	ButtonName:setString(self.mCurJobBreak==1 and CommonHelper.getUIString(513) or CommonHelper.getUIString(jobName[self.mCurJobBreak-1]))
	self:selectEquip()

	CommonHelper.playCsbAnimate(self.mBreakButtonFather, breakButton,  self.mSelectedCount > 0 and "Able" or "Disable", false, nil, true)
	self:initTopScrollViewBreak()
	self:initDowniScrollViewBreak()
end

--------------- 按钮回调 ----------------------
-- 点击右边职业,什么职业等
function UIEquipMake:jobListSonCallBack(ref)

	local tag = ref:getTag()
	local showTag = jobType[tag]
	if showTag == self.mCurJob then
		return
	end

   	for i=1,#jobType  do
   		CommonHelper.playCsbAnimate(self.mJobList[i], AllButton, "Normal", false, nil, true)
   		self.mJobList[i]:setLocalZOrder(i)
   	end

   	self.mCurJob = showTag
	self.mEquipDataIndex = {}
   	self.mEquipDataIndex = equipMakeModel:getEquipByHead(self.mCurJob, levelName[self.mCurLevel])

   	CommonHelper.playCsbAnimate(self.mJobList[tag], AllButton, "On", false, nil, true)
   	self.mJobList[tag]:setLocalZOrder(99999)
   	-- 红点, 职业变了,等级的也要变一下
   	for i=1,#levelType do
		self.mLevelRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~= nil and UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob][levelName[i]] ~= nil)
	end
	self.mLevelRed:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~= nil)

	self:initLeftScrollView()
	self:initRightUI()
end

-- 点击等级框
function UIEquipMake:levelListCallBack(ref)
	print("等级选择")
	if self.mIsLevel then
		self.mIsLevel = false
		CommonHelper.playCsbAnimate(self.mLevelList, downListBufftonFile, "On", false, nil, true)
	else
		self.mIsLevel = true
		CommonHelper.playCsbAnimate(self.mLevelList, downListBufftonFile, "Normal", false, nil, true)
	end
end

-- 点击等级框的子界面,几级,什么等级等
function UIEquipMake:levelListSonCallBack(ref)
	local ButtonName = CsbTools.getChildFromPath(self.mLevelList, "OrderButton/ButtonName")
	local tag = ref:getTag()
	local showTag = levelType[tag]
	ButtonName:setString(CommonHelper.getUIString(26)..levelName[showTag])
	self:levelListCallBack(nil)
	self.mCurLevel = showTag
	self.mCurParts = 1
	self.mEquipDataIndex = {}
   	self.mEquipDataIndex = equipMakeModel:getEquipByHead(self.mCurJob, levelName[self.mCurLevel])
	self:initLeftScrollView()
	self:initRightUI()
end

-- 点击选择装备
function UIEquipMake:propBarTouchCallBack(ref)
	local index = ref:getTag()
	if index == self.mCurParts then --重复点击过滤
		return
	end
	--把别的变成没选择的状态
	local children = self.mPropScrollView:getChildren()
	for _,node in pairs(children) do
		local itemCsb = node:getChildByTag(7758258)
		CommonHelper.playCsbAnimate(itemCsb, csbFile.PropBar, "Normal", false, nil, true)
	end

	local itemCsb = ref:getChildByTag(7758258)
	CommonHelper.playCsbAnimate(itemCsb, csbFile.PropBar, "Choose", false, nil, true)

	self.mCurParts = index
	self.mCurIndex = self.mEquipDataIndex[index]
	self:initRightUI()
end

function UIEquipMake:checkBoxSelectedEvent(sender,eventType)
    MusicManager.playSoundEffect(sender:getName())
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])
	print("eventType", eventType)
    if 0 == eventType then  -- 选中
        isQuality = true
        print("精炼")
        CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Orange", false, nil, true)
    	local needGold = equipData.Eq_NormalCastGoldCost
		self.mPriceNum:setString(needGold)
		self.mTextOrange:setString(CommonHelper.getUIString(1245))
		self.mArrowIcon2:setVisible(true)
		self.mArrowIcon:setVisible(true)
    else                    -- 取消
        isQuality = false
        print("不精炼")
        CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Green", false, nil, true)
    	local needGold = equipData.Eq_QualityCastGoldCost
		self.mTextGreen:setString(CommonHelper.getUIString(1244))
		self.mPriceNum:setString(needGold)
		self.mArrowIcon2:setVisible(false)
		self.mArrowIcon:setVisible(false)
    end

    -- if not self.mMoneyenough then
    -- 	CommonHelper.playCsbAnimate(self.mMakeButton, MakeButton, "Grey", false, nil, true)
    -- end

    cc.UserDefault:getInstance():setBoolForKey("isQuality", isQuality)
 end  

-- 返回
function UIEquipMake:backBtnCallBack(ref)
	UIManager.close()
end

function UIEquipMake:TouchCallBack(ref)
	-- 材料途径
	local tag = ref:getTag()
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])
	local id = equipData["Eq_Synthesis"..tag]

	print("tag id is  ", tag,id)
	UIManager.open(UIManager.UI.UIPropQuickTo, id)
end

-- 右边标签上下切换
function UIEquipMake:btnCallBack(ref)
	local tag = ref:getTag()
	self.mIsLevel = true
	self.mIsJobBreak = true
	self.isSuccess = true

	CommonHelper.playCsbAnimate(self.mJobListBreak, downListBufftonFile, "Normal", false, nil, true)
	CommonHelper.playCsbAnimate(self.mLevelList, downListBufftonFile, "Normal", false, nil, true)


	if tag == buttonType.equipBreak then
		self.mMakePanel:setVisible(true)
		self.mBreakPanel:setVisible(false)
		self.mMakeBreakButton:setTag(buttonType.equipMake)
		self.mMakeBreakButtonText:setString(CommonHelper.getUIString(1240))
		self.mMakeIcon:setVisible(true)
		self.mBreakIcon:setVisible(false)
		for i=1,#jobType do
			self.mJobList[i]:setVisible(true)
		end
	elseif tag ==buttonType.equipMake then
		self.mMakePanel:setVisible(false)
		self.mBreakPanel:setVisible(true)
		self.mMakeBreakButton:setTag(buttonType.equipBreak)
		self.mMakeBreakButtonText:setString(CommonHelper.getUIString(1241))
		self.mMakeIcon:setVisible(false)
		self.mBreakIcon:setVisible(true)
		for i=1,#jobType do
			self.mJobList[i]:setVisible(false)
		end
	end
end

function UIEquipMake:viewCallBack(ref)
	local equipInfo = {}
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])

	equipInfo.name = CommonHelper.getPropString(equipData.Item_Name)
	equipInfo.level = equipData.Eq_Level..CommonHelper.getUIString(528)
	equipInfo.job = CommonHelper.getUIString(jobName[self.mCurJob])
	equipInfo.equipData = equipData
	UIManager.open(UIManager.UI.UIEquipMakeView, equipInfo, isQuality)
end

function UIEquipMake:questionCallBack(ref)

	UIManager.open(UIManager.UI.UIEquipMakeQuestion)
end

function UIEquipMake:beginEquipMake(ref)
	ref.soundId = nil

	if self.isSuccess then
		
		print("发送的数据为   行号,  是否为精炼打造",self.mEquipDataIndex[self.mCurParts], isQuality)
		local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])
		print("打造的装备名字为",CommonHelper.getPropString(equipData.Item_Name))

		if not self.mIsCanSend then
			print("要么钱不够,要么材料不够,小伙子不充钱还想打造装备?")
            ref.soundId = MusicManager.commonSound.fail
			if not self.mMoneyenough then
                UIManager.open(UIManager.UI.UIGold)
				--CsbTools.addTipsToRunningScene(CommonHelper.getUIString(572))
				return
			end
            --dump(self.mWhichCaliao)
			if table.maxn(self.mWhichCaliao) > 0 then
				CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1250))
				return
			end
			return
		end

		if isQuality then
			if self.mWhichCaliao[5] ~= nil then
				CsbTools.addTipsToRunningScene(CommonHelper.getUIString(1251))
				return
			end
		end
		-- 背包空间大小判定
		local bagCount = getGameModel():getBagModel():getItemCount()
		local maxBagCount = getGameModel():getBagModel():getCurCapacity()
		print("背包物品数, 背包 最大上限数",bagCount, maxBagCount)
		if bagCount>=maxBagCount then
			CsbTools.addTipsToRunningScene(CommonHelper.getUIString(118))
			return
		end

		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 发送打造装备协议")
		local buffData = NetHelper.createBufferData(MainProtocol.Bag, BagProtocol.makeEquipCS)
	    bufferData:writeInt(self.mEquipDataIndex[self.mCurParts])
	    bufferData:writeInt(equipData.Eq_Level)
	    bufferData:writeInt(equipData.Eq_Parts)
	    bufferData:writeInt(equipData.Eq_Vocation)
	    bufferData:writeBool(isQuality)
	   	NetHelper.request(buffData)
	end
end

function UIEquipMake:backGroudCallback(ref)
	
	if not self.isIng then
		return
	end
	self.mForgingText:setVisible(false)
	self.isIng = false
	if self.mMakeTime < self.mMaxTime then
		MusicManager.playSoundEffect(effecMusic[self.mMakeTime])
		CommonHelper.playCsbAnimate(self.mForging, csbFile.Forging, animation[self.mMakeTime], false, function()
		self.mMakeTime = self.mMakeTime + 1
		self.isIng = true
		end, true)
	else
		self:showResult()
	end
end

function UIEquipMake:beginEquipBreakFrist(ref)
	if self.mImportantEquipCount > 0 then
		UIManager.open(UIManager.UI.UIEquipMakeTip, handler(self, self.beginEquipBreak))
	else
		self:beginEquipBreak()
	end
end

function UIEquipMake:beginEquipBreak()
	print("开始分解")
	print("勾选的个数为 金币为", self.mSelectedCount, self.mBreakMoney)
	print("精品装备的个数为,", self.mImportantEquipCount)
	--dump(Cailiao)

    CommonHelper.checkConsumeCallback(1, self.mBreakMoney, function ()
	    print("发送分解协议")
	    local buffData = NetHelper.createBufferData(MainProtocol.Bag, BagProtocol.breakEquipCS)
        bufferData:writeInt(self.mSelectedCount)

	    for i=1,#self.mRealShowEuips do
		    if self.mRealShowEuips[i].isSelected then
	   		    bufferData:writeInt(self.mRealShowEuips[i].equipId)
			    bufferData:writeInt(self.mRealShowEuips[i].confId)
		    end
	    end

   	    NetHelper.request(buffData)
    end)
end

function UIEquipMake:showResult()

	local propIcon = CsbTools.getChildFromPath(self.mMakeItem, "PropIcon")
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])
	CsbTools.replaceSprite(propIcon, equipData.Item_Icon)
	MusicManager.playSoundEffect(effecMusic[self.mMakeTime])
	self.isIng = false
	self.mForging:setVisible(true)
	CommonHelper.playCsbAnimate(self.mForging, csbFile.Forging, animation[self.mMakeTime], false, function()
		self.mForging:setVisible(false)
		CommonHelper.playCsbAnimate(self.mMakeItem, MakeItem, "Made", false, 
		function()
		self.isIng = true

		self.mMaxTime = 1
		self.mMakeTime = 1
			print("self.mMakeMoney=", self.mMakeMoney)
			self:initCommonUI()
			self:initRightUI()

			print("self.mEquipId", self.mEquipId)
			UIManager.open(UIManager.UI.UIShowEquip, self.mEquipId)
			CsbTools.replaceImg(self.mPropImage, equipData.Item_Icon)
			self.mPropImage:setVisible(true)
			self.mIsMakeBack = true --onTop要用
			self.mMakeItem:setVisible(false)

			-- 分解部分要重新初始化一下
			self.mShowEquips = {}
			self.mShowEquips = equipMakeModel:getEquipModelCanBreakEquip()
			self:selectEquip()
			self:initTopScrollViewBreak()
			CommonHelper.playCsbAnimate(self.mBreakButtonFather, breakButton,  self.mSelectedCount > 0 and "Able" or "Disable", false, nil, true)
			self:initDowniScrollViewBreak()
		end, true)
	end, true)
end

function UIEquipMake:makeCallBack(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 打造结果返回")
	local a = buffData:readInt()
	self.mConfId = buffData:readInt()
	self.mEquipId = buffData:readInt()					
	--local confId = buffData:readInt()					
	self.mMainPropNum = buffData:readChar()				
	self.mEffectIds = {}
	for j = 1, 8 do
		table.insert(self.mEffectIds, buffData:readChar()) 	
	end
	self.mEffectVals = {}
	for j = 1, 8 do
		table.insert(self.mEffectVals, buffData:readShort())	
	end

	self:deleteUserData()
	getGameModel():getEquipModel():addEquip(self.mEquipId, self.mConfId, self.mMainPropNum, self.mEffectIds, self.mEffectVals)
	getGameModel():getBagModel():addItem(self.mEquipId, self.mConfId)

	self.propConf   = getPropConfItem(self.mConfId)
	--dump(self.propConf)
	self.isSuccess = false
	self.mMaxTime = self.propConf.Quality

	-- 打造通知 
	EventManager:raiseEvent(GameEvents.EventEquipMake, {quality = self.mMaxTime})

	if self.mMaxTime == 1 then
		self:showResult()
		return
	end
	self.mForging:setVisible(true)
	self.isIng = false
	MusicManager.playSoundEffect(effecMusic[self.mMakeTime])
	CommonHelper.playCsbAnimate(self.mForging, csbFile.Forging, animation[self.mMakeTime], false, function()
		self.mMakeTime = self.mMakeTime + 1
		self.mForgingText:setVisible(true)
		self.isIng = true
	end, true)

	--红点
	UIEquipMakeRedHelper:abcdefg()
	self:initLeftScrollView()
   	for i=1,#levelType do
		self.mLevelRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~= nil and UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob][levelName[i]] ~= nil)
	end
	for i=1,#jobType do
		self.mJobRedPoint[i]:setVisible(UIEquipMakeRedHelper.mCanShowJobRed[jobType[i]] ~= nil)
	end
	self.mPartsRedPoint[self.mCurParts]:setVisible(UIEquipMakeRedHelper.mCanShowPartsRed[self.mCurIndex] ~= nil)
	self.mLevelRed:setVisible(UIEquipMakeRedHelper.mCanShowLevelRed[self.mCurJob] ~= nil)
end

function UIEquipMake:deleteUserData()
	local equipData = equipMakeModel:getEquipByIndex(self.mEquipDataIndex[self.mCurParts])

	local needGold = isQuality and equipData.Eq_QualityCastGoldCost or equipData.Eq_NormalCastGoldCost
	ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -needGold) --减金币
	for i=1,4 do
		local needCount = equipData["Eq_Synthesis"..i.."Param"]
		getGameModel():getBagModel():removeItems(equipData["Eq_Synthesis"..i], needCount)
	end
	if isQuality then
		local needCount = equipData["Eq_Synthesis5Param"]
		getGameModel():getBagModel():removeItems(equipData["Eq_Synthesis5"], needCount)
	end
end

function UIEquipMake:breakCallBack(mainCmd, subCmd, buffData)
	print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 分解结果返回")
	local gold = buffData:readInt()
	local count = buffData:readInt()
	print("gold,count",gold,count)
	local result = {}
	for i=1,count do
		local tmep = {}

		tmep.id = buffData:readInt()
		tmep.num = buffData:readInt()
		table.insert(result, tmep)
	end
	--dump(result)
	if #result then
		ModelHelper.addCurrency(UIAwardHelper.ResourceID.Gold, -gold) --减金币

		for i=1,#self.mRealShowEuips do --移除装备
			if self.mRealShowEuips[i].isSelected then
				getGameModel():getEquipModel():removeEquip(self.mRealShowEuips[i].equipId)
				getGameModel():getBagModel():removeItems(self.mRealShowEuips[i].equipId, 1)
			end
		end
		
		--加材料  --后端自己会对前端模型加数据 ,好厉害
		-- for i=1,#result do
		-- 	getGameModel():getBagModel():addItem(result[i].id, result[i].num)
		-- end
		-- 展示所得
		UIManager.open(UIManager.UI.UIAward, result)--,CommonHelper.getUIString(1286))
		-- 刷新界面
		self:initCommonUI()
		self.mShowEquips = {}
		self.mShowEquips = equipMakeModel:getEquipModelCanBreakEquip()
		self:selectEquip()
		self:initTopScrollViewBreak()
		CommonHelper.playCsbAnimate(self.mBreakButtonFather, breakButton,  self.mSelectedCount > 0 and "Able" or "Disable", false, nil, true)
		self:initDowniScrollViewBreak()


		-- 还要刷新一下打造的界面
		self:initCommonUI()
		self:initRightUI()
	end
end

return UIEquipMake 