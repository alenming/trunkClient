--[[
副本入口界面
]]

local UIInstanceEntry = class("UIInstanceEntry", function()
    return require("common.UIView").new()
end)


local Instances = {GoldTrialButton = {language = 1037, subSystem = 1}
    , HeroTrialButton = {language = 1038, subSystem = 2}
    , ClimbTownButton = {language = 1040, subSystem = 3}
    , InstanceButton = {language = 1039, subSystem = 4}}

--构造函数
function UIInstanceEntry:ctor()
    self.rootPath = ResConfig.UIInstanceEntry.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    self.back = getChild(self.root, "BackButton")
    CsbTools.initButton(self.back, function(obj)
        obj:setTouchEnabled(false)
        UIManager.close() 
    end)

    -- 1、金币2、英雄3、爬塔4、活动副本
    self.redPointTips = {}
    for btnName, info in pairs(Instances) do
        CsbTools.initButton(getChild(self.root, "MianPanel/"..btnName), handler(self, self.onClick)
            , CommonHelper.getUIString(Instances[btnName].language), btnName.."/NameText", btnName)

        local redPoint = getChild(self.root, "MianPanel/"..btnName.."/"..btnName.."/ButtonPanel/RedTipPoint")
        redPoint:setVisible(false)
        self.redPointTips[info.subSystem] = redPoint

        if 4 == info.subSystem then
            CommonHelper.applyGray(getChild(self.root, "MianPanel/"..btnName))
        end
        ----[[
        if 3 == info.subSystem then
            if not getGameModel():getTowerTestModel():getIsOpen() then
                CommonHelper.applyGray(getChild(self.root, "MianPanel/"..btnName))
            end
        end
        --]]
    end

    getChild(self.root, "MianPanel/TittleImage/TittleText"):setString(CommonHelper.getUIString(1041))
end

--初始化函数
function UIInstanceEntry:init()

end

function UIInstanceEntry:onOpen(fromUIID, ...)
    self.back:setTouchEnabled(true)
    local info = RedPointHelper.getSystemInfo(RedPointHelper.System.FB)
    for k, v in pairs(info) do
        if self.redPointTips[k] then
            self.redPointTips[k]:setVisible(v > 0)
        end
    end
    EventManager:raiseEvent(GameEvents.EventUIRefresh, UIManager.UI.UIInstanceEntry)
end

function UIInstanceEntry:onClick(obj)
    local btnName = obj:getName()
    obj.soundId = nil
    if "GoldTrialButton" == btnName then
        UIManager.open(UIManager.UI.UIGoldTest)
    elseif "HeroTrialButton" == btnName then
        UIManager.open(UIManager.UI.UIHeroTestChoose)
    elseif "ClimbTownButton" == btnName then
        if not getGameModel():getTowerTestModel():getIsOpen() then
            CsbTools.createDefaultTip(CommonHelper.getUIString(2202)):addTo(self)
        else
            SceneManager.loadScene(SceneManager.Scene.SceneTowerTrial)
        end
    else
        obj.soundId = MusicManager.commonSound.fail
        CsbTools.createDefaultTip(CommonHelper.getUIString(11)):addTo(self)
        --UIManager.open(UIManager.UI.UICopyChoose)
    end
end

return UIInstanceEntry

