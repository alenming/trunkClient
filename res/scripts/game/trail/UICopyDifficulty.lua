--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local UICopyDifficulty = class("UICopyDifficulty", function()
    return require("common.UIView").new()
end)

--构造函数
function UICopyDifficulty:ctor()
    self.rootPath = ResConfig.UICopyDifficult.Csb2.main
    self.root = cc.CSLoader:createNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    back:addClickEventListener(function()
        UIManager.close()
    end)
    
    --local add = getChild(self.root, "MainPanel/AddButton")
    --add:addClickEventListener(function()
    --    self:buy()
    --end)
    
    local sweep = getChild(self.root, "MainPanel/OneSweepButton")
    getChild(sweep, "Button_Confrim/ButtomName"):setString(getUILanConfItem(230))
    sweep:addClickEventListener(function()
        print("扫荡")
    end)

    local guide = getChild(self.root, "MainPanel/StrategyButton")
    guide:addClickEventListener(function()
        UIManager.open(UIManager.UI.UICopyStrategy, self.id)
    end)
    
    local start = getChild(self.root, "MainPanel/AttackButton")
    start:setTouchEnabled(true)
    start:addClickEventListener(function()
        print("ActivityInstance", self.id, self.lv)
        local count = getGameModel():getActivityInstanceModel():getActivityInstance()[self.id].useTimes
        if count <= 0 then
            self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(353),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
            return
        end
        UIManager.open(UIManager.UI.UITeam, function(summonerId, heroIds, mercenaryId)
            BattleHelper.requestInstance(summonerId, heroIds, self.id, self.lv, mercenaryId)
        end)
    end)
end

--初始化函数
function UICopyDifficulty:init(id)
    print("活动副本难度选择：", id)
    self.id = id
    self:info()
    self:ui()
end

--资源信息
function UICopyDifficulty:info()
    local user = getGameModel():getUserModel()
    getChild(self.root, "GoldInfo/GoldPanel/GoldCountLabel"):setString(tostring(user:getGold()))
    getChild(self.root, "GemInfo/GemPanel/GemCountLabel"):setString(tostring(user:getDiamond()))
    getChild(self.root, "EnergInfo/EnergyPanel/EnergyCountLabel"):setString(user:getEnergy())
end

function UICopyDifficulty:ui()
    local conf = getActivityInstanceItem(self.id)
    local ins = getGameModel():getActivityInstanceModel():getActivityInstance()
    local data = ins[self.id]

    getChild(self.root, "MainPanel/TopTitleLabel"):setString(getStageLanConfItem(conf.Title))
    getChild(self.root, "MainPanel/IntroInfo"):setString(getStageLanConfItem(conf.Desc))
    getChild(self.root, "MainPanel/AttackNum"):setString(tostring(data.useTimes) .. "/" .. conf.CompleteTimes)

    local lv = {"Simple", "Common", "Diffcult", "Infernal", "Legend"}
    local sr = {"Star0", "Star1", "Star2", "Star3"}
    local view = getChild(self.root, "MainPanel/DiffcultScrollView")
    for i=1,5 do
        local btn = getChild(view, "DiffcultButton".. i)
        local bar = getChild(btn, "DiffcultItem")  
        local panel = getChild(bar, "DiffcultPanel")
        panel:setSwallowTouches(false) 
        local map = getChild(panel, "DiffcultMap")  
        CommonHelper.playCsbAnimate(bar, ResConfig.UICopyDifficult.Csb2.map, lv[i], false)
        local star = getChild(panel, "DiffcultStarLevel")  
        local s = 0
        if i == 1 then
            s = data.easy
        elseif i == 2 then
            s = data.normal
        elseif i == 3 then
            s = data.difficult
        elseif i == 4 then
            s = data.hell
        elseif i == 5 then
            s = data.legend
        end
        CommonHelper.playCsbAnimate(star, ResConfig.UICopyDifficult.Csb2.star, sr[s + 1], false)
        btn:addClickEventListener(function()
            self:level(i)
        end)
    end

    self:level(1)
end

function UICopyDifficulty:level(lv)
    self.lv = lv
    local view = getChild(self.root, "MainPanel/DiffcultScrollView")
    for i=1,5 do
        local btn = getChild(view, "DiffcultButton".. i)
        local bar = getChild(btn, "DiffcultItem")  
        CommonHelper.playCsbAnimate(bar, ResConfig.UICopyDifficult.Csb2.item, i == lv and "On" or "Normal", false)
    end

    local conf = getActivityInstanceItem(self.id)
    local stageid = conf.Diffcult[lv].DiffID
    local sc = getStageConfItem(stageid)
    for i = 1, 2 do
        local award = getChild(self.root, "MainPanel/AwardItem_" .. i)
        local t1 = getChild(award, "MainPanel/Equip")
        local t2 = getChild(award, "MainPanel/ExpCard")
        local t3 = getChild(award, "MainPanel/SkillBook")
        local t4 = getChild(award, "MainPanel/Gold")
        local t5 = getChild(award, "MainPanel/Hero")
        local t6 = getChild(award, "MainPanel/Summoner")
        t1:setVisible(false)
        t2:setVisible(false)
        t3:setVisible(false)
        t4:setVisible(false)
        t5:setVisible(false)
        t6:setVisible(false)
        local cfg_item = getPropConfItem(sc.ItemDrop[i])
        if cfg_item then
            if cfg_item.Type == 1 then
                t1:setVisible(true)
                getChild(t1, "EquipImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t1, "LevelImage"):loadTexture("", 1)
                getChild(t1, "EqSumLabel"):setString("")
            elseif cfg_item.Type == 2 then
                t2:setVisible(true)
                getChild(t2, "IconImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t2, "LevelImage"):loadTexture("", 1)
                getChild(t2, "NumLabel"):setString("")
            elseif cfg_item.Type == 3 then
                t3:setVisible(true)
                getChild(t3, "IconImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t3, "LevelImage"):loadTexture("", 1)
                getChild(t3, "NumLabel"):setString("")
            elseif cfg_item.Type == 4 then
                t4:setVisible(true)
                getChild(t4, "IconImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t4, "LevelImage"):loadTexture("", 1)
                getChild(t4, "NumLabel"):setString("")
            elseif cfg_item.Type == 5 then
                t5:setVisible(true)
                getChild(t5, "HeroImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t5, "LevelImage"):loadTexture("", 1)
                getChild(t5, "RaceImage"):loadTexture("", 1)
                getChild(t5, "StarImage"):loadTexture("", 1)
                getChild(t5, "StarLabel"):setString("")
            elseif cfg_item.Type == 6 then
                t6:setVisible(true)
                getChild(t6, "SumImage"):loadTexture(cfg_item.Icon, 1)
                getChild(t6, "LevelImage"):loadTexture("", 1)
            end
        end
    end
end

function UICopyDifficulty:buy()
    local conf = getActivityInstanceItem(self.id)
    local ins = getGameModel():getActivityInstanceModel():getActivityInstance()
    local data = ins[self.id]
    local price = 50 --getGameSettingConfItem(1).BuyTimesPrice
    local max = conf.BuyTimes - data.buyTimes
    local cur = max

    if cur <= 0 then
        self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(372),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
        return
    end
    
    local ex = cc.CSLoader:createNode(ResConfig.UICopyDifficult.Csb2.buy)
    self:addChild(ex)
    local panel = getChild(ex, "BuyTimesPanel")

    local cancel = getChild(panel, "CancelButton")
    cancel:addClickEventListener(function()
        ex:removeFromParent(true)
    end)
    
    getChild(panel, "BuyTimesTip"):setString(string.format(getUILanConfItem(576), data.buyTimes, conf.BuyTimes))
    local total = getChild(panel, "GemSum")
    local num = getChild(panel, "NumLabel")
    num:setString(tostring(cur))
    total:setString(tostring(cur * price))

    local delbtn = getChild(panel, "DelButton")
    delbtn:addClickEventListener(function()
        if cur > 1 then
            cur = cur - 1
            num:setString(tostring(cur))
            total:setString(tostring(cur * price))
        else
            self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(371),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
        end
    end)

    local addbtn = getChild(panel, "AddButton")
    addbtn:addClickEventListener(function()
        if cur < max then
            cur = cur + 1
            num:setString(tostring(cur))
            total:setString(tostring(cur * price))
        else
            self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(370),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
        end
    end)

    local maxbtn = getChild(panel, "MaxButton")
    maxbtn:addClickEventListener(function()
        if cur ~= max then
            cur = max
            num:setString(tostring(cur))
            total:setString(tostring(cur * price))
        else
            self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(370),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
        end
    end)

    local commit = getChild(panel, "ConfrimButton")
    commit:addClickEventListener(function()
        local bufferData = NetHelper.createBufferData(MainProtocol.Instance, InstanceProtocol.BuyTimesCS)
	    bufferData:writeInt(self.id)
        bufferData:writeInt(cur)
        local respCmd = NetHelper.makeCommand(MainProtocol.Instance, InstanceProtocol.BuyTimesSC)
	    NetHelper.setResponeHandler(respCmd, function(mainCmd, subCmd, bufferData)
            print(mainCmd, subCmd)
            local id = bufferData:readInt()
            local buy = bufferData:readInt()
            local use = bufferData:readInt()
            local gem = bufferData:readInt()
            getGameModel():getActivityInstanceModel():getActivityInstance()[self.id].buyTimes = buy
            getGameModel():getActivityInstanceModel():getActivityInstance()[self.id].useTimes = use
            ex:removeFromParent(true)
        end)
        print(MainProtocol.Instance, InstanceProtocol.BuyTimesCS)
	    NetHelper.request(bufferData)
	    NetHelper.deleteBufferData(bufferData)
    end)
end

function UICopyDifficulty:update(time)
   --更新当前时间
   local tb = TimeHelper.toTimeS(time)
   getChild(self.root, "Time"):setString(tb.hour .. ":" .. tb.min .. ":" .. tb.sec)
end

return UICopyDifficulty
--endregion
