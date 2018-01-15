--[[
	战斗回放频道界面界面，主要实现以下内容
	1. 显示战斗回放列表
		玩家头像,名称,公会名,排名,胜负,观看次数,发布时间,出战阵容
	2. 跳转到分享界面
	3. 体转到观看界面
--]]

local UIReplayChannel = class("UIReplayChannel", require("common.UIView"))

function UIReplayChannel:ctor()
	self.csbFile = ResConfig.UIReplayChannel.Csb2
	self.rootPath = self.csbFile.main
	self.root = getResManager():getCsbNode(self.rootPath)
	self:addChild(self.root)

	-- 返回按钮
	local backBtn = CsbTools.getChildFromPath(self.root, "MainPanel/RepalyPanel/CloseButton")
	CsbTools.initButton(backBtn, handler(self, self.backBtnCallBack))

	-- 滚动列表
	self.scroll = CsbTools.getChildFromPath(self.root, "MainPanel/RepalyPanel/ReplayScrollView")
	self.scroll:removeAllChildren()
	self.scroll:setVisible(false)
	self.tableView = cc.TableView:create(self.scroll:getContentSize())
	self.tableView:setDirection(self.scroll:getDirection())
	self.tableView:setPosition(self.scroll:getPosition())
	self.tableView:setDelegate()	
    self.tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.scroll:getParent():addChild(self.tableView)

    self.tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView),cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
    self.tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll),cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.tableView:registerScriptHandler(handler(self, self.scrollViewDidZoom),cc.SCROLLVIEW_SCRIPT_ZOOM)
    self.tableView:registerScriptHandler(handler(self, self.tableCellTouched),cc.TABLECELL_TOUCHED)
    self.tableView:registerScriptHandler(handler(self, self.cellSizeForTable),cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableView:registerScriptHandler(handler(self, self.tableCellAtIndex),cc.TABLECELL_SIZE_AT_INDEX)

	local itemCsb = getResManager():getCsbNode(self.csbFile.item)
	self.itemSize = CsbTools.getChildFromPath(itemCsb, "ReplayPanel"):getContentSize()
	itemCsb:cleanup()
end

function UIReplayChannel:onOpen()
	-- 回放数据(假)
	self.replayInfo = {}

	self.tableView:reloadData()
end

function UIReplayChannel:onClose()
end

function UIReplayChannel:numberOfCellsInTableView(table)
	return 30
end

function UIReplayChannel:scrollViewDidScroll(view)
	--print("scrollViewDidScroll")
end

function UIReplayChannel:scrollViewDidZoom(view)
	--print("scrollViewDidZoom")
end

function UIReplayChannel:tableCellTouched(table,cell)
	print("cell touched at index: " .. cell:getIdx())
end

function UIReplayChannel:cellSizeForTable(table,idx)
	return self.itemSize.width, self.itemSize.height + 5
end

function UIReplayChannel:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    local itemCsb = nil    
    if nil == cell then
        cell = cc.TableViewCell:new()

        itemCsb = getResManager():getCsbNode(self.csbFile.item)
        local layout = CsbTools.getChildFromPath(itemCsb, "ReplayPanel")
        layout:setAnchorPoint(cc.p(0,0))
        layout:setPosition(cc.p(5, 0))
        itemCsb:setTag(123456)
        cell:addChild(itemCsb)

        local shareBtn = CsbTools.getChildFromPath(layout, "ShareButton")
        local watchBtn = CsbTools.getChildFromPath(layout, "ViewButton")
        shareBtn:addClickEventListener(handler(self, self.shareBtnCallBack))
        watchBtn:addClickEventListener(handler(self, self.watchBtnCallBack))

        -- 不能用此方法(拖动的时候后台,按钮的触摸事件不知道为什么就没了!!!)
        --CsbTools.initButton(shareBtn, handler(self, self.shareBtnCallBack))
        --CsbTools.initButton(watchBtn, handler(self, self.watchBtnCallBack))
    else
        itemCsb = cell:getChildByTag(123456)
    end

    -- 初始化item显示数据
    if nil ~= itemCsb then
    	local replayNode = CsbTools.getChildFromPath(itemCsb, "ReplayPanel")
		xpcall(UIReplayHelper.setReplayNode, function() print(debug.traceback()) end, replayNode, info)
    	CsbTools.getChildFromPath(replayNode, "ShareButton"):setTag(idx)
    	CsbTools.getChildFromPath(replayNode, "ViewButton"):setTag(idx)
    end
    return cell
end

function UIReplayChannel:backBtnCallBack(obj)
	UIManager.close()
end

function UIReplayChannel:shareBtnCallBack(obj)
	print("share idx", obj:getTag())

	UIManager.open(UIManager.UI.UIShareDialog, obj:getTag(), handler(self, self.shareDialogCallBack))
end

function UIReplayChannel:shareDialogCallBack(battleID, shareSucess, shareDesc)
	print("battleID, shareSucess, shareDesc", battleID, shareSucess, shareDesc)
	if battleID == nil or shareSucess == nil or shareDesc == nil then
		return
	end

	if shareSucess then
		CsbTools.addTipsToRunningScene(string.format("成功分享 battleid: %d", battleID))
	else
		CsbTools.addTipsToRunningScene(string.format("取消分享 battleid: %d", battleID))
	end
end

function UIReplayChannel:watchBtnCallBack(obj)
	print("watch idx", obj:getTag())
end

return UIReplayChannel