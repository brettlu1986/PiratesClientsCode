local luaclass = require("luaclass")
local SimpleStateMachineClass = require("SimpleStateMachine")
local PVPOccupyAreaStateMachine = luaclass("PVPOccupyAreaStateMachine", SimpleStateMachineClass)

local Proto = require("DungeonRepProtoNames")
local Timer = require("Timer")


PVPOccupyAreaStateMachine.nAreaId = 0
PVPOccupyAreaStateMachine.rInfo = nil  -- DungeonRepProtoNames里的PVPOccupyAreaInfo
PVPOccupyAreaStateMachine.tbIds = nil
PVPOccupyAreaStateMachine.Timer = nil
PVPOccupyAreaStateMachine.nPunishTime = nil -- 占领中过程中惩罚的时间，和Timer生命周期相同，用于计算nOccupyingRemainTime
PVPOccupyAreaStateMachine.nMoreTeamId = nil -- 人数较多的队伍id
PVPOccupyAreaStateMachine.nMoreMemberCount = 0  -- 人数较多的队伍里的人数
PVPOccupyAreaStateMachine.nLessTeamId = nil  -- 人数较少的队伍id
PVPOccupyAreaStateMachine.nLessMemberCount = 0  -- 人数较少的队伍里的人数
PVPOccupyAreaStateMachine.fnOnStateChanged = nil


-- 获取圈内人数较多的队伍
local function GetMoreNumberTeamId(tbBlackboard)
    local nFirstTeamId, nSecondTeamId
    local nFirstMemberCount = 0
    local nSecondMemberCount = 0
    for nUniqueId, nTeamId in pairs(tbBlackboard.tbIds) do
        if(nFirstTeamId == nil) then
            nFirstTeamId = nTeamId
            nFirstMemberCount = 1
        elseif(nFirstTeamId ~= nTeamId) then
            nSecondTeamId = nTeamId
            nSecondMemberCount = nSecondMemberCount + 1
        else
            nFirstMemberCount = nFirstMemberCount + 1
        end
    end
    
    if(nFirstMemberCount > nSecondMemberCount) then
        return nFirstTeamId, nFirstMemberCount, nSecondTeamId, nSecondMemberCount
    elseif(nFirstMemberCount < nSecondMemberCount) then
        return nSecondTeamId, nSecondMemberCount, nFirstTeamId, nFirstMemberCount
    end

    return -1, nFirstMemberCount, -1, nFirstMemberCount   -- 相等
end

local function LogState(szLog, tbBlackboard)
    local rInfo = tbBlackboard.rInfo
    log(szLog, rInfo.nAreaIndex, rInfo.nOwnerTeamId, rInfo.nOccupyingTeamId, rInfo.nOccupyingRemainTime) 
end

-- 初始状态
local tbNoneState = {
    szName = "NoneState",
    nState = Proto.PVPOccupyAreaInfo_OccupyState.NONE,
    OnActived = function(self, tbBlackboard)
        LogState(self.szName, tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        rInfo.nState = self.nState
        assert(rInfo.nOwnerTeamId == -1)
        rInfo.nOccupyingTeamId = -1
        rInfo.nOccupyingRemainTime = nil
        rInfo.nOccupyingMaxTime = nil
    end,
    TryMoveToOccuping = function(self, tbToState, tbBlackboard)
        LogState("tbNoneState->TryMoveToOccuping", tbBlackboard)
        return tbBlackboard.nMoreMemberCount > 0
    end,
}

-- 已占领状态
local tbOccupiedState = {
    szName = "OccupiedState",
    nState = Proto.PVPOccupyAreaInfo_OccupyState.OCCUPIED,
    OnActived = function(self, tbBlackboard)
        LogState(self.szName, tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        rInfo.nState = self.nState
        assert(rInfo.nOwnerTeamId ~= -1)
        rInfo.nOccupyingTeamId = -1
        rInfo.nOccupyingRemainTime = nil
        rInfo.nOccupyingMaxTime = nil
    end,
    TryMoveToOccuping = function(self, tbToState, tbBlackboard)
        LogState("tbOccupiedState->TryMoveToOccuping", tbBlackboard)
        -- 己方人数为0并且非己方人数不为0
        local rInfo = tbBlackboard.rInfo
        return tbBlackboard.nMoreTeamId >= 0 and 
            rInfo.nOwnerTeamId ~= tbBlackboard.nMoreTeamId and
            tbBlackboard.nMoreMemberCount > 0 and
            tbBlackboard.nLessMemberCount == 0
    end,
    TryMoveToStalemate = function(self, tbToState, tbBlackboard)
        LogState("tbOccupiedState->TryMoveToStalemate", tbBlackboard)
        -- 只要有非己方的人在都处于僵持
        local rInfo = tbBlackboard.rInfo
        if(rInfo.nOwnerTeamId == tbBlackboard.nMoreTeamId) then
            return tbBlackboard.nLessMemberCount > 0
        end
        return tbBlackboard.nMoreMemberCount > 0 
    end,
}

-- 占领中
local tbOccupingState = {
    szName = "OccupingState",
    nState = Proto.PVPOccupyAreaInfo_OccupyState.OCCUPING,
    OnActived = function(self, tbBlackboard)
        LogState(self.szName, tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        rInfo.nState = self.nState
        -- 只有当nOccupyingRemainTime为空，或者上一次占领的队伍和这次占领的队伍不一样，才重置时间，否则用老的
        if(rInfo.nOccupyingRemainTime == nil or rInfo.nOccupyingTeamId ~= tbBlackboard.nMoreTeamId) then
            rInfo.nOccupyingTeamId = tbBlackboard.nMoreTeamId
            assert(rInfo.nOccupyingTeamId >= 0)
            rInfo.nOccupyingRemainTime = tbBlackboard.nOccupyTime
            rInfo.nOccupyingMaxTime = tbBlackboard.nOccupyTime
        end        
        assert(rInfo.nOccupyingRemainTime > 0)
        tbBlackboard.Timer = Timer.NewTimer(function() self:OnTimer(tbBlackboard) end, rInfo.nOccupyingRemainTime, false)
        tbBlackboard.nPunishTime = 0
    end,
    OnTimer = function(self, tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        if tbBlackboard.nPunishTime > 0 then
            tbBlackboard.Timer = Timer.NewTimer(function() self:OnTimer(tbBlackboard) end, tbBlackboard.nPunishTime, false)
            rInfo.nOccupyingRemainTime = tbBlackboard.nPunishTime
            tbBlackboard.nPunishTime = 0
        else
            rInfo.nOwnerTeamId = rInfo.nOccupyingTeamId
            rInfo.nOccupyingRemainTime = 0
            tbBlackboard:TryCompleteState(self)
        end
    end,
    OnDeactived = function(self, tbBlackboard)        
        -- 这里不清Time，因为出了这个状态在回来得判上一次的队伍和新占领中的队伍是否一致，一致的话还用这个remaintime
        local rInfo = tbBlackboard.rInfo
        if(rInfo.nOccupyingRemainTime > 0) then
            assert(tbBlackboard.Timer)
            rInfo.nOccupyingRemainTime = tbBlackboard.Timer:GetRemainingTime() + tbBlackboard.nPunishTime
        end
        if(tbBlackboard.Timer) then
            tbBlackboard.Timer:Clear()
            tbBlackboard.Timer = nil
            tbBlackboard.nPunishTime = nil
        end                
    end,
    TryMoveToOccupied = function(self, tbToState, tbBlackboard)
        LogState("tbOccupingState->TryMoveToOccupied", tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        return (rInfo.nOccupyingTeamId == rInfo.nOwnerTeamId and rInfo.nOccupyingRemainTime == 0)    -- 到时间了
            or (tbBlackboard.nMoreMemberCount == 0 and rInfo.nOwnerTeamId ~= -1)         -- 有owner并且占一半离开了
    end,
    TryMoveToStalemate = function(self, tbToState, tbBlackboard)
        LogState("tbOccupingState->TryMoveToStalemate", tbBlackboard)
        -- 只要有非己方的人在都处于僵持
        local rInfo = tbBlackboard.rInfo
        if(rInfo.nOccupyingTeamId == tbBlackboard.nMoreTeamId) then
            return tbBlackboard.nLessMemberCount > 0
        end
        return tbBlackboard.nMoreMemberCount > 0
    end,
    TryMoveToNone = function(self, tbToState, tbBlackboard)
        LogState("tbOccupingState->TryMoveToNone", tbBlackboard)
        return tbBlackboard.nMoreMemberCount == 0 and tbBlackboard.rInfo.nOwnerTeamId == -1   -- 没人在并且没有老Owner
    end,
}

-- 僵持
local tbStalemateState = {
    szName = "StalemateState",
    nState = Proto.PVPOccupyAreaInfo_OccupyState.STALEMATE,
    OnActived = function(self, tbBlackboard)
        LogState(self.szName, tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        rInfo.nState = self.nState
    end,
    TryMoveToOccuping = function(self, tbToState, tbBlackboard)   
        LogState("tbStalemateState->TryMoveToOccuping", tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        if(rInfo.nOwnerTeamId == -1) then
            -- 无owner的情况下
            return tbBlackboard.nMoreTeamId >= 0 and tbBlackboard.nLessMemberCount == 0  -- 一方有人一方无人
        end

        --  有Owner的情况下，对方人数多，并且有Owner方的人数为0
        return tbBlackboard.nMoreTeamId >= 0 and
            rInfo.nOwnerTeamId ~= tbBlackboard.nMoreTeamId and
            tbBlackboard.nLessMemberCount == 0
    end,    
    TryMoveToOccupied = function(self, tbToState, tbBlackboard)
        LogState("tbStalemateState->TryMoveToOccupied", tbBlackboard)
        local rInfo = tbBlackboard.rInfo
        if(rInfo.nOwnerTeamId == -1) then
            return false
        end
        -- 非owner方人数为0
        return tbBlackboard.nLessMemberCount == 0
    end,
}


function PVPOccupyAreaStateMachine:Init()
    PVPOccupyAreaStateMachine.super.Init(self)

    self.tbIds = {}
    self:SetBlackboard(self)
    self:SetInitState(tbNoneState)
    self:AddState(tbOccupiedState)
    self:AddState(tbOccupingState)
    self:AddState(tbStalemateState)

    self:Link(tbNoneState, tbOccupingState, tbNoneState.TryMoveToOccuping)

    self:Link(tbOccupiedState, tbOccupingState, tbOccupiedState.TryMoveToOccuping)
    self:Link(tbOccupiedState, tbStalemateState, tbOccupiedState.TryMoveToStalemate)

    self:Link(tbOccupingState, tbOccupiedState, tbOccupingState.TryMoveToOccupied)
    self:Link(tbOccupingState, tbStalemateState, tbOccupingState.TryMoveToStalemate)
    self:Link(tbOccupingState, tbNoneState, tbOccupingState.TryMoveToNone)

    self:Link(tbStalemateState, tbOccupingState, tbStalemateState.TryMoveToOccuping)
    self:Link(tbStalemateState, tbOccupiedState, tbStalemateState.TryMoveToOccupied)
end

function PVPOccupyAreaStateMachine:SetParams(PVPOccupyAreaInfo, nOccupyTime, fnOnStateChanged)
    self.rInfo = PVPOccupyAreaInfo
    PVPOccupyAreaInfo.nOwnerTeamId = -1
    PVPOccupyAreaInfo.nOccupyingTeamId = -1
    PVPOccupyAreaInfo.nOccupyingRemainTime = nil
    PVPOccupyAreaInfo.nOccupyingMaxTime = nil

    self.nOccupyTime = nOccupyTime
    self.fnOnStateChanged = fnOnStateChanged
end

function PVPOccupyAreaStateMachine:OnEnter(nUniqueId, nTeamId)
    self.tbIds[nUniqueId] = nTeamId
    self.nMoreTeamId, self.nMoreMemberCount, self.nLessTeamId, self.nLessMemberCount = GetMoreNumberTeamId(self)
    log("GetMoreNumberTeamId", self.nMoreTeamId, self.nMoreMemberCount, self.nLessTeamId, self.nLessMemberCount)
    self:TryCompleteState(self.tbCurrentState)
end

function PVPOccupyAreaStateMachine:OnLeave(nUniqueId, nTeamId)
    self.tbIds[nUniqueId] = nil
    self.nMoreTeamId, self.nMoreMemberCount, self.nLessTeamId, self.nLessMemberCount = GetMoreNumberTeamId(self)
    log("GetMoreNumberTeamId", self.nMoreTeamId, self.nMoreMemberCount, self.nLessTeamId, self.nLessMemberCount)
    self:TryCompleteState(self.tbCurrentState)
end

function PVPOccupyAreaStateMachine:OnStateChanged(tbFromState, tbToState)
    if(self.fnOnStateChanged) then
        self.fnOnStateChanged(self, tbFromState, tbToState)
    end
end

function PVPOccupyAreaStateMachine:OnPunishOccupyingTime(nUniqueId, nTeamId, nPunishTime)
    assert(self.tbIds[nUniqueId] ~= nil)

    if nPunishTime <= 0 then
        return false
    end

    local tbBlackboard = self.tbBlackboard
    local rInfo = tbBlackboard.rInfo

    -- 注意：目前版本占领中状态下被击有惩罚，占领中->僵持被击有惩罚，占领了->僵持被击无惩罚，目前无此玩法，待有需求了，按需调整
    if rInfo.nOccupyingTeamId == nTeamId then
        local nOccupyingRemainTime = rInfo.nOccupyingRemainTime
        local nOccupyingMaxTime = rInfo.nOccupyingMaxTime
        assert(nOccupyingRemainTime > 0)
        assert(nOccupyingMaxTime > 0)

        if tbBlackboard.Timer then
            assert(tbBlackboard.nPunishTime ~= nil)
            local nTimerRemainingTime = tbBlackboard.Timer:GetRemainingTime()
            nOccupyingRemainTime = nTimerRemainingTime + tbBlackboard.nPunishTime + nPunishTime
            if nOccupyingRemainTime > nOccupyingMaxTime then
                nOccupyingRemainTime = nOccupyingMaxTime
            end
            tbBlackboard.nPunishTime = nOccupyingRemainTime - nTimerRemainingTime
            rInfo.nOccupyingRemainTime = nOccupyingRemainTime
            return true
        else
            local nOriginalRemainTime = nOccupyingRemainTime
            nOccupyingRemainTime = nOccupyingRemainTime + nPunishTime
            if nOccupyingRemainTime > nOccupyingMaxTime then
                nOccupyingRemainTime = nOccupyingMaxTime
            end
            rInfo.nOccupyingRemainTime = nOccupyingRemainTime
            return nOriginalRemainTime ~= nOccupyingRemainTime
        end
    end
    return false
end

function PVPOccupyAreaStateMachine:RefreshRepInfo()
    -- 目前只有nOccupyingRemainTime需要刷新
    local tbBlackboard = self.tbBlackboard
    local rInfo = tbBlackboard.rInfo
    if tbBlackboard.Timer then
        assert(tbBlackboard.nPunishTime ~= nil)
        local nTimerRemainingTime = tbBlackboard.Timer:GetRemainingTime()
        local nOccupyingRemainTime = nTimerRemainingTime + tbBlackboard.nPunishTime
        rInfo.nOccupyingRemainTime = nOccupyingRemainTime
    end
end

return PVPOccupyAreaStateMachine