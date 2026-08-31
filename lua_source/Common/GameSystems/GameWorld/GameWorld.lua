local luaclass = require("luaclass")
local GameWorld = luaclass("GameWorld")


function GameWorld:Create(tbCreateData)
    return true
end

function GameWorld:Destroy()

end

return GameWorld