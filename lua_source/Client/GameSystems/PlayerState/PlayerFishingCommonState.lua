local luaclass                  = require("luaclass")
local PlayerState               = require("PlayerState")
local PlayerFishingCommonState  = luaclass("PlayerFishingCommonState", PlayerState)

PlayerFishingCommonState.nWeaponId = nil

function PlayerFishingCommonState:Init(szName, tbParams)
    self.nWeaponId = tbParams.nWeaponId
    PlayerFishingCommonState.super.Init(self, szName, tbParams)
end

function PlayerFishingCommonState:Uninit()
    self.nWeaponId = nil
    PlayerFishingCommonState.super.Uninit(self)
end

local function PlayPartAnimation(self)
    if not self.nWeaponId then
        return false
    end
    return self.tbAnimationHelper:PlayHumanPartAnimation(self.tbOwner.pUEActor, "RightScabbard", self.nWeaponId, self.szAnimKey)
end

function PlayerFishingCommonState:PlayAnimation()
    if not PlayerFishingCommonState.super.PlayAnimation(self) then
        return false
    end

    return PlayPartAnimation(self)
end

return PlayerFishingCommonState