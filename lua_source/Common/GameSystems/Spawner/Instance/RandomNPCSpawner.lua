local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local RandomNPCSpawner = luaclass("RandomNPCSpawner", SpawnerBaseClass)

local SpawnerSystem = require("SpawnerSystem")
local SpawnerDef = require("SpawnerDef")

RandomNPCSpawner.tbSpawnerIds = nil
RandomNPCSpawner.nRandomMinCount = 0
RandomNPCSpawner.nRandomMaxCount = 0

function RandomNPCSpawner:OnCreate(tbParams)
    RandomNPCSpawner.super.OnCreate(self, tbParams)

    self.nType = SpawnerDef.SpawnerType.RANDOM_NPC
    self.tbSpawnerIds = tbParams.SpawnerIds
    self.nRandomMinCount = tbParams.RandomMinCount
    self.nRandomMaxCount = tbParams.RandomMaxCount

    if(self.nRandomMaxCount < self.nRandomMinCount) then
        logerror("RandomNPCSpawner:OnCreate failed, the min max count is invalid", self.nSpawnerId)
        return false
    end

    local nSpawnerCount = #self.tbSpawnerIds
    if(self.nRandomMaxCount > nSpawnerCount) then
        logerror("RandomNPCSpawner the random max count is more then spanwer count")
        self.nRandomMaxCount = nSpawnerCount
    end
    if(self.nRandomMinCount > nSpawnerCount) then
        logerror("RandomNPCSpawner the random min count is more then spanwer count")
        self.nRandomMinCount = nSpawnerCount    
    end

    return true
end 

function RandomNPCSpawner:Spawn()
    local tbRet = {}
    
    local nCount = math.random(self.nRandomMinCount, self.nRandomMaxCount)

    local tbSpawnerIds = self.tbSpawnerIds
    local nSpawnerCount = #tbSpawnerIds    
    if(nCount > nSpawnerCount) then        
        nCount = nSpawnerCount
    end    

    for i=1, nSpawnerCount do
        table.insert(tbRet, tbSpawnerIds[i])
    end

    -- 随机删，删完了就是需要spawn的，这样能少倒腾一次表
    local nRemoveCount = nSpawnerCount - nCount
    for i=1, nRemoveCount do
        table.remove(tbRet, math.random(1, #tbRet))
    end

    log("RandomNPCSpawner:Spawn", self.nSpawnerId, nCount)

    nCount = #tbRet
    local nSpawnerId, tbSpawner
    for i=1, nCount do
        nSpawnerId = tbRet[i]
        tbSpawner = SpawnerSystem:FindById(nSpawnerId)
        if(tbSpawner) then
            tbRet[i] = SpawnerSystem:Spawn(tbSpawner)
        else
            logerror("RandomNPCSpawner:Spawn failed, can not find spawner", nSpawnerId)
        end
    end
    return tbRet
end

return RandomNPCSpawner
