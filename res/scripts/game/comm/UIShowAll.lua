--[[
显示任意(多件)物品界面
1、物品分三大类:召唤师、英雄、其他
2、实现功能:关闭一个显示界面后显示下一个物品,直到显示完
]]

local UIShowAll = class("UIShowAll", function()
    return require("common.UIView").new()
end)

local UILanguage = {confirm = 500}

function UIShowAll:ctor()
end

function UIShowAll:init()
    local gameModel = getGameModel()
    self.summonerModel = gameModel:getSummonersModel()
    self.heroCardBagModel = gameModel:getHeroCardBagModel()
end

function UIShowAll:onOpen(fromUIID, items)
--    self.summoners = {1100, 1000, 1500}
--    self.heroCards = {{cardId = 11000, star = 3,  heroLv = 1}, {cardId = 40800, star = 3,  heroLv = 1}}
--    self.others = {110001, 120003}
    self.summoners = items.summoners or {}
    self.heroCards = items.heroCards or {}
    self.others = items.others or {}

    self.curSummonerIndex = 1
    self.curHeroIndex = 1
    self.curOtherIndex = 1

    self:showAll()
end

function UIShowAll:onTop()
    self:showAll()
end

function UIShowAll:onClose()
end

function UIShowAll:showAll()
    if self.curSummonerIndex <= #self.summoners then
        self:showSummonerUI()
        return
    end

    if self.curHeroIndex <= #self.heroCards then
        self:showHeroCardUI()
        return
    end

    if self.curOtherIndex <= 1 and #self.others > 0 then
        self:showOtherUI()
        return
    end

    UIManager.close()
end

function UIShowAll:showSummonerUI()
    local summonerID = self.summoners[self.curSummonerIndex]
    --if self.summonerModel:hasSummoner(summonerID) then
--        local summonerConf = getHeroConfItem(summonerID)
--        if not summonerConf then
--            print("can't find summoner in conf", summonerID)
--            return
--        end

--        local params = {}
--        params.msg = string.format(CommonHelper.getUIString(178), CommonHelper.getHSString(summonerConf.Common.Name))
--        params.confirmFun = function () UIManager.close() end
--        params.cancelFun = function () print("nothing to do...") end
--        UIManager.open(UIManager.UI.UIDialogBox, params)
--    else
        UIManager.open(UIManager.UI.UIShowSummoner, summonerID)
--    end
    
    self.curSummonerIndex = self.curSummonerIndex + 1
end

function UIShowAll:showHeroCardUI()
    --if ModelHelper.isHeroMaxStar(self.heroCards[self.curHeroIndex].cardId
--        , self.heroCards[self.curHeroIndex].star) then
            UIManager.open(UIManager.UI.UIShowCard, 2, self.heroCards[self.curHeroIndex])
            self.curHeroIndex = self.curHeroIndex + 1
--    else
--        self.curHeroIndex = self.curHeroIndex + 1
--        self:showAll()
--    end
end

function UIShowAll:showOtherUI()
    local awardData = {}
    local dropInfo = {}
	for i=1, #self.others do
	    dropInfo.id = self.others[i].id
	    dropInfo.num = self.others[i].num
	    UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
	end

	-- 显示奖励
	UIManager.open(UIManager.UI.UIAward, awardData)
    self.curOtherIndex = self.curOtherIndex + 1
end

return UIShowAll
