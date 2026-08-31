local luaclass = require("luaclass")
local HumanWeaponAttackHelper = luaclass("HumanWeaponAttackHelper")

local Timer = require("Timer")
local HumanWeaponMisc = require("HumanWeaponMisc")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local ExitType = HumanWeaponMisc.AttackExitType
local AUTO_FINISH       = 1
local PENDING_FINISH    = 2
local PENDING_CANCEL    = 3
local HAS_FINISHED      = 4

HumanWeaponAttackHelper.tbWeapon = nil
HumanWeaponAttackHelper.tbInfo = nil
HumanWeaponAttackHelper.tbStates = nil
HumanWeaponAttackHelper.nCurrentState = nil
HumanWeaponAttackHelper.nFinishType = HAS_FINISHED
HumanWeaponAttackHelper.StateTimer = nil

local TryStepNextState = nil
local Deactivate = nil
local Activate = nil
local OnFinished = nil
local CreateState = nil
local SetFinish = nil
local DeactivateAttackState = nil

local function GetCurrentState(self)
    return self.tbStates[self.nCurrentState]
end

local function DestroyTimer(self)
    local StateTimer = self.StateTimer
    if(StateTimer) then
        StateTimer:Clear()
        self.StateTimer = nil
    end
end

local function TryCreateTimer(self, fnFunc, nTime, bLoop)
    DestroyTimer(self)
    if(nTime > 0) then
        self.StateTimer = Timer.NewTimer(fnFunc, nTime, bLoop)
    else
        fnFunc()
    end
end

local function Clear(self)
    self.tbWeapon = nil
    self.tbInfo = nil
    self.tbStates = nil
    self.nCurrentState = nil
    self.nAttackCD = nil
    self.nFinishType = HAS_FINISHED
    DestroyTimer(self)
end

Deactivate = function(self, tbState, bCancel)
    if(GetCurrentState(self) ~= tbState) then
        return
    end

    if(tbState.bOnDeactivate) then
        return
    end
    tbState.bOnDeactivate = true
    tbState.bOnActivate = false

    DestroyTimer(self)
    local tbSubInfo = tbState.tbSubInfo
    assert(tbSubInfo)
    if(tbSubInfo.OnDeactivate) then
        tbSubInfo.OnDeactivate(self.tbWeapon, self.tbInfo, bCancel, tbSubInfo)
    end

    TryStepNextState(self)
    tbState.bOnDeactivate = false
end

Activate = function(self, tbState)
    if(GetCurrentState(self) ~= tbState) then
        return
    end

    if(tbState.bOnActivate) then
        return
    end
    tbState.bOnDeactivate = false
    tbState.bOnActivate = true

    local tbSubInfo = tbState.tbSubInfo
    assert(tbSubInfo)
    if(tbSubInfo.OnActivate) then
        tbSubInfo.OnActivate(self.tbWeapon, self.tbInfo, tbSubInfo)
    end

    local nDuration = tbSubInfo.nDuration
    if GlobalVariableSystem.bIsClient and GlobalVariableSystem.nAttackCDTime >= 0 then
        nDuration = GlobalVariableSystem.nAttackCDTime
    end
    if(nDuration ~= nil and nDuration >= 0) then
        TryCreateTimer(self, function()
            self.Timer = nil
            Deactivate(self, tbState, false)
        end, nDuration, false)
    end

    tbState.bOnActivate = false
end

TryStepNextState = function(self)
    local nFinishType = self.nFinishType
    local bCancel = nFinishType == PENDING_CANCEL
    if(bCancel) then
        -- 直接cancel，不走底下了
        OnFinished(self, true)
        return
    end

    local tbInfo = self.tbInfo
    local nCurrentState = self.nCurrentState
    --local tbCurrentState = self.tbStates[nCurrentState]
    local bPendingFinish = nFinishType == PENDING_FINISH -- or bCancel
    local bFinished = false
    local bAllStateEnd = nCurrentState == tbInfo.nStateCount
    local nAllLoopCount = tbInfo.nAllLoopCount

    if(nCurrentState ~= 0) then
        if(bPendingFinish and tbInfo.nExitTypeWhenFinish == ExitType.CURRENT_STATE_FINISHED) then
            bFinished = true
        elseif(bAllStateEnd) then
            if(nAllLoopCount ~= nil and nAllLoopCount > 0) then
                nAllLoopCount = nAllLoopCount - 1
                tbInfo.nAllLoopCount = nAllLoopCount
            end
            if(nAllLoopCount == 0) then
                -- 都循环完了，所以结束
                bFinished = true
            elseif(bPendingFinish and tbInfo.nExitTypeWhenFinish == ExitType.ALL_STATE_FINISHED) then
                bFinished = true
            else
                nCurrentState = 0
            end
        end
    end

    if(bFinished) then
        -- Finish attack
        OnFinished(self, bCancel)
        return
    end

    -- 起下一个
    local nNewState = nCurrentState + 1
    self.nCurrentState = nNewState
    local tbNewState = self.tbStates[nNewState]
    Activate(self, tbNewState)

    if(bPendingFinish) then
        if(tbNewState.tbSubInfo.bCanDeactivateExternally) then
            Deactivate(self, tbNewState, bCancel)
        end
    end
end

OnFinished = function(self, bCancel)
    self.nFinishType = HAS_FINISHED
    local fnOnFinished = self.tbInfo.OnFinished
    if(fnOnFinished) then
        fnOnFinished(self.tbWeapon, self.tbInfo, bCancel)
    end
    DeactivateAttackState(self.OwnerComponent, bCancel)
end

CreateState = function(self, tbInfo, nState)
    local tbState = {}
    local tbSubInfo = tbInfo[nState]
    assert(tbSubInfo)
    tbState.nState = nState
    tbState.tbSubInfo = tbSubInfo
    self.tbStates[nState] = tbState
    return tbState
end

SetFinish = function(self, nFinishType)
    local nCurrentFinishType = self.nFinishType
    if(nCurrentFinishType == HAS_FINISHED or nCurrentFinishType ~= AUTO_FINISH) then
        return
    end

    self.nFinishType = nFinishType
    local tbState = GetCurrentState(self)
    if(tbState and tbState.tbSubInfo.bCanDeactivateExternally) then
        local bCancel = nFinishType == PENDING_CANCEL
        Deactivate(self, tbState, bCancel)
    end
end

---------------------------------------------------------------------------------------
function HumanWeaponAttackHelper:Init(OwnerComponent, fnDeactivateAttackState)
    self.OwnerComponent = OwnerComponent
    DeactivateAttackState = fnDeactivateAttackState
end

function HumanWeaponAttackHelper:Uninit()
    Clear(self)
end

function HumanWeaponAttackHelper:StartAttack(tbWeapon, tbAttackInfo)
    if not self:IsFinished() then  
        logerror("StartAttack Error Attack Is Not Finish", self.nFinishType)
        return
    end 

    self.tbWeapon = tbWeapon
    self.tbStates = {}
    self.tbInfo = tbAttackInfo
    local nStateCount = tbAttackInfo.nStateCount
    assert(nStateCount > 0)
    for i=1, nStateCount do
        CreateState(self, tbAttackInfo, i)
    end

    self.nCurrentState = 0
    self.nFinishType = AUTO_FINISH
    TryStepNextState(self)
end

function HumanWeaponAttackHelper:FinishAttack()
    SetFinish(self, PENDING_FINISH)
end

function HumanWeaponAttackHelper:CancelAttack()
    --logdebug("CancelAttack")
    --SetFinish(self, PENDING_CANCEL)

    -- 直接停，现阶段没有pending cancel的需求
    if(not self:IsFinished()) then
        self.nFinishType = PENDING_CANCEL
        Deactivate(self, GetCurrentState(self), true)
    end
end

function HumanWeaponAttackHelper:IsFinished()
    return self.nFinishType == HAS_FINISHED
end

function HumanWeaponAttackHelper:GetCD()
    return self.tbInfo.nCD
end

function HumanWeaponAttackHelper:IsPendingFinished(bIncludeCancel)
    if(self.nFinishType == PENDING_FINISH) then
        return true
    end

    return bIncludeCancel and self.nFinishType == PENDING_CANCEL
end

return HumanWeaponAttackHelper