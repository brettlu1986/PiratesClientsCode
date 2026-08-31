--[[
    DataTable类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    tbContainer: table
    OnEditorParseLine： 解析函数，参数Parser

    可选的变量与函数
    OnEditorParseFinished: 参数无，本DataTable读取完毕后触发
    OnGameRequired: 参数无，游戏运行时第一次require时触发
    OnEditorDefine: 定义导出参数    自定义导出标签：
         导出单行：-- [EXPORT]
         导出多行：-- [EXPORT BEGIN] 和 -- [EXPORT END]

    DataTableExporter.TypeInt = 0
    DataTableExporter.TypeString = 1
    DataTableExporter.TypeFloat = 2
    DataTableExporter.TypeBool = 3
    DataTableExporter.TypeL10N = 4
    DataTableExporter.TypeArrayInt = 5
    DataTableExporter.TypeArrayString = 6
    DataTableExporter.TypeArrayFloat = 7
    DataTableExporter.TypeArrayBool = 8
    DataTableExporter.TypeArrayL10N = 9
--]]
local ShipDataTable = {}
local L10N = require("L10N")

ShipDataTable.szFileName = "common/ffa/ship/ship.tab"

function ShipDataTable:OnEditorDefine(Parser)
    Parser:SetKey("nId")
    Parser:Define("nId", "id", nil, Parser.TypeInt)

    Parser:Define("l10nName", "name", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nCategory", "category", nil, Parser.TypeInt)
    Parser:Define("nGrade", "grade", nil, Parser.TypeInt)
    Parser:Define("nResId", "res_id", nil, Parser.TypeInt)
    Parser:Define("nGearId", "gear_id", nil, Parser.TypeInt)
    Parser:Define("l10nDesc", "desc", L10N.NullString, Parser.TypeL10N)
    Parser:Define("nMaxInventorySlots", "max_inventory_slots", nil, Parser.TypeInt)
    Parser:Define("nInventoryCapacity", "inventory_capacity", nil, Parser.TypeInt)

    Parser:Define("nHp", "hp", -1, Parser.TypeInt)
    Parser:Define("nDyingHp", "dying_hp", -1, Parser.TypeInt)
    Parser:Define("nDyingHpReduceSpeed", "dying_hp_reduce_speed", -1, Parser.TypeInt)
    Parser:Define("nRescuedHp", "rescued_hp", -1, Parser.TypeInt)
    -- Parser:Define("nHideRange", "hide_range", -1, Parser.TypeFloat)
    -- Parser:Define("nFirePunishmentRatio", "fire_punishment_ratio", 1, Parser.TypeFloat)
    -- Parser:Define("nFirePunishmentTime", "fire_punishment_time", 1, Parser.TypeFloat)
    -- Parser:Define("nSideWeaponCount", "side_weapon_count", -1, Parser.TypeInt)
    -- Parser:Define("nSideDefaultWeapon", "side_default_weapon", -1, Parser.TypeInt)
    -- Parser:Define("nHeadWeaponCount", "head_weapon_count", -1, Parser.TypeInt)
    -- Parser:Define("nHeadDefaultWeapon", "head_default_weapon", -1, Parser.TypeInt)
    -- Parser:Define("nDeckWeaponCount", "deck_weapon_count", -1, Parser.TypeInt)
    -- Parser:Define("nDeckDefaultWeapon", "deck_default_weapon", -1, Parser.TypeInt)
    Parser:Define("nBasicArmor", "basic_armor", -1, Parser.TypeInt)
    Parser:Define("nArmorSuitId", "armor_suit_id", -1, Parser.TypeInt)
    Parser:Define("nMaxMorale", "max_morale", -1, Parser.TypeInt)
    Parser:Define("nMoraleDecreasePerSecond", "ep_decrease_per_second", 0, Parser.TypeFloat)
    Parser:Define("nMoralePhaseId", "morale_phase_id", -1, Parser.TypeInt)
    Parser:Define("nListenRange", "listen_range", -1, Parser.TypeInt)
    Parser:Define("nHeadCollisionArmorId", "head_collision_armor_id", -1, Parser.TypeInt)
    Parser:Define("nSideCollisionArmorId", "side_collision_armor_id", -1, Parser.TypeInt)
    Parser:Define("nSternCollisionArmorId", "stern_collision_armor_id", -1, Parser.TypeInt)
    Parser:Define("nSailAppearanceUnique", "sail_appearance_unique", 0, Parser.TypeInt)
    Parser:Define("nArmorAppearanceUnique", "armor_appearance_unique", 0, Parser.TypeInt)
    Parser:Define("nCaptainAppearanceUnique", "captain_appearance_unique", 0, Parser.TypeInt)
    Parser:Define("nVisibleDistance", "visible_distance", 0, Parser.TypeInt)
    Parser:Define("nMaxLeanDegress", "max_lean_degress", 0, Parser.TypeFloat)
end

-- [EXPORT BEGIN]
function ShipDataTable:GetTemplate(nId)
    return self.tbContainer[nId]
end

function ShipDataTable:GetResTemplate(nId)
    local tbShipTemplateData = self:GetTemplate(nId)
    if tbShipTemplateData then
        return tbShipTemplateData.tbResData
    else
        error("Cannot find Ship Template with template_id:".. nId)
    end
end

function ShipDataTable:GetShipMovementData(nId)
    local tbShipTemplateData = self:GetTemplate(nId)
    if tbShipTemplateData == nil then
        error("Cannot find Ship Template with template_id:".. nId)
    else
        return tbShipTemplateData.tbShipMovementData
    end
end

function ShipDataTable:GetShipCategoryData(nId)
    local tbShipTemplateData = self:GetTemplate(nId)
    if tbShipTemplateData == nil then
        error("Cannot find Ship Template with template_id:".. nId)
    else
        return tbShipTemplateData.nCategory
    end
end

function ShipDataTable:OnGameRequired()
    local ShipResDataTable = require("ShipResDataTable")
    local ShipGearDataTable = require("ShipGearDataTable")
    local tbContainer = self.tbContainer
    for k,v in pairs(tbContainer) do
        v.tbResData = ShipResDataTable:GetTemplate(v.nResId)
        if(v.tbResData == nil) then
            error("ShipDataTable find res data failed: ".. v.nResId)
        end
        v.tbShipGearData = ShipGearDataTable:GetTemplateArray(v.nGearId)
        if (v.tbShipGearData == nil) then
            error("ShipDataTable find ship gear data failed: ".. v.nGearId)
        end
    end
end
-- [EXPORT END]


return ShipDataTable
