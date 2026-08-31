local luaclass              = require("luaclass")
local BattleActionBase      = require("BattleActionBase")
local BattleSpawnLocalDummy = luaclass("BattleSpawnLocalDummy", BattleActionBase)
local BattleBlackboard      = require("BattleBlackboard")
local BattleOperationHelper = require("BattleOperationHelper")  
local SpawnerSystem         = require("SpawnerSystem")
local SpawnerDef            = require("SpawnerDef")
local BattleDummyHelper     = require("BattleDummyHelper")
local UEActorHelper         = require("UEActorHelper")

BattleSpawnLocalDummy.nGroupId  = 0
BattleSpawnLocalDummy.szObjKey  = nil

function BattleSpawnLocalDummy:Parse(tbJsonData)    
    BattleSpawnLocalDummy.super.Parse(self, tbJsonData)

    self.nGroupId = tbJsonData.GroupId
    self.szObjKey = tbJsonData.ObjKey

    return true
end

function BattleSpawnLocalDummy:Execute()
    local tbPlayer = nil
    local szObjKey = self.szObjKey

    if szObjKey and string.len(szObjKey) > 0 then
        tbPlayer = BattleBlackboard:GetTable(szObjKey)
    end 
    if tbPlayer == nil then
        BattleOperationHelper:PrintLog(self, "Battle Spawn Dummy, But can not find player from blackboard")
        return false
    end

    local nGroupId = self.nGroupId
    local tbAll = SpawnerSystem:GetAllSpawners()
    for nId, Spawner in pairs(tbAll) do
        if Spawner.nSpawnerType == SpawnerDef.SpawnerType.DUMMY and Spawner.nGroupIndex == nGroupId then
            local tbDummy = SpawnerSystem:Spawn(Spawner)
            UEActorHelper:SetOnlyRelevantToOwner(tbDummy.pUEActor, tbPlayer.pUEActor)
            BattleDummyHelper:AddDummy(nGroupId, tbDummy)
        end
    end

    return true
end


return BattleSpawnLocalDummy