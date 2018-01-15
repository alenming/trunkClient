local UIMailInfoHelper = class("UIMailInfoHelper")
require("game.mail.MailHelper")
require("game.comm.UIAwardHelper")
local PropTips = require("game.comm.PropTips")

local awardItemFile = ResConfig.UIMail.Csb2.awardItem
local receiveBtnFile = "ui_new/g_gamehall/m_mail/MailReceiveButton.csb"
local confrimBtnFile = "ui_new/p_public/Button_Confrim.csb"

function UIMailInfoHelper:ctor(uiMail)
	self.uiMail = uiMail

	self.itemSize = CsbTools.getChildFromPath(getResManager():getCsbNode(awardItemFile), "MainPanel"):getContentSize()

	self.root = CsbTools.getChildFromPath(self.uiMail.root, "MainPanel/MessagePanel")
	-- 标题
	self.titleLab = CsbTools.getChildFromPath(self.root, "MessagePanel/BarImage1/TitleName")
	-- 内容
	self.descLab = CsbTools.getChildFromPath(self.root, "MessagePanel/MessageScrollView/MessgeInfo")
	-- 来自
	self.fromLab = CsbTools.getChildFromPath(self.root, "MessagePanel/MessageScrollView/FromText")
	-- 内容scrollView
	self.descScroll = CsbTools.getChildFromPath(self.root, "MessagePanel/MessageScrollView")
	-- 奖励scrollView
	self.awardScroll = CsbTools.getChildFromPath(self.root, "MessagePanel/AwardScrollView")
	self.awardScroll:removeAllChildren()
	-- 领取按钮
	self.csbReceiveBtn = CsbTools.getChildFromPath(self.root, "MessagePanel/MailReceiveButton")
	self.receiveBtn = CsbTools.getChildFromPath(self.csbReceiveBtn, "ReceiveButton")
	CsbTools.getChildFromPath(self.receiveBtn, "Button_Confrim/ButtomName")
		:setString(CommonHelper.getUIString(79))
	CsbTools.initButton(self.receiveBtn, handler(self, self.receiveCallBack), nil, nil, "Button_Confrim")

end

function UIMailInfoHelper:onOpen()
	-- 道具点击提示
	self.propTips = PropTips.new()
	self.receiveBtn:setTouchEnabled(true)
end

function UIMailInfoHelper:onClose()
	self.propTips:removePropAllTips()
	self.propTips = nil
end

function UIMailInfoHelper:reShow(mailKey)
	self.mailKey = mailKey
	self:setIsShow(true)

	self.mailInfo = MailHelper.getMailData(mailKey)
	if not self.mailInfo then
		print("error not find mail info", mailID, mailType)
		self:setIsShow(false)
		return 
	end

	-- 排序道具
	local function sortProp(prop1, prop2)
		if prop1.id < prop2.id then
			return true
		end
	end
	table.sort(self.mailInfo.vecItem, sortProp)

	local lifeDays = math.ceil((self.mailInfo.sendTimeStamp + MailHelper.validSce - getGameModel():getNow())/86400)
	-- 邮件文字显示
	self.titleLab:setString(self.mailInfo.title)
    local hasDay = string.find(self.mailInfo.content, "%%d")
    if hasDay then
	    self.descLab:setString(string.format(self.mailInfo.content, lifeDays))
    else
        self.descLab:setString(self.mailInfo.content)
    end
	self.fromLab:setString(self.mailInfo.sender)
	self.descLab:setTextAreaSize(cc.size(self.descLab:getContentSize().width, 0))
	local innerSize = self.descScroll:getContentSize()
	local realHeight = self.descLab:getVirtualRendererSize().height + self.fromLab:getContentSize().height
	if realHeight > innerSize.height then
		innerSize.height = realHeight
	end
	self.descLab:setTextAreaSize(cc.size(self.descLab:getContentSize().width, self.descLab:getVirtualRendererSize().height))
	self.descScroll:setInnerContainerSize(innerSize)
	self.descLab:setPositionY(innerSize.height - self.descLab:getContentSize().height/2)
	self.fromLab:setPositionY(innerSize.height - self.descLab:getVirtualRendererSize().height - self.fromLab:getContentSize().height)

    -- 邮件奖励列表拖动长度
    innerSize = self.awardScroll:getContentSize()
    if innerSize.width < self.itemSize.width * (#self.mailInfo.vecItem) then
        innerSize.width = self.itemSize.width * (#self.mailInfo.vecItem)
    end
    self.awardScroll:setInnerContainerSize(innerSize)
	
	self.awardScroll:removeAllChildren()

	for i, v in ipairs(self.mailInfo.vecItem) do
		local item = getResManager():cloneCsbNode(awardItemFile)
		self.awardScroll:addChild(item)
		UIAwardHelper.setAllItemOfConf(item, getPropConfItem(v.id), v.num)
		item:setPosition(cc.p(self.itemSize.width * (i - 0.5), self.itemSize.height/2))

		local touchNode = CsbTools.getChildFromPath(item, "MainPanel")
		self.propTips:addPropTips(touchNode, getPropConfItem(v.id))
	end

	if #self.mailInfo.vecItem == 0 then
		-- 没有奖励 直接删除邮件
		MailHelper.delMail(mailKey)
		self.uiMail:uiMailListDel({mailKey})
	end

	if #self.mailInfo.vecItem == 0 then
		CommonHelper.playCsbAnimate(self.csbReceiveBtn, receiveBtnFile, "Null", false, nil, true)
	else
		CommonHelper.playCsbAnimate(self.csbReceiveBtn, receiveBtnFile, "Receive", false, nil, true)
	end
end

function UIMailInfoHelper:setReceived()
	CommonHelper.playCsbAnimate(self.csbReceiveBtn, receiveBtnFile, "Received", false, nil, true)
end

function UIMailInfoHelper:setIsShow(isShow)
	self.root:setVisible(isShow)
	self.receiveBtn:setTouchEnabled(isShow)
end

function UIMailInfoHelper:getIsShow()
	return self.root:isVisible()
end

function UIMailInfoHelper:receiveCallBack(obj)
	obj:setTouchEnabled(false)
	-- 发包
	local bufferData = NetHelper.createBufferData(MainProtocol.Mail, MailProtocol.GetMailGoodsCS)
	bufferData:writeChar(self.mailInfo.mailType == MailHelper.Type.normal and 1 or 0)
	bufferData:writeChar(self.mailInfo.mailType == MailHelper.Type.web and 1 or 0)
	bufferData:writeInt(self.mailInfo.mailID)
	NetHelper.request(bufferData)
end

return UIMailInfoHelper