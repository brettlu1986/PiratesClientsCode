local luaclass = require("luaclass")
local NPCSpawnerClass = require("NPCSpawner")
local RandomTemplatesNPCSpawner = luaclass("RandomTemplatesNPCSpawner", NPCSpawnerClass)

local SpawnerDef = require("SpawnerDef")

function RandomTemplatesNPCSpawner:OnCreate(tbParams)
    local tbTemplateIds = tbParams.TemplateIds
    local nTemplatesCount = #tbTemplateIds
    
    local nRandomIndex = math.random(1, nTemplatesCount)
    tbParams.TemplateId = tbTemplateIds[nRandomIndex]
    RandomTemplatesNPCSpawner.super.OnCreate(self, tbParams)
    
    self.nType = SpawnerDef.SpawnerType.RANDOM_TEMPLATE_NPC

    return true
end

return RandomTemplatesNPCSpawner
