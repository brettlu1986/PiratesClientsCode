local luaclass = require("luaclass")
local GameCoreALSimple = luaclass("GameCoreALSimple")

GameCoreALSimple.nTotolCount = 0

function GameCoreALSimple:GetLevel(tbGameObject)
    self.nTotolCount = self.nTotolCount + 1
    if self.nTotolCount <= 20 then
        return 3
    end
    if (self.nTotolCount - 20) % 3 ~= 0 then
        return 2
    end
    return 1
end

function GameCoreALSimple:Init()
    self.nTotolCount = 0
end

return GameCoreALSimple