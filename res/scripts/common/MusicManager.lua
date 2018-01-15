--[[
音乐管理器
1、切换界面/场景时切换相关音乐
2、实现界面/场景淡入、淡出的声音效果
3、退出界面淡出音乐后需淡入该界面之前的界面音乐
]]

local AudioEngine = getFMODAudioEngine()
local Scheduler = require("framework.scheduler")
MusicManager = {}
-- 背景音乐
MusicManager.BgMusicCache = {}
MusicManager.FadeSchedule = nil
MusicManager.isPlayMusic = false
MusicManager.commonSound = {fail = 6, unlockBag = 18, flyIn = 30, heroLvUp = 33, confirm = 3
    , matchRoll = 20, matchPlayer = 21, matchLoading = 41, callHero = 42}

--初始化
function MusicManager.init()
    EventManager:addEventListener(GameEvents.EventOpenUIBefore, MusicManager.openUIBefore)
    --EventManager:addEventListener(GameEvents.EventOpenUI, MusicManager.openUI)
    EventManager:addEventListener(GameEvents.EventCloseUI, MusicManager.closeUI)
    EventManager:addEventListener(GameEvents.EventChangeScene, MusicManager.changeScene)
    EventManager:addEventListener(GameEvents.EventBattleOver, MusicManager.battleOver)

    MusicManager.isOpenMusic = cc.UserDefault:getInstance():getBoolForKey("Music_Switch", true)
    if not MusicManager.isOpenMusic then
        MusicManager.MusicVolume = 0
    else
        MusicManager.MusicVolume = 1
    end

    MusicManager.isOpenEffect = cc.UserDefault:getInstance():getBoolForKey("Sound_Switch", true)
    AudioEngine:setOpenEffect(MusicManager.isOpenEffect)
end

function MusicManager.openUIBefore(eventName, uiID)
    local bgMusic = getUIBgMusic(uiID)
    if not bgMusic then
        return
    end

    -- 打开界面音效
    MusicManager.playSoundEffect(bgMusic.EffectID)
    -- 背景音乐
    MusicManager.playBgMusicWithParam(bgMusic.BgMusicID, true, bgMusic.MoodEffect)
end

function MusicManager.openUI(eventName, uiID)
    -- 获取该UI的背景音乐
--    local bgMusic = getUIBgMusic(uiID)
--    if not bgMusic then
--        --print("this uiid no config the bg musicID", uiID)
--        return
--    end

--    MusicManager.playBgMusicWithParam(bgMusic.BgMusicID, true, bgMusic.MoodEffect)
end

function MusicManager.closeUI(eventName, uiID)
    local closeUIBgMusic = getUIBgMusic(uiID)
    if not closeUIBgMusic or closeUIBgMusic.BgMusicID <= 0 then
        return
    end

    local curBgMusicIndex = #MusicManager.BgMusicCache
    if curBgMusicIndex <= 0 then
        return
    end

    -- 最后一个背景音乐就是当前退出的界面
    local preBgMusic = MusicManager.BgMusicCache[curBgMusicIndex - 1]
    if preBgMusic then
        MusicManager.playBgMusicWithParam(preBgMusic.bgMusicID, false, preBgMusic.param)
    end

    table.remove(MusicManager.BgMusicCache, curBgMusicIndex)
end

function MusicManager.changeScene(eventName)
    MusicManager.isPlayMusic = false
    AudioEngine:stopBackgroundMusic()
    -- 切换场景清空
    MusicManager.BgMusicCache = {}
end

function MusicManager.battleOver(eventName, result)
    if 1 == result then
        MusicManager.playBgMusic(4)
    else
        MusicManager.playBgMusic(5)
    end
end

-- 淡入淡出声音
function MusicManager.playBgMusic(musicID, isCache)
    MusicManager.playBgMusicWithParam(musicID, isCache, nil)
end

function MusicManager.playBgMusicWithParam(musicID, isCache, param)
    if not musicID then
        print("play the bg music, but the musicID is nil")
        return
    end

    local bgMusicConf = getBgMusic(musicID)
    if not bgMusicConf then
        --print("this musicID no config the bg music", musicID)        
        return
    end

    -- 如果还有淡出淡入效果没处理完,强制中断
    if MusicManager.FadeSchedule then
        Scheduler.unscheduleGlobal(MusicManager.FadeSchedule)
    end
    
    if MusicManager.isOpenMusic then
        if not MusicManager.isPlayMusic then
            MusicManager.isPlayMusic = true
            -- 执行淡入
            MusicManager.fadeInMusic(bgMusicConf, param)
        else
            local curBgMusicID, _ = MusicManager.getCurBgMusic()
            if (curBgMusicID == musicID or musicID <= 0) and type(param) == "table" then
                -- 同个背景音乐不变,氛围参数可能不同
                MusicManager.setMusicParam(param[1], tonumber(param[2]))
            else
                -- 执行淡出
                MusicManager.fadeOutMusic(getBgMusic(curBgMusicID), bgMusicConf, param)
            end
        end
    end

    if isCache then
        table.insert(MusicManager.BgMusicCache, {bgMusicID = musicID, param = param})
    end
end

-- 淡入声音
function MusicManager.fadeInMusic(fadeInMusicConf, param)
    if not fadeInMusicConf then
        --print("no fade in music")
        return
    end
    
    -- 最大声音为当前设置
    local musicVolume = MusicManager.MusicVolume
    -- 播放音乐
    AudioEngine:playMusic(fadeInMusicConf.FileName)
    if type(param) == "table" then
        MusicManager.setMusicParam(param[1], tonumber(param[2]))
    end

--    if fadeInMusicConf.IsRepeate == 1 then
--        -- FMOD设置
--    end
    
    -- 需要淡入
    if fadeInMusicConf.FadeInTime > 0 then
        AudioEngine:setMusicVolume(0)
        local it = 0
        MusicManager.FadeSchedule = Scheduler.scheduleGlobal(function(dt)
            it = it + dt
            if it >= fadeInMusicConf.FadeInTime then
                Scheduler.unscheduleGlobal(MusicManager.FadeSchedule)
            else
                -- 声音从0到最大
                local volume = it * musicVolume / fadeInMusicConf.FadeInTime
                AudioEngine:setMusicVolume(volume >= musicVolume and musicVolume or volume)
            end
        end, 0.2)
    else
        AudioEngine:setMusicVolume(musicVolume)
    end
end

-- 淡出声音
function MusicManager.fadeOutMusic(fadeOutMusicConf, fadeInMusicConf, param)
    if not fadeOutMusicConf then
        --print("no fade out music, fade in music")
        MusicManager.fadeInMusic(fadeInMusicConf)
        return
    end
    
    -- 需要淡出
    if fadeOutMusicConf.FadeOutTime > 0 then
        local ot = 0
        MusicManager.FadeSchedule = Scheduler.scheduleGlobal(function(dt)
            ot = ot + dt
            if ot >= fadeOutMusicConf.FadeOutTime then
                Scheduler.unscheduleGlobal(MusicManager.FadeSchedule)
                --print("fade out music end, fade in music")
                MusicManager.fadeInMusic(fadeInMusicConf, param)
            else
                -- 声音从最大(当前音量)到0
                local volume = AudioEngine:getMusicVolume() * ot / fadeOutMusicConf.FadeOutTime
                AudioEngine:setMusicVolume(volume <= 0 and 0 or volume)
            end
        end, 0.15)
    else
        AudioEngine:setMusicVolume(0)
        MusicManager.fadeInMusic(fadeInMusicConf, param)
    end
end

-- 播放当前背景音乐
function MusicManager.playCurBgMusic()
    if not MusicManager.isOpenMusic then
        return
    end

    local bgMusicId, param = MusicManager.getCurBgMusic()
    MusicManager.playBgMusicWithParam(bgMusicId, false, param)
end

-- 停止背景音乐
function MusicManager.stopBgMusic()
    if MusicManager.FadeSchedule then
        Scheduler.unscheduleGlobal(MusicManager.FadeSchedule)
    end

    if not MusicManager.isOpenMusic then
        return
    end

    AudioEngine:stopBackgroundMusic()
end

function MusicManager.setOpenMusic(isOpen)
    MusicManager.isOpenMusic = isOpen

    if isOpen then
        MusicManager.MusicVolume = 1
        local bgMusicId, param = MusicManager.getCurBgMusic()
        MusicManager.playBgMusicWithParam(bgMusicId, false, param)
    else
        MusicManager.MusicVolume = 0
        AudioEngine:stopBackgroundMusic()
        MusicManager.isPlayMusic = false
    end
end

function MusicManager.setOpenEffect(isOpen)
    MusicManager.isOpenEffect = isOpen
    AudioEngine:setOpenEffect(isOpen)
end

-- effect为音效Id或者为音效名
function MusicManager.playSoundEffect(effect)
    --print("********************************", effect)
    local path = nil
    if type(effect) == "number" then
        path = getUISoundEffectPath(effect)
    elseif type(effect) == "string" then
        path = getButtonEffectPath(effect)
    else
        return -1
    end

    return MusicManager.playEffect(path)
end

function MusicManager.playEffect(path)
    if not path then
        return -1
    end

    if not MusicManager.isOpenEffect then
        return 0
    end

    return AudioEngine:playEffect(path)
end

function MusicManager.stopEffect(effectid)
    if not effectid or type(effectid) ~= "number" then
        return
    end

    AudioEngine:stopEffect(effectid)
end

function MusicManager.playFailSoundEffect()
    return MusicManager.playSoundEffect(MusicManager.commonSound.fail)
end

function MusicManager.playGuideSound(id)
    return MusicManager.playEffect(getGuideMusicPath(id))
end

function MusicManager.setMusicParam(paramName, paramVal)
    if not MusicManager.isPlayMusic then
        return
    end

    if type(paramName) == "string" and type(paramVal) == "number" then
        AudioEngine:setMusicParam(paramName, paramVal)
    end
end

function MusicManager.getCurBgMusic()
    local size = #MusicManager.BgMusicCache
    if size > 0 then
        local curBgMusic = MusicManager.BgMusicCache[size]
        return curBgMusic.bgMusicID, curBgMusic.param
    end
end

return MusicManager