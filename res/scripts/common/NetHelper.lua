--[[
	NetHelper主要用于处理网络请求、网络响应、网络异常，下面简单介绍如何使用。
	1.如何发起请求
		调用NetHelper.createBufferData方法，传入主命令+子命令（参考协议）。
		该方法会返回一个BufferData对象，调用该对象的writeInt、writeString等方法写入数据（API参考LuaBufferData.cpp）
		填充好要发送的内容后，调用NetHelper.request方法，传入BufferData对象（框架自动计算包长字段）
	2.如何监听服务器返回的响应
		首先添加一个回调到NetHelper中，示例如下：
			注册一个大厅购买的响应回调
			local cmd = NetHelper.makeCommand(CMD_HALL, CMD_HALL_BUY_COIN_SC)
			NetHelper.setResponeHandler(cmd, onHallBuyCoinSC)
		C++层网络框架在接收到服务端消息时会回调NetHelper.onResponse方法，并传入BufferData对象
		在回调方法中处理客户端的响应逻辑
		当不需要该回调时，应调用NetHelper.removeResponeHandler将该回调移除
		
	3.关于单机调试，可以在request方法中，添加临时代码，填充服务端返回的结果对象，直接调用onResponse
	4.关于网络异常等的处理，待定...
	
	2015-8-27 by 宝爷
]]


NetHelper = NetHelper or {}
NetHelper.callbacks = {}

-- 根据协议命令设置回调
-- 回调函数参数列表 —— 主命令、子命令、BufferData对象
-- BufferData对象已经偏移到包头后的数据部分
function NetHelper.setResponeHandler(cmd, callback)
	NetHelper.callbacks[cmd] = { [callback] = true }
end

-- 根据协议命令添加回调
-- 回调函数参数列表 —— 主命令、子命令、BufferData对象
-- BufferData对象已经偏移到包头后的数据部分
function NetHelper.addResponeHandler(cmd, callback)
	if NetHelper.callbacks[cmd] == nil then
		-- 初始化table
		NetHelper.callbacks[cmd] = { [callback] = true }
	else
		NetHelper.callbacks[cmd][callback] = true
	end
end

-- 移除回调，可以只传cmd参数
function NetHelper.removeResponeHandler(cmd, callback)
    print("removeResponeHandler:" .. cmd)
	if callback and NetHelper.callbacks[cmd] ~= nil then
		NetHelper.callbacks[cmd][callback] = nil
	else
		NetHelper.callbacks[cmd] = nil
	end
end

-- 服务端响应时回调该方法
function NetHelper.onResponse(bufferData)
	local head = NetHelper.getHead(bufferData)
    if nil == head then
        return
    end

	local cmd = head.cmd
    print("receive network cmd" .. cmd)
	local funs = NetHelper.callbacks[cmd]
	if funs ~= nil then
		for fun,_ in pairs(funs) do
			print("NetHelper.onResponse, cmd, func, bufferData", head.maincmd, head.subcmd, bufferData)
			fun(head.maincmd, head.subcmd, bufferData)
            head = NetHelper.getHead(bufferData)
            if nil == head then
                break
            end
		end
	end
end

--根据bufferData返回包头对象（一个Table）
function NetHelper.getHead(bufferData)
	--先重置到包头位置再读取包头
	bufferData:resetOffset()
	local ret = {}
	ret.length = bufferData:readInt()
	ret.cmd = bufferData:readInt()
	ret.id = bufferData:readInt()
    if "number" ~= type(ret.cmd) then
        print("data type is error!!!")
        return nil
    end

	--调用C提供的获取主命令和子命令接口
	ret.maincmd = getMainCmd(ret.cmd)
	ret.subcmd = getSubCmd(ret.cmd)
	return ret
end

-- 根据主命令和子命令合成一个命令
function NetHelper.makeCommand(mainCmd, subCmd)
	-- makeCommand是C++封装的全局函数
	return makeCommand(mainCmd, subCmd)
end

-- 根据主命令和子命令创建一个已经包含包头的Buf对象
function NetHelper.createBufferData(mainCmd, subCmd)
	-- newBufferData是C++封装的全局函数
	bufferData = newBufferData()
	-- length字段 由C++部分最后直接获取buf的长度进行修改
	bufferData:writeInt(0)
	-- cmd字段
	bufferData:writeInt(makeCommand(mainCmd, subCmd))
	-- id字段 对客户端而言此字段无用
	bufferData:writeInt(0)
	return bufferData
end

-- 传入BufferData对象进行释放，在每次request之后都会自动释放
-- 当创建了BufferData对象而又没有request时，需要调用该方法进行释放，以避免内存泄露
function NetHelper.deleteBufferData(bufferData)
	-- newBufferData是C++封装的全局函数
	deleteBufferData(bufferData)
end

-- 直接发起网络请求,connType为请求的服务器类型0session,1chat
function NetHelper.request(bufferData, connType)
	-- request是C++封装的全局函数
    if connType then
        request(bufferData, connType)
    else
        request(bufferData)
    end
	
	-- deleteBufferData是C++封装的全局函数
	deleteBufferData(bufferData)
end

-- 发起网络请求，等待指定响应，屏蔽点击
-- 提示网络等待【设置网络等待提示延迟时间】
-- 网络超时，提示网络错误
function NetHelper.requestWithTimeOut(bufferData, s2cCmd, callback, tipsTime, timeOut)
    tipsTime = tipsTime or 1.0
    timeOut = timeOut or 10.0

    local responeCallback = function (mainCmd, subCmd, data)
        if callback then
            callback(mainCmd, subCmd, data)
        end

        NetworkTips.closeTips()
    end

    -- 网络回应监听(注意添加的是匿名函数)
    NetHelper.addResponeHandler(s2cCmd, responeCallback)
    
    request(bufferData)
    NetworkTips.createTips(tipsTime, timeOut, bufferData, s2cCmd, responeCallback)
end

function NetHelper.setErrorHandler(callback)
	-- 设置网络异常的回调
end

return NetHelper