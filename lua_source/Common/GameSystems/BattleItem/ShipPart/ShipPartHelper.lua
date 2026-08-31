local ShipPartHelper = { }

local BattleItemSystemHelper  = require("BattleItemSystemHelper")
local ShipPartTypeDef = require("ShipPartTypeDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ShipDataTable = require("ShipDataTable")
local ShipArmorDataTableEx = require("ShipArmorDataTableEx")

local function IsInTable(tbTable,  nGrade)
    for _,v in ipairs(tbTable) do
        if v == nGrade then
            return true
        end
    end
    return false
end

local function GetArmorTemplate(tbShip, nArmorId)
    local tbShipTemplate = ShipDataTable:GetTemplate(tbShip:GetTemplateId())
    return ShipArmorDataTableEx:GetTemplate(tbShipTemplate.nArmorSuitId, nArmorId)
end

local function GetShipPartByArmorId(tbShip, nArmorId)
    if tbShip and tbShip:IsShip() then
        local tbShipArmorTemplate = GetArmorTemplate(tbShip, nArmorId)
        local tbCoveredShipPartGrades = tbShipArmorTemplate.tbCoveredShipPartGrades
        local nShipPartType = tbShipArmorTemplate.nShipPartCategory
        if tbCoveredShipPartGrades and nShipPartType > 0 and nShipPartType <= ShipPartTypeDef.Max then
            local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
            local tbShipPart = BattleItemSystemServer:GetEquippedItem(tbShip:GetServerInstanceId(), BattleItemCategoryDef.SHIP_PART,
            tbShip:GetServerInstanceId(), nShipPartType)
            if tbShipPart and IsInTable(tbCoveredShipPartGrades, tbShipPart.tbTemplate.nGrade) then
                return tbShipPart
            end
        end
    end
    return nil
end

-- 扣除零件耐久，返回折算后需要扣除的血量
function ShipPartHelper.DecreaseDurability(tbShip, nArmorId, nDamage)
    local tbShipPart = GetShipPartByArmorId(tbShip, nArmorId)
    if tbShipPart then
        tbShipPart:ApplyDamage(nDamage)
        local nShipPartArmor = tbShipPart.tbTemplate.nShipPartArmor
        if nShipPartArmor and nShipPartArmor > 0 then
            return nShipPartArmor * nDamage, nShipPartArmor
        end
    end
    return nDamage, 1
end

return ShipPartHelper