require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")

local SummonerUpdateApp = class("SummonerUpdateApp", cc.mvc.AppBase)

function SummonerUpdateApp:ctor()
	SummonerUpdateApp.super.ctor(self)
end

function SummonerUpdateApp:run(...)
	app:enterScene("UpdateScene", {...})
end

return SummonerUpdateApp
