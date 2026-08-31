local luaclass = require("luaclass")
local BattleCommonPlayerStateBase = require("BattleCommonPlayerState")
local JsonPlayerState = luaclass("JsonPlayerState", BattleCommonPlayerStateBase)

local Proto = require("DungeonRepProtoNames")


function JsonPlayerState:DefineProperties()
    JsonPlayerState.super.DefineProperties(self)
    self:DefineProtoProperty(Proto.rBattleSpecialToast)
end

return JsonPlayerState