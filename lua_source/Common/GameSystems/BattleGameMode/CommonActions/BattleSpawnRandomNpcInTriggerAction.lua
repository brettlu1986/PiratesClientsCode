local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSpawnRandomNpcInTriggerAction = luaclass("BattleSpawnRandomNpcInTriggerAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local SpawnerSystem = require("SpawnerSystem")

BattleSpawnRandomNpcInTriggerAction.nTriggerId = nil
BattleSpawnRandomNpcInTriggerAction.nTemplateId = nil
BattleSpawnRandomNpcInTriggerAction.nCampType = nil
BattleSpawnRandomNpcInTriggerAction.nCount = nil

function BattleSpawnRandomNpcInTriggerAction:Parse(tbJsonData)
    self.nTriggerId = tbJsonData.TriggerId
    self.nTemplateId = tbJsonData.TemplateId
    self.nCampType = tbJsonData.CampType
    self.nCount = tbJsonData.Count
    
    return true
end

local function GetTriggerParams(self)
    local tbAll = SpawnerSystem:GetAllSpawners()
    for nId, Spawner in pairs(tbAll) do
        if Spawner.nTriggerId == self.nTriggerId then
            return Spawner.nRadius, Spawner.nX, Spawner.nY, Spawner.nZ
        end
    end
    return nil
end

local function RandomNpcLocation(nRadius, nX, nY, nZ)
    local nRandomR = math.random(0, nRadius)
    local nRandomAngle = math.random(0, 360)
    local nDiffX = math.ceil(nRandomR * math.cos(math.rad(nRandomAngle)))
    local nDiffY = math.ceil(nRandomR * math.sin(math.rad(nRandomAngle)))
    local nRandomX = nDiffX + nX
    local nRandomY = nDiffY + nY
    return nRandomX, nRandomY, nZ
end


function BattleSpawnRandomNpcInTriggerAction:Execute()
    self.nCount = self.nCount > 1 and self.nCount or 1

    BattleOperationHelper:PrintLog(self, "TriggerId: "..self.nTriggerId..
    " TemplateId: "..self.nTemplateId..
    " CampType: "..self.nCampType..
    " Count: "..self.nCount)
   
    
    
    local nTriggerRadius, nTriggerX, nTriggerY, nTriggerZ = GetTriggerParams(self)

    local tbAll = SpawnerSystem:GetAllSpawners()
    for nId, Spawner in pairs(tbAll) do
        if Spawner.nTemplateId == self.nTemplateId then
            for i = 1, self.nCount do
                Spawner.nX, Spawner.nY, Spawner.nZ = RandomNpcLocation(nTriggerRadius, nTriggerX, nTriggerY, nTriggerZ)
                Spawner.nCampType = self.nCampType
                Spawner.tbCreateParams.CampType = self.nCampType
                SpawnerSystem:Spawn(Spawner)
            end
            break
        end
    end

    return true
end

return BattleSpawnRandomNpcInTriggerAction