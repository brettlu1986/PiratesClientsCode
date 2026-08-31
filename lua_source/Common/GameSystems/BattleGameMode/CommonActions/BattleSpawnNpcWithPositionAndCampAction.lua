local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSpawnNpcWithPositionAndCampAction = luaclass("BattleSpawnNpcWithPositionAndCampAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local SpawnerSystem = require("SpawnerSystem")
local BattleNpcHelper = require("BattleNpcHelper")
local BattleBlackboard = require("BattleBlackboard")

BattleSpawnNpcWithPositionAndCampAction.bNpc = nil
BattleSpawnNpcWithPositionAndCampAction.szGetObjKey = nil
BattleSpawnNpcWithPositionAndCampAction.nNewCampType = nil

function BattleSpawnNpcWithPositionAndCampAction:Parse(tbJsonData)
    self.bNpc = tbJsonData.Npc
    self.szGetObjKey = tbJsonData.GetObjKey
    self.nNewCampType = tbJsonData.NewCampType
    
    if(self.bNpc) then
        BattleNpcHelper:ParseIdentifier(self, tbJsonData)
    end
    return true
end

function BattleSpawnNpcWithPositionAndCampAction:Execute()
    local tbRet = nil
    local pLocation = nil

    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer then 
            pLocation = tbPlayer:GetLocation()
        end
    end

    if(self.bNpc == true) then
        BattleOperationHelper:PrintLog(self, "Npc: "..BattleNpcHelper:GetIdentifierInfo(self))
        tbRet = {}
        local tbAll = SpawnerSystem:GetAllSpawners()
        for nId, Spawner in pairs(tbAll) do
            if(BattleNpcHelper:CheckIdentifier(self, Spawner, true)) then
                if pLocation then
                    Spawner.nX = pLocation.X
                    Spawner.nY = pLocation.Y
                    Spawner.nZ = pLocation.Z
                    Spawner.nYaw = pLocation.Yaw
                end 
                Spawner.nCampType = self.nNewCampType
                Spawner.tbCreateParams.CampType = self.nNewCampType
                local Object = SpawnerSystem:Spawn(Spawner)
                if(Object) then
                    table.insert(tbRet, Object)                    
                end
            end
        end
    end

    if not (tbRet ~= nil and tbRet[1] ~= nil) then    
        BattleOperationHelper:PrintError(self, "Spawn error")
        return false
    end
    return true
end

return BattleSpawnNpcWithPositionAndCampAction