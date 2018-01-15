--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-08-24 17:00
** 版  本:	1.0
** 描  述:  首次取名界面
** 应  用:
********************************************************************/
--]]
local userModel = getGameModel():getUserModel()

local FloatText = {UnDevelop = 11, RepeatName = 51, NoEnoughDiamond = 5, OpenUnion = 301, UnNil = 432, UnLegal = 8}

local UINameIntitle = class("UINameIntitle", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UINameIntitle:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UINameIntitle:init(...)
    self.rootPath = ResConfig.UINameIntitle.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- -- UI文本
    CsbTools.getChildFromPath(self.root, "MainPanel/TipsText"):setString(CommonHelper.getUIString(1697))
    CsbTools.getChildFromPath(self.root, "MainPanel/TipsText_2"):setString(CommonHelper.getUIString(1698))
    -- 按钮文本
    CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton1/ButtonName"):setString(CommonHelper.getUIString(500))

    -- 随机按钮
    local btnRandom = CsbTools.getChildFromPath(self.root, "MainPanel/RandomButton")
    CsbTools.initButton(btnRandom, handler(self, self.onClick))

    -- 确认按钮
    local btnConfirm = CsbTools.getChildFromPath(self.root, "MainPanel/ConfrimButton1")
    CsbTools.initButton(btnConfirm, handler(self, self.onClick))

    -- 文本输入
    self.inputField = CsbTools.getChildFromPath(self.root, "MainPanel/InputField")
    self.inputField:addEventListener(handler(self, self.onInput))
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UINameIntitle:onOpen(openerUIID, ...)
    self:onInput(self.inputField, 0)

    local nameConf = getSysAutoNameConf()
    if nil == nameConf then
        return
    end

    self.libraryA = nameConf[1] or {""}
    self.libraryB = nameConf[2] or {""}
    self.libraryC = nameConf[3] or {""}

    self:randomName()
end

function UINameIntitle:randomName()
    while (true) do
        if nil == self.libraryA or 0 == #self.libraryA then
            local nameConf = getSysAutoNameConf()
            if nil == nameConf then
                return
            end
            self.libraryA = nameConf[1]
            if nil == self.libraryA or 0 == #self.libraryA then
                return
            end
        end
        if nil == self.libraryB or 0 == #self.libraryB then
            local nameConf = getSysAutoNameConf()
            if nil == nameConf then
                return
            end
            self.libraryB = nameConf[2]
            if nil == self.libraryB or 0 == #self.libraryB then
                return
            end
        end
        if nil == self.libraryC or 0 == #self.libraryC then
            local nameConf = getSysAutoNameConf()
            if nil == nameConf then
                return
            end
            self.libraryC = nameConf[3]
            if nil == self.libraryC or 0 == #self.libraryC then
                return
            end
        end

        math.randomseed(os.time())
        local mode = math.random(1, 4)
        local idxA = math.random(1, #self.libraryA)
        local idxB = math.random(1, #self.libraryB)
        local idxC = math.random(1, #self.libraryC)

        local name = ""
        local strA = self.libraryA[idxA] or ""
        local strB = self.libraryB[idxB] or ""
        local strC = self.libraryC[idxC] or ""
        if 1 == mode then
            name = strA .. strB ..strC
            table.remove(self.libraryA, idxA)
            table.remove(self.libraryB, idxB)
            table.remove(self.libraryC, idxC)
        elseif 2 == mode then
            name = strA .. strB
            table.remove(self.libraryA, idxA)
            table.remove(self.libraryB, idxB)
        elseif 3 == mode then
            name = strA .. strC
            table.remove(self.libraryA, idxA)
            table.remove(self.libraryC, idxC)
        elseif 4 == mode then
            name = strB .. strC
            table.remove(self.libraryB, idxB)
            table.remove(self.libraryC, idxC)
        end

        if string.len(name) <= 18 then
            self.inputField:setString(name)
            break
        end
    end
end

-- 每次界面Open动画播放完毕时回调
function UINameIntitle:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UINameIntitle:onClose()
    if self.renameHandler then
        local cmd = NetHelper.makeCommand(MainProtocol.User, UserProtocol.RenameSC)
        NetHelper.removeResponeHandler(cmd, self.renameHandler)
        self.renameHandler = nil
    end
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UINameIntitle:onTop(preUIID, ...)

end

function UINameIntitle:onClick(obj)
    local name = obj:getName()
    if "RandomButton" == name then
        self:randomName()
    elseif "ConfrimButton1" == name then
        obj.soundId = nil
        if not self:sendRenameCmd() then
            obj.soundId = MusicManager.commonSound.fail
        end
    end
end

function UINameIntitle:onInput(obj, event)
    -- if event == 0 then
        -- -- ATTACH_WITH_IME
    -- elseif event == 1 then
        -- -- DETACH_WITH_IME
    -- elseif event == 2 then
        -- -- INSERT_TEXT
    -- elseif event == 3 then
        -- -- DELETE_BACKWARD
    -- end
    if 2 == event then
        -- 敏感词屏蔽
        local newStr = FilterSensitive.FilterStr(obj:getString())
        -- 长度限制(6个汉字12个字符)
        newStr = CommonHelper.limitStrLen(newStr, 6)
        obj:setString(newStr)
    end
end

-- 发送改名请求
function UINameIntitle:sendRenameCmd()
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
        return true
    end
end

-- 接收改名请求
function UINameIntitle:acceptRenameCmd(mainCmd, subCmd, buffData)
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
        print("Error: UINameIntitle, change name fail!!!")
    end
    UIManager.replace(UIManager.UI.UIArena)
end

return UINameIntitle