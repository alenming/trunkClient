
local Helper = require("Helper")
local EmptyScene = class("EmptyScene", function()
    return display.newScene("EmptyScene")
end)

function EmptyScene:ctor()

end

return EmptyScene