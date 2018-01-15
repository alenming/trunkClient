--------------------------------------------------
--名称:GuideManager
--描述:引导管理器
--时间:20160405
--作者:Azure
-------------------------------------------------
require("guide.GuideUI")
require("guide.GuideCondition")
require("common.WidgetExtend")
require("summonerComm.GameEvents")

GuideManager = {}

--当前引导
GuideManager.currentGuide = nil

--引导列表(k为guide,v为guideID)
GuideManager.guideList = {}

--初始化
function GuideManager.init()
    local data = getGameModel():getGuideModel():getActives()

    if #data <= 0 then
        return
    end

    if not GlobalCloseGuide then
        for _,v in pairs(data) do
            local guide = require("guide.Guide").new(v)
            GuideManager.guideList[guide] = v
        end
        GuideUI.collectLockButtons(data)
        WidgetExtend.initClick()
        EventManager:addEventListener(GameEvents.EventOpenUI, GuideManager.uiLock)
        EventManager:addEventListener(GameEvents.EventUIRefresh, GuideManager.uiLock)        
    end
end

--执行引导
function GuideManager.executeGuide(guide)
    if not GuideManager.guideList[guide] then
        return
    end
    if GuideManager.currentGuide then
        -- 强制解锁引导
        print("引导" .. guide.guideID .. "触发，强制结束当前引导" .. GuideManager.currentGuide.guideID)
        GuideManager.currentGuide:finish(true)
        GuideManager.finishGuide(GuideManager.currentGuide)
    end
    GuideManager.currentGuide = guide
end

--完成引导
function GuideManager.finishGuide(guide)
    local guideID = GuideManager.guideList[guide]
    if nil == guideID then
        print("finishGuide error, guideID is nil!!!")
        return
    end

    print("!!!!!!---------------------------引导" .. guideID .. "结束-------------------------!!!!!!!")
    local conf = getGuideConfItem(guideID)
    if not conf then
        print("finish Guide get Guide Conf Error " .. guide)
        return
    end

    -- 关闭引导
    local guideToClose = {}

    if conf.Closes then
        local hasClose = false
        for k,v in pairs(conf.Closes) do
            guideToClose[v] = true
            hasClose = true
        end

        -- 发送引导存储请求
        if hasClose then
            local bufferData = NetHelper.createBufferData(MainProtocol.Guide, GuideProtocol.RecordCS)
            local GuideNum = 1
            bufferData:writeInt(GuideNum)       --引导数目
            bufferData:writeInt(guideID)     -- 引导id
            NetHelper.request(bufferData)
        end
    end

    for k,v in pairs(GuideManager.guideList) do
        if guideToClose[v] then
            if k ~= guide then
                -- 移除监听
                k:finish(true)
            end
            
            GuideManager.guideList[k] = nil
        end
    end

    if GuideManager.currentGuide then
        GuideManager.currentGuide = nil
    end

    -- 开启下一个引导
    if #conf.Nexts > 0 then
        for _,v in pairs(conf.Nexts) do
            print("unlocak Guide " .. v)
			-- 判定是否已经有该引导
			local hasGuide = false
			for _guide, _guideId in pairs(GuideManager.guideList) do
				if _guideId == v then
					hasGuide = true
					break
				end
			end
            if not hasGuide then
                print("!!!!!!---------------------------解锁引导" .. v .. "-------------------------!!!!!!!")
                local newGuide = require("guide.Guide").new(v)
                GuideManager.guideList[newGuide] = v
                newGuide:onEnter()
            end
        end
    end

    -- 一段恶心的代码，要在新手引导结束时触发回到大厅的事件，GuideManager作为一个游戏逻辑无关的低耦合类，终于也被策划肮脏的需求污染了
    -- 大厅说，关我屁事啊，王洋洋调皮地说，宝爷你就加一下吧，我不想当备胎
    -- 于是，出现了下面这段代码，2016-11-22
    -- 如果当前大厅界面处于顶端，且没有引导，触发一下713消息
    if UIManager.isTopUI(UIManager.UI.UIHall) and GuideManager.currentGuide == nil then
        EventManager:raiseEvent(GameEvents.EventGotoHall)
    end
end

local function getTableCount(tab)
    local count = 0
    for _,v in pairs(tab) do
        count = count + 1
    end
    return count
end

--锁定回调
function GuideManager.uiLock(eventName, uiID)
    local list = GuideUI.LockButtons[uiID]
    if not list then
        return
    end
    local count = getTableCount(list)
    if count <= 0 then
        return
    end

    -- 遍历按钮隐藏
    for v,_ in pairs(list) do
        local btn = GuideUI.getUINode(v)
        if btn then
            print("lock btn id " .. v)
            -- 辅助(透明)按钮
            if GuideAssistUIButton[v] then
                GuideManager.createAssistUIButton(btn, GuideAssistUIButton[v])
            end

            if uiID == UIManager.UI.UIHall
              or uiID == UIManager.UI.UIInstanceEntry then
                -- 如果是大厅界面,按钮灰化
                btn:setTouchEnabled(false)
                CommonHelper.applyGray(btn)
                -- 红点
                if uiID == UIManager.UI.UIHall then
                    local redPoint = CsbTools.getChildFromPath(btn, "Button/ButtonPanel/RedTipPoint")
                    if redPoint then
                        redPoint:setVisible(false)
                    end
                end
            elseif uiID == UIManager.UI.UIHeroInfo then
                -- btn不为nil，conf一定不为nil，无需判断
                local conf = getUINodeConfItem(v)
                -- 升星按钮 ID为129 灰化、其他隐藏
                if conf.NodeID == 129 then
                    btn:setTouchEnabled(false)
                    CommonHelper.applyGray(btn)
                    local lb = CsbTools.getChildFromPath(btn, "Button_Orange2/ButtomName")
                    if lb then
                        lb:setTextColor(cc.c4b(125, 125, 125, 255))
                        lb:enableOutline(cc.c4b(70, 70, 70, 255), 2)
                    end
                else
                    btn:setVisible(false)
                end
            elseif uiID == UIManager.UI.UIEquipBag then
                btn:setTouchEnabled(false)
                CommonHelper.applyGray(btn)
            else
                btn:setVisible(false)
            end
        end
    end

    -- 播放锁状态动画
    local cfg = getUIStatusConfItem(uiID, count)
    if cfg then
        -- 大厅需要特殊处理
        local node = GuideUI.getUINode(cfg.NodeID)
        if node then
            CommonHelper.playCsbAnimation(node, cfg.CSB, false)
        end
    end
end

-- 创建辅助按钮
function GuideManager.createAssistUIButton(button, tips)
    local btn = button:getChildByTag(100100100)
    if not btn then
        local buttonSize = button:getContentSize()
        local btn = ccui.Button:create()
	    btn:setTouchEnabled(true)
	    btn:setScale9Enabled(true)
        btn:setTouchSwallowEnabled(true)
	    btn:setContentSize(buttonSize)
	    btn:setTag(100100100)
        btn:setName("AssistUIButton")
	    btn:setPosition(cc.p(buttonSize.width/2, buttonSize.height/2))
        btn:addClickEventListener(function (obj)
            CsbTools.addTipsToRunningScene(CommonHelper.getStoryString(tips))
            MusicManager.playFailSoundEffect()
        end)

        button:addChild(btn, button:getLocalZOrder() + 1)
    end
end

function GuideManager.removeAssistUIButton(button)
    button:removeChildByTag(100100100)
end

return GuideManager