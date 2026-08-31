local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")

local EngineSettingSystem = {}
EngineSettingSystem.tbActors = nil

local function OnParachutionEnd(self)
    local szClass = "Class'/Game/Game/OtherObject/Optimization/BP_OnLanding.BP_OnLanding_C'"
    local pActor = EngineExtActorShell.SpawnActorForScript(GWorld, szClass:load(), Transform(), nil)
    if isvalidhandle(pActor) then
        table.insert(self.tbActors, pActor)
    end
end

function EngineSettingSystem:OnDungeonAndPlayerState()
    OnParachutionEnd(self)
end

function EngineSettingSystem:Init()
    self.tbActors = {}
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, OnParachutionEnd)

    return true
end

function EngineSettingSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil

    for i, v in ipairs(self.tbActors) do
        if isvalidhandle(v) then
            EngineExtActorShell.DestroyActor(GWorld, v, false)
        end    
    end
    self.tbActors = nil
end

return EngineSettingSystem