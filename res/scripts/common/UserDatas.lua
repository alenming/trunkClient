--[[
    本地数据存储
]]

UserDatas = {}

local UserDefault = cc.UserDefault:getInstance()

function UserDatas.init()
    local serverId = UserDefault:getIntegerForKey("ServerId", 1)
    UserDatas.userKey = "_"..serverId.."_"..getGameModel():getUserModel():getUserID()
end

function UserDatas.setStringForKey(key, value)
    UserDefault:setStringForKey(key..UserDatas.userKey, value)
end

function UserDatas.getStringForKey(key, value)
    return UserDefault:getStringForKey(key..UserDatas.userKey, value or "")
end

function UserDatas.setBoolForKey(key, value)
    UserDefault:setBoolForKey(key..UserDatas.userKey, value)
end

function UserDatas.getBoolForKey(key, value)
    return UserDefault:getBoolForKey(key..UserDatas.userKey, value or false)
end

function UserDatas.setIntegerForKey(key, value)
    UserDefault:setIntegerForKey(key..UserDatas.userKey, value)
end

function UserDatas.getIntegerForKey(key, value)
    return UserDefault:getIntegerForKey(key..UserDatas.userKey, value or 0)
end

function UserDatas.deleteValueForKey(key)
    UserDefault:deleteValueForKey(key..UserDatas.userKey)
end

return UserDatas