--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--打印行
local io_file = nil

local function print_line(node, name)
	local childs = node:getChildren()
	for k,v in pairs(childs) do
		local temp = name .. "/" .. v:getName()
		io_file:write(temp)
		io_file:write("\n")
		print_line(v, temp)
	end
end

--输出文件结构目录
function check_file(csb, path)
	io_file = assert(io.open(path, 'w'))
	print_line(csb, "csb")
	io_file:close()
end

--分割字符串
function split_str(str, delimiter)
	if str == nil or str == '' or delimiter == nil then
		return nil
	end
	local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
    return result
end

--递归获取节点
function getChild(node, path)
	local list = split_str(path, "/")
	local ret = node
	for k, v in pairs(list) do
		if not ret then 
			return nil
		end
		ret = ret:getChildByName(v)
	end
	return ret
end

function printTable(tb)
    if not tb then
        return
    end
    for k,v in pairs(tb) do
        if type(v) == "table" then
            printTable(v)
        else
            print(k,v)
        end
    end
end

--复制Table
function copyTable(tb)  
    if type(tb) ~= "table" then  
        return nil  
    end  
    local bak = {}  
    for k,v in pairs(tb) do  
        local v_type = type(v)  
        if (v_type == "table") then  
            bak[k] = copyTable(v)   
        else  
            bak[k] = v  
        end  
    end  
    return bak  
end 

--播放动画
function action_animation(obj, path, state, loop)
    action = cc.CSLoader:createTimeline(path)
    --obj:stopAllActions()    --开启这一行，频繁调用会效率很低
    obj:runAction(action)
    action:play(state, loop ~= nil and loop or false)
end

--获取等级
function getLevel(lv)
    -- local setting = getGameSettingConfItem(1)
    -- local ret
    -- if lv == 1 then
    --     ret = setting.White_bg
    -- elseif lv == 2 then
    --     ret = setting.Green_bg
    -- elseif lv == 3 then
    --     ret = setting.Blue_bg
    -- elseif lv == 4 then
    --     ret = setting.Purple_bg
    -- elseif lv == 5 then
    --     ret = setting.Gold_bg
    -- elseif lv == 6 then
    --     ret = setting.Orange_bg
    -- elseif lv == 7 then
    --     ret = setting.Platinum_bg
    -- end
    return ""
end

--endregion
