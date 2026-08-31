-----------------------------------------------------
--File Name    : DummySpawner.lua
--Author       : yangyankun
--Create Time  : 2017-05-05
--Description  : DummySpawner
-----------------------------------------------------
local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local DummySpawner = luaclass("DummySpawner", SpawnerBaseClass)

local GameObjectSystem = dynamic_require("GameObjectSystem")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GameDummy = dynamic_require("GameDummy")
local SpawnerDef = require("SpawnerDef")

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
function DummySpawner:OnCreate(tbParams)
    DummySpawner.super.OnCreate(self, tbParams)
    self.nType = SpawnerDef.SpawnerType.DUMMY
    
    return true
end 

function DummySpawner:Spawn()
    local tbCreateParams = self.tbCreateParams
    local tbRet = GameObjectSystem:CreateDummyInGameMode(tbCreateParams.ResId, 
        tbCreateParams.Transform, tbCreateParams.Scale, self.szTag, tbCreateParams)
    return tbRet
end

function DummySpawner:CollectResource(tbInOutResources)
    local tbCreateParams = self.tbCreateParams
    local tbCreateData = GOCreateDataHelper:ParseDummyGameModeData(-1, tbCreateParams.ResId, 
        tbCreateParams.Transform, tbCreateParams.Scale, self.szTag)
    local szRes = GameDummy.StaticCollectResources(tbCreateData, nil)
    if(szRes) then
        table.insert(tbInOutResources, szRes)
    end
end

return DummySpawner
