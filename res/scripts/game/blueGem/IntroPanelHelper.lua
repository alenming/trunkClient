local IntroPanelHelper = {}

function IntroPanelHelper.init(node)
	IntroPanelHelper.mRoot = node

	IntroPanelHelper.mEveryDayPanel = CsbTools.getChildFromPath(IntroPanelHelper.mRoot, "EveryDayPanel")

	IntroPanelHelper.mTips = CsbTools.getChildFromPath(IntroPanelHelper.mEveryDayPanel, "TipsText")
	if not IntroPanelHelper.mTips:getChildByTag(1) then
		local richText = createRichText(IntroPanelHelper.mTips:getContentSize().width)
	    richText:setAnchorPoint(cc.p(0, 0))
	    richText:setPosition(0, 0)
	    richText:setString(getBlueDiamondLanConfItem(1008))
	    richText:setTag(1)
	    IntroPanelHelper.mTips:addChild(richText)
	    IntroPanelHelper.mTips:setString("")
	end

	IntroPanelHelper.mGotoBtn = CsbTools.getChildFromPath(IntroPanelHelper.mEveryDayPanel, "GotoButton")
	CsbTools.initButton(IntroPanelHelper.mGotoBtn, function () 
		openURL("http://gamevip.qq.com/?ADTAG=VIP.WEB.zhsOL")
	end)
end

return IntroPanelHelper