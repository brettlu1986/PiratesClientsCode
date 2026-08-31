-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanCrossAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanCrossAim = luaclass("UPHumanCrossAim", UPHumanWeaponAim)



--member function

function UPHumanCrossAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanCrossAim.super.ScaleToTargetSize(self, bReset, bFirstAttack)
end


return UPHumanCrossAim
