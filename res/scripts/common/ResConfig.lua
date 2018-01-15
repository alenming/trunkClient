--[[
	ResConfig为【召唤师联盟】的资源配置文件
	用于配置每个场景、界面需要预加载的资源
	支持各种纹理、图集、CocoStudio2.x导出的csb和json、CocoStudio1.6骨骼、Spine骨骼、音效等资源

	1.界面资源配置，填写规则：
	在ResConfig下以自己的界面名字为key，填写一个Table，Table支持以下字段
		Csb2——CocoStudio2.0以上版本导出的Csb对象，支持csb、json、ExportJson格式
		Tex——纹理和图集资源，支持plist、png、jpg、pvrtc、etc等等格式
		Spine——Spine导出的骨骼动画，支持json格式
		Armature——CocoStudio1.6导出的骨骼动画，支持csb、ExportJson格式
		Music——音效资源，支持wav、mp3、ogg、aiff、caf3等等格式
	以上的每一个Key都会对应一个Table，不需要加载该资源可不填或设置为nil
	需要加载可以直接写入资源路径、或以key=路径的方式写入（方便程序索引），例如：
	ResConfig.UITest = {
		-- 注意，这里使用了key-value以及顺序赋值两种方式
		-- 当同时使用这2种方式时，会先将顺序初始化的内容填入table，再执行key-value的
		-- 所以，当key-value的key与顺序索引发生冲突，那么最终会被key-value覆盖！！！
		ResConfig.UITest.Csb2.closeButton
		local Csb = ResConfig.UITest.Csb2
		Csb.closeButton
		Csb2 = {closeButton = "csb/close.csb", test = "csb/test.csb", "csb/test2.csb", ...}
		-- 不需要其他资源，可以不填
	}

	2.场景资源配置，在界面资源配置的基础上，增加了UI字段，用以表示该场景需要预加载哪些资源
	UI字段的使用规则如下：
	ResConfig.SceneTest = {
		UI = {"UITest", "UITest2", },
		...
	}

	PS:在程序启动时初始化该文件，并根据平台初始化该文件的IOS或Android修正版本
	修正版本会将纹理和音乐格式调整为平台相关的格式

	2015-10-31 By 宝爷
]]

ResConfig = {}

-- 资源类型
ResConfig.ResType = {
	Csb = 1,
	Armature = 2,
	Spine = 3,
	Music = 4,
	Texture = 5,
}

--
ResConfig.Cache = {

}

-- 公共资源，在任何场景切换时，Resmanager都保证不会释放这些缓存资源
ResConfig.Common = {
	-- 需要一直Cache的界面
	UI = {"UIDialogBox"},
	-- CocoStudio2.0以上版本导出的Csb对象，支持csb、json、ExportJson格式
	Csb2 = {buyGold = "ui_new/g_gamehall/g_gpub/BuygoldPanel.csb",
            buyEnergyPanel 	= "ui_new/g_gamehall/g_gpub/BuyEnergyPanel.csb",
            propTips = "ui_new/w_worldmap/AwradItemTips.csb",
            connectTips = "ui_new/f_fight/ConnectTips.csb",
			wifiTips = "ui_new/f_fight/WifiTips.csb",
            record = "ui_new/g_gamehall/c_chat/RecordTimeButton.csb",
            marquee = "ui_new/g_gamehall/g_gpub/TopTips.csb",},
	-- 纹理和图集资源，支持plist、png、jpg、pvrtc、etc等等格式
	Tex = { "ui_new/i_icon/i_icon.plist",
            "ui_new/i_icon/icon_head.plist",
            "ui_new/i_icon/icon_prop.plist",
            "ui_new/i_icon/icon_skill.plist",
            "ui_new/p_public/p_public.plist",
            "ui_new/p_public/p_public2.plist",
            "ui_new/i_icon/tencent_logo.plist",
            -- 为避免加载界面中的跳帧
            "ui_new/l_loading/loading.plist"
            },
	-- Spine导出的骨骼动画，支持json格式
	Spine = {},
	-- CocoStudio1.6导出的骨骼动画，支持csb、ExportJson格式
	Armature = {},
	-- 音效资源，支持wav、mp3、ogg、aiff、caf3等等格式
	Music = {"music/Master Bank.bank", "music/Master Bank.strings.bank", "music/Music.bank"
        , "music/Public.bank", "music/UI.bank", "music/Voice.bank"},
}

---------------------------- SCENE Login ---------------------------------
ResConfig.SceneLogin = {
	UI = {"UILogin", --[["UIServerList"]] },
	Csb2 = {},
	Tex = {},
	Spine = {},
	Armature = {},
	Music = {},
	-- 需要使用函数动态生成资源
	Func = {},
	-- 该场景离开时不释放的资源类型
	Cache = {},
}

ResConfig.UILogin = {
    Csb2 = {main = "ui_new/l_login/Login_Test.csb",
            mainQQ = "ui_new/l_login/Login.csb",
            mainUpdate = "ui_new/l_login/Loading.csb",
            Notic = "ui_new/l_login/UserAgreement.csb",
            },
}

ResConfig.UILoginSDK = ResConfig.UILogin

ResConfig.UIServerList = {
    Csb2 = {main = "ui_new/l_login/OnlineMode.csb",
    },
}

ResConfig.UILoginAccountInput = {
    Csb2 = {
        main = "ui_new/l_login/Login_Input.csb",
    },
}

ResConfig.UILoginTips = {
    Csb2 = {
        main = "ui_new/l_login/Login_Tips.csb",
    },
}

---------------------------- SCENE Hall ---------------------------------
ResConfig.UIHallBG = {
    Csb2 = {HallBG = "ui_new/g_gamehall/g_gpub/GameHallBg.csb"}
}

ResConfig.UIHall = {
	-- CocoStudio2.0以上版本导出的Csb对象，支持csb、json、ExportJson格式
	Csb2 = {GameHallNew 	= "ui_new/g_gamehall/g_gpub/GameHall.csb",
			TalkButton		= "ui_new/g_gamehall/g_gpub/TalkButton.csb",
            PlayerInfoPanel = "ui_new/g_gamehall/g_gpub/PlayerInfoPanel.csb",
            Record          = "ui_new/g_gamehall/c_chat/RecordTimeButton.csb"},

	-- 纹理和图集资源，支持plist、png、jpg、pvrtc、etc等等格式
	Tex = {},

	-- Spine导出的骨骼动画，支持json格式
	--Spine = {},
	-- CocoStudio1.6导出的骨骼动画，支持csb、ExportJson格式
	--Armature = {},
	-- 音效资源，支持wav、mp3、ogg、aiff、caf3等等格式
	--Music = {},
}

