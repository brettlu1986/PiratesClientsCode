
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIPatrolSystem = luaclass("SAIPatrolSystem", SAISystemBase)
local SAISystemDef = require("SAISystemDef")
local SAIMisc = require("SAIMisc")


SAIPatrolSystem.nPathId = 0
SAIPatrolSystem.tbLocations = nil
SAIPatrolSystem.nCurrentWayPoint = 0
SAIPatrolSystem.tbGoalSystem = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPatrolSystem:", ...)
end
-- luacheck: pop


function SAIPatrolSystem:OnConfig(tbConfig)
    self.tbConfig = tbConfig
    self.bEnabled = false
    local tbPatrolConfig = tbConfig.Patrol
    if tbPatrolConfig then
        if tbPatrolConfig.nPathId and tbPatrolConfig.nPathId > 0 then
            self:SetPathID(tbPatrolConfig.nPathId)
            self.bEnabled = true
        end
    end
end

function SAIPatrolSystem:SetPathID(nPathId)
    if self.nPathId ~= nPathId then
        LOG("set path id", nPathId)
        self.nPathId = nPathId
        self.tbLocations = {}
        local pPathNode =  CommonShell.Get(GWorld):GetGameDelegateManager().PathNode
        self.pPathNode = pPathNode
        local nWayPointIndex  = 0
        local bEnd = false
        local pLocation = pPathNode.GetPathNodeLocation(GWorld, self.nPathId, nWayPointIndex)
        table.insert(self.tbLocations, { X = pLocation.X, Y = pLocation.Y, Z = pLocation.Z})
        local bCircle = false
        local pGetNextPathNodeInfo = pPathNode.GetNextPathNodeInfo
        while (not bEnd) do
            local nNextWayPointIndex, pNextLocation, bFinish = pGetNextPathNodeInfo(GWorld, self.nPathId, nWayPointIndex)
            if not bFinish then
                if nNextWayPointIndex <= nWayPointIndex then
                    bCircle = true
                    bEnd = true
                else
                    nWayPointIndex = nNextWayPointIndex
                    table.insert(self.tbLocations, { X = pNextLocation.X, Y = pNextLocation.Y, Z = pNextLocation.Z})
                end
            else
                bCircle = false
                bEnd = true
            end
        end
        if bCircle then
            local nFromIndex = #self.tbLocations - 1
            for i=nFromIndex,2,-1 do
                table.insert(self.tbLocations, self.tbLocations[i])
            end
        end
        LOG("num way positions ", #self.tbLocations)
    end
end

function SAIPatrolSystem:ToNextWayPoint()
    if self.nCurrentWayPoint < #self.tbLocations then
        self.nCurrentWayPoint = self.nCurrentWayPoint + 1
    else
        self.nCurrentWayPoint = 1
    end
    local pLocation = self.tbLocations[self.nCurrentWayPoint]
    self.tbGoalSystem:SetGoalLocation(pLocation.X, pLocation.Y, pLocation.Z)
    --LOG("next way point ", self.nCurrentWayPoint, #self.tbLocations)
end

function SAIPatrolSystem:GetNereastWayPoint()
    local pLocation = self.tbOwner:GetLocation()
    local nSourceX = pLocation.X
    local nSourceY = pLocation.Y
    local nMinDisatnce = 1000000
    local nRet = -1
    for i,v in ipairs(self.tbLocations) do
        local nDistance =  SAIMisc:Distance(nSourceX, nSourceY, v.X, v.Y)
        if nDistance < nMinDisatnce or nRet < 0 then
            nRet = i
            nMinDisatnce = nDistance
        end
    end
    return nRet
end


function SAIPatrolSystem:OnStart()
    local tbOwner = self.tbOwner
    local AIComponent = tbOwner.SAIComponent
    self.tbGoalSystem = AIComponent:GetSystem(SAISystemDef.Goal)
    if self.tbLocations then
        self.nCurrentWayPoint = self:GetNereastWayPoint()
        LOG("start way point ", self.nCurrentWayPoint)
        local pLocation = self.tbLocations[self.nCurrentWayPoint]
        self.tbGoalSystem:SetGoalLocation(pLocation.X, pLocation.Y, pLocation.Z)
    end
end


function SAIPatrolSystem:OnStop()
    if self.nPathId and self.tbLocations then
        self.tbGoalSystem:ClearGoalLocation()
    end
    self.tbGoalSystem = nil
end

function SAIPatrolSystem:OnUninit()

end

return SAIPatrolSystem
