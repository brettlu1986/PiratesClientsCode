-----------------------------------------------------
--Author       : lzheng
--Description  : UPHumanSniperAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanWeaponAim = require("UPHumanWeaponAim")
local UPHumanSniperAim = luaclass("UPHumanSniperAim", UPHumanWeaponAim)



--member function

function UPHumanSniperAim:ScaleToTargetSize(bReset, bFirstAttack)
    UPHumanSniperAim.super.ScaleToTargetSize(self, bReset, bFirstAttack)
end


return UPHumanSniperAim
