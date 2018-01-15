IconHelper = {}

local qualityFile = {"grey", "green", "blue", "voilet", "yellow", "red", "colorfull"}
local jobFile = {"warrior", "assassin", "archer", "mage", "assistant"}

-- 道具边框
function IconHelper.getPropFrame(quality)
	local item = getItemLevelSettingItem(quality)
	if item then
		return item.ItemFrame		
	end
	return nil
end

-- 英雄身体的边框
function IconHelper.getSoldierBodyFrame(rare)
	local item = getSoldierRareSettingConfItem(rare)
	if item then
		return item.UiRes
	end
	return nil
end

-- 英雄头像的边框
function IconHelper.getSoldierHeadFrame(rare)
	local item = getSoldierRareSettingConfItem(rare)
	if item then
		return item.HeadboxRes
	end
	return nil
end

-- 英雄大头像的边框
function IconHelper.getSoldierBigHeadFrame(rare)
	local item = getSoldierRareSettingConfItem(rare)
	if item then
		return item.BigHeadboxRes
	end
	return nil
end

-- 英雄头像背景
function IconHelper.getSoldierHeadBg(rare)
    local item = getSoldierRareSettingConfItem(rare)
    if item then
        return item.HeadboxBgRes
    end
    return nil
end

-- 英雄职业框
function IconHelper.getSoldierJobIcon(rare, vocation)
	local item = getSoldierRareSettingConfItem(rare)
	if item then
		return item.JobsIcon[vocation]
	end
	return nil
end

-- 英雄职业框
function IconHelper.getSoldierJobIconCircle(rare)
	local item = getSoldierRareSettingConfItem(rare)
	if item then
		return item.JobBg
	end
	return nil
end

-- 装备部位默认图标
function IconHelper.getEquipIcon(partID)
	local item = getIconSettingConfItem()
	if item then
		return item.EqIcon[partID]
	end
	return nil
end

-- 种族图标
function IconHelper.getRaceIcon(raceID)
	local item = getIconSettingConfItem()
	if item then
		return item.RaceIcon[raceID]
	end
	return nil
end

-- 职业图标
function IconHelper.getJobIcon(jobID)
	local item = getIconSettingConfItem()
	if item then
		return item.JobIcon[jobID]
	end
	return nil
end

-- 系统头像
function IconHelper.getSystemIconID(id)
	local item = getSystemHeadIconItem()
	if item then
		return item[id]
	end
	return nil
end

--卡包上的卡片武器图片
function IconHelper.getSoldierWeapon(rare, job)
	if not qualityFile[rare] or not jobFile[job] then 
		return "" 
	end
	return "card_profesion_" .. jobFile[job] .. "_" .. qualityFile[rare] .. ".png"
end

-- 卡包卡片的边框
function IconHelper.getCardLevelBorder(quality)
	if not qualityFile[quality] then
		return ""
	end

	return "card_lv_bar_" .. qualityFile[quality] .. ".png"
end

-- 卡包卡片的种族
function IconHelper.getCardBackRace(rare, race)
    if race > 3 or race < 1 then
        return ""
    end

    local raceStr = {"human", "dead", "nature", "other"}
    local retImg = ""
    if rare >= 3 then
        retImg = "card_golden_race_"
    else
        retImg = "card_silver_race_"
    end

    return retImg .. raceStr[race]..".png"
end

