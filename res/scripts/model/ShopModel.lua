local ShopModel = class("ShopModel")

function ShopModel:ctor()
	self.mShopCount = 0
	self.mShops = {}
	self.mDiamondShop = {}
    self.mUnionShopState = 0        -- 0-普通状态, 1-正在上架状态
    self.mUnionGoodsCount = 0
    self.mUnionShop = {}
end

function ShopModel:init(buffData)
	self.mShopCount = buffData:readChar()					-- 商店个数
	self.mShops = {}
	for i = 1, self.mShopCount do
		local times = buffData:readInt()					-- 已经刷新的次数
		local nextFreshTime = buffData:readInt() 			-- 下次刷新时间点
		local shopID = buffData:readChar()					-- 商店类型
		local curItemCount = buffData:readChar()			-- 当前物品数

		local goodsList = {}
		for i = 1, curItemCount do
			local goodsId = buffData:readInt()				-- 道具ID
			local goodsNum = buffData:readInt()				-- 道具个数
			local coinNum = buffData:readInt()				-- 价格
			local goodsShopId = buffData:readShort()		-- 商品ID
			local coinType = buffData:readChar()			-- 货币类型
			local index = buffData:readChar()				-- 商品索引
			local sale = buffData:readChar()					-- 折扣值

			table.insert(goodsList, {
				nIndex = index,
				nGoodsShopID = goodsShopId,
				nGoodsID = goodsId,
				nGoodsNum = goodsNum,
				nCoinType = coinType,
				nCoinNum = coinNum,
				nSale = sale,
			})
		end

		self.mShops[shopID] = {
			nShopType = shopID,
			--nCount = itemCount,
			nCurCount = curItemCount,
			nFreshedCount = times,
			nNextFreshTime = nextFreshTime,
			GoodsData = goodsList
		}
	end

	----------------- 钻石商店 -----------------
	local num = buffData:readChar()							-- 已经充值的个数
	self.mDiamondShop = {}
	for i = 1, num do
		local timeStamp = buffData:readInt()				-- 时间戳
		local index = buffData:readChar()					-- 商品索引
		self.mDiamondShop[index] = timeStamp
	end

	return true
end

function ShopModel:initUnionShop(buffData)
	self.mUnionGoodsCount = buffData:readShort()
    self.mUnionShopState = buffData:readChar()
 
    self.mUnionShop = {}
    for i = 1, self.mUnionGoodsCount do
    	local goodsId = buffData:readInt()              -- 道具ID
    	local coinNum = buffData:readInt()              -- 价格
    	local goodsShopId = buffData:readShort()        -- 商品ID
        local goodsNum = buffData:readChar()            -- 道具个数
        local coinType = buffData:readChar()            -- 货币类型
        local sale = buffData:readChar()                -- 折扣值

        table.insert(self.mUnionShop, {
            nGoodsShopID = goodsShopId,
            nGoodsID = goodsId,
            nGoodsNum = goodsNum,
            nCoinType = coinType,
            nCoinNum = coinNum,
            nSale = sale,
        })
    end
end

function ShopModel:getUnionShopData()
    return self.mUnionShop
end
function ShopModel:setUnionShopData(data)
    self.mUnionShop = data
end
function ShopModel:clearUnionShopData()
    self.mUnionShopState = 0
    self.mUnionGoodsCount = 0
    self.mUnionShop = {}
end

function ShopModel:getUnionSHopGoodsData(id)
    for i, v in pairs(self.mUnionShop or {}) do
        if v.nGoodsShopID == id then
            return v
        end
    end
end
function ShopModel:setUnionShopGoodsData(id, num)
    for i, v in pairs(self.mUnionShop or {}) do
        if v.nGoodsShopID == id then
            self.mUnionShop[i].nGoodsNum = self.mUnionShop[i].nGoodsNum - num
        end
    end
end


function ShopModel:getUnionShopState()
    return self.mUnionShopState
end
function ShopModel:setUnionShopState(state)
    self.mUnionShopState = state or 0
end

function ShopModel:getUnionGoodsCount()
    return self.mUnionGoodsCount
end
function ShopModel:setUnionGoodsCount(count)
    self.mUnionGoodsCount = count
end

function ShopModel:getShopCount()
	return self.mShopCount
end

function ShopModel:getShopModelData(shopType)
	return self.mShops[shopType]
end

function ShopModel:setShopModelData(data)
	self.mShops[data.nShopType] = data
end

function ShopModel:isFirstCharge(index)
	if self.mDiamondShop[index] then
		return not (self.mDiamondShop[index] > 0)
	end
	return true
end

function ShopModel:setFirstChargeState(index)
	self.mDiamondShop[index] = getGameModel():getNow()
end

return ShopModel