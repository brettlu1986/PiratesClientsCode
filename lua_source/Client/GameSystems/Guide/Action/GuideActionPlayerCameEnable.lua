-----------------------------------------------------
--File Name    : GuideActionTeamInfoEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionFunctional                 = require("GuideActionFunctional")
local GuideActionPlayerCameEnable           = luaclass("GuideActionPlayerCameEnable", GuideActionFunctional)

--import
local GamePlayerSelfHelper        = require("GamePlayerSelfHelper")
--local 

local function SetPlayerCameEnable(self)
    local tbTemplate = self.tbTemplate
    local bEnable = tbTemplate.bEnable
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    self:DebugLog("GuideActionPlayerCameEnable SetPlayerCameEnable " .. tostring(bEnable))
    tbPlayerSelf.pUEActor.PlayerInputComponent:SetCameraControlEnable(bEnable)
end

function GuideActionPlayerCameEnable:Begin()
    self:DebugLog("GuideActionPlayerCameEnable Begin")
    GuideActionPlayerCameEnable.super.Begin(self)
    SetPlayerCameEnable(self)
end

return GuideActionPlayerCameEnable
