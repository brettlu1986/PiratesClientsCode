local luaclass = require("luaclass")
local LevelCppDelegateProcessorClass = require("LevelCppDelegateProcessor")
local LevelCppDelegateProcesser_C = luaclass("LevelCppDelegateProcessor_C", LevelCppDelegateProcessorClass)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

local function OnMatchDisconnected()
    -- Do nothing
    log("Battle Disconnected")

    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_DISCONNECTED)
end

function LevelCppDelegateProcesser_C:Init()
    LevelCppDelegateProcesser_C.super.Init(self)
    -- Register Gameplay Delegate

    local GameState = ClientShell.GetClient(GWorld):GetGameDelegateManager().GameState

    self:Register(GameState.OnMatchDisconnected, OnMatchDisconnected)

    return true
end

return LevelCppDelegateProcesser_C
