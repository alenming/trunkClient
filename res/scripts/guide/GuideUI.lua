---------------------------------------------------
--名称:GuideUI
--描述:引导UI
--时间:20160328
--作者:Azure
-------------------------------------------------
require("common.UIManager")

GuideUI = {}
GuideAssistUIButton = 
{
    [128] = 659,         -- 召唤师
	[133] = 658,         -- 公会
    [134] = 662,         -- 副本
	[526] = 669,         -- 金币试炼
    [135] = 663,         -- 英雄试炼
    [527] = 664,         -- 爬塔试炼
    [131] = 665,         -- 竞技场
    [568] = 667,         -- 铁匠铺
    [575] = 658,         -- 聊天界面公会按钮
    [576] = 667,         -- 铁匠铺
	[544] = 668,         -- 神秘商店
}

--未解锁的按钮集合
GuideUI.LockButtons = {}

local function getTableCount(tab)
    local count = 0
    for _,v in pairs(tab) do
        count = count + 1
    end
    return count
end

--收集未解锁的按钮
function GuideUI.collectLockButtons(ids)
    -- 防止重复检测导致死循环
    local first = false
    if collectedGuides == nil then
        collectedGuides = {}
        first = true
    end

    for _, guideID in pairs(ids) do
        -- 检测collectedGuides中为nil时才进行收集
        if collectedGuides[guideID] == nil then
            collectedGuides[guideID] = true
            local steps = getGuideStepItemList(guideID)
            if steps then
                for _, stepID in pairs(steps) do
                    local confStep = getGuideStepConfItem(guideID, stepID)
                    if confStep then
                        for _, btnID in pairs(confStep.ShowButton) do
                            local confUI = getUINodeConfItem(btnID)
                            if confUI then
                                if not GuideUI.LockButtons[confUI.UIID] then
                                    GuideUI.LockButtons[confUI.UIID] = {}
                                end
                                print("find lock button " .. btnID .. " ui " .. confUI.UIID)
                                GuideUI.LockButtons[confUI.UIID][btnID] = true
                            end
                        end
                    end
                end
            end
            local confGuide = getGuideConfItem(guideID)
            if confGuide then
                GuideUI.collectLockButtons(confGuide.Nexts)
            else
                print("Guide Conf Error " .. guideID)
            end
        end
    end
    GuideUI.printData()

    if first then
        collectedGuides = nil
    end
end

--打印收集的信息
function GuideUI.printData()
    for uiId, uiBtn in pairs(GuideUI.LockButtons) do
        --print(" ui " .. uiId .. " btnCount " .. #uiBtn)
        --[[local s = ""
        for m,n in pairs(v) do
            s = s .. " " .. v
        end
        print("[" .. k .. "] = " .. s)]]
    end
end

function GuideUI.islock(id)
    local conf = getUINodeConfItem(id)
    if not conf then
        print("getUINodeConfItem(" .. id .. ") error")
        return false
    end

    if GuideUI.LockButtons[conf.UIID] then
        if GuideUI.LockButtons[conf.UIID][id] == true then
            return true
        end
    end

    return false
end

--解锁按钮，并从集合里删除
function GuideUI.unlockButton(id)
    print("unlock button " .. id)
    local conf = getUINodeConfItem(id)
    if not conf then
        print("getUINodeConfItem(" .. id .. ") error")
        return
    end

    -- 先解锁按钮
    local isunlock = false
    if GuideUI.LockButtons[conf.UIID] then
        if GuideUI.LockButtons[conf.UIID][id] == true then
            GuideUI.LockButtons[conf.UIID][id] = nil
            isunlock = true
        end
    end

    -- 如果真的解锁了，播放表现
    if isunlock then
        -- 解锁按钮，设置可视化
        local btn = GuideUI.getUINode(id)
        if btn then
            -- 清除辅助(透明)按钮
            if GuideAssistUIButton[id] then
                GuideManager.removeAssistUIButton(btn)
            end

            if conf.UIID == UIManager.UI.UIHall
              or conf.UIID == UIManager.UI.UIInstanceEntry then
                -- 如果是大厅界面,按钮灰化恢复
                btn:setTouchEnabled(true)
                CommonHelper.removeGray(btn)
                -- 红点刷新
                EventManager:raiseEvent(GameEvents.EventUpdateMainBtnRed)
            elseif conf.UIID == UIManager.UI.UIEquipBag then
                btn:setTouchEnabled(true)
                CommonHelper.removeGray(btn)
            else
                btn:setVisible(true)
            end

            return btn
        else
            print("找不到该按钮")
        end 
    end

    print("没有锁住该按钮")
    return
end

--获取界面按钮
function GuideUI.getUINode(id)
    local conf = getUINodeConfItem(id)
    if not conf then
        return
    end

    -- 如果是战斗UI
    if conf.UIID == UIManager.UI.UIBattleLayer then
        local uiLayer = display.getRunningScene():getChildByName("BattleUILayer")
        if nil ~= uiLayer then
            return CommonHelper.getChild(uiLayer, conf.NodePath)
        end
    else
        local ui = UIManager.getUI(conf.UIID)
        if not ui then
            print("获取UI失败" .. conf.UIID)
            return
        end
        return CommonHelper.getChild(ui, conf.NodePath)
    end
end

return GuideUI