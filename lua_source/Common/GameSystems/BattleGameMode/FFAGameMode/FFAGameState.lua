local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local FFAGameState = luaclass("FFAGameState", BattleGameStateBaseClass)
local Proto = require("DungeonRepProtoNames")

function FFAGameState:DefineStepIds()
    FFAGameState.super.DefineStepIds(self)

    self:DefineStepId("nStepId")
end

function FFAGameState:DefineProperties()
    FFAGameState.super.DefineProperties(self)
    self:DefineProtoProperty(Proto.rFFAInfo)
end

return FFAGameState