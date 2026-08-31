-----------------------------------------------------
--File Name    : GuideTriggerShipIsEquiped.lua
--Description  : 当装配某艘舰船时的trigger
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerShipIsEquiped     = luaclass("GuideTriggerShipIsEquiped", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
-----------------------------------------------------

-----------------------------------------------------

local function ConvertParamsToNumber(tbParam)
    for i,v in ipairs(tbParam) do
        if v then
            tbParam[i] = tonumber(v)
        end
    end
    return tbParam
end

local function CheckInTable(tbVal, value)
    for k,v in pairs(tbVal) do
        if v == value then
            return true
        end
    end
    return false
end

local function ShipIsEquiped(self, tbTemplateIds)
    local tbShipPreparationComponent = GamePlayerSelfHelper:Get().ShipPreparationComponent
    if not tbShipPreparationComponent then
        self:Break()
        return
    end
    local tbShipIds = tbShipPreparationComponent:GetEquippedShipIds()
    if not tbShipIds then
        self:Break()
        return
    end
    local bResult = false
    for i,v in ipairs(tbShipIds) do
        bResult = CheckInTable(tbTemplateIds, v)
        if bResult then
            break
        end
    end
    bResult = self.tbTemplate.bIsEnable and bResult or not bResult
    if bResult then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerShipIsEquiped:Begin()
    GuideTriggerShipIsEquiped.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    local tbTemplateIds = ConvertParamsToNumber(tbParam)
    ShipIsEquiped(self, tbTemplateIds)
end

function GuideTriggerShipIsEquiped:BindEvent(EventHelper)
end

return GuideTriggerShipIsEquiped
