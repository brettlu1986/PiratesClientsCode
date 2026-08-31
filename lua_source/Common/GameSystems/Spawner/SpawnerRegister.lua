-----------------------------------------------------
--File Name    : SpawnerRegister.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : SpawnerRegister
-----------------------------------------------------
local SpawnerRegister = {}

local SpawnerDef = require("SpawnerDef")

local SpawnerType = SpawnerDef.SpawnerType

function SpawnerRegister:RegisterAllSpawners(SpawnerSystem)
    SpawnerSystem:Register(SpawnerType.NPC, require("NPCSpawner"))
    SpawnerSystem:Register(SpawnerType.RANDOM_NPC, require("RandomNPCSpawner"))
    SpawnerSystem:Register(SpawnerType.DUMMY, require("DummySpawner"))
    SpawnerSystem:Register(SpawnerType.TEAM_NPC, require("TeamNPCSpawner"))
    SpawnerSystem:Register(SpawnerType.RANDOM_TEMPLATE_NPC, require("RandomTemplatesNPCSpawner"))
    SpawnerSystem:Register(SpawnerType.TRIGGER, require("TriggerSpawner"))
    SpawnerSystem:Register(SpawnerType.ITEMDROP, require("ItemDropSpawner"))
    SpawnerSystem:Register(SpawnerType.FOG, require("FogSpawner"))
    SpawnerSystem:Register(SpawnerType.VEHICLE, require("VehicleSpawner"))
    SpawnerSystem:Register(SpawnerType.HOMELAND_BLOCK, require("HomelandBlockSpawner"))
    SpawnerSystem:Register(SpawnerType.DESTRUCTIBLEOBJECT, require("DestructibleObjectSpawner"))
end

return SpawnerRegister
