
CommonHelper = {}

function replaceStr(str, ...) -- 替换str中的{}为参数
    for _, v in ipairs{...} do
        str = string.gsub(str, "{}", v, 1) -- 替换一个{}为v,每个参数替换一个
    end

    return str
end

function CommonHelper.playCsbAnimation(node, actName, loop, fun)
    local action = node:getActionByTag(node:getTag())
    if nil == action then
        return
    end
    action:play(actName, loop)
    if  loop ~= false or type(fun) ~= "function" then
        return
    end
    local actionTime = (action:getEndFrame() - action:getStartFrame()) / 60
    node:runAction(cc.Sequence:create(cc.DelayTime:create(actionTime), cc.CallFunc:create(fun)))
end

function CommonHelper.playCsbAnimate(node, act, actName, loop, fun, cache)
    local action = act
    if node._csbAnimate ~= nil and cache == true then
        action =  node._csbAnimate
    else
        if type(act) == "string" then
            action = cc.CSLoader:createTimeline(act)
        end

        if action == nil then
            return
        end
        node._csbAnimate = action
        node:runAction(action)
    end
    action:play(actName, loop)

    if  loop ~= false or type(fun) ~= "function" then
        return
    end
    local actionTime = (action:getEndFrame() - action:getStartFrame()) / 60
    node:runAction(cc.Sequence:create(cc.DelayTime:create(actionTime), cc.CallFunc:create(fun)))
end

-- 除大厅界面的骨骼动画使用
-- 角色配置表ID, 骨骼节点, 骨骼节点的父节点, 最原始的位置
function CommonHelper.setRoleZoom(roleID, animationNode, objNode, originX, originY)
    if not roleID or not animationNode or not objNode then
        return
    end

    local zoom = getRoleZoom(roleID)
    if not zoom then
        print("getRoleZoom is nil", roleID)
        return
    end

    objNode:setPosition(originX + zoom.StandOffSet.x, originY + zoom.StandOffSet.y)
    animationNode:setScale(zoom.ZoomNumber)
end

function CommonHelper.layoutNode(node)
    node:setContentSize(display.width, display.height)
    ccui.Helper:doLayout(node)
end

--递归获取节点
function CommonHelper.getChild(node, path)
    local list = {}
    for match in (path .. '/'):gmatch("(.-)/") do
        table.insert(list, match)
    end

    local ret = node
    for k, v in pairs(list) do
        if not ret then 
            return nil
        end
        ret = ret:getChildByName(v)
    end
    return ret
end

function CommonHelper.replaceCsbNodeWithWidget(node)
	local ret = ccui.Widget:create()
    ret:setName(node:getName())
    ret:setTag(node:getTag())
    
	local children = node:getChildren()
	for _, n in pairs(children) do
		n:retain()
		n:removeFromParent(false)
		ret:addChild(n)
		n:release()
	end
	return ret
end

-- dump一个对象
function CommonHelper.dumpObject(obj)
    local tp = type(obj)
    print("wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww")
    print("obj type is nil" .. tp)

    if tp == "string" 
    or tp == "boolean"
    or tp == "number" then
        print("obj is " .. obj)
    elseif tp == "table" then
        for k, v in pairs(obj) do
            if type(k) == "string" then
                print(k .. "    " .. type(v))
            else
                print(type(k) .. "    " .. type(v))
            end
        end
    end
    print("wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww")
end

-- 节点，是否递归，是否显示tag
function CommonHelper.dumpNode(node, prefix)
    if prefix == nil then 
        print("++++++++++++++++++++++++++++++++++++++++")
        prefix = ""
    end
    
    print(prefix .. " Name " ..  node:getName() .. " Tag " .. node:getTag())
    
    local children = node:getChildren()
    for _, n in pairs(children) do
         CommonHelper.dumpNode(n, prefix .. "----")
    end
end

function CommonHelper.playActOverFrameCallBack(nodeAct, actName, loop, frameFunc)
    if not nodeAct or "function" ~= type(frameFunc) then
        return
    end
    nodeAct:pause()
    nodeAct:clearFrameEventCallFunc() -- 清理之前的帧事件
    nodeAct:play(actName, loop)
    nodeAct:setFrameEventCallFunc(frameFunc)
end

--获取字符串系列方法 宝爷
--获取道具文本
function CommonHelper.getPropString(stringId)
    return getPropLanConfItem(stringId)
end

--获取关卡文本
function CommonHelper.getStageString(stringId)
    return getStageLanConfItem(stringId)
end

--获取UI文本
function CommonHelper.getUIString(stringId)
    return getUILanConfItem(stringId)
end

--获取BOSS、Monster、召唤物文本
function CommonHelper.getBMCString(stringId)
    return getBMCLanConfItem(stringId)
end

--获取BOSS、Monster、召唤物的技能文本
function CommonHelper.getBMCSkillString(stringId)
    return getBMCSkillLanConfItem(stringId)
end

--获取Hero和Solider文本
function CommonHelper.getHSString(stringId)
    return getHSLanConfItem(stringId)
