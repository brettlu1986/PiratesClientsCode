-----------------------------------------------------
--File Name    : GuideActionShowPort.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionShowPort   = luaclass("GuideActionShowPort", GuideActionFunctional)

local MiniMapSystem = require("MiniMapSystem")

function GuideActionShowPort:DoAction(tbTemplate)
    GuideActionShowPort.super.DoAction(self, tbTemplate)
    local tbParam = tbTemplate.tbParam
    if not tbParam or #tbParam == 0 then
        return
    end
    MiniMapSystem:ShowPort(tonumber(tbParam[1]))
end

return GuideActionShowPort
