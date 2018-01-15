--[[
	AnimatePool 用于控制骨骼资源总量的增长，以及加载对应的骨骼资源

	2015-10-31 By 宝爷
]]

AnimatePool = class("AnimatePool")

AnimatePool.HeroAnimation = {"Attack1", "Attack2", "Attack3", "Attack4", "Skill1", "Skill2", "Skill3", "Hit1", "Vertigo1"}
AnimatePool.SummonerAnimation = {"Skill1", "Skill2", "Skill3", "Hit1"}
local Stand = "Stand1"

AnimatePool.AnimateType = {
    Armature = 1,
    Spine = 2
}

-- 超过20个会执行清理的逻辑
AnimatePool.PoolSize = 12

-- 动画资源，用于记录当前使用了哪些骨骼
-- key为资源名，value为{ ref = 资源引用数, type = AnimatePool.AnimateType}
AnimatePool.MainAnimates = {}

-- 
function AnimatePool.AnimateCount()
    local count = 0
    for k,v in pairs(AnimatePool.MainAnimates) do
        if v.ref > 0 then
            count = count + 1
        end
    end
    return count
end

function AnimatePool.setExitCallback(animateNode, path)
    if animateNode then
        print(path .. " setExitCallback ")
        animateNode:addNodeEventListener(cc.NODE_EVENT, function(event)
            if event.name == "cleanup" then
                local newRef = AnimatePool.MainAnimates[path].ref - 1
                AnimatePool.MainAnimates[path].ref = newRef
                print("AnimatePool Recv Event " .. event.name .. " refCount is " .. AnimatePool.MainAnimates[path].ref or 0 .. " " .. path)
           end
        end)
    end
end

-- 清理1个无用的Animate
function AnimatePool.removeUnusedAnimate()
    for k,v in pairs(AnimatePool.MainAnimates) do
        -- 找到一个引用数量为0
        if v.ref <= 0 then
            print("remove Animate " .. k)
            if v.type == AnimatePool.AnimateType.Armature then
                getResManager():removeArmature(k)
            else
                getResManager():removeRes(k)
            end
            break
        end
    end
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end

-- 传入骨骼动画id创建骨骼动画对象，并将对象传入到callback中
function AnimatePool.createAnimate(id, callback)
    if true then
        print("--------------------- dump animate cache -----------------------")
        for k, v in pairs(AnimatePool.MainAnimates) do
            print(k .. " ref Count " .. v.ref)
        end
        print("--------------------- dump animate cache -----------------------")
    end

    -- 获取ResPath.csv，得到这个显示id对应的角色骨骼
    -- 检查池大小，如果超过警戒值则清理无用的资源
    if AnimatePool.AnimateCount() > AnimatePool.PoolSize then
        print("AnimatePool.removeUnusedAnimate()")
        AnimatePool.removeUnusedAnimate()
    end
    
    local resPath = getResPathInfoByID(id)
    if resPath == nil then return end

    local resFile = resPath.Path
    local resAssist = resPath.AtlasPath
    local resSkin = resPath.Skin

    -- 创建骨骼并执行回调
    if resAssist == nil then
        AnimatePool.createArmature(id, resFile, callback)
    else
        AnimatePool.createSpine(id, resFile, resAssist, resSkin, callback)
    end
end

function AnimatePool.createArmature(id, csbFile, callback)
    getResManager():addPreloadRes(csbFile, function(csbFile, success)
            if success then
                armature = ccs.Armature:create(id)
                armature:setName("armature") 
                armature:getAnimation():play(Stand)
                AnimatePool.setExitCallback(armature, csbFile)
                if AnimatePool.MainAnimates[csbFile] == nil then
                    AnimatePool.MainAnimates[csbFile] = { ref = 1, type = AnimatePool.AnimateType.Armature, }
                else
                    AnimatePool.MainAnimates[csbFile].ref = AnimatePool.MainAnimates[csbFile].ref + 1
                    AnimatePool.MainAnimates[csbFile].type = AnimatePool.AnimateType.Armature
                end
            end
            callback(armature, id)
        end)
    getResManager():startResAsyn()
end

function AnimatePool.createSpine(id, jsonFile, atlasFile, resSkin, callback)
    getResManager():addPreloadRes(jsonFile, atlasFile, function(json, success)
        local spine = getResManager():createSpine(json)
        if nil == spine then
            print("getResManager():createSpine is fail, jsonfile and atlasFile:", jsonFile, atlasFile, json, success)
            return
        end

        if resSkin ~= "" then
            spine:setSkin(resSkin)
        end
        spine:setName("spine")
        spine:setAnimation(0, Stand, true)
        AnimatePool.setExitCallback(spine, json)
        callback(spine, id)
        if AnimatePool.MainAnimates[json] == nil then
            AnimatePool.MainAnimates[json] = { ref = 1, type = AnimatePool.AnimateType.Spine, }
        else
            AnimatePool.MainAnimates[json].ref = AnimatePool.MainAnimates[json].ref + 1
            AnimatePool.MainAnimates[json].type = AnimatePool.AnimateType.Spine
        end
    end)
    getResManager():startResAsyn()
end

return AnimatePool