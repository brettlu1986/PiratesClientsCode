local luaclass = require("luaclass")
local CppDelegateProcessorBaseClass = require("CPPDelegateProcessorBase")
local BattlePathNodeCppDelegateProcessor = luaclass("BattlePathNodeCppDelegateProcessor", CppDelegateProcessorBaseClass)

--local PathNodeSystem = require("PathNodeSystem")

-- local pLocation = Vector()
-- local pZeroLocation = Vector()

-- local function CopyLocation(Location)
--     pLocation.X = Location.X
--     pLocation.Y = Location.Y
--     pLocation.Z = Location.Z
--     return pLocation
-- end

-- local function OnGetPathNodeLocation(nPathId, nNodeIndex)
--     local Location = PathNodeSystem:FindPathNodeLocation(nPathId, nNodeIndex)
--     if(Location == nil) then
--         return pZeroLocation
--     end
--     return CopyLocation(Location)
-- end

-- local function OnGetNextPathNodeInfo(nPathId, nNodeIndex)
--     local nNextIndex, Location, bIsEndPoint = PathNodeSystem:FindNextPathInfo(nPathId, nNodeIndex)
--     if(nNextIndex == nil or Location == nil) then
--         return -1, pZeroLocation, false
--     end
--     return nNextIndex, CopyLocation(Location), bIsEndPoint
-- end

function BattlePathNodeCppDelegateProcessor:Init()
    BattlePathNodeCppDelegateProcessor.super.Init(self)
    
    --local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().PathNode
    --self:Register(DelegateMgr.OnGetPathNodeLocation, OnGetPathNodeLocation)
    --self:Register(DelegateMgr.OnGetNextPathNodeInfo, OnGetNextPathNodeInfo)
    return true
end

return BattlePathNodeCppDelegateProcessor
