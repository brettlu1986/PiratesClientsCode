-----------------------------------------------------
--File Name    : GuideActionShowShipWeaponVideoText.lua
--Author       : Edward J
--Create Time  : 2020-08-21
--Description  : 
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionFunctional                 = require("GuideActionFunctional")
local GuideActionShowShipWeaponVideoText    = luaclass("GuideActionShowShipWeaponVideoText", GuideActionFunctional)
-----------------------------------------------------

-----------------------------------------------------

function GuideActionShowShipWeaponVideoText:DoAction(tbTemplate)
    GuideActionShowShipWeaponVideoText.super.DoAction(self, tbTemplate)
    self:CallShowShipWeaponVideoText()
end

return GuideActionShowShipWeaponVideoText
