--[[
英雄天赋面板
]]

local UIHeroTalent = class("UIHeroTalent", function ()
    return require("common.UIView").new()
end)

local csbFile = ResConfig.UIHeroTalent.Csb2

function UIHeroTalent:ctor()
    self.rootPath = csbFile.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 技能提示
    self.tips = getResManager():cloneCsbNode(csbFile.tips)    
    self.root:addChild(self.tips, 500)
    self.tips:setVisible(false)
    CsbTools.getChildFromPath(self.tips, "TipPanel/CoolingTime"):setVisible(false)
    CsbTools.getChildFromPath(self.tips, "TipPanel/SkillAttackLabel"):setVisible(false)
    self.tipsSize = self.tips:getChildByName("TipPanel"):getContentSize()

    -- 返回按钮
    local backBtn = CsbTools.getChildFromPath(self.root, "BackButton")
    CsbTools.initButton(backBtn, handler(self, self.backBtnCallBack))

    -- 主面板
    self.mainLayout = CsbTools.getChildFromPath(self.root, "MainPanel")

    -- 文字: 英雄天赋
    CsbTools.getChildFromPath(self.root, "MainPanel/TitleBar/Text")
    -- 文字: 天赋数
    self.talentCountLab = CsbTools.getChildFromPath(self.root, "StarBar/StarNum")

    -- 种族天赋面板
    local raceLayout = CsbTools.getChildFromPath(self.root, "MainPanel/LeftPanel")
    -- 职业天赋面板
    local vocationLayout = CsbTools.getChildFromPath(self.root, "MainPanel/RightPanel")

    -- 种族图标
    self.raceSpr = CsbTools.getChildFromPath(raceLayout, "Race")
    -- 职业图标
    self.JobSpr = CsbTools.getChildFromPath(vocationLayout, "Profesion")
    -- tips点击提示
    local tipsLab = CsbTools.getChildFromPath(self.root, "Tips2")

    -- 4行种族天赋csb
    self.raceTalentCsb = {}
    -- 4行职业天赋csb
    self.vocationTalentCsb = {}
    local talentBtn, pressHandler, cancelHandler
    if device.platform ~= "android" and device.platform ~= "ios" then
        pressHandler = nil
        cancelHandler = nil
        tipsLab:setOpacity(0)
    else
        pressHandler = handler(self, self.talentPressCallBack)
        cancelHandler = handler(self, self.talentCancelCallBack)
        tipsLab:setOpacity(255)
    end
    for i=1, 4 do
        self.raceTalentCsb[i] = CsbTools.getChildFromPath(raceLayout, "GiftItems_" .. i)
        self.vocationTalentCsb[i] = CsbTools.getChildFromPath(vocationLayout, "GiftItems_" .. i)
        for j=1, 3 do

            talentBtn = CsbTools.getChildFromPath(self.raceTalentCsb[i], "GiftsListView/GiftButton_" .. j)
            talentBtn:setTag(i*10 + j)
            PressExtend.addPressEX(talentBtn, 0.2, handler(self, self.talentClickCallback), pressHandler, cancelHandler)

            talentBtn = CsbTools.getChildFromPath(self.vocationTalentCsb[i], "GiftsListView/GiftButton_" .. j)
            talentBtn:setTag((i+4)*10 + j)
            PressExtend.addPressEX(talentBtn, 0.2, handler(self, self.talentClickCallback), pressHandler, cancelHandler)
        end
    end

    -- 重置按钮
    self.resetBtn = CsbTools.getChildFromPath(self.root, "MainPanel/ResetButton")
    -- 保存按钮
    self.saveBtn = CsbTools.getChildFromPath(self.root, "MainPanel/SaveButton")
    CsbTools.initButton(self.resetBtn, handler(self, self.resetBtnCallBack))
    CsbTools.initButton(self.saveBtn, handler(self, self.saveBtnCallBack))
end

