local NPCInfoCollector = {}

local NPCUsageDef = require("NPCUsageDef")
local NPCDataTable = require("NPCDataTable")
local SceneDataTable = require("SceneDataTable")


--local MAX_NPC_DATA_CACHE_COUNT = 5

--local nCurrentUseCount = 1
local tbFilters = {}

NPCInfoCollector.tbNPCData = nil
NPCInfoCollector.tbServerNPCData = nil
NPCInfoCollector.nNPCDataCount = 0

local LoadNPCDataInScene = function(self, nSceneId)
    -- local tbSceneData = SceneDataTable:GetTemplate(nSceneId)
    -- if(tbSceneData == nil) then
    --     error("LoadNPCDataInScene failed, sceneid: ["..nSceneId.."]")
    --     return nil
    -- end

    -- local szLuaDescriptorPath = tbSceneData.szLuaDescriptorPath
    -- if(szLuaDescriptorPath == nil) then
    --     logerror('load static npc data failed', nSceneId)
    --     return nil
    -- end

    -- local tbTable = require(szLuaDescriptorPath)

    local tbDescriptor = SceneDataTable:GetDescriptor(nSceneId)
    if(tbDescriptor == nil) then
        logerror('get static npc data failed', nSceneId)
        return nil
    end
    local tbNpcs = tbDescriptor.tbNpcs
    self.tbNPCData[nSceneId] = tbNpcs
    -- tbContainer.nUseCount = 0
    -- tbContainer.nUseTime = 0
    -- self.nNPCDataCount = self.nNPCDataCount + 1
    return tbNpcs
end

-- local DiscardData = function(self, nSceneId)
--     local nDiscardId, nWeight
--     local nMinWeight = -1
--     for _, tbData in pairs(self.tbNPCData) do
--         -- 一直保存海洋的数据
--         if(OCEAN_TYPE ~= tbData.nType) then
--             -- nUseTime越大表明越近使用权值越大，使用越频繁权值越大
--             nWeight = tbData.nUseCount * 0.8 + tbData.nUseTime * 1.2
--             if(nMinWeight < 0 or nMinWeight > nWeight) then
--                 nMinWeight = nWeight
--                 nDiscardId = nSceneId
--             end
--         end
--     end

--     if(nDiscardId and self.tbNPCData[nSceneId] ) then
--         self.tbNPCData[nSceneId] = nil
--     end
--     return nDiscardId
-- end

local function VerifyNPCDatas(self, nSceneId)
    local tbNPCDatas = self.tbNPCData[nSceneId]
    if(not tbNPCDatas) then
        -- if(self.nNPCDataCount >= MAX_NPC_DATA_CACHE_COUNT) then
        --     DiscardData(self, nSceneId)
        -- end
        tbNPCDatas = LoadNPCDataInScene(self, nSceneId)
        if(tbNPCDatas == nil) then
            return nil
        end

        local tbServerData = self.tbServerNPCData
        local nCount = #tbServerData
        for i=1, nCount do
            if(tbServerData[i].nSceneId == nSceneId) then
                table.insert(tbNPCDatas, tbServerData[i])
            end
        end
    end
    -- tbNPCDatas.nUseCount = tbNPCDatas.nUseCount + 1
    -- tbNPCDatas.nUseTime = nCurrentUseCount
    -- nCurrentUseCount = nCurrentUseCount + 1
    return tbNPCDatas
end

------------------------------------------------------------------------------------------
tbFilters[NPCUsageDef.ProcessType.UI] = function(tbNPCs, tbProcessInfo, tbOut)    
    local nTargetUIId = tbProcessInfo.nUIId
    local tbInstance, tbTemplate
    local nCount = #tbNPCs
    for i=1, nCount do
        tbInstance = tbNPCs[i]
        tbTemplate = NPCDataTable:GetTemplate(tbInstance.nId)
        if(tbTemplate and tbTemplate.UI) then        
            if(type(tbTemplate.UI) == 'table') then
                for _, nUIId in ipairs(tbTemplate.UI) do
                    if(nTargetUIId == nUIId) then
                        table.insert(tbOut, tbInstance)
                    end
                end
            else
                if(nTargetUIId == tbTemplate.UI) then
                    table.insert(tbOut, tbInstance)
                end
            end -- end if(type(tbTemplate.UI) == 'table') then
        end -- end if(tbTemplate and tbTemplate.UI) then
    end -- for i=1, nCount do
end

tbFilters[NPCUsageDef.ProcessType.Server] = function(tbNPCs, tbProcessInfo, tbOut)    
    local nTargetUsage = tbProcessInfo.nUsage
    local tbInstance
    local nCount = #tbNPCs
    for i=1, nCount do
        tbInstance = tbNPCs[i]
        if(tbInstance.nUsage == nTargetUsage) then
            table.insert(tbOut, tbInstance)
        end
    end -- for i=1, nCount do
end

function NPCInfoCollector:Init()
    self.tbNPCData = {}
    self.tbServerNPCData = {}
    --nCurrentUseCount = 1
end

function NPCInfoCollector:Uninit()
    self.tbNPCData = nil
    self.tbServerNPCData = nil
    --nCurrentUseCount = 1
end

function NPCInfoCollector:FindByUsage(nSceneId, nUsage, tbOut)
    local tbNPCDatas = VerifyNPCDatas(self, nSceneId)
    if(tbNPCDatas == nil) then
        logerror("NPCInfoCollector:FindByUsage failed, can not find NPC data", nUsage)
        return nil
    end

    local tbProcessInfo = NPCUsageDef.ProcessType[nUsage]
    if(tbProcessInfo == nil) then
        logerror("NPCInfoCollector:FindByUsage failed, invalid usage", nUsage)
        return nil
    end

    local fnFilter = tbFilters[tbProcessInfo.nProcessType]
    if(fnFilter == nil) then
        logerror("NPCInfoCollector:FindByUsage failed, can not find filter", nUsage, tbProcessInfo.nProcessType)
        return nil
    end

    fnFilter(tbNPCDatas, tbProcessInfo, tbOut)
    return tbOut
end

function NPCInfoCollector:FindDataByTemplateId(nSceneId, nTemplateId)
    local tbNPCDatas = VerifyNPCDatas(self, nSceneId)
    if(tbNPCDatas == nil) then
        return nil
    end

    local tbData
    local nCount = #tbNPCDatas
    for i=1, nCount do
        tbData = tbNPCDatas[i]
        if(tbData.nId == nTemplateId) then
            return tbData
        end
    end
    return nil
end

function NPCInfoCollector:FindDataByRangeTemplateId(nSceneId, nBeginId, nEndId)
    local tbNPCDatas = VerifyNPCDatas(self, nSceneId)
    if(tbNPCDatas == nil) then
        return nil
    end

    local tbData = nil
    local tbDataList = {}
    local nCount = #tbNPCDatas
    for i=1, nCount do
        tbData = tbNPCDatas[i]
        if(tbData.nId >= nBeginId and tbData.nId <= nEndId) then
            table.insert(tbDataList, tbData)
        end
    end

    return tbDataList
end

function NPCInfoCollector:FindDataBySceneId(nSceneId)
    local tbNPCDatas = VerifyNPCDatas(self, nSceneId)
    if(tbNPCDatas == nil) then
        logwarning("NPCInfoCollector:FindDataBySceneId failed, sceneid: ", nSceneId)
        return nil
    end

    return tbNPCDatas
end

function NPCInfoCollector:AddServerNPCInfo(nSceneId, nActorId, nTemplateId, tbTransform, nUsage)
    local tbNewData = {}
    tbNewData.nSceneId = nSceneId
    tbNewData.nActorId = nActorId
    tbNewData.nId = nTemplateId
    tbNewData.nX = tbTransform.x
    tbNewData.nY = tbTransform.y
    tbNewData.nZ = tbTransform.z
    tbNewData.nUsage = nUsage
    tbNewData.bDeleted = false
    table.insert(self.tbServerNPCData, tbNewData)

    local tbNPCData = self.tbNPCData[nSceneId]
    if(tbNPCData) then
        table.insert(tbNPCData, tbNewData)
    end
end

function NPCInfoCollector:RemoveServerNPCInfo(nActorId)
    local tbDatas = self.tbServerNPCData
    local nCount = #tbDatas
    local tbDelete, nSceneId
    for i=1, nCount do
        tbDelete = tbDatas[i]
        if(tbDelete.nActorId == nActorId) then
            nSceneId = tbDelete.nSceneId
            table.remove(tbDatas, i)
            break
        end
    end

    if(nSceneId) then
        local tbNPCData = self.tbNPCData[nSceneId]
        if(tbNPCData) then
            nCount = #tbNPCData
            for i=1, nCount do
                if(tbNPCData[i].nActorId == nActorId) then
                    table.remove(tbNPCData, i)
                    break
                end
            end
        end
    end
end

function NPCInfoCollector:FindServerNPCInfo(nUsage, tbOut)
    local tbProcessInfo = NPCUsageDef.ProcessType[nUsage]
    if(tbProcessInfo == nil) then
        logerror("NPCInfoCollector:FindServerNPCInfo failed, invalid usage", nUsage)
        return nil
    end

    local tbServerInfo = self.tbServerNPCData
    local nTargetUsage = tbProcessInfo.nUsage
    local tbInfo
    local nCount = #tbServerInfo
    for i=1, nCount do
        tbInfo = tbServerInfo[i]
        if(tbInfo.nUsage == nTargetUsage) then
            table.insert(tbOut, tbInfo)
        end
    end -- for i=1, nCount do
end

return NPCInfoCollector