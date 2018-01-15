----------------------使用到csb里面的一些基本方法--------------------
CsbTools = {}
local PopTip = require("game.comm.PopTip")
require("common.MusicManager")

--分割字符串
function CsbTools.split_str(str, delimiter)
	if str == nil or str == '' or delimiter == nil then
		return nil
	end
	local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
    return result
end

-- 递归获取节点
function CsbTools.getChildFromPath(node, path)
    local list = CsbTools.split_str(path, "/")
	local ret = node
	for k, v in pairs(list) do
		if not ret then 
			return nil
		end
		ret = ret:getChildByName(v)
	end
	return ret
end

local function pr (t, name, indent)   
    local tableList = {}   
    function table_r (t, name, indent, full)   
        local id = not full and name or type(name)~="number" and tostring(name) or '['..name..']'   
        local tag = indent .. id .. ' = '   
        local out = {}  -- result   
        if type(t) == "table" then   
            if tableList[t] ~= nil then   
                table.insert(out, tag .. '{} -- ' .. tableList[t] .. ' (self reference)')   
            else  
                tableList[t]= full and (full .. '.' .. id) or id  
                if next(t) then -- Table not empty   
                    table.insert(out, tag .. '{')   
                    for key,value in pairs(t) do   
                        table.insert(out,table_r(value,key,indent .. '|  ',tableList[t]))   
                    end   
                    table.insert(out,indent .. '}')   
                else table.insert(out,tag .. '{}') end   
            end   
        else  
            local val = type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"' or tostring(t)   
            table.insert(out, tag .. val)   
        end   
        return table.concat(out, '\n')   
    end   
    return table_r(t,name or 'Value',indent or '')   
end

function CsbTools.printValue(value, name)
    print(pr(value, name))
end

-- 计算字符串宽度 (英文占1个, 中文占2个)
function CsbTools.stringWidth(inputstr)
    local lenInByte = #inputstr     -- 占字节数
    local width = 0                 -- 统计长度
    local i = 1
    while (i <= lenInByte) do
        local curByte = string.byte(inputstr, i)
        local byteCount = 1
        if curByte>0 and curByte<=127 then
            byteCount = 1                           --1字节字符
        elseif curByte>=192 and curByte<=223 then
            byteCount = 2                           --双字节字符
        elseif curByte>=224 and curByte<=239 then
            byteCount = 3                           --汉字
        elseif curByte>=240 and curByte<=247 then
            byteCount = 4                           --4字节字符
        end
        i = i + byteCount
        width = width + math.ceil(byteCount/2)
    end
    return width
end

-- 替换图片
function CsbTools.replaceImg(imageNode, ImgName)
    if imageNode and ImgName then       
        if cc.SpriteFrameCache:getInstance():getSpriteFrame(ImgName) == nil then
            local info = debug.getinfo(2, "Sl")
            print(string.format("\"%s\" 图片不存在  [%s]:%d", ImgName, info.source, info.currentline))
            if device.platform == "android" or device.platform == "ios" or gIsQQHall then
                return
            end
        end 
        imageNode:loadTexture(ImgName, 1)
    end
end

function CsbTools.replaceSprite(spriteNode, ImgName)
    if spriteNode and ImgName then       
        if cc.SpriteFrameCache:getInstance():getSpriteFrame(ImgName) == nil then
            local info = debug.getinfo(2, "Sl")
            print(string.format("\"%s\" 图片不存在  [%s]:%d", ImgName, info.source, info.currentline))
            if device.platform == "android" or device.platform == "ios" or gIsQQHall then
                return
            end
        end 
        spriteNode:setSpriteFrame(ImgName)
    end
end

-- 建议使用 addTipsToRunningScene
function CsbTools.createDefaultTip(tipText)
    return PopTip.new({
            text = tipText or "nil", 
            font = "../fonts/msyh.ttf",
            animate = 1,
            x = display.cx,
            y = display.cy,
            size = 32, 
            color = cc.c3b(253, 243, 77),
            align = cc.ui.TEXT_ALIGN_CENTER,
            valign= cc.ui.TEXT_VALIGN_CENTER,
            dimensions = cc.size(display.cx, display.cy)
        })
end

-- 建议使用 addTipsToRunningScene
function CsbTools.createFloatTip(tipText, format)
    format = format or {}
    return PopTip.new({
            text = tipText or "nil", 
            font = format.font or "../fonts/msyh.ttf",
            animate = format.animate or 1,
            x = format.x or display.cx,
            y = format.y or display.cy,
            size = format.size or 32, 
            color = format.color or cc.c3b(253, 243, 77),
            align = format.align or cc.ui.TEXT_ALIGN_CENTER,
            valign= format.valign or cc.ui.TEXT_VALIGN_CENTER,
            dimensions = cc.size(x, y)
        })
end

-- 由于关闭界面的时候动画会暂停, 再次打开的时候导致文字还存在,
-- 添加到runningScene后动作不会暂停
function CsbTools.addTipsToRunningScene(tipText, format)
    format = format or {}
    local tips = PopTip.new({
        text = tipText or "nil", 
        font = format.font or "../fonts/msyh.ttf",
        animate = format.animate or 1,
        x = format.x or display.cx,
        y = format.y or display.cy,
        size = format.size or 32, 
        color = format.color or cc.c3b(253, 243, 77),
        align = format.align or cc.ui.TEXT_ALIGN_CENTER,
        valign= format.valign or cc.ui.TEXT_VALIGN_CENTER,
        dimensions = cc.size(display.width, display.height)
    })

    display.getRunningScene():addChild(tips, 1000)

    return tips
end

-- 填充按钮文字，传入按钮button、要设置的文字text、文字节点textNode、按钮下的节点csbNode
-- 实现按钮点击时，按钮下方的内容自动跟随按钮进行缩放的效果
-- textNode参数详解
-- textNode为空时默认查找按钮下的Text节点作为文字节点，找不到则不处理
-- textNode为字符串时默认查找按下指定名字的节点作为文字节点
-- 其他情况需要将按钮的文字节点作为textNode参数传入
-- csbNode参数详解
-- csbNode为空时默认使用按钮下的Text节点作为缩放节点
-- csbNode为字符串时默认查找按下指定名字的节点作为文字节点
-- 其他情况需要将按钮的文字节点作为textNode参数传入
function CsbTools.fillButtonText(button, text, textNode, csbNode)
    if not textNode then
        textNode = button:getChildByName("Text")
    elseif type(textNode) == "string" then
        textNode = CsbTools.getChildFromPath(button, textNode)
    end

    if textNode and type(text) == "string" then
        textNode:setString(text)
    end

    if csbNode == nil and textNode then
        csbNode = textNode
    elseif type(csbNode) == "string" then
        csbNode = CsbTools.getChildFromPath(button, csbNode)
    end

    if not csbNode then
        return
    end

    -- textNode可以传入节点、空、字符串
    local callback = function ()
        local normalNode = button:getRendererNormal()
        csbNode:setScaleX(normalNode:getScaleX())
        csbNode:setScaleY(normalNode:getScaleY())
    end
    csbNode:scheduleUpdateWithPriorityLua(callback, 0) 
end

-- 初始化按钮，传入按钮、点击回调、要设置的文字text、文字节点textNode、按钮下的节点csbNode
-- 除按钮点击回调外，其他参数同fillButtonText方法
function CsbTools.initButton(button, callback, text, textNode, csbNode)
    button:setTouchEnabled(true)
    button:setTouchSwallowEnabled(true)
    button:addClickEventListener(function (obj)
    --button:addTouchEventListener(function(obj, state)
        --if state == 0 then
            if callback then
                callback(obj)
            end

            if obj.soundId then
                MusicManager.playSoundEffect(obj.soundId)
            else
                MusicManager.playSoundEffect(obj:getName())
            end
        --end
    end)
    CsbTools.fillButtonText(button, text, textNode, csbNode)
end
