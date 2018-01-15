--[[
存放Java需要调用的一些全局函数
]]

-- QQ游戏大厅登录成功
function javaQghLoginSuccess(args)
	args = string.split(args, "|")

	EventManager:raiseEvent(GameEvents.EventSDKLoginSucess, {
		pfType = 1,
		openId = args[1],
		token = args[2],
	})
end

-- QQ游戏大厅登录失败
function javaQghLoginFail()
	EventManager:raiseEvent(GameEvents.EventSDKLoginFail)
end