--[[
渠道对应的商店地址:
	markPackName: 应用商店包名
	markActivity: 应用商店activity
	funcId: 调用方式
		1: goToMarket
		2: goToMarketWithActivity
		3: goToSamsungappsMarket
		4: goToLeTVStoreDetail

	markAddress: 商店地址
]]
markConf = {}

if device.platform == "android" then
	markConf = {
		-- 应用宝
		[160136] = {markPackName = "com.tencent.android.qqdownloader", markActivity = "com.tencent.pangu.link.LinkProxyActivity", funcId = 2},
		[999999] = {markPackName = "com.tencent.android.qqdownloader", markActivity = "com.tencent.pangu.link.LinkProxyActivity", funcId = 2},
	}

elseif device.platform == "ios" then
	markConf = {
		[500026] = {markAddress = "itms://itunes.apple.com/gb/app/yi-dong-cai-bian/id391945719?mt=8"},
		[999999] = {markAddress = "itms://itunes.apple.com/gb/app/yi-dong-cai-bian/id391945719?mt=8"},
	}
end