function UIHeroTalent:onOpen(_, heroID, onlyReadInfo)
    if not onlyReadInfo then
        self.onlyRead = false
        -- 监听消息
        local cmdTalent = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.ActivaeTalentSC)
        self.cmdHandler = handler(self, self.onResponseTalent)
        NetHelper.setResponeHandler(cmdTalent, self.cmdHandler)

        self.heroID = heroID
        self.heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroID)
        self.heroStar = 0
        self.heroTalent = {0,0,0,0,0,0,0,0}

        if self.heroModel then
            self.heroStar = self.heroModel:getStar()
            self.heroTalent = clone(self.heroModel:getTalent())
        end    

        self.resetBtn:setVisible(true)
        self.saveBtn:setVisible(true)
    else
        self.onlyRead = true
        self.heroID = onlyReadInfo.heroID
        self.heroStar = onlyReadInfo.heroStar
        self.heroTalent = onlyReadInfo.talents

        self.resetBtn:setVisible(false)
        self.saveBtn:setVisible(false)
    end

    local heroConf = getSoldierConfItem(self.heroID, self.heroStar == 0 and 1 or self.heroStar)
    if not heroConf then 
        print("heroConf is nil", self.heroID, self.heroStar)
        return
    end

    self.heroRace = heroConf.Common.Race
    self.heroVocation = heroConf.Common.Vocation

    CsbTools.replaceSprite(self.raceSpr, IconHelper.getRaceIcon(self.heroRace))
    CsbTools.replaceSprite(self.JobSpr, IconHelper.getSoldierJobIcon(1, self.heroVocation))

    self.raceArrangeConf = getTalentArrangeConf(self.heroRace)
    self.vocationArrangeConf = getTalentArrangeConf(self.heroVocation + 100)
    if not self.raceArrangeConf then
        print("talentArrangeConf1 is nil", self.heroRace)
        return
    end
    if not self.vocationArrangeConf then
        print("talentArrangeConf2 is nil", self.heroVocation + 100)
        return
    end

    self:reSortTalentUI()
    self:reloadTalent()

    if device.platform ~= "android" and device.platform ~= "ios" then
        self.mouseListenerMouse = cc.EventListenerMouse:create()
        self.mouseListenerMouse:registerScriptHandler(handler(self, self.mouseCallBack), 50)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.mouseListenerMouse, self)
    end
end

function UIHeroTalent:onClose()
    if self.cmdHandler then
        local cmdTalent = NetHelper.makeCommand(MainProtocol.Hero, HeroProtocol.ActivaeTalentSC)
        NetHelper.removeResponeHandler(cmdTalent, self.cmdHandler)
    end

    self.tips:setVisible(false)

    if self.mouseListenerMouse then
        cc.Director:getInstance():getEventDispatcher():removeEventListener(self.mouseListenerMouse)
        self.mouseListenerMouse = nil
    end
end

-- 计算可用的天赋点
function UIHeroTalent:countTalentPoint()
    local talentPoint = self.heroStar
    for _, v in ipairs(self.heroTalent) do
        if v ~= 0 then
            talentPoint = talentPoint - 1
        end
    end
    return talentPoint
end

-- 重新加载天赋
function UIHeroTalent:reloadTalent()
    for i=1, 8 do
        self:reloadRowUI(i)
    end

    self.talentCountLab:setString(self:countTalentPoint())
end

-- 重新排列天赋 (仅排列天赋图标)
function UIHeroTalent:reSortTalentUI()
    self.talentBtns = {}
    local talentIDs, listView, talentBtn, itemCsb
    for i=1, 4 do
        talentIDs = self.raceArrangeConf.FloorTalent[i]
        if talentIDs and self.raceTalentCsb[i] then
            listView = CsbTools.getChildFromPath(self.raceTalentCsb[i], "GiftsListView")
            listView:setContentSize(cc.size(80 + (#talentIDs -1)*110, listView:getContentSize().height))
            for j, id in ipairs(talentIDs) do
                talentBtn = CsbTools.getChildFromPath(listView, "GiftButton_" .. j)
                itemCsb = CsbTools.getChildFromPath(talentBtn, "GiftItem")
                table.insert(self.talentBtns, talentBtn)
                self:reloadItem(itemCsb, id)
            end
        end
    end

    for i=1, 4 do
        talentIDs = self.vocationArrangeConf.FloorTalent[i]
        if talentIDs and self.vocationTalentCsb[i] then
            listView = CsbTools.getChildFromPath(self.vocationTalentCsb[i], "GiftsListView")
            listView:setContentSize(cc.size(80 + (#talentIDs -1)*110, listView:getContentSize().height))
            for j, id in ipairs(talentIDs) do
                talentBtn = CsbTools.getChildFromPath(listView, "GiftButton_" .. j)
                itemCsb = CsbTools.getChildFromPath(talentBtn, "GiftItem")
                table.insert(self.talentBtns, talentBtn)
                self:reloadItem(itemCsb, id)
            end
        end
    end
end

-- 设置天赋图标
function UIHeroTalent:reloadItem(itemCsb, talentID)
    local talentConf = getTalentConf(talentID)
    if not talentConf then
        print("talentConf is nil ", talentID)
        return
    end
    local talentIconBtn = CsbTools.getChildFromPath(itemCsb, "ItemPanel/GiftIcon")
    if cc.SpriteFrameCache:getInstance():getSpriteFrame(talentConf.TalentPic) == nil then
        print("talentConf.TalentPic is nil", talentID, talentConf.TalentPic)
    else
        talentIconBtn:loadTextureNormal(talentConf.TalentPic, 1)
    end
end

-- 重新设置某行的天赋界面
function UIHeroTalent:reloadRowUI(row)
    local talentPoint = self:countTalentPoint()
    local choosable = false

    if self.heroTalent[row] ~= 0 then
        -- 当前行有选中天赋, 则此行可选
        choosable = true
    elseif (talentPoint > 0) and (row == 1 or row == 5 or self.heroTalent[row -1] ~= 0) then
        -- 有天赋点, 且上一个天赋已选或是种族第一天赋,职业第一天赋
        choosable = true
    end

    -- 当前行天赋ID列表, 当前行csb
    local talentIDs, talentCsb
    if row <= 4 then
        talentIDs = self.raceArrangeConf.FloorTalent[row]
        talentCsb = self.raceTalentCsb[row]
    else
        talentIDs = self.vocationArrangeConf.FloorTalent[row - 4]
        talentCsb = self.vocationTalentCsb[row - 4]
    end

    if not (talentIDs and talentCsb) then
        print("talentIDs or talentCsb is nil ", row, talentIDs, talentCsb)
        return
    end

    local isError = true
    for i, id in ipairs(talentIDs) do
        local itemCsb = CsbTools.getChildFromPath(talentCsb, "GiftsListView/GiftButton_" .. i .. "/GiftItem")
        self:initTalentItem(itemCsb, choosable, self.heroTalent[row] == id)
        if self.heroTalent[row] == id or self.heroTalent[row] == 0 then
            isError = false
        end
    end
    if isError then
        print("前后端配置表不一致, 前端" .. row .. "行, 找不到天赋 " .. self.heroTalent[row])
    end
end

-- 天赋csb, 是否可选, 是否选中
function UIHeroTalent:initTalentItem(itemCsb, choosable, isChoose)
    if not itemCsb then
        print("talentItemCsb is nil")
        return
    end

    if isChoose then
        CommonHelper.playCsbAnimation(itemCsb, "Choose", true, nil)
    else
        CommonHelper.playCsbAnimation(itemCsb, "Normal", true, nil)
    end
    
    local iconBtn = CsbTools.getChildFromPath(itemCsb, "ItemPanel/GiftIcon")
    if choosable then
        iconBtn:setBright(true)
    else
        iconBtn:setBright(false)
    end
end

-- 计算天赋列
function UIHeroTalent:getTalentID(row, col)
    if row <= 4 then
        if self.raceArrangeConf.FloorTalent[row][col] then
            return self.raceArrangeConf.FloorTalent[row][col]
        else
            print("配置表错, 不存在此行列", row, col)
            return -1
        end
    else
        if self.vocationArrangeConf.FloorTalent[row - 4][col] then
            return self.vocationArrangeConf.FloorTalent[row - 4][col]
        else
            print("配置表错, 不存在此行列", row, col)
            return -1
        end
    end
end

-- 计算天赋列
function UIHeroTalent:getTalentCol(row, id)
    if id == 0 then
        return 0
    end

    if row <= 4 then
        for i,v in ipairs(self.raceArrangeConf.FloorTalent[row]) do
            if v == id then
                return i
            end
        end
    else
        for i,v in ipairs(self.vocationArrangeConf.FloorTalent[row - 4]) do
            if v == id then
                return i
            end
        end
    end

    print("前后端配置表不一致, 前端" .. row .. "行, 找不到天赋 " .. id)
    return 0
end

function UIHeroTalent:getTalentByTag(tag)
    local row, col = math.modf(tag/10)
    col = math.mod(tag, 10)
    return row, col
end

function UIHeroTalent:backBtnCallBack(node)
    UIManager.close()
end

function UIHeroTalent:resetBtnCallBack(node)
    for i=1, 8 do
        self.heroTalent[i] = 0
    end
    self:reloadTalent()
end

function UIHeroTalent:saveBtnCallBack(node)
    if self.heroStar == 0 then
        return
    end

    -- 判断是否变更了天赋, 没变更则不发送
    local isMatch = true
    local tanlent = self.heroModel:getTalent()
    for i=1, 8 do
        if tanlent[i] ~= self.heroTalent[i] then
            isMatch = false
        end
    end
    if isMatch then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(450))
        return
    end

    -- 发送激活天赋,已激活则取消
    local buffData = NetHelper.createBufferData(MainProtocol.Hero, HeroProtocol.ActivaeTalentCS)
    buffData:writeInt(self.heroID)
    for i=1, 8 do
        buffData:writeChar(self:getTalentCol(i, self.heroTalent[i]))
    end
    NetHelper.request(buffData)
end

function UIHeroTalent:talentClickCallback(node)
    if self.onlyRead then
        return
    end

    local talentRow, talentCol = self:getTalentByTag(node:getTag())
    local talentID = self:getTalentID(talentRow, talentCol)

    MusicManager.playSoundEffect(node:getName())
    if self.heroTalent[talentRow] == talentID then
        -- 点击已激活的天赋
        if talentRow == 4 or talentRow == 8 or self.heroTalent[talentRow + 1] == 0 then
            -- 下一个技能没有开启, 取消激活
            self.heroTalent[talentRow] = 0
            self:reloadTalent()

        else
            --下一个技能开启了,点击无效
        end
    else
        -- 点击未激活的天赋
        if self.heroTalent[talentRow] ~= 0 then
            -- 该行存在天赋
            self.heroTalent[talentRow] = talentID
            self:reloadRowUI(talentRow)
        elseif self:countTalentPoint() > 0 then
            -- 有未使用的天赋点
            if talentRow == 1 or talentRow == 5 or self.heroTalent[talentRow-1] ~= 0 then
                -- 上一个技能开启了
                self.heroTalent[talentRow] = talentID
                self:reloadTalent()
            end
        end
    end
end

function UIHeroTalent:talentPressCallBack(node)
    local tag = node:getTag()
    local talentRow, talentCol = self:getTalentByTag(tag)

    if self.tips:isVisible() and self.tips:getTag() == tag then
        return
    end

    self.tips:setVisible(true)
    self.tips:setTag(tag)

    local wPos = node:convertToWorldSpace(cc.p(0, 0))
    local nodeSize = node:getContentSize()

    local talentIDs = {}
    if talentRow <= 4 then
        talentIDs = self.raceArrangeConf.FloorTalent[talentRow]
        self.tips:setPosition(wPos.x + nodeSize.width + self.tipsSize.width/2 + 3, 
            wPos.y + nodeSize.height/2 - self.tipsSize.height/2)
    else
        talentIDs = self.vocationArrangeConf.FloorTalent[talentRow - 4] 
        self.tips:setPosition(wPos.x - self.tipsSize.width/2 - 3, 
            wPos.y + nodeSize.height/2 - self.tipsSize.height/2)
    end

    if not talentIDs[talentCol] then
        print("how do you click this one???", talentRow, talentCol)
        return
    end
    local talentConf = getTalentConf(talentIDs[talentCol])
    if not talentConf then
        print("talentConf is nil ", talentIDs[talentCol])
        return
    end

    CsbTools.getChildFromPath(self.tips, "TipPanel/SkillNameLabel")
        :setString(CommonHelper.getHSSkillString(talentConf.TalentName))
    CsbTools.getChildFromPath(self.tips, "TipPanel/SkillInfoLabel")        
        :setString(CommonHelper.getHSSkillString(talentConf.TalentDes))
end

function UIHeroTalent:talentCancelCallBack(node)
    self.tips:setVisible(false)
end

function UIHeroTalent:mouseCallBack(event)
    local talentPos , talentSize
    local isContains = false
    local touchPos = cc.p(event:getCursorX(), event:getCursorY())
    for _, talentBtn in pairs(self.talentBtns) do
        talentPos = talentBtn:convertToWorldSpace(cc.p(0,0))
        talentSize = talentBtn:getContentSize()
        if cc.rectContainsPoint(cc.rect(talentPos.x, talentPos.y, talentSize.width, talentSize.height), touchPos) then
            self:talentPressCallBack(talentBtn)
            isContains = true
        end
    end
    if not isContains then
        self.tips:setVisible(false)
    end
end

function UIHeroTalent:onResponseTalent(mainCmd, subCmd, data)
    local talent = {}
    local heroID = data:readInt()
    for i=1, 8 do
        talent[i] = data:readUChar()
    end

    local heroModel = getGameModel():getHeroCardBagModel():getHeroCard(heroID)
    if heroModel then
        heroModel:setTalent(talent)
    end

    local isMatch = true
    for i=1, 8 do
        if self.heroTalent[i] ~= talent[i] then
            print(self.heroTalent[i], talent[i], "???")
            isMatch = false
            print("配表不匹配 "..i.."行, 前端天赋"..self.heroTalent[i].."后端天赋"..talent[i])
        end
    end

    CsbTools.addTipsToRunningScene(CommonHelper.getUIString(450))

    self.heroTalent = clone(self.heroModel:getTalent())
    self:reloadTalent()

    EventManager:raiseEvent(GameEvents.EventSetTalent, {heroId = heroID})
end

return UIHeroTalent