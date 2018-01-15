--[[
回放战斗相关回调
]]

local ReplayBattle = {}

--请求进入战斗网络回调
function ReplayBattle:onBattleStart(mainCmd, subCmd, bufferData)
--    print("ReplayBattle:Battle Start ......")
--    -- 初始化房间
--    openAndinitRoom(bufferData)
--    -- 跳转战斗界面
--    SceneManager.loadScene(SceneManager.Scene.SceneReplayBattle)
--    -- 设置结束回调
--    if BattleHelper.finishCallback then
--        print("ReplayBattle:onBattleStart set finish callback, but finishCallback NOT nil!")
--    end
    BattleHelper.finishCallback = handler(self, self.onBattleOver)	
end

--战斗结束本地回调
function ReplayBattle:onBattleOver()
    print("ReplayBattle:Battle Over ......")
    UIManager.open(UIManager.UI.UIReplayAccount)
end

return ReplayBattle