ResConfig.UIUserSetting = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/InfoSetPanel.csb",
            SoundSwitch = "ui_new/g_gamehall/g_gpub/SoundSwitch.csb",
    }
}

ResConfig.UIHeadSetting = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/HeadPanel.csb",
            item = "ui_new/g_gamehall/g_gpub/HeadItem.csb",
        }
}

ResConfig.UINameSetting = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/ChangeName.csb", }
}

ResConfig.UIPackageRedeem = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/RedeemCode.csb", }
}

ResConfig.UIInputPassword = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/InputPassWord.csb", }
}

ResConfig.UINameIntitle = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/InputName.csb", }
}

ResConfig.UIPushSetPanel = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/PushSetPanel.csb", }
}

ResConfig.UIBag = {
    Csb2 = {main = "ui_new/g_gamehall/b_bag/bag.csb",
            tab = "ui_new/g_gamehall/b_bag/AllButton2.csb",
            item = "ui_new/g_gamehall/b_bag/PropItem.csb",
            effect = "ui_new/g_gamehall/b_bag/BagItemEffect.csb",},
    Tex = {},
}

ResConfig.UIChatBag = {
    Csb2 = {main = "ui_new/g_gamehall/b_bag/bag.csb",
            btn = "ui_new/g_gamehall/c_collection/GeneralButton.csb",
            tab = "ui_new/g_gamehall/b_bag/AllButton2.csb",
            item = "ui_new/g_gamehall/b_bag/PropItem.csb",
            effect = "ui_new/g_gamehall/b_bag/BagItemEffect.csb",
            award = "ui_new/g_gamehall/t_task/Award.csb",
            unit = "ui_new/g_gamehall/t_task/AwardItem_E.csb",
            ok = "ui_new/g_gamehall/c_collection/ConfirmButton.csb",},
    Tex = {},
}

ResConfig.UIBagSale = {
    Csb2 = {main = "ui_new/g_gamehall/b_bag/BagSale.csb",}
}

ResConfig.UIBagUse = {
    Csb2 = {main = "ui_new/g_gamehall/b_bag/BagSale.csb",}
}

ResConfig.UIBagUnlock = {
    Csb2 = {main = "ui_new/g_gamehall/b_bag/BagUnlock2.csb",}
}

ResConfig.UISummonerList = {
    Csb2 = {main = "ui_new/g_gamehall/s_sommoner/SummonerBuy.csb",
            card = "ui_new/g_gamehall/s_sommoner/SummonerCard.csb",
            item = "ui_new/g_gamehall/s_sommoner/SkillItem.csb",
            },
    Tex = {},
}

ResConfig.UISummonerInfo = {
    Csb2 = {main = "ui_new/g_gamehall/s_sommoner/SummonerAttri.csb",
            bar = "ui_new/g_gamehall/s_sommoner/SkillBar.csb",
            tab = "ui_new/g_gamehall/b_bag/AllButton.csb",
            showSummoner = "ui_new/g_gamehall/s_sommoner/BuyEffect.csb",},
    Tex = {},
}

ResConfig.UISummonerBuyTips = {
    Csb2 = {main = "ui_new/g_gamehall/s_sommoner/BuyTips.csb",},
    Tex = {},
}

ResConfig.UICopyChoose = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/InstanceChoose.csb",
             item = "ui_new/g_gamehall/i_instance/instance_item/InstanceItem.csb"},
}

ResConfig.UICopyDifficult = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/DiffcultChoose.csb",
             map = "ui_new/g_gamehall/i_instance/instance_item/DiffcultMap.csb",
             star = "ui_new/g_gamehall/i_instance/instance_item/DiffcultStarLevel.csb",
             item = "ui_new/g_gamehall/i_instance/instance_item/DiffcultItem.csb",
             buy = "ui_new/g_gamehall/i_instance/BuyTimes.csb"},
}

ResConfig.UICopyStrategy = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/TroopRecommend.csb",
             sum = "ui_new/w_worldmap/SummonerIcon.csb",
             hero = "ui_new/w_worldmap/HeroIcon.csb",
             sumtip = "ui_new/g_gamehall/i_instance/SummonerTips.csb",
             herotip = "ui_new/g_gamehall/i_instance/HeroTips.csb"},
     Tex = {},
}

ResConfig.UIGoldTest = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/GoldTrial.csb"},
     Tex = {},
}

ResConfig.UIGoldTestChest = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/GoldTrial_Receive.csb",
             box = "ui_new/g_gamehall/i_instance/GoldTrial/AwardBox.csb",
             chest = "ui_new/w_worldmap/ChestBox.csb"},
     Tex = {},
}

ResConfig.UIHeroTestChoose = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/HeroTrial.csb",
             card = "ui_new/g_gamehall/i_instance/TrialBar.csb"},
     Tex = {},
}

ResConfig.UIHeroTestDifficulty = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/HeroTrial_DiffcultChoose.csb",
             bar = "ui_new/g_gamehall/i_instance/DiffcultBar.csb",
             diffcultLvIcon = "ui_new/g_gamehall/i_instance/DiffcultLvIcon.csb"},
     Tex = {"ui_new/g_gamehall/i_instance/ClimbTower/climbtower.plist"},
}

ResConfig.UIHeroTestInfo = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/TrialInfoPanel.csb"},
     Tex =  {},
}

ResConfig.UIShowSummoner = {
    Csb2 = {showSummoner = "ui_new/g_gamehall/s_sommoner/BuyEffect.csb",}
}

