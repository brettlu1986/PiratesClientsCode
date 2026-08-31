-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideTriggerEnterInshore  = luaclass("GuideTriggerEnterInshore", GuideTrigger)

local ClientEventDef            = require("ClientEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local ControlModeSystem         = require("ControlModeSystem")
local ControlModeDef            = require("ControlModeDef")
local HumanMovementStateType    = require ("HumanMovementStateType")
local BattleLandSystem          = dynamic_require("BattleLandSystem")
-----------------------------------------------------
-- GuideTriggerEnterInshore.bVisible   = false
GuideTriggerEnterInshore.szType     = ""
GuideTriggerEnterInshore.PlayerSelf = nil
-----------------------------------------------------
function GuideTriggerEnterInshore:OnEnterInshore(bVisible)
    self:DebugLog("GuideTriggerEnterInshore:OnEnterInshore, bVisible = " .. tostring(bVisible))
    if bVisible then
        self:Check()
    end
end

function GuideTriggerEnterInshore:Check()
    --local bVisible = self.bVisible
    local bResult = false
    local PlayerSelf = self.PlayerSelf
    local szType = self.szType
    local nCurrentContorlMode = ControlModeSystem:GetCurrentModeType()
    self:DebugLog("OnEnterInshore current mode type = " .. tostring(nCurrentContorlMode))
    local bIsHuman = PlayerSelf:IsHuman()
    if szType == "gotosea" and bIsHuman then
        local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
        local nCurState = HumanMovementStateComponent:GetCurrentState()
        bResult =  nCurrentContorlMode == ControlModeDef.HUMAN and (nCurState == HumanMovementStateType.UpRight_State or nCurState == HumanMovementStateType.Crouch_State or nCurState == HumanMovementStateType.Crawl_State or nCurState == HumanMovementStateType.Vehicle)
    elseif szType == "gotoland" and not bIsHuman then
        bResult =  nCurrentContorlMode == ControlModeDef.SHIP
    end
    self:DebugLog("OnEnterInshore, bResult = " .. tostring(bResult))
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerEnterInshore:ControlModeChange(nControlMode)
    self:DebugLog("ControlModeChange, ControlModeChange = " .. tostring(nControlMode))
    local nTargetRegionType = BattleLandSystem:GetTargetRegionTypeByLocation(self.PlayerSelf)
    local szType = self.szType
    if nTargetRegionType == nil then
        return
    end
    if (szType == "gotosea" and nControlMode == ControlModeDef.HUMAN) or (szType == "gotoland" and nControlMode == ControlModeDef.SHIP) then
        self:Check()
    end
end

--override
function GuideTriggerEnterInshore:Begin()
    GuideTriggerEnterInshore.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.szType = tbParam[1]
    self.PlayerSelf = GamePlayerSelfHelper:Get()
end

function GuideTriggerEnterInshore:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_CHANGE_DISPLAY, self, self.OnEnterInshore)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, self.ControlModeChange)
end

return GuideTriggerEnterInshore
