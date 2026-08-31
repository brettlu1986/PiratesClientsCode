local luaclass = require("luaclass")
local GameComponentBase     = require("GameComponentBase")
local PlayerStateComponent  = luaclass("PlayerStateComponent", GameComponentBase)
local PlayerStateMachine    = require("PlayerStateMachine")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")

PlayerStateComponent.tbStateMachine = nil
PlayerStateComponent.tbParams = nil

function PlayerStateComponent:OnCreate(Owner, tbParams)
    PlayerStateComponent.super.OnCreate(self, Owner, tbParams)

    self.nStateId = tbParams
    local tbStateMachine = PlayerStateMachine()
    tbStateMachine:Init(Owner)
    self.tbStateMachine = tbStateMachine 

    return true  
end

function PlayerStateComponent:OnDestroy()
    self.tbParams = nil
    self.tbStateMachine:Uninit()
    self.tbStateMachine = nil

    PlayerStateComponent.super.OnDestroy(self)
end

function PlayerStateComponent:OnActorCreated(pUEActor)
    self:Start()
    self:TryTransfer({nStateId = self.nStateId, bPlayInstantAnim = GamePlayerSelfHelper:Get() == self.Owner})
end

function PlayerStateComponent:Start()
    self.tbStateMachine:Start()
end

function PlayerStateComponent:TryTransfer(tbParams)
    self.tbStateMachine:TryTransfer(tbParams)
end

function PlayerStateComponent:CanTransfer(tbParams)
    return self.tbStateMachine:CanTransfer(tbParams)
end

return PlayerStateComponent
