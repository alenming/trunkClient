--[[
相关道具(或英雄卡、装备等)节点显示辅助
1、纯显示图标节点,不包括模型操作
2、提供不同CSB节点显示接口
]]

UIAwardHelper = {}

-- 奖励的类型
UIAwardHelper.awardType = {
	exp = true,
	gold = true,
	diamond = true,
	pvpCoin = true,
	towerCoin = true,
	guildContrib = true,
	energy = true,
	item = true,
    dropInfo = true,
}

UIAwardHelper.ResourceID = {
    Gold            = 1,
    Diamond         = 2,
    PvpCoin         = 3,
    TowerCoin       = 4,
    Energy          = 5,
    UnionContrib    = 6,
    Exp             = 7,
    xxxxxxxxx       = 8,
    Flashcard10     = 9,
    Flashcard       = 10,
}

-- 道具表里面的道具类型
UIAwardHelper.ItemType = {
	Equip 			= 1,
	EquipMaterial	= 2,
	HeroCard 		= 3,
	SummonerCard 	= 4,
	ExpBook 		= 5,
	SkillBook		= 6,
	GoldBag 		= 7,
	EnergyBag 		= 8,
	ExpBag 			= 9,
	DiamondBag		= 10,
	Treasure 		= 11,
	Material 		= 12,
    EquipCreat      = 13,
    Resource        = 14,
    Frag			= 15,
    Head 			= 16,
}

-------------------新道具csb---------------------
-- 将数据转换成UIAward需要的格式
-- type参考UIAwardHelper.awardType, data奖励的table数据, value需要插入到奖励数据的值
function UIAwardHelper.formatAwardData(awardData, type, value)
	if not (UIAwardHelper.awardType[type] and value) then
		print("error of type or value ", type, value)
		return
	end

	if type == "item" then
		table.insert(awardData[type], {id = value.id, num = value.num})
	elseif type == "dropInfo" then
		table.insert(awardData, {id = value.id, num = value.num})
	else
		if value ~= 0 then
			table.insert(awardData[type], value)
		end
	end
end

-- 通过道具表配置 设置 PropItem.csb 节点
function UIAwardHelper.setPropItemOfConf(node, propConf, count)
    local frameImg = CsbTools.getChildFromPath(node, "Item/Level")
    if propConf == nil then
		CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/PropItem.csb", "Null", false)
        --CommonHelper.playCsbAnimation(node, "Null", false, nil)
        CsbTools.replaceImg(frameImg, IconHelper.getPropFrame(1))
        return
    end

	local countLab = CsbTools.getChildFromPath(node, "Item/Num")
	local iconImg = CsbTools.getChildFromPath(node, "Item/icon")
	local heroImg = CsbTools.getChildFromPath(node, "Item/HeroGem/Icon")
	local eqMaterialImg = CsbTools.getChildFromPath(node, "Item/SmithScroll/Icon")

	if propConf.Type == UIAwardHelper.ItemType.SkillBook then
		CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/PropItem.csb", "Gem", false)
        --CommonHelper.playCsbAnimation(node, "Gem", false, nil)
		CsbTools.replaceSprite(heroImg, propConf.Icon)
	elseif propConf.Type == UIAwardHelper.ItemType.EquipMaterial and propConf.TypeParam[1] == 1 then
		CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/PropItem.csb", "Scroll", false)
		--CommonHelper.playCsbAnimation(node, "Scroll", false, nil)
		CsbTools.replaceSprite(eqMaterialImg, propConf.Icon)
	else
		CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/PropItem.csb", "Prop", false)
        --CommonHelper.playCsbAnimation(node, "Prop", false, nil)
		CsbTools.replaceImg(iconImg, propConf.Icon)
	end
	CsbTools.replaceImg(frameImg, IconHelper.getPropFrame(propConf.Quality))
	countLab:setString(count ~= 0 and count or "")
end

-- 通过货币类型 设置 PropItem.csb 节点
function UIAwardHelper.setPropItemOfCurrency(node, type, count)
	local resourcePng = {
		[UIAwardHelper.awardType.exp] = "pub_exp.png",
		[UIAwardHelper.awardType.gold] = "pub_gold.png",
		[UIAwardHelper.awardType.diamond] = "pub_gem.png",
		[UIAwardHelper.awardType.pvpCoin] = "icon_button_fight.png",
		[UIAwardHelper.awardType.towerCoin] = "icon_button_setting.png",
		[UIAwardHelper.awardType.guildContrib] = "icon_guild_01.png",
		[UIAwardHelper.awardType.energy] = "pub_energy.png",
	}

	if resourcePng[type] == nil then
		node:setVisible(false)
		return
	end

	local frameImg = CsbTools.getChildFromPath(node, "Item/Level")
	local iconImg = CsbTools.getChildFromPath(node, "Item/icon")
	local countLab = CsbTools.getChildFromPath(node, "Item/Num")

    CommonHelper.playCsbAnimation(node, "Prop", false, nil)
	CsbTools.replaceImg(frameImg, IconHelper.getPropFrame(1))
	CsbTools.replaceImg(iconImg, resourcePng[info])
	countLab:setString(count ~= 0 and count or "")
end

-- 通过道具配表 设置HeroItem.csb 节点
function UIAwardHelper.setHeroItemOfConf(node, propConf, count)
    if propConf == nil then
        node:setVisible(false)
        return
    end

    local bgImg = CsbTools.getChildFromPath(node, "Item/Bg")
    local iconImg = CsbTools.getChildFromPath(node, "Item/Icon")
    local frameImg = CsbTools.getChildFromPath(node, "Item/Level")
    local raceImg = CsbTools.getChildFromPath(node, "Item/Race")
    local starLab = CsbTools.getChildFromPath(node, "Item/StarNum")
    local countLab = CsbTools.getChildFromPath(node, "Item/Num")

    if propConf.Type == UIAwardHelper.ItemType.HeroCard then
    	CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/HeroItem.csb", "Hero", false)
        --CommonHelper.playCsbAnimation(node, "Hero", false, nil)
        if #propConf.TypeParam >= 2 then
            local heroConf = getSoldierConfItem(propConf.TypeParam[1], propConf.TypeParam[2])
            if heroConf == nil then
                print("heroConf is nil ", propConf.TypeParam[1], propConf.TypeParam[2])
                return
            end
            CsbTools.replaceImg(raceImg, IconHelper.getRaceIcon(heroConf.Common.Race))
            starLab:setString(propConf.TypeParam[2])			
        end
    elseif propConf.Type == UIAwardHelper.ItemType.SummonerCard then
    	CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/HeroItem.csb", "Summoner", false)
        --CommonHelper.playCsbAnimation(node, "Summoner", false, nil)
    else
    	CommonHelper.playCsbAnimate(node, "ui_new/g_gamehall/b_bag/HeroItem.csb", "Piece", false)
        --CommonHelper.playCsbAnimation(node, "Piece", false, nil)
    end
    CsbTools.replaceImg(iconImg, propConf.Icon)
    CsbTools.replaceImg(frameImg, IconHelper.getSoldierHeadFrame(propConf.Quality))
    CsbTools.replaceImg(bgImg, IconHelper.getSoldierHeadBg(propConf.Quality))
    countLab:setString(count ~= 0 and count or "")
end

-- 通过 propConf 设置 AllItem.csb
function UIAwardHelper.setAllItemOfConf(node, propConf, count)
	local propNode = CsbTools.getChildFromPath(node, "MainPanel/Prop")
	local heroNode = CsbTools.getChildFromPath(node, "MainPanel/Hero")
	local callType = {
		[UIAwardHelper.ItemType.Equip] 			= 1,
		[UIAwardHelper.ItemType.EquipMaterial]	= 1,
		[UIAwardHelper.ItemType.HeroCard] 		= 2,
		[UIAwardHelper.ItemType.SummonerCard] 	= 2,
		[UIAwardHelper.ItemType.ExpBook] 		= 1,
		[UIAwardHelper.ItemType.SkillBook]		= 1,
		[UIAwardHelper.ItemType.GoldBag] 		= 1,
		[UIAwardHelper.ItemType.EnergyBag] 		= 1,
		[UIAwardHelper.ItemType.ExpBag]			= 1,
		[UIAwardHelper.ItemType.DiamondBag]		= 1,
		[UIAwardHelper.ItemType.Treasure] 		= 1,
		[UIAwardHelper.ItemType.Material] 		= 1,
	    [UIAwardHelper.ItemType.EquipCreat]     = 1,
	    [UIAwardHelper.ItemType.Resource]       = 1,
	    [UIAwardHelper.ItemType.Frag]			= 2,
	    [UIAwardHelper.ItemType.Head]			= 1,
	}
	if propConf and callType[propConf.Type] == 2 then
		propNode:setVisible(false)
		heroNode:setVisible(true)
		UIAwardHelper.setHeroItemOfConf(heroNode, propConf, count)
	else
		propNode:setVisible(true)
		heroNode:setVisible(false)
		UIAwardHelper.setPropItemOfConf(propNode, propConf, count)
	end
end