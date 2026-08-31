-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                    = require("luaclass")
local GuideTrigger                = require("GuideTrigger")
local GuideTriggerPlayerHP        = luaclass("GuideTriggerPlayerHP", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local HumanMovementStateType        = require("HumanMovementStateType")
local GameObjectTypeDef             = require("GameObjectTypeDef")
local ClientEventDef                = require("ClientEventDef")
local HumanMovementStateComponent   = dynamic_require("HumanMovementStateComponent")
-----------------------------------------------------
GuideTriggerPlayerHP.nMaxPercent = 0
GuideTriggerPlayerHP.nMinPercent = 0
GuideTriggerPlayerHP.tbHpChangedHandle = nil
GuideTriggerPlayerHP.tbHpChangedHandle = nil
-- GuideTriggerPlayerHP.nCurrentMovementType = nil
-----------------------------------------------------

local function OnHpChanged(self, nHp, nMaxHp, nHpPercent)
    self:DebugLog("OnHpChanged nHp = " .. tostring(nHp) .. " nMaxHp = " .. tostring(nMaxHp) .. " nHpPercent = " .. tostring(nHpPercent))
    self:DebugLog("nMinPercent = " .. self.nMinPercent .. " nMaxPercent = " .. self.nMaxPercent)
    --nHpPercent = nHpPercent * 100
    --local nCurrentMovementType = self.nCurrentMovementType
    local nCurrentMovementType = HumanMovementStateComponent:GetCurrentState() 
    if nCurrentMovementType == HumanMovementStateType.InPlane_State or
    nCurrentMovementType == HumanMovementStateType.Parachutine_State or
    nCurrentMovementType == HumanMovementStateType.Vehicle or
    nCurrentMovementType == HumanMovementStateType.Swimming then
        self:DebugLog("change 111")
        return
    end

    self:DebugLog("change", nHpPercent)
    if nHpPercent >self.nMinPercent and nHpPercent < self.nMaxPercent then
        self:Execute()
    end
end

--override
function GuideTriggerPlayerHP:Execute()
    self:DebugLog("Execute")
    self:Trigger()
end

function GuideTriggerPlayerHP:Begin()
    GuideTriggerPlayerHP.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nMaxPercent = tonumber(tbParam[2])
    self.nMinPercent = tonumber(tbParam[1])
end

function GuideTriggerPlayerHP:OnHumanMovementStateChange(Player, nOldState, nNewState)
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local bResult = (nOldState == HumanMovementStateType.Parachutine_State and nNewState == HumanMovementStateType.UpRight_State)
    self.nCurrentMovementType = nNewState
    if bResult then
        local EventHelper = self.EventHelper
        local PropertyComponent = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent()
        self:DebugLog("event")
        EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
    end
end

function GuideTriggerPlayerHP:OnPlayerSelfReady()
    local PropertyComponent = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent()
    self:DebugLog("event")
    local EventHelper = self.EventHelper
    if not self.tbHpChangedHandle then
        self:DebugLog("RegisterLuaDelegate OnHpChanged")
        self.tbHpChangedHandle = EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged, self)
    end
end

function GuideTriggerPlayerHP:Uninit()
    GuideTriggerPlayerHP.super.Uninit(self)
    if self.tbHpChangedHandle then
        self.EventHelper:UnregisterLuaDelegate(self.tbHpChangedHandle, OnHpChanged, self)
        self.tbHpChangedHandle = nil
    end
end

function GuideTriggerPlayerHP:BindEvent(EventHelper)
    --EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, self.OnHumanMovementStateChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, self.OnPlayerSelfReady)
end

return GuideTriggerPlayerHP
