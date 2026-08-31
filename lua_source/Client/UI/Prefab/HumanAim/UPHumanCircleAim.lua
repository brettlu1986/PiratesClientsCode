-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanCircleAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanCircleAim = luaclass("UPHumanCircleAim", UPHumanWeaponAim)



--member function

function UPHumanCircleAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanCircleAim.super.ScaleToTargetSize(self, bReset, bFirstAttack)
end


return UPHumanCircleAim