end

--获取Hero和Solider的技能文本
function CommonHelper.getHSSkillString(stringId)
    return getHSSkillLanConfItem(stringId)
end

--获取剧情文本
function CommonHelper.getStoryString(stringId)
    return getStoryLanConfItem(stringId)
end

--获取任务文本
function CommonHelper.getTaskString(stringId)
    return getTaskLanConfItem(stringId)
end

--获取任务文本
function CommonHelper.getAchieveString(stringId)
    return getAchieveLanConfItem(stringId)
end

-- 获取公会任务文字
function CommonHelper.getUnionTaskString(stringId)
    return getUnionTaskLanConfItem(stringId)
end

-- 获取属性文字
function CommonHelper.getRoleAttributeString(stringId)
    return getRoleAttributeLanConfItem(stringId)
end

-- 获取vip文字
function CommonHelper.getVipString(stringId)
    return getVipLanConfItem(stringId)
end

-- 获取错误码文字
function CommonHelper.getErrorCodeString(stringId)
    return getErrorCodeConfItem(stringId)
end

function CommonHelper.getServerConfigById(serverId)
    for _, v in pairs(ServerConfig) do
        if serverId == v.ServerId then
            return v
        end
    end
end

function CommonHelper.moveNode(node, newParent)
    local ret = node:getParent()
    if ret then
        local posX, posY = node:getPosition()
        local worldPos = ret:convertToWorldSpace(cc.p(posX, posY))
        local newPos = newParent:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        print(newPos.x, newPos.y)
        node:retain()
        node:removeFromParent(false)
        newParent:addChild(node)
        node:setPosition(newPos.x, newPos.y)
        node:release()
    end
    return ret
end

function CommonHelper.applyGray(node)
    if not node.isGray then
        applyGray(node)
        node.isGray = true
    end
end

function CommonHelper.removeGray(node)
    if node.isGray then
        removeGray(node)
        node.isGray = false
    end
end

-- n个汉字或n*2个字符(utf8一个汉字3个字节)
function CommonHelper.limitStrLen(str, n)
    local newStr = ""
    local len = string.len(str)
    local byteCount = 0
    local chinese = 0

    for i = 1, len do
        local s = ""
        local curByte = string.byte(str, i)
        
        if curByte > 0 and curByte <= 127 then
            byteCount = byteCount + 1
            s = string.sub(str, i, i)

        elseif curByte >= 192 and curByte < 223 then
            byteCount = byteCount + 2
            chinese = chinese + 1
            s = string.sub(str, i, i + 1)

        elseif curByte >= 224 and curByte < 239 then
            byteCount = byteCount + 3
            chinese = chinese + 1
            s = string.sub(str, i, i + 2)

        elseif curByte >= 240 and curByte <= 247 then
            --byteCount = byteCount + 4
        end

        if chinese <= n and byteCount - 2 * n <= chinese then
            newStr = newStr .. s
        else
            break
        end
    end

    return newStr
end

function CommonHelper.getKeys(t)
    local ret = {}
    for k, _ in pairs(t) do
        table.insert(ret, k)
    end
    return ret
end

-- 数字等级转换为字母等级
function CommonHelper.numberLv2letterLv(lv)
    if lv == 1 then
        return "A"
    elseif lv == 2 then
        return "B"
    elseif lv == 3 then
        return "C"
    elseif lv == 4 then
        return "D"
    elseif lv == 5 then
        return "S"
    elseif lv == 6 then
        return "SS"
    elseif lv == 7 then
        return "SSS"
    else
        print("CommonHelper.numberLv2letterLv, error arg "..tostring(lv))
        return ""
    end
end

-- 在一天当中经过了多少秒
function CommonHelper.passedSecOfDay(...)
    local date

    local args = {...}
    if #args == 1 then
        date = os.date("*t", args[1])
    elseif #args == 3 then
        date = { hour = args[1], min = args[2], sec = args[3] }
    else
        printError("wrong number of arguments")
        return
    end 

    return date.hour * 60 * 60 + date.min * 60 + date.sec
end

-- 生成一个随机的字符串，字符串内容为小写字母和数字
function CommonHelper.ralnum(len)
    len = len or 0
    local str = {}
    for _ = 1, len do
        local i = math.random(0, 35)
        if i <= 9 then
            table.insert(str, i)
        else
            i = string.byte("a") + i - 10
            table.insert(str, string.format("%c", i))
        end
    end
    return table.concat(str)
end

-- 资源类型(同UIAwardHelper)
local ResourceType = 
{
    Gold            = 1,
    Diamond         = 2,
    PvpCoin         = 3,
    TowerCoin       = 4,
    Energy          = 5,
    UnionContrib    = 6,
    Exp             = 7,
    xxxxxxxxx       = 8,
    Flashcard10     = 9,
    Flashcard       = 10,
}
-- resourceType:消耗资源类型
-- costVal:消耗值
-- enoughCallback:足够回调
function CommonHelper.checkConsumeCallback(resourceType, costVal, enoughCallback, noEnoughCall, isOpen)
    local userModel = getGameModel():getUserModel()
    local enough = false
    if resourceType == ResourceType.Gold then
        enough = userModel:getGold() >= costVal
    elseif resourceType == ResourceType.Diamond then
        enough = userModel:getDiamond() >= costVal
    elseif resourceType == ResourceType.Energy then
        --enough = userModel:getEnergy() >= costVal
    end

    local toShop = function (shopType)
        if not isOpen then
            UIManager.replace(UIManager.UI.UIShop, shopType)
        else
            UIManager.open(UIManager.UI.UIShop, shopType)
        end
    end

    -- 不足够支付弹出相关购买框
    if enough then
       if enoughCallback then
           enoughCallback()
       end
    else
        if noEnoughCall then
            noEnoughCall()
        else
            if resourceType == ResourceType.Gold then
                UIManager.open(UIManager.UI.UIGold)
            elseif resourceType == ResourceType.Diamond then
                toShop(4)
            elseif resourceType == ResourceType.Energy then
                --UIManager.open(UIManager.UI.UIEnergy)
            end
        end
    end
end

-- 显示蓝钻
local BlueDiamondType = 
{
    Non = 0,              -- 无
    Normal = 1,           -- 普通蓝钻
    Year = 3,             -- 年费蓝钻
    Luxury = 5,           -- 豪华版蓝钻
    LuxuryYear = 7,       -- 豪华版年费蓝钻
}

-- 参数:蓝钻csb节点,蓝钻类型,等级,默认label,文本信息(文本内容text+颜色color),是否右对齐
function CommonHelper.showBlueDiamond(csbNode, type, lv, defaultLabel, textParam, isRight)
    if not csbNode then
        return
    end

    local lvImg = CsbTools.getChildFromPath(csbNode, "Logo1")
    local yearImg = CsbTools.getChildFromPath(csbNode, "Logo2")
    local nameLb = CsbTools.getChildFromPath(csbNode, "PlayerName")
    if not lvImg or not yearImg or not nameLb then
        return
    end

    local isShowLv = true
    local isShowYear = false
    local lvImgWidth = lvImg:getContentSize().width * csbNode:getScaleX()
    local yearImgWidth = yearImg:getContentSize().width * csbNode:getScaleX()

    if gIsQQHall then
        local type = type or getGameModel():getUserModel():getBDType()
        local lv = lv or getGameModel():getUserModel():getBDLv()

        -- 蓝钻类型显示
        if type == BlueDiamondType.Normal then
            lvImg:setSpriteFrame("bluediamond_"..lv..".png")
        elseif type == BlueDiamondType.Year then
            lvImg:setSpriteFrame("bluediamond_"..lv..".png")
            yearImg:setSpriteFrame("year_vip.png")
            isShowYear = true
        elseif type == BlueDiamondType.Luxury then
            lvImg:setSpriteFrame("luxury_bluediamond_"..lv..".png")
        elseif type == BlueDiamondType.LuxuryYear then    
            lvImg:setSpriteFrame("luxury_bluediamond_"..lv..".png")
            yearImg:setSpriteFrame("year_vip.png")
            isShowYear = true
        else
            isShowLv = false
        end
    else
        isShowLv = false
    end

    if defaultLabel then
        if textParam then
            if textParam.text then
                defaultLabel:setString(textParam.text)
            end

            if textParam.color then
                defaultLabel:setTextColor(textParam.color)
            end
        end

        if not defaultLabel.originPosX then
            defaultLabel.originPosX = defaultLabel:getPositionX()
        end

        if isRight then
            local lbWidth = defaultLabel:getContentSize().width
            if isShowLv then
                if isShowYear then
                    csbNode:setPositionX(defaultLabel.originPosX - lbWidth - 8)
                else
                    csbNode:setPositionX(defaultLabel.originPosX - lbWidth + yearImgWidth - 8)
                end
            else
                csbNode:setVisible(false)
            end
        else
            if not isShowLv then
                defaultLabel:setPositionX(defaultLabel.originPosX)
            elseif isShowYear then
                defaultLabel:setPositionX(defaultLabel.originPosX + lvImgWidth + yearImgWidth)
            else
                defaultLabel:setPositionX(defaultLabel.originPosX + lvImgWidth)
            end
        end
    end

    nameLb:setVisible(false)
    lvImg:setVisible(isShowLv)
    yearImg:setVisible(isShowYear)
end

function CommonHelper.getIdentity(identity)
    return math.floor(identity%10), math.floor(identity/10)
end

-- 将颜色c3b十进制转为十六进制
local hashHex = {[10] = 'a', [11] = 'b', [12] = 'c', [13] = 'd', [14] = 'e', [15] = 'f'}
function CommonHelper.c3bToHex(r, g, b)
    local function toHex(n)
        local function toHexChar(c)
            return hashHex[c] or c
        end

        local a = math.floor(n / 16) % 16
        local b = math.floor(n % 16)

        return toHexChar(a)..toHexChar(b)
    end

    return toHex(r)..toHex(g)..toHex(b)
end

return CommonHelper