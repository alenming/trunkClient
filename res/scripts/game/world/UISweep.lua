

local UISweep = class("UISweep", function ()
	return require("common.UIView").new()
end)

local PropTips = require("game.comm.PropTips")

function UISweep:ctor()
    self.sweep = getResManager():cloneCsbNode(ResConfig.UISweep.Csb2.sweep)
    self.sweepAct = cc.CSLoader:createTimeline(ResConfig.UISweep.Csb2.sweep)
    self.sweep:runAction(self.sweepAct)
    self.listView = CsbTools.getChildFromPath(self.sweep, "MainPanel/SweepListView")
    self.listView:setScrollBarEnabled(false)
    self.closeBtn = CsbTools.getChildFromPath(self.sweep, "MainPanel/CloseButton")
    self.propsTips = PropTips.new()

    self.root = self.sweep
    self:addChild(self.sweep)
    --关闭按钮
    CsbTools.initButton(self.closeBtn, handler(self, self.onClickOk))
end

function UISweep:init(bufferData)
    self.listView:removeAllItems()
    self.index = 1
    self.itemActs = {}
    self.items = {}

    self.chapterId = bufferData.chapterId
    self.stageId = bufferData.stageId
    for i, reward in pairs(bufferData.stageReward) do
        local exp = 0
        local gold = 0
        local itemInfos = {}
        local idx = 1
        for j, item in pairs(reward.itemInfo) do
            --解析每个道具的数据
            local id = item.id
            local count = item.num
            if id == UIAwardHelper.ResourceID.Gold then 
                gold = gold + count
            elseif id == UIAwardHelper.ResourceID.Energy then
                print("nothing----")
            elseif id == UIAwardHelper.ResourceID.Exp then
                exp = exp + count
            elseif id == UIAwardHelper.ResourceID.Diamond then
                print("nothing----")
            elseif id == UIAwardHelper.ResourceID.TowerCoin then
                print("nothing----")
            elseif id == UIAwardHelper.ResourceID.UnionContrib then
                print("nothing----")
            elseif id == UIAwardHelper.ResourceID.PvpCoin then
                print("nothing----")
            else
                itemInfos[idx] = reward.itemInfo[j]
                idx = idx + 1
            end
        end
        self:insertItem(self.chapterId, self.stageId, exp, gold, itemInfos)
    end
    self:insertEndItem()

    --扣体力
--    local chapterConf = getChapterConfItem(self.chapterId)
--    local chapterStageInfo = chapterConf.Stages[self.stageId]
--    local times = bufferData.times
--    local neenEnergy = chapterStageInfo.Energy * times
--    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Energy, -neenEnergy)

    -- 关卡结束事件
    EventManager:raiseEvent(GameEvents.EventStageOver, {chapterId = bufferData.chapterId, stageId = bufferData.stageId, battleResult = 1, count = times})

    self:showSweep()
end

function UISweep:onClose()
    self.propsTips:removePropAllTips()
    self.propsTips = nil
    return self.chapterId, self.stageId
end

function UISweep:insertItem(chapterId, stageId, exp, gold, items)
    local stageInfo = getStageInfoInChapter(chapterId, stageId)
    if stageInfo == nil then
        return
    end

    local chapterConf = getChapterConfItem(chapterId)
    local stageConf = chapterConf.Stages[stageId]

    --普通节点获得
    local awardPanel = getResManager():cloneCsbNode(ResConfig.UISweep.Csb2.awardPanel)
    awardPanel = CommonHelper.replaceCsbNodeWithWidget(awardPanel)
    local awardItemAct = cc.CSLoader:createTimeline(ResConfig.UISweep.Csb2.awardPanel)
    local secondaryNode = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem")
    secondaryNode:setAnchorPoint(0, 0)
    local stageName = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/StageName")
    local summonerTex = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/SummonerTex")
    local numTime = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/NumTime")
    local addExp = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/SummonerExpNum")
    local addGold = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/GoldSum")
    awardPanel:runAction(awardItemAct)
    -- 设置基本信息
    stageName:setString(getStageLanConfItem(stageConf.Name))
    -- summonerTex:setString(CommonHelper.getUIString(14))
    addExp:setString(exp)
    addGold:setString(gold)
    awardPanel:setContentSize(370, 200)
    awardPanel:setVisible(false)
    -- 最多显示3个物品
    local itemCount = #items
    local offset  = (3 - itemCount) * 49;
    for i = 1, 3 do
        local awardItem = CsbTools.getChildFromPath(awardPanel, "SweepAwardItem/AwardItem_" .. i)
        if i <= itemCount then
            -- 设置物品信息, 所有信息都是item中存在的配置
            local propConf = getPropConfItem(items[i].id)
            UIAwardHelper.setAllItemOfConf(awardItem, propConf, items[i].num)
            awardItem:setPositionX(awardItem:getPositionX() + offset)
            local touchNode = CsbTools.getChildFromPath(awardItem, "MainPanel")
            self.propsTips:addPropTips(touchNode, propConf)
        else
            awardItem:setVisible(false)
        end
    end

    self.listView:pushBackCustomItem(awardPanel)
    --将每个选项添加到table, 用来依次播放
    table.insert(self.itemActs, awardItemAct)
    table.insert(self.items, awardPanel)

    local times = string.format(CommonHelper.getUIString(228), #self.itemActs)
    numTime:setString(times)
end

function UISweep:insertEndItem()
    --尾部节点
    local overPanel = getResManager():cloneCsbNode(ResConfig.UISweep.Csb2.overPanel)
    overPanel = CommonHelper.replaceCsbNodeWithWidget(overPanel)
    local overItemAct = cc.CSLoader:createTimeline(ResConfig.UISweep.Csb2.overPanel)
    local secondaryNode = CsbTools.getChildFromPath(overPanel, "SweepOverItem")
    secondaryNode:setAnchorPoint(0, 0)
    local sweepImg = CsbTools.getChildFromPath(overPanel, "SweepOverItem/SweepOver")
    local tipTex = CsbTools.getChildFromPath(overPanel, "SweepOverItem/TipTex")
    local okBtn = CsbTools.getChildFromPath(overPanel, "SweepOverItem/ConfirmButtom")
    overPanel:runAction(overItemAct)
    overPanel:setContentSize(370, 200)
    overPanel:setVisible(false)
    --确定按钮
    CsbTools.initButton(okBtn, handler(self, self.onClickOk), 
        CommonHelper.getUIString(500), "NameLabel", okBtn)

    self.listView:pushBackCustomItem(overPanel)
    table.insert(self.itemActs, overItemAct)
    table.insert(self.items, overPanel)
end

function UISweep:showSweep()
    self.sweepAct:play("Open", false)
    self.sweepAct:setFrameEventCallFunc(function(frame)
        local eventName = frame:getEvent()
        if eventName == "OpenEnd" then
            if #self.itemActs > 0 then
                self.items[self.index]:setVisible(true)
                self.itemActs[self.index]:play("Appear", false)
                self.itemActs[self.index]:setFrameEventCallFunc(handler(self, self.awardEndCallback))

                MusicManager.playSoundEffect(59)
            end
        end
    end)
end

function UISweep:awardEndCallback()
    if #self.itemActs > self.index then
        self.index = self.index + 1
        local viewSize = self.listView:getContentSize()
        local innerSize = self.listView:getInnerContainerSize()
        local divisor = (innerSize.height - viewSize.height) / 200
        if divisor > 0 then
            local percent = (self.index - 2) / divisor * 100
            self.listView:jumpToPercentVertical(percent)
            local action11 = cc.JumpBy:create(0.1, cc.p(0,0), 5, 1)
            self.listView:runAction(action11)
        end
        self.items[self.index]:setVisible(true)
        self.itemActs[self.index]:play("Appear", false)
        self.itemActs[self.index]:setFrameEventCallFunc(handler(self, self.awardEndCallback))

        if #self.itemActs == self.index then
            MusicManager.playSoundEffect(12)
        else
            MusicManager.playSoundEffect(59)
        end
    end
end

function UISweep:onClickOk()
    UIManager.close()
end

return UISweep