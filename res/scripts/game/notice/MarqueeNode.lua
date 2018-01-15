
--[[
/*******************************************************************
** 创建人:	wsy
** 日  期:  2016-11-21 19:59
** 版  本:	1.0
** 描  述:  跑马灯节点
** 应  用:
********************************************************************/
--]]

local MarqueeNode = class("MarqueeNode", function()
    return cc.Node:create()
end)

function MarqueeNode:ctor()
    self.marqueeNode = getResManager():cloneCsbNode(ResConfig.Common.Csb2.marquee)
	self:addChild(self.marqueeNode)

    CommonHelper.layoutNode(self.marqueeNode)

    self.defaultText = CsbTools.getChildFromPath(self.marqueeNode, "NoticeBar/TipsText")
    self.noticeBar = CsbTools.getChildFromPath(self.marqueeNode, "NoticeBar")
    
    self.startPosX = self.noticeBar:getContentSize().width
    self.endPosX = -20
end

function MarqueeNode:setString(text, isRich)
    -- 如果传递的是使用富文本就创建,否则用默认的
    if isRich then
        local richTextLb = self.noticeBar:getChildByName("RICHTEXT")
        if not richTextLb then
            richTextLb = createRichText()
            richTextLb:setName("RICHTEXT")
            self.noticeBar:addChild(richTextLb)
        end

        self.tipsText = richTextLb
        self.defaultText:setVisible(false)
    else
        self.tipsText = self.defaultText
        self.defaultText:setVisible(true)
    end

    self.tipsText:setString(text)
end

function MarqueeNode:running(callback)
    self:setVisible(true)
    self.callBack = callback
    local textWidth = self.tipsText:getContentSize().width
    self.tipsText:setPosition(cc.p(self.startPosX, self.tipsText:getPositionY()))
    
    local moveTo = cc.MoveTo:create(15, cc.p(self.endPosX - textWidth, self.tipsText:getPositionY()))
    local finishCall = cc.CallFunc:create(function ()
        if self.callBack then
            self.callBack()
            self:setVisible(false)
        end
    end)
    
    self.tipsText:runAction(cc.Sequence:create(moveTo, finishCall))
end

return MarqueeNode