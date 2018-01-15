--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  商店物品购买界面
** 应  用:
********************************************************************/
--]]
require("common.WidgetExtend")

local userModel = getGameModel():getUserModel()
local equipModel = getGameModel():getEquipModel()

local function setEqAttriLab(lab, attriID, attriValue)
	local value = attriValue >= 0 and "+" .. attriValue or "-" .. attriValue
	local str = CommonHelper.getRoleAttributeString(attriID) or "nil %d"
	lab:setString(string.format(str, value))
end

local UIShowEquip = class("UIShowEquip", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIShowEquip:ctor()
    self.rootPath = ResConfig.UIShowEquip.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)
    
    self.btnConfrim = getChild(self.root, "MainPanel/ConfirmButtom")
    CsbTools.initButton(self.btnConfrim, handler(self, self.onClick), nil, nil, "Text")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIShowEquip:init(...)

end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIShowEquip:onOpen(openerUIID, eqDynID)
    self.eqDynID = eqDynID

	self.equipInfo      = equipModel:getEquipInfo(eqDynID)
    self.baseAttriCout  = self.equipInfo.nMainPropNum

	local cfgId     = equipModel:getEquipConfId(eqDynID)
	self.equipCfg   = getEquipmentConfItem(cfgId)
	self.propConf   = getPropConfItem(cfgId)

    -- 初始化上部分显示
    self:initHeadInfo()
	-- 初始化可变区域显示
	self:initDyBodyInfo()
end

-- 初始化上部分显示
function UIShowEquip:initHeadInfo()
    -- 装备名称
    local eqNameLab	= getChild(self.root, "MainPanel/Name")
    local eqNameStr	= CommonHelper.getPropString(self.propConf.Name)
    eqNameLab:setString(eqNameStr)

    -- 装备图标
    local propItem 	= getChild(self.root, "MainPanel/PropItem")
    UIAwardHelper.setPropItemOfConf(propItem, self.propConf, 0)
end

function UIShowEquip:initDyBodyInfo()
    -- 重置显示区域大小
    self.infoList		= getChild(self.root, "MainPanel/EqInfoListView")
    self.infoList:setContentSize(cc.size(self.infoList:getContentSize().width, 225))
    self.infoList:jumpToTop()
    self.infoList:setScrollBarEnabled(false)

    self:initBaseInfo()
    self:initAddInfo()
    self:initSuitInfo()
    self:initSuitAbilityInfo()
    self:initDescInfo()

    self.infoList:requestDoLayout()
end

function UIShowEquip:initBaseInfo()
    local scroll	= getChild(self.infoList, "BasicAttri")
    local innerSize = scroll:getContentSize()
    local lab 	= {}
    for i=0, 8 do
        lab[i]	= getChild(scroll, "AddAttri_" .. i)
    end
    lab[0]:setString(CommonHelper.getUIString(197))
    innerSize.height = 0

    local count = 0
    for i=1, 8 do
        if i <= self.baseAttriCout then
            local effectID 		= self.equipInfo.eqEffectIDs[i]
            local effectValue 	= self.equipInfo.eqEffectValues[i]
            if 0 ~= effectID and 0 ~= effectValue then
                count = count + 1
                setEqAttriLab(lab[count], effectID, effectValue)
                innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
            end
        end
    end
    scroll:setContentSize(innerSize)
end

function UIShowEquip:initAddInfo()
    local scroll	= getChild(self.infoList, "AddAttri")
    local innerSize = scroll:getContentSize()
    local lab 	= {}
    for i=0, 8 do
        lab[i]	= getChild(scroll, "AddAttri_" .. i)
    end
    lab[0]:setString(CommonHelper.getUIString(198))
    innerSize.height = 0

    local count = 0
    for i=1, 8 do
        if i > self.baseAttriCout then
            local effectID 		= self.equipInfo.eqEffectIDs[i]
            local effectValue 	= self.equipInfo.eqEffectValues[i]
            if 0 ~= effectID and 0 ~= effectValue then
                count = count + 1
                setEqAttriLab(lab[count], effectID, effectValue)		
                innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
            end
        end
    end
    scroll:setContentSize(innerSize)
end

