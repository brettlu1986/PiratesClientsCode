-----------------------------------------------------
--File Name    : GuideActionRotateToTarget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionRotateToTarget = luaclass("GuideActionRotateToTarget", GuideActionFunctional)

--import
local CameraGameHelper = require("CameraGameHelper")

local function RotateToTarget(self)
    local tbTemplate = self.tbTemplate
    local nP1 = tonumber(tbTemplate.tbParam[1])
    local nP2 = tonumber(tbTemplate.tbParam[2])
    local nP3 = tonumber(tbTemplate.tbParam[3])
    local nP4 = tonumber(tbTemplate.tbParam[4])
    self:DebugLog("RotateToTarget X = " .. nP1 .. " Y = " .. nP2 .. " Z = " .. nP3 .. " Time = " .. nP4)
    local pLocation = Vector{X = nP1, Y = nP2, Z = nP3}
    CameraGameHelper.RotateToTarget(pLocation, nP4) 
end

function GuideActionRotateToTarget:DoAction(tbTemplate)
    GuideActionRotateToTarget.super.DoAction(self, tbTemplate)
    RotateToTarget(self)
end

return GuideActionRotateToTarget
