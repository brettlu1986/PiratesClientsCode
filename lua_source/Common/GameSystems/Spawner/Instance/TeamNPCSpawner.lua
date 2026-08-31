local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local TeamNPCSpawner = luaclass("TeamNPCSpawner", SpawnerBaseClass)

local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")

TeamNPCSpawner.tbTeammateIds = nil
TeamNPCSpawner.nCaptainId = 0

local AddObjectToTable = nil

function TeamNPCSpawner:OnCreate(tbParams)
    TeamNPCSpawner.super.OnCreate(self, tbParams)

    self.nType = SpawnerDef.SpawnerType.TEAM_NPC
    self.nCaptainId = tbParams.Captain
    self.nCampType = tbParams.CampType
    self.tbTeammateIds = tbParams.Teammates

    return true
end

AddObjectToTable = function(ObjectOrTable, tbOutRet)
    if(type(ObjectOrTable) == 'table') then
        if(ObjectOrTable.ObjectType ~= nil) then
            -- GameObject
            table.insert(tbOutRet, ObjectOrTable)
        else
            -- List
            local nCount = #ObjectOrTable
            for j=1, nCount do
                AddObjectToTable(ObjectOrTable[j], tbOutRet)
            end
        end
    end
end

function TeamNPCSpawner:Spawn()
    local tbRet = {}
    local CaptainObject = SpawnerSystem:SpawnById(self.nCaptainId)

    if(CaptainObject == nil or CaptainObject.ObjectType == nil) then
        logerror("TeamNPCSpawner spawn failed, can not spawn captain", self.nCaptainId)
        return nil
    end
    table.insert(tbRet, CaptainObject)

    local ObjectOrTable, tbSpawner
    local tbTeammates = self.tbTeammateIds
    local nCount = #tbTeammates
    for i=1, nCount do
        tbSpawner = SpawnerSystem:FindById(tbTeammates[i])
        if(tbSpawner) then
            ObjectOrTable = SpawnerSystem:Spawn(tbSpawner)
            if(ObjectOrTable ~= nil) then
                AddObjectToTable(ObjectOrTable, tbRet)
            else
                logerror("TeamNPCSpawner spawn failed, ", tbTeammates[i])
            end
        else
            logerror("TeamNPCSpawner can not find spawner", tbTeammates[i])
        end
    end

    local Object, BattleAIComponent, BattleCampComponent
    nCount = #tbRet
    for i=1, nCount do
        Object = tbRet[i]
        BattleAIComponent = Object.BattleAIComponent
        if(BattleAIComponent) then
            BattleAIComponent:SetCaptain(CaptainObject)
        end

        BattleCampComponent = Object.BattleCampComponent
        if(BattleCampComponent) then
            BattleCampComponent:SetCampType(self.nCampType)
        end
        Object.nGroupIndex = self.nGroupIndex
    end

    return tbRet
end

return TeamNPCSpawner
