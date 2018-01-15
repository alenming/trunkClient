--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-06-07 18:31
** 版  本:	1.0
** 描  述:  爬塔试炼辅助类
** 应  用:
********************************************************************/
--]]

TowerTestHelper = {
    awardData = nil,
}

function TowerTestHelper:setAwardData(data)
    self.awardData = data
end

function TowerTestHelper:getAwardData()
    return self.awardData
end

function TowerTestHelper:resetAwardData()
    self.awardData = nil
end

return TowerTestHelper