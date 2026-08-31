-----------------------------------------------------
--File Name    : TriggerSpawner.lua
--Author       : zhangjingjing
--Create Time  : 2017-11-14
--Description  : TriggerSpawner
-----------------------------------------------------
local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local TriggerSpawner = luaclass("TriggerSpawner", SpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameTrigger = dynamic_require("GameTrigger")
local SpawnerDef = require("SpawnerDef")
local ProtoDC = require("DungeonCommonProtoNames")

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

TriggerSpawner.nTriggerId = nil
TriggerSpawner.nRadius = nil
TriggerSpawner.nResId = nil
TriggerSpawner.nBoxX = nil
TriggerSpawner.nBoxY = nil
TriggerSpawner.nBoxZ = nil
TriggerSpawner.tbCreateData = nil

-- tbParams 为JsonData
function TriggerSpawner:OnCreate(tbParams)
    TriggerSpawner.super.OnCreate(self, tbParams)

    self.nType = SpawnerDef.SpawnerType.TRIGGER
    self.nTriggerId = tbParams.TriggerId
    self.nRadius = tbParams.Shape.Radius
    self.nResId = tbParams.ResId
    self.nBoxX = tbParams.nBoxX
    self.nBoxY = tbParams.nBoxY
    self.nBoxZ = tbParams.nBoxZ
    self.tbCreateData = {tbJsonData = self.tbCreateParams}
    local tbCollisionType = ProtoDC.TriggerActorInitData_ECollisionType
    self.tbCreateData.tbJsonData.CollisionType = tbCollisionType.ALL
    
    return true
end 

function TriggerSpawner:Spawn()
    return GameObjectSystem:CreateTriggerInGameMode(self.tbCreateData)
end

function TriggerSpawner:CollectResource(tbInOutResources)

    local tbCreateData = GOCreateDataHelper:ParseTriggerGameModeData(-1, self.tbCreateData)
    local szRes = GameTrigger.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end

return TriggerSpawner
