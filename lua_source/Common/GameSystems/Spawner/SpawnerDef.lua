-----------------------------------------------------
--File Name    : SpawnerDef.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : SpawnerSystem
-----------------------------------------------------
local SpawnerDef = {}

SpawnerDef.SpawnerType = {}
SpawnerDef.SpawnerType.NONE = 0
SpawnerDef.SpawnerType.NPC = 1
SpawnerDef.SpawnerType.RANDOM_NPC = 1<<1
SpawnerDef.SpawnerType.DUMMY = 1<<2
SpawnerDef.SpawnerType.TEAM_NPC = 1<<3
SpawnerDef.SpawnerType.RANDOM_TEMPLATE_NPC = 1<<4
SpawnerDef.SpawnerType.TRIGGER = 1<<5
SpawnerDef.SpawnerType.ITEMDROP = 1<<6
SpawnerDef.SpawnerType.FOG = 1<<7
SpawnerDef.SpawnerType.VEHICLE = 1<<8
SpawnerDef.SpawnerType.HOMELAND_BLOCK = 1<<9
SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT = 1<<10

SpawnerDef.SpawnerType.ALL_NPC = SpawnerDef.SpawnerType.NPC 
    | SpawnerDef.SpawnerType.RANDOM_NPC 
    | SpawnerDef.SpawnerType.TEAM_NPC 
    | SpawnerDef.SpawnerType.RANDOM_TEMPLATE_NPC

SpawnerDef.SpawnerJsonDef = 
{
    ["DungeonNPCSpawners"] = SpawnerDef.SpawnerType.NPC,
    ["DungeonRandomNPCSpawners"] = SpawnerDef.SpawnerType.RANDOM_NPC,
    ['DungeonDummySpawners'] = SpawnerDef.SpawnerType.DUMMY,
    ['DungeonTeamNPCSpawners'] = SpawnerDef.SpawnerType.TEAM_NPC,
    ["DungeonRandomTemplateNPCSpawners"] = SpawnerDef.SpawnerType.RANDOM_TEMPLATE_NPC,
    ["Triggers"] = SpawnerDef.SpawnerType.TRIGGER,
    ["DropGroups"] = SpawnerDef.SpawnerType.ITEMDROP,
    ["Fogs"] = SpawnerDef.SpawnerType.FOG,
    ["Vehicles"] = SpawnerDef.SpawnerType.VEHICLE,
    ["DestructibleObjects"] = SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT,
}

return SpawnerDef
