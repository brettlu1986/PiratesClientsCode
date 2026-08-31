-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanBowAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanBowAim = luaclass("UPHumanBowAim", UPHumanWeaponAim)



--member function

function UPHumanBowAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanBowAim.super.ScaleToTargetSize(self,bReset, bFirstAttack)
end


return UPHumanBowAim
