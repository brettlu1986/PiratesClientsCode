local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local HomelandBlockSpawner = luaclass("HomelandBlockSpawner", SpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local SpawnerDef = require("SpawnerDef")

local HOMELAND_FIELD_RES_ID = 26

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
function HomelandBlockSpawner:OnCreate(tbParams)
    HomelandBlockSpawner.super.OnCreate(self, tbParams)
    self.nType = SpawnerDef.SpawnerType.HOMELAND_BLOCK
    self.bAutoSpawn = true
    local tbCreateData = {}
    tbCreateData.actor_id = tbParams.nGenerateInstanceId
    tbCreateData.res_id = HOMELAND_FIELD_RES_ID
    tbCreateData.transform = tbParams.Transform
    local tbShapeData = tbParams.Shape
    tbCreateData.shape_type = tbShapeData.Type
    tbCreateData.radius = tbShapeData.Radius
    tbCreateData.box_x = tbShapeData.BoxX
    tbCreateData.box_y = tbShapeData.BoxY
    tbCreateData.box_z = tbShapeData.BoxZ
    tbCreateData.nTriggerId = tbParams.TriggerId
    tbCreateData.nBlockId = tbParams.BlockId
    self.tbCreateData = tbCreateData

    return true
end 

function HomelandBlockSpawner:Spawn()
    log("HomelandBlockSpawner:Spawn",self.tbCreateData.actor_id)
    local tbGameObject = GameObjectSystem:CreateTriggerInHub(self.tbCreateData)
    local tbCustomData = {}
    tbCustomData.nBlockId = self.tbCreateData.nBlockId
    tbGameObject.tbCustomData = tbCustomData
    local tbTransform = self.tbCreateData.transform
    local nLocationX = tbTransform.X
    local nLocationY = tbTransform.Y
    local nLocationZ = tbTransform.Z
    tbGameObject:SetLocation(nLocationX, nLocationY, nLocationZ)
    tbGameObject:SetRotation(0, tbTransform.Yaw, 0)
    return tbGameObject
end

function HomelandBlockSpawner:OnDestroy()
    GameObjectSystem:DestroyTriggerInHub(self.tbCreateData.actor_id, true)
end

return HomelandBlockSpawner
