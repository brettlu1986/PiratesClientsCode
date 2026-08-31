local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattlePlayerStateComponent = luaclass("BattlePlayerStateComponent", GameComponentBaseClass)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattlePlayerStateComponent.GamePlayerState = nil

function BattlePlayerStateComponent:OnCreate(Owner, tbParams)
    BattlePlayerStateComponent.super.OnCreate(self, Owner, tbParams)
    local TempPlayerState = BattleGameModeSystem:GetPlayerState(Owner.nPlayerId)
    if( TempPlayerState ~= nil ) then
        self:SetGamePlayerState(TempPlayerState)
    end
end

function BattlePlayerStateComponent:SetGamePlayerState(tbPlayerState)
    self.GamePlayerState = tbPlayerState
end

function BattlePlayerStateComponent:GetGamePlayerState()
    return self.GamePlayerState
end

function BattlePlayerStateComponent:OnActorDestroyed(pUEActor)
    self.GamePlayerState = nil
    BattlePlayerStateComponent.super.OnActorDestroyed(self)
end


return BattlePlayerStateComponent