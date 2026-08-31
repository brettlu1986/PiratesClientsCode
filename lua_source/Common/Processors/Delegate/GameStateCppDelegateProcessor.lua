local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local GameStateCppDelegateProcessor = luaclass("GameStateCppDelegateProcessor", CppDelegateProcessorBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")


local function OnGameStateBeginPlay(pGameState)    
    log("OnGameStateBeginPlay")
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_STATE_ON_BEGIN_PLAY, pGameState)
end

local function OnGameStateEndPlay(pGameState)
    log("OnGameStateEndPlay")
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_STATE_ON_END_PLAY, pGameState)
end

function GameStateCppDelegateProcessor:Init()
    GameStateCppDelegateProcessor.super.Init(self)
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameState
    self:Register(DelegateMgr.OnGameStateBeginPlay, OnGameStateBeginPlay)
    self:Register(DelegateMgr.OnGameStateEndPlay, OnGameStateEndPlay)

    return true
end

return GameStateCppDelegateProcessor