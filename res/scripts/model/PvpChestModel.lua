require"model.ModelConst"

-- pvp宝箱模型
local PvpChestModel = class("PvpChestModel")

function PvpChestModel:ctor()
end

function PvpChestModel:init(buffData)
	local count = buffData:readChar()
	self.mChests = {}
	for i = 1, count do
        local chestId = buffData:readInt()
		table.insert(self.mChests, chestId)
	end
end

-- 获取宝箱列表
function PvpChestModel:getChests()
	return self.mChests
end

function PvpChestModel:hasChest()
	return #self.mChests > 0
end

-- 添加宝箱
function PvpChestModel:addChest(id)
	table.insert(self.mChests, id)
end

-- 删除宝箱
function PvpChestModel:popChest(id)
    if #self.mChests <= 0 or self.mChests[1] ~= id then
        print("remove chest fail!!!")
        return false
    end
    
    table.remove(self.mChests, 1)
    return true
end

return PvpChestModel