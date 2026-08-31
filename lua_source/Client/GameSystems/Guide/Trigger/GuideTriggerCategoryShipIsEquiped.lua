-----------------------------------------------------
--File Name    : GuideTriggerCategoryShipIsEquiped.lua
--Description  : 当装配某艘舰船时的trigger
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerCategoryShipIsEquiped     = luaclass("GuideTriggerCategoryShipIsEquiped", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local ItemSystem                = require("ItemSystem")
-----------------------------------------------------

-----------------------------------------------------

local function CategoryShipIsEquiped(self, nCategory)
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
    for i, nShipItemId in ipairs(tbShipIds) do    
        local tbShipTemplate = ItemSystem:GetItemTemplate(nShipItemId)
        local nEquipedShipCategory = tbShipTemplate.nSubCategory
        if nCategory == nEquipedShipCategory then
            bResult = true
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
function GuideTriggerCategoryShipIsEquiped:Begin()
    GuideTriggerCategoryShipIsEquiped.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    local nCategory = tbParam[1]
    CategoryShipIsEquiped(self, nCategory)
end

function GuideTriggerCategoryShipIsEquiped:BindEvent(EventHelper)
end

return GuideTriggerCategoryShipIsEquiped
