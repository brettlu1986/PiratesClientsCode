local ShipWeaponCategoryDataTable = {}

local L10N = require("L10N")
-- [EXPORT BEGIN]
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
-- [EXPORT END]

ShipWeaponCategoryDataTable.szFileName = "common/ffa/item/ship_weapon/ship_weapon_category.tab"
ShipWeaponCategoryDataTable.bEnableIterateKey = true

function ShipWeaponCategoryDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nCategory")
    Parser:Define("nCategory"       , "category"        , nil                       , Parser.TypeInt)
    Parser:Define("l10nName"        , "name"            , L10N.NullString           , Parser.TypeL10N)
    Parser:Define("nWeaponSlot"     , "weapon_slot"     , ShipWeaponSlotDef.UNKNOWN , Parser.TypeInt)
    Parser:Define("bPairedWeapon"   , "paired_weapon"   , false                     , Parser.TypeBool)
    Parser:Define("bDisplayOnLobby" , "display_on_lobby", true                      , Parser.TypeBool)
    Parser:Define("szCrosshairsRes" , "crosshairs_res"  , nil                       , Parser.TypeString)
    Parser:Define("szFireNormalRes" , "fire_normal_res" , nil                       , Parser.TypeString)
    Parser:Define("szFirePressedRes", "fire_pressed_res", nil                       , Parser.TypeString)
end

-- [EXPORT BEGIN]
function ShipWeaponCategoryDataTable:GetTemplate(nCategory)
    return self.tbContainer[nCategory]
end

function ShipWeaponCategoryDataTable:GetTemplates()
    return self.tbContainer
end

function ShipWeaponCategoryDataTable:GetWeaponSlot(nCategory)
    local tbTemplate = self:GetTemplate(nCategory)
    return tbTemplate and tbTemplate.nWeaponSlot or ShipWeaponSlotDef.UNKNOWN
end

function ShipWeaponCategoryDataTable:GetIsPairedWeapon(nCategory)
    local tbTemplate = self:GetTemplate(nCategory)
    return tbTemplate and tbTemplate.bPairedWeapon or false
end

function ShipWeaponCategoryDataTable:GetCrosshairsRes(nCategory)
    local tbTemplate = self:GetTemplate(nCategory)
    return tbTemplate and tbTemplate.szCrosshairsRes
end
-- [EXPORT END]

return ShipWeaponCategoryDataTable
