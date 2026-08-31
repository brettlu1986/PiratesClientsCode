local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSpawnDummyAction = luaclass("BattleSpawnDummyAction", BattleActionBase)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")
local BattleDummyHelper = require("BattleDummyHelper")
local BattleOperationHelper = require("BattleOperationHelper")

BattleSpawnDummyAction.bOpen = false    -- 阻挡开关
BattleSpawnDummyAction.bGroupId = 0     -- 阻挡开关组标识

function BattleSpawnDummyAction:Parse(tbJsonData)
    self.bOpen = tbJsonData.Open
    self.nGroupId = tbJsonData.GroupId
    return true
end

function BattleSpawnDummyAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "Open: "..(self.bOpen and "true" or "false")..
        ", GroupId: " ..self.nGroupId)

    if self.bOpen then 
        self.tbDummies = self:SpawnDummiesByGroupId(self.nGroupId)
    else
        self:DestoryDummiesByGroupId(self.nGroupId)
    end
    return true
end

function BattleSpawnDummyAction:SpawnDummiesByGroupId(nGroupId)
    local tbAll = SpawnerSystem:GetAllSpawners()
    for nId, Spawner in pairs(tbAll) do
        if Spawner.nSpawnerType == SpawnerDef.SpawnerType.DUMMY and Spawner.nGroupIndex == nGroupId then
            local tbDummy = SpawnerSystem:Spawn(Spawner)
            BattleDummyHelper:AddDummy(nGroupId, tbDummy)
        end
    end
    return true
end

function BattleSpawnDummyAction:DestoryDummiesByGroupId(nGroupId)
    local tbDummies = BattleDummyHelper:GetDummiesByGroupId(nGroupId)
    if tbDummies == nil then 
        return
    end

    for nId, tbDummy in pairs(tbDummies) do
        if tbDummies then 
            GameObjectSystem:DestroyDummyInGameMode(tbDummy:GetUEActorUniqueId())
        end
    end
end


return BattleSpawnDummyAction