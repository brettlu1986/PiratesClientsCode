-----------------------------------------------------
--File Name    : AbilityAction_ShipBulletReloadSpeedRatio.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 修改炮弹Load速度
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipBulletReloadSpeedRatio = luaclass("AbilityAction_ShipBulletReloadSpeedRatio", AbilityActionPropBase)

function AbilityAction_ShipBulletReloadSpeedRatio:GetWrapperName()
    return require("PropName").nReloadSpeedRatio
end

return AbilityAction_ShipBulletReloadSpeedRatio
