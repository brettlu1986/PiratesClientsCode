-----------------------------------------------------
--File Name    : GuideActionShipSailChange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionBase           = require("GuideActionBase")
local GuideActionShipSailChange = luaclass("GuideActionShipSailChange",GuideActionBase)

local ClientEventDef            = require("ClientEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")

local function OnShipSetPosture(self, nOldPosture, nCurPosture)
    self:DebugLog("OnShipSetPosture nOldPosture = " .. nOldPosture .. " nCurPosture = " .. nCurPosture .. " nRequirePosture = " .. self.nRequirePosture)
    if nOldPosture == self.nRequirePosture and nCurPosture ~= self.nRequirePosture then
        self:EndAction()
    end
end

local function OnPlayerSelfReady(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf:IsHuman() then
        self:EndAction()
    end
end

function GuideActionShipSailChange:Begin()
    GuideActionShipSailChange.super.Begin(self)
	self.nRequirePosture = tonumber(self.tbTemplate.tbParam[2])
end

function GuideActionShipSailChange:BindEvent()
    GuideActionShipSailChange.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_SET_POSTURE, self, OnShipSetPosture)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_BINDREPLICATE_UEACTOR, self, OnPlayerSelfReady)
end

function GuideActionShipSailChange:EndAction()
    self:DebugLog("EndAction")
    self:ForceEndCurrentStep()
end

return GuideActionShipSailChange
