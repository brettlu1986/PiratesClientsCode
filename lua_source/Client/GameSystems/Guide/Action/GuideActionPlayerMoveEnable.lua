-----------------------------------------------------
--File Name    : GuideActionTeamInfoEnable.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionFunctional                 = require("GuideActionFunctional")
local GuideActionPlayerMoveEnable           = luaclass("GuideActionPlayerMoveEnable", GuideActionFunctional)

--import
local GamePlayerSelfHelper        = require("GamePlayerSelfHelper")
--local 

local function SetPlayerMoveEnable(self)
    local tbTemplate = self.tbTemplate
    local bEnable = tbTemplate.bEnable
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local bIsHuman = tbPlayerSelf:IsHuman()
    if not bIsHuman then
        return
    end
    self:DebugLog("GuideActionPlayerMoveEnable SetPlayerMoveEnable " .. tostring(bEnable))
    tbPlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(bEnable)
end

function GuideActionPlayerMoveEnable:Begin()
    self:DebugLog("GuideActionPlayerMoveEnable Begin")
    GuideActionPlayerMoveEnable.super.Begin(self)
    SetPlayerMoveEnable(self)
end

return GuideActionPlayerMoveEnable
