--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-04-13 19:59
** 版  本:	1.0
** 描  述:  背包解锁提示界面
** 应  用:
********************************************************************/
--]]

local UIBagUnlock = class("UIBagUnlock", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIBagUnlock:ctor()
    self.rootPath = ResConfig.UIBagUnlock.Csb2.main
    self.root = getResManager():cloneCsbNode(self.rootPath)
    self:addChild(self.root)

    local titleLab 	= getChild(self.root, "BagUnlock/BitmapFontLabel_1")
    local tipLab 	= getChild(self.root, "BagUnlock/TipsText")
    titleLab:setString(CommonHelper.getUIString(68))
    tipLab:setString(CommonHelper.getUIString(74))

    local BuyButton = getChild(self.root, "BagUnlock/BuyButton/BuyButton")
    CsbTools.initButton(BuyButton, handler(self, self.onClick), nil, nil, "Node")
    self.priceLabel = getChild(BuyButton, "Node/ButtonName")
end

-- 当界面被创建时回调
-- 只初始化一次
function UIBagUnlock:init(...)
	--self.root
	--self.rootPath
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIBagUnlock:onOpen(openerUIID, price, callback)
    self.price = price
    self.callback = callback

    self.priceLabel:setString(price)
    self:setPriceLbColor()
end

-- 每次界面Open动画播放完毕时回调
function UIBagUnlock:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIBagUnlock:onClose()
    if self.unlockHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.UnlockSC)
        NetHelper.removeResponeHandler(cmd, self.unlockHandler)
        self.unlockHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIBagUnlock:onTop(preUIID, ...)
    self:setPriceLbColor()
end

-- 当前界面按钮点击回调
function UIBagUnlock:onClick(obj)
    local btnName = obj:getName()
    obj.soundId = nil
    if btnName == "BuyButton" then
        CommonHelper.checkConsumeCallback(2, self.price, function ()
            self:sendUnlockCmd()
        end)
    end
end

-- 发送解锁请求
function UIBagUnlock:sendUnlockCmd()

    -- 注册解锁命令
    local cmd = NetHelper.makeCommand(MainProtocol.Bag, BagProtocol.UnlockSC)
    self.unlockHandler = handler(self, self.acceptUnlockCmd)
    NetHelper.setResponeHandler(cmd, self.unlockHandler)

    local buffData = NetHelper.createBufferData(MainProtocol.Bag, BagProtocol.UnlockCS)
    buffData:writeInt(1)  --解锁行数
    NetHelper.request(buffData)
end

-- 接收解锁请求
function UIBagUnlock:acceptUnlockCmd(mainCmd, subCmd, buffData)
   
    -- 注销解锁命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.unlockHandler)
    self.unlockHandler = nil

    local diamond = buffData:readInt()   -- 消耗钻石
    local bagLine = buffData:readInt()   -- 解锁行数
    if self.callback and type(self.callback) == "function" then
        self.callback(bagLine)
    end
    -- 设置钻石信息
    ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -diamond)

    UIManager.close()
end

function UIBagUnlock:setPriceLbColor()
    if self.price > getGameModel():getUserModel():getDiamond() then
        self.priceLabel:setColor(cc.c3b(255, 0, 0))
    else
        self.priceLabel:setColor(cc.c3b(255, 255, 255))
    end
end

return UIBagUnlock