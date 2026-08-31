-----------------------------------------------------
--File Name    : SpawnerBase.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : SpawnerBase
-----------------------------------------------------
local luaclass = require("luaclass")
local SpawnerBase = luaclass("SpawnerBase")

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
SpawnerBase.szTag = nil

function SpawnerBase:OnCreate(tbParams)
    self.tbCreateParams = tbParams
    self.bAutoSpawn = tbParams.AutoSpawn
    self.bAutoDestroy = tbParams.AutoDestroy
    self.nSpawnerId = tbParams.SpawnerId
    self.nGroupIndex = tbParams.GroupIndex
    self.nSubGroupIndex = tbParams.SubGroupIndex
    self.szTag = tbParams.Tag

    local tbTransform = tbParams.Transform
    self.nX = tbTransform.X
    self.nY = tbTransform.Y
    self.nZ = tbTransform.Z
    self.nYaw = tbTransform.Yaw    
    return true
end 

function SpawnerBase:Spawn()
    return nil
end

function SpawnerBase:OnDestroy()
end

function SpawnerBase:CollectResource(tbInOutResources)
    
end

return SpawnerBase
