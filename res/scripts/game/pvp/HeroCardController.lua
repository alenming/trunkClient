local HeroCardController = class("HeroCardController")

function HeroCardController:ctor()

end

function HeroCardController:setTarget(target)
	self.target = target

	self.heroPanel = getChild(self.target, "HeroCard")
	self.heroPanel:setTouchEnabled(true)
	self.heroPanel:addClickEventListener(function () 
		if self.clickCallback then
			self.clickCallback(self.heroId)
		end
	end)

	self.heroImg = getChild(self.heroPanel, "HeroImage")
	self.frameImg = getChild(self.heroPanel, "LvImage")
	self.raceImg = getChild(self.heroPanel, "RaceImage")
	self.gems = getChild(self.heroPanel, "GemSum")
	self.professionFrameImg = getChild(self.heroPanel, "ProfesionBar")
	self.professionImg = getChild(self.heroPanel, "Profesion")
	
	return self
end

function HeroCardController:updateHero(id)
	self.heroId = id

	local soldierItem = getSoldierConfItem(id, 1)
	--dump(soldierItem)

	self.heroImg:loadTexture(soldierItem.Common.Picture, 1)

	self.gems:setString(soldierItem.Cost)

	local soldierRareItem = getSoldierRareSettingConfItem(soldierItem.Rare)
	self.frameImg:loadTexture(soldierRareItem.BigHeadboxRes, 1)
	self.professionFrameImg:setSpriteFrame(soldierRareItem.JobBg)
	self.professionImg:setSpriteFrame(soldierRareItem.JobsIcon[soldierItem.Common.Vocation])

	local iconSettingItem = getIconSettingConfItem()
	self.raceImg:loadTexture(iconSettingItem.RaceIcon[soldierItem.Common.Race], 1)
end

function HeroCardController:setHeroPanelColor(color)
	self.heroPanel:setColor(color)
end

function HeroCardController:setClickCallback(callback)
	self.clickCallback = callback
end

return HeroCardController