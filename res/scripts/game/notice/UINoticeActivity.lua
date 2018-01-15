
--[[
/*******************************************************************
** 创建人:	卢松
** 日  期:  2016-08-31 18:03
** 版  本:	1.0
** 描  述:  活动公告界面
** 应  用:
********************************************************************/
--]]

local UINoticeActivity = class("UINoticeActivity", function()
    return require("common.UIView").new()
end)

-- 构造函数
function UINoticeActivity:ctor()

end

-- 当界面被创建时回调
-- 只初始化一次
function UINoticeActivity:init(...)
    self.rootPath = ResConfig.UINoticeActivity.Csb2.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

    -- UI文本
    getChild(self.root, "MainPanel/NoticePanel/TitleText"):setString(CommonHelper.getUIString(1642))
    getChild(self.root, "MainPanel/NoticePanel/TipText"):setString(CommonHelper.getUIString(1713))

    -- 关闭按钮
    local btnClose = getChild(self.root, "MainPanel/NoticePanel/CloseButton")
    CsbTools.initButton(btnClose, handler(self, self.onClick))

    -- 公告开启复选框
    local checkBox = getChild(self.root, "MainPanel/NoticePanel/CheckBox_1")
    checkBox:addEventListener(handler(self, self.onCheckBox))
    checkBox:setSelected(false)
end

-- 当界面被打开时回调
-- 每次调用Open时回调
function UINoticeActivity:onOpen(openerUIID, callback)
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_IPHONE == targetPlatform or cc.PLATFORM_OS_ANDROID == targetPlatform then
        local scrollview = getChild(self.root, "MainPanel/NoticePanel/NoticeScrollView")
        scrollview:setVisible(false)
        --
        local winSize = cc.Director:getInstance():getVisibleSize()
        self._webView = ccexp.WebView:create()
        self._webView:setAnchorPoint(scrollview:getAnchorPoint())
        self._webView:setContentSize(scrollview:getContentSize())
        self._webView:setPosition(scrollview:getPosition())
        self._webView:setLocalZOrder(scrollview:getLocalZOrder())
        self._webView:loadURL("http://zhs-rc-linux.fanhougame.com/game-notice/preview")
        self._webView:setScalesPageToFit(true)

        self._webView:setOnShouldStartLoading(function(sender, url)
            print("onWebViewShouldStartLoading, url is ", url)
            return true
        end)
        self._webView:setOnDidFinishLoading(function(sender, url)
            print("onWebViewDidFinishLoading, url is ", url)
        end)
        self._webView:setOnDidFailLoading(function(sender, url)
            print("onWebViewDidFinishLoading, url is ", url)
        end)

        scrollview:getParent():addChild(self._webView)

        self:initEvent()
    end
end

-- 每次界面Open动画播放完毕时回调
function UINoticeActivity:onOpenAniOver()
end

-- 当界面被关闭时回调
-- 每次调用Close时回调
-- 可以返回多个数据
function UINoticeActivity:onClose()
    self:removeEvent()
end

-- 当界面被置顶时回调
-- Open时并不会回调该函数
function UINoticeActivity:onTop(preUIID, ...)
    if self._webView then
        self._webView:setVisible(true)
    end
end

function UINoticeActivity:onClick(obj)
    local name = obj:getName()
    if "CloseButton" == name then
        UIManager.close()
    end
end

function UINoticeActivity:onCheckBox(obj, checkType)
    MusicManager.playSoundEffect(obj:getName())

    if 0 == checkType then  -- 选中
        cc.UserDefault:getInstance():setIntegerForKey("NoticeActivityHideTime", os.time())
    else                    -- 取消
        cc.UserDefault:getInstance():setIntegerForKey("NoticeActivityHideTime", 0)
    end
end


---------------------------------------------------------------------
-- 初始化事件回调
function UINoticeActivity:initEvent()
    -- 添加界面打开事件监听
    self.openUIHandler = handler(self, self.openUI)
    EventManager:addEventListener(GameEvents.EventOpenUI, self.openUIHandler)
end

-- 移除事件回调
function UINoticeActivity:removeEvent()
    -- 移除界面打开事件监听
    if self.openUIHandler then
        EventManager:removeEventListener(GameEvents.EventOpenUI, self.openUIHandler)
        self.openUIHandler = nil
    end
end

function UINoticeActivity:openUI(eventName, uiID)
    if uiID ~= UIManager.UI.UINoticeActivity then
        if self._webView then
            self._webView:setVisible(false)
        end
    end
end

return UINoticeActivity