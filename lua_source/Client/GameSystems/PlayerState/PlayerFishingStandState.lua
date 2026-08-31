local luaclass                  = require("luaclass")
local PlayerFishingCommonState  = require("PlayerFishingCommonState")
local PlayerFishingStandState   = luaclass("PlayerFishingStandState", PlayerFishingCommonState)
local PlayerAnimDef             = require("PlayerAnimDef")

local function OnEnterStand(self)
    if self:IsActived() then
        self.szAnimKey = PlayerAnimDef.PAN_FISHING_STAND
        self:PlayAnimation()
    end
end

function PlayerFishingStandState:Init(szName, tbParams)
    PlayerFishingStandState.super.Init(self, szName, tbParams)
    
    self.szAnimKey   = PlayerAnimDef.PAN_FISHING_ENTER
    self.fnAnimComplete = function() 
        OnEnterStand(self)
    end
end

function PlayerFishingStandState:Uninit()
    PlayerFishingStandState.super.Uninit(self)
end

function PlayerFishingStandState:OnActive(tbParams)
    if tbParams then
        if tbParams.bSuccess ~= nil then
            self.szAnimKey = tbParams.bSuccess and PlayerAnimDef.PAN_FISHING_SUCESS or PlayerAnimDef.PAN_FISHING_FAIL
        elseif tbParams.bPlayInstantAnim ~= nil then
            self.szAnimKey = tbParams.bPlayInstantAnim and PlayerAnimDef.PAN_FISHING_ENTER or PlayerAnimDef.PAN_FISHING_STAND
        else
            self.szAnimKey = PlayerAnimDef.PAN_FISHING_ENTER
        end
    else
        self.szAnimKey = PlayerAnimDef.PAN_FISHING_ENTER
    end

    PlayerFishingStandState.super.OnActive(self, tbParams)
end

function PlayerFishingStandState:OnDeactive()
    PlayerFishingStandState.super.OnDeactive(self)
end

return PlayerFishingStandState