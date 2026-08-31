local luaclass = require("luaclass")
local GameStateCppDelegateProcessorClass = require("GameStateCppDelegateProcessor")
local GameStateCppDelegateProcessor_S = luaclass("GameStateCppDelegateProcessor_S", GameStateCppDelegateProcessorClass)

local BattleGameModeSystem = require("BattleGameModeSystem_S")

local function OnGameStateSerializeNewActor()
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    tbGameMode:SnapshotGameState()
end

function GameStateCppDelegateProcessor_S:Init()
    GameStateCppDelegateProcessor_S.super.Init(self)
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameState

    self:Register(DelegateMgr.OnGameStateSerializeNewActor, OnGameStateSerializeNewActor)
    return true
end

return GameStateCppDelegateProcessor_S