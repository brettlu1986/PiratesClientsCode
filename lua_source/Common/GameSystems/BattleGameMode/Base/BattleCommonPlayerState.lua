local luaclass = require("luaclass")
local BattlePlayerStateBase = require("BattlePlayerStateBase")    
local BattleCommonPlayerState = luaclass("BattleCommonPlayerState", BattlePlayerStateBase)

local Proto = require("DungeonRepProtoNames")


function BattleCommonPlayerState:DefineProperties()
    BattleCommonPlayerState.super.DefineProperties(self)
    self:DefineProtoProperty(Proto.rReviveInfoAndShow)
end


return BattleCommonPlayerState