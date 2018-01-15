--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--活动副本选择界面
local UICopyChoose = class("UICopyChoose", function()
    return require("common.UIView").new()
end)

--构造函数
function UICopyChoose:ctor()
    self.rootPath = ResConfig.UICopyChoose.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local back = getChild(self.root, "BackButton")
    back:addClickEventListener(function()
        UIManager.close()
    end)
end

--初始化函数
function UICopyChoose:init()
    self:info()
    self:check()
    self:sort()
    self:view()
end

--资源信息
function UICopyChoose:info()
    local user = getGameModel():getUserModel()
    getChild(self.root, "GoldInfo/GoldPanel/GoldCountLabel"):setString(tostring(user:getGold()))
    getChild(self.root, "GemInfo/GemPanel/GemCountLabel"):setString(tostring(user:getDiamond()))
    getChild(self.root, "EnergInfo/EnergyPanel/EnergyCountLabel"):setString(tostring(user:getEnergy()))
end

--数据检测，根据当前时间，更新状态
function UICopyChoose:check()
    --构造需要数据
    self.data = {}
    local ins = getGameModel():getActivityInstanceModel():getActivityInstance()
    for k, v in pairs(ins) do
        local item = {id = v.activityId, count = v.useTimes, active = 2}
        table.insert(self.data, item)
    end

    --2是进行中，0是未开启，1是已完成
    local function status(cur, start, over)
        if cur < start then
            return 0
        elseif cur > over then
            return 1
        else
            return 2
        end
    end

    --是否有更改状态
    local b = false  
    local cur = os.time()
    local curS = TimeHelper.toTimeS(cur)
    for k, v in pairs(self.data) do
        local conf = getActivityInstanceItem(v.id)
        if conf then
            local st = conf.StartTime
            local ot = conf.EndTime
            if conf.Type == 1 then      --常开
                v.active = 2
            elseif conf.Type == 2 then     --日常
                local start = TimeHelper.toTimeN({hour = st[1], min = st[2], sec = 0})
                local over = TimeHelper.toTimeN({hour = ot[1], min = ot[2], sec = 0})
                local bi = status(cur, start, over)
                if v.active ~= bi then
                    v.active = bi
                    b = true
                end
            elseif conf.Type == 3 then   --周常
                local s_t = st[1] == 7 and 0 or st[1]   --周日系统是0，策划是7
                local o_t = ot[1] == 7 and 0 or ot[1]
                if o_t < s_t then                        
                    o_t = ot + 7
                end
                local start = TimeHelper.toTimeN({day = curS.day + (s_t - curS.wday), hour = st[2], min = st[3], sec = 0})
                local over = TimeHelper.toTimeN({day = curS.day + (o_t - curS.wday), hour = ot[2], min = ot[3], sec = 0})        
                local bi = status(cur, start, over)
                if v.  active ~= bi then
                    v.active = bi
                    b = true
                end
            elseif conf.Type == 4 then     --节日
                local start = TimeHelper.toTimeN({month = st[1], day = st[2], hour = st[3], min = st[4], sec = 0})
                local over = TimeHelper.toTimeN({month = ot[1], day = ot[2], hour = ot[3], min = ot[4], sec = 0})
                local bi = status(cur, start, over)
                if v.active ~= bi then
                    v.active = bi
                    b = true
                end
            end
        end
    end
    return b
end

--数据排序，规则：未用完、已用完、未开启、Place、ID
function UICopyChoose:sort()
    local function func(a, b)
        local conf_a = getActivityInstanceItem(a.id)
        local conf_b = getActivityInstanceItem(b.id)
        if a.active > b.active then
            return true
        elseif a.active == b.active then
            if a.count > b.count then
                return true
            elseif a.count == b.count then
                if conf_a.Place > conf_b.Place then
                    return true
                elseif conf_a.Place == conf_b.Place then
                    if a.id > b.id then
                        return true
                    end
                end
            end
        end
        return false
    end

    table.sort(self.data, func)

    for k,v in pairs(self.data) do
        print(k, v.id, v.count, v.active)
    end
end

--创建视图
function UICopyChoose:view()
    local view = getChild(self.root, "MainPanel/InstanceScrollView")
    view:removeAllChildren()     --因为这里是清除的，所以可以可以刷新用
    view:setBounceEnabled(true)
    local size = view:getContentSize()
    local line = math.modf(#self.data / 2) + 1    
    local reh = size.height * (line / 3)
    view:setInnerContainerSize(cc.size(size.width, reh)) 

    local res = ResConfig.UICopyChoose.Csb2.item
    for i=1, #self.data do
        local item = cc.CSLoader:createNode(res) --getResManager():cloneCsbNode(res)
        item:setTag(i)
        view:addChild(item)
        local panel = getChild(item, "InstancePanel")
        panel:setSwallowTouches(false)
        local r = math.modf((i-1) / 2)
        local c = math.modf((i-1) % 2)
        local w = panel:getContentSize().width
        local h = panel:getContentSize().height
        local offsetx = 0.525 * w
        local offsety = 0.55 * h
        local gapx = 0.2 * c * w
        local gapy = 0.0875 * r * h
        local x = offsetx + gapx + c * w
        local y = reh - (offsety + gapy + r * h)                                                                   
        item:setPosition(x, y)
        panel:addClickEventListener(function()
            self:check()
            self:sort()  --点击之前先更新数据，界面暂时不刷新
            if self.data[i].active == 2 then
                UIManager.open(UIManager.UI.UICopyDifficulty, self.data[i].id)
            else
                self:addChild(require("game.comm.PopTip").new({
                    text = getUILanConfItem(self.data[i].active == 1 and 351 or 352),
                    x = display.cx,
					y = display.cy,
					size = 32, 
					color = cc.c3b(255,0,0)}))
            end
        end)

        local conf = getActivityInstanceItem(self.data[i].id)
        getChild(panel, "Image_Bg"):loadTexture(conf.Pic, 1)
        getChild(panel, "FightTipLabel"):setVisible(false)
        getChild(panel, "FightNumLabel"):setString(string.format(getUILanConfItem(364), self.data[i].count, conf.CompleteTimes))
        getChild(panel, "InstanceName"):setString(getStageLanConfItem(conf.Title))
        
        --显示时间
        local str = ""  
        local b = (self.data[i].active == 2)
        local t = (b and conf.EndTime or conf.StartTime)
        if conf.Type == 1 then      
            str = ""
        elseif conf.Type == 2 then    
            if b then
                local tb = TimeHelper.restTime({hour = t[1], min = t[2], sec = 0})
                str = getUILanConfItem(359) .. tb.hour .. ":" .. tb.min   --显示倒计时
            else
                str = string.format(getUILanConfItem(354), t[1], t[2])
            end
        elseif conf.Type == 3 then      --周常
            str = string.format(getUILanConfItem(b and 360 or 355), t[1], t[2], t[3])
        elseif conf.Type == 4 then      --节日
            str = string.format(getUILanConfItem(b and 363 or 358), t[1], t[2], t[3], t[4])
        end
        getChild(panel, "TimeTipLabel"):setString(str)     
        
        --根据是否在活动区间决定高亮
        local act = cc.CSLoader:createTimeline(res)     
        item:runAction(act)
        act:play(b and "Normal" or "Lightting", true)
        --CommonHelper.playCsbAnimate(item, ResConfig.UICopyChoose.Csb2.item, b and "Lightting" or "Normal", false)
    end
end

--数据恢复
function UICopyChoose:update(time)
   --更新当前时间
   local tb = TimeHelper.toTimeS(time)
   getChild(self.root, "Time"):setString(tb.hour .. ":" .. tb.min .. ":" .. tb.sec)

   --恢复挑战次数,
   for k,v in pairs(self.data) do
       local t = TimeHelper.toTimeN({hour = 18, min = 30, sec = 0})   --这里要根据配置的时间
       if t == time then
           local conf = getActivityInstanceItem(v.id)
           v.count = conf.RecoverParam          --这里没有真正回写到模型
           --这里也需要刷新视图
           self:sort()
           self:view()
       end
   end

   --如果数据有更新就更新视图
   local b = self:check()
   if b then
       self:sort()
       self:view()
   end

   --实时更新倒计时
   local view = getChild(self.root, "MainPanel/InstanceScrollView")
   for i=1, #self.data do
       local conf = getActivityInstanceItem(self.data[i].id)
       if conf and conf.Type == 2 and self.data[i].active == 2 then
            local tb = TimeHelper.restTime({hour = conf.EndTime[1], min = conf.EndTime[2], sec = 0})
            str = getUILanConfItem(359) .. tb.hour .. ":" .. tb.min .. ":" .. tb.sec   --显示倒计时
            getChild(view:getChildByTag(i), "InstancePanel/TimeTipLabel"):setString(str)  
       end
   end
end

return UICopyChoose
--endregion
