-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanWandAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanWandAim = luaclass("UPHumanWandAim", UPHumanWeaponAim)

local ClientEventDef = require("ClientEventDef")

local function OnWeaponAccumulate(self, bFocus, nPreAttackTime, nMaxAccumulateTime)
    --logdebug("OnWeaponAccumulate",nPreAttackTime,nMaxAccumulateTime, bFocus)
    local pCirclepgbWnd = self.pWidgetRef.circlepgbWand
    if not bFocus then
        pCirclepgbWnd:StopAnimation()
        pCirclepgbWnd:SetPercent(0)
        return
    end
    pCirclepgbWnd:SetPercent(0)
    pCirclepgbWnd.AnimDuration = nPreAttackTime
    pCirclepgbWnd:SetPercent(1, true)
end

--member function
function UPHumanWandAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanWandAim.super.ScaleToTargetSize(self,bReset, bFirstAttack)
end

function UPHumanWandAim:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, self, OnWeaponAccumulate)
    --EventHelper:RegisterCppDelegate(self.pWidgetRef.circlepgbWand.OnAnimationFinished, self, OnProgressBarAnimFinished)
end

return UPHumanWandAim
