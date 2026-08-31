
local BuildHumanWeaponTipsContentHelper = {}

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local HumanWeaponDef = require("HumanWeaponDef")
local UISetUtils = require("UISetUtils")
local HumanWeaponCategoryPropertyDataTable = require("HumanWeaponCategoryPropertyDataTable")
local L10N = require("L10N")
local DescKeyParser = require("DescKeyParser")
local DescKeyParserMiscDef = require("DescKeyParserMiscDef")

local WEAPON_TITLE = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_WEAPON_TITLE")                            -- {0}({1})


local function GetTitle(tbItemTemplate)
    local tbWeaponCategoryPropertyTemplate = HumanWeaponCategoryPropertyDataTable:GetTemplate(tbItemTemplate.nWeaponCategory)
    return L10N:Format(WEAPON_TITLE, tbItemTemplate.l10nName, tbWeaponCategoryPropertyTemplate.l10nName)
end


local MELEE_DESC_KEYS =
{
    "dungeon_general_desc",
    "dungeon_special_desc",
    "damage",
    "attack_range",
    "melee_attack_speed",
}
local RANGED_DESC_KEYS =
{
    "dungeon_general_desc",
    "dungeon_special_desc",
    "damage",
    "attack_times",
    "speed_of_bullet",
    "reload_time",
    "rate_of_fire",
    "recoil",
}
local WAND_DESC_KEYS =
{
    "dungeon_general_desc",
    "dungeon_special_desc",
    "damage",
    "charge_time",
    "fire_ball_speed",
    "fire_ball_explosive_range",
    "fire_ball_auto_explosive_range",
}

local function GetKeyList(tbItemTemplate)
    if tbItemTemplate.nWeaponCategory == HumanWeaponDef.WeaponCategory.Wand then
        return WAND_DESC_KEYS
    end
    if tbItemTemplate.nPrimaryCategory  == HumanWeaponDef.WeaponPrimaryCategory.Melee then
        return MELEE_DESC_KEYS
    else
        return RANGED_DESC_KEYS
    end
end

-- tbTipsData.szTitle
-- tbTipsData.tbDatas
-- tbTipsData.nDamage
-- tbTipsData.szDesc
-- table.insert(tbTipsData.tbDatas, {szTitle = "", szDesc = ""})
function BuildHumanWeaponTipsContentHelper.GetTipsData(nItemTemplateId)
    local tbTipsData = {}
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    assert(nCategory == BattleItemCategoryDef.HUMAN_WEAPON, "error! category not human weapon!".. nItemTemplateId)

    tbTipsData.szTitle = GetTitle(tbItemTemplate)
    tbTipsData.tbCharacteristics = {}
    local tbDatas = {}
    tbTipsData.tbDatas = tbDatas
    local tbInputData = {}
    tbInputData.nItemTemplateId = nItemTemplateId
    local tbKeys = GetKeyList(tbItemTemplate)
    for _, szKey in ipairs(tbKeys) do
        local tbOutData = DescKeyParser.GetParseData(DescKeyParserMiscDef.NAME_SPACE_HUMAN_WEAPON, szKey, tbInputData)
        local tbData = {}
        tbData.szTitle = tbOutData.l10nKey
        tbData.szDesc = tbOutData.l10nValue
        table.insert(tbDatas, tbData)
    end
    return tbTipsData
end

return BuildHumanWeaponTipsContentHelper
