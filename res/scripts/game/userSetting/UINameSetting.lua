--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-08-09 10:03
** 版  本:	1.0
** 描  述:  名称修改界面
** 应  用:
********************************************************************/
--]]
local userModel = getGameModel():getUserModel()

local FloatText = {UnDevelop = 11, RepeatName = 51, NoEnoughDiamond = 5, OpenUnion = 301, UnNil = 432, UnLegal = 8}
local ChangeNameDiamond = 10 -- 10钻石

local UINameSetting = class("UINameSetting", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UINameSetting:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UINameSetting:init(...)
    self.rootPath = ResConfig.UINameSetting.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- UI文本
    CsbTools.getChildFromPath(self.root, "MainPanel/TipsText"):setString(CommonHelper.getUIString(1669))
    CsbTools.getChildFromPath(self.root, "MainPanel/TipsText_2"):setString(string.format(CommonHelper.getUIString(1670), ChangeNameDiamond))
    -- 按钮文本
    CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton/Node/PriceNum"):setString(ChangeNameDiamond)

    -- 关闭按钮
    local touchPanel = CsbTools.getChildFromPath(self.root, "MainPanel")
    CsbTools.initButton(touchPanel, handler(self, self.onClick))

    -- 确认按钮
    local btnConfirm = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton")
    CsbTools.initButton(btnConfirm, handler(self, self.onClick),nil,nil,"Node")

    -- 文本输入
    self.inputField = CsbTools.getChildFromPath(self.root, "MainPanel/InputField")
    self.inputField:addEventListener(handler(self, self.onInput))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UINameSetting:onOpen(openerUIID, callback)
    self.callback = callback
    self.inputField:setString(userModel:getUserName())
end

-- 每次界面Open动画播放完毕时回调
function UINameSetting:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UINameSetting:onClose()
    self.inputField:didNotSelectSelf()
    if self.renameHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.RenameSC)
        NetHelper.removeResponeHandler(cmd, self.renameHandler)
        self.renameHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UINameSetting:onTop(preUIID, ...)

end

function UINameSetting:onClick(obj)
    local name = obj:getName()
    if "MainPanel" == name then
        UIManager.close()
    elseif "ConfrimButton" == name then
        obj.soundId = nil
        if not self:sendRenameCmd() then
            obj.soundId = MusicManager.commonSound.fail
        end
    end
end

function UINameSetting:onInput(obj, event)
    if 2 == event then
        -- 敏感词屏蔽
        local newStr = FilterSensitive.FilterStr(obj:getString())
        -- 长度限制(6个汉字12个字符)
        newStr = CommonHelper.limitStrLen(newStr, 6)
        obj:setString(newStr)
    end
end

-- 发送改名请求
function UINameSetting:sendRenameCmd()
	-- 注册改名命令
	local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.RenameSC)
    self.renameHandler = handler(self, self.acceptRenameCmd)
	NetHelper.setResponeHandler(cmd, self.renameHandler)

    -- 改名字输入框
    local changeName = self.inputField:getString()
    if changeName == userModel:getUserName() then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(FloatText.RepeatName))
        return
    elseif 0 ~= userModel:getChangeNameFree() and userModel:getDiamond() < ChangeNameDiamond then -- 钻石不够
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(FloatText.NoEnoughDiamond))
        return
    elseif string.find(changeName, " ") or string.len(changeName) <= 0 then
        CsbTools.addTipsToRunningScene(CommonHelper.getUIString(FloatText.UnNil))
        return
    else
        -- 发送改名消息
        local BufferData = NetHelper.createBufferData(MainProtocol.User, UserProtocol.RenameCS)
        BufferData:writeString(changeName)
        NetHelper.request(BufferData)

        self.inputField:didNotSelectSelf()
        return true
    end
end

-- 接收改名请求
function UINameSetting:acceptRenameCmd(mainCmd, subCmd, buffData)
    -- 注销改名命令
    local cmd = NetHelper.makeCommand(mainCmd, subCmd)
    NetHelper.removeResponeHandler(cmd, self.renameHandler)
    self.renameHandler = nil

    local result = buffData:readInt()
    if 1 == result then
        if 0 == userModel:getChangeNameFree() then -- 0免费
            userModel:setChangeNameFree()
        else
            ModelHelper.addCurrency(UIAwardHelper.ResourceID.Diamond, -ChangeNameDiamond)
        end
        userModel:setUserName(self.inputField:getString())

        if self.callback and "function" == type(self.callback) then
            self.callback()
        end
    else
        print("Error: UINameSetting, change name fail!!!")
    end
    UIManager.close()
end

return UINameSetting