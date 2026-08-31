local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local FogSpawner = luaclass("FogSpawner", SpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameTrigger = dynamic_require("GameTrigger")
local SpawnerDef = require("SpawnerDef")
local FogDataTable = require("FogDataTable")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local FOG_RES_ID = 25
local ECollisionType_ALL = 2

--[[
    SpawnerBase.nType = nil
    SpawnerBase.tbCreateParams = nil
    SpawnerBase.bAutoSpawn = false
    SpawnerBase.bAutoDestroy = false
    SpawnerBase.nSpawnerId = nil
    SpawnerBase.nX = nil
    SpawnerBase.nY = nil
    SpawnerBase.nZ = nil
    SpawnerBase.nYaw = nil
    SpawnerBase.tbListeners = nil
    SpawnerBase.nGroupIndex = nil
    SpawnerBase.nSubGroupIndex = nil
]]

-- tbParams 为JsonData
function FogSpawner:OnCreate(tbParams)
    FogSpawner.super.OnCreate(self, tbParams)
    self.nType = SpawnerDef.SpawnerType.FOG
    
    local tbCreateData = {tbJsonData = self.tbCreateParams}
    local tbShape = {}
    tbCreateData.tbJsonData.Shape = tbShape 
    tbShape.Type = 0
    tbShape.Radius = tbParams.Radius

    tbCreateData.tbJsonData.CollisionType = ECollisionType_ALL
    tbCreateData.tbJsonData.ResId = FOG_RES_ID
    tbCreateData.tbJsonData.TriggerId = tbParams.FogId

    self.tbCreateData = tbCreateData

    return true
end 

function FogSpawner:Spawn()
    local tbCreateParams = self.tbCreateParams
    local tbFogDataTable = FogDataTable:GetTemplate(tbCreateParams.FogId)
    if tbFogDataTable == nil then
        logerror("FogSpawner Spawn failed: invalid id ", tbCreateParams.FogId)
        return nil
    end

    local tbRet = GameObjectSystem:CreateTriggerInGameMode(self.tbCreateData)
    tbRet.pUEActor:SetMoveData(tbCreateParams.PathId, tbFogDataTable.nSpeed, tbFogDataTable.nAccelation, tbFogDataTable.nStopRate, tbFogDataTable.nStopTime)
    for i, v in ipairs(tbFogDataTable.tbChange) do
        tbRet.pUEActor:AddChangeData(v.nTargetDensity, v.nChangeTime, v.nElapseTime)
    end
    tbRet.pUEActor:StartChangeDensity()
    EventManager:OnFireEvent(CommonEventDef.EV_SPAWN_FOG_TRIGGER, tbRet)
    return tbRet
end

function FogSpawner:CollectResource(tbInOutResources)
    local tbCreateData = GOCreateDataHelper:ParseTriggerGameModeData(-1, self.tbCreateData)
    local szRes = GameTrigger.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end

return FogSpawner
