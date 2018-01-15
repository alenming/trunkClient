--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

StageHelper = {}

function StageHelper.resetUpdate(time)	
    local model = getGameModel():getStageModel()
    model:resetCount(time)
end

return StageHelper
--endregion
