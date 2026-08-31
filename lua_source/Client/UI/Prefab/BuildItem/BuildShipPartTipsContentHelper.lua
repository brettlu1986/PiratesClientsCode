
local BuildShipPartTipsContentHelper = {}

local UISetUtils = require("UISetUtils")
local L10N = require("L10N")

local BattleItemCategoryDef = require("BattleItemCategoryDef")

local BattleItemDataTable = require("BattleItemDataTable")

local COLOR_STRING_FORMAT             = '<text color="%s">%s</>'

local YELLOW_COLOR = '#efc124ff'
local WHITE_COLOR  = '#ffffffff'

local LINE_BREAK = "\n"

local DESC_PART_EFFECT_TITLE             = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_PART_EFFECT_TITLE")               -- 属性效果：{0}
local DESC_PART_POS_TITLE                = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_PART_POS_TITLE")                  -- 部位：{0}
local DESC_PART_DURABILITY_TITLE         = UISetUtils.GetL10NTextByKey("FFA_UI_ITEM_TIPS_PART_DURABILITY_TITLE")           -- 耐久：{0}（100%）

local function ColorString(szText, szColor)
    return string.format(COLOR_STRING_FORMAT, szColor, szText)
end

local function FillShipPartTipsData(tbTipsData, tbItemTemplate)
    tbTipsData.szTitle = tbItemTemplate.l10nName
    local szDesc = ""
    local l10nEffect = L10N:Format(DESC_PART_EFFECT_TITLE, tbItemTemplate.l10nDesc)

    local l10nShipPartCategoryName = BattleItemDataTable:GetSubCategoryName(tbItemTemplate.nCategory, tbItemTemplate.nSubCategory)
    local l10nPos = L10N:Format(DESC_PART_POS_TITLE, l10nShipPartCategoryName)

    local l10nDurability = L10N:Format(DESC_PART_DURABILITY_TITLE, tbItemTemplate.nDurability)

    szDesc = szDesc .. ColorString(L10N:ToString(l10nEffect), YELLOW_COLOR) .. LINE_BREAK .. LINE_BREAK
    szDesc = szDesc .. ColorString(L10N:ToString(l10nPos), WHITE_COLOR) .. LINE_BREAK
    szDesc = szDesc .. ColorString(L10N:ToString(l10nDurability), WHITE_COLOR) .. LINE_BREAK .. LINE_BREAK .. LINE_BREAK

    tbTipsData.szDesc = szDesc
end

-- tbTipsData.szTitle
-- tbTipsData.szDesc
function BuildShipPartTipsContentHelper.GetTipsData(nItemTemplateId)
    local tbTipsData = {}
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    assert(nCategory == BattleItemCategoryDef.SHIP_PART, "error! category not ship part!".. nItemTemplateId)
    FillShipPartTipsData(tbTipsData, tbItemTemplate)
    return tbTipsData
end

return BuildShipPartTipsContentHelper
