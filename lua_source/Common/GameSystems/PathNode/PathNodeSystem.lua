local PathNodeSystem = {}

PathNodeSystem.tbPaths = nil

-- 挪到了C++里
-- local function FindNodeLocation(tbPath, nIndex)
--     if(nIndex <= 0 or nIndex > tbPath.nCount) then
--         logerror("FindNodeLocation failed, invalid index", nIndex)
--         return nil
--     end
--     return tbPath[nIndex]
-- end

-- local function FindNextNodeIndex(tbPath, nCurrentIndex)
--     if(nCurrentIndex <= 0) then
--         logerror("FindNextNodeIndex failed, invalid index", tbPath, nCurrentIndex)
--         return
--     end

--     local nCount = tbPath.nCount
--     if(nCount == 1) then
--         return 1, tbPath[1], true
--     end

--     if(tbPath.bStopWhenEnd and nCurrentIndex >= nCount) then
--         return nCurrentIndex, tbPath[nCurrentIndex], true
--     end

--     local nNextIndex 
--     if(tbPath.bCycle) then
--         nNextIndex = nCurrentIndex + 1
--         if(nNextIndex > nCount) then
--             nNextIndex = 1
--         end
--     else
--         if(tbPath.bOrdered) then            
--             if(nCurrentIndex >= nCount) then
--                 nNextIndex = nCount - 1
--                 tbPath.bOrdered = false
--             else
--                 nNextIndex = nCurrentIndex + 1 
--             end
--         else            
--             if(nCurrentIndex <= 1) then
--                 tbPath.bOrdered = true
--                 nNextIndex = 2
--             else
--                 nNextIndex = nCurrentIndex - 1
--             end
--         end
--     end
--     assert(nNextIndex >= 1 and nNextIndex <= nCount)
--     return nNextIndex, tbPath[nNextIndex], false
-- end

function PathNodeSystem:Init()
    self.tbPaths = {}
    
    return true
end

function PathNodeSystem:Uninit()
    self.tbPaths = nil
    local pFinder = CommonShell.GetCommon(GWorld):GetPathNodeFinder()
    pFinder:Clear()    
end

local function CreatePath(self, pFinder, nPathId, bCycle, tbNodes, bStopWhenEnd)
    local tbPaths = self.tbPaths
    if(tbPaths[nPathId]) then
        logerror("PathNodeSystem:CreatePath failed, duplicated path", nPathId)
        return false
    end

    local nCount = #tbNodes
    local tbNewPath = {}
    tbPaths[nPathId] = tbNewPath
    tbNewPath.nPathId = nPathId
    tbNewPath.bCycle = bCycle
    tbNewPath.nCount = nCount

    for i=1, nCount do
        tbNewPath[i] = tbNodes[i]
    end

    -- 折返路线，这里伪造回去的路线
    if(not bStopWhenEnd and not bCycle) then
        tbNewPath.bCycle = true
        local nIndex = nCount
        for i=nCount-1, 2, -1 do
            nIndex = nIndex + 1
            tbNewPath[nIndex] = tbNodes[i]   
        end
        tbNewPath.nCount = nIndex
    end

    local Node
    pFinder:AddPath(nPathId, tbNewPath.bCycle)
    for i=1, tbNewPath.nCount do
        Node = tbNewPath[i]
        pFinder:AddNode(nPathId, Node.X, Node.Y, Node.Z)
    end
    
    return true
end

function PathNodeSystem:ParseJson(tbJsonData)

    if(tbJsonData == nil or tbJsonData.PathNodes == nil) then
        return false
    end

    local pFinder = CommonShell.GetCommon(GWorld):GetPathNodeFinder()
    local tbPathInfo
    local tbPaths = tbJsonData.PathNodes
    local nCount = #tbPaths
    for i=1, nCount do
        tbPathInfo = tbPaths[i]
        CreatePath(self, pFinder, tbPathInfo.PathId, tbPathInfo.IsCyclePath, 
            tbPathInfo.PathNodes, tbPathInfo.StopWhenEnd)
    end

    return true
end

function PathNodeSystem:Clear()
    self.tbPaths = {}
    local pFinder = CommonShell.GetCommon(GWorld):GetPathNodeFinder()
    pFinder:Clear()
end

function PathNodeSystem:FindPath(nPathId)
    return self.tbPaths[nPathId]
end

-- function PathNodeSystem:FindPathNodeLocation(nPathId, nPathNodeIndex)
--     local tbPath = self:FindPath(nPathId)
--     if(tbPath == nil) then
--         logwarning("PathNodeSystem:FindPathNodeLocation failed, can not find path", nPathId, nPathNodeIndex)
--         return nil
--     end
--     local Location = FindNodeLocation(tbPath, nPathNodeIndex)
--     log("PathNodeSystem:FindPathNodeLocation, ", nPathId, nPathNodeIndex, Location.X, Location.Y, Location.Z)
--     return Location
-- end

-- function PathNodeSystem:FindNextPathInfo(nPathId, nPathNodeIndex)
--     local tbPath = self:FindPath(nPathId)
--     if(tbPath == nil) then
--         logwarning("PathNodeSystem:FindNextPathInfo failed, can not find path", nPathId, nPathNodeIndex)
--         return nil
--     end
--     local nIndex, Location, bIsEndPoint = FindNextNodeIndex(tbPath, nPathNodeIndex)
--     log("PathNodeSystem:FindNextPathInfo, ", nPathId, nPathNodeIndex, nIndex, Location.X, Location.Y, Location.Z)
--     return nIndex, Location, bIsEndPoint
-- end

return PathNodeSystem