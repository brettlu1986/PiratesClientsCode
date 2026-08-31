-----------------------------------------------------
--File Name    : AbilityAction_ControlModeSwitchSpeedRatio.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-13
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ControlModeSwitchSpeedRatio = luaclass("AbilityAction_ControlModeSwitchSpeedRatio", AbilityActionPropBase)

function AbilityAction_ControlModeSwitchSpeedRatio:GetWrapperName()
    return require("PropName").nControlModeSwitchSpeedRatio
end

return AbilityAction_ControlModeSwitchSpeedRatio
