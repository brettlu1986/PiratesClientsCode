local luaclass = require("luaclass")
local GameStateCppDelegateProcessorClass = require("GameStateCppDelegateProcessor")
local GameStateCppDelegateProcessor_C = luaclass("GameStateCppDelegateProcessor_C", GameStateCppDelegateProcessorClass)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local DungeonDataTable = require("DungeonDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CppDelegate = require("CppDelegate")

local pOnRepDungeonMode = nil

local function OnGameStateActorChannelOpen(pGameState)
    log("OnGameStateActorChannelOpen")

    local SetDungeonMode = function()
        DungeonDataTable:SetMode(BattleGameModeSystem.nDungeonId, pGameState.DungeonMode)
        local PlayerSelf = GamePlayerSelfHelper:Get()
        PlayerSelf.bDungeonPrepareReady = true
        PlayerSelf:VerifyReplicatedPlayerReady()
        if pOnRepDungeonMode ~= nil then
            pOnRepDungeonMode:Unbind()
            pOnRepDungeonMode = nil
        end
    end
    if pGameState.DungeonMode >= 0 then
        SetDungeonMode()
    else
        pOnRepDungeonMode = CppDelegate:Bind(pGameState.OnRepDungeonMode, function()
            SetDungeonMode()
        end)
    end

    EventManager:OnFireEvent(ClientEventDef.EV_GAME_STATE_ON_ACTOR_CHANNEL_OPEN, pGameState)
end

function GameStateCppDelegateProcessor_C:Init()
    GameStateCppDelegateProcessor_C.super.Init(self)
      
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameState
    self:Register(DelegateMgr.OnGameStateActorChannelOpen, OnGameStateActorChannelOpen)
end

function GameStateCppDelegateProcessor_C:Uninit()
    if pOnRepDungeonMode ~= nil then
        pOnRepDungeonMode:Unbind()
        pOnRepDungeonMode = nil
    end
    GameStateCppDelegateProcessor_C.super.Uninit(self)
end

return GameStateCppDelegateProcessor_C