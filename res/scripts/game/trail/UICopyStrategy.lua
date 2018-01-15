--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local UICopyStrategy = class("UICopyStrategy", function()
    return require("common.UIView").new()
end)

function UICopyStrategy:ctor()
    self.rootPath = ResConfig.UICopyStrategy.Csb2.main
    self.root = cc.CSLoader:createNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    back:addClickEventListener(function()
        UIManager.close()
    end)

    local panel = getChild(self.root, "MainPanel")
    local close = getChild(panel, "CloseButton")
    close:addClickEventListener(function()
        UIManager.close()
    end)

    local view = getChild(self.root, "MainPanel/TeamSetScrollView")

    local function createTeam(i)
        local team = getChild(view, "TeamItem_" .. i)
        local sum = getChild(team, "TeamItem/SummonerIcon")
        local panel = getChild(sum, "SummonerImage")
        panel:setTouchEnabled(true)
        panel:setSwallowTouches(false) 
        panel:addClickEventListener(function()
            self:sum(i)
        end)
        for j = 1, 7 do
            local hero = getChild(team, "TeamItem/HeroIcon_" .. j)
            local panel = getChild(hero, "HeroImage")
            panel:setTouchEnabled(true)
            panel:setSwallowTouches(false) 
            panel:addClickEventListener(function()
                self:hero(i, j)
            end)
        end
    end

    for i = 0, 3 do
        createTeam(i)
    end
end

function UICopyStrategy:init(id)
    self.id = id
    self:fill()
    self:refresh()
end

function UICopyStrategy:fill()
    self.data = {}
    --设置监听回调函数
    local cmd = NetHelper.makeCommand(MainProtocol.Stage, StageProtocol.StrategySC)
    local function onTeam(main, sub, buf)
        local stageid = buf.readInt()
        local teamcount = buf.readInt()
        print("stageid:", stageid)
        print("teamcount:", teamcount)
        for i = 1, teamcount do
            local t = buf.readInt()
            local s = buf:readInt()
            local sumid = buf:readInt()
            local userlv = buf:readInt()
            local herocount = buf:readInt()
            local name = buf:readStr()
            local heros = {}
            print("sumid:",sumid)
            print("herocount:",herocount)
            for j = 1, herocount do
                local heroid = buf:readInt()
                local herostar = buf:readInt()
                local herolevel = buf:readInt()
                local herotalent = buf:readInt()
                local eqcount = buf:readInt()
                local eqs = {} 
                print("heroid:",heroid)
                print("eqcount:",eqcount)
                for k = 1, eqcount do
                    local eqid = buf:readInt()
                    print("eqid:", eqid)
                    table.insert(eqs, eqid)
                end
                table.insert(heros, {hero_id = heroid, hero_star = herostar, hero_level = herolevel, hero_talent = herotalent, equip = eqs})
            end
            table.insert(self.data, {tp = t, stamp = s, sum_id = sumid, user_level = userlv, user_name = name, hero = heros})
        end
        NetHelper.removeResponeHandler(cmd, onTeam)
    end
    NetHelper.setResponeHandler(cmd, onTeam)

    local buf_data = NetHelper.createBufferData(MainProtocol.Stage, StageProtocol.StrategyCS)
    buf_data:writeInt(self.id)          
    NetHelper.request(buf_data)
end

function UICopyStrategy:refresh()
    local view = getChild(self.root, "MainPanel/TeamSetScrollView")
    local size = view:getContentSize()
    local h = size.height-- + 135 * (-2 + #self.data)
    view:setInnerContainerSize(cc.size(size.width, h))  

    getChild(view, "TimeTips"):setString("3")   --这里要根据时间戳算出来
    view:scrollToTop(0.05, false)

    for i = 0, 3 do
        if i < #self.data then
            self:refreshTeam(i)
        else
            getChild(view, "TeamItem_" .. i):setVisible(false)
        end
    end
end

function UICopyStrategy:refreshTeam(i)
    local view = getChild(self.root, "MainPanel/TeamSetScrollView")
    local team = getChild(view, "TeamItem_" .. i)
    getChild(team, "TeamItem/NameLabel"):setString("Team")

    local sum_conf = getHeroConfItem(self.data[i+1].sum_id)
    local sum = getChild(team, "TeamItem/SummonerIcon")
    local act = cc.CSLoader:createTimeline(ResConfig.UICopyStrategy.Csb2.sum)  
    sum:runAction(act) 
    act:play("Normal", false) 
    getChild(sum, "SummonerImage"):loadTexture(sum_conf.Common.HeadIcon, 1)
    
    for j = 1,7 do
        local heros = data[i+1].hero
        local hero = getChild(team, "TeamItem/HeroIcon_" .. j)
        if j <= #hero then
            local hero_conf = getSoldierConfItem(heros[j], 2)
            local act = cc.CSLoader:createTimeline(ResConfig.UICopyStrategy.Csb2.hero)  
            hero:runAction(act) 
            act:play("Normal", false) 
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(hero_conf.Common.HeadIcon)
            getChild(hero, "HeroImage"):loadTexture(frame and hero_conf.Common.HeadIcon or "", 1)
            getChild(hero, "BGImage"):loadTexture(getLevel(1), 1)
            getChild(hero, "StarLabel"):setString(tostring(3))
            getChild(hero, "LvLabel"):setString(tostring(1))
            getChild(hero, "GemLabel"):setString(tostring(200))
        else    
            hero:setVisible(false)
        end
    end
end

function UICopyStrategy:sum(i)
    print("sum", i)

    local res = ResConfig.UICopyStrategy.Csb2.sumtip
    local csb = cc.CSLoader:createNode(res)
    csb:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
    self:addChild(csb)
    
    local panel = getChild(csb, "TipInfoPanel")
    panel:addClickEventListener(function()
        csb:removeFromParent(true)
    end)

    local conf = getHeroConfItem(data[i+1].sum_id)

    local icon =  getChild(panel, "SummonerIcon")
    local act = cc.CSLoader:createTimeline(ResConfig.UICopyStrategy.Csb2.sum)  
    icon:runAction(act) 
    act:play("Normal", false) 
    getChild(panel, "SummonerIcon/SummonerImage"):loadTexture(conf.Common.HeadIcon, 1)
    getChild(panel, "HeroName"):setString(getHSLanConfItem(conf.Common.Name))
    getChild(panel, "TipInfoText"):setString(getHSLanConfItem(conf.Common.Desc))

    for k = 1, 3 do
        local skill = getChild(panel, "SkillLvImage_" .. k)
        local cfg = getSkillConfItem(conf.PlayerSkill[k])
        skill:loadTexture(cfg.IconName, 1)
        --getChild(skill, "SkillImage"):loadTexture(getLevel(cfg.SkillLv), 1)   
    end
end

function UICopyStrategy:hero(i, j)
    print("hero", i, j)

    local res = ResConfig.UICopyStrategy.Csb2.herotip
    local csb = cc.CSLoader:createNode(res)
    csb:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
    self:addChild(csb)
    
    local panel = getChild(csb, "TipInfoPanel")
    panel:addClickEventListener(function()
        csb:removeFromParent(true)
    end)

    local id = self.data[i+1].hero[j]
    local conf = getSoldierConfItem(id, 2)

    local hero = getChild(panel, "HeroIcon")
    local act = cc.CSLoader:createTimeline(ResConfig.UICopyStrategy.Csb2.hero)  
    hero:runAction(act) 
    act:play("Normal", false) 

    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(conf.Common.HeadIcon)
    getChild(hero, "HeroImage"):loadTexture(frame and conf.Common.HeadIcon or "", 1)
    getChild(hero, "BGImage"):loadTexture(getLevel(1), 1)
    getChild(hero, "StarLabel"):setString(tostring(3))
    getChild(hero, "LvLabel"):setString(tostring(1))
    getChild(hero, "GemLabel"):setString(tostring(200))

    getChild(panel, "HeroName"):setString(getHSLanConfItem(conf.Common.Name))
    getChild(panel, "TipInfoText"):setString(getHSLanConfItem(conf.Common.Desc))

    local skilllv = getChild(panel, "Skillbar")
    local skillimage = getChild(skilllv, "HeroskillImage")

    for k = 1, 6 do
        local eqlv = getChild(panel, "EqLvImage_" .. k)
        local eqimage = getChild(eqlv, "EqImage"):loadTexture("", 1)
    end
end

return UICopyStrategy

--endregion