function UIShowEquip:initSuitInfo()
    local scroll	= getChild(self.infoList, "SuitEq")
    local innerSize = scroll:getContentSize()

    if 0 ~= self.equipCfg.Suit then
        -- 套装信息
        local suitCfg = getSuitConfItem(self.equipCfg.Suit)
        if nil == suitCfg then
            print("Error: UIShowEquip:initSuitInfo, suitCfg==nil, Suit", self.equipCfg.Suit)
            return
        end

        local lab 	= {}
        for i=0, 6 do
            lab[i]	= getChild(scroll, "AddAttri_" .. i)
        end
        lab[0]:setString(CommonHelper.getPropString(suitCfg.Name))

        local count = 0
        for i=1, 6 do
            if suitCfg.Eq[i] ~= nil and suitCfg.Eq[i] ~= 0 then
                count = count + 1

                local propConf = getPropConfItem(suitCfg.Eq[i])
                if nil == propConf then
                    print("Error: UIShowEquip:initSuitInfo, propConf==nil, Suit, equip", self.equipCfg.Suit, suitCfg.Eq[i])
                    return
                end
                -- 设置该装备显示
                lab[count]:setString(CommonHelper.getPropString(propConf.Name))
                lab[count]:setTextColor(cc.c3b(127, 127, 127))
                innerSize.height = lab[0]:getPositionY() - lab[count]:getPositionY() + 11
            end
        end
    else
        innerSize.height = 0
    end
    scroll:setContentSize(innerSize)
end

function UIShowEquip:initSuitAbilityInfo()
    local scroll	= getChild(self.infoList, "EqsEffect")
    local innerSize = scroll:getContentSize()

    local heroEqs = {}
    if self.heroModel ~= nil then
        heroEqs = self.heroModel:getEquips()
    end
    if 0 ~= self.equipCfg.Suit then
        -- 套装信息
        local suitCfg = getSuitConfItem(self.equipCfg.Suit)
        if suitCfg == nil then
            print("Error: UIShowEquip:initSuitAbilityInfo, suitCfg==nil, Suit", self.equipCfg.Suit)
        end

        local descLab 	= {}
        local attriLab 	= {}
        local lanID = {199, 200, 201, 202, 203}
        for i=2, 6 do
            attriLab[i]	= getChild(scroll, "IntroText_" .. i)
            descLab[i]	= getChild(scroll, "EqsEffect_" .. i)
            descLab[i]:setString(CommonHelper.getUIString(lanID[i - 1]))
        end

        -- 计算套装数
        local allSuitNum 	= 0
        for i=1, 6 do
            if nil ~= suitCfg.Eq[i] and 0 ~= suitCfg.Eq[i] then
                allSuitNum = allSuitNum + 1
            end
        end
        for i=2, allSuitNum do
            local ability = suitCfg.Ability[i]
            if ability and 0 ~= ability and 0 ~= ability.EquipEffect.AbilityDesc then
                local abilityStr = CommonHelper.getPropString(ability.EquipEffect.AbilityDesc)
                attriLab[i]:setString(abilityStr)
            else
                attriLab[i]:setString("bad suit")
            end
            attriLab[i]:setTextColor(cc.c3b(127, 127, 127))
            descLab[i]:setTextColor(cc.c3b(127, 127, 127))
        end
        innerSize.height = descLab[2]:getPositionY() - attriLab[allSuitNum]:getPositionY() + 11
    else
        innerSize.height = 0
    end
    scroll:setContentSize(innerSize)
end

function UIShowEquip:initDescInfo()
    local scroll	= getChild(self.infoList, "Intro")
    local innerSize = scroll:getContentSize()
    local lab 		= getChild(scroll, "IntroText")
    lab:setString(CommonHelper.getPropString(self.propConf.Desc))
    innerSize.height = lab:getContentSize().height
    scroll:setContentSize(innerSize)
end


-- 每次界面Open动画播放完毕时回调
function UIShowEquip:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIShowEquip:onClose()

end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIShowEquip:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIShowEquip:onClick(obj)
    local btnName = obj:getName()
    if "ConfirmButtom" == btnName then
        -- CommonHelper.playCsbAnimate(getChild(self.btnConfrim, "ConfirmButtom"), ResConfig.UIBag.Csb2.btn, "OnAnimation", false, function()
        --     UIManager.close()
        -- end)
        UIManager.close()
    end
end

return UIShowEquip