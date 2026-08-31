local luaclass = require("luaclass")
local HumanWeaponStateLocalHelper = luaclass("HumanWeaponStateLocalHelper")

local HumanWeaponStateDef = require("HumanWeaponStateDef")
local Timer = require("Timer")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local STATE_TIMER = "StateTimer"

HumanWeaponStateLocalHelper.OwnerComponent = nil
HumanWeaponStateLocalHelper.nCurrentState = HumanWeaponStateDef.NONE
HumanWeaponStateLocalHelper.nLastState = HumanWeaponStateDef.NONE
HumanWeaponStateLocalHelper.tbStates = nil

---------------------------------------------------------------
-- helper
local function GetCurrentState(self)
    return self.tbStates[self.nCurrentState]
end

local function Deactivate(self, tbState, bCancel)
    if(tbState.bOnDeactivate) then
        return
    end
    tbState.bOnDeactivate = true
    tbState.bOnActivate = false

    local OwnerComponent = self.OwnerComponent
    OwnerComponent:OnStateDeactivate(tbState.nState, bCancel)

    Timer.StopOwnerTimer(self, STATE_TIMER)

    if(tbState.OnDeactivate) then
        tbState.OnDeactivate(self, tbState, OwnerComponent, bCancel)
    end
end

local function DeactivateFromTimer(self)
    Deactivate(self, GetCurrentState(self), false)
end

local function Activate(self, tbState)
    if(tbState.bOnActivate) then
        return
    end
    tbState.bOnDeactivate = false
    tbState.bOnActivate = true

    local OwnerComponent = self.OwnerComponent
    local nInstanceId = OwnerComponent:GetCurrentWeaponInstanceId()
    if(tbState.bMustHaveWeapon and nInstanceId == 0) then
        error(string.format("Invalid current weapon, currrent state: %s, new state: %s bMustHaveWeapon: %s nCurrentWeaponInstanceId: %d",
            HumanWeaponStateDef.v2s(self:GetLastState()),
            HumanWeaponStateDef.v2s(tbState.nState),
            tostring(tbState.bMustHaveWeapon),
            nInstanceId))
    end

    
    OwnerComponent:OnStateActivate(tbState.nState)
    local nTime = OwnerComponent:GetCurrentStateElapsedTime()
    if(nTime ~= nil) then
        Timer.StartOwnerTimer(self, STATE_TIMER, DeactivateFromTimer, nTime)
    else
        Timer.StopOwnerTimer(self, STATE_TIMER)
    end

    if(tbState.OnActivate) then
        tbState.OnActivate(self, tbState, OwnerComponent)
    end
end

local function CreateState(self, nState, tbState)
    self.tbStates[nState] = tbState
    tbState.nState = nState
    return tbState
end

local function InitStates(self)
    local tbStates = {}
    self.tbStates = tbStates
    CreateState(self, HumanWeaponStateDef.NONE, {
    })

    CreateState(self, HumanWeaponStateDef.UNHOLDED, {
    })

    CreateState(self, HumanWeaponStateDef.UNHOLDING, {
        bMustHaveWeapon = true,
        OnDeactivate = function(Helper, SelfState, OwnerComponent, bCancel)
            if(bCancel) then
                return
            end

            Helper:ChangeState(HumanWeaponStateDef.UNHOLDED)
        end
    })

    CreateState(self, HumanWeaponStateDef.HOLDED, {
        bMustHaveWeapon = true,
    })

    CreateState(self, HumanWeaponStateDef.HOLDING, {
        bMustHaveWeapon = true,
        OnDeactivate = function(Helper, SelfState, OwnerComponent, bCancel)
            if(bCancel) then
                return
            end

            Helper:ChangeState(HumanWeaponStateDef.HOLDED)
        end
    })

    CreateState(self, HumanWeaponStateDef.RELOADING, {
        bMustHaveWeapon = true,
        OnDeactivate = function(Helper, SelfState, OwnerComponent, bCancel)
            if(bCancel) then
                return
            end

            if(OwnerComponent:GetCurrentWeapon() == nil) then
                Helper:ChangeState(HumanWeaponStateDef.UNHOLDED)
            else
                Helper:ChangeState(HumanWeaponStateDef.HOLDED)
            end
        end
    })

    -- CreateState(self, HumanWeaponStateDef.AIMING, {
    -- })

    CreateState(self, HumanWeaponStateDef.ATTACKING, {
        bMustHaveWeapon = false, -- 因为有空手攻击，所以这里得false
        OnDeactivate = function(Helper, SelfState, OwnerComponent, bCancel)
            if(bCancel) then
                OwnerComponent:CancelAttack()
                return
            end
        end        
    })
end

---------------------------------------------------------------
-- public interface
function HumanWeaponStateLocalHelper:Init(OwnerComponent)
    self.OwnerComponent = OwnerComponent

    InitStates(self)
end

function HumanWeaponStateLocalHelper:Uninit()
    local tbState = GetCurrentState(self)
    if(tbState) then
        Deactivate(self, tbState, true)
    end
    Timer.StopOwnerTimer(self, STATE_TIMER)
    self.nCurrentState = HumanWeaponStateDef.NONE
    self.nLastState = HumanWeaponStateDef.NONE
end

function HumanWeaponStateLocalHelper:ChangeState(nNewState, bCancel)
    local nCurrentState = self.nCurrentState

    -- 允许强制刷同一个状态，这个大部分是为了刷当前武器状态
    -- if(nNewState == nCurrentState) then
    --     return false
    -- end
    -- logdebug("ChangeState nNewState", nNewState, "nCurrentState", nCurrentState, "bCancel", bCancel)
    local tbStates = self.tbStates
    local tbOldState = tbStates[nCurrentState]
    if(tbOldState) then
        Deactivate(self, tbOldState, bCancel)
    end
    -- logdebug("nCurrentState", nCurrentState, "nNewState", nNewState, "bCancel", bCancel, debug.traceback())
    self.nLastState = nCurrentState
    self.nCurrentState = nNewState
    local tbNewState = tbStates[nNewState]
    if(tbNewState) then
        Activate(self, tbNewState)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_STATE_CHANGED_CLIENT, nNewState, self.OwnerComponent.Owner)
    return true
end

function HumanWeaponStateLocalHelper:GetCurrentState()
    return self.nCurrentState
end

function HumanWeaponStateLocalHelper:GetLastState()
    return self.nLastState
end

return HumanWeaponStateLocalHelper