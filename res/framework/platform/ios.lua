
--[[if cc.bPlugin_ then
	luaoc = require("cocos.cocos2d.luaoc")
else
	luaoc = require(cc.PACKAGE_NAME .. ".luaoc")
end]]

luaoc = require(cc.PACKAGE_NAME .. ".luaoc")

function device.showAlertIOS(title, message, buttonLabels, listener)
end
