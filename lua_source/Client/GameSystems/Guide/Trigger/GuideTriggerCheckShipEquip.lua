-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-17
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerCheckShipEquip        = luaclass("GuideTriggerCheckShipEquip",GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
-----------------------------------------------------

function GuideTriggerCheckShipEquip:CheckShipIsEquip()
    local tbShipId = self.tbTemplate.tbItemId
    local nShipId = tbShipId[1]
    local PreparationComponent = GamePlayerSelfHelper:Get().ShipPreparationComponent
    if not PreparationComponent then
        self:DebugLog("CheckShipIsEquip(),PreparationComponent = nil")
        return
    end
    local tbEquippedShipIds = PreparationComponent:GetEquippedShipIds()
    if not tbEquippedShipIds then
        self:DebugLog("CheckShipIsEquip(),tbEquippedShipIds = nil")
        return
    end
    local bResult = false
    for k, v in pairs(tbEquippedShipIds) do
        if v == nShipId then
            bResult = true
            break
        end
    end
    if not self.tbTemplate.bIsEnable then
        bResult = not bResult
    end
    self:DebugLog("CheckShipIsEquip = " .. tostring(bResult) .. tostring(self.tbTemplate.bIsEnable))
    return bResult
end

--override
function GuideTriggerCheckShipEquip:Begin()
    GuideTriggerCheckShipEquip.super.Begin(self)
    local bResult = self:CheckShipIsEquip()
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

return GuideTriggerCheckShipEquip