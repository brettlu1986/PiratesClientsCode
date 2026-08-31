-----------------------------------------------------
--File Name    : SpawnerSystem.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-13
--Description  : SpawnerSystem
-----------------------------------------------------
local SpawnerSystem = {}
local SpawnerRegister = require("SpawnerRegister")
local SpawnerDef = require("SpawnerDef")
local AsyncHelperSystem = require("AsyncHelperSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local CDSpawnHelper = require("CDSpawnHelper")

local JsonClassMap = SpawnerDef.SpawnerJsonDef


SpawnerSystem.tbClasses = nil
SpawnerSystem.tbInstances = nil
SpawnerSystem.tbInstanceCount = nil

local function AddObjectOrTable(tbRet, tbObjectOrTable)
    if(tbObjectOrTable == nil or tbRet == nil) then
        return
    end

    if(tbObjectOrTable.ObjectType == nil) then
        for _, Object in ipairs(tbObjectOrTable) do
            AddObjectOrTable(tbRet, Object)            
        end
    else
        table.insert(tbRet, tbObjectOrTable)
    end
end

local function VerifySpawnOver(self, nSpawnerType)
    local tbInstanceCount = self.tbInstanceCount[nSpawnerType]
    tbInstanceCount.nCurCount = tbInstanceCount.nCurCount + 1
    if tbInstanceCount.nCurCount == tbInstanceCount.nMaxCount then
        EventManager:OnFireEvent(CommonEventDef.EV_SPAWN_TYPE_OVER, nSpawnerType)
    end 
end

function SpawnerSystem:Init()
    self.tbClasses = {}
    self.tbInstances = {}
    self.tbInstanceCount = {}
    CDSpawnHelper:Init()
    SpawnerRegister:RegisterAllSpawners(self)
    return true
end

function SpawnerSystem:Register(nType, SpawnerClass)
    if nType == SpawnerDef.SpawnerType.NONE then 
        error("Register Spawner Error")
        return 
    end 
    self.tbClasses[nType] = SpawnerClass
end 

function SpawnerSystem:Uninit()    
    self:DestroyAll()
    CDSpawnHelper:Uninit()
    self.tbInstanceCount = nil
    self.tbInstances = nil
    self.tbClasses = nil    
end

-- tbParams 为JsonData
function SpawnerSystem:CreateSpawner(nSpawnerType, tbParams, bEnableAutoSpawn)
    local SpawnerClass = self.tbClasses[nSpawnerType]
    local ObjectInstance = nil
    if not SpawnerClass then 
        logerror("Error Spawner Type : " .. nSpawnerType)
        return nil
    end 

    local tbInstance = SpawnerClass()
    tbInstance.nSpawnerType = nSpawnerType
    if(false == tbInstance:OnCreate(tbParams)) then
        logerror("SpawnerSystem:Create failed", nSpawnerType)
        return nil
    end
    
    table.insert(self.tbInstances, tbInstance)
    if self.tbInstanceCount[nSpawnerType] == nil then
        self.tbInstanceCount[nSpawnerType] = {nMaxCount = 0, nCurCount = 0}
    end
    self.tbInstanceCount[nSpawnerType].nMaxCount = self.tbInstanceCount[nSpawnerType].nMaxCount + 1

    if(bEnableAutoSpawn and tbInstance.bAutoSpawn) then
        ObjectInstance = self:Spawn(tbInstance)
    end

    return tbInstance, ObjectInstance
end 

function SpawnerSystem:DestroySpawner(tbInstance)
    for i, tbTemp in ipairs(self.tbInstances) do
        if tbTemp == tbInstance then
            table.remove(self.tbInstances, i)
            tbInstance:OnDestroy()            
            return true
        end
    end
    return false
end

function SpawnerSystem:Spawn(tbInstance, bAutoDestroy)
    if(not tbInstance) then
        logerror("SpawnerSystem:Spawn failed, the instance is nil")
        return nil
    end

    local tbRet = tbInstance:Spawn()

    VerifySpawnOver(self, tbInstance.nSpawnerType)

    if(bAutoDestroy or tbInstance.bAutoDestroy) then
        self:DestroySpawner(tbInstance)
    end
    return tbRet
end

function SpawnerSystem:SpawnById(nSpawnerId, bAutoDestroy)
    local tbSpawner = self:FindById(nSpawnerId)
    if(tbSpawner == nil) then
        logerror("SpawnerSystem:SpawnById failed, can not find spawner", nSpawnerId)
        return nil
    end
    return self:Spawn(tbSpawner, bAutoDestroy)
end

function SpawnerSystem:FindById(nSpawnerId)
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.nSpawnerId == nSpawnerId) then
                return tbInstance
            end
        end
    end
    return nil
end

function SpawnerSystem:SpawnByTag(szTag, bAutoDestroy)
    local tbRet = {}
    for i, tbInstance in ipairs(self.tbInstances) do
        if(tbInstance.szTag == szTag) then
            local tbObjectOrTable = self:Spawn(tbInstance, false)
            AddObjectOrTable(tbRet, tbObjectOrTable)
        end
    end
    return tbRet
end

function SpawnerSystem:FindByTag(szTag)
    if(self.tbInstances) then
        local tbRet = {}
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.szTag == szTag) then
                table.insert(tbRet, tbInstance)
            end
        end
        return tbRet
    end
    return nil
end 

function SpawnerSystem:ParseJson(tbJsonData)
    if(tbJsonData == nil) then
        return nil
    end
    
    local tbRet = {}
    local nSpawnerType, tbSpawner
    for szKey, tbDatas in pairs(tbJsonData) do
        nSpawnerType = JsonClassMap[szKey]
        if(nSpawnerType ~= nil) then
            for _, tbSpawnerData in ipairs(tbDatas) do
                tbSpawner = self:CreateSpawner(nSpawnerType, tbSpawnerData, false)
                if(tbSpawner) then
                    table.insert(tbRet, tbSpawner)
                end
            end
        end
    end

    for i, tbTempSpawner in pairs(tbRet) do
        if(tbTempSpawner.bAutoSpawn) then
            self:Spawn(tbTempSpawner)
        end
    end
    return tbRet
end

function SpawnerSystem:GetAllSpawners()
    return self.tbInstances
end

function SpawnerSystem:DestroyAll()
    if(self.tbInstances) then
        for _, tbInstance in pairs(self.tbInstances) do
            tbInstance:OnDestroy()
        end
        self.tbInstances = {}
    end
end

function SpawnerSystem:SpawnByGroupIndex(nGroupIndex, nTypes)
    local tbRet = {}
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.nGroupIndex == nGroupIndex and 
                (nTypes == nil or (tbInstance.nType & nTypes > 0))) then
                local tbObjectOrTable = self:Spawn(tbInstance)
                AddObjectOrTable(tbRet, tbObjectOrTable)
            end
        end    
    end
    return tbRet
end

function SpawnerSystem:SpawnBySubGroupIndex(nGroupIndex, nSubGroupIndex)
    local tbRet = {}
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.nGroupIndex == nGroupIndex
                and tbInstance.nSubGroupIndex == nSubGroupIndex) then
                local tbObjectOrTable = self:Spawn(tbInstance)
                AddObjectOrTable(tbRet, tbObjectOrTable)
            end
        end    
    end
    return tbRet
end

function SpawnerSystem:SpawnByTemplateId(nTemplateId)
    local tbRet = {}
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.nTemplateId == nTemplateId) then
                local tbObjectOrTable = self:Spawn(tbInstance)
                AddObjectOrTable(tbRet, tbObjectOrTable)
            end
        end    
    end
    return tbRet
end

function SpawnerSystem:SpawnByTriggerId(nTriggerId)
    local tbRet = {}
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            if(tbInstance.nTriggerId == nTriggerId) then
                local tbObjectOrTable = self:Spawn(tbInstance)
                AddObjectOrTable(tbRet, tbObjectOrTable)
            end
        end    
    end
    return tbRet
end

function SpawnerSystem:SpawnAllByType(tbTypes)
    local tbRet = {}
    if self.tbInstances then
        for i, tbInstance in ipairs(self.tbInstances) do
            if tbTypes[tbInstance.nType] then
                local tbObjectOrTable = self:Spawn(tbInstance)
                if tbInstance.nType == SpawnerDef.SpawnerType.ITEMDROP then 
                    AddObjectOrTable(tbRet, tbObjectOrTable)
                end
            end
        end    
    end
    return tbRet
end 

function SpawnerSystem:AsyncSpawnAllByType(tbTypes)
    -- AsyncSpawnByType(self, 1, tbTypes)
    if self.tbInstances then
        for i, tbInstance in ipairs(self.tbInstances) do
            if tbTypes[tbInstance.nType] then
                AsyncHelperSystem:AddToAsyncList(tbInstance, function()
                    self:Spawn(tbInstance)
                end)   
            end
        end    
        AsyncHelperSystem:ReadyForAsync()
    end
end 

function SpawnerSystem:SpawnAll()
    local tbRet = {}
    if(self.tbInstances) then
        for i, tbInstance in ipairs(self.tbInstances) do
            local tbObjectOrTable = self:Spawn(tbInstance)
            AddObjectOrTable(tbRet, tbObjectOrTable)
        end    
    end
    return tbRet
end

function SpawnerSystem:CollectResources(tbInOutResources)
    if(self.tbInstances) then
        local tbRes = {}
        for i, tbInstance in ipairs(self.tbInstances) do
            tbInstance:CollectResource(tbRes)
        end

        local bFind = false
        for _, szRes in ipairs(tbRes) do
            bFind = false
            for _, szTempRes in ipairs(tbInOutResources) do
                if(szTempRes == szRes) then
                    bFind = true
                    break
                end
            end
            if(not bFind) then
                table.insert(tbInOutResources, szRes)
            end
        end


    end
end

return SpawnerSystem
