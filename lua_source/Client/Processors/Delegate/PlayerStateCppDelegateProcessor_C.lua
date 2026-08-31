local luaclass = require("luaclass")
local PlayerStateCppDelegateProcessorClass = require("PlayerStateCppDelegateProcessor")
local PlayerStateCppDelegateProcessor_C = luaclass("PlayerStateCppDelegateProcessor_C", PlayerStateCppDelegateProcessorClass)

local EventManager = require("EventManager")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem = require("GameObjectSystem_C")


local function OnPlayerStateEndPlay(pPlayerState)
    local nPlayerId = pPlayerState.PiratePlayerId
    if(nPlayerId < 0) then
        -- Ignore
        return
    end
    
    EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_STATE_ON_END_PLAY, pPlayerState)

    local GameObject = GameObjectSystem:FindPlayerByPlayerId(nPlayerId);
    BattleGameModeSystem:UninitPlayerState(nPlayerId, GameObject)
end

local function OnPostNetInit(pPlayerState)
    local nPlayerId = pPlayerState.PiratePlayerId
    if(nPlayerId < 0) then
        -- Ignore
        return
    end

    local GameObject = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    BattleGameModeSystem:InitPlayerState(nPlayerId, pPlayerState, GameObject)
end

function PlayerStateCppDelegateProcessor_C:Init()
    PlayerStateCppDelegateProcessor_C.super.Init(self)
      
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().PlayerState
    self:Register(DelegateMgr.OnPlayerStateEndPlay, OnPlayerStateEndPlay)
    self:Register(DelegateMgr.OnPostNetInit, OnPostNetInit)
end

return PlayerStateCppDelegateProcessor_C