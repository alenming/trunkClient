--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-08-12 11:09
** 版  本:	1.0
** 描  述:  礼包兑换界面
** 应  用:
********************************************************************/
--]]
local SdkManager = require("common.sdkmanager.SdkManager")

local UIPackageRedeem = class("UIPackageRedeem", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UIPackageRedeem:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UIPackageRedeem:init(...)
    self.rootPath = ResConfig.UIPackageRedeem.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- UI文本
    CsbTools.getChildFromPath(self.root, "MainPanel/BarText"):setString(CommonHelper.getUIString(260))
    CsbTools.getChildFromPath(self.root, "MainPanel/TipsText"):setString(CommonHelper.getUIString(261))
    -- 按钮文本
    CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton/ButtonName"):setString(CommonHelper.getUIString(500))
    CsbTools.getChildFromPath(self.root, "MainPanel/CancelButton/ButtonName"):setString(CommonHelper.getUIString(501))

    -- 关闭
    local touchPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    CsbTools.initButton(touchPanel, handler(self, self.onClick))

    -- 关闭按钮
    local btnCancel = CsbTools.getChildFromPath(self.root, "MainPanel/CancelButton")
    CsbTools.initButton(btnCancel, handler(self, self.onClick), nil, nil, "ButtonName")

    -- 确认按钮
    local btnConfirm = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
    CsbTools.initButton(btnConfirm, handler(self, self.onClick), nil, nil, "ButtonName")

    -- 文本输入
    self.inputField = CsbTools.getChildFromPath(self.root, "MainPanel/CodeInputField")
    self.inputField:setMaxLengthEnabled(true)
    self.inputField:setMaxLength(19)
    self.inputField:setTextAreaSize(cc.size(320, 30))
    self.inputField:setTouchSize(cc.size(320, 30))
    self.inputField:addEventListener(handler(self, self.onInput))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UIPackageRedeem:onOpen(openerUIID, ...)
    self.inputField:setString("")
    self.textCount = 0
    self:initNetwork()
end

-- 每次界面Open动画播放完毕时回调
function UIPackageRedeem:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UIPackageRedeem:onClose()
    self:removeNetwork()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UIPackageRedeem:onTop(preUIID, ...)

end

function UIPackageRedeem:onClick(obj)
    local name = obj:getName()
    if "MainPanel" == name then
        UIManager.close()
    elseif "CancelButton" == name then
        UIManager.close()
    elseif "ConfrimButton" == name then
        local code = ""
        for s in string.gmatch(self.inputField:getString(), '%x+') do
            code = code .. s
        end
        if --[[gIsQQHall and]] code == "26995164" then      -- 用户设置密码的兑换码
            UIManager.replace(UIManager.UI.UIInputPassword)
        else
            self:sendRedeemCmd()
        end
    end
end

function UIPackageRedeem:onInput(obj, event)
    if 2 == event then
        local inputString = obj:getString()
        print("UIPackageRedeem:onInput 2 == event inputString", inputString)
        print("\n")
        -- 16进制限制
        if string.find(obj:getString(), "[^%x%-]") then
            CsbTools.addTipsToRunningScene(CommonHelper.getUIString(262))
            local str = string.sub(obj:getString(), 1, self.textCount)
            self.inputField:setString(str)
        else
            local md5 = ""
            for s in string.gmatch(obj:getString(), '%x+') do
                md5 = md5 .. s
            end
            local text = ""
            for i = 1, string.len(md5) do
                text = text .. string.sub(md5, i, i)
                if 4 == i or 8 == i or 12 == i then
                    text = text .. "-"
                end
            end
            obj:setString(text)
        end
    elseif 3 == event then
        local inputString = obj:getString()
        print("UIPackageRedeem:onInput 3 == event inputString", inputString)
        print("\n")
        if 0 == (string.len(obj:getString()) + 1) % 5 then
            local idx = string.len(obj:getString())
            local str = string.sub(obj:getString(), 1, idx)
            local inputString = obj:getString()
            print("UIPackageRedeem:onInput 3 == event inputString", inputString)
            print("\n")
            self.inputField:setString(str)
        end
    end
    local inputString = obj:getString()
    print("UIPackageRedeem:onInput 4 == event inputString", inputString)
    print("-----------------------------------------------------------")
    print("\n")
    self.textCount = string.len(obj:getString())
end

-- 初始化网络回调
function UIPackageRedeem:initNetwork()
    -- 注册礼包兑换命令
    local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.GiftSC)
    self.redeemHandler = handler(self, self.acceptRedeemCmd)
    NetHelper.setResponeHandler(cmd, self.redeemHandler)
end

-- 移除网络回调
function UIPackageRedeem:removeNetwork()
    if self.redeemHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.GiftSC)
        NetHelper.removeResponeHandler(cmd, self.redeemHandler)
        self.redeemHandler = nil
    end
end

-- 发送礼包兑换请求
function UIPackageRedeem:sendRedeemCmd()
    -- 礼包码
    local md5 = ""
    for s in string.gmatch(self.inputField:getString(), '%x+') do
        md5 = md5 .. s
    end
print("UIPackageRedeem:sendRedeemCmd md5", md5)
    if string.len(md5) < 16 then
        CsbTools.addTipsToRunningScene(CommonHelper.getErrorCodeString(900))
        return
    end

    -- 平台类型
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
print("UIPackageRedeem:sendRedeemCmd targetPlatform", targetPlatform)
    -- 渠道id
    local channelId = SdkManager.getChannelId() or 0
print("UIPackageRedeem:sendRedeemCmd channelId", channelId)

    local buffData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.GiftCS)
    buffData:writeChar(targetPlatform)
    buffData:writeInt(channelId)
    buffData:writeString(md5)
    NetHelper.request(buffData)
end

-- 接收礼包兑换请求
function UIPackageRedeem:acceptRedeemCmd(mainCmd, subCmd, buffData)
    local num = buffData:readInt()
    -- 显示奖励
    local awardData = {}
    local dropInfo = {}
    for i = 1, num do
        dropInfo.id = buffData:readInt()
        dropInfo.num = buffData:readInt()
        UIAwardHelper.formatAwardData(awardData, "dropInfo", dropInfo)
    end

    UIManager.replace(UIManager.UI.UIAward, awardData)
end

return UIPackageRedeem