--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-03-23 18:31
** 版  本:	1.0
** 描  述:  商店刷新提示界面
** 应  用:
********************************************************************/
--]]

local userModel = getGameModel():getUserModel()
local shopModel = getGameModel():getShopModel()

local UIShopRefresh = class("UIShopRefresh", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIShopRefresh:ctor()
    self.rootPath = ResConfig.UIShopRefresh.Csb2.main
    self.root = getResManager():getCsbNode(self.rootPath)
    self:addChild(self.root)

    -- 语言包
    local title         = getChild(self.root, "MainPanel/SaleFontLabel")
    local tipsText      = getChild(self.root, "MainPanel/TipsText")
    local confrimText   = getChild(self.root, "MainPanel/ConfrimButton/NameText")
    local cancelText    = getChild(self.root, "MainPanel/CancelButton/NameText")
    title:setString(CommonHelper.getUIString(605))
    tipsText:setString(CommonHelper.getUIString(110))
    confrimText:setString(CommonHelper.getUIString(971))
    cancelText:setString(CommonHelper.getUIString(501))

    local btnClose = getChild(self.root, "MainPanel/Button_Close")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    local btnCancel = getChild(self.root, "MainPanel/CancelButton")
    CsbTools.initButton(btnCancel, handler(self, self.onClick), nil, nil, "NameText")

    self.btnConfrim = getChild(self.root, "MainPanel/ConfrimButton")
    CsbTools.initButton(self.btnConfrim, handler(self, self.onClick), nil, nil, "NameText")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIShopRefresh:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIShopRefresh:onOpen(openerUIID, shopId, callback)
    self.shopId     = shopId
    self.callback   = callback
    self.btnConfrim:setTouchEnabled(true)

    self:initNetwork()
    -- 设置刷新消耗
    self:setCostLabel()
    -- 设置刷新次数
    self:setFreshedCount()
end

-- 每次界面Open动画播放完毕时回调
function UIShopRefresh:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIShopRefresh:onClose()
    self:removeNetwork()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIShopRefresh:onTop(preUIID, ...)

end

-- 当前界面按钮点击回调
function UIShopRefresh:onClick(obj)
    local btnName = obj:getName()
    obj.soundId = nil
    if btnName == "Button_Close" then
        UIManager.close()
    elseif btnName == "CancelButton" then
        UIManager.close()
    elseif btnName == "ConfrimButton" then
        local shopModelData = shopModel:getShopModelData(self.shopId)
        if shopModelData then
            local nFreshedCount = shopModelData.nFreshedCount
            local conf = getIncreasePayConfItem(nFreshedCount + 1)
            if nil == conf then
                return
            end
            if getGameModel():getUserModel():getDiamond() < conf.FreshShopCost then
                obj.soundId = MusicManager.commonSound.fail
                -- 进入充值提示界面
                CsbTools.addTipsToRunningScene(CommonHelper.getUIString(530))
            else
                self:sendRefreshCmd()
            end
        end
    end
end


---------------------------------------------------------------------
-- 初始化网络回调
function UIShopRefresh:initNetwork()
    -- 注册自动刷新的网络回调
    local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopRefreshSC)
    self.refreshHandler = handler(self, self.acceptRefreshCmd)
    NetHelper.setResponeHandler(cmd, self.refreshHandler)
end

-- 移除网络回调
function UIShopRefresh:removeNetwork()
    -- 移除自动刷新的网络回调
    if self.refreshHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Shop, ShopProtocol.ShopRefreshSC)
        NetHelper.removeResponeHandler(cmd, self.refreshHandler)
        self.refreshHandler = nil
    end
end


-- 设置刷新消耗
function UIShopRefresh:setCostLabel()
    local countLabel = getChild(self.root, "MainPanel/CountLabel")

    local shopModelData = shopModel:getShopModelData(self.shopId)
    if shopModelData then
        local nFreshedCount = shopModelData.nFreshedCount
        local conf = getIncreasePayConfItem(nFreshedCount + 1)
        if conf then
            countLabel:setString(tostring(conf.FreshShopCost))
        end
    end
end

-- 设置刷新次数
function UIShopRefresh:setFreshedCount()
    local timeTips = getChild(self.root, "MainPanel/TimeTips")
    local shopModelData = shopModel:getShopModelData(self.shopId)
    if shopModelData then
        local nFreshedCount = shopModelData.nFreshedCount
        timeTips:setString(string.format(CommonHelper.getUIString(1126), nFreshedCount))
    end
end

-- 发送刷新请求
function UIShopRefresh:sendRefreshCmd()
    self.btnConfrim:setTouchEnabled(false)

    local buffData = NetHelper.createBufferData(MainProtocol.Shop, ShopProtocol.ShopRefreshCS)
    buffData:writeChar(self.shopId)     -- 商店类型
    buffData:writeChar(1)               -- 刷新类型, 自动：0， 手动：1
    NetHelper.request(buffData)
end

-- 接收刷新请求
function UIShopRefresh:acceptRefreshCmd(mainCmd, subCmd, buffData)
    if self.callback and type(self.callback) == "function" then
        self.callback(mainCmd, subCmd, buffData)
    end

    UIManager.close()
end

return UIShopRefresh