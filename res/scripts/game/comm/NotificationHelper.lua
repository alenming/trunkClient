--[[
	切换场景后不会关闭此节点
]]

NotificationHelper = {}

-- 取出notificationNode 如果不存在则创建一个
NotificationHelper.node = cc.Director:getInstance():getNotificationNode()

if not NotificationHelper.node then
	NotificationHelper.node = cc.Node:create()
	cc.Director:getInstance():setNotificationNode(NotificationHelper.node)
end

function NotificationHelper.addNode(node, zOrder)
	NotificationHelper.node:addChild(node, zOrder)
end

function NotificationHelper.removeNode(node, clean)
	NotificationHelper.node:removeChild(node, clean)
end

function NotificationHelper.hasNode(node)
	if node == nil then
		return false
	end

	local children = NotificationHelper.node:getChildren()
	for _, v in ipairs(children) do
		if node == v then
			return true
		end
	end
	return false
end



