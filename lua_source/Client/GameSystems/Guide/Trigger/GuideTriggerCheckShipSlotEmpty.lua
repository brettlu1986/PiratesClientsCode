-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-17
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerCheckShipSlotEmpty    = luaclass("GuideTriggerCheckShipSlotEmpty",GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerCheckShipSlotEmpty:CheckSlotIsEmpty()
    local tbSlotId = self.tbTemplate.tbItemId
    local nSlotId = tbSlotId[1]
    nSlotId = nSlotId == nil and 1 or nSlotId
    local PreparationComponent = GamePlayerSelfHelper:Get().ShipPreparationComponent
    if not PreparationComponent then
        self:DebugLog("CheckShipIsEquip, PreparationComponent = nil")
        return
    end
    local tbEquippedShipIds = PreparationComponent:GetEquippedShipIds()
    if not tbEquippedShipIds then
        self:DebugLog("CheckShipIsEquip, tbEquippedShipIds = nil")
        return
    end
    local bResult = false
    bResult = (tbEquippedShipIds[nSlotId] == nil)
    if not self.tbTemplate.bIsEnable then
        bResult = not bResult
    end
    self:DebugLog("CheckSlotIsEmpty = " .. tostring(bResult) .. tostring(self.tbTemplate.bIsEnable))
    return bResult
end

--override
function GuideTriggerCheckShipSlotEmpty:Begin()
    GuideTriggerCheckShipSlotEmpty.super.Begin(self)
    local bResult = self:CheckSlotIsEmpty()
    if bResult then
        self:Trigger()
    else
        self:ForceEndCurrentGroup()
    end
end

return GuideTriggerCheckShipSlotEmpty