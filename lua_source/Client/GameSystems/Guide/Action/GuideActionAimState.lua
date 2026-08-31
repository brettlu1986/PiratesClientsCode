-----------------------------------------------------
--File Name    : GuideActionAimState.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionAimState       = luaclass("GuideActionAimState",GuideActionFunctional)

-- local HandlerManagerHelper = require("HandlerManagerHelper")

function GuideActionAimState:Begin()
    GuideActionAimState.super.Begin(self)
end

function GuideActionAimState:DoAction(tbTemplate)
    GuideActionAimState.super.DoAction(self, tbTemplate)
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)
end

return GuideActionAimState