-- 动态根据当前队伍计算出所需的资源列表，并返回
--[[
CurrentTeamRes 是根据当前队伍的召唤师和英雄返回他们的【角色骨骼资源】
]]
function ResConfig.CurrentTeamRes()
    -- 获取模型
    -- 获取角色资源配置表
    -- 创建当前队伍所需的资源列表
    local ret = {Csb2= {},Tex = {},Spine = {},
            Armature = {},Music = {},Cache = {}}
    -- 0为通关队伍, 1为竞技队伍
    -- local summonerId, teamInfos = getGameModel():getTeamModel():getTeamInfo(0)
    local teamId = TeamHelper.getTeamId()
    local summonerId = 0
    local teamSummoner = TeamHelper.getTeamSummoner(teamId)
    local summoners = getGameModel():getSummonersModel():getSummoners()
    for i, v in pairs(summoners) do
        if teamSummoner == v then
            summonerId = teamSummoner
            break
        end
    end
    if summonerId ~= nil and summonerId > 0 then
        local summonerConf = getHeroConfItem(summonerId)
        if summonerConf == nil then
            print("操操操，Fuck You，大策划，你忘记在Hero.csv加上召唤师了" .. summonerId)
            summonerRes.fuck()
        end
        local summonerRes = getResPathInfoByID(summonerConf.Common.AnimationID)
        if summonerRes == nil then
            print("操操操，Fuck You，大策划，你忘记在Res.csv里面配上角色资源了" .. summonerId)
            summonerRes.fuck()
        end
        --召唤师的骨骼
        if summonerRes.ResType == 1 then
            table.insert(ret.Armature, summonerRes.Path)
        else
            ret.Spine[summonerRes.Path] = summonerRes.AtlasPath
        end
    end

    local existHeroList = {}
    --查找每个英雄配置, 获得英雄资源
    local heroCardBagModel = getGameModel():getHeroCardBagModel()
    local teamInfos = TeamHelper.getTeamHeros(teamId)
    for i = 1, #teamInfos do
        local heroModel = heroCardBagModel:getHeroCard(teamInfos[i])
        if heroModel then
            local confId = heroModel:getID()
            local confStar = heroModel:getStar()
            local soldierConf = getSoldierConfItem(confId, confStar);
            if soldierConf == nil then
                print("操操操，Fuck You，大策划，你忘记在Soldier.csv里面配上角色资源了 " .. confId .. " " .. confStar)
                heroRes.fuck()
            end
            local heroRes = getResPathInfoByID(soldierConf.Common.AnimationID)
            if heroRes == nil then
                print("操操操，Fuck You，大策划，你忘记在Res.csv里面配上角色资源了 " .. confId .. " " .. confStar)
                heroRes.fuck()
            end
            if heroRes.ResType == 1 then
                table.insert(ret.Armature, heroRes.Path)
            elseif heroRes.ResType == 3 then
                table.insert(ret.Csb2, heroRes.Path)
            else
                ret.Spine[heroRes.Path] = heroRes.AtlasPath
            end
            -- 缓存服务器存在的英雄id
            table.insert(existHeroList, teamInfos[i])
        end
    end

    -- 服务器清数据了之后将本地缓存的队伍信息清除
    TeamHelper.setTeamInfo(teamId, summonerId, existHeroList)

    return ret
end

ResConfig.UITowerTestDifficulty = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/ClimbTower_ChooseDiffcult.csb",
             btn = "ui_new/p_public/Button_Orange.csb",
             item = "ui_new/g_gamehall/i_instance/ClimbTower/ChooseDiffcultItem.csb"},
     Tex = {},
}

ResConfig.UITowerTestBuff = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/ClimbTower_AttriAdd.csb",
             item = "ui_new/g_gamehall/i_instance/ClimbTower/AttriAddItem.csb"},
     Tex = {},
}

ResConfig.UITowerTestChest = {
     Csb2 = {main = "ui_new/g_gamehall/t_task/Award.csb",
             found = "ui_new/g_gamehall/i_instance/ClimbTower_FoundChest.csb",
             ok = "ui_new/g_gamehall/c_collection/ConfirmButton.csb",
             start = "ui_new/p_public/Button_Green.csb",
             leave = "ui_new/p_public/Button_Orange.csb",
             chest = "ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_Chest.csb"},
     Tex = {},
}

ResConfig.UITowerTestRank = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/ClimbTower_Ranking.csb",
             item = "ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_RankingItem.csb",
             tab = "ui_new/g_gamehall/g_gpub/SetButton.csb",
             num = "ui_new/g_gamehall/i_instance/ClimbTower/RankingNum.csb",
             info = "ui_new/g_gamehall/i_instance/ClimbTower_RuleIntro.csb"},
     Tex = {},
}

ResConfig.UITowerTestRule = {
    Csb2 = {
        main = "ui_new/g_gamehall/i_instance/ClimbTower_RuleIntro.csb",
    }
}

ResConfig.UITowerTest = {
     Csb2 = {main = "ui_new/g_gamehall/i_instance/ClimbTower.csb",
             rule = "ui_new/g_gamehall/i_instance/ClimbTower_RuleIntro.csb",
             tip = "ui_new/g_gamehall/g_gpub/TipPanel.csb",
             bar = "ui_new/g_gamehall/i_instance/ClimbTower/DownButtonBar.csb",
             buff = "ui_new/g_gamehall/i_instance/ClimbTower/TabSkillBar.csb",
             item = "ui_new/g_gamehall/i_instance/ClimbTower/TabSkillItem.csb",
             chest = "ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_Chest.csb",
             bazier = "ui_new/g_gamehall/i_instance/LightBall_Bazier.csb",
             powerBall = "ui_new/g_gamehall/i_instance/ClimbTower/TabBall.csb",
     },
     Tex = {},
}

ResConfig.UIInstanceEntry = {
     Csb2 = {main = "ui_new/g_gamehall/g_gpub/InstanceEntry.csb",},
     Tex = {},
}

ResConfig.UIArena = {
    Csb2 = {arena = "ui_new/g_gamehall/a_arena/Arena.csb",
            arenaNew = "ui_new/g_gamehall/a_arena/Arena_New.csb",
            generalRule = "ui_new/g_gamehall/a_arena/GeneralRule.csb",
            awardItem = "ui_new/g_gamehall/t_task/MoneyItem.csb",
            arenaRule = "ui_new/g_gamehall/a_arena/ArenaRule.csb",
            chest = "ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_Chest.csb",
            chestNew = "ui_new/g_gamehall/a_arena/ChestBoxBar.csb", 
            levelUnlock = "ui_new/g_gamehall/a_arena/Arena_LevelUnlock.csb",
            levelBar = "ui_new/g_gamehall/a_arena/Arena_LevelBar.csb",
            level = "ui_new/g_gamehall/a_arena/Arenna_Level.csb",
        },
    Texture = {
        stage2 = "ui_new/w_worldmap/map/stage2.plist",
    }
}

ResConfig.UIArenaTask = {
     Csb2 = {task = "ui_new/g_gamehall/a_arena/Arena_Task.csb",
            arenaTaskBar = "ui_new/g_gamehall/a_arena/ArenaTaskBar.csb",}
}

ResConfig.UIReplayChannel = {
     Csb2 = {main = "ui_new/g_gamehall/r_replay/Replay.csb",
            item = "ui_new/g_gamehall/r_replay/ReplayItem.csb",}
}

ResConfig.UIShareDialog = {
     Csb2 = {main = "ui_new/g_gamehall/a_arena/Arena_Share.csb",}
}

ResConfig.UIDrawCard = {
	Csb2 = {main = "ui_new/g_gamehall/d_drawcard/DrawCard.csb",
            ten = "ui_new/g_gamehall/d_drawcard/TenCardPanel.csb",
			heroCard = "ui_new/g_gamehall/d_drawcard/SummonerCard.csb",
			heroGoldCard = "ui_new/g_gamehall/d_drawcard/SummonerCard_Golden.csb",
			heroSilverCard = "ui_new/g_gamehall/d_drawcard/SummonerCard_Silver.csb",
			bigStar = "ui_new/g_gamehall/c_collection/BigStarPanel.csb",
			againPanel = "ui_new/g_gamehall/d_drawcard/AgainButtonPanel.csb",
			againBtn = "ui_new/p_public/Button_Green.csb",
			backBtn = "ui_new/p_public/Button_Orange.csb",
            oneCard = "ui_new/g_gamehall/d_drawcard/OneCardPanel.csb",},
    Spine = {--["ui_new/g_gamehall/d_drawcard/effect/json/cat.json"] = "ui_new/g_gamehall/d_drawcard/effect/json/cat.atlas",
            --["ui_new/g_gamehall/d_drawcard/effect/json/Fairy.json"] = "ui_new/g_gamehall/d_drawcard/effect/json/Fairy.atlas",
            ["ui_new/g_gamehall/d_drawcard/effect/json/C_chou.json"] = "ui_new/g_gamehall/d_drawcard/effect/json/C_chou.atlas",
            --["ui_new/g_gamehall/d_drawcard/effect/json/Spirit.json"] = "ui_new/g_gamehall/d_drawcard/effect/json/Spirit.atlas"
            },
    Tex = {"ui_new/g_gamehall/d_drawcard/effect/ui_luckbox/ui_luckbox.plist"}
}

ResConfig.UIShowCard = {
    Csb2 = {"ui_new/g_gamehall/d_drawcard/OneCardPanel.csb",
    "ui_new/g_gamehall/d_drawcard/SummonerCard_Golden.csb", 
    "ui_new/g_gamehall/d_drawcard/SummonerCard_Silver.csb",
    "ui_new/g_gamehall/d_drawcard/AgainButtonPanel.csb",
    "ui_new/p_public/Button_Green.csb",
    "ui_new/p_public/Button_Orange.csb"}
}

ResConfig.UIMail = {
	Csb2 = {mailPanel = "ui_new/g_gamehall/m_mail/Mail.csb",
			mailItem = "ui_new/g_gamehall/m_mail/AwardMailBar.csb",
			awardItem = "ui_new/g_gamehall/b_bag/AllItem.csb"},
}

ResConfig.UIHeroUpgradeLv = {
	Csb2 = {main = "ui_new/g_gamehall/c_card/UpLevel.csb",
            materialItem = "ui_new/g_gamehall/c_card/Meterial_UpLv.csb",
            materialTypeBtn = "ui_new/g_gamehall/c_card/MaterialButton.csb",
            upSkill = "ui_new/g_gamehall/c_collection/UpSkillEffect.csb"},
}

ResConfig.UIHeroUpgradeStar = {
	Csb2 = {main = "ui_new/g_gamehall/c_card/UpStar.csb",
            effect = "ui_new/g_gamehall/c_card/UpStarEffect.csb"},
}

ResConfig.UIHeroTalent = {
	Csb2 = {main = "ui_new/g_gamehall/c_card/HeroGift.csb",
            item = "ui_new/g_gamehall/c_card/GiftItem.csb",
            tips = "ui_new/g_gamehall/c_card/SkillTips.csb",},
}

ResConfig.UIShop = {
    Csb2 = {main = "ui_new/g_gamehall/s_shop/Shop.csb",
            btn = "ui_new/g_gamehall/s_shop/ShopButton.csb",
            cell = "ui_new/g_gamehall/s_shop/ShopItem.csb"
    },
    Spine = {["ui_new/g_gamehall/s_shop/json/Store_alika.json"] = "ui_new/g_gamehall/s_shop/json/Store_alika.atlas"}
}

ResConfig.UIShopBuyMeterial = {
    Csb2 = { main = "ui_new/g_gamehall/s_shop/BuyMeterial.csb", },
}

ResConfig.UIShopBuyHero = {
    Csb2 = { main = "ui_new/g_gamehall/s_shop/BuyHero.csb", },
}

ResConfig.UIShopBuyEquip = {
    Csb2 = { main = "ui_new/g_gamehall/s_shop/BuyEquip.csb", },
}

ResConfig.UIShowEquip = {
    Csb2 = { main = "ui_new/g_gamehall/s_shop/AwardEq.csb", },
}

ResConfig.UIShopRefresh = {
    Csb2 = { main = "ui_new/g_gamehall/s_shop/RefreshTips.csb", },
}

ResConfig.UIChat = {
    Csb2 = { main = "ui_new/g_gamehall/c_chat/Chat.csb",
        item = "ui_new/w_worldmap/HeroIcon.csb",
        record = "ui_new/g_gamehall/c_chat/RecordTimeButton.csb",
        talkBarL = "ui_new/g_gamehall/c_chat/Chat_TalkBar_L.csb",
        talkBarR = "ui_new/g_gamehall/c_chat/Chat_TalkBar_R.csb",
        soundBarL = "ui_new/g_gamehall/c_chat/ChatItem/Chat_Sound_L.csb",
        soundBarR = "ui_new/g_gamehall/c_chat/ChatItem/Chat_Sound_R.csb",
        replayBar = "ui_new/g_gamehall/r_replay/Chat_ReplayBar.csb",
        eqInfo = "ui_new/g_gamehall/c_card/EquipInfoPanel.csb",},
}

ResConfig.UIReplayInfo = {
    Csb2 = {replayInfo = "ui_new/g_gamehall/r_replay/Chat_Replay.csb",},
}

ResConfig.UIChatSetting = {
    Csb2 = { main = "ui_new/g_gamehall/c_chat/ChatSetting.csb",
        allBtn = "ui_new/g_gamehall/b_bag/AllButton.csb", },
}

ResConfig.UIOperateActive = {
    Csb2 = { main = "ui_new/g_gamehall/o_operate/Operate.csb",
            operateButton = "ui_new/g_gamehall/o_operate/OperateButton.csb",
            salePanel = "ui_new/g_gamehall/o_operate/SalePanel.csb",
            taskBar = "ui_new/g_gamehall/o_operate/OperateTaskBar.csb",
            monthCard = "ui_new/g_gamehall/o_operate/MonthCard.csb",
            moneyItem = "ui_new/g_gamehall/t_task/MoneyItem.csb",
            awardItem = "ui_new/g_gamehall/t_task/TaskAwardItem.csb",
            taskState = "ui_new/g_gamehall/o_operate/OperateTaskState.csb",
    },
}

ResConfig.UIFirstRecharge = {
    Csb2 = { main = "ui_new/g_gamehall/o_operate/f_firstrecharge/FirstRecharge.csb",}
}

ResConfig.UISignIn = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/SignPanel.csb",
             item = "ui_new/g_gamehall/g_gpub/SignItem.csb",
             btn = "ui_new/g_gamehall/g_gpub/SignButton.csb",
    },
}

ResConfig.UINoticeActivity = {
    Csb2 = { main = "ui_new/g_gamehall/g_gpub/NoticePanel_2.csb",}
}

ResConfig.SceneHall = {
	UI = {"UIHall", "UIHallBG", "UIBag", },
	Csb2 = {},
	Tex = {},
	Spine = {},
	Armature = {},
	Music = {},
	-- 需要使用函数动态生成资源
	Func = {"CurrentTeamRes", },
	-- 该场景离开时不释放的资源类型
	Cache = { ResConfig.ResType.Armature, ResConfig.ResType.Spine },
}

ResConfig.UIHeroQuickTo = {
    Csb2 = {main = "ui_new/g_gamehall/c_collection/GetHeroPath.csb",
            stageItem = "ui_new/g_gamehall/c_collection/StagePathBar.csb",
            shopItem = "ui_new/g_gamehall/c_collection/ShopPathBar.csb"},
    Tex = {"ui_new/w_worldmap/map/thumbnail.plist"}
}

---------------------------- SCENE SceneTowerTrial -----------------------

ResConfig.SceneTowerTrial = {
    UI = {"UITeam", "UIAward", "UITowerTest", "UITowerTestRank",
        "UITowerTestChest", "UITowerTestBuff", "UITowerTestDifficulty",
        },
	Csb2 = {},
	Tex = {},
	Spine = {},
	Armature = {},
	Music = {},
	-- 需要使用函数动态生成资源
	Func = {"CurrentTeamRes", },
	-- 该场景离开时不释放的资源类型
	Cache = { },
}

---------------------------- SCENE World ---------------------------------
ResConfig.SceneWorld = {
	UI = {"UIMap",},
	Csb2 = {},
	Tex = {},
	Spine = {},
	Armature = {},
	Music = {},
    Func = {"CurrentTeamRes", "PreloadMapRes"},
}

-- 加载共9个CSB(根据公式：每张plist地图数 * (最大plist数 - 1) + 1),每张plist里面有4个地图资源, 最大plist数我们取3()
-- 根据当前章节ID来获取需要加载的CSB
function ResConfig.PreloadMapRes()
    local ret = {Csb2= {}, Tex = {}, Spine = {}, Armature = {}, Music = {}, Cache = {}}

    --更新模型
    StageHelper.updateStageModel()

    -- 第一次进来
    if nil == StageHelper.CurChapter then
        local curStageID = getGameModel():getStageModel():getCurrentComonStageID()
        StageHelper.CurChapter = StageHelper.getChapterByStage(curStageID)
    end
    -- 进入的章节ID
    local chapterID = StageHelper.CurChapter
    if StageHelper.QuickStageId then    -- 指定了快速进入的关卡ID
        chapterID = StageHelper.getChapterByStage(StageHelper.QuickStageId)
    end

    -- 当前地图ID
    local curMapID = math.mod(chapterID, 100)
    -- 最小地图ID
    local minMapID = 1
    -- 最大地图ID
    local chapterType = StageHelper.getChapterType(chapterID)
    local chapterID = StageHelper.getCurrentChapter(chapterType)
    local maxMapID = math.mod(chapterID, 100)
    local conf = getChapterConfItem(chapterID)
    if conf and conf.NextID > 0 then
        maxMapID = math.mod(conf.NextID, 100)
    end

    -- 预加载的第一个地图ID
    local firstMapID = curMapID - 4
    if firstMapID < minMapID then
        firstMapID = minMapID
    end

    -- 预加载的最后一个地图ID
    local lastMapID = curMapID + 4
    if lastMapID > maxMapID then
        lastMapID = maxMapID
    end

    -- 开始加载
    for i = firstMapID, lastMapID do
        local csbMap = "ui_new/w_worldmap/map/Map_" .. i .. ".csb"
        table.insert(ret.Csb2, csbMap)
    end

    return ret
end


ResConfig.UIMap = {
    Csb2 = {main = "ui_new/w_worldmap/WorldMap.csb",
            once = "ui_new/w_worldmap/StageOnece.csb",
            elite = "ui_new/w_worldmap/StageElite.csb",
            boss = "ui_new/w_worldmap/StageBoss.csb",
            board = "ui_new/w_worldmap/StageInfoBar.csb",
            awardstate = "ui_new/w_worldmap/StageAwardState.csb",
            fog = "ui_new/w_worldmap/EliteMaskFog.csb",
            cbtn = "ui_new/w_worldmap/GeneralButton.csb",
            ebtn = "ui_new/w_worldmap/EliteButton.csb",
            chest = "ui_new/g_gamehall/i_instance/ClimbTower/ClimbTower_Chest.csb",
            lock = "ui_new/w_worldmap/map/MapUnlock.csb",
            },
    Tex = {},
}

ResConfig.UIChallenge = {
    Csb2 = {main = "ui_new/w_worldmap/AttackPanel.csb",
            commit = "ui_new/p_public/Button_Confrim.csb",
            cancel = "ui_new/p_public/Button_Cancel.csb",
            attack = "ui_new/w_worldmap/AttackButton.csb",
            },
    Tex = {},
}

ResConfig.UIChallengeBuy = {
    Csb2 = {main = "ui_new/w_worldmap/AddAttackTipPanel.csb",}
}

ResConfig.UITeam = {
    Csb2 = {main = "ui_new/w_worldmap/TeamSet.csb",
            tab =  "ui_new/g_gamehall/b_bag/AllButton.csb",
            sum = "ui_new/w_worldmap/SummonerIcon.csb",
            hero = "ui_new/w_worldmap/HeroIcon.csb",
            sort = "ui_new/w_worldmap/OrderButton.csb",
            },
    Tex = {},
}

ResConfig.UISweep = {
	Csb2 = {sweep = "ui_new/w_worldmap/SweepPanel.csb",
			awardPanel = "ui_new/w_worldmap/SweepAwardItem.csb",
			overPanel = "ui_new/w_worldmap/SweepOverItem.csb",
			okBtn = "ui_new/g_gamehall/c_collection/ConfirmButton.csb",}
}

ResConfig.UIChapterAward = {
    Csb2 = {main = "ui_new/w_worldmap/StageAward.csb",
            awardItem = "ui_new/g_gamehall/b_bag/AllItem.csb",
            confirmBtn = "ui_new/g_gamehall/c_collection/ConfirmButton.csb",
    },
}

ResConfig.UISettleAccountNormal = {
	Csb2 = {win = "ui_new/f_fight/Fight_Win.csb",
			fail = "ui_new/f_fight/Fight_Failure.csb",
			awardGold = "ui_new/f_fight/AwardGoldPanel.csb",
			awardItem = "ui_new/f_fight/AwardItem.csb",
			failEffect = "ui_new/f_fight/FailureEffect.csb",
			getStar = "ui_new/f_fight/GetStar.csb",
			okBtn = "ui_new/g_gamehall/c_collection/ConfirmButton.csb",
			awardSum = "ui_new/f_fight/AwardSummonerEffect.csb",
			heroAgainBtn = "ui_new/g_gamehall/d_drawcard/AgainButtonPanel.csb"},
	Tex =  {}
}

ResConfig.UISettleAccountLose = {
    Csb2 = {fail = "ui_new/f_fight/Fight_Failure.csb",
            okBtn = "ui_new/g_gamehall/c_collection/ConfirmButton.csb"}
}

ResConfig.UIHeroCardBag = {
    Csb2 = {cardBag = "ui_new/g_gamehall/c_card/CardBag.csb",
            cardItem = "ui_new/g_gamehall/c_card/HeroCard.csb",
            line = "ui_new/g_gamehall/c_card/CardBag_DivideLine.csb"},
}

ResConfig.UIHeroInfo = {
    Csb2 = {heroInfo = "ui_new/g_gamehall/c_card/HeroInfo.csb",
            eqInfo = "ui_new/g_gamehall/c_card/EquipInfoPanel.csb"}
}

ResConfig.UILookHeroInfo = {
    Csb2 = {heroInfo = "ui_new/g_gamehall/c_card/HeroInfo.csb",
            eqInfo = "ui_new/g_gamehall/c_card/EquipInfoPanel.csb"}
}

ResConfig.UIPropQuickTo = {
	Csb2 = {meterial = "ui_new/g_gamehall/c_collection/GetPropPath.csb",
            stageItem = "ui_new/g_gamehall/c_collection/StagePathBar.csb",
            shopItem = "ui_new/g_gamehall/c_collection/ShopPathBar.csb"},
    Tex = {"ui_new/w_worldmap/map/thumbnail.plist"}
}

ResConfig.UITaskAchieve = {
	Csb2 = {taskAchieve = "ui_new/g_gamehall/t_task/Task.csb",
			taskItem = "ui_new/g_gamehall/t_task/TaskBar.csb",
			taskAward1 = "ui_new/g_gamehall/t_task/MoneyItem.csb",
			taskAward2 = "ui_new/g_gamehall/t_task/TaskAwardItem.csb",
			achieveItem = "ui_new/g_gamehall/t_task/AchieveBar.csb",},
}

ResConfig.UIAward = {
	Csb2 = {award = "ui_new/g_gamehall/t_task/Award.csb",
			item = "ui_new/g_gamehall/t_task/AwardItem_E.csb",},
}


------------------------------ SCENE Union begin ---------------------------------
ResConfig.SceneUnion = {
	UI = {"UIUnion", "UIUnionHall",},
	Csb2 = {},
	Tex = {"ui_new/g_gamehall/g_guild/guildmap.plist"},
	Spine = {},
	Armature = {},
	Music = {},
	-- 需要使用函数动态生成资源
	Func = {},
	-- 该场景离开时不释放的资源类型
	Cache = {},
}

ResConfig.UIUnionList = {
    Csb2 = {list = "ui_new/g_gamehall/g_guild/Guild.csb",
            item = "ui_new/g_gamehall/g_guild/GuildBar.csb",}
}

ResConfig.UIUnionCreate = {
    Csb2 = {create = "ui_new/g_gamehall/g_guild/SetGuildTip.csb",}
}

ResConfig.UIUnion = {
    Csb2 = {union = "ui_new/g_gamehall/g_guild/GuildMap.csb",
			TalkButton = "ui_new/g_gamehall/g_gpub/TalkButton.csb",
            Record = "ui_new/g_gamehall/c_chat/RecordTimeButton.csb"},
}

ResConfig.UIUnionHall = {
    Csb2 = {hall = "ui_new/g_gamehall/g_guild/guildinfo/Guild.csb",
            onlineItem = "ui_new/g_gamehall/g_guild/guildinfo/Online_MembersBar.csb",
            allItem = "ui_new/g_gamehall/g_guild/guildinfo/Guild_MembersBar.csb",
            activeItem = "ui_new/g_gamehall/g_guild/guildinfo/Guild_WealBar.csb",
            activeSItem = "ui_new/g_gamehall/g_guild/guildinfo/Guild_WealBar.csb",
            auditItem = "ui_new/g_gamehall/g_guild/guildinfo/Guild_NewReviewBar.csb",
            func = "ui_new/g_gamehall/g_guild/guildinfo/ChairmanButton.csb"}
}

ResConfig.UIUnionReEmblem = {
    Csb2 = {main = "ui_new/g_gamehall/g_guild/guildinfo/ChooseLogo.csb",
            emblem = "ui_new/g_gamehall/g_guild/guildinfo/GuildLogoItem.csb", }
}

ResConfig.UIUnionReName = {
    Csb2 = {main = "ui_new/g_gamehall/g_guild/guildinfo/ChangeName.csb",}
}

ResConfig.UIUnionReNotice = {
    Csb2 = {main = "ui_new/g_gamehall/g_guild/guildinfo/ChangeBoard.csb",}
}

ResConfig.UIAuditSet = {
    Csb2 = {auditSet = "ui_new/g_gamehall/g_guild/guildinfo/ReviewSet.csb"}
}

ResConfig.UIUnionMercenaryRule = {
    Csb2 = {GeneralRule = "ui_new/g_gamehall/a_arena/GeneralRule.csb"}   
}

--公会佣兵主界面
ResConfig.UIUnionMercenary = {
    Csb2 = {root = "ui_new/g_gamehall/g_guild/mercenary/MercenaryBag.csb",
            MercenaryBar_Guild =  "ui_new/g_gamehall/g_guild/mercenary/MercenaryBar_Guild.csb",
            MercenaryBar_Self =  "ui_new/g_gamehall/g_guild/mercenary/MercenaryBar_Self.csb",
            SendButton =  "ui_new/g_gamehall/g_guild/mercenary/SendButton.csb",
            UIUnionMercenaryYes = "ui_new/g_gamehall/g_gpub/TipPanel.csb",
            GeneralRule = "ui_new/g_gamehall/a_arena/GeneralRule.csb"
            }
}

--公会佣兵详细信息界面
ResConfig.UIUnionMercenaryInfo = {
    Csb2 = {heroInfo = "ui_new/g_gamehall/c_card/HeroInfo.csb",
            eqInfo = "ui_new/g_gamehall/c_card/EquipInfoPanel.csb"}
}

