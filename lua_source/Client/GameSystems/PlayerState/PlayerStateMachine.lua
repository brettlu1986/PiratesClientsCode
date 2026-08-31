local luaclass          = require("luaclass")
local BaseStateMachine  = require("BaseStateMachine")
local PlayerStateMachine= luaclass("PlayerStateMachine", BaseStateMachine)
local PlayerStateDef    = require("PlayerStateDef")

PlayerStateMachine.tbOwner = nil
PlayerStateMachine.tbFishingState = nil

local function TryToFishing(self, _tbFromState, _tbToState, tbParams)
    local nStateId = tbParams and tbParams.nStateId
    if nStateId then 
        return nStateId >= PlayerStateDef.PS_FISHING_STAND and nStateId <= PlayerStateDef.PS_FISHING_WAIT
    end
    return false
end

local function TryToNormal(self, _tbFromState, _tbToState, tbParams)
    local nStateId = tbParams and tbParams.nStateId
    if nStateId then 
        return nStateId == PlayerStateDef.PS_NORMAL
    end
    return false
end

function PlayerStateMachine:Init(tbOwner)
    self.tbOwner = tbOwner
    PlayerStateMachine.super.Init(self)
    self:SetBlackboard(self)
end

function PlayerStateMachine:DefineAll()
    local Owner    = self.tbOwner
    local tbNormalState  = self:DefineInitState("PlayerState", {tbOwner = Owner})
    local tbFishingState = self:DefineState("PlayerFishingState",{tbOwner = Owner})

    self:Link(tbNormalState, tbFishingState,  TryToFishing)
    self:Link(tbFishingState, tbNormalState,  TryToNormal)

    self.tbFishingState = tbFishingState
end

function PlayerStateMachine:Uninit()
    self.tbFishingState = nil
    self.tbOwner = nil
    PlayerStateMachine.super.Uninit(self)
end

function PlayerStateMachine:TryTransfer(tbParams)
    local bRet = PlayerStateMachine.super.TryTransfer(self, tbParams)
    if not bRet then
        if self.tbCurrentState.TryTransfer then
            bRet = self.tbCurrentState:TryTransfer(tbParams)
        end
    end

    return bRet
end

function PlayerStateMachine:CanTransfer(tbParams)
    local bRet = PlayerStateMachine.super.CanTransfer(self, tbParams)
    if not bRet then
        if self.tbCurrentState.CanTransfer then
            bRet = self.tbCurrentState:CanTransfer(tbParams)
        end
    end

    return bRet
end

return PlayerStateMachine