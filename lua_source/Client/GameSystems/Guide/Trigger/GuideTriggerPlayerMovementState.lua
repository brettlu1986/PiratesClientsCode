-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideTrigger                          = require("GuideTrigger")
local GuideTriggerPlayerMovementState       = luaclass("GuideTriggerPlayerMovementState", GuideTrigger)

local CommonEventDef            = require("CommonEventDef")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local HumanMovementStateType    = require("HumanMovementStateType")
-----------------------------------------------------

function GuideTriggerPlayerMovementState:OnHumanMovementStateChange(Player, nOldState, nNewState)
    self:DebugLog("nOldState = " .. nOldState .. " nNewState " .. nNewState)
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local szMovement = tbParam[1]
    self:DebugLog("OnHumanMovementStateChange, szMovement = " .. szMovement)
    local bResult = false
    if szMovement == "inship" then
        bResult = nNewState == HumanMovementStateType.InPlane_State
    elseif szMovement == "parachute" then
        bResult = nNewState == HumanMovementStateType.Parachutine_State
    elseif szMovement == "land" then
        bResult = (nOldState == HumanMovementStateType.Gliding_State and nNewState == HumanMovementStateType.UpRight_State)
    elseif szMovement == "swiming" then
        bResult = nNewState == HumanMovementStateType.Swimming
    end
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
    self:DebugLog("OnHumanMovementStateChange, bResult = " .. tostring(bResult))
end

--override
function GuideTriggerPlayerMovementState:Begin()
    GuideTriggerPlayerMovementState.super.Begin(self)
end

function GuideTriggerPlayerMovementState:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, self.OnHumanMovementStateChange)
end

return GuideTriggerPlayerMovementState