--公会佣兵派遣时调用面.抄别人的啦 !
ResConfig.UIUnionHeroCard = {
    Csb2 = {cardBag = "ui_new/g_gamehall/c_card/CardBag.csb",
            cardItem = "ui_new/g_gamehall/c_card/HeroCard.csb",
            line = "ui_new/g_gamehall/c_card/CardBag_DivideLine.csb"},
}

ResConfig.UIExpeditionWorld = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/ExpedMap.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionAreaSet = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/ExpedTipPanel.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionArea = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/ExpedMap_Island.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionChallenge = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/Exped_AttackPanel.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionHelpTips = {
    Csb2 = {
            main = "ui_new/s_story/TalkPanel_R.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionRanking = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/HurtsRanking.csb",
            rankItem = "ui_new/g_gamehall/g_guild/expedmap/RankingBar.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionDiary = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/DiaryPaper.csb",
    },
    Tex = {},
}

ResConfig.UIExpeditionDiaryIslandIntro = {
    Csb2 = {
        main = "ui_new/g_gamehall/g_guild/expedmap/DiaryPaper_IslandIntro.csb",
        item = "ui_new/g_gamehall/g_guild/expedmap/IslandEnemy.csb"
    },
}

ResConfig.UIExpeditionEnemyIntro = {
    Csb2 = {
        main = "ui_new/g_gamehall/g_guild/expedmap/DiaryPaper_EnemyIntro.csb",
    },
}

------------------------------ SCENE Union end ---------------------------------

ResConfig.UIEquipBag = {
    Csb2 = {eqBag = "ui_new/g_gamehall/c_card/EquipChoose.csb",
            item = "ui_new/g_gamehall/c_collection/EqItem.csb"}
}

ResConfig.UIDialogBox = {
    Csb2 = {dialog = "ui_new/g_gamehall/g_gpub/TipPanel.csb"}
}

ResConfig.UIRank = {
    Csb2 = {rank = "ui_new/g_gamehall/i_instance/Ranking.csb",
            typeItem = "ui_new/g_gamehall/g_gpub/SetButton.csb",
            rankItem = "ui_new/g_gamehall/i_instance/ClimbTower/RankingItem.csb"}
}

ResConfig.UITowerRankDesc = {
      Csb2 = {desc = "ui_new/g_gamehall/g_gpub/NoticePanel.csb",}
}

-- 根据房间的玩家模型和关卡ID找到应该加载的资源列表
function ResConfig.BattleResByRoom()
    print("BattleResByRoom")
    local ret = {Csb2= {}, Tex = {}, Spine = {},
            Armature = {}, Music = {}, Cache = {}}
    local room = getGameModel():getRoom()
    if room == nil then
        return ret
    end

    local resIds = {}
    -- 1.获取关卡的资源
    local stageConf = getStageConfItem(room:getStageId())
    -- （PVP可能不走关卡）
    if stageConf then
        -- 获取关卡Monster的资源
        for k,v in ipairs(stageConf.Monsters) do
            print("Monster" .. v)
            local monsterRes = getResIDsByIDStar(v, 0)
            if monsterRes == nil then
                print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上怪物资源了" .. v)
                resInfo.fuck()
            end
            for _,id in ipairs(monsterRes.ResIDs) do
                resIds[id] = true
            end
            for _, musicRes in ipairs(monsterRes.MusicRess) do
                table.insert(ret.Music, musicRes)
            end
        end
        -- 获取关卡BOSS的资源
        if stageConf.Boss > 0 then
            print("Boss" .. stageConf.Boss)
            local bossRes = getResIDsByIDStar(stageConf.Boss, 0)
            if bossRes == nil then
                print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上BOSS资源了" .. stageConf.Boss)
                resInfo.fuck()
            end
            for _,id in ipairs(bossRes.ResIDs) do
                resIds[id] = true
            end
            for _, musicRes in ipairs(bossRes.MusicRess) do
                table.insert(ret.Music, musicRes)
            end
        end

        -- 获取关卡场景召唤物资源
        for i,v in ipairs(stageConf.SceneCall or {}) do
            local callRes = getResIDsByIDStar(v.callID, 0)
            if callRes == nil then
                print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上召唤物资源了" .. v.callID)
                resInfo.fuck()
            end
            for _,id in ipairs(callRes.ResIDs) do
                resIds[id] = true
            end
            for _, musicRes in ipairs(callRes.MusicRess) do
                table.insert(ret.Music, musicRes)
            end
        end

        -- 获取关卡背景资源
        local stageSceneConf = getStageSceneConfItem(stageConf.StageSenceID)
        if stageSceneConf then
            table.insert(ret.Csb2, stageSceneConf.FrontScene_ccs)
            table.insert(ret.Csb2, stageSceneConf.FightScene_ccs)
            table.insert(ret.Csb2, stageSceneConf.BgScene_ccs)
            table.insert(ret.Csb2, stageSceneConf.FarScene_ccs)
        end
    end

    -- 2.获取Player的资源
    local allPlayer = room:getPlayers()
    for k,player in pairs(allPlayer) do
        -- 获取英雄（士兵）的资源
        if 0 ~= player:getUserId() then
            local heros = player:getSoldiers()
            local heroCount = #heros - 1
            print("herocount" .. heroCount)
            for i = 0, heroCount do
                local heroInfo = player:getSoldierInfo(i)
                print("HeroId, HeroStar" .. tonumber(heroInfo.Id) .. " " .. tonumber(heroInfo.Star))
                local soldierRes = getResIDsByIDStar(tonumber(heroInfo.Id), tonumber(heroInfo.Star))
                if soldierRes == nil then
                    print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上士兵资源了" .. tonumber(heroInfo.Id) .. " " .. tonumber(heroInfo.Star))
                    resInfo.fuck()
                end
                for _,id in ipairs(soldierRes.ResIDs) do
                    resIds[id] = true
                end
                for _, musicRes in ipairs(soldierRes.MusicRess) do
                    table.insert(ret.Music, musicRes)
                end
            end
            -- 获取召唤师的资源
            print("Summoner"..player:getHeroId())
            local summonerRes = getResIDsByIDStar(player:getHeroId(), 0)
            if summonerRes == nil then
                print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上召唤师资源了" .. player:getHeroId())
                resInfo.fuck()
            end
            for _,id in ipairs(summonerRes.ResIDs) do
                resIds[id] = true
            end
            for _, musicRes in ipairs(summonerRes.MusicRess) do
                table.insert(ret.Music, musicRes)
            end
        end
    end

    -- 3.关卡的战斗场景资源
    local commRes = getResIDsByIDStar(0, 0)
    if commRes == nil then
        print("操操操，Fuck You，大策划，你忘记在ResPreload.csv里面配上公共资源了0_0!")
        resInfo.fuck()
    end
    for _,id in ipairs(commRes.ResIDs) do
        resIds[id] = true
    end

    -- 4.找到ResPath对应的资源
    print("Debug BattleResByRoom")
    for k,v in pairs(resIds) do
        print(k)
        local resInfo = getResPathInfoByID(k)
        if resInfo == nil then
            print("操操操，Fuck You，大策划，你忘记在Res.csv里面配上角色资源了" .. k)
            resInfo.fuck()
        else
            if resInfo.ResType == 1 then
                -- Armature
                table.insert(ret.Armature, resInfo.Path)
                print("Armature " .. resInfo.Path)
            elseif resInfo.ResType == 2 then
                -- Spine
                ret.Spine[resInfo.Path] = resInfo.AtlasPath
                print("Spine " .. resInfo.Path)
            elseif resInfo.ResType == 3 then
                -- CSB2.0
                table.insert(ret.Csb2, resInfo.Path)
                print("Csb2 " .. resInfo.Path)
            end
        end
    end
    return ret
end

---------------------------- SCENE Battle ---------------------------------
ResConfig.SceneBattle = {
    UI = {},
    Func = { "BattleResByRoom" },
    Cache = {},
}

ResConfig.SceneReplayBattle = ResConfig.SceneBattle

ResConfig.UIGoldTestWin = {
    Csb2 = {main = "ui_new/g_gamehall/i_instance/GoldTrial_FightOver.csb",}
}

ResConfig.UIHeroTestWin = {
    Csb2 = {main = "ui_new/g_gamehall/i_instance/HeroTrial_FightWin.csb",
            star = "ui_new/f_fight/GetStar.csb",
            awardItem = "ui_new/g_gamehall/b_bag/AllItem.csb"}
}

ResConfig.UITowerTestWin = {
    Csb2 = {main = "ui_new/g_gamehall/i_instance/ClimbTower_FightWin.csb",
            star = "ui_new/f_fight/GetStar.csb"}
}

ResConfig.UIArenaAccount = {
     Csb2 = {arenaFailure = "ui_new/g_gamehall/a_arena/Arena_Failure.csb",
             arenaWin     = "ui_new/g_gamehall/a_arena/Arena_Win.csb",
             arenaDogfall = "ui_new/g_gamehall/a_arena/Arena_Dogfall.csb"}
}

ResConfig.UIExpeditionWin = {
    Csb2 = {
            main = "ui_new/g_gamehall/g_guild/expedmap/Exped_FightOver.csb",
    },
    Tex = {},
}

ResConfig.UIReplayAccount = {
     Csb2 = {main = "ui_new/g_gamehall/r_replay/Replay_Result.csb"}
}

---------------------------- SCENE Pvp ---------------------------------
ResConfig.ScenePvp = {
    UI = { "UIArenaMatch", "UIReconnect" },
    Csb2 = {readyGo = "ui_new/f_fight/ReadyGo.csb"},
	Tex = {},
	Spine = {},
	Armature = {},
	Music = {},
    Func = {},
    Cache = { ResConfig.ResType.Armature, ResConfig.ResType.Spine },
}

ResConfig.UIArenaMatch = {
     Csb2 = {playerHead         = "ui_new/g_gamehall/a_arena/Arena_PlayerHead.csb",
             arenaMatching      = "ui_new/g_gamehall/a_arena/ArenaMatching.csb",
             loadingLine        = "ui_new/g_gamehall/a_arena/LoadingLine.csb",
             reconnect          = "ui_new/g_gamehall/a_arena/ArenaReconnect.csb",
             },
}

ResConfig.UIReconnect = {
    --Csb2 = {mainPanel = "ui_new/g_gamehall/a_arena/ArenaReconnect.csb"}
}

ResConfig.UIEquipMake = {
        Csb2 = { SmithShop = "ui_new/g_gamehall/s_smith/SmithShop.csb",
            ViewPanel     = "ui_new/g_gamehall/s_smith/ViewPanel.csb",
            BreakPanel = "ui_new/g_gamehall/s_smith/BreakPanel.csb",
            MakePanel = "ui_new/g_gamehall/s_smith/MakePanel.csb",
            PropBar = "ui_new/g_gamehall/s_smith/PropBar.csb",
            QuestionPanel = "ui_new/g_gamehall/s_smith/QuestionPanel.csb",
            ViewPanel = "ui_new/g_gamehall/s_smith/ViewPanel.csb",
            AttriBar  = "ui_new/g_gamehall/s_smith/AttriBar.csb",
            PropItem = "ui_new/g_gamehall/s_smith/PropItem.csb",
            Tips = "ui_new/g_gamehall/s_smith/BreakTips.csb",
            Forging = "ui_new/g_gamehall/s_smith/Forging.csb",
        }
}

ResConfig.UISevenCrazy = {
        Csb2 = {root =         "ui_new/g_gamehall/o_operate/s_sevenday/SevenDay.csb",
                view =         "ui_new/g_gamehall/o_operate/s_sevenday/AwardView.csb",
                AwardItem =    "ui_new/g_gamehall/o_operate/s_sevenday/AwardItem.csb",  
                TabButton =    "ui_new/g_gamehall/o_operate/s_sevenday/TabButton.csb",
                PropItem =     "ui_new/g_gamehall/o_operate/s_sevenday/PropItem.csb",
                TaskItem =     "ui_new/g_gamehall/o_operate/s_sevenday/TaskItem.csb",
                TabPanel_2 =   "ui_new/g_gamehall/o_operate/s_sevenday/TabPanel_2.csb",
                TabPanel_1 =   "ui_new/g_gamehall/o_operate/s_sevenday/TabPanel_1.csb",
        }
}

ResConfig.UIBlueGem = {
        Csb2 = {root = "ui_new/g_gamehall/o_operate/t_tencent/TencentVip.csb",
                everyDayItem = "ui_new/g_gamehall/o_operate/t_tencent/EveryDay_AwardItem.csb",
                growUpItem = "ui_new/g_gamehall/o_operate/t_tencent/GrowUp_AwardItem.csb",
                awardItem = "ui_new/g_gamehall/b_bag/AllItem.csb",
        }
}

ResConfig.UICommonHall = {
        Csb2 = {root = "ui_new/g_gamehall/o_operate/t_tencent/QQGameVip.csb",
                growUpItem = "ui_new/g_gamehall/o_operate/t_tencent/QQGame_GrowUp_AwardItem.csb",
                AllItem = "ui_new/g_gamehall/b_bag/AllItem.csb",
                AwardItem = "ui_new/g_gamehall/o_operate/t_tencent/AwardItem.csb",
        }
}

return ResConfig