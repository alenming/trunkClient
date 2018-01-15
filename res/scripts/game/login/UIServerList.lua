--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-14 15:17
** 版  本:	1.0
** 描  述:  服务器选择界面
** 应  用:
********************************************************************/
--]]
require ("game.login.ServerConfig")

local UIServerList = class("UIServerList", function()
    return require("common.UIView").new()
end)

function UIServerList:ctor()
    self.rootPath = ResConfig.UIServerList.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    local touchPanel = getChild(self.root, "MainPanel")
    touchPanel:addClickEventListener(handler(self, self.onClick))
    
    self.itemTable = {}
    for i=1, 12 do
        local item  = getChild(self.root, "MainPanel/OnlineItem_" .. i)
        item:setVisible(false)
        self.itemTable[i] = item
    end

    for i, v in pairs(ServerConfig) do
        if i > 12 then return end

        local item = self.itemTable[i]
        item:setVisible(true)
        --
        local touchPanel    = getChild(item, "OnlinePanel")
        touchPanel:setTag(i)
        touchPanel:addClickEventListener(handler(self, self.onClick))
        --
        local zoneId        = getChild(item, "OnlinePanel/Text_1")    -- 区id
        local serverName    = getChild(item, "OnlinePanel/Text_2")    -- 名称
        local serverState   = getChild(item, "OnlinePanel/Text_3")    -- 状态
        zoneId:setString(v.Id)
        serverName:setString(v.Name)
        serverState:setString(v.Status)
    end
end

-- 当界面被创建时回调
-- 只初始化一次
function UIServerList:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIServerList:onOpen(openerUIID, callback)
    self.callback = callback
end

-- 每次界面Open动画播放完毕时回调
function UIServerList:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIServerList:onClose()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIServerList:onTop(preUIID, ...)

end

function UIServerList:onClick(obj)
    local objName = obj:getName()
    if objName == "MainPanel" then
        UIManager.close()
    else
        gServerID = obj:getTag()
        if self.callback then
            self.callback()
        end
        UIManager.close()
    end
end

return UIServerList