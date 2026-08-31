-----------------------------------------------------
--File Name    : DestructibleObjectSpawner.lua
--Author       : fangjing
--Create Time  : 2019-12-26
--Description  : DestructibleObjectSpawner
-----------------------------------------------------
local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local DestructibleObjectSpawner = luaclass("DestructibleSpawner", SpawnerBaseClass)

local SpawnerDef = require("SpawnerDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameDestructibleObject = dynamic_require("GameDestructibleObject")

DestructibleObjectSpawner.nDestructibleObjectType = nil

-- tbParams 为JsonData
function DestructibleObjectSpawner:OnCreate(tbParams)
    DestructibleObjectSpawner.super.OnCreate(self, tbParams)
    self.nType = SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT
    -- self.nDestructibleObjectType = SpawnerDef.SpawnerType.DESTRUCTIBLEOBJECT

    return true
end 

function DestructibleObjectSpawner:Spawn()
    local tbCreateParams = self.tbCreateParams
    return GameObjectSystem:CreateDestructibleObjectInGameMode(tbCreateParams.Id, 
            tbCreateParams.Transform, tbCreateParams.Scale, tbCreateParams)
end

function DestructibleObjectSpawner:CollectResource(tbInOutResources)
    local tbCreateParams = self.tbCreateParams
    local tbCreateData = GOCreateDataHelper:ParseDestructibleObjectGameModeData(-1, tbCreateParams.Id, 
        tbCreateParams.Transform, tbCreateParams.Scale, tbCreateParams)
    local szRes = GameDestructibleObject.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end

return DestructibleObjectSpawner
