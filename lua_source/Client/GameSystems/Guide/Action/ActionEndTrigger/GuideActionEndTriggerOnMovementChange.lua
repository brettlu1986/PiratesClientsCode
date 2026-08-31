-----------------------------------------------------
--File Name    : GuideActionEndTriggerOnMovementChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerOnMovementChange     = luaclass("GuideActionEndTriggerOnMovementChange", GuideActionEndTriggerBase)

local CommonEventDef        = require("CommonEventDef")
local GameObjectTypeDef     = require("GameObjectTypeDef")
local HumanMovementStateType= require("HumanMovementStateType")
-----------------------------------------------------

local function OnHumanMovementStateChange(self, Player, nOldState, nNewState)
    self:DebugLog("OnHumanMovementStateChange")
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local szMovement = self.tbParam[1]
    self:DebugLog("OnHumanMovementStateChange, szMovement = " .. szMovement)
    local bResult = false
    if szMovement == "inship" then
        bResult = nNewState == HumanMovementStateType.InPlane_State
    elseif szMovement == "parachute" then
        bResult = nNewState == HumanMovementStateType.Parachutine_State
    elseif szMovement == "land" then
        bResult = (nOldState == HumanMovementStateType.Parachutine_State and nNewState == HumanMovementStateType.UpRight_State)
    elseif szMovement == "swiming" then
        bResult = nNewState == HumanMovementStateType.Swimming
    end
    if bResult then
        self:Triggered()
    end
end

function GuideActionEndTriggerOnMovementChange:BindEvent(tbParam)
    GuideActionEndTriggerOnMovementChange.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChange)
end

return GuideActionEndTriggerOnMovementChange
