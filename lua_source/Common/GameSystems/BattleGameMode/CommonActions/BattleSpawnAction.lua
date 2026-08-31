local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSpawnAction = luaclass("BattleSpawnAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local SpawnerSystem = require("SpawnerSystem")
local BattleTriggerHelper = require("BattleTriggerHelper")
local BattleNpcHelper = require("BattleNpcHelper")
local SpawnerDef = require("SpawnerDef")

BattleSpawnAction.nSpawnerId = nil
BattleSpawnAction.bAll = nil
BattleSpawnAction.nTriggerId = nil
BattleSpawnAction.nGroupIndex = nil
BattleSpawnAction.bNpc = nil

function BattleSpawnAction:Parse(tbJsonData)
    self.nSpawnerId = tbJsonData.SpawnerId
    self.bAll = tbJsonData.All
    self.nTriggerId = tbJsonData.TriggerId
    self.nGroupIndex = tbJsonData.GroupIndex
    self.nTriggerGroupIndex = tbJsonData.TriggerGroupIndex
    self.nFogGroupIndex = tbJsonData.FogGroupIndex
    self.bNpc = tbJsonData.Npc
    if(self.bNpc) then
        BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    end
    return true
end

function BattleSpawnAction:Execute()
    local tbRet = nil
    if(self.bNpc == true) then
        BattleOperationHelper:PrintLog(self, "Npc: "..BattleNpcHelper:GetIdentifierInfo(self))
        tbRet = {}
        local tbAll = SpawnerSystem:GetAllSpawners()
        for nId, Spawner in pairs(tbAll) do
            if(BattleNpcHelper:CheckIdentifier(self, Spawner, true)) then
                local Object = SpawnerSystem:Spawn(Spawner)
                if(Object) then
                    table.insert(tbRet, Object)
                end
            end
        end
    elseif(self.nSpawnerId ~= nil and self.nSpawnerId > 0) then
        BattleOperationHelper:PrintLog(self, "SpawnerId: "..self.nSpawnerId)
        tbRet = SpawnerSystem:SpawnById(self.nSpawnerId)
    -- elseif(self.nTriggerId ~= nil) then
    --     -- 因为历史原因，这里没用spawnersystem。。
    --     BattleOperationHelper:PrintLog(self, "TriggerId: "..self.nTriggerId)
    --     tbRet = BattleTriggerHelper:SpawnTrigger(self.nTriggerId)
    elseif(self.nTriggerId ~= nil and self.nTriggerId > 0) then
        BattleOperationHelper:PrintLog(self, "TriggerId: "..self.nTriggerId)
        tbRet = SpawnerSystem:SpawnByTriggerId(self.nTriggerId)
    elseif(self.nTriggerGroupIndex ~= nil and self.nTriggerGroupIndex > 0) then
        BattleOperationHelper:PrintLog(self, "TriggerGroupIndex: "..self.nTriggerGroupIndex)
        tbRet = SpawnerSystem:SpawnByGroupIndex(self.nTriggerGroupIndex, SpawnerDef.SpawnerType.TRIGGER)
    elseif (self.nFogGroupIndex ~= nil and self.nFogGroupIndex > 0) then
        BattleOperationHelper:PrintLog(self, "FogGroupIndex: "..self.nFogGroupIndex)
        tbRet = SpawnerSystem:SpawnByGroupIndex(self.nFogGroupIndex, SpawnerDef.SpawnerType.FOG)
    elseif(self.bAll ~= nil) then
        BattleOperationHelper:PrintLog(self, "All")
        tbRet = SpawnerSystem:SpawnAll()
        local tbTriggers = BattleTriggerHelper:SpawnAllTriggers()
        if(tbTriggers) then
            if(tbRet == nil) then
                tbRet = {}
            end
            for i, v in ipairs(tbTriggers) do
                table.insert(tbRet, v)
            end
        end
    else
        BattleOperationHelper:PrintError(self, "All params are invalid.")
        return false
    end

    if(tbRet == nil) then
        BattleOperationHelper:PrintError(self, "Spawn failed")
        return false
    end

    local szType = type(tbRet)
    if (szType == 'table' and (tbRet.ObjectType ~= nil or tbRet[1] ~= nil))
        or (szType == 'boolean' and tbRet == true) then
        return true
    end

    BattleOperationHelper:PrintError(self, "Spawn failed")
    return false
end

return BattleSpawnAction